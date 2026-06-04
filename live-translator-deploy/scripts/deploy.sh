#!/usr/bin/env bash
# ============================================================================
#  deploy.sh -- live-translator to Cloud Run
# ============================================================================
#
#  Lingo PWA M1 integration. Deploys kazunori279/live-translator (Apache-2.0)
#  to Google Cloud Run and prints the public URL.
#
#  USAGE
#    ./scripts/deploy.sh                          use gcloud config defaults
#    ./scripts/deploy.sh -p my-gcp-project        override project
#    ./scripts/deploy.sh -r asia-northeast3       region (Seoul)
#    ./scripts/deploy.sh -s live-translation      service name
#    ./scripts/deploy.sh -i 2                     min/max instances
#    ./scripts/deploy.sh -t 7200                  WebSocket timeout (sec)
#    ./scripts/deploy.sh -k YOUR_KEY              pass API key directly
#    ./scripts/deploy.sh --no-clone               assume already cloned
#    ./scripts/deploy.sh --skip-iam               skip API enablement check
#    ./scripts/deploy.sh --dry-run                print command, do not run
# ============================================================================

set -euo pipefail

# ---- defaults ----
PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null || echo "")}"
REGION="${REGION:-us-central1}"
SERVICE="${SERVICE:-live-translation}"
INSTANCES="${INSTANCES:-1}"
TIMEOUT="${TIMEOUT:-3600}"
MEMORY="${MEMORY:-1Gi}"
CPU="${CPU:-1}"
CONCURRENCY="${CONCURRENCY:-10}"
API_KEY_VAR="GEMINI_LIVE_KEY"
API_KEY_VAR_BACKUP="LT_API_KEY"
API_KEY="${!API_KEY_VAR:-${!API_KEY_VAR_BACKUP:-}}"

# ---- colors (only when stdout is a TTY) ----
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[1;33m'
  BLU=$'\033[0;34m'; DIM=$'\033[2m'; BLD=$'\033[1m'; RST=$'\033[0m'
else
  RED=''; GRN=''; YEL=''; BLU=''; DIM=''; BLD=''; RST=''
fi

# ---- option parsing ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)     PROJECT="$2";     shift 2 ;;
    -r|--region)      REGION="$2";      shift 2 ;;
    -s|--service)     SERVICE="$2";     shift 2 ;;
    -i|--instances)   INSTANCES="$2";   shift 2 ;;
    -t|--timeout)     TIMEOUT="$2";     shift 2 ;;
    -m|--memory)      MEMORY="$2";      shift 2 ;;
    -c|--cpu)         CPU="$2";         shift 2 ;;
    -n|--concurrency) CONCURRENCY="$2"; shift 2 ;;
    -k|--api-key)     API_KEY="$2";     shift 2 ;;
    --no-clone)       NO_CLONE=true;    shift   ;;
    --skip-iam)       SKIP_IAM_CHECK=true; shift ;;
    --dry-run)        DRY_RUN=true;     shift   ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *) echo "${RED}Unknown option:${RST} $1" >&2; exit 1 ;;
  esac
done

# ---- helpers ----
err()  { echo "${RED}ERROR:${RST} $*" >&2; exit 1; }
warn() { echo "${YEL}WARN:${RST}  $*" >&2; }
info() { echo "${BLU}INFO:${RST}  $*"; }
ok()   { echo "${GRN}OK:${RST}    $*"; }

# ---- validate ----
[[ -z "$PROJECT" ]] && err "GCP project not set. export GCP_PROJECT=... or gcloud config set project ..."
[[ -z "$API_KEY" ]] && err "Gemini API key required. Set GEMINI_LIVE_KEY env var or pass -k KEY. Get one at https://aistudio.google.com/apikey"
command -v gcloud >/dev/null 2>&1 || err "gcloud CLI not found. Install from https://cloud.google.com/sdk/docs/install"

# ---- resolve paths ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$DEPLOY_DIR/.." && pwd)"
LIVE_TRANSLATOR_DIR="$WORKSPACE_DIR/live-translator"

# ---- ensure live-translator source is present ----
if [[ "$NO_CLONE" == false ]]; then
  if [[ -d "$LIVE_TRANSLATOR_DIR/.git" ]]; then
    info "Found live-translator/, trying fast-forward pull..."
    (cd "$LIVE_TRANSLATOR_DIR" && git pull --ff-only 2>&1 | sed "s/^/  /" || warn "pull failed (continuing)")
  elif [[ -d "$LIVE_TRANSLATOR_DIR" ]]; then
    warn "$LIVE_TRANSLATOR_DIR is not a git clone. Use --no-clone to skip clone step."
  else
    info "Cloning kazunori279/live-translator..."
    git clone --depth 1 https://github.com/kazunori279/live-translator.git "$LIVE_TRANSLATOR_DIR" \
      || err "clone failed"
  fi
fi

if [[ ! -f "$LIVE_TRANSLATOR_DIR/app/main.py" ]]; then
  err "live-translator source not found at $LIVE_TRANSLATOR_DIR/app/main.py
  Clone it first, or use --no-clone and point LIVE_TRANSLATOR_DIR to a valid path."
fi

# ---- build gcloud command ----
GCLOUD_CMD=(
  gcloud run deploy "$SERVICE"
  --source "$LIVE_TRANSLATOR_DIR"
  --project "$PROJECT"
  --region "$REGION"
  --allow-unauthenticated
  --timeout "$TIMEOUT"
  --memory "$MEMORY"
  --cpu "$CPU"
  --concurrency "$CONCURRENCY"
  --min-instances "$INSTANCES"
  --max-instances "$INSTANCES"
  --set-env-vars "${API_KEY_VAR}=${API_KEY}"
)

# ---- print banner ----
echo "${BLU}================================================================${RST}"
echo "${BLD}  Live Translator -> Cloud Run deploy${RST}"
echo "${BLU}================================================================${RST}"
echo "  ${DIM}project${RST}     $PROJECT"
echo "  ${DIM}region${RST}      $REGION"
echo "  ${DIM}service${RST}     $SERVICE"
echo "  ${DIM}instances${RST}   min=$INSTANCES max=$INSTANCES"
echo "  ${DIM}timeout${RST}     ${TIMEOUT}s"
echo "  ${DIM}memory${RST}      $MEMORY  ${DIM}cpu${RST} $CPU  ${DIM}concurrency${RST} $CONCURRENCY"
echo "  ${DIM}source${RST}      $LIVE_TRANSLATOR_DIR"
echo "  ${DIM}dry-run${RST}     $DRY_RUN"
echo "${BLU}================================================================${RST}"

# ---- dry-run short circuit ----
if [[ "$DRY_RUN" == true ]]; then
  echo
  echo "${YEL}(DRY-RUN) command that would be executed:${RST}"
  printf '  %q ' "${GCLOUD_CMD[@]}"; echo
  echo
  info "Re-run without --dry-run to actually deploy."
  exit 0
fi

# ---- enable APIs (idempotent) ----
if [[ "$SKIP_IAM_CHECK" == false ]]; then
  info "Checking required APIs..."
  for api in run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com; do
    if ! gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" 2>/dev/null \
        | grep -q "^${api}$"; then
      info "Enabling $api..."
      gcloud services enable "$api" --project="$PROJECT" 2>&1 | sed 's/^/  /' \
        || err "Failed to enable $api. Run manually: gcloud services enable $api --project=$PROJECT"
    fi
  done
fi

# ---- deploy ----
echo
info "Building and deploying (first time 5-10 min, subsequent 2-3 min)..."
echo
"${GCLOUD_CMD[@]}" || err "Deploy failed. See gcloud output above."

# ---- result ----
SERVICE_URL="$("$SCRIPT_DIR/get-live-url.sh" -p "$PROJECT" -r "$REGION" -s "$SERVICE" 2>/dev/null || echo '(URL lookup failed)')"

echo
echo "${GRN}================================================================${RST}"
echo "${GRN}${BLD}  Deploy complete!${RST}"
echo "${GRN}================================================================${RST}"
echo "  ${BLD}Service URL:${RST} $SERVICE_URL"
echo

LINGO_INDEX="$WORKSPACE_DIR/index.html"
if [[ -f "$LINGO_INDEX" ]]; then
  echo "${BLU}Next step -- update Lingo PWA iframe URL:${RST}"
  echo "  $DEPLOY_DIR/scripts/update-iframe-url.sh $SERVICE_URL"
  echo
fi

echo "${BLU}Health check:${RST}"
echo "  curl -sI $SERVICE_URL | head -1"
echo
echo "${BLU}WebSocket smoke test (5s):${RST}"
echo "  websocat ${SERVICE_URL}/ws/smoke/smoke-${RANDOM}?source=en&target=ja"
echo "${GRN}================================================================${RST}"
