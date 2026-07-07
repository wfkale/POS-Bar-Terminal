# Deploy POS Bar Floor Terminal on Railway

Repository: **https://github.com/wfkale/POS-Bar-Terminal**

Deploy in the **same Railway project** as:

- `pos-bar-api` ([POS-Bar](https://github.com/wfkale/POS-Bar))
- `pos-bar-till` ([POS-Bar-Till](https://github.com/wfkale/POS-Bar-Till))

---

## 1. New service from GitHub

1. [railway.app](https://railway.app) → open your POS Bar project.
2. **+ New** → **GitHub Repo** → **`wfkale/POS-Bar-Terminal`**.
3. Rename the service to **`pos-bar-terminal`**.

Railway reads `railway.toml` and builds with the root `Dockerfile` (Flutter web → nginx).

First build may take **10–15 minutes**.

### Repo layout

```text
POS-Bar-Terminal/
├── packages/pos_bar_core/   ← copy from monorepo (see scripts/prepare-pwa-standalone.sh)
├── lib/
├── web/
├── Dockerfile
└── railway.toml
```

---

## 2. API URL (service variables)

| Variable | Production example |
|----------|-------------------|
| `API_BASE_URL` | `https://pos-bar-api-production.up.railway.app/api` |
| `ONLINE_API_BASE_URL` | `https://pos-bar-api-production.up.railway.app/api` |

Redeploy after changing variables. Verify at `https://YOUR-TERMINAL-URL/app-config.json`.

---

## 3. Networking

**Settings** → **Networking** → **Generate Domain**  
Example: `pos-bar-terminal-production.up.railway.app`

---

## 4. API CORS

Redeploy **`pos-bar-api`** after the terminal domain exists. `config/cors.php` allows `https://*.up.railway.app`.

---

## 5. Verify

1. Open the terminal Railway URL → staff splash screen.
2. Select staff → PIN login.
3. Floor home loads menu and tabs (no CORS errors).

---

## 6. Local dev

```bash
cd apps/bar_terminal
flutter pub get
flutter run -d chrome
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build timeout | Retry deploy |
| Missing `pos_bar_core` | Run `../../scripts/prepare-pwa-standalone.sh bar_terminal` before push |
| CORS errors | Redeploy API |
| Stale PWA | Hard refresh; check `/version.json` |
