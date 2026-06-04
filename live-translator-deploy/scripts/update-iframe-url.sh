#!/usr/bin/env bash
# ============================================================================
#  update-iframe-url.sh -- patch Lingo PWA's iframe data-live-url
# ============================================================================
#
#  After deploying live-translator to Cloud Run, run this to update the
#  Lingo PWA's index.html so the embedded iframe points to your service.
#
#  Usage:
#    ./scripts/update-iframe-url.sh                              # auto-fetch
#    ./scripts/update-iframe-url.sh https://my-app.run.app      # explicit URL
#    ./scripts/update-iframe-url.sh -p proj -r region           # lookup args
#    ./scripts/update-iframe-url.sh --check                     # verify only
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$DEPLOY_DIR/.." && pwd)"
LINGO_INDEX="$WORKSPACE_DIR/index.html"
CHECK_ONLY=false
EXPLICIT_URL=""

# Forward args to get-live-url.sh
FETCH_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)         CHECK_ONLY=true; shift ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    http://|https://)
      EXPLICIT_URL="$1"; shift ;;
    *)
      FETCH_ARGS+=("$1"); shift ;;
  esac
done

if [[ -z "$EXPLICIT_URL" ]]; then
  echo "Fetching deployed URL via get-live-url.sh..."
  EXPLICIT_URL="$("$SCRIPT_DIR/get-live-url.sh" "${FETCH_ARGS[@]}")"
fi

# Basic URL sanity check
if [[ ! "$EXPLICIT_URL" =~ ^https://[a-z0-9.-]+\.run\.app/?$ ]]; then
  echo "ERROR: URL does not look like a Cloud Run URL: $EXPLICIT_URL" >&2
  exit 1
fi

if [[ ! -f "$LINGO_INDEX" ]]; then
  echo "ERROR: Lingo PWA not found at $LINGO_INDEX" >&2
  exit 1
fi

# ---- check mode ----
if [[ "$CHECK_ONLY" == true ]]; then
  if grep -q "data-live-url=\"$EXPLICIT_URL\"" "$LINGO_INDEX"; then
    echo "OK: index.html already points to $EXPLICIT_URL"
    exit 0
  else
    echo "MISMATCH: index.html does NOT point to $EXPLICIT_URL"
    grep -E "data-live-url=" "$LINGO_INDEX" | head -1
    exit 1
  fi
fi

# ---- patch ----
echo "Current iframe URL:"
grep -E "data-live-url=" "$LINGO_INDEX" | head -1
echo

# Use python for safe in-place edit
python3 - <<PY
import re, sys
path = "$LINGO_INDEX"
new_url = "$EXPLICIT_URL"
with open(path) as f:
    content = f.read()

# Replace any existing data-live-url="..." value with the new one
new_content, n = re.subn(
    r'(data-live-url=")[^"]*(")',
    r'\1' + new_url + r'\2',
    content,
    count=1,
)
if n == 0:
    print("ERROR: no data-live-url attribute found in index.html", file=sys.stderr)
    sys.exit(1)
with open(path, "w") as f:
    f.write(new_content)
print(f"Patched {n} occurrence(s).")
PY

echo
echo "New iframe URL:"
grep -E "data-live-url=" "$LINGO_INDEX" | head -1
echo
echo "Next steps:"
echo "  cd $WORKSPACE_DIR"
echo "  git diff index.html   # review the change"
echo "  git add index.html && git commit -m 'M2: update live-translator URL to $EXPLICIT_URL'"
echo "  git push origin main  # GitHub Pages will auto-rebuild"
