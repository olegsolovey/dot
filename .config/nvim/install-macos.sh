#!/usr/bin/env bash
#
# macOS installer for this Neovim (LazyVim) configuration.
# Supports Apple Silicon and Intel Macs with the system Bash 3.2 and BSD tools.
# Runs without confirmation prompts; requires Homebrew and Xcode Command Line Tools.
#
# Installs Neovim, tree-sitter, buildifier, lazygit, dedicated Python tools,
# Rust via rustup, the adjacent configuration, pinned plugins, and Mason tools.
# Homebrew supplies git, cmake, ninja, ripgrep, fd, Python 3.13, and LLVM/clangd.
# Existing configurations are backed up; Vim and other dotfiles are left alone.
#
# Usage:
#   bash install-macos.sh [--skip-brew] [--skip-rust] [--skip-headless] [--force-nvim]
#   bash install-macos.sh --pack [SRC_DIR] > /tmp/nvim-install-macos.sh
#
# Options:
#   --skip-brew      Use existing dependencies without installing Homebrew packages.
#   --skip-rust      Leave the Rust toolchain unchanged.
#   --skip-headless  Skip plugin, Treesitter parser, and Mason installation.
#   --force-nvim     Reinstall the requested Neovim version, even if newer is present.
#
# Environment overrides:
#   NVIM_VERSION         (default v0.12.5)
#   TREE_SITTER_VERSION  (default 0.27.0)
#   BUILDIFIER_VERSION   (default 7.3.1)
#   LAZYGIT_VERSION      (default latest GitHub release, fallback 0.44.1)
#   PREFIX               (default ~/.local)
#   XDG_CONFIG_HOME, XDG_DATA_HOME (default ~/.config, ~/.local/share)
# PATH is added to ${ZDOTDIR:-$HOME}/.zshrc, or the active Bash login file.
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "${BASH_SOURCE[0]}")"

archive_config() {
  COPYFILE_DISABLE=1 tar -C "$1" \
    --exclude=./install.sh --exclude=./install-macos.sh \
    --exclude=./.git --exclude=./data --exclude=./debug \
    --exclude=./.tests --exclude=./.repro --exclude='./*.log' --exclude='./foo.*' --exclude='./tt.*' \
    -czf - .
}

# --pack is usable on either platform without installing anything.
if [[ "${1:-}" == "--pack" ]]; then
  src="${2:-$SCRIPT_DIR}"
  [[ -f "$src/init.lua" ]] || { echo "no init.lua in $src" >&2; exit 1; }
  sed -n '1,/^__PAYLOAD_BELOW__$/p' "$SCRIPT_PATH"
  archive_config "$src" | base64 | fold -w 76
  exit 0
fi

NVIM_VERSION="${NVIM_VERSION:-v0.12.5}"
TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-0.27.0}"
BUILDIFIER_VERSION="${BUILDIFIER_VERSION:-7.3.1}"
LAZYGIT_VERSION="${LAZYGIT_VERSION:-}"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PY_TOOLS="$DATA_DIR/python-tools"
PYTHON=python3
BREW_PREFIX=""

PY_PACKAGES=(
  "basedpyright==1.39.10"
  "ruff==0.16.5"
  "debugpy==1.8.21"
  "cmakelang==0.6.13"
  "clang-format==21.1.2"
)
PY_BINS=(basedpyright basedpyright-langserver ruff debugpy debugpy-adapter cmake-format cmake-lint clang-format)
MASON_PACKAGES=(codelldb lua-language-server neocmakelsp shfmt stylua)
TS_FALLBACK_PARSERS=(bash c cmake cpp cuda diff html javascript jsdoc json jsonc lua luadoc luap markdown markdown_inline ninja printf python query regex ron rst rust starlark toml tsx typescript vim vimdoc xml yaml)

SKIP_BREW=0 SKIP_RUST=0 SKIP_HEADLESS=0 FORCE_NVIM=0
for arg in "$@"; do
  case "$arg" in
    --skip-brew) SKIP_BREW=1 ;;
    --skip-rust) SKIP_RUST=1 ;;
    --skip-headless) SKIP_HEADLESS=1 ;;
    --force-nvim) FORCE_NVIM=1 ;;
    -h|--help) sed -n '2,30p' "$SCRIPT_PATH"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == "Darwin" ]] || die "this script supports macOS only; use install.sh on Linux"
case "$(uname -m)" in
  arm64)  NVIM_ARCH=arm64; TS_ARCH=arm64; BUILDIFIER_ARCH=arm64; LAZYGIT_ARCH=arm64; BREW_DEFAULT_PREFIX=/opt/homebrew ;;
  x86_64) NVIM_ARCH=x86_64; TS_ARCH=x64; BUILDIFIER_ARCH=amd64; LAZYGIT_ARCH=x86_64; BREW_DEFAULT_PREFIX=/usr/local ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

# Explicit settings also cover runs launched from an interactive terminal.
unset HOMEBREW_ASK INTERACTIVE
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1 PIP_NO_INPUT=1 GIT_TERMINAL_PROMPT=0
exec < /dev/null

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
export PATH="$BIN:$HOME/.cargo/bin:$PATH"

download() { # url dest
  curl -fsSL --retry 3 -o "$2" "$1"
}

github_latest_tag() { # owner/repo
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1
}

version_ge() { # dotted numeric versions; BSD sort has no -V
  awk -v a="$1" -v b="$2" 'BEGIN {
    n = split(a, x, "."); m = split(b, y, ".")
    for (i = 1; i <= n || i <= m; i++) {
      if (x[i] + 0 > y[i] + 0) exit 0
      if (x[i] + 0 < y[i] + 0) exit 1
    }
    exit 0
  }'
}

# ---------------------------------------------------------------------------
# 1. configuration staging and Homebrew dependencies
# ---------------------------------------------------------------------------
prepare_config() {
  if [[ -n "$(sed -n '/^__PAYLOAD_BELOW__$/{n;p;}' "$SCRIPT_PATH")" ]]; then
    sed -n '/^__PAYLOAD_BELOW__$/,$p' "$SCRIPT_PATH" | tail -n +2 | base64 -d >"$WORK_DIR/config.tar.gz"
  elif [[ -f "$SCRIPT_DIR/init.lua" ]]; then
    archive_config "$SCRIPT_DIR" >"$WORK_DIR/config.tar.gz"
  else
    die "no configuration alongside $SCRIPT_PATH; copy the whole config directory or use --pack"
  fi
  mkdir -p "$WORK_DIR/config"
  tar -xzf "$WORK_DIR/config.tar.gz" -C "$WORK_DIR/config"
  [[ -f "$WORK_DIR/config/init.lua" ]] || die "configuration extraction failed (no init.lua)"
  # Installed reruns use the current config rather than an old packed snapshot.
  sed -n '1,/^__PAYLOAD_BELOW__$/p' "$SCRIPT_PATH" >"$WORK_DIR/config/install-macos.sh"
  chmod +x "$WORK_DIR/config/install-macos.sh"
}

install_system_packages() {
  if ! have brew && [[ -x "$BREW_DEFAULT_PREFIX/bin/brew" ]]; then
    export PATH="$BREW_DEFAULT_PREFIX/bin:$PATH"
  fi
  if have brew; then
    BREW_PREFIX="$(brew --prefix)"
    export PATH="$BIN:$HOME/.cargo/bin:$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
  fi

  if [[ $SKIP_BREW -eq 1 ]]; then
    log "Skipping Homebrew packages (--skip-brew)"
  else
    have brew || die "Homebrew is required; install it from https://brew.sh or use --skip-brew with dependencies already installed"
    if ! xcode-select -p >/dev/null 2>&1 || ! xcrun --find clang >/dev/null 2>&1; then
      die "Xcode Command Line Tools are required; run xcode-select --install, then rerun this installer"
    fi
    log "Installing Homebrew dependencies"
    brew install --no-ask git cmake ninja ripgrep fd python@3.13 llvm
  fi

  if have brew; then
    local llvm python_prefix
    llvm="$(brew --prefix llvm 2>/dev/null || true)"
    # LLVM is keg-only; expose clangd without replacing Apple's compilers.
    if [[ -x "$llvm/bin/clangd" ]]; then
      mkdir -p "$BIN"
      ln -sfn "$llvm/bin/clangd" "$BIN/clangd"
    fi
    python_prefix="$(brew --prefix python@3.13 2>/dev/null || true)"
    if [[ -x "$python_prefix/bin/python3.13" ]]; then
      PYTHON="$python_prefix/bin/python3.13"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 2. Neovim and tree-sitter CLI
# ---------------------------------------------------------------------------
install_neovim() {
  mkdir -p "$BIN" "$PREFIX/opt"
  local want="${NVIM_VERSION#v}" current=""
  if [[ -x "$BIN/nvim" ]]; then
    current="$("$BIN/nvim" --version | sed -n 's/^NVIM v\([0-9.]*\).*/\1/p')"
  fi
  if [[ $FORCE_NVIM -eq 0 && -n "$current" ]] && version_ge "$current" "$want"; then
    ok "neovim $current already at $BIN/nvim"
    return
  fi
  log "Installing Neovim $NVIM_VERSION ($NVIM_ARCH)"
  local dest="$PREFIX/opt/nvim-$NVIM_VERSION"
  download "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-macos-$NVIM_ARCH.tar.gz" "$WORK_DIR/nvim.tar.gz"
  mkdir -p "$WORK_DIR/neovim"
  tar -xzf "$WORK_DIR/nvim.tar.gz" -C "$WORK_DIR/neovim" --strip-components=1
  "$WORK_DIR/neovim/bin/nvim" --version >/dev/null
  rm -rf "$dest"
  mv "$WORK_DIR/neovim" "$dest"
  ln -sfn "$dest/bin/nvim" "$BIN/nvim"
  ok "$("$BIN/nvim" --version | head -n1) -> $BIN/nvim"
}

install_tree_sitter() {
  if have tree-sitter && [[ "$(tree-sitter --version | awk '{print $2}')" == "$TREE_SITTER_VERSION" ]]; then
    ok "tree-sitter $TREE_SITTER_VERSION"
    return
  fi
  log "Installing tree-sitter CLI $TREE_SITTER_VERSION"
  local dest="$PREFIX/tree-sitter-cli/bin"
  download "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-macos-$TS_ARCH.gz" "$WORK_DIR/tree-sitter.gz"
  gzip -dc "$WORK_DIR/tree-sitter.gz" >"$WORK_DIR/tree-sitter"
  chmod +x "$WORK_DIR/tree-sitter"
  "$WORK_DIR/tree-sitter" --version >/dev/null
  mkdir -p "$dest"
  mv "$WORK_DIR/tree-sitter" "$dest/tree-sitter"
  ln -sfn "$dest/tree-sitter" "$BIN/tree-sitter"
  ok "$(tree-sitter --version)"
}

# ---------------------------------------------------------------------------
# 3. Python tools and Rust toolchain
# ---------------------------------------------------------------------------
install_python_tools() {
  log "Installing Python tools into $PY_TOOLS"
  if have uv; then
    [[ -x "$PY_TOOLS/bin/python" ]] || uv venv --quiet --python "$PYTHON" "$PY_TOOLS"
    uv pip install --quiet --python "$PY_TOOLS/bin/python" "${PY_PACKAGES[@]}"
  else
    have "$PYTHON" || die "python3 is required"
    [[ -x "$PY_TOOLS/bin/python" ]] || "$PYTHON" -m venv "$PY_TOOLS"
    if ! "$PY_TOOLS/bin/python" -m pip --version >/dev/null 2>&1; then
      "$PY_TOOLS/bin/python" -m ensurepip --upgrade
    fi
    "$PY_TOOLS/bin/python" -m pip install --quiet --upgrade pip
    "$PY_TOOLS/bin/python" -m pip install --quiet "${PY_PACKAGES[@]}"
  fi
  local b
  for b in "${PY_BINS[@]}"; do
    [[ -x "$PY_TOOLS/bin/$b" ]] || die "expected Python tool $PY_TOOLS/bin/$b"
    ln -sfn "$PY_TOOLS/bin/$b" "$BIN/$b"
  done
  ok "python tools: ${PY_BINS[*]}"
}

install_rust() {
  if [[ $SKIP_RUST -eq 1 ]]; then
    log "Skipping Rust toolchain (--skip-rust)"
    return
  fi
  if ! have rustup; then
    log "Installing rustup"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile default
    export PATH="$BIN:$HOME/.cargo/bin:$PATH"
  fi
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    log "Installing stable Rust toolchain"
    rustup default stable
  fi
  log "Ensuring Rust components"
  rustup component add rust-analyzer rust-src rustfmt clippy >/dev/null
  ok "rust: $(rustc --version)"
}

# ---------------------------------------------------------------------------
# 4. buildifier and lazygit
# ---------------------------------------------------------------------------
install_buildifier() {
  if have buildifier && [[ "$(buildifier --version 2>/dev/null | awk '/^buildifier version:/ {print $3}')" == "$BUILDIFIER_VERSION" ]]; then
    ok "buildifier $BUILDIFIER_VERSION"
    return
  fi
  log "Installing buildifier $BUILDIFIER_VERSION"
  download "https://github.com/bazelbuild/buildtools/releases/download/v$BUILDIFIER_VERSION/buildifier-darwin-$BUILDIFIER_ARCH" "$WORK_DIR/buildifier"
  chmod +x "$WORK_DIR/buildifier"
  "$WORK_DIR/buildifier" --version >/dev/null
  mv "$WORK_DIR/buildifier" "$BIN/buildifier"
  ok "$(buildifier --version | head -n1)"
}

install_lazygit() {
  if have lazygit; then
    local current
    current="$(lazygit --version | sed -n 's/.*version=\([^,]*\).*/\1/p')"
    if [[ -z "$LAZYGIT_VERSION" || "$current" == "${LAZYGIT_VERSION#v}" ]]; then
      ok "lazygit $current"
      return
    fi
  fi
  local ver="${LAZYGIT_VERSION:-$(github_latest_tag jesseduffield/lazygit || true)}"
  ver="${ver#v}"; ver="${ver:-0.44.1}"
  log "Installing lazygit $ver"
  local url="https://github.com/jesseduffield/lazygit/releases/download/v$ver"
  # Older releases capitalized Darwin in archive names.
  if download "$url/lazygit_${ver}_darwin_$LAZYGIT_ARCH.tar.gz" "$WORK_DIR/lazygit.tar.gz" \
    || download "$url/lazygit_${ver}_Darwin_$LAZYGIT_ARCH.tar.gz" "$WORK_DIR/lazygit.tar.gz"; then
    tar -xzf "$WORK_DIR/lazygit.tar.gz" -C "$WORK_DIR" lazygit
    install -m 755 "$WORK_DIR/lazygit" "$BIN/lazygit"
    ok "lazygit $ver"
  else
    warn "lazygit download failed; skipping (optional, used by <leader>gg)"
  fi
}

# ---------------------------------------------------------------------------
# 5. configuration and shell PATH
# ---------------------------------------------------------------------------
install_config() {
  log "Installing configuration into $CONFIG_DIR"
  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    local backup; backup="$(mktemp -d "$CONFIG_DIR.bak.$(date +%Y%m%d-%H%M%S).XXXXXX")"
    rmdir "$backup"
    mv "$CONFIG_DIR" "$backup"
    warn "existing config moved to $backup"
  fi
  mkdir -p "$CONFIG_DIR"
  cp -R "$WORK_DIR/config/." "$CONFIG_DIR/"
  ok "config: $(find "$CONFIG_DIR" -type f | wc -l) files"
}

ensure_path() {
  local rc="${ZDOTDIR:-$HOME}/.zshrc" line brew_path
  if [[ "${SHELL:-/bin/zsh}" == */bash ]]; then
    rc="$HOME/.bash_profile"
    if [[ ! -f "$rc" ]]; then
      if [[ -f "$HOME/.bash_login" ]]; then
        rc="$HOME/.bash_login"
      elif [[ -f "$HOME/.profile" ]]; then
        rc="$HOME/.profile"
      fi
    fi
  fi
  printf -v line 'export PATH=%q:"%s/.cargo/bin":' "$BIN" '$HOME'
  if [[ -n "$BREW_PREFIX" ]]; then
    printf -v brew_path '%q:%q:' "$BREW_PREFIX/bin" "$BREW_PREFIX/sbin"
    line="$line$brew_path"
  fi
  line="$line\"\$PATH\""
  if [[ -f "$rc" ]] && grep -Fxq "$line" "$rc"; then
    return
  fi
  mkdir -p "$(dirname -- "$rc")"
  printf '\n# added by nvim install-macos.sh\n%s\n' "$line" >>"$rc"
  warn "added Neovim tools to PATH in $rc; open a new shell or run: source \"$rc\""
}

# ---------------------------------------------------------------------------
# 6. headless bootstrap: plugins, Treesitter parsers, Mason packages
# ---------------------------------------------------------------------------
bootstrap_headless() {
  if [[ $SKIP_HEADLESS -eq 1 ]]; then
    log "Skipping headless bootstrap (--skip-headless)"
    return
  fi
  local nvim="$BIN/nvim" lua="$WORK_DIR/bootstrap.lua"
  log "Restoring plugins from lazy-lock.json"
  "$nvim" --headless "+Lazy! restore" \
    "+lua if require('lazy.manage.checker').has_errors() then vim.cmd.cquit() end" +qa < /dev/null

  cat >"$lua" <<'LUA'
local function fail(msg)
  io.stderr:write("bootstrap: " .. msg .. "\n")
  vim.cmd.cquit()
end

local ok_ts, err = pcall(function()
  require("lazy").load({ plugins = { "nvim-treesitter" } })
  local lazy_plugin = require("lazy.core.config").plugins["nvim-treesitter"]
  local opts = require("lazy.core.plugin").values(lazy_plugin, "opts", false)
  local langs = opts.ensure_installed
  if type(langs) ~= "table" or #langs == 0 then
    langs = vim.split(vim.env.TS_FALLBACK_PARSERS or "", " ", { trimempty = true })
  end
  local ts = require("nvim-treesitter")
  local installed, seen, missing = {}, {}, {}
  for _, l in ipairs(ts.get_installed()) do installed[l] = true end
  for _, l in ipairs(langs) do
    if not installed[l] and not seen[l] then
      seen[l] = true
      missing[#missing + 1] = l
    end
  end
  if #missing > 0 then
    print("treesitter: installing " .. table.concat(missing, " "))
    ts.install(missing, { summary = true }):wait(30 * 60 * 1000)
    installed = {}
    for _, l in ipairs(ts.get_installed()) do installed[l] = true end
    for _, l in ipairs(missing) do
      if not installed[l] then error("parser not installed: " .. l) end
    end
  end
  print("treesitter: all " .. #langs .. " parsers present")
end)
if not ok_ts then fail("treesitter: " .. tostring(err)) end

local ok_mason, merr = pcall(function()
  require("lazy").load({ plugins = { "mason.nvim" } })
  local registry = require("mason-registry")
  local refreshed = false
  registry.refresh(function() refreshed = true end)
  if not vim.wait(60 * 1000, function() return refreshed end, 100) then
    error("timed out refreshing Mason registry")
  end
  local want = vim.split(vim.env.MASON_PACKAGES or "", " ", { trimempty = true })
  local pending, failed = 0, {}
  for _, name in ipairs(want) do
    local pkg = registry.get_package(name)
    local installing = pkg:is_installing()
    if not installing and pkg:is_installed() and vim.uv.fs_stat(vim.fn.stdpath("data") .. "/mason/bin/" .. name) then
      print("mason: " .. name .. " present")
    else
      pending = pending + 1
      local function complete(success, result)
        pending = pending - 1
        if success then
          print("mason: " .. name .. " installed")
        else
          failed[#failed + 1] = name .. " (" .. tostring(result) .. ")"
        end
      end
      if installing then
        print("mason: waiting for " .. name)
        -- Automatic installs can already be running; handle closure precedes the final result.
        pkg:once("install:success", function(result) complete(true, result) end)
        pkg:once("install:failed", function(result) complete(false, result) end)
      else
        print("mason: installing " .. name)
        pkg:install({ force = true }, complete)
      end
    end
  end
  local done = vim.wait(30 * 60 * 1000, function() return pending == 0 end, 500)
  if not done then error("timed out waiting for mason packages") end
  if #failed > 0 then error("failed: " .. table.concat(failed, ", ")) end
end)
if not ok_mason then fail("mason: " .. tostring(merr)) end
LUA

  log "Installing Treesitter parsers and Mason packages"
  TS_FALLBACK_PARSERS="${TS_FALLBACK_PARSERS[*]}" MASON_PACKAGES="${MASON_PACKAGES[*]}" \
    NVIM_BOOTSTRAP_LUA="$lua" "$nvim" --headless -c 'lua dofile(vim.env.NVIM_BOOTSTRAP_LUA)' -c qa < /dev/null
  ok "plugins, parsers, Mason packages"
}

summary() {
  log "Summary"
  local t m
  for t in nvim git rg fd clangd tree-sitter basedpyright-langserver ruff debugpy-adapter clang-format cmake-format cmake-lint buildifier rustup rust-analyzer rustfmt lazygit; do
    if have "$t"; then ok "$t -> $(command -v "$t")"; else warn "$t missing"; fi
  done
  for m in "${MASON_PACKAGES[@]}"; do
    if [[ -e "$DATA_DIR/mason/bin/$m" ]]; then ok "mason: $m"; else warn "mason: $m missing"; fi
  done
  have bazel || warn "bazel not found (only needed for the Bazel overseer tasks)"
  echo
  echo "Done. Start with: nvim"
}

prepare_config
install_system_packages
install_neovim
install_tree_sitter
install_python_tools
install_rust
install_buildifier
install_lazygit
install_config
ensure_path
bootstrap_headless
summary
exit 0

__PAYLOAD_BELOW__
