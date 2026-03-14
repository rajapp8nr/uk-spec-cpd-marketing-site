# CPDPath Marketing Site

SEO-focused marketing website for **CPDPath** (`cpdpath.com`).

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
