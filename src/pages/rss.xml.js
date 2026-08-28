import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = (await getCollection('posts', ({ data }) => !data.draft))
    .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());

  const base = import.meta.env.BASE_URL;

  return rss({
    title: 'AuvergneInfo',
    description: 'Actualités, guides et informations publiés sur AuvergneInfo.fr',
    site: context.site,
    customData: '<language>fr-fr</language>',
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: `${base}articles/${post.id}/`,
      categories: [post.data.category, ...post.data.tags]
    }))
  });
}
