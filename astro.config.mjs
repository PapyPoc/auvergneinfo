import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://auvergneinfo.fr',
  integrations: [sitemap()],
  trailingSlash: 'always'
});
