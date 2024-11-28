# k8s manifest

## ローカルテスト用のセットアップ

- `asterion.cp20.local` を `127.0.0.1` に向ける
- `k3d cluster create --config k3d-config.yaml`
- `kubectl config use-context k3d-asterion`

## Bootstrap

ArgoCDのセットアップ

```
# argocd ネームスペースを作成
kubectl create ns argocd

# argocd を apply
kustomize build ./argocd --enable-alpha-plugins --enable-exec | kubectl apply -n argocd -f -
```

ArgoCDにアクセス (`localhost:8124`)

- Port Forward: `kubectl port-forward svc/argocd-server -n argocd 8124:443`
- `admin` ユーザーのパスワードを取得 `kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
