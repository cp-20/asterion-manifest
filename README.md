# k8s manifest

## ローカルテスト用のセットアップ

- 次のアドレスを `127.0.0.1` に向ける
  - `asterion.cp20.local`
  - `cd.cp20.local`
  - `traq-ing.cp20.local`
- `k3d cluster create --config k3d-config.yaml`
  - 壊すときは `k3d cluster delete asterion`
- `kubectl config use-context k3d-asterion`


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
argocd login cd.cp20.local --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
# local
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

- Port Forward: `kubectl port-forward svc/argocd-server -n argocd 8124:443`
- `admin` ユーザーのパスワードを取得 `kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
