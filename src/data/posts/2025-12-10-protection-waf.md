---
title: "Le WAF"
description: "Un WAF (Web Application Firewall) est un pare-feu applicatif web . Sa mission principale : protéger les applications web (sites, API, applications métiers) contre les attaques ciblant leurs failles ou leurs comporteme…"
pubDate: "2025-12-10T18:56:56+01:00"
updatedDate: "2025-12-10T20:04:51+01:00"
author: "poc"
category: "Explication"
tags: []
featured: false
draft: false
---
<p>Un <strong>WAF</strong> (Web Application Firewall) est un <strong>pare-feu applicatif web</strong>.<br>Sa mission principale : <strong>protéger les applications web</strong> (sites, API, applications métiers) contre les attaques ciblant leurs failles ou leurs comportements.</p>

<h1 class="wp-block-heading">Définition simple</h1>

<p>Un <strong>WAF analyse le trafic HTTP/HTTPS</strong> entre un utilisateur et une application web.<br>Il filtre, bloque ou laisse passer les requêtes en fonction de règles de sécurité.</p>

<p>Il agit <strong>au niveau applicatif (couche 7 du modèle OSI)</strong>, contrairement aux firewalls traditionnels qui se concentrent sur les couches réseau.</p>

<h1 class="wp-block-heading">Ce que protège un WAF</h1>

<p>Un WAF permet de contrer des attaques courantes telles que :</p>

<h3 class="wp-block-heading">✔️ Injection SQL</h3>

<p>Tentatives d’injections dans les champs de formulaires ou URLs.</p>

<h3 class="wp-block-heading">✔️ Cross-Site Scripting (XSS)</h3>

<p>Scripts malveillants insérés dans les pages pour voler des données ou modifier le comportement.</p>

<h3 class="wp-block-heading">✔️ Cross-Site Request Forgery (CSRF)</h3>

<p>Utilisation d’un utilisateur légitime pour exécuter des actions à son insu.</p>

<h3 class="wp-block-heading">✔️ Attaques sur les cookies/session</h3>

<p>Vol ou manipulation de tokens, fixation de session, etc.</p>

<h3 class="wp-block-heading">✔️ Exposition d’informations sensibles</h3>

<p>Bloque les fuites d’erreurs serveurs, données internes, etc.</p>

<h3 class="wp-block-heading">✔️ Bots / scans automatisés</h3>

<p>Bloque les outils d’attaque automatisés, brute force, scraping massif…</p>

<h3 class="wp-block-heading">✔️ Attaques Zero-day (selon les WAF)</h3>

<p>Les WAF avancés utilisent des mécanismes comportementaux ou d'IA pour détecter des patterns anormaux.</p>

<h1 class="wp-block-heading">Comment fonctionne un WAF ?</h1>

<p>Un WAF peut fonctionner selon 3 modes :</p>

<h3 class="wp-block-heading"><strong>1. Mode liste noire (signature-based)</strong></h3>

<p>Il bloque les requêtes correspondant à des attaques connues.<br>→ Exemple : une requête contenant <code>' OR 1=1</code> déclenche une alerte.</p>

<h3 class="wp-block-heading"><strong>2. Mode liste blanche (policy-based)</strong></h3>

<p>L’application ne peut recevoir que des requêtes conformes à un schéma défini.<br>→ Très sécurisé, utilisé pour des environnements critiques.</p>

<h3 class="wp-block-heading"><strong>3. Mode heuristique / comportemental</strong></h3>

<p>Analyse du comportement des utilisateurs et détection de requêtes anormales.</p>

<p>Les WAF modernes combinent les trois.</p>

<h1 class="wp-block-heading">Où s'intègre un WAF ?</h1>

<p>Un WAF peut être placé :</p>

<ul class="wp-block-list">
<li><strong>Sur un serveur physique/dédié</strong></li>
<li><strong>En appliance virtuelle</strong></li>
<li><strong>Dans le cloud</strong> (AWS WAF, Cloudflare WAF, Azure Front Door…)</li>
<li><strong>Intégré dans un reverse proxy</strong> (Nginx + ModSecurity)</li>
</ul>

<p>Il se place <strong>devant l’application web</strong>, entre les utilisateurs et le serveur web.</p>

<h1 class="wp-block-heading">Exemple d’utilisation typique</h1>

<p>➡️ Un site e-commerce subit des injections SQL dans son formulaire de recherche.<br>➡️ Le WAF détecte la requête suspecte.<br>➡️ Il la bloque <strong>avant qu’elle n’atteigne le serveur</strong>.<br>➡️ Le site reste opérationnel et l’attaque est consignée dans les logs.</p>

<h1 class="wp-block-heading">Avantages d’un WAF</h1>

<ul class="wp-block-list">
<li>Réduit fortement les risques liés aux failles applicatives.</li>
<li>Protège les applications même si le code n’est pas parfait.</li>
<li>Intègre des mises à jour automatiques contre les nouvelles attaques.</li>
<li>Fournit logs, alertes, tableaux de bord de sécurité.</li>
<li>Facilite la conformité (PCI-DSS, RGPD dans certains cas).</li>
</ul>

<h1 class="wp-block-heading">Limites d’un WAF</h1>

<ul class="wp-block-list">
<li>Un mauvais paramétrage peut <strong>bloquer du trafic légitime</strong>.</li>
<li>Ne remplace pas les bonnes pratiques :
<ul class="wp-block-list">
<li>développement sécurisé</li>
<li>patch management</li>
<li>scans de vulnérabilité</li>
</ul>
</li>
<li>Peut être contourné si mal placé ou mal configuré.</li>
</ul>

<h1 class="wp-block-heading">Résumé en une phrase</h1>

<p><strong>Un WAF est un bouclier spécialisé qui protège les applications web contre les attaques qui exploitent leurs failles et leurs données.</strong></p>
