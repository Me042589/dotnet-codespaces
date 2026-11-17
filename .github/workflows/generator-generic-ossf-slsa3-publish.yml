#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE="@decimalturn/toml-patch@3.0.2"

command -v node >/dev/null 2>&1 || {
  echo "Missing required command: node" >&2
  exit 1
}

command -v npx >/dev/null 2>&1 || {
  echo "Missing required command: npx" >&2
  exit 1
}

PACKAGE_ROOT="$(npx --yes --package="$PACKAGE" sh -c 'dirname "${PATH%%:*}"')"
TOML_PATCH_MODULE="$PACKAGE_ROOT/@decimalturn/toml-patch/dist/toml-patch.js"

if [[ ! -f "$TOML_PATCH_MODULE" ]]; then
  echo "Unable to load $PACKAGE through npx" >&2
  exit 1
fi

CODEX_RECOMMENDED_CONFIG="$REPO_DIR/recommended-config.toml" \
TOML_PATCH_MODULE="$TOML_PATCH_MODULE" \
  node "$REPO_DIR/scripts/update-config.mjs" "$@"
