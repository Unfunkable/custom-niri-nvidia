#!/usr/bin/env bash
set -euo pipefail

curl --proto '=https' --tlsv1.2 -sSf \
  https://install.determinate.systems/nix | \
  sh -s -- install linux \
    --no-confirm \
    --init systemd \
    --extra-conf "trusted-users = root @wheel" \
    --extra-conf "experimental-features = nix-command flakes"
 
# Ensure the nix binaries are on the system PATH for subsequent build steps
echo 'export PATH="/nix/var/nix/profiles/default/bin:$PATH"' \
  > /etc/profile.d/nix.sh
