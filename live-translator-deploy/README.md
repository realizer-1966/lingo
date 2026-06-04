# live-translator-deploy

Deployment tooling for the **Live Translate** feature in the Lingo PWA.

This directory is a **deploy-only toolkit** for `kazunori279/live-translator`
(Apache-2.0) — it does **not** contain the live-translator source. The
upstream is cloned on demand by `scripts/deploy.sh` (or referenced as a path
in CI).

## Why this exists

Lingo PWA (a static GitHub Pages app) integrates the live-translator voice
translation app via an `<iframe>`. The iframe needs the deployed Cloud Run
URL. This repo gives you:

| File | Purpose |
|---|---|
| `scripts/deploy.sh` | Local deploy with `gcloud` (interactive or `--dry-run`) |
| `scripts/get-live-url.sh` | Look up the deployed service URL |
| `scripts/update-iframe-url.sh` | Patch Lingo's `index.html` to point at the URL |
| `.github/workflows/deploy.yml` | CI/CD: push to main -> Cloud Run + auto-update Lingo |

## Quick start (local)

```bash
# 1. Authenticate
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT

# 2. Set your API key (Gemini Live)
export GEMINI_LIVE_KEY=*** --dry-run             # preview the deploy command
./scripts/deploy.sh                 # actually deploy (5-10 min first time)

# 3. (Optional) auto-patch Lingo PWA's index.html
./scripts/update-iframe-url.sh      # uses the just-deployed URL

# 4. Commit and push Lingo
cd ..
git add index.html
git commit -m "M2: update live-translator URL"
git push origin main
```

## Quick start (CI/CD)

See `.github/workflows/deploy.yml`. The recommended path is **Workload
Identity Federation** (no JSON keys in GitHub). Set these four secrets in
your repo:

| Secret | Example |
|---|---|
| `GCP_PROJECT_ID` | `my-gcp-project` |
| `GCP_WORKLOAD_IDP` | `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT` | `github-deployer@my-gcp-project.iam.gserviceaccount.com` |
| `GEMINI_LIVE_KEY` | *(your key)* |

Or, for simpler setup, set `GCP_SA_KEY` to a base64-encoded service account
JSON key (less secure, but works without WIF).

## Layout

```
live-translator-deploy/
├── README.md                          (this file)
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy.yml                 (Cloud Run CI/CD)
└── scripts/
    ├── deploy.sh                      (local: gcloud run deploy)
    ├── get-live-url.sh                (look up URL)
    └── update-iframe-url.sh           (patch Lingo PWA)
```

## Common tasks

### Change region

```bash
./scripts/deploy.sh -r asia-northeast3    # Seoul
./scripts/deploy.sh -r europe-west1       # Belgium
```

### Use a different service name

```bash
./scripts/deploy.sh -s lingo-live
./scripts/update-iframe-url.sh -s lingo-live
```

### Just check what URL is currently live

```bash
./scripts/get-live-url.sh
# or
./scripts/get-live-url.sh -p my-project -r asia-northeast3
```

### Verify Lingo PWA points at the right URL

```bash
./scripts/update-iframe-url.sh --check
```

### Re-deploy after live-translator upstream changes

```bash
./scripts/deploy.sh                    # pulls latest from kazunori279
```

## License

This deploy tooling is MIT. The deployed service is
[kazunori279/live-translator](https://github.com/kazunori279/live-translator)
under Apache-2.0.
