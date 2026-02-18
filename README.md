# UK-SPEC CPD Marketing Site

Professional, SEO-friendly marketing website for the UK-SPEC CPD Portal.

## Local preview

Open `index.html` directly in the browser, or run a quick static server:

```bash
python3 -m http.server 8080
```

Then visit: `http://localhost:8080`

## Notes before launch

- Replace `https://example.com` in:
  - `index.html` (canonical + OG URL)
  - `robots.txt`
  - `sitemap.xml`
- Update `hello@example.com` CTA email in `index.html`
- Optionally add a custom OG image and favicon assets

## Deployment (Task 2)

This repo is ready for **Vercel** or **Netlify** static deployment.

### Vercel

1. Import repo in Vercel: `rajapp8nr/uk-spec-cpd-marketing-site`
2. Framework preset: **Other**
3. Build command: *(leave empty)*
4. Output directory: `.`
5. Deploy

`vercel.json` is included for clean URLs and security headers.

### Netlify

1. Import repo in Netlify
2. Build command: *(leave empty)*
3. Publish directory: `.`
4. Deploy

`netlify.toml` is included and configured for static publish + SPA-style fallback.
