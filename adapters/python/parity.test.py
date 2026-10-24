import json
from pathlib import Path
import sys
from themes import Resolver, FIELDS

root = Path(__file__).resolve().parents[2]
catalog = json.loads((root / "catalog/icons.json").read_text())
nix = json.loads(Path(sys.argv[1]).read_text())
resolver = Resolver({"theme": "github-dark-dimmed"})
maps = {category: {} for category in FIELDS}
for record in catalog["icons"]:
    for category, field in FIELDS.items():
        for name in record.get(field, []):
            maps[category].setdefault(name, record)
for category, records in {**nix["mini"], "application": nix["applications"],
                          "website": {record["domains"][0]: record for record in nix["websites"]}}.items():
    for name, record in records.items():
        portable = resolver.resolve(maps[category][name], category, name)
        assert portable["color"] == record["color"], (category, name)
        assert portable["glyph"] == record["glyph"], (category, name)
print("Full semantic catalog Nix/portable parity passed")
