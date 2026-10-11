# Development

Run the focused adapter checks and all flake checks:

```sh
./adapters/shell/shell.test.sh
nix flake check
```

Regenerate `catalog/icons.json` and `catalog/generated-stats.json` from the
locked Nerd Fonts, MiniIcons, and Simple Icons inputs:

```sh
nix run .#generate
```

The update workflow verifies deterministic generation, proposes scheduled
catalog updates, and produces advisory website-health output. Redirects,
outages, and uncertain mappings are never applied automatically.

See [Contributing](../CONTRIBUTING.md) for catalog-editing rules.
