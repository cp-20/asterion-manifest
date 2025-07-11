#!/usr/bin/env bash

mkdir -p .crd
cd .crd || exit

# renovate:github-url
wget https://raw.githubusercontent.com/yannh/kubeconform/v0.7.0/scripts/openapi2jsonschema.py
export FILENAME_FORMAT='{fullgroup}-{kind}-{version}'

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/argoproj/argo-cd/v3.0.11/manifests/install.yaml

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/traefik/traefik/v3.4.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# renovate:github-url
python3 openapi2jsonschema.py https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
