"""Offline installer checks: python3 -m unittest discover -s tests -v."""

import base64
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
CONFIG = REPO / ".config/nvim"
INSTALLER = CONFIG / "install.sh"
MAIN = """
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
"""


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nvim-install-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home path"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.work = self.root / "work"
        self.work.mkdir()
        self.env = os.environ.copy()
        for key in ("PREFIX", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "BASH_ENV", "ENV"):
            self.env.pop(key, None)
        self.env.update(HOME=str(self.home), PATH=f"{self.bin}:/usr/bin:/bin")
        self.command("uname", '#!/bin/bash\ncase "$1" in -s) echo Linux;; *) echo x86_64;; esac\n')

    def command(self, name, text):
        path = self.bin / name
        path.write_text(text)
        path.chmod(0o755)
        return path

    def run_script(self, path, *args, success=True):
        result = subprocess.run(
            ["/bin/bash", str(path), *args], cwd=self.work, env=self.env,
            text=True, capture_output=True, timeout=30,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def config_only_script(self, text):
        # Keep real configuration/PATH logic without running package managers.
        self.assertEqual(text.count(MAIN), 1)
        return text.replace(MAIN, "\ninstall_config\nensure_path\nexit 0\n")

    def source_copy(self, destination):
        shutil.copytree(CONFIG, destination)
        script = destination / "install.sh"
        script.write_text(self.config_only_script(INSTALLER.read_text()))
        return script

    def assert_config(self, destination):
        for path in CONFIG.rglob("*"):
            if path.is_file() and path.name != "install.sh":
                self.assertEqual((destination / path.relative_to(CONFIG)).read_bytes(), path.read_bytes())
        self.assertTrue(os.access(destination / "install.sh", os.X_OK))

    def test_pack_contains_complete_configuration(self):
        result = self.run_script(INSTALLER, "--pack")
        payload = result.stdout.split("\n__PAYLOAD_BELOW__\n", 1)[1]
        with tarfile.open(fileobj=io.BytesIO(base64.b64decode(payload)), mode="r:gz") as archive:
            files = {str(Path(member.name)): archive.extractfile(member).read()
                     for member in archive.getmembers() if member.isfile()}
        expected = {str(path.relative_to(CONFIG)): path.read_bytes()
                    for path in CONFIG.rglob("*") if path.is_file() and path.name != "install.sh"}
        self.assertEqual(files, expected)

    def test_pack_explicit_source_excludes_generated_files(self):
        source = self.root / "other config"
        source.mkdir()
        (source / "init.lua").write_text("return {}\n")
        for directory in (".git", "data", "debug", ".tests", ".repro"):
            (source / directory).mkdir()
            (source / directory / "ignored").touch()
        for name in ("install.sh", "trace.log", "foo.tmp", "tt.tmp"):
            (source / name).touch()
        result = self.run_script(INSTALLER, "--pack", str(source))
        payload = result.stdout.split("\n__PAYLOAD_BELOW__\n", 1)[1]
        with tarfile.open(fileobj=io.BytesIO(base64.b64decode(payload)), mode="r:gz") as archive:
            self.assertEqual([str(Path(m.name)) for m in archive.getmembers() if m.isfile()], ["init.lua"])

    def test_help_unknown_option_and_missing_pack_source(self):
        self.assertIn("--skip-headless", self.run_script(INSTALLER, "--help").stdout)
        result = self.run_script(INSTALLER, "--invalid", success=False)
        self.assertEqual(result.returncode, 2)
        self.assertIn("no init.lua", self.run_script(INSTALLER, "--pack", str(self.work), success=False).stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_rejects_non_linux_before_creating_directories(self):
        self.command("uname", '#!/bin/bash\ncase "$1" in -s) echo Darwin;; *) echo x86_64;; esac\n')
        self.assertIn("Linux only", self.run_script(INSTALLER, success=False).stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_existing_config_is_preserved_and_in_place_rerun_works(self):
        script = self.source_copy(self.root / "source config")
        target = self.home / ".config/nvim"
        target.mkdir(parents=True)
        (target / "old.lua").write_text("old config")
        self.run_script(script)
        backups = list(target.parent.glob("nvim.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "old.lua").read_text(), "old config")
        self.assertFalse((backups[0] / "init.lua").exists())
        self.assertFalse((target / "old.lua").exists())
        self.assert_config(target)
        self.run_script(target / "install.sh")
        self.assert_config(target)
        self.assertEqual(len(list(target.parent.glob("nvim.bak.*"))), 2)
        self.assertEqual((self.home / ".bashrc").read_text().count("export PATH="), 1)

    def test_linked_config_is_backed_up_without_changing_its_target(self):
        source = self.root / "source config"
        self.source_copy(source)
        target = self.home / ".config/nvim"
        target.parent.mkdir()
        target.symlink_to(source, target_is_directory=True)
        self.run_script(target / "install.sh")
        self.assertFalse(target.is_symlink())
        self.assertTrue(next(target.parent.glob("nvim.bak.*")).is_symlink())
        self.assert_config(target)
        self.assert_config(source)

    def test_packed_installer_uses_embedded_source_and_can_rerun(self):
        packed = self.run_script(INSTALLER, "--pack").stdout
        script = self.work / "packed.sh"
        script.write_text(self.config_only_script(packed))
        (self.work / "init.lua").write_text("wrong adjacent config")
        self.run_script(script)
        target = self.home / ".config/nvim"
        self.assert_config(target)
        self.run_script(target / "install.sh")
        self.assert_config(target)

    def test_missing_source_leaves_existing_config_intact(self):
        script = self.work / "install.sh"
        script.write_text(self.config_only_script(INSTALLER.read_text()))
        target = self.home / ".config/nvim"
        target.mkdir(parents=True)
        (target / "init.lua").write_text("old config")
        self.assertIn("no configuration", self.run_script(script, success=False).stderr)
        self.assertEqual((target / "init.lua").read_text(), "old config")
        self.assertEqual(list(target.parent.glob("nvim.bak.*")), [])

    def test_custom_xdg_and_prefix_paths_are_quoted_and_idempotent(self):
        script = self.source_copy(self.root / "source config")
        prefix = self.home / "tools $literal"
        self.env.update(PREFIX=str(prefix), XDG_CONFIG_HOME=str(self.home / "config root"),
                        XDG_DATA_HOME=str(self.home / "data root"))
        (self.home / ".bashrc").write_text('# Unrelated .local/bin mention\nexport PATH="/usr/bin:/bin"\n')
        self.run_script(script)
        self.run_script(script)
        self.assert_config(self.home / "config root/nvim")
        self.assertEqual((self.home / ".bashrc").read_text().count("# added by nvim"), 1)
        result = subprocess.run(
            ["/bin/bash", "-c", 'source "$HOME/.bashrc"; printf "%s" "$PATH"'],
            env=self.env, text=True, capture_output=True, check=True,
        )
        self.assertEqual(result.stdout.split(":"), [str(prefix / "bin"), str(self.home / ".cargo/bin"),
                                                   "/usr/bin", "/bin"])

    def ubuntu_fixture(self):
        checkout = self.root / "repo"
        checkout.mkdir()
        shutil.copy(REPO / ".bashrc", checkout / ".bashrc")
        self.source_copy(checkout / ".config/nvim")
        self.env.update(TEST_REPO=str(checkout), TEST_LOG=str(self.root / "commands.jsonl"))
        mock = self.command("git", f"#!{sys.executable}\n" + '''
import json, os, shutil, sys
from pathlib import Path
name, args = Path(sys.argv[0]).name, sys.argv[1:]
with open(os.environ["TEST_LOG"], "a") as log:
    log.write(json.dumps([name, args, os.environ["PATH"]]) + "\\n")
if name == "git" and args[0] == "clone":
    if args[1] == "https://github.com/olegsolovey/dot.git":
        shutil.copytree(os.environ["TEST_REPO"], "dot")
    elif args[1] == "https://github.com/vim/vim.git":
        Path("vim/src").mkdir(parents=True)
        Path("vim/src/Makefile").write_text("#CONF_OPT_PYTHON3 = --enable-python3interp=dynamic\\n")
    elif args[1] == "https://github.com/tmux-plugins/tpm":
        destination = Path(args[-1]) / "bin/install_plugins"
        destination.parent.mkdir(parents=True)
        destination.write_text("#!/bin/bash\\nexit 0\\n")
        destination.chmod(0o755)
    else:
        Path(args[-1]).mkdir(parents=True, exist_ok=True)
''')
        for name in ("sudo", "make", "vim", "rustup", "tmux", "sed"):
            (self.bin / name).symlink_to(mock)
        # The installer's sed calls must run normally; only GNU sed -i needs a stub on macOS.
        (self.bin / "sed").unlink()
        self.command("sed", '#!/bin/bash\nif [[ "$1" == "-i" ]]; then exit 0; fi\nexec /usr/bin/sed "$@"\n')
        self.env["TMUX"] = "test-session"
        return checkout

    def test_ubuntu_integration_preserves_backup_and_existing_setup(self):
        self.ubuntu_fixture()
        target = self.home / ".config/nvim"
        target.mkdir(parents=True)
        (target / "old.lua").write_text("old config")
        self.run_script(REPO / "ubuntu-22.sh", "-g", "test-token")
        self.assert_config(target)
        backup = next(target.parent.glob("nvim.bak.*"))
        self.assertEqual(list(backup.iterdir()), [backup / "old.lua"])
        self.assertFalse((self.work / "dot").exists())
        events = [json.loads(line) for line in Path(self.env["TEST_LOG"]).read_text().splitlines()]
        self.assertTrue(any(name == "vim" and "PluginInstall" in args for name, args, _ in events))
        self.assertTrue(any(name == "tmux" for name, _, _ in events))
        rust = [(args, path) for name, args, path in events if name == "rustup"]
        self.assertEqual(rust[-1][0], ["component", "add", "rust-analyzer", "rust-src", "clippy", "rustfmt", "--toolchain", "1.94.0"])
        self.assertTrue(rust[-1][1].startswith(f"{self.home}/.local/bin:{self.home}/.cargo/bin:"))

    def test_ubuntu_can_run_from_stdin(self):
        self.ubuntu_fixture()
        result = subprocess.run(
            ["/bin/bash", "-s", "--", "-g", "test-token"],
            input=(REPO / "ubuntu-22.sh").read_text(), cwd=self.work, env=self.env,
            text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assert_config(self.home / ".config/nvim")
        self.assertFalse((self.work / "dot").exists())

    def test_ubuntu_stops_if_neovim_installation_fails(self):
        checkout = self.ubuntu_fixture()
        (checkout / ".config/nvim/install.sh").write_text("#!/bin/bash\nexit 42\n")
        self.run_script(REPO / "ubuntu-22.sh", "-g", "test-token", success=False)
        self.assertTrue((self.work / "dot").is_dir())
        events = [json.loads(line) for line in Path(self.env["TEST_LOG"]).read_text().splitlines()]
        self.assertEqual([name for name, _, _ in events], ["git", "git"])


if __name__ == "__main__":
    unittest.main()
