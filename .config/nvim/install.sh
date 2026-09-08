#!/usr/bin/env bash
#
# Linux installer for this Neovim (LazyVim) configuration.
#
# The configuration is tracked alongside this script. Use --pack to embed it
# in a self-contained installer that can be copied to a fresh machine.
# It installs:
#
#   - Neovim (pinned release, into ~/.local/opt, symlinked at ~/.local/bin/nvim)
#   - system packages needed by the plugins (git, compilers, ripgrep, fd, clangd, ...)
#   - tree-sitter CLI (needed by nvim-treesitter's main branch to build parsers)
#   - a dedicated Python venv with basedpyright, ruff, debugpy, cmakelang, clang-format
#   - Rust toolchain via rustup with rust-analyzer, rustfmt, clippy, rust-src
#   - buildifier and lazygit from GitHub releases
#   - the configuration into ~/.config/nvim (existing config is backed up)
#   - all plugins at the commits pinned in lazy-lock.json (headless `Lazy! restore`)
#   - all Treesitter parsers and Mason packages (headless)
#
# Usage:
#   ./install.sh [--skip-apt] [--skip-rust] [--skip-headless] [--force-nvim]
#   ./install.sh --pack [SRC_DIR] > /tmp/nvim-install.sh   # defaults to the adjacent config
#
# Environment overrides:
#   NVIM_VERSION      (default v0.12.5)
#   TREE_SITTER_VERSION (default 0.27.0)
#   BUILDIFIER_VERSION  (default 7.3.1)
#   LAZYGIT_VERSION     (default: latest GitHub release, fallback 0.44.1)
#   PREFIX              (default ~/.local)
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename -- "${BASH_SOURCE[0]}")"

archive_config() {
  COPYFILE_DISABLE=1 tar -C "$1" \
    --exclude=./install.sh --exclude=./.git --exclude=./data --exclude=./debug \
    --exclude=./.tests --exclude=./.repro --exclude='./*.log' --exclude='./foo.*' --exclude='./tt.*' \
    -czf - .
}

# ---------------------------------------------------------------------------
# --pack: emit a copy of this script with a fresh payload built from SRC_DIR
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--pack" ]]; then
  src="${2:-$SCRIPT_DIR}"
  [[ -f "$src/init.lua" ]] || { echo "no init.lua in $src" >&2; exit 1; }
  sed -n '1,/^__PAYLOAD_BELOW__$/p' "$SCRIPT_PATH"
  archive_config "$src" | base64 | fold -w 76
  exit 0
fi

# ---------------------------------------------------------------------------
# settings
# ---------------------------------------------------------------------------
NVIM_VERSION="${NVIM_VERSION:-v0.12.5}"
TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-0.27.0}"
BUILDIFIER_VERSION="${BUILDIFIER_VERSION:-7.3.1}"
LAZYGIT_VERSION="${LAZYGIT_VERSION:-}"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PY_TOOLS="$DATA_DIR/python-tools"

# Python packages installed into the dedicated venv.
PY_PACKAGES=(
  "basedpyright==1.39.10"
  "ruff==0.16.5"
  "debugpy==1.8.21"
  "cmakelang==0.6.13"
  "clang-format==21.1.2"
)
PY_BINS=(basedpyright basedpyright-langserver ruff debugpy debugpy-adapter cmake-format cmake-lint clang-format)

# Mason packages the config expects (everything else is `mason = false` and taken from PATH).
MASON_PACKAGES=(codelldb lua-language-server neocmakelsp shfmt stylua)

# Fallback parser list if it cannot be read from the config at runtime.
TS_FALLBACK_PARSERS=(bash c cmake cpp cuda diff html javascript jsdoc json jsonc lua luadoc luap markdown markdown_inline ninja printf python query regex ron rst rust starlark toml tsx typescript vim vimdoc xml yaml)

SKIP_APT=0 SKIP_RUST=0 SKIP_HEADLESS=0 FORCE_NVIM=0
for arg in "$@"; do
  case "$arg" in
    --skip-apt) SKIP_APT=1 ;;
    --skip-rust) SKIP_RUST=1 ;;
    --skip-headless) SKIP_HEADLESS=1 ;;
    --force-nvim) FORCE_NVIM=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

SUDO=""
if [[ $EUID -ne 0 ]]; then
  have sudo && SUDO="sudo"
fi

case "$(uname -m)" in
  x86_64)  NVIM_ARCH=x86_64; TS_ARCH=x64;   BUILDIFIER_ARCH=amd64; LAZYGIT_ARCH=x86_64 ;;
  aarch64) NVIM_ARCH=arm64;  TS_ARCH=arm64; BUILDIFIER_ARCH=arm64; LAZYGIT_ARCH=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac
[[ "$(uname -s)" == "Linux" ]] || die "this script supports Linux only"

mkdir -p "$BIN" "$PREFIX/opt"
export PATH="$BIN:$HOME/.cargo/bin:$PATH"

download() { # url dest
  curl -fsSL --retry 3 -o "$2" "$1"
}

github_latest_tag() { # owner/repo
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1
}

version_ge() { # a b  -> true if a >= b (dotted numeric)
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# ---------------------------------------------------------------------------
# 1. system packages
# ---------------------------------------------------------------------------
install_system_packages() {
  if [[ $SKIP_APT -eq 1 ]]; then
    log "Skipping system packages (--skip-apt)"
    return
  fi
  if ! have apt-get; then
    warn "apt-get not found; install these manually: git curl tar gzip unzip build-essential cmake ninja ripgrep fd clangd python3 python3-venv"
    return
  fi
  log "Installing system packages"
  local pkgs=(git curl ca-certificates tar gzip unzip xz-utils build-essential cmake ninja-build
              ripgrep fd-find python3 python3-venv python3-pip clangd clang-format)
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq "${pkgs[@]}"
  # Debian/Ubuntu ship fd as fdfind.
  if ! have fd && have fdfind; then
    ln -sfn "$(command -v fdfind)" "$BIN/fd"
  fi
  ok "system packages"
}

# ---------------------------------------------------------------------------
# 2. Neovim
# ---------------------------------------------------------------------------
install_neovim() {
  local want="${NVIM_VERSION#v}"
  local current=""
  if [[ -x "$BIN/nvim" ]]; then
    current="$("$BIN/nvim" --version | sed -n 's/^NVIM v\([0-9.]*\).*/\1/p')"
  fi
  if [[ $FORCE_NVIM -eq 0 && -n "$current" ]] && version_ge "$current" "$want"; then
    ok "neovim $current already at $BIN/nvim"
    return
  fi
  log "Installing Neovim $NVIM_VERSION"
  local dest="$PREFIX/opt/nvim-$NVIM_VERSION"
  local tmp; tmp="$(mktemp -d)"
  download "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-linux-$NVIM_ARCH.tar.gz" "$tmp/nvim.tar.gz"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar -xzf "$tmp/nvim.tar.gz" -C "$dest" --strip-components=1
  rm -rf "$tmp"
  ln -sfn "$dest/bin/nvim" "$BIN/nvim"
  ok "$("$BIN/nvim" --version | head -n1) -> $BIN/nvim"
}

# ---------------------------------------------------------------------------
# 3. tree-sitter CLI
# ---------------------------------------------------------------------------
install_tree_sitter() {
  if have tree-sitter && [[ "$(tree-sitter --version | awk '{print $2}')" == "$TREE_SITTER_VERSION" ]]; then
    ok "tree-sitter $TREE_SITTER_VERSION"
    return
  fi
  log "Installing tree-sitter CLI $TREE_SITTER_VERSION"
  local dest="$PREFIX/tree-sitter-cli/bin"
  mkdir -p "$dest"
  download "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-linux-$TS_ARCH.gz" "$dest/tree-sitter.gz"
  gunzip -f "$dest/tree-sitter.gz"
  chmod +x "$dest/tree-sitter"
  ln -sfn "$dest/tree-sitter" "$BIN/tree-sitter"
  ok "tree-sitter $(tree-sitter --version)"
}

# ---------------------------------------------------------------------------
# 4. Python tools (basedpyright, ruff, debugpy, cmake-format, clang-format)
# ---------------------------------------------------------------------------
install_python_tools() {
  log "Installing Python tools into $PY_TOOLS"
  if have uv; then
    [[ -x "$PY_TOOLS/bin/python" ]] || uv venv --quiet "$PY_TOOLS"
    uv pip install --quiet --python "$PY_TOOLS/bin/python" "${PY_PACKAGES[@]}"
  else
    have python3 || die "python3 is required"
    [[ -x "$PY_TOOLS/bin/python" ]] || python3 -m venv "$PY_TOOLS"
    "$PY_TOOLS/bin/python" -m pip install --quiet --upgrade pip
    "$PY_TOOLS/bin/python" -m pip install --quiet "${PY_PACKAGES[@]}"
  fi
  local b
  for b in "${PY_BINS[@]}"; do
    [[ -x "$PY_TOOLS/bin/$b" ]] || { warn "expected $PY_TOOLS/bin/$b"; continue; }
    ln -sfn "$PY_TOOLS/bin/$b" "$BIN/$b"
  done
  ok "python tools: ${PY_BINS[*]}"
}

# ---------------------------------------------------------------------------
# 5. Rust toolchain
# ---------------------------------------------------------------------------
install_rust() {
  if [[ $SKIP_RUST -eq 1 ]]; then
    log "Skipping Rust toolchain (--skip-rust)"
    return
  fi
  if ! have rustup; then
    log "Installing rustup"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile default
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    log "Installing stable Rust toolchain"
    rustup default stable
  fi
  log "Ensuring Rust components"
  rustup component add rust-analyzer rust-src rustfmt clippy >/dev/null
  ok "rust: $(rustc --version), rust-analyzer $(rust-analyzer --version 2>/dev/null | awk '{print $2}')"
}

# ---------------------------------------------------------------------------
# 6. buildifier, lazygit
# ---------------------------------------------------------------------------
install_buildifier() {
  if have buildifier && buildifier --version 2>/dev/null | grep -q "version: $BUILDIFIER_VERSION"; then
    ok "buildifier $BUILDIFIER_VERSION"
    return
  fi
  log "Installing buildifier $BUILDIFIER_VERSION"
  download "https://github.com/bazelbuild/buildtools/releases/download/v$BUILDIFIER_VERSION/buildifier-linux-$BUILDIFIER_ARCH" "$BIN/buildifier"
  chmod +x "$BIN/buildifier"
  ok "buildifier $(buildifier --version | head -n1)"
}

install_lazygit() {
  if have lazygit; then
    ok "lazygit $(lazygit --version | sed -n 's/.*version=\([^,]*\).*/\1/p')"
    return
  fi
  local ver="${LAZYGIT_VERSION:-$(github_latest_tag jesseduffield/lazygit)}"
  ver="${ver#v}"; ver="${ver:-0.44.1}"
  log "Installing lazygit $ver"
  local tmp; tmp="$(mktemp -d)"
  if download "https://github.com/jesseduffield/lazygit/releases/download/v$ver/lazygit_${ver}_Linux_$LAZYGIT_ARCH.tar.gz" "$tmp/lazygit.tar.gz"; then
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    install -m 755 "$tmp/lazygit" "$BIN/lazygit"
    ok "lazygit $ver"
  else
    warn "lazygit download failed; skipping (optional, used by <leader>gg)"
  fi
  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# 7. configuration
# ---------------------------------------------------------------------------
install_config() {
  log "Installing configuration into $CONFIG_DIR"
  local tmp; tmp="$(mktemp -d)"
  # Stage the source before backing up a config that may contain this installer.
  if [[ -n "$(sed -n '/^__PAYLOAD_BELOW__$/{n;p;}' "$SCRIPT_PATH")" ]]; then
    sed -n '/^__PAYLOAD_BELOW__$/,$p' "$SCRIPT_PATH" | tail -n +2 | base64 -d >"$tmp/config.tar.gz"
  elif [[ -f "$SCRIPT_DIR/init.lua" ]]; then
    archive_config "$SCRIPT_DIR" >"$tmp/config.tar.gz"
  else
    die "no configuration alongside $SCRIPT_PATH; copy the whole config directory or use --pack"
  fi
  mkdir -p "$tmp/config"
  tar -xzf "$tmp/config.tar.gz" -C "$tmp/config"
  [[ -f "$tmp/config/init.lua" ]] || die "configuration extraction failed (no init.lua)"
  cp "$SCRIPT_PATH" "$tmp/config/install.sh"
  chmod +x "$tmp/config/install.sh"
  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    local backup; backup="$(mktemp -d "$CONFIG_DIR.bak.$(date +%Y%m%d-%H%M%S).XXXXXX")"
    rmdir "$backup"
    mv "$CONFIG_DIR" "$backup"
    warn "existing config moved to $backup"
  fi
  mkdir -p "$CONFIG_DIR"
  cp -R "$tmp/config/." "$CONFIG_DIR/"
  rm -rf "$tmp"
  ok "config: $(find "$CONFIG_DIR" -type f | wc -l) files"
}

# ---------------------------------------------------------------------------
# 8. headless bootstrap: plugins, treesitter parsers, mason packages
# ---------------------------------------------------------------------------
bootstrap_headless() {
  if [[ $SKIP_HEADLESS -eq 1 ]]; then
    log "Skipping headless bootstrap (--skip-headless)"
    return
  fi
  local nvim="$BIN/nvim"

  log "Restoring plugins from lazy-lock.json"
  "$nvim" --headless "+Lazy! restore" +qa

  local lua; lua="$(mktemp --suffix=.lua)"
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
  local installed, seen, missing = {}, {}, {}
  for _, l in ipairs(require("nvim-treesitter").get_installed()) do installed[l] = true end
  for _, l in ipairs(langs) do
    if not installed[l] and not seen[l] then
      seen[l] = true
      missing[#missing + 1] = l
    end
  end
  if #missing == 0 then
    print("treesitter: all " .. #langs .. " parsers present")
    return
  end
  print("treesitter: installing " .. table.concat(missing, " "))
  require("nvim-treesitter").install(missing, { summary = true }):wait(30 * 60 * 1000)
end)
if not ok_ts then fail("treesitter: " .. tostring(err)) end

local ok_mason, merr = pcall(function()
  require("lazy").load({ plugins = { "mason.nvim" } })
  local registry = require("mason-registry")
  registry.refresh()
  local want = vim.split(vim.env.MASON_PACKAGES or "", " ", { trimempty = true })
  -- Package:is_installed() only checks that the package directory exists, which is true
  -- as soon as an install starts, so completion is tracked via the install callback.
  local pending, failed = 0, {}
  for _, name in ipairs(want) do
    local pkg = registry.get_package(name)
    if pkg:is_installed() and vim.uv.fs_stat(vim.fn.stdpath("data") .. "/mason/bin/" .. name) then
      print("mason: " .. name .. " present")
    else
      print("mason: installing " .. name)
      pending = pending + 1
      pkg:install({ force = true }, function(success, result)
        pending = pending - 1
        if success then
          print("mason: " .. name .. " installed")
        else
          failed[#failed + 1] = name .. " (" .. tostring(result) .. ")"
        end
      end)
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
    "$nvim" --headless -c "luafile $lua" -c qa
  rm -f "$lua"
  ok "plugins, parsers, mason packages"
}

# ---------------------------------------------------------------------------
# 9. PATH in ~/.bashrc
# ---------------------------------------------------------------------------
ensure_path() {
  local rc="$HOME/.bashrc"
  local line='export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"'
  if [[ "$PREFIX" != "$HOME/.local" ]]; then
    printf -v line 'export PATH=%q:"$HOME/.cargo/bin:$PATH"' "$BIN"
  fi
  if [[ -f "$rc" ]] && grep -Fxq "$line" "$rc"; then
    return
  fi
  printf '\n# added by nvim install.sh\n%s\n' "$line" >>"$rc"
  warn "added $BIN and ~/.cargo/bin to PATH in $rc; open a new shell or run: source $rc"
}

# ---------------------------------------------------------------------------
# 10. summary
# ---------------------------------------------------------------------------
summary() {
  log "Summary"
  local t
  for t in nvim git rg fd clangd tree-sitter basedpyright-langserver ruff debugpy-adapter clang-format cmake-format cmake-lint buildifier rustup rust-analyzer rustfmt lazygit; do
    if have "$t"; then ok "$t -> $(command -v "$t")"; else warn "$t missing"; fi
  done
  local m
  for m in "${MASON_PACKAGES[@]}"; do
    if [[ -e "$DATA_DIR/mason/bin/$m" ]]; then ok "mason: $m"; else warn "mason: $m missing"; fi
  done
  have cuda-gdb || warn "cuda-gdb not found (part of the CUDA toolkit; only needed for GPU debugging)"
  have bazel   || warn "bazel not found (only needed for the Bazel overseer tasks)"
  echo
  echo "Done. Start with: nvim"
}

install_system_packages
install_neovim
install_tree_sitter
install_python_tools
install_rust
install_buildifier
install_lazygit
install_config
bootstrap_headless
ensure_path
summary
exit 0

__PAYLOAD_BELOW__
