#!/usr/bin/env bash
set -euo pipefail

dump_nix_state() {
  echo "=== Nix filesystem diagnostics ===" >&2

  if [[ -e /nix ]]; then
    ls -ald /nix >&2 || true
    find /nix -maxdepth 3 \( -type d -o -type f -o -type l \) | sort >&2 || true
  else
    echo "/nix does not exist" >&2
  fi

  if [[ -e /nix/receipt.json ]]; then
    echo "=== /nix/receipt.json ===" >&2
    cat /nix/receipt.json >&2 || true
  fi

  if [[ -e /etc/nix/nix.conf ]]; then
    echo "=== /etc/nix/nix.conf ===" >&2
    cat /etc/nix/nix.conf >&2 || true
  fi
}

installer_log="$(mktemp)"

if ! curl --proto '=https' --tlsv1.2 -fsSL \
  https://install.determinate.systems/nix | \
  env NIX_INSTALLER_VERBOSITY=2 NIX_INSTALLER_LOGGER=full \
    sh -s -- install linux \
      --no-confirm \
      --init none \
      --extra-conf "trusted-users = root @wheel" \
      --extra-conf "experimental-features = nix-command flakes" \
  2>&1 | tee "$installer_log"; then
  echo "Determinate installer exited non-zero" >&2
  echo "=== Installer log ===" >&2
  cat "$installer_log" >&2 || true
  dump_nix_state
  exit 1
fi

# Ensure the nix binaries are on the system PATH for subsequent build steps
echo 'export PATH="/nix/var/nix/profiles/default/bin:$PATH"' \
  > /etc/profile.d/nix.sh

nix_bin="/nix/var/nix/profiles/default/bin/nix"

if [[ ! -x "$nix_bin" ]]; then
  echo "Nix install failed: expected binary missing at $nix_bin" >&2
  echo "=== Installer log ===" >&2
  cat "$installer_log" >&2 || true
  dump_nix_state
  exit 1
fi

"$nix_bin" --version

experimental_features="$("$nix_bin" config show experimental-features)"

if [[ "$experimental_features" != *"nix-command"* ]] || [[ "$experimental_features" != *"flakes"* ]]; then
  echo "Nix install failed: flakes support is not enabled" >&2
  echo "$experimental_features" >&2
  exit 1
fi
