import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// GitHub Pages fournit dynamiquement l'origine et le chemin de base.
// En local (ou hors GitHub Actions), on conserve le domaine final.
const site = process.env.PAGES_ORIGIN || 'https://auvergneinfo.fr';
const base = process.env.PAGES_BASE_PATH || undefined;

export default defineConfig({
  site,
  base,
  integrations: [sitemap()],
  trailingSlash: 'always'
});
