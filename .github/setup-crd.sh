#!/usr/bin/env bash

mkdir -p .crd
cd .crd || exit

# renovate:github-url
wget https://raw.githubusercontent.com/yannh/kubeconform/v0.8.0/scripts/openapi2jsonschema.py
export FILENAME_FORMAT='{fullgroup}-{kind}-{version}'

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/argoproj/argo-cd/v3.2.6/manifests/install.yaml

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/traefik/traefik/v3.4.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# renovate:github-url
python3 openapi2jsonschema.py https://github.com/cert-manager/cert-manager/releases/download/v1.19.4/cert-manager.yaml

# Keep the tag in sync with the ARC chart version in arc-systems and arc-runners.
python3 openapi2jsonschema.py https://raw.githubusercontent.com/actions/actions-runner-controller/gha-runner-scale-set-0.15.1/charts/gha-runner-scale-set-controller/crds/actions.github.com_autoscalingrunnersets.yaml
