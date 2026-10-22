# k8s manifest

## Production CA trust

Production workloads mount the node's public `/etc/ssl/certs` and
`/usr/share/ca-certificates` directories read-only. Update `ca-certificates` on
every production node before deploying these overlays. Ubuntu 24.04 requires
`20260816ubuntu0.24.04.1` or newer for the October 2026 eMudhra incident.
Private keys are not mounted. Restart workloads after CA updates because some
runtimes cache their trust store.

traQing also preloads `traq-ing/overlays/production/bun-ca-preload.js` so its
outgoing fetch requests use only the patched CA bundle. Its production overlay
supplies Bun 1.4.3 from a digest-pinned init container; Bun 1.3.14 accepted an
affected chain even with an explicit CA override. The server and scheduled jobs
run their entry files directly with `--preload`, so the mitigation applies in
the process making the requests. `PATH` also selects the supplied Bun binary.
Keep the preload until a released Bun version distrusts the affected roots by
default. Other runtimes with embedded roots also require their own fix.

Verify both
`https://dv-g3b-emudhra.we-have-a-problem.com/` and
`https://dv-g3b-aaa-emudhra.we-have-a-problem.com/` fail certificate validation
while normal HTTPS requests continue to work.

Run the preload check with
`bun test traq-ing/overlays/production/bun-ca-preload.test.js`.

## セットアップ

### 共通 (ツールのセットアップ)

- `kustomize`
  - `curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash`
- `ksops`
  - `curl -s https://raw.githubusercontent.com/viaduct-ai/kustomize-sops/master/scripts/install-ksops-archive.sh | bash`
- `sops`
  - `curl -LO https://github.com/getsops/sops/releases/download/v3.9.2/sops-v3.9.2.linux.amd64`
  - `mv sops-v3.9.2.linux.amd64 /usr/local/bin/sops`
  - `chmod +x /usr/local/bin/sops`
- `age`
  - `apt install age`
- `go`
  - `apt install golang-go` (Go >= 1.19)
- `argocd`
  - `curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64`
  - `sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd`
  - `rm argocd-linux-amd64`

### local

- `asterion.cp20.local` を `127.0.0.1` に向ける
- `k3d cluster create --config k3d-config.yaml`
  - 壊すときは `k3d cluster delete asterion`
- `kubectl config use-context k3d-asterion`

### production

https://docs.k3s.io/quick-start に従って k3s をインストールする

```shell
curl -sfL https://get.k3s.io | sh -
```

## Bootstrap

ArgoCDのセットアップ

```
# cert-manager を用意
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

# argocd ネームスペースを作成
kubectl create ns argocd

# argocd を apply
# local
kustomize build ./argocd/overlays/local --enable-alpha-plugins --enable-exec | kubectl apply -n argocd -f -
# production
kustomize build ./argocd/overlays/production --enable-alpha-plugins --enable-exec | kubectl apply -n argocd -f -

# ksops の鍵を生成して渡す
age-keygen -o ~/.config/sops/age/keys.txt
# ここで得られた public key を .sops.yaml に記載する
# クラスタに登録する
kubectl -n argocd create secret generic age-key --from-file=$HOME/.config/sops/age/keys.txt

# applications を登録する
# local
argocd login cd.cp20.local --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
argocd app create applications \
  --repo https://github.com/cp-20/asterion-manifest \
  --path applications/overlays/local \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace applications \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --revision main
# production
# 一旦ポートフォワード (別ターミナルで)
kubectl port-forward svc/argocd-server -n argocd 8124:443
argocd login localhost:8124 --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
argocd app create applications \
  --repo https://github.com/cp-20/asterion-manifest \
  --path applications/overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace applications \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --revision main
```

cloudflared

```
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/

# cloudflared をインストール (Ubuntu)
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install cloudflared

# cloudflared にログイン
cloudflared tunnel login

# 新しい Tunnel を作成
cloudflared tunnel create asterion

# Tunnel を route に紐づけ
cloudflared tunnel route dns asterion traqing.cp20.dev
cloudflared tunnel route dns asterion cd.cp20.dev

# その Tunnel 用の認証情報をクラスタに登録 (<TunnelID> は適宜置き換え)
kubectl -n cloudflared create secret generic credentials \
  --from-file=credentials.json=$HOME/.cloudflared/<TunnelID>.json
```
