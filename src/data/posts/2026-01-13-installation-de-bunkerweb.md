---
title: "Installation de BunkerWeb"
description: "Il existe plusieurs façons d'installer BunkerWeb, je vais me contenter de vous expliquer l'installation sur un Linux fraichement installer."
pubDate: "2026-01-13T11:58:33+01:00"
updatedDate: "2026-01-13T13:18:04+01:00"
author: "poc"
category: "Tutoriel"
tags: []
featured: true
draft: false
image: "uploads/2026/01/bunkerweb_logo.png"
---
<figure class="wp-block-image aligncenter size-full"><img src="../../uploads/2026/01/bunkerweb_logo.png" alt="" class="wp-image-154"/></figure>

<h1 class="wp-block-heading">Installation</h1>

<p>Il existe plusieurs façons d'installer BunkerWeb, je vais me contenter de vous expliquer l'installation sur un Linux fraichement installer.</p>

<p>Ma VM est installé avec Debian 12, une IP fixe lui a été attribuée</p>

<figure class="wp-block-image size-full"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-120513.png" alt="" class="wp-image-157"/></figure>

<p>On va utiliser la méthode officielle avec ce petit script:</p>

<pre class="wp-block-code"><code># Download the script and its checksum
curl -fsSL -O https://github.com/bunkerity/bunkerweb/releases/download/v1.6.6/install-bunkerweb.sh
curl -fsSL -O https://github.com/bunkerity/bunkerweb/releases/download/v1.6.6/install-bunkerweb.sh.sha256

# Verify the checksum
sha256sum -c install-bunkerweb.sh.sha256

# If the check is successful, run the script
chmod +x install-bunkerweb.sh</code></pre>

<figure class="wp-block-image aligncenter size-full"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162425.png" alt="" class="wp-image-158"/></figure>

<p>On tape la commande:</p>

<pre class="wp-block-code"><code>./install-bunkerweb.sh</code></pre>

<figure class="wp-block-image size-full"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162425.png" alt="" class="wp-image-160"/></figure>

<p>Il suffi juste de répondre au question posé</p>

<figure class="wp-block-image aligncenter size-full"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162510.png" alt="" class="wp-image-161"/><figcaption class="wp-element-caption">Choix du type d'installation</figcaption></figure>

<figure class="wp-block-image aligncenter size-full"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162537.png" alt="" class="wp-image-163"/><figcaption class="wp-element-caption">Choix des DNS à utilisé</figcaption></figure>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162550.png" alt="" class="wp-image-164"/><figcaption class="wp-element-caption">Choix de l'activation de CrowdSec</figcaption></figure>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162559.png" alt="" class="wp-image-165"/><figcaption class="wp-element-caption">Choix  de l'activation de l'API</figcaption></figure>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162608.png" alt="" class="wp-image-166"/><figcaption class="wp-element-caption">Configuration de CrowdSec AppSec Component</figcaption></figure>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162612.png" alt="" class="wp-image-167"/><figcaption class="wp-element-caption">Validation de l'ensemble des questions posé</figcaption></figure>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-162744.png" alt="" class="wp-image-168"/><figcaption class="wp-element-caption">Fin de l'installation</figcaption></figure>

<h2 class="wp-block-heading">Configuration</h2>

<p>On se connecter à l'adresse IP de notre machine puis on crée un compte</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163448.png" alt="" class="wp-image-169"/><figcaption class="wp-element-caption">Création d'un compte d'administration</figcaption></figure>

<p>Configuration de l'UI de BunkerWeb</p>

<figure class="wp-block-image aligncenter size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163456.png" alt="" class="wp-image-172"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163507.png" alt="" class="wp-image-173"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163514.png" alt="" class="wp-image-174"/></figure>

<p>Connexion à l'UI de BunkerWeb</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163541.png" alt="" class="wp-image-175"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163727.png" alt="" class="wp-image-176"/></figure>

<p>Modification de quelles règles globale</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163817.png" alt="" class="wp-image-177"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-163953.png" alt="" class="wp-image-178"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-164355.png" alt="" class="wp-image-179"/></figure>

<p>Création du service</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-164712.png" alt="" class="wp-image-183"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-164517.png" alt="" class="wp-image-180"/></figure>

<p>Test du service</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2025-12-10-164733.png" alt="" class="wp-image-184"/></figure>

<h2 class="wp-block-heading">Réglage du par feu (pfSense)</h2>

<p>Utilisation du service HAproxy de pfSense</p>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-130853.png" alt="" class="wp-image-204"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-130953.png" alt="" class="wp-image-202"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-131103.png" alt="" class="wp-image-205"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-131203.png" alt="" class="wp-image-208"/></figure>

<figure class="wp-block-image size-large"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-131407-2.png" alt="" class="wp-image-210"/></figure>

<p>Ouverture des ports sur le routeur</p>

<figure class="wp-block-image aligncenter size-full"><img src="../../uploads/2026/01/Capture-decran-2026-01-13-123915.png" alt="" class="wp-image-197"/></figure>
