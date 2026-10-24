"""Portable theme and override resolution shared by shell and Lua adapters."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


FIELDS = {
    "application": "applications", "website": "domains", "default": "defaults",
    "directory": "directories", "extension": "extensions", "file": "files",
    "editorFiletype": "editorFiletypes", "lsp": "lsp", "os": "operatingSystems",
    "nerdFont": "nerdFontNames", "symbol": "symbols",
}


def normalize(category, name):
    return name if category in ("file", "directory", "application", "symbol", "nerdFont") else name.lower()


def contrast(foreground, background):
    def luminance(color):
        channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        return sum(weight * (value / 12.92 if value <= .04045 else ((value + .055) / 1.055) ** 2.4)
                   for weight, value in zip((.2126, .7152, .0722), channels))
    a, b = sorted((luminance(foreground), luminance(background)))
    return (b + .05) / (a + .05)


def color_role(color):
    r, g, b = (int(color[i:i + 2], 16) for i in (1, 3, 5))
    maximum, minimum = max(r, g, b), min(r, g, b)
    delta = maximum - minimum
    if delta < 32:
        return "foreground"
    hue = ((g - b) / delta if maximum == r else
           2 + (b - r) / delta if maximum == g else 4 + (r - g) / delta) % 6
    for boundary, role in ((.35, "red"), (.8, "orange"), (1.5, "yellow"), (2.7, "green"),
                           (3.3, "cyan"), (4.5, "blue"), (5.3, "purple"), (5.8, "pink")):
        if hue < boundary:
            return role
    return "red"


class Resolver:
    def __init__(self, config=None):
        self.config = config or {}
        theme = self.config.get("theme")
        self.theme = {}
        if isinstance(theme, str):
            if theme != "github-dark-dimmed":
                raise ValueError(f"unknown theme: {theme}")
            self.theme = json.loads((Path(__file__).resolve().parents[2] / "themes" / f"{theme}.json").read_text())
        self.colors = {**self.theme.get("colors", {}),
                       **(theme if isinstance(theme, dict) else {}), **self.config.get("themeColors", {})}
        if not all(isinstance(color, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", color) for color in self.colors.values()):
            raise ValueError("theme colors must be six-digit hex colors")
        self.polarity = self.config.get("polarity") or self.theme.get("polarity", "dark")

    def role(self, name):
        if name not in self.colors:
            raise ValueError(f"unknown theme color role: {name}")
        return self.colors[name]

    def resolve(self, icon, category, name, app=None):
        category = {"editor-filetype": "editorFiletype", "editor_filetype": "editorFiletype"}.get(category, category)
        app_config = self.config.get("apps", {}).get(app, {})
        global_override = self.config.get("overrides", {}).get(category, {}).get(name, {})
        app_override = app_config.get("overrides", {}).get(category, {}).get(name, {})
        result = {**icon, **global_override, **app_override}
        # Explicit overrides short-circuit lower-priority policy and role
        # evaluation, matching the lazy Nix resolver.
        for override in (app_override, global_override):
            if "color" in override and "colorRole" in override:
                raise ValueError("specify color or colorRole, not both")
            if "color" in override:
                color = override["color"]
                if color is not None and (not isinstance(color, str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", color)):
                    raise ValueError("icon colors must be six-digit hex colors")
                return {**result, "color": color}
            if "colorRole" in override:
                return {**result, "color": self.role(override["colorRole"])}
        if category == "website":
            if name in self.config.get("colors", {}):
                return {**result, "color": self.config["colors"][name]}
            if name == "*" and self.config.get("fallbackColor") is not None:
                return {**result, "color": self.config["fallbackColor"]}
        role = self.theme.get("roles", {}).get(category, {}).get(name, icon.get("colorRole"))
        color = icon.get("color")
        if isinstance(color, dict):
            color = color.get(self.polarity)
        if role is None and self.theme and color is not None:
            role = color_role(color)
        policy = app_config.get("colors", {})
        mode = policy.get("mode", "preserve")
        if mode == "none":
            color = None
        elif mode == "monochrome":
            color = policy.get("color") or self.colors.get(policy.get("colorRole") or "muted")
        elif mode == "role":
            color = self.role(policy.get("colorRole") or "foreground")
        else:
            if role is not None:
                color = self.role(role)
        if mode == "contrast" and "background" in self.colors:
            readable = lambda value: value is not None and contrast(value, self.colors["background"]) >= 3
            if not readable(color):
                candidates = [policy.get("color"), self.colors.get("foregroundStrong"), self.colors.get("foreground")]
                candidates += [self.colors[key] for key in sorted(self.colors)]
                color = next((value for value in candidates if readable(value)), None)
                if color is None:
                    raise ValueError("theme has no icon color with 3:1 background contrast")
        result["color"] = color
        return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path)
    parser.add_argument("--theme")
    parser.add_argument("--app")
    parser.add_argument("--catalog", type=Path)
    parser.add_argument("--lookup", choices=["get", "file"])
    parser.add_argument("--category")
    parser.add_argument("--name")
    parser.add_argument("--prepare", type=Path)
    parser.add_argument("--resolver")
    args = parser.parse_args()
    config = json.loads(args.config.read_text()) if args.config else {}
    if args.theme:
        config["theme"] = args.theme
    resolver = Resolver(config)
    if args.catalog:
        catalog = json.loads(args.catalog.read_text())
        if args.lookup:
            category = {"editor-filetype": "editorFiletype"}.get(args.category, args.category)
            name = args.name
            candidates = []
            if args.lookup == "file":
                name = name.replace("\\", "/").rsplit("/", 1)[-1]
                candidates.append(("file", name))
                parts = name.split(".")
                candidates.extend(("extension", ".".join(parts[i:]).lower()) for i in range(1, len(parts)))
                if category:
                    candidates.append(("editorFiletype", category.lower()))
                candidates.append(("default", "file"))
            elif category == "website":
                from urllib.parse import urlsplit
                name = (urlsplit(name if "://" in name else "//" + name).hostname or "").lower()
                candidates.append((category, name))
                labels = name.split(".")
                candidates.extend((category, "*." + ".".join(labels[i:])) for i in range(1, len(labels)))
                candidates.append((category, "*"))
            else:
                name = normalize(category, name)
                candidates.append((category, name))
            for category, name in candidates:
                field = FIELDS.get(category)
                if field is None:
                    raise ValueError(f"unknown icon category: {category}")
                match = next(((icon, key) for icon in catalog["icons"] for key in icon.get(field, [])
                              if normalize(category, key) == name), None)
                key = next((key for key in config.get("overrides", {}).get(category, {})
                            if normalize(category, key) == name), match[1] if match else name)
                record = match[0] if match else None
                override = config.get("overrides", {}).get(category, {}).get(key, {})
                if record is None and "glyph" in override:
                    record = {field: [name], **override}
                if record is not None:
                    print(json.dumps(resolver.resolve(record, category, key, args.app)))
                    return
            sys.exit(1)
        records = []
        for icon in catalog["icons"]:
            # Split matcher projections so a per-matcher override cannot leak
            # onto another filetype, domain, or application sharing a glyph.
            for category, field in FIELDS.items():
                for name in icon.get(field, []):
                    record = resolver.resolve(icon, category, name, args.app)
                    for matcher_field in FIELDS.values():
                        record.pop(matcher_field, None)
                    record[field] = [name]
                    records.append(record)
            if not any(icon.get(field) for field in FIELDS.values()):
                records.append(resolver.resolve(icon, "nerdFont", "", args.app))
        added_overrides = {category: dict(values) for category, values in config.get("overrides", {}).items()}
        for category, overrides in config.get("apps", {}).get(args.app, {}).get("overrides", {}).items():
            for name, override in overrides.items():
                if name not in added_overrides.get(category, {}):
                    # App overrides can customize existing matchers, not create
                    # new matchers without a global catalog entry.
                    if not any(name in icon.get(FIELDS.get(category), []) for icon in catalog["icons"]):
                        raise ValueError("application override needs an existing global matcher")
        for category, overrides in added_overrides.items():
            field = FIELDS.get(category)
            if field is None:
                continue
            for name, override in overrides.items():
                if not any(name in icon.get(field, []) for icon in catalog["icons"]):
                    if "glyph" not in override:
                        raise ValueError("a new matcher needs a glyph")
                    records.append({**resolver.resolve(override, category, name, args.app), field: [name]})
        projected = {**catalog, "icons": records}
        if args.prepare:
            if not args.resolver:
                raise ValueError("--prepare requires --resolver")
            args.prepare.mkdir(parents=True, exist_ok=True)
            records_path = args.prepare / "icons.records.jsonl"
            matchers_path = args.prepare / "icons.matchers.tsv"
            with records_path.open("w") as output, matchers_path.open("w") as matchers:
                for index, record in enumerate(records):
                    output.write(json.dumps(record, separators=(",", ":")) + "\n")
                    for category, field in FIELDS.items():
                        for name in record.get(field, []):
                            if "\t" in name or "\n" in name:
                                raise ValueError("invalid matcher")
                            category_name = "editor-filetype" if category == "editorFiletype" else category
                            if category == "website":
                                if name == "*":
                                    category_name = "website-fallback"
                                elif name.startswith("*."):
                                    category_name, name = "website-wildcard", name[2:]
                            matchers.write(f"{category_name}\t{name}\t{index}\n")
            subprocess.run([args.resolver, "--build", str(records_path), str(matchers_path),
                            str(args.prepare / "icons.index")], check=True)
        else:
            print(json.dumps(projected))
    else:
        print(json.dumps(resolver.resolve(json.load(sys.stdin), args.category, args.name, args.app)))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError) as error:
        sys.exit(f"Glyphbook: {error}")
