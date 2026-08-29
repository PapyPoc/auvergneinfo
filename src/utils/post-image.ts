type PostLike = {
  body?: string;
  data?: {
    image?: string;
  };
};

/**
 * Retourne la première image rencontrée dans le contenu d'un article.
 * Les contenus HTML importés de WordPress et les images Markdown sont pris en charge.
 */
export function extractFirstPostImage(body = ''): string {
  const candidates: Array<{ index: number; src: string }> = [];

  const htmlImage = /<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["'][^>]*>/i.exec(body);
  if (htmlImage?.[1]) {
    candidates.push({ index: htmlImage.index, src: htmlImage[1] });
  }

  const markdownImage = /!\[[^\]]*\]\(\s*<?([^\s)>]+)>?(?:\s+["'][^"']*["'])?\s*\)/i.exec(body);
  if (markdownImage?.[1]) {
    candidates.push({ index: markdownImage.index, src: markdownImage[1] });
  }

  candidates.sort((a, b) => a.index - b.index);
  return candidates[0]?.src ?? '';
}

/**
 * Transforme un chemin d'image d'article en URL compatible avec le BASE_URL Astro.
 */
export function resolvePostImageSource(src: string, base: string): string {
  const value = src.trim();
  if (!value) return '';

  if (/^(?:https?:)?\/\//i.test(value) || /^(?:data|blob):/i.test(value)) {
    return value;
  }

  // Les anciens articles WordPress peuvent contenir ../../uploads/...
  const clean = value
    .replace(/^\.\//, '')
    .replace(/^(?:\.\.\/)+/, '')
    .replace(/^\/+/, '');

  return `${base}${clean}`;
}

/**
 * Priorité : image déclarée dans le frontmatter, puis première image du contenu.
 * Si aucune image n'existe, une chaîne vide est retournée afin que le composant
 * puisse utiliser sa vignette de secours.
 */
export function getPostImage(post: PostLike, base: string): string {
  const declaredImage = post?.data?.image?.trim();
  const firstContentImage = extractFirstPostImage(post?.body ?? '');
  return resolvePostImageSource(declaredImage || firstContentImage, base);
}
