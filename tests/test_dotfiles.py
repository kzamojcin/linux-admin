"""Testy w izolowanym katalogu domowym; bez wykonywania PHP ani APT."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


class DotfilesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="linux-admin-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "repo ze spacjami"
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        self.home = self.base / "home"
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home))
        self.env["NVIM_LOG_FILE"] = str(self.base / "nvim.log")
        for key in ("NVIM_APPNAME", "VIMINIT", "EXINIT", "BASH_ENV"):
            self.env.pop(key, None)
        for key, directory in (("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                               ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache")):
            self.env[key] = str(self.base / directory)
        self.config = self.base / "config" / "nvim"

    def run_cmd(self, args, expected=0):
        result = subprocess.run(args, cwd=self.repo, env=self.env, capture_output=True,
                                text=True, timeout=30)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def bash(self, script, expected=0):
        return self.run_cmd(["bash", "--noprofile", "--norc", "-ic",
                             'source "$1/bash/init.sh"\n' + script,
                             "test", str(self.repo)], expected)

    def install_nvim(self):
        return self.run_cmd(["bash", "scripts/install-nvim.sh", "--config-only"])

    def test_shell_syntax(self):
        for file in self.repo.rglob("*.sh"):
            self.run_cmd(["bash", "-n", str(file)])

    def test_bash_install_preserves_content_and_is_repeatable(self):
        rc = self.home / ".bashrc"
        rc.write_text("# Existing config\nexport EXISTING_SETTING=yes\n")
        self.run_cmd(["bash", "install.sh"])
        first = rc.read_bytes()
        self.run_cmd(["bash", "install.sh"])
        self.assertEqual(first, rc.read_bytes())
        backups = list(self.home.glob(".bashrc.backup.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "# Existing config\nexport EXISTING_SETTING=yes\n")
        (self.home / ".bashrc.local").write_text("export EDITOR=custom-editor\nHISTSIZE=9000\n")
        self.bash('source "$HOME/.bashrc"; [[ $EXISTING_SETTING == yes && $EDITOR == custom-editor && $HISTSIZE == 9000 ]]')

    def test_artisan_arguments_and_exit_codes(self):
        binary = self.base / "bin"
        binary.mkdir()
        php = binary / "php"
        php.write_text('#!/bin/bash\nprintf "%s\\0" "$@"\nexit "${PHP_TEST_EXIT:-0}"\n')
        php.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]
        (self.repo / "artisan").touch()
        commands = {"artisan": [], "am": ["migrate"], "amf": ["migrate", "--force"],
                    "ams": ["migrate:status"], "ao": ["optimize"],
                    "aoc": ["optimize:clear"], "acc": ["config:clear"], "acch": ["config:cache"]}
        for name, args in commands.items():
            with self.subTest(name=name):
                output = self.bash(f'{name} --help "argument ze spacjami"').stdout
                self.assertEqual(output.split("\0"), ["artisan", *args, "--help", "argument ze spacjami", ""])
        self.env["PHP_TEST_EXIT"] = "7"
        self.bash("ao", expected=7)
        (self.repo / "artisan").unlink()
        result = self.bash("ams", expected=1)
        self.assertEqual(result.stdout, "")
        self.assertIn("katalogu aplikacji Laravel", result.stderr)

    def test_navigation_aliases_and_history(self):
        self.bash('[[ $(alias casa) == *"cd /etc/apache2/sites-available"* ]] && '
                  '[[ $(alias cnsa) == *"cd /etc/nginx/sites-available"* ]] && '
                  '[[ $HISTSIZE == 2000 && $HISTFILESIZE == 2000 && $HISTCONTROL == ignoredups ]]')
        local_bin = self.home / ".local" / "bin"
        local_bin.mkdir(parents=True)
        output = self.bash('source "$1/bash/init.sh"; printf "%s" "$PATH"').stdout
        self.assertEqual(output.split(os.pathsep).count(str(local_bin)), 1)

    def test_nvim_backup_and_idempotency(self):
        self.config.mkdir(parents=True)
        (self.config / "init.lua").write_text("-- original lua\n")
        (self.config / "init.vim").write_text('" original vim\n')
        self.install_nvim()
        backups = list(self.config.glob("backup-dotfiles.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "init.lua").read_text(), "-- original lua\n")
        self.assertEqual((backups[0] / "init.vim").read_text(), '" original vim\n')
        self.assertFalse((self.config / "init.vim").exists())
        self.assertEqual((self.config / "init.lua").resolve(), (self.repo / "nvim/init.lua").resolve())
        self.install_nvim()
        self.assertEqual(len(list(self.config.glob("backup-dotfiles.*"))), 1)

    def test_nvim_preserves_existing_symlink_target(self):
        self.config.mkdir(parents=True)
        external = self.base / "original.lua"
        external.write_text("-- keep this\n")
        (self.config / "init.lua").symlink_to(external)
        self.install_nvim()
        backup = next(self.config.glob("backup-dotfiles.*")) / "init.lua"
        self.assertTrue(backup.is_symlink())
        self.assertEqual(external.read_text(), "-- keep this\n")

    def test_nvim_rejects_config_directory_without_changes(self):
        (self.config / "init.vim").mkdir(parents=True)
        self.run_cmd(["bash", "scripts/install-nvim.sh", "--config-only"], expected=1)
        self.assertFalse((self.config / "init.lua").exists())
        self.assertEqual(list(self.config.glob("backup-dotfiles.*")), [])

    @unittest.skipUnless(NVIM, "Neovim nie jest zainstalowany")
    def test_real_nvim_options_and_php_highlighting(self):
        self.install_nvim()
        sample = self.base / "example.php"
        sample.write_text("<?php\nfunction example() {}\n")
        checks = '''lua local ok, err = pcall(function()
            assert(vim.v.errmsg == '', vim.v.errmsg)
            assert(vim.wo.number and vim.wo.relativenumber and vim.wo.cursorline)
            assert(vim.bo.tabstop == 4 and vim.bo.shiftwidth == 4)
            assert(vim.bo.filetype == 'php' and vim.bo.syntax == 'php')
            assert(vim.fn.synIDattr(vim.fn.synID(2, 1, 1), 'name') ~= '')
        end); if not ok then print(err); vim.cmd('cquit 1') end'''
        self.run_cmd([NVIM, "--headless", "-i", "NONE", str(sample), "-c", checks, "-c", "qa!"])


if __name__ == "__main__":
    unittest.main()
