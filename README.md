# AuvergneInfo.fr

Site statique Astro publié sur GitHub Pages.

## Fonctionnement

- articles : `src/data/posts/*.md`
- génération : Astro
- déploiement : GitHub Actions
- hébergement : GitHub Pages
- domaine : `auvergneinfo.fr`
- RSS : `/rss.xml`
- sitemap : généré automatiquement

## Développement local

```bash
npm install
npm run dev
```

Build de production :

```bash
npm run build
```

## Publier depuis GitHub sans ligne de commande

1. Ouvrir **Issues**.
2. Cliquer sur **New issue**.
3. Choisir **Publier un article**.
4. Remplir le titre, le résumé, la catégorie, les tags et le contenu Markdown.
5. Créer l'issue.

Le workflow `.github/workflows/publier-article.yml` :

- convertit automatiquement l'issue en Markdown ;
- ajoute le fichier dans `src/data/posts/` ;
- ferme l'issue ;
- le push déclenche ensuite le workflow de déploiement.

### Image utilisée pour les vignettes

La même règle est appliquée aux cartes d'articles, aux suggestions de la page d'accueil et au bandeau Breakings :

1. si le champ **Image principale** est rempli dans le formulaire GitHub, cette image est utilisée ;
2. sinon, si le **tout premier contenu** de l'article est une image, cette image est utilisée ;
3. sinon, le site utilise automatiquement `public/uploads/2025/01/pdd.jpg`.

Une image placée plus loin dans l'article ne remplace donc pas automatiquement la vignette.

## Publier manuellement un article

Créer un fichier dans `src/data/posts/`, par exemple :

```md
---
title: "Titre de l'article"
description: "Résumé court."
pubDate: 2026-08-28T12:00:00+02:00
author: "AuvergneInfo"
category: "Actualités"
tags: ["auvergne", "information"]
featured: false
draft: false
---

Contenu de l'article en Markdown.
```

Pour forcer une vignette spécifique, ajouter par exemple :

```yaml
image: "uploads/2026/08/mon-image.jpg"
```

Sans champ `image:`, une image placée en première position dans le contenu sera utilisée. Si l'article commence par du texte ou un titre, `pdd.jpg` sera utilisée automatiquement.

Pour préparer un article sans le publier, mettre `draft: true`.

## Configuration GitHub Pages

Dans le dépôt :

1. **Settings → Pages**
2. Source : **GitHub Actions**
3. Custom domain : `auvergneinfo.fr`
4. Activer **Enforce HTTPS** lorsque le certificat est disponible.

## DNS

Pour utiliser le domaine racine `auvergneinfo.fr` directement sur GitHub Pages :

```text
@    A      185.199.108.153
@    A      185.199.109.153
@    A      185.199.110.153
@    A      185.199.111.153
www  CNAME  papypoc.github.io.
```

Important : ces enregistrements concernent uniquement le site web. Conserver les enregistrements de messagerie existants (`MX`, SPF, DKIM, DMARC, `smtp`, `imap`, `pmg`, etc.).

## Déploiement

Tout push sur `main` lance `.github/workflows/deploy.yml` et publie automatiquement la nouvelle version.
