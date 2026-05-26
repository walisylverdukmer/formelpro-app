# FormelPro — Conventions Assets

## Nommage obligatoire

- **lowercase** uniquement
- **snake_case** (underscores, pas de tirets ni d'espaces)
- Noms stables et descriptifs (pas de hash, pas de date, pas de "final2")
- Pas d'espaces, pas de majuscules, pas de caractères spéciaux

```
✅  fond_batiment.jpg
✅  plomberie_icon.png
✅  onboarding_client.webp
✅  no_results.png

❌  Fond_Batiment.JPG
❌  WhatsApp Image 2026-03-13.jpeg
❌  image_final2_vrai.png
```

---

## Formats recommandés

| Usage | Format | Raison |
|-------|--------|--------|
| Photos / fonds | `.jpg` | Compression, taille réduite |
| Logos / icônes | `.png` | Transparence |
| Illustrations UI | `.webp` | Meilleure compression mobile |
| Drapeaux / petites icônes | `.png` | Netteté pixel-perfect |

---

## Tailles recommandées

| Usage | Taille max | Résolution |
|-------|-----------|------------|
| Banners dashboard | 1200×400 px | 72 dpi |
| Cartes pays / hero | 800×500 px | 72 dpi |
| Catégories icônes | 256×256 px | 144 dpi |
| Avatars par défaut | 256×256 px | 144 dpi |
| Onboarding | 1080×1080 px | 72 dpi |
| Empty states illustrations | 400×400 px | 144 dpi |
| Logos / app icon | 1024×1024 px | 72 dpi |

Poids max par image : **500 KB**. Au-delà, compresser avec [Squoosh](https://squoosh.app) ou [TinyPNG](https://tinypng.com).

---

## Structure des dossiers

```
assets/images/
│
├── categories/          # Icônes / visuels par catégorie de service
│   └── plomberie.png
│   └── electricite.png
│   └── climatisation.png
│
├── metiers/             # Visuels illustrant les métiers (techniciens)
│   └── technicien_solaire.jpg
│   └── soudeur.jpg
│
├── onboarding/          # Écrans d'introduction (slides)
│   └── onboarding_client.webp
│   └── onboarding_technicien.webp
│   └── onboarding_welcome.webp
│
├── banners/             # Banners dashboard (hero CIV / CMR)
│   └── fond_ci.jpeg     # ← déjà utilisé dans accueil_client
│   └── fond_cmr.jpeg    # ← déjà utilisé dans accueil_client
│
├── avatars/             # Avatars par défaut (clients + techniciens)
│   └── avatar_default.png
│   └── avatar_technicien.png
│
├── illustrations/       # Illustrations génériques UI
│   └── success.webp
│   └── error.webp
│
├── localisation/        # Assets liés à la carte / géolocalisation
│   └── pin_civ.png
│   └── pin_cmr.png
│
└── empty_states/        # Illustrations états vides
    └── no_results.png
    └── no_notifications.png
    └── no_messages.png
    └── no_interventions.png
```

---

## Fichiers racine existants (assets/images/)

| Fichier | Usage actuel |
|---------|-------------|
| `logo.png` | Logo FormelPro (AppBar, splash) |
| `ci.jpg` / `ci.png` | Drapeau Côte d'Ivoire |
| `cmr.jpg` | Drapeau Cameroun |
| `tech_ci.jpg` | Photo technicien CIV (carte pays) |
| `tech_cmr.jpg` | Photo technicien CMR (carte pays) |
| `fond_ci.jpeg` | Hero banner dashboard CIV |
| `fond_cmr.jpeg` | Hero banner dashboard CMR |

---

## Déclaration pubspec.yaml

Chaque sous-dossier doit être déclaré explicitement dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/categories/
    - assets/images/metiers/
    - assets/images/onboarding/
    - assets/images/banners/
    - assets/images/avatars/
    - assets/images/illustrations/
    - assets/images/localisation/
    - assets/images/empty_states/
```

> **Note :** Flutter ne supporte pas les wildcards. Chaque nouveau sous-dossier doit être ajouté manuellement.

---

## Optimisation mobile/web

- Toujours utiliser `fit: BoxFit.cover` pour les images de fond
- Toujours fournir `errorBuilder` pour les `Image.asset` et `Image.network`
- Pour les images réseau : utiliser `cached_network_image` si ajouté en dépendance
- Éviter les images > 1 MB dans les assets Flutter (augmente la taille APK)
- Pour les SVG : ajouter `flutter_svg` en dépendance et stocker dans `assets/icons/`

---

## Workflow ajout d'une image

1. Compresser l'image (Squoosh ou TinyPNG)
2. Renommer en snake_case
3. Placer dans le bon sous-dossier
4. Vérifier que le dossier est bien déclaré dans `pubspec.yaml`
5. Référencer dans le code : `Image.asset('assets/images/categories/plomberie.png')`
