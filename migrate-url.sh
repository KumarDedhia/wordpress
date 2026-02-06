#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./migrate-url.sh <old_url> <new_url> [--apply]

Examples:
  ./migrate-url.sh https://beta.example.com https://example.com
  ./migrate-url.sh https://beta.example.com https://example.com --apply

By default this runs a dry run. Use --apply to perform changes.
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

OLD_URL="$1"
NEW_URL="$2"
APPLY="${3:-}"

compose_cmd=()
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  compose_cmd=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  compose_cmd=(docker-compose)
else
  echo "Error: docker compose or docker-compose is required." >&2
  exit 1
fi

DRY_RUN_FLAG="--dry-run"
if [[ "$APPLY" == "--apply" ]]; then
  DRY_RUN_FLAG=""
fi

if [[ -z "$DRY_RUN_FLAG" ]]; then
  echo "Running URL migration (apply mode)..."
else
  echo "Running URL migration (dry run)..."
fi

echo "Old URL: $OLD_URL"
echo "New URL: $NEW_URL"

"${compose_cmd[@]}" --profile tools run --rm backup wp search-replace \
  "$OLD_URL" "$NEW_URL" \
  --all-tables --precise --recurse-objects --skip-columns=guid \
  --path=/var/www/html --allow-root \
  ${DRY_RUN_FLAG}

if [[ -z "$DRY_RUN_FLAG" ]]; then
  "${compose_cmd[@]}" --profile tools run --rm backup wp option update home "$NEW_URL" --path=/var/www/html --allow-root
  "${compose_cmd[@]}" --profile tools run --rm backup wp option update siteurl "$NEW_URL" --path=/var/www/html --allow-root
  echo "URL migration complete."
else
  echo "Dry run complete. Re-run with --apply to perform changes."
fi
