# CLAUDE.md — Guide Central FormelPro

> **Ce fichier est la référence absolue pour tout agent IA ou développeur humain intervenant sur ce projet.**  
> Lire entièrement avant toute modification de code. Respecter chaque règle sans exception.

---

## 0. LIENS DOCUMENTATION COMPLÈTE

| Document | Rôle |
|----------|------|
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | État du projet, plan de route, backlog |
| [docs/architecture/overview.md](docs/architecture/overview.md) | Architecture système complète |
| [docs/supabase/schema_guide.md](docs/supabase/schema_guide.md) | Toutes les tables + colonnes + RLS |
| [docs/supabase/migrations.sql](docs/supabase/migrations.sql) | Schéma SQL exécutable |
| [docs/supabase/rls_policies.sql](docs/supabase/rls_policies.sql) | Politiques RLS (✅ appliquées) |
| [docs/design_system/design_system.md](docs/design_system/design_system.md) | Design system complet |
| [docs/realtime/realtime_guide.md](docs/realtime/realtime_guide.md) | Realtime, FCM, streams |
| [docs/security/security_guide.md](docs/security/security_guide.md) | Sécurité, secrets, validation |
| [docs/roadmap/execution_roadmap.md](docs/roadmap/execution_roadmap.md) | Roadmap IA d'exécution |
| [docs/architecture/code_health.md](docs/architecture/code_health.md) | Dette technique, refactoring |
| [docs/progress/](docs/progress/) | Suivi par module |

---

## 1. VISION PRODUIT

**FormelPro** — Application mobile Flutter (iOS/Android) de mise en relation **géolocalisée et sécurisée** entre clients et techniciens certifiés.

- **Marchés :** Côte d'Ivoire (`CIV`) + Cameroun (`CMR`)
- **Backend :** Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)
- **Notifications :** Firebase Cloud Messaging (FCM)
- **Identité visuelle :** "Soft Premium" — fonds image pays, coins arrondis, ombres légères
- **Thème pays :** Orange `#E67E22` (CIV) / Rouge `#CE1126` (CMR)
- **Devises :** FCFA (toujours suffixer les montants)
- **Web :** Portail recrutement HTML standalone déployé sur Vercel (`/devenir-prestataire`) — hors Flutter

---

## 2. COMMANDES UTILES

> **Prérequis :** copier `dart_defines.json.example` → `dart_defines.json` et y renseigner les vraies clés (fichier gitignore).

```bash
flutter run --dart-define-from-file=dart_defines.json                                                           # Lancer l'app
flutter build apk --split-per-abi --dart-define-from-file=dart_defines.json                                    # APK debug
flutter build apk --release --obfuscate --split-debug-info=symbols/ --dart-define-from-file=dart_defines.json  # APK release
flutter build web --dart-define-from-file=dart_defines.json                                                    # Build web (Vercel)
flutter clean && flutter pub get                                                                                 # Nettoyer + réinstaller
flutter analyze                                                                                                  # Analyse statique (doit retourner 0 issues)
flutter pub get                                                                                                  # Après modification pubspec.yaml
```

---

## 3. CONVENTIONS FLUTTER

### 3.1 Usage de `const`

```dart
// ✅ TOUJOURS utiliser const pour les widgets sans état dynamique
const SizedBox(height: 16)
const Icon(Icons.star)
const Text("Libellé fixe")

// ✅ Constructeur const sur tout widget qui le permet
class MonWidget extends StatelessWidget {
  const MonWidget({super.key});
```

### 3.2 Taille des fichiers et responsabilité unique

- **Maximum 350 lignes** par fichier Dart — au-delà, extraire en sous-composants
- Un écran = un seul rôle métier. Les widgets complexes vont dans `widgets/`
- Les appels Supabase vont dans des méthodes dédiées, **jamais inline dans `build()`**

### 3.3 Structure d'un écran type

```dart
class MonEcran extends StatefulWidget { ... }

class _MonEcranState extends State<MonEcran> {
  // 1. Variables d'état
  bool _loading = false;

  // 2. Méthodes async Supabase (préfixe _)
  Future<void> _chargerDonnees() async { ... }

  // 3. build() clair, délègue aux helpers
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? _buildLoader() : _buildContent(),
    );
  }

  // 4. Helpers UI (préfixe _build)
  Widget _buildLoader() => const Center(child: CircularProgressIndicator(...));
  Widget _buildContent() => ...;
}
```

### 3.4 Gestion obligatoire des états Loading / Error / Empty

Tout écran avec données Supabase doit gérer les 4 états :

```dart
// Pattern StreamBuilder standard
StreamBuilder<List<Map<String, dynamic>>>(
  stream: monStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildShimmer();          // Jamais CircularProgressIndicator seul
    }
    if (snapshot.hasError) {
      return _buildError(snapshot.error.toString());
    }
    final items = snapshot.data ?? [];
    if (items.isEmpty) {
      return _buildEmptyState();       // Toujours un message vide explicite
    }
    return _buildList(items);
  },
)
```

### 3.5 Navigation

```dart
// Push standard
Navigator.push(context, MaterialPageRoute(builder: (_) => MonEcran()));

// Remplacement (AuthGate, redirections)
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MonEcran()));

// Pop avec résultat
Navigator.pop(context, resultat);

// INTERDIT : jamais Navigator.pushAndRemoveUntil sauf après déconnexion
```

### 3.6 Gestion des Streams Supabase

```dart
// ✅ Pattern standard realtime
StreamBuilder(
  stream: Supabase.instance.client
      .from('ma_table')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .order('created_at', ascending: false),
  builder: (context, snapshot) { ... },
)

// ✅ Toujours dispose les controllers
@override
void dispose() {
  _scrollController.dispose();
  _textController.dispose();
  super.dispose();
}
```

### 3.7 Null Safety stricte

```dart
// ✅ Toujours fournir une valeur par défaut
final String nom = data['nom_complet'] ?? 'Prestataire';
final double note = (data['score_global'] ?? 5.0).toDouble();
final int total = (data['total_transactions'] ?? 0) as int;

// ✅ Vérification avant navigation
if (context.mounted) {
  Navigator.pop(context);
}

// ❌ INTERDIT
data['nom']!              // Force-unwrap sans certitude
(data['note'] as double)  // Cast direct sans vérification
```

### 3.8 Gestion des erreurs

```dart
try {
  await Supabase.instance.client.from('table').insert({...});
  if (mounted) _showSuccess();
} on PostgrestException catch (e) {
  if (mounted) _showError(e.message);
} catch (e) {
  if (mounted) _showError("Erreur inattendue");
  debugPrint("Erreur: $e");
}
```

---

## 4. CONVENTIONS SUPABASE

### 4.1 Jamais de `select('*')`

```dart
// ❌ INTERDIT
.from('utilisateurs').select()
.from('utilisateurs').select('*')

// ✅ TOUJOURS sélectionner les colonnes nécessaires
.from('utilisateurs').select('id, nom_complet, metier_personnalise, score_global, photo_profil_url')
```

### 4.2 Toujours filtrer par pays

```dart
// Toute liste de techniciens DOIT être filtrée par pays
.from('utilisateurs')
.select('id, nom_complet, score_global, ville')
.eq('pays', userData['pays'])          // 'CIV' ou 'CMR' — jamais 'CI' ou 'CM'
.eq('role', 'technicien')
.eq('disponible', true)
.order('score_global', ascending: false)
.limit(50)
```

### 4.3 Limites systématiques

```dart
// Toujours limiter les requêtes de liste
.limit(50)   // Maximum sur les listes d'utilisateurs
.limit(100)  // Maximum sur les messages chat
.limit(20)   // Maximum sur les notifications

// Pagination si nécessaire
.range(offset, offset + 19)
```

### 4.4 Noms de colonnes — référence rapide

| Table | Colonnes à connaître |
|-------|---------------------|
| `utilisateurs` | `pays` = `'CIV'`/`'CMR'` · `role` = `'client'`/`'technicien'` · `photo_profil_url` · `metier_personnalise` · `telephone` |
| `interventions` | `titre_service` · `montant_final` (INTEGER FCFA) · `tech_id` NOT NULL · `date_prevue` NOT NULL |
| `messages` | `cree_le` (pas `created_at`) · `expediteur_id` |
| `avis` | `date_avis` (pas `created_at`) |

> Schéma complet : [docs/supabase/schema_guide.md](docs/supabase/schema_guide.md)

### 4.5 Patterns Realtime

```dart
// ✅ Stream standard avec filtre
.stream(primaryKey: ['id']).eq('user_id', uid)

// ✅ Toujours unsubscribe dans dispose()
late final StreamSubscription _sub;
_sub = stream.listen(...);
@override void dispose() { _sub.cancel(); super.dispose(); }
```

### 4.6 Upsert et conflits

```dart
// Conversation unique (client_id, tech_id)
await supabase.from('conversations').upsert(
  {'client_id': clientId, 'tech_id': techId, 'dernier_message': ''},
  onConflict: 'client_id,tech_id',
).select().single();
```

---

## 5. UI / UX — RÈGLES DESIGN SYSTEM

> Guide complet : [docs/design_system/design_system.md](docs/design_system/design_system.md)

### 5.1 Couleurs

```dart
// Thème par pays — TOUJOURS depuis userData['pays']
Color get accentColor => userData['pays'] == 'CIV'
    ? const Color(0xFFE67E22)   // Orange CIV
    : const Color(0xFFCE1126);  // Rouge CMR

// Palette fixe
const Color kDark      = Color(0xFF0F172A);   // Fond dark
const Color kNavy      = Color(0xFF1E293B);   // Dark secondaire
const Color kLight     = Color(0xFFF8FAFC);   // Fond light
const Color kWhite70   = Colors.white70;       // Textes secondaires
const Color kWhite38   = Colors.white38;       // Labels discrets
```

### 5.2 BorderRadius standards

```dart
BorderRadius.circular(14)   // Chips, badges, inputs
BorderRadius.circular(20)   // Cards standards
BorderRadius.circular(22)   // Cards premium
BorderRadius.circular(28)   // Bottom sheets
BorderRadius.circular(35)   // Panneaux DraggableScrollableSheet
```

### 5.3 Ombres

```dart
// Ombre card légère (fond clair)
BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))

// Ombre bouton accent
BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))

// Ombre dark/premium
BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 20, offset: Offset(0, 8))
```

### 5.4 Spacing system

```dart
// Espacements standards — utiliser uniquement ces valeurs
4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48

// Padding horizontal standard
EdgeInsets.symmetric(horizontal: 24)   // Pages
EdgeInsets.symmetric(horizontal: 20)   // Cards
EdgeInsets.symmetric(horizontal: 16)   // Bottom sheets
```

### 5.5 Typography (Google Fonts)

```dart
// Titres
GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)
GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)

// Corps
GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6)
GoogleFonts.inter(fontSize: 13, color: Colors.white54)
GoogleFonts.inter(fontSize: 12, color: Colors.white38)

// Labels catégories / tags
GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)
```

### 5.6 SnackBar standard

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message, style: GoogleFonts.inter()),
    backgroundColor: const Color(0xFF1E293B),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    duration: const Duration(seconds: 3),
  ),
);
```

### 5.7 Bottom Sheets

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
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    ),
    child: ...,
  ),
);
```

### 5.8 Animations autorisées

```dart
AnimatedSwitcher       // Transitions d'état
AnimatedOpacity        // Apparitions / disparitions
Hero                   // Transitions de navigation
TweenAnimationBuilder  // Animations custom simples

// INTERDIT sauf cas justifié : Lottie, Rive, custom painters complexes
```

---

## 6. SÉCURITÉ

> Guide complet : [docs/security/security_guide.md](docs/security/security_guide.md)

### 6.1 Aucun secret hardcodé

```dart
// ❌ INTERDIT en production
const supabaseUrl = 'https://xxx.supabase.co';
const anonKey = 'eyJ...';

// ✅ Utiliser --dart-define
// flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_KEY=yyy
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const anonKey = String.fromEnvironment('SUPABASE_KEY');
```

> Note : Les clés sont actuellement hardcodées dans `main.dart`. À migrer avant production.

### 6.2 Validation des entrées utilisateur

```dart
// Valider AVANT tout insert Supabase
if (description.trim().isEmpty) return;
if (description.length > 500) return;
if (montant <= 0 || montant > 10000000) return;

// Nettoyer les données
final cleaned = input.trim().replaceAll(RegExp(r'\s+'), ' ');
```

### 6.3 Upload sécurisé (Supabase Storage)

```dart
// Chemin avec userId pour isoler les fichiers
final path = 'profils/$userId/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

// Vérifier la taille avant upload
if (file.lengthSync() > 5 * 1024 * 1024) {
  // Refuser > 5MB
}

// Vérifier le type MIME
final allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
```

### 6.4 RLS — principe de base

- **Toutes les tables ont RLS activé** (✅ fait)
- Jamais de `service_role_key` dans le code Flutter
- Les triggers Supabase utilisent `SECURITY DEFINER` pour contourner RLS légitimement

---

## 7. PERFORMANCE

### 7.1 Éviter les rebuilds inutiles

```dart
// ✅ Extraire en sous-widgets const
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  // ...
}

// ❌ Éviter les lambdas inline dans build()
// children: [
//   GestureDetector(onTap: () { setState(() { ... }); }, ...)
// ]
// → extraire en méthode _buildItem() ou sous-widget
```

### 7.2 Images réseau

```dart
// Toujours fournir placeholder et errorWidget
Image.network(
  url,
  fit: BoxFit.cover,
  loadingBuilder: (_, child, progress) =>
      progress == null ? child : const ShimmerBox(),
  errorBuilder: (_, __, ___) =>
      const Icon(Icons.person, color: Colors.white24, size: 60),
)
```

### 7.3 Listes longues

```dart
// ✅ ListView.builder pour toutes les listes > 5 éléments
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, i) => _buildItem(items[i]),
)

// ❌ Ne jamais mapper une liste en Column pour des données Supabase
Column(children: items.map((i) => _buildItem(i)).toList())
```

### 7.4 Streams — règles

- Un seul StreamBuilder par source de données par écran
- Combiner plusieurs sources avec `StreamZip` si nécessaire
- Toujours `cancel()` les subscriptions dans `dispose()`

---

## 8. ARCHITECTURE CIBLE

> Détail complet : [docs/architecture/overview.md](docs/architecture/overview.md)

L'app suit actuellement une architecture **Flutter + Supabase directe** (appels Supabase dans les widgets). La cible est une migration progressive vers **Riverpod + Repository pattern** :

```
Actuel :  Widget → Supabase.instance.client.from(...)
Cible :   Widget → Provider (Riverpod) → Repository → Supabase
```

Préparer cette migration en :
1. Regroupant les appels Supabase en méthodes dans des classes `*Service`
2. Évitant `Supabase.instance.client` directement dans les `build()`
3. Nommant les services : `InterventionService`, `ChatService`, `UserService`

### Fichiers clés à connaître

| Fichier | Rôle |
|---------|------|
| `lib/services/notification_router.dart` | `navigatorKey` global + `routeFromNotification()` — navigation FCM hors widget tree |
| `lib/screens/dashboard/verification_documents_page.dart` | Upload docs identité tech + statut par document — SQL §13 exécuté |
| `lib/screens/admin/admin_documents_page.dart` | Validation/rejet docs par admin — SQL §14 exécuté, accès via `is_admin=true` |
| `lib/widgets/stats_dashboard_tech.dart` | Revenus FCFA + graphique mensuel (6 mois) — chargé dans `accueil_technicien.dart` |
| `lib/widgets/filtres_techniciens.dart` | Model `FiltresTechniciens` (disponibleSeulement, noteMin, categorieId, categorieNom, **commune, quartier, typePrestation**) + bottom sheet filtres avancés |
| `lib/widgets/categories_chips.dart` | Cartes image **96×116px DB-driven** — reçoit `categories: List<Map>` + `activeCatId` + `onSelect(id, nom)` — image mapper par nom — filtre via `categorieId` réel (pas de ilike) |
| `lib/widgets/services_rapides_widget.dart` | 5 boutons 1-clic avec images métiers — typedef `OnServiceTap(categorieNom, {typePrestation?, disponibleSeulement})` — bottom sheets contextuels Gaz + Ménagère |
| `lib/widgets/experts_pres_widget.dart` | Liste horizontale experts disponibles (est_en_ligne OU disponible) — cartes 148px, badge statut, filtre par commune — "Voir plus" → `TechnicianSelectionPage` |
| `lib/widgets/location_picker_widget.dart` | Carte flutter_map + GPS + Nominatim reverse geocode + sélection manuelle ville/commune/quartier — retourne `{ville, commune, quartier, region, repere}` |
| `lib/widgets/carte_technicien.dart` | Card technicien — avatar 76×76px `borderRadius(14)` + `_DisponibiliteBadge` + favori cœur |
| `web/devenir-prestataire.html` | Portail recrutement HTML standalone — Supabase JS CDN — zéro Flutter — mobile-first |
| `vercel.json` | `outputDirectory: build/web` + SPA catch-all `→ /index.html` — cleanUrls pour `.html` statiques |
| `docs/supabase/migrations.sql` | Toutes les migrations SQL — triggers idempotents (`DROP TRIGGER IF EXISTS`) — **remplacer `<SERVICE_ROLE_KEY>` ligne ~307** |
