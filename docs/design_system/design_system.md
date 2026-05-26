# Design System — FormelPro "Soft Premium"

*Dernière mise à jour : 2026-05-26 — Session 8 : withValues migration, image cards, fonds écrans, badges disponibilité*

---

## 1. PRINCIPE DIRECTEUR

**"Soft Premium"** — L'app doit inspirer confiance et professionnalisme sans être froide.  
- Coins arrondis généreux
- Ombres légères (jamais lourdes)
- Fonds clairs sur fond sombre (dark theme principal)
- Couleur d'accent contextualisée par pays

---

## 2. PALETTE COULEURS

### 2.1 Couleurs fixes

```dart
// Fonds
const Color kDarkBg     = Color(0xFF0F172A);  // Fond principal dark (Slate 900)
const Color kNavyBg     = Color(0xFF1E293B);  // Fond secondaire (Slate 800)
const Color kLightBg    = Color(0xFFF8FAFC);  // Fond light (Slate 50)
const Color kCardDark   = Color(0xFF1E293B);  // Cards en fond dark

// Textes
const Color kTextPrimary   = Colors.white;
const Color kTextSecondary = Colors.white70;   // rgba(255,255,255,0.70)
const Color kTextDisabled  = Colors.white38;   // rgba(255,255,255,0.38)
const Color kTextLabel     = Colors.white24;   // Labels très discrets

// Séparateurs & borders
const Color kBorderSubtle  = Colors.white10;   // rgba(255,255,255,0.10)
const Color kBorderLight   = Colors.white24;   // rgba(255,255,255,0.24)

// Statuts
const Color kSuccess = Color(0xFF22C55E);  // Green 500
const Color kWarning = Color(0xFFF59E0B);  // Amber 500
const Color kError   = Color(0xFFEF4444);  // Red 500
const Color kInfo    = Color(0xFF3B82F6);  // Blue 500
```

### 2.2 Couleurs par pays (TOUJOURS depuis `userData['pays']`)

```dart
Color accentColor(String pays) {
  return pays == 'CIV'
      ? const Color(0xFFE67E22)   // Orange — Côte d'Ivoire
      : const Color(0xFFCE1126);  // Rouge — Cameroun
}

// Variante light pour fonds
Color accentColorLight(String pays) {
  return pays == 'CIV'
      ? const Color(0xFFE67E22).withValues(alpha: 0.15)
      : const Color(0xFFCE1126).withValues(alpha: 0.15);
}
```

### 2.3 Couleurs de statut interventions

```dart
Color statutColor(String statut) => switch (statut) {
  'en_attente' => const Color(0xFFF59E0B),  // Amber
  'accepte'    => const Color(0xFF3B82F6),  // Blue
  'en_cours'   => const Color(0xFF8B5CF6),  // Violet
  'termine'    => const Color(0xFF22C55E),  // Green
  'annule'     => const Color(0xFF6B7280),  // Gray
  _            => Colors.white38,
};
```

---

## 3. SPACING SYSTEM

Utiliser **uniquement** ces valeurs pour les espacements :

```dart
// Micro
const double kSp4  = 4;
const double kSp6  = 6;
const double kSp8  = 8;
const double kSp10 = 10;

// Standard
const double kSp12 = 12;
const double kSp14 = 14;
const double kSp16 = 16;
const double kSp20 = 20;

// Grand
const double kSp24 = 24;
const double kSp28 = 28;
const double kSp32 = 32;
const double kSp40 = 40;
const double kSp48 = 48;

// Padding horizontal page
const EdgeInsets kPagePadding = EdgeInsets.symmetric(horizontal: 24);
// Padding horizontal card
const EdgeInsets kCardPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
```

---

## 4. BORDER RADIUS STANDARDS

```dart
const double kRadiusXS  = 8;   // Petits éléments internes
const double kRadiusSM  = 12;  // Boutons secondaires, back buttons
const double kRadius    = 14;  // Chips, badges, inputs, items liste
const double kRadiusLG  = 20;  // Cards standards
const double kRadiusXL  = 22;  // Cards premium
const double kRadius2XL = 28;  // Bottom sheets
const double kRadius3XL = 35;  // Panneaux DraggableScrollableSheet
```

---

## 5. OMBRES

```dart
// Ombre légère (cards sur fond clair)
const kShadowLight = [
  BoxShadow(
    color: Color(0x0F000000),  // black 6%
    blurRadius: 12,
    offset: Offset(0, 4),
  )
];

// Ombre bouton accent (couleur dépend de accentColor)
List<BoxShadow> accentShadow(Color accent) => [
  BoxShadow(
    color: accent.withValues(alpha: 0.30),
    blurRadius: 12,
    offset: const Offset(0, 6),
  )
];

// Ombre dark premium
const kShadowDark = [
  BoxShadow(
    color: Color(0x33000000),  // black 20%
    blurRadius: 20,
    offset: Offset(0, 8),
  )
];
```

---

## 6. TYPOGRAPHIE

Toujours `GoogleFonts`. Deux familles :
- **Poppins** — Titres, labels importants, boutons
- **Inter** — Corps de texte, descriptions, données

```dart
// ━━━ TITRES ━━━
// Grand titre page
GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
// Titre section
GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)
// Titre card / modal
GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)
// Titre item
GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)

// ━━━ CORPS ━━━
// Corps principal
GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6)
// Corps secondaire
GoogleFonts.inter(fontSize: 13, color: Colors.white54)
// Note / caption
GoogleFonts.inter(fontSize: 12, color: Colors.white38)

// ━━━ LABELS SPÉCIAUX ━━━
// Tag métier / catégorie (majuscules)
GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: accentColor)
// Montant FCFA
GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)

// ━━━ BOUTONS ━━━
// Bouton primaire
GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)
// Bouton secondaire / texte
GoogleFonts.inter(fontSize: 13, color: accentColor)
```

---

## 7. COMPOSANTS STANDARDS

### 7.1 Card Standard (fond dark)

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.04),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
  ),
  child: ...,
)
```

### 7.2 Card Premium (avec accent)

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
    boxShadow: [
      BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
    ],
  ),
  child: ...,
)
```

### 7.3 Bouton Primaire (accent)

```dart
ElevatedButton(
  onPressed: _loading ? null : _onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    disabledBackgroundColor: Colors.white12,
    padding: const EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  child: _loading
      ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
      : Text("Label", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
)
```

### 7.4 Bouton Secondaire (ghost)

```dart
OutlinedButton(
  onPressed: onPressed,
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  child: Text("Label", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
)
```

### 7.5 Input Field

```dart
TextField(
  style: GoogleFonts.inter(color: Colors.white),
  decoration: InputDecoration(
    labelText: "Mon champ",
    labelStyle: GoogleFonts.inter(color: Colors.white54),
    hintText: "Saisir...",
    hintStyle: GoogleFonts.inter(color: Colors.white38),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: accentColor, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

### 7.6 Badge Statut

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: statutColor.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: statutColor.withValues(alpha: 0.30)),
  ),
  child: Text(
    label,
    style: GoogleFonts.inter(color: statutColor, fontSize: 11, fontWeight: FontWeight.w600),
  ),
)
```

### 7.7 SnackBar Standard

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
    backgroundColor: const Color(0xFF1E293B),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ),
);

// Variante succès
SnackBar(backgroundColor: const Color(0xFF166534), ...)  // Green dark
// Variante erreur
SnackBar(backgroundColor: const Color(0xFF991B1B), ...)  // Red dark
```

### 7.8 Bottom Sheet Standard

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF0F172A),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.only(
      left: 24, right: 24, top: 24,
      bottom: MediaQuery.of(context).viewInsets.bottom + 32,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Poignée obligatoire
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
          ),
        ),
        // Contenu...
      ],
    ),
  ),
);
```

### 7.9 Shimmer Loading (placeholder)

```dart
// Utiliser shimmer_flutter ou animation manuelle
AnimatedOpacity(
  opacity: _shimmerVisible ? 0.4 : 1.0,
  duration: const Duration(milliseconds: 800),
  child: Container(
    height: 80,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
  ),
)
```

### 7.10 Avatar Technicien (76×76px arrondi)

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(14),
  child: photoUrl != null
      ? Image.network(photoUrl, width: 76, height: 76, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarFallback())
      : _buildAvatarFallback(),
)

Widget _buildAvatarFallback() => Container(
  width: 76, height: 76,
  decoration: BoxDecoration(
    color: accentColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Icon(Icons.person_rounded, color: accentColor, size: 36),
);
```

### 7.11 Badge Disponibilité

```dart
// Trois états — chip coloré 10px
if (isOnline)    _chip(Color(0xFF22C55E), 'En ligne maintenant');
if (disponible)  _chip(Color(0xFF3B82F6), 'Disponible');
else             _chip(Color(0xFF94A3B8), 'Indisponible');

Widget _chip(Color color, String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withValues(alpha: 0.25)),
  ),
  child: Text(label, style: TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, color: color,
  )),
);
```

### 7.12 État vide (Empty State)

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
      const SizedBox(height: 16),
      Text(
        "Aucun élément pour l'instant",
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Text(
        "Description contextuelle ici",
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    ],
  ),
)
```

---

## 8. FONDS D'ÉCRANS PAR CONTEXTE

### 8.1 Mapping assets → écrans

| Asset | Écran | Overlay |
|-------|-------|---------|
| `assets/images/login_bg.jpeg` | Login (`page_connexion_principale.dart`) | Gradient `[0x77000000, 0xDD0F172A]` |
| `assets/images/fond_ci.jpeg` | Dashboard client CIV | Blanc 88% (`Color(0xFFF8FAFC).withValues(alpha: 0.88)`) |
| `assets/images/fond_cmr.jpeg` | Dashboard client CMR | Blanc 88% |
| `assets/images/fond_ci_T.jpeg` | Dashboard tech CIV | Dark 85% (`0xFF0F172A` alpha 0.85) + BackdropFilter blur 30 |
| `assets/images/fond_cmr_T.jpeg` | Dashboard tech CMR | Dark 85% + BackdropFilter blur 30 |

### 8.2 Pattern fond image avec overlay (écran clair)

```dart
// Dashboard client — fond image + overlay clair pour lisibilité des cartes blanches
Scaffold(
  backgroundColor: const Color(0xFF0F172A),
  body: Stack(
    children: [
      Positioned.fill(
        child: Image.asset(bgImage, fit: BoxFit.cover),
      ),
      Positioned.fill(
        child: Container(
          color: const Color(0xFFF8FAFC).withValues(alpha: 0.88),
        ),
      ),
      // Contenu principal
    ],
  ),
)
```

### 8.3 Catégories — image cards 96×116px

```dart
// categories_chips.dart — mapping nom → image asset
static String? _imageFor(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('élec') || n.contains('electr')) return 'assets/images/categories/fond_energie.jpg';
  if (n.contains('bâtiment') || n.contains('menuis')) return 'assets/images/categories/fond_batiment.jpg';
  if (n.contains('livraison') || n.contains('gaz')) return 'assets/images/categories/fond_livraison.jpg';
  if (n.contains('ménage') || n.contains('service')) return 'assets/images/categories/fond_services.jpg';
  if (n.contains('plomb') || n.contains('maison')) return 'assets/images/categories/fond_maison.jpg';
  return null; // → fallback gradient
}
```

### 8.4 Services rapides — mapping query → image

| Service | Query | Asset |
|---------|-------|-------|
| Livraison gaz | `'gaz'` | `assets/images/metiers/fond_lovraison_gaz.jpg` |
| Femme de ménage | `'ménage'` | `assets/images/metiers/fond_menagegère.jpg` |
| Électricien | `'électricité'` | `assets/images/metiers/Fond_electricité.jpg` |
| Plombier | `'plomberie'` | `null` → icône `Icons.handyman_rounded` |
| Menuisier | `'menuiserie'` | `null` → icône `Icons.handyman_rounded` |

---

## 9. ANIMATIONS AUTORISÉES

| Animation | Usage | Package |
|-----------|-------|---------|
| `AnimatedSwitcher` | Transition état loading→content | Flutter natif |
| `AnimatedOpacity` | Apparitions progressives | Flutter natif |
| `AnimatedContainer` | Resize, couleur | Flutter natif |
| `Hero` | Transitions navigation photo | Flutter natif |
| `TweenAnimationBuilder` | Custom simples | Flutter natif |

**Interdits sans justification :** Lottie, Rive, custom painters complexes, animations > 300ms non liées à une action utilisateur.

---

## 10. RESPONSIVE & MOBILE-FIRST

- **Toujours tester** en portrait 375px (iPhone SE) et 393px (iPhone 15)
- **Éviter les tailles hardcodées** de hauteur — utiliser `Flexible`, `Expanded`, `MediaQuery`
- **SafeArea** obligatoire sur tous les écrans racine
- **Keyboard padding** obligatoire sur tous les formulaires avec bottom sheet :
  ```dart
  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24)
  ```
