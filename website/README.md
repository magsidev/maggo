# Maggo — Official Landing Page & Commercial Website

> Fast, modern, single-page landing site built with **Astro 5+** and pure native CSS.  
> Designed with Apple-like restraint and indie Mac utility aesthetics.

---

## Features

- ⚡ **Zero JS Bloat:** Pure static HTML with instantaneous loads (&lt;1s build time).
- 🧭 **Interactive macOS Window Mockup:** Interactive tabs, live Split View toggle (`⌘⇧S`), and Move To (`⌘⇧M`) destination picker preview.
- 🎯 **Topical SEO Hierarchy:**
  - One clean semantic `<h1>`: `A better file manager for Mac.`
  - 7 topical `<h2>` sections covering the problem, features, familiar design, use cases, Finder comparison, pricing, and FAQ.
  - JSON-LD Structured Data (`SoftwareApplication` & `FAQPage`) for rich snippets on Google.
- 📦 **Direct Downloads & 1-Line Web Installer:** Serves the actual release `.dmg`, `.zip`, and `install.sh` from `/downloads/`.

---

## Commands

All commands are run from the `website/` directory:

```bash
# Run local development server (http://localhost:4321)
npm run dev

# Build production static site to ./dist/
npm run build

# Preview production build locally
npm run preview
```

---

## Deployment

Because the site builds to a static `./dist/` directory, it can be deployed to:
- **Cloudflare Pages:** Build command `npm run build`, output directory `dist`
- **Vercel:** Auto-detected as Astro
- **GitHub Pages:** Deploy `./dist` folder or use GitHub Action
- **Netlify:** Build command `npm run build`, publish directory `dist`
