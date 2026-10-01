#!/bin/bash
set -euo pipefail

case "$(uname -m)" in
  x86_64)  arch="" ;;
  aarch64) arch="-arm64" ;;
  *)       arch="-$(uname -m)" ;;
esac

# Mirrors tried in order until one responds.
mirrors="https://mirror2.openshift.com https://mirror.openshift.com"
path="pub/rhacs/assets/${ROXCTL_VERSION}/bin/Linux/sha256sum.txt"

fetch_first() {
  # $@ are URLs; echo body of the first that succeeds, else fail.
  for url in "$@"; do
    if body="$(curl -sf "$url")"; then
      printf '%s' "$body"
      return 0
    fi
  done
  return 1
}

urls=""
for m in $mirrors; do urls="$urls ${m}/${path}"; done
# shellcheck disable=SC2086
sums="$(fetch_first $urls)" || { echo "could not fetch sha256sum.txt from any mirror: ${mirrors}" >&2; exit 1; }
want="$(printf '%s\n' "$sums" | awk -v f="./roxctl${arch}" '$2 == f {print $1}')"
[ -n "$want" ] || { echo "no entry for ./roxctl${arch} in sha256sum.txt" >&2; exit 1; }

echo "${want}  roxctl" | sha256sum -c
