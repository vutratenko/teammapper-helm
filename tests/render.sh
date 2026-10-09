#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
service_rendered="$(mktemp)"
trap 'rm -f "${rendered}" "${service_rendered}"' EXIT

helm template teammapper "${repo_root}" \
  --namespace teammapper \
  --values "${repo_root}/values.sion2k.yaml" >"${rendered}"

helm template teammapper "${repo_root}" \
  --namespace teammapper \
  --values "${repo_root}/values.sion2k.yaml" \
  --set ingress.backend=service >"${service_rendered}"

assert_contains() {
  local expected="$1"
  if ! grep -Fq -- "${expected}" "${rendered}"; then
    echo "expected rendered chart to contain: ${expected}" >&2
    exit 1
  fi
}

assert_not_contains() {
  local unexpected="$1"
  if grep -Fq -- "${unexpected}" "${rendered}"; then
    echo "expected rendered chart not to contain: ${unexpected}" >&2
    exit 1
  fi
}

assert_contains "kind: Deployment"
assert_contains "kind: Service"
assert_contains "kind: Ingress"
assert_contains "kind: postgresql"
assert_contains "kind: NetworkPolicy"
assert_contains "kind: Gateway"
assert_contains "kind: HTTPRoute"
assert_contains "gatewayClassName: cilium"
assert_contains "helm.sh/chart: teammapper-0.2.1"
assert_contains "name: teammapper"
assert_contains "port: 80"
assert_contains "ghcr.io/b310-digital/teammapper:v0.3.7-1@sha256:a48e4e01c0361c69743374b7ae1416692993bf3f2bc173d892af11474c890538"
assert_contains "teammapper.sion2k.ru"
assert_contains "cert-manager.io/cluster-issuer: corp-acme"
assert_contains "nginx.ingress.kubernetes.io/service-upstream: \"true\""
assert_contains "storageClass: proxmox-data-xfs"
assert_contains "name: teammapper-app"
assert_contains "readOnlyRootFilesystem: true"
assert_contains "allowPrivilegeEscalation: false"
assert_contains "runAsUser: 1000"
assert_not_contains "kind: Secret"
assert_not_contains "latest"

if ! grep -Fq -- "name: cilium-gateway-teammapper" "${rendered}"; then
  echo "expected sion2k Ingress to point at the Cilium Gateway Service" >&2
  exit 1
fi

if grep -Fq -- "name: cilium-gateway-teammapper" "${service_rendered}"; then
  echo "expected rollback mode to point Ingress directly at the application Service" >&2
  exit 1
fi

if ! grep -A1 -- "- name: POSTGRES_SSL" "${rendered}" | grep -Fq 'value: "true"'; then
  echo "expected sion2k PostgreSQL connection to require TLS" >&2
  exit 1
fi

echo "render assertions passed"
