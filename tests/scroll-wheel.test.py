"""Run isolated Qt Quick scrolling checks without loading user services/state."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


repo = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="lc-scroll-test-") as directory:
    root = Path(directory)
    widgets = root / "common/widgets"
    widgets.mkdir(parents=True)
    shutil.copy(repo / "common/widgets/ScrollWheelHandler.qml", widgets)
    shutil.copy(repo / "tests/scroll-wheel.qml", root / "shell.qml")
    # Use the real speed settings, without initializing the full theme/services.
    appearance = (repo / "common/Appearance.qml").read_text()
    properties = re.findall(r"readonly property real (?:wheelScrollMultiplier|touchpadScrollMultiplier): [\d.]+", appearance)
    assert len(properties) == 2
    (root / "common/Appearance.qml").write_text(
        "pragma Singleton\nimport QtQuick\nimport Quickshell\nSingleton {\n"
        + "\n".join(properties) + "\n}\n"
    )
    runtime = root / "runtime"
    runtime.mkdir(mode=0o700)
    environment = dict(os.environ, QT_QPA_PLATFORM="offscreen",
                       QT_QUICK_BACKEND="software", QT_QPA_PLATFORMTHEME="basic",
                       XDG_RUNTIME_DIR=str(runtime))
    result = subprocess.run(["quickshell", "-p", str(root)], env=environment,
                            capture_output=True, text=True, timeout=15)
    output = result.stdout + result.stderr
    # QtTest can exit with code zero after an assertion fails under Quickshell.
    assert result.returncode == 0 and "SCROLL_WHEEL_TEST_PASSED" in output, output
    print("PASS: wheel speed, list/grid/ScrollView, nested bounds, pixel deltas, repeated input")
