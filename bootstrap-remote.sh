#!/usr/bin/env bash
# Bootstrap a remote Ubuntu VM: copy SSH keys + client-certs, then run ubuntu-22.sh there.
# Usage: bootstrap-remote.sh <ip>
set -euo pipefail
 
IP="${1:?usage: $(basename "$0") <ip>}"
KEY="${SSH_IDENTITY:-$HOME/.ssh/osolovey.id_explorer}"
PORT="${SSH_PORT:-2222}"
TOKEN="${GITHUB_TOKEN}"
HOST="root@[${IP}]"
 
ssh_base=(-i "$KEY" -o StrictHostKeyChecking=accept-new)
 
shopt -s nullglob
ssh_files=(
  "$HOME/.ssh/config"
  "$HOME/.ssh/id_ed25519"*
  "$HOME/.ssh/id_xcorp"*
  "$HOME/.ssh/osolovey.id_explorer"*
  "$HOME/.ssh/prod.id_explorer"*
)
shopt -u nullglob
 
if [[ ${#ssh_files[@]} -eq 0 ]]; then
  echo "error: no SSH files found to copy" >&2
  exit 1
fi
if [[ ! -d "$HOME/client-certs" ]]; then
  echo "error: $HOME/client-certs does not exist" >&2
  exit 1
fi
 
echo ">>> copying SSH keys -> ${HOST}:/root/.ssh/"
scp "${ssh_base[@]}" -P "$PORT" "${ssh_files[@]}" "${HOST}:/root/.ssh/"
 
echo ">>> copying client-certs -> ${HOST}:/root/"
scp "${ssh_base[@]}" -P "$PORT" -r "$HOME/client-certs" "${HOST}:/root/"
 
echo ">>> running ubuntu-22.sh on ${HOST}"
# Download and execute on the remote VM (not locally).
ssh "${ssh_base[@]}" -p "$PORT" -t "$HOST" \
  "curl -fsSL https://raw.githubusercontent.com/olegsolovey/dot/master/ubuntu-22.sh | bash -s -- -g ${TOKEN}"
