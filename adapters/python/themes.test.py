import json
from pathlib import Path
import subprocess
import sys
from themes import Resolver, contrast

root = Path(__file__).resolve().parents[2]
explicit = {"color": "#123456"}
for policy in ({"mode": "role", "colorRole": "missing"}, {"mode": "contrast"}):
    config = {"themeColors": {"background": "#000000", "foreground": "#000000"},
              "overrides": {"website": {"github.com": explicit}},
              "apps": {"rofi": {"colors": policy}}}
    assert Resolver(config).resolve({"glyph": "G", "colorRole": "missing"}, "website", "github.com", "rofi")["color"] == "#123456"
catalog = json.loads((root / "catalog/icons.json").read_text())
github = next(icon for icon in catalog["icons"] if "github.com" in icon.get("domains", []))
resolver = Resolver({"theme": "github-dark-dimmed"})
assert Resolver({"theme": "github-dark-dimmed", "themeColors": {"blue": "#123456"}}).resolve(
    {"glyph": "N", "color": "#7EBAE4"}, "editorFiletype", "nix")["color"] == "#123456"
assert resolver.resolve(github, "website", "github.com")["color"] == "#cdd9e5"
custom = Resolver({"theme": "github-dark-dimmed", "themeColors": {"foregroundStrong": "#ffffff"},
                   "overrides": {"website": {"github.com": {"glyph": "G"}}}})
assert custom.resolve(github, "website", "github.com")["glyph"] == "G"
assert custom.resolve(github, "website", "github.com")["color"] == "#ffffff"
config = {"theme": "github-dark-dimmed", "overrides": {"website": {"github.com": {"colorRole": "blue"}}},
          "apps": {"rofi": {"colors": {"mode": "none"}, "overrides": {"website": {"github.com": {"glyph": "R"}}}}}}
icon = Resolver(config).resolve(github, "website", "github.com", "rofi")
assert icon["color"] == "#539bf5" and icon["glyph"] == "R"
for override in ({"color": "#ffffff", "colorRole": "blue"}, {"colorRole": "missing"}):
    try:
        Resolver({"overrides": {"website": {"github.com": override}}}).resolve(github, "website", "github.com")
    except ValueError:
        pass
    else:
        raise AssertionError("invalid icon override accepted")
for background, foreground in (("#22272e", "#cdd9e5"), ("#ffffff", "#000000")):
    resolver = Resolver({"themeColors": {"background": background, "foreground": foreground},
                         "apps": {"rofi": {"colors": {"mode": "contrast"}}}})
    for record in catalog["icons"]:
        assert contrast(resolver.resolve(record, "website", "example.com", "rofi")["color"], background) >= 3
for config in ({"theme": "missing"}, {"themeColors": {"blue": "invalid"}}):
    try:
        Resolver(config)
    except ValueError:
        pass
    else:
        raise AssertionError("invalid configuration accepted")
output = subprocess.check_output([sys.executable, str(root / "adapters/python/themes.py"),
                                  "--theme", "github-dark-dimmed", "--catalog", str(root / "catalog/icons.json")])
projected = json.loads(output)
assert next(icon for icon in projected["icons"] if icon.get("domains") == ["github.com"])["color"] == "#cdd9e5"
print("Portable theme checks passed")
