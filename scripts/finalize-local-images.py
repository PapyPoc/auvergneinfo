from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
POSTS = ROOT / "src" / "data" / "posts"
PREFIX = "https://auvergneinfo.fr/wp-content/uploads/"

ALIASES = {
    "2025/01/cropped-pdd.jpg": "2025/01/pdd.jpg",
    "2026/01/Capture-decran-2025-12-10-162417.png": "2026/01/Capture-decran-2025-12-10-162425.png",
    "2026/01/Capture-decran-2025-12-10-162425-1.png": "2026/01/Capture-decran-2025-12-10-162425.png",
    "2026/01/Capture-decran-2026-01-13-130853-1.png": "2026/01/Capture-decran-2026-01-13-130853.png",
    "2026/01/Capture-decran-2026-01-13-131203-1.png": "2026/01/Capture-decran-2026-01-13-131203.png",
}


def canonical_rel(rel: str) -> str:
    # WordPress insère souvent une variante redimensionnée du type -1024x550.
    rel = re.sub(r"-\d+x\d+(?=\.[^.]+$)", "", rel)
    return ALIASES.get(rel, rel)


def replace_wp_url(match: re.Match[str]) -> str:
    rel = canonical_rel(match.group(1))
    return f"../../uploads/{rel}"


for post in sorted(POSTS.glob("*.md")):
    text = post.read_text(encoding="utf-8")
    text = re.sub(
        r"https://auvergneinfo\.fr/wp-content/uploads/([^\s\"<>]+)",
        replace_wp_url,
        text,
    )
    # Une image de frontmatter doit être résolue par Astro avec BASE_URL,
    # contrairement aux images HTML des articles qui sont relatives à /articles/<slug>/.
    text = re.sub(
        r'(?m)^image: "\.\./\.\./uploads/([^\"]+)"$',
        r'image: "uploads/\1"',
        text,
    )
    post.write_text(text, encoding="utf-8")

# Header : bannière locale, compatible GitHub Pages et futur domaine personnalisé.
header_path = ROOT / "src" / "components" / "Header.astro"
header = header_path.read_text(encoding="utf-8")
header = header.replace(
    'src="https://auvergneinfo.fr/wp-content/uploads/2025/12/cropped-A.png"',
    'src={`${base}uploads/2025/12/A.png`}',
)
header_path.write_text(header, encoding="utf-8")

# Cartes d'articles : les images locales du frontmatter doivent recevoir BASE_URL.
card_path = ROOT / "src" / "components" / "PostCard.astro"
card = card_path.read_text(encoding="utf-8")
if "const imageSrc =" not in card:
    card = card.replace(
        "const image = post.data.image;\n",
        "const image = post.data.image;\nconst imageSrc = image ? (image.startsWith('http') ? image : `${base}${image.replace(/^\\/+/, '')}`) : '';\n",
    )
card = card.replace('<img src={image} alt="" loading="lazy" />', '<img src={imageSrc} alt="" loading="lazy" />')
card_path.write_text(card, encoding="utf-8")

# Page d'article : même résolution BASE_URL pour l'image mise en avant.
article_path = ROOT / "src" / "pages" / "articles" / "[id].astro"
article = article_path.read_text(encoding="utf-8")
if "const imageSrc =" not in article:
    article = article.replace(
        "const base = import.meta.env.BASE_URL;\n",
        "const base = import.meta.env.BASE_URL;\nconst imageSrc = post.data.image ? (post.data.image.startsWith('http') ? post.data.image : `${base}${post.data.image.replace(/^\\/+/, '')}`) : '';\n",
    )
article = article.replace('src={post.data.image} alt=""', 'src={imageSrc} alt=""')
article_path.write_text(article, encoding="utf-8")

# Favicon : utiliser directement l'image fournie par l'utilisateur.
layout_path = ROOT / "src" / "layouts" / "BaseLayout.astro"
layout = layout_path.read_text(encoding="utf-8")
layout = layout.replace(
    '<link rel="icon" href={withBase(\'favicon.svg\')} type="image/svg+xml" />',
    '<link rel="icon" href={withBase(\'uploads/2025/01/cropped-pdd-32x32.jpg\')} type="image/jpeg" />',
)
layout_path.write_text(layout, encoding="utf-8")

# Validation : plus aucune dépendance aux uploads WordPress dans les articles/header.
remaining = []
for path in [*POSTS.glob("*.md"), header_path]:
    if PREFIX in path.read_text(encoding="utf-8"):
        remaining.append(str(path.relative_to(ROOT)))
if remaining:
    raise SystemExit(f"URLs WordPress restantes: {', '.join(remaining)}")

# Validation : chaque média local référencé dans les articles existe réellement.
missing = set()
for post in POSTS.glob("*.md"):
    text = post.read_text(encoding="utf-8")
    for rel in re.findall(r'image: "uploads/([^\"]+)"', text):
        if not (ROOT / "public" / "uploads" / rel).is_file():
            missing.add(f"uploads/{rel}")
    for rel in re.findall(r'\.\./\.\./uploads/([^\"\s<>]+)', text):
        if not (ROOT / "public" / "uploads" / rel).is_file():
            missing.add(f"uploads/{rel}")
if missing:
    raise SystemExit("Médias locaux manquants: " + ", ".join(sorted(missing)))

print("Migration locale terminée et validée.")
