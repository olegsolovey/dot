#!/bin/bash
#
# Invoke without cloning:
#   curl -fsSL https://raw.githubusercontent.com/olegsolovey/dot/master/ubuntu-22.sh | bash -s -- -g <github-token>
#
# Safe to re-run. SSH keys for git@github.com must already be in ~/.ssh
# (bootstrap-remote.sh copies them). Outbound TCP/22 to github.com is often
# blocked; this script uses ssh.github.com:443 when that rewrite is missing.

set -euo pipefail

usage() {
  echo "Usage: $0 -g <github-token>"
  echo "  -g  Git token for github.com"
  exit 1
}

# Child processes must not read the script when this is invoked as `curl | bash`.
run() {
  "$@" < /dev/null
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    run "$@"
  elif command -v sudo >/dev/null 2>&1; then
    # -n and a closed stdin: sudo must not prompt, and must not eat the piped script.
    sudo -n "$@" < /dev/null
  else
    echo "error: need root or passwordless sudo to run: $*" >&2
    exit 1
  fi
}

log() {
  printf '>>> %s\n' "$*"
}

GH_TOKEN=""

while getopts "g:" opt; do
  case $opt in
    g) GH_TOKEN="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$GH_TOKEN" || "$GH_TOKEN" == "TOKEN_HERE" ]]; then
  echo "Error: -g <github-token> is required."
  usage
fi

export DEBIAN_FRONTEND=noninteractive
export GIT_TERMINAL_PROMPT=0
export LANG="${LANG:-C.UTF-8}"
export PATH="/usr/local/bin:${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

log "installing base packages"
as_root apt-get update
as_root apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  gettext \
  git \
  libffi-dev \
  libncurses-dev \
  libssl-dev \
  openssh-client \
  pkg-config \
  python-is-python3 \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  rsync \
  tmux \
  unzip \
  wget

# Write credentials before xtrace so the token is not printed.
# Restore umask afterwards: umask 077 would make `make install` drop
# the other-user execute bit on /usr/local/bin/vim.
cred="${HOME}/.git-credentials"
old_umask="$(umask)"
umask 077
touch "$cred"
{
  grep -v 'github.com' "$cred" 2>/dev/null || true
  printf 'https://olegsolovey:%s@github.com\n' "$GH_TOKEN"
} > "${cred}.new"
mv "${cred}.new" "$cred"
chmod 600 "$cred"
umask "$old_umask"
unset GH_TOKEN

set -x

# Re-apply after the dotfile rsync; the repo .gitconfig hardcodes /root.
apply_git_credentials() {
  run git config --global --replace-all credential.helper "store --file=${HOME}/.git-credentials"
}

apply_git_credentials

workdir="$(mktemp -d)"
log "cloning dotfiles into ${workdir}"
run git clone --depth 1 https://github.com/olegsolovey/dot.git "${workdir}/dot"

# Neovim's installer backs up and installs ~/.config/nvim itself.
run rsync -a \
  --exclude='.git' \
  --exclude='.git-credentials' \
  --exclude='.config/nvim' \
  "${workdir}/dot/" "${HOME}/"
apply_git_credentials

install_rust() {
  if [[ ! -x "${HOME}/.cargo/bin/rustup" ]]; then
    log "installing rustup"
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path --default-toolchain none
  fi
  if [[ -f "${HOME}/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "${HOME}/.cargo/env"
  fi
  export PATH="${HOME}/.cargo/bin:${PATH}"

  local attempt
  for attempt in 1 2 3; do
    # Interrupted rustup downloads leave a corrupt cache; the next install then fails.
    rm -rf "${HOME}/.rustup/downloads" "${HOME}/.rustup/tmp"
    if run rustup toolchain install 1.94.0 --profile minimal \
      --component rust-analyzer,rust-src,clippy,rustfmt; then
      run rustup default 1.94.0
      return 0
    fi
    echo "rustup toolchain install failed (attempt ${attempt}/3)" >&2
    sleep 2
  done
  return 1
}

install_rust

log "installing neovim config"
# Rust is pinned above. Do not let the Neovim installer pull stable over it.
run bash "${workdir}/dot/.config/nvim/install.sh" --skip-rust
rm -rf "${workdir}/dot"

install_tmux_plugins() {
  mkdir -p "${HOME}/.tmux/plugins"
  if [[ ! -d "${HOME}/.tmux/plugins/tpm/.git" ]]; then
    rm -rf "${HOME}/.tmux/plugins/tpm"
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
  fi
  # install_plugins reads TMUX_PLUGIN_MANAGER_PATH from the running server.
  # start-server does not reload a server that was started before ~/.tmux.conf
  # existed, so the variable is missing and TPM aborts.
  run tmux start-server
  run tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "${HOME}/.tmux/plugins/"
  run "${HOME}/.tmux/plugins/tpm/bin/install_plugins"
  run tmux source-file "${HOME}/.tmux.conf"
}

install_tmux_plugins

install_vim() {
  if [[ -x /usr/local/bin/vim ]] && /usr/local/bin/vim --version 2>/dev/null | grep -q '+python3'; then
    log "vim already installed at /usr/local/bin/vim with +python3"
    return 0
  fi

  log "building vim with python3"
  run git clone --depth 1 https://github.com/vim/vim.git "${workdir}/vim"
  (
    cd "${workdir}/vim"
    # Explicit configure: the Makefile sed can miss the flag and still "succeed"
    # without +python3. Pin the system interpreter so a venv on PATH is not linked in.
    run ./configure \
      --prefix=/usr/local \
      --with-features=huge \
      --enable-multibyte \
      --enable-python3interp=dynamic \
      --with-python3-command=/usr/bin/python3 \
      --enable-fail-if-missing
    run make -j"$(nproc)"
    as_root make install
  )
  rm -rf "${workdir}/vim"
  hash -r
  /usr/local/bin/vim --version | grep -q '+python3'
}

install_vim
ln -sfn "${HOME}/.vim/vimrc" "${HOME}/.vimrc"
mkdir -p "${HOME}/.vim/tmp" "${HOME}/.vim/bundle"

if [[ ! -d "${HOME}/.vim/bundle/Vundle.vim/.git" ]]; then
  rm -rf "${HOME}/.vim/bundle/Vundle.vim"
  run git clone --depth 1 https://github.com/VundleVim/Vundle.vim "${HOME}/.vim/bundle/Vundle.vim"
fi

# -es (silent ex mode) exits on the first vimrc warning and never installs plugins.
# --not-a-term works with no tty and still runs :PluginInstall to completion.
log "installing vim plugins"
run vim --not-a-term -u "${HOME}/.vimrc" -c 'set nomore' -c 'PluginInstall' -c 'qa!'
if [[ ! -d "${HOME}/.vim/bundle/molokai" ]]; then
  echo "error: vim PluginInstall did not install plugins" >&2
  exit 1
fi

ensure_github_ssh() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  touch "${HOME}/.ssh/known_hosts"
  chmod 600 "${HOME}/.ssh/known_hosts"

  local host port identity
  host="$(ssh -G github.com 2>/dev/null | awk '$1 == "hostname" { print $2; exit }')"
  port="$(ssh -G github.com 2>/dev/null | awk '$1 == "port" { print $2; exit }')"
  # First matching Host block wins, so prepend. Skip when github.com is already :443.
  if [[ "$host" != "ssh.github.com" || "$port" != "443" ]]; then
    if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
      identity="${HOME}/.ssh/id_ed25519"
    elif [[ -f "${HOME}/.ssh/id_rsa" ]]; then
      identity="${HOME}/.ssh/id_rsa"
    else
      echo "error: no SSH key in ~/.ssh (expected id_ed25519); cannot clone xai-org/xai" >&2
      exit 1
    fi
    if ! grep -q 'Added by ubuntu-22.sh' "${HOME}/.ssh/config" 2>/dev/null; then
      local tmpcfg
      tmpcfg="$(mktemp)"
      cat > "$tmpcfg" <<EOF
# Added by ubuntu-22.sh. TCP/22 to github.com is often blocked.
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ${identity}
  IdentitiesOnly yes

EOF
      if [[ -f "${HOME}/.ssh/config" ]]; then
        cat "${HOME}/.ssh/config" >> "$tmpcfg"
      fi
      mv "$tmpcfg" "${HOME}/.ssh/config"
      chmod 600 "${HOME}/.ssh/config"
    fi
  fi

  # Port 22 keyscan hangs on networks that drop it; bound both lookups.
  if ! ssh-keygen -F ssh.github.com >/dev/null 2>&1; then
    ssh-keyscan -T 5 -p 443 -t ed25519,rsa ssh.github.com >> "${HOME}/.ssh/known_hosts" || true
  fi
  if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    ssh-keyscan -T 5 -t ed25519,rsa github.com >> "${HOME}/.ssh/known_hosts" || true
  fi
  chmod 600 "${HOME}/.ssh/known_hosts"
}

ensure_github_ssh

clone_xai() {
  local dest="${HOME}/workspace/xai"
  mkdir -p "${HOME}/workspace"
  if [[ -d "$dest" && ! -d "$dest/.git" ]]; then
    echo "removing incomplete clone at ${dest}" >&2
    rm -rf "$dest"
  fi
  # BatchMode: fail instead of prompting (no tty under curl | bash).
  # accept-new: record the host key instead of hanging on the yes/no prompt.
  export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
  # GitHub exits 1 even when auth succeeds ("does not provide shell access").
  local auth
  auth="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com < /dev/null 2>&1 || true)"
  if [[ "$auth" != *"successfully authenticated"* ]]; then
    echo "error: GitHub SSH auth failed; cannot clone xai-org/xai" >&2
    echo "$auth" >&2
    exit 1
  fi
  if [[ ! -d "$dest/.git" ]]; then
    local attempt
    for attempt in 1 2; do
      if run git clone --single-branch --branch main git@github.com:xai-org/xai.git "$dest"; then
        break
      fi
      if [[ "$attempt" -eq 2 ]]; then
        echo "error: failed to clone xai-org/xai" >&2
        exit 1
      fi
      rm -rf "$dest"
      echo "xai clone failed (attempt ${attempt}/2), retrying" >&2
      sleep 2
    done
  else
    log "${dest} already cloned"
  fi
  run git -C "$dest" submodule update --init --recursive --jobs "$(nproc)"
}

clone_xai

# ~/.bashrc returns immediately when this script is non-interactive, so sourcing
# it does not apply PATH. Cargo and local bins are exported above instead.
if [[ -n "${TMUX:-}" ]]; then
  run tmux source-file "${HOME}/.tmux.conf"
fi

rm -rf "$workdir"
hash -r

set +x
log "ubuntu-22.sh finished"
command -v vim
command -v nvim
rustc --version
rustup show active-toolchain
echo "xai: ${HOME}/workspace/xai"
