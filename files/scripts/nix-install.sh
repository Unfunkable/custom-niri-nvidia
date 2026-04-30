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

tmp_flake_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_flake_dir"' EXIT

cat >"$tmp_flake_dir/flake.nix" <<'EOF'
{
  description = "nix install smoke check";

  outputs = { self }: {
  };
}
EOF

if ! "$nix_bin" flake metadata --offline "path:$tmp_flake_dir" >/dev/null; then
  echo "Nix install failed: flakes support is not enabled" >&2
  exit 1
fi
