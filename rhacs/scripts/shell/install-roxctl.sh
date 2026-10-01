#!/bin/sh
set -eu

case "$(uname -m)" in
  x86_64)  arch="" ;;
  aarch64) arch="-arm64" ;;
  *)       arch="-$(uname -m)" ;;
esac

curl -L -f -o roxctl "https://mirror.openshift.com/pub/rhacs/assets/${ROXCTL_VERSION}/bin/Linux/roxctl${arch}"
chmod +x roxctl
