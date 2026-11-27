# arc-runners

Self-hosted GitHub Actions runners for
[cp-20/kaggle-elf-calculator](https://github.com/cp-20/kaggle-elf-calculator),
managed by Actions Runner Controller (ARC) in gha-runner-scale-set mode.

- Controller: `../arc-systems` (namespace `arc-systems`).
- Runner scale set: `asterion-kaggle` (namespace `arc-runners`),
  0 to 2 runners, 1 CPU / 2Gi requested per runner.
- Use it in a workflow with `runs-on: asterion-kaggle`.

Keep the chart version the same in both kustomizations and in the CRD URL in
`.github/setup-crd.sh`.

## Secret

`base/secrets/arc-github-app.yaml` is SOPS-encrypted and still holds the
placeholder `REPLACE_ME` for every key. Fill in the real values before merging
to `main`:

| Key | Value |
| --- | --- |
| `github_app_id` | GitHub App ID (or client ID) |
| `github_app_installation_id` | Installation ID of the App on `cp-20/kaggle-elf-calculator` |
| `github_app_private_key` | Whole contents of the App's private key `.pem` |

Edit it with `task edit-secret -- arc-runners/base/secrets/arc-github-app.yaml`
(write the private key as a YAML block scalar, `github_app_private_key: |`).

The App needs these repository permissions: Administration (read and write)
and Metadata (read-only).
