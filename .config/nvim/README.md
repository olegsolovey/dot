# Neovim development guide

This configuration is based on LazyVim and is set up for Python, Rust, C, C++, CUDA, CMake, and Bazel projects. The leader key is **Space**. Leader shortcuts are pressed sequentially: press `Space`, release it, then press the remaining keys.

## Installation

### Linux

On Ubuntu 22, the repo's `ubuntu-22.sh -g <github-token>` runs this installer before the existing Vim setup. It installs Neovim, system dependencies, Python and Rust tools, buildifier, lazygit, the pinned plugins, Treesitter parsers, and Mason packages.

To install only Neovim from a checkout:

```bash
bash .config/nvim/install.sh
```

The installer supports Linux x86_64 and aarch64. It uses `sudo` for system packages when needed; the editor and language tools are installed for the current user. Neovim defaults to `~/.local/bin/nvim`, and the config defaults to `~/.config/nvim`. Existing config directories or symlinks are moved to a uniquely named `nvim.bak.*` sibling before replacement. Vim and its config remain available.

Options:

- `--skip-apt`: leave system packages unchanged.
- `--skip-rust`: leave the Rust toolchain unchanged.
- `--skip-headless`: skip plugin, parser, and Mason installation.
- `--force-nvim`: reinstall the requested Neovim release even if a newer version is present.

`NVIM_VERSION`, `TREE_SITTER_VERSION`, `BUILDIFIER_VERSION`, and `LAZYGIT_VERSION` override release versions. `PREFIX` overrides `~/.local`; `XDG_CONFIG_HOME` and `XDG_DATA_HOME` override the config and data roots. The installer adds its binaries to `~/.bashrc`; open a new shell after installation.

The Lua files and `lazy-lock.json` in this directory are the configuration source. To create a portable single-file installer, run this from a checkout on Linux or macOS:

```bash
bash .config/nvim/install.sh --pack > /tmp/nvim-install.sh
# Copy /tmp/nvim-install.sh to a Linux machine, then run it with bash.
```

An optional directory after `--pack` selects another config source. Write the output outside that source directory. Without an embedded archive, `install.sh` needs the adjacent config files; copying only the unpacked script is insufficient.

If an older installer fails during Mason setup with `Package is already installing.`, rerun from a checkout containing the fix (or regenerate the packed installer). The bootstrap waits for packages already being installed by the configuration and reuses completed installations; there is no need to delete Neovim's data directory. Since system packages and Rust were set up before this stage, you can retry with:

```bash
bash .config/nvim/install.sh --skip-apt --skip-rust
```

### macOS

Use the separate macOS installer on Apple Silicon (`arm64`) or Intel (`x86_64`):

```bash
# Complete Apple's installer if the Command Line Tools are not already installed.
xcode-select --install
# Install Homebrew from https://brew.sh if needed, then run from this checkout:
bash .config/nvim/install-macos.sh
```

The installer runs without confirmation prompts, including Homebrew's default install approval. It disables interactive input for installation steps, pip prompts, and Git terminal credential prompts; rustup already runs with `-y`. No extra flag is needed, even when launched from a terminal. Failures stop the installer rather than waiting for approval.

Homebrew and Xcode Command Line Tools must already be available. If either is missing, the installer exits with instructions instead of opening an installation dialog or asking for a password. Initial macOS administrator authorization and Xcode license acceptance cannot be bypassed by this script.

Run it as your normal user, not with `sudo`. On Apple Silicon, use a native terminal with native Homebrew rather than mixing it with an Intel/Rosetta installation. The macOS release must be supported by both Homebrew and the requested Neovim binaries.

Homebrew provides Git, CMake, Ninja, ripgrep, fd, Python 3.13, and LLVM. Neovim, tree-sitter, buildifier, and lazygit use macOS release binaries. Python language tools use a dedicated virtual environment, and Rust tools use rustup. LLVM's keg-only `clangd` is linked into the installer's binary directory without changing Apple's compiler. Plugins, Treesitter parsers, and Mason tools are bootstrapped headlessly.

The defaults are `~/.local/bin/nvim`, `~/.config/nvim`, and `~/.local/share/nvim`. Existing config directories and symlinks are backed up to a unique `nvim.bak.*` sibling before replacement. The installed copy includes `install-macos.sh` for reruns; the macOS configuration archive excludes both installer scripts to avoid nesting packed installers. The repository's Linux installer, Vim setup, and other dotfiles are unchanged. Run this installer directly: the general `setup.sh` copies dotfiles without these Neovim backup safeguards.

Options:

- `--skip-brew`: skip Homebrew package installation when dependencies are already available. Homebrew itself is then optional.
- `--skip-rust`, `--skip-headless`, and `--force-nvim`: behave as described for Linux.
- `--pack [SRC_DIR]`: create a self-contained macOS installer without installing anything; packaging also works on Linux.

The same version, `PREFIX`, and XDG environment overrides apply. The installer adds its binaries, Rust tools, and the detected Homebrew paths to `${ZDOTDIR:-$HOME}/.zshrc`. When `SHELL` selects Bash, it uses the first existing login file (`~/.bash_profile`, `~/.bash_login`, or `~/.profile`), creating `~/.bash_profile` if none exists. Open a new shell after installation. To create a portable copy:

```bash
bash .config/nvim/install-macos.sh --pack > /tmp/nvim-install-macos.sh
# Copy it to another Mac, then run:
bash /tmp/nvim-install-macos.sh
```

CUDA source editing remains available, but CUDA-GDB and GPU execution require a supported Linux environment. Bazel and project-specific test dependencies are not installed automatically.

## Start Neovim

Open a project from its root directory:

```bash
cd /path/to/project
nvim .
```

Open a particular file:

```bash
nvim path/to/file.py
```

Press `Space` and wait briefly to see the available shortcut groups.

## Essential Vim controls

Neovim is modal:

- **Normal mode** is for navigation and commands. Press `Esc` to return to it.
- **Insert mode** is for typing. Press `i` to insert before the cursor or `a` after it.
- **Visual mode** is for selecting text. Press `v`.
- **Command mode** runs commands. Press `:` from Normal mode.

Useful controls:

| Keys | Action |
|---|---|
| `i` | Enter Insert mode |
| `Esc` | Return to Normal mode |
| `h j k l` | Move left, down, up, right |
| `w` / `b` | Move forward/backward by word |
| `0` / `$` | Start/end of line |
| `gg` / `G` | Start/end of file |
| `u` / `Ctrl-r` | Undo/redo |
| `dd` | Delete a line |
| `yy` | Copy a line |
| `p` | Paste after the cursor |
| `ciw` | Replace the word under the cursor |
| `.` | Repeat the last edit |
| `/text` | Search in the current file |
| `n` / `N` | Next/previous search result |
| `:w` | Save |
| `:q` | Quit current window |
| `:wq` | Save and quit |
| `Space q q` | Quit all windows |

Run `:Tutor` for the built-in interactive Vim lesson.

## Files, search, buffers, and windows

| Keys | Action |
|---|---|
| `Space e` | Toggle the project file tree |
| `Space E` | Toggle the file tree at the current working directory |
| `Space f f` | Find files in the project |
| `Space f r` | Open a recent file |
| `Space s g` | Search text across the project |
| `Space s w` | Search the word under the cursor |
| `Space ,` | Switch between open buffers |
| `Shift-h` / `Shift-l` | Previous/next buffer |
| `Space b d` | Close the current buffer |
| `Ctrl-h/j/k/l` | Move between editor windows |
| `Space -` | Horizontal split |
| `Space |` | Vertical split |
| `Space f t` | Open a terminal at the project root |
| `Ctrl-/` | Toggle the terminal |

In Neo-tree:

- `Enter` or `l`: open a file or directory.
- `h`: close a directory.
- `a`: create a file.
- `A`: create a directory.
- `r`: rename.
- `d`: delete.
- `R`: refresh.
- `H`: show or hide hidden files.
- `?`: show all Neo-tree shortcuts.

## Completion

Completion appears while typing:

| Keys | Action |
|---|---|
| `Ctrl-n` / `Ctrl-p` | Select next/previous completion |
| `Enter` or `Ctrl-y` | Accept completion |
| `Ctrl-e` | Hide completion |
| `Ctrl-Space` | Open completion manually |
| `Ctrl-f` / `Ctrl-b` | Scroll completion documentation |
| `Tab` / `Shift-Tab` | Move through snippet placeholders |

## Code intelligence

These commands work when the language server is attached:

| Keys | Action |
|---|---|
| `gd` | Go to definition |
| `gr` | Find references |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Show documentation and type information |
| `gK` | Show function signature |
| `Space c a` | Show code actions and quick fixes |
| `Space c r` | Rename a symbol across the project |
| `Space c f` | Format the current file or selection |
| `Space c l` | Show attached language servers |
| `Space c m` | Open the tool installer |
| `Space c h` | Switch between C/C++ source and header |
| `Space u h` | Toggle inlay hints |

Diagnostics:

| Keys | Action |
|---|---|
| `]d` / `[d` | Next/previous diagnostic |
| `Space x x` | Project diagnostics |
| `Space x X` | Current-buffer diagnostics |

Run `:LspInfo` or press `Space c l` when completion or navigation is not working.

## Formatting and linting

Files are formatted automatically when saved unless auto-formatting is toggled off.

| Keys or command | Action |
|---|---|
| `Space c f` | Format now |
| `Space u f` | Toggle auto-format globally |
| `Space u F` | Toggle auto-format for the current buffer |
| `:ConformInfo` | Show the formatter selected for this file |

Configured formatters:

- Python: Ruff import sorting followed by Ruff formatting.
- Rust: rustfmt.
- C, C++, and CUDA: clang-format 21, exposed through `PATH`.
- CMake: cmake-format.
- Bazel/Starlark: buildifier.

Lint and formatting policy should remain in project files such as `pyproject.toml`, `rustfmt.toml`, `.clang-format`, and `.clang-tidy` so the editor and continuous integration agree.

## Python

Python uses **BasedPyright** for types, navigation, hover, and completion, and **Ruff** for linting, import organization, and formatting.

Open a Python file, then select the project environment when needed:

```text
Space c v
```

This opens the virtual-environment selector and supports `.venv`, `uv`, Poetry, Conda, and other common layouts. The selected environment is remembered per project and is also used by terminals and the debugger.

Testing uses Neotest:

| Keys | Action |
|---|---|
| `Space t r` | Run the nearest test |
| `Space t t` | Run the current test file |
| `Space t T` | Run all tests in the current project |
| `Space t s` | Toggle the test summary |
| `Space t o` | Show test output |
| `Space t l` | Run the previous test again |
| `Space t d` | Debug the nearest test |

Python-specific debugging shortcuts:

- `Space d P t`: debug the current test method.
- `Space d P c`: debug the current test class.

Put Ruff and BasedPyright settings in `pyproject.toml` for reproducibility.

## Rust

Rust uses rustaceanvim with the rustup-managed Rust Analyzer, rustfmt, Clippy, and Rust source code. Cargo dependency completion is enabled in `Cargo.toml`.

Useful Rust commands:

| Keys or command | Action |
|---|---|
| `Space c R` | Rust-aware code actions |
| `Space d r` | Select a runnable Rust debug target |
| `Space t r` | Run the nearest test |
| `Space t d` | Debug the nearest test |
| `:RustLsp runnables` | Select a Cargo runnable |
| `:RustLsp testables` | Select a Cargo test |
| `:RustLsp expandMacro` | Expand the macro under the cursor |
| `:RustLsp explainError` | Explain the current compiler error |
| `:RustLsp openDocs` | Open documentation for the symbol |

Clippy checks run through Rust Analyzer on save. The setup uses ordinary `cargo test`, not cargo-nextest. It does not force every Cargo feature on globally; add project-specific features through project configuration when needed.

## C and C++

Clangd provides completion, diagnostics, code navigation, inlay hints, and clang-tidy integration. Its accuracy depends on a compilation database.

For CMake projects, generate it with:

```bash
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sfn build/compile_commands.json compile_commands.json
```

The configured CMake integration creates or updates the root link automatically after generation.

Useful CMake commands:

```text
:CMakeSelectConfigurePreset
:CMakeSelectBuildType
:CMakeSelectKit
:CMakeGenerate
:CMakeBuild
:CMakeBuildCurrentFile
:CMakeRun
:CMakeDebug
:CMakeRunTest
```

Recommended flow:

1. Open the project root with `nvim .`.
2. Run `:CMakeSelectConfigurePreset` or `:CMakeSelectKit`.
3. Run `:CMakeGenerate`.
4. Run `:CMakeBuild`.
5. Use `:CMakeRun` or `:CMakeDebug` for an executable target.

For CTest projects, build first, then use the normal `Space t ...` Neotest shortcuts. The adapter supports GoogleTest, Catch2, doctest, and CppUTest.

## Bazel

Open the monorepo or Bazel workspace root, then press:

```text
Space o o
```

Choose one of the custom tasks:

- `bazel build`
- `bazel test`
- `bazel run`

Enter a target such as `//path/to/package:target` or keep `//...`. Additional Bazel arguments can be supplied in the second prompt.

Other task shortcuts:

| Keys | Action |
|---|---|
| `Space o o` | Select and run a task |
| `Space o w` | Toggle the task list |
| `Space o t` | Act on the selected task |

For clangd in a Bazel C/C++ project, generate or export a `compile_commands.json` using the repository's Bazel tooling. Clangd cannot infer full include paths and defines from BUILD files alone.

## CUDA

CUDA files (`.cu` and `.cuh`) are detected automatically. They use the CUDA Treesitter parser, clangd, clang-format, CMake/Bazel tasks, CodeLLDB for host code, and CUDA-GDB for device debugging.

Clangd's CUDA support is useful but less complete than its C++ support. The real NVCC or Clang CUDA build remains authoritative. For best results, provide CUDA compile commands. If a `.cuh` header is parsed as plain C++, add a project `.clangd` file:

```yaml
If:
  PathMatch: '.*\.(cu|cuh)$'
CompileFlags:
  Add: [-xcuda]
```

Only add `--cuda-path`, GPU architecture flags, or removals for NVCC-only flags after inspecting the actual clangd error. Avoid copying broad flag-removal lists from unrelated projects.

### CUDA debugging

Build device-debuggable code with symbols, typically `-g -G`, then open a CUDA file and press:

```text
Space d c
```

Select `CUDA-GDB: Launch executable`. Enter the compiled executable path. The installed CUDA 13 debugger supports native Debug Adapter Protocol mode.

`Space d c` in a CUDA buffer offers both `CodeLLDB: Launch CUDA host code` and CUDA-GDB configurations. Choose CodeLLDB for CPU-only host debugging. CUDA-GDB is required for kernel breakpoints, device variables, warps, blocks, and GPU stepping. CUDA-specific commands can be entered in the debugger console, for example:

```text
info cuda kernels
info cuda threads
cuda kernel 1
cuda block 0
cuda thread 0
```

## Debugger controls

| Keys | Action |
|---|---|
| `Space d b` | Toggle breakpoint |
| `Space d B` | Add conditional breakpoint |
| `Space d c` | Start or continue |
| `Space d a` | Start with command-line arguments |
| `Space d i` | Step into |
| `Space d O` | Step over |
| `Space d o` | Step out |
| `Space d C` | Run to cursor |
| `Space d e` | Evaluate expression or selection |
| `Space d u` | Toggle debugger interface |
| `Space d r` | Toggle debugger console; Rust buffers use this for Rust debuggables |
| `Space d t` | Terminate debugging |

A project's `.vscode/launch.json` can also define reusable debug configurations. Use `type = "codelldb"` for C/C++/Rust CodeLLDB configurations.

## Git

| Keys | Action |
|---|---|
| `]h` / `[h` | Next/previous changed hunk |
| `Space g h p` | Preview hunk |
| `Space g h s` | Stage hunk |
| `Space g h r` | Reset hunk |
| `Space g b` | Blame current line |
| `Space g g` | Open Lazygit if installed |

## Maintenance and diagnosis

| Command | Purpose |
|---|---|
| `:Lazy` | View, update, or restore plugins |
| `:LazyExtras` | Enable or disable LazyVim language packs |
| `:Mason` | View installed language tools and debuggers |
| `:LazyHealth` | Run comprehensive health checks |
| `:checkhealth rustaceanvim` | Diagnose Rust integration |
| `:checkhealth nvim-treesitter` | Diagnose syntax parsers |
| `:LspInfo` | Inspect active language servers |
| `:LspLog` | Open the language-server log |
| `:ConformInfo` | Inspect formatting |
| `:messages` | Review recent errors and notices |

Plugin versions are recorded in `lazy-lock.json`. Use `:Lazy update` deliberately, test the setup, and keep the updated lockfile. The installer prints the `nvim.bak.*` path when it backs up an existing configuration.
