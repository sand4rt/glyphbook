import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[2]
resolver = os.environ["GLYPHBOOK_RESOLVER"]
with tempfile.TemporaryDirectory() as directory:
    env = {**os.environ, "GLYPHBOOK_THEME": "github-dark-dimmed",
           "GLYPHBOOK_CATALOG": str(root / "catalog/icons.json"),
           "GLYPHBOOK_THEME_RESOLVER": str(root / "adapters/python/themes.py")}
    # A fresh shell prepares one snapshot, then all repeated lookups use the
    # native index. Removing Python from PATH proves no catalog rescans occur.
    script = '''
      . "$1/adapters/shell/shell.sh"
      icons_prepare_theme "$2"
      PATH=/nonexistent
      icons_get website github.com
      icons_get website https://github.com/test
      icons_get_file example.nix nix
    '''
    output = subprocess.check_output(["sh", "-ec", script, "sh", str(root), directory], env=env, text=True)
    records = [json.loads(line) for line in output.splitlines()]
    assert records[0]["color"] == "#cdd9e5"
    assert records[1]["color"] == records[0]["color"]
    assert records[2]["color"] == "#539bf5"
print("Prepared indexed shell lookups passed")
