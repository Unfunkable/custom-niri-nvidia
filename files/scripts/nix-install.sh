#!/usr/bin/env bash
set -euo pipefail

curl --proto '=https' --tlsv1.2 -fsSL \
  https://install.determinate.systems/nix | \
  sh -s -- install linux \
    --no-confirm \
    --init none \
    --extra-conf "trusted-users = root @wheel" \
    --extra-conf "experimental-features = nix-command flakes"

# Ensure the nix binaries are on the system PATH for subsequent build steps
echo 'export PATH="/nix/var/nix/profiles/default/bin:$PATH"' \
  > /etc/profile.d/nix.sh

nix_bin="/nix/var/nix/profiles/default/bin/nix"

if [[ ! -x "$nix_bin" ]]; then
  echo "Nix install failed: expected binary missing at $nix_bin" >&2
  exit 1
fi

"$nix_bin" --version

experimental_features="$("$nix_bin" config show extra-experimental-features)"

if [[ "$experimental_features" != *"nix-command"* ]] || [[ "$experimental_features" != *"flakes"* ]]; then
  echo "Nix install failed: flakes support is not enabled" >&2
  echo "$experimental_features" >&2
  exit 1
fi
