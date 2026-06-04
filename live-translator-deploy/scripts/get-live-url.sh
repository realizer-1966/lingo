#!/usr/bin/env bash
# ============================================================================
#  get-live-url.sh -- look up the deployed Cloud Run URL
# ============================================================================
#  Usage:
#    ./scripts/get-live-url.sh                       # from gcloud config
#    ./scripts/get-live-url.sh -p project -r region -s service
#    ./scripts/get-live-url.sh --json                # emit raw JSON
# ============================================================================
set -euo pipefail

PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null || echo "")}"
REGION="${REGION:-us-central1}"
SERVICE="${SERVICE:-live-translation}"
JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project) PROJECT="$2"; shift 2 ;;
    -r|--region)  REGION="$2";  shift 2 ;;
    -s|--service) SERVICE="$2"; shift 2 ;;
    --json)       JSON=true;    shift ;;
    -h|--help)
      sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$PROJECT" ]] && { echo "ERROR: project not set" >&2; exit 1; }

if ! command -v gcloud >/dev/null 2>&1; then
  echo "ERROR: gcloud CLI not installed" >&2
  exit 1
fi

if [[ "$JSON" == true ]]; then
  gcloud run services describe "$SERVICE" \
    --project="$PROJECT" --region="$REGION" \
    --format="json" 2>/dev/null
else
  gcloud run services describe "$SERVICE" \
    --project="$PROJECT" --region="$REGION" \
    --format="value(status.url)" 2>/dev/null
fi
