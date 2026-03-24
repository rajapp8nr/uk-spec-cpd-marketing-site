# CPDPath Web (`cpdpath-web`)

SEO-focused marketing website for **CPDPath** (`cpdpath.com`).

## Repository structure

- `cpdpath-web` → marketing website (this repo)
- `cpdpath-app` → core product application (separate repo)

## Local preview

Open `index.html` directly in the browser, or run a quick static server:

```bash
python3 -m http.server 8080
```

Then visit: `http://localhost:8080`

## Production domain checklist

- Canonical + OG URLs point to `https://cpdpath.com/`
- `robots.txt` points to `https://cpdpath.com/sitemap.xml`
- CTA/contact emails should use `hello@cpdpath.com`
- Submit sitemap to Google Search Console and Bing Webmaster Tools

## Cloudflare Workers deployment

This repo is configured for **Cloudflare Workers static assets** via Wrangler.

### Files used

- `wrangler.toml`
- `src/worker.js`

### Deploy

```bash
# one-time auth
wrangler login

# deploy
wrangler deploy
```

### Optional: custom domain

In Cloudflare dashboard, attach `cpdpath.com` to this Worker route.

## SEO trust pages included

- `/privacy.html`
- `/terms.html`
- `/contact.html`
- `/thank-you.html` (conversion page, noindex)

## AI copy optimizer (GitHub Actions)

This repo includes an automated copy optimization workflow:

- Workflow: `.github/workflows/copy-optimizer.yml`
- Script: `scripts/copy_optimizer.rb`
- Output report: `copy/last-run.json`

### What it does

- Runs weekly (and on manual dispatch)
- Improves key homepage copy blocks in `index.html`
- Opens a PR with suggested changes for review

### Required secrets/variables

Set at repo level in GitHub:

- One API key secret:
  - `OPENROUTER_API_KEY` **or** `OPENAI_API_KEY` **or** `AI_API_KEY`
- Optional variables:
  - `AI_BASE_URL` (defaults to `https://openrouter.ai/api/v1`)
  - `AI_MODEL` (defaults to `openai/gpt-4o-mini`)
  - `AI_HTTP_REFERER` (optional, useful for OpenRouter ranking)

If no key is set, the workflow exits safely without changing files.
