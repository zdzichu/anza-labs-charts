#!/usr/bin/env bash

set -eu

YQ="${1}"

# Update Chart.yaml with the image tag from values.yaml
"${YQ}" '.appVersion = load("./values.yaml").image.tag' './Chart.yaml' -i

VERSION=$("${YQ}" '.image.tag' ./values.yaml)

TREE=$(curl -fsSL "https://api.github.com/repos/clastix/kamaji/git/trees/${VERSION}?recursive=1")
CRDS=$(echo "${TREE}" |\
    jq -r '[.tree.[] | select(.path | startswith("charts/kamaji/crds/"))] | .[].path')

# Remove previous file if it exists
rm -rf ./crds
mkdir -p ./crds

while IFS= read -r CRD; do
    CRD_FILE="./crds/$(basename "${CRD}")"
    curl -fsSL "https://raw.githubusercontent.com/clastix/kamaji/refs/tags/${VERSION}/${CRD}" > "${CRD_FILE}"
    "${YQ}" '.' "${CRD_FILE}" -i
done <<< "${CRDS}"

GENERATED=$(echo "${TREE}" |\
    jq -r '[.tree.[] | select(.path | startswith("charts/kamaji/controller-gen/"))] | .[].path')

# Remove previous file if it exists
rm -rf ./generated
mkdir -p ./generated

while IFS= read -r GEN; do
    GEN_FILE="./generated/$(basename "${GEN}")"
    curl -fsSL "https://raw.githubusercontent.com/clastix/kamaji/refs/tags/${VERSION}/${GEN}" > "${GEN_FILE}"
    "${YQ}" '.' "${CRD_FILE}" -i
done <<< "${GENERATED}"

curl -fsSL "https://raw.githubusercontent.com/clastix/kamaji/refs/tags/${VERSION}/charts/kamaji/Chart.yaml" > Chart.tmp.yaml
"${YQ}" '.dependencies = load("./Chart.tmp.yaml").dependencies' './Chart.yaml' -i
rm -rf Chart.tmp.yaml
