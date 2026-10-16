"""Tests for Linux and Chrome compatibility."""
import os
import shutil
import sys
import unittest
from unittest.mock import patch

import cf_turnstile
import scheduler
import pyqt_downloader


class TestLinuxChromeCompatibility(unittest.TestCase):
    def test_chrome_detected_first_on_linux(self):
        """Verify that Chrome binaries on Linux are discovered and prioritized."""
        browsers = cf_turnstile.find_browsers()
        self.assertTrue(len(browsers) > 0, "At least one browser should be found")
        first = browsers[0]
        # On Linux, google-chrome or chromium should be selected
        self.assertTrue(
            any(name in first.lower() for name in ("google-chrome", "chrome", "chromium")),
            f"Expected Google Chrome or Chromium as first candidate, got: {first}"
        )

    def test_chrome_bin_env_override(self):
        """Verify that CHROME_BIN environment variable overrides browser discovery."""
        dummy_path = "/tmp/dummy_chrome_test"
        with open(dummy_path, "w") as f:
            f.write("#!/bin/sh\n")
        os.chmod(dummy_path, 0o755)
        try:
            os.environ["CHROME_BIN"] = dummy_path
            browsers = cf_turnstile.find_browsers()
            self.assertEqual(browsers[0], dummy_path)
        finally:
            os.environ.pop("CHROME_BIN", None)
            if os.path.exists(dummy_path):
                os.remove(dummy_path)

    def test_linux_sleep_inhibition(self):
        """Verify Linux sleep inhibition works via systemd-inhibit if available."""
        if shutil.which("systemd-inhibit") and sys.platform.startswith("linux"):
            started = scheduler.prevent_sleep()
            self.assertTrue(started)
            stopped = scheduler.allow_sleep()
            self.assertTrue(stopped)
            self.assertIsNone(scheduler._linux_inhibit_proc)

    def test_extractor_linux_resolution(self):
        """Verify Linux extractor picks native 7z/7za instead of bundled Windows 7z.exe."""
        extractor_type, base_cmd, seven_zip = pyqt_downloader.MainWindow._find_extractor()
        if shutil.which("7z"):
            self.assertEqual(extractor_type, "7z")
            self.assertEqual(base_cmd, "7z")
            self.assertEqual(seven_zip, "7z")
        elif shutil.which("7za"):
            self.assertEqual(extractor_type, "7z")
            self.assertEqual(base_cmd, "7za")
            self.assertEqual(seven_zip, "7za")
        self.assertFalse(str(seven_zip).endswith(".exe"))

    def test_default_downloads_folder(self):
        """Verify default downloads folder defaults to ~/Downloads on fresh install."""
        with patch("pyqt_downloader.get_settings_path", return_value="/tmp/non_existent_settings_123.json"):
            settings = pyqt_downloader.load_settings()
            expected = os.path.join(os.path.expanduser("~"), "Downloads")
            if os.path.exists(expected):
                self.assertEqual(settings.get("default_save_dir"), expected)


if __name__ == "__main__":
    unittest.main()
