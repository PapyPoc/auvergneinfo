type PostLike = {
  body?: string;
  data?: {
    image?: string;
  };
};

export const DEFAULT_POST_IMAGE = 'uploads/2025/01/pdd.jpg';

/**
 * Retourne l'image uniquement si elle constitue le premier contenu réel de l'article.
 * Prend en charge les articles WordPress importés (<figure><img ...>) ainsi que
 * les images Markdown placées en première position.
 */
export function extractLeadingPostImage(body = ''): string {
  const content = body
    .replace(/^\uFEFF/, '')
    .replace(/^(?:\s|<!--(?:.|\n|\r)*?-->)+/, '')
    .trimStart();

  const htmlFigure = /^<figure\b[^>]*>\s*<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["'][^>]*>/i.exec(content);
  if (htmlFigure?.[1]) return htmlFigure[1];

  const htmlImage = /^<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["'][^>]*>/i.exec(content);
  if (htmlImage?.[1]) return htmlImage[1];

  const markdownImage = /^!\[[^\]]*\]\(\s*<?([^\s)>]+)>?(?:\s+["'][^"']*["'])?\s*\)/i.exec(content);
  if (markdownImage?.[1]) return markdownImage[1];

  return '';
}

/**
 * Transforme un chemin d'image d'article en URL compatible avec BASE_URL Astro.
 */
export function resolvePostImageSource(src: string, base: string): string {
  const value = src.trim();
  if (!value) return '';

  if (/^(?:https?:)?\/\//i.test(value) || /^(?:data|blob):/i.test(value)) {
    return value;
  }

  // Les articles WordPress importés peuvent encore contenir ../../uploads/...
  const clean = value
    .replace(/^\.\//, '')
    .replace(/^(?:\.\.\/)+/, '')
    .replace(/^\/+/, '');

  return `${base}${clean}`;
}

/**
 * Règle commune à tout le site :
 * 1. `image:` dans le frontmatter permet de forcer une vignette ;
 * 2. sinon, utiliser l'image si elle est le premier contenu de l'article ;
 * 3. sinon, utiliser automatiquement pdd.jpg.
 */
export function getPostImage(post: PostLike, base: string): string {
  const declaredImage = post?.data?.image?.trim();
  const leadingImage = extractLeadingPostImage(post?.body ?? '');
  return resolvePostImageSource(declaredImage || leadingImage || DEFAULT_POST_IMAGE, base);
}
