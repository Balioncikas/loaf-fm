#!/usr/bin/env python3
"""Send real Qt mouse events to FilePane with disposable files and settings.

Requires the Qt Quick Test QML module (QtTest), plus a built Loaf binary.
Run: python3 tests/check-file-selection.py [path/to/loaf]
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    root = Path(__file__).resolve().parents[1]
    binary = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / "target/debug/loaf"
    with tempfile.TemporaryDirectory(prefix="loaf-selection-") as directory:
        sandbox = Path(directory)
        for folder, count in [("small", 8), ("large", 80)]:
            fixture = sandbox / folder
            fixture.mkdir()
            for index in range(count):
                (fixture / f"item_{index:02d}.txt").touch()
        config = sandbox / "config/loaf/config.json"
        config.parent.mkdir(parents=True)
        config.write_text(json.dumps({"selectionTestRoot": str(sandbox)}))
        env = os.environ.copy()
        env.update(XDG_CONFIG_HOME=str(sandbox / "config"),
                   QT_QPA_PLATFORM="offscreen", QT_FORCE_STDERR_LOGGING="1",
                   LOAF_QML=str(root / "tests/file-selection.qml"))
        result = subprocess.run([str(binary), "--new-window"], env=env,
                                capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        if result.returncode or "FILE_SELECTION_PASS" not in output or "FILE_SELECTION_FAIL" in output:
            raise AssertionError(output)
        print("\n".join(line for line in output.splitlines() if "SELECTION_" in line))


if __name__ == "__main__":
    main()
