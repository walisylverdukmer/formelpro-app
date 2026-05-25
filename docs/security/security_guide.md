# Guide Sécurité — FormelPro

*Dernière mise à jour : 2026-05-20*

---

## 1. ÉTAT ACTUEL DE LA SÉCURITÉ

| Point | Statut | Action requise |
|-------|--------|---------------|
| RLS sur toutes les tables | ✅ Appliqué | Vérifier après chaque nouvelle table |
| Clés Supabase hardcodées | ⚠️ Présent | Migrer via `--dart-define` avant production |
| Validation inputs | ⚠️ Partielle | Renforcer dans les formulaires |
| Upload sécurisé | 🔲 À faire | Buckets Storage + validation MIME |
| Désabonnement FCM à la déconnexion | 🔲 À faire | Implémenter dans `signOut()` |

---

## 2. ROW LEVEL SECURITY (RLS)

### 2.1 Principe général

Chaque table doit respecter ce modèle :

```
Lecture    → qui peut VOIR les données ?
Écriture   → qui peut MODIFIER les données ?
Insertion  → qui peut CRÉER des données ?
Suppression → qui peut SUPPRIMER ?
```

### 2.2 Politiques appliquées — résumé

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `utilisateurs` | Public | Soi-même | Soi-même | ❌ |
| `categories_services` | Public | service_role | service_role | service_role |
| `technicien_categories` | Public | Soi (technicien_id) | ❌ | Soi |
| `conversations` | Participant | Client | Participant | ❌ |
| `messages` | Participant | Soi (expediteur_id) | ❌ | ❌ |
| `interventions` | Participant | Client | Participant | Client |
| `favoris` | Soi (client) | Soi | ❌ | Soi |
| `factures` | Participant | Tech | Participant | ❌ |
| `avis` | Public | Client (intervention terminée) | ❌ | ❌ |
| `notifications` | Soi | service_role | Soi (est_lu) | Soi |
| `transactions` | Participant | Client | service_role | ❌ |
| `signalements` | Soi (signaleur) | Tout utilisateur auth | ❌ | ❌ |

### 2.3 Vérification RLS après ajout de table

```sql
-- Toujours exécuter après créer une nouvelle table
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
-- Toutes les lignes doivent avoir rowsecurity = true

-- Tester une politique
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub": "user-uuid-ici"}';
SELECT * FROM utilisateurs;  -- Doit retourner les données attendues
RESET ROLE;
```

### 2.4 Règle SECURITY DEFINER pour les triggers

Les fonctions `SECURITY DEFINER` s'exécutent avec les droits du propriétaire (superuser), contournant légitimement RLS pour les triggers internes.

```sql
-- ✅ Correct pour les triggers automatiques
CREATE FUNCTION calculer_reputation_technicien()
RETURNS TRIGGER AS $$ ... $$
LANGUAGE plpgsql SECURITY DEFINER;  -- Nécessaire pour UPDATE utilisateurs depuis trigger

-- ❌ Ne jamais utiliser SECURITY DEFINER sur des fonctions exposées via RPC public
```

---

## 3. GESTION DES SECRETS

### 3.1 Situation actuelle (⚠️ à corriger avant production)

Les clés Supabase sont hardcodées dans `lib/main.dart` :
```dart
url: 'https://elsweibfytmvaeasekaf.supabase.co',    // ⚠️
anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' // ⚠️
```

### 3.2 Solution recommandée — `--dart-define`

**Étape 1 — Modifier main.dart :**
```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  ),
);
```

**Étape 2 — Lancer l'app :**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=FIREBASE_API_KEY=xxx
```

**Étape 3 — CI/CD :**
```yaml
# .github/workflows/build.yml
- name: Build APK
  run: flutter build apk --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} ...
```

**Étape 4 — `.gitignore` :**
```
.env
.env.local
dart_defines.json
```

### 3.3 Secrets Supabase Edge Functions

```bash
# Configurer les secrets Supabase (JAMAIS dans le code)
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'

# Lister les secrets
supabase secrets list
```

### 3.4 Clé service_role dans le trigger notifications

Le trigger `send-push-on-insert` contient la `service_role_key` directement dans Supabase (pas dans le code Flutter). C'est **acceptable côté DB** mais :
- Ne JAMAIS exporter ou committer cette clé
- La rotation de cette clé nécessite de mettre à jour le trigger
- Envisager à terme de passer par un appel authentifié via le JWT de l'utilisateur

---

## 4. SÉCURITÉ AUTHENTIFICATION

### 4.1 Vérifications à l'initialisation

```dart
// ✅ Toujours vérifier currentUser avant les opérations sensibles
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageConnexionPrincipale()));
  return;
}
```

### 4.2 Session expirée

```dart
// Supabase Flutter SDK renouvelle automatiquement les tokens
// Le stream onAuthStateChange détecte la déconnexion et redirige via AuthGate
// Pas de gestion manuelle requise
```

### 4.3 Mot de passe

- Minimum configuré à **6 caractères** dans `supabase/config.toml`
- **Recommandation production :** Passer à 8 caractères minimum
- Le reset password n'est pas encore implémenté (Phase 3.6)

---

## 5. VALIDATION DES ENTRÉES

### 5.1 Règles de validation Flutter

```dart
// Fonction de validation réutilisable
String? validateDescription(String? value) {
  if (value == null || value.trim().isEmpty) return "Ce champ est obligatoire";
  if (value.trim().length < 10) return "Minimum 10 caractères";
  if (value.length > 500) return "Maximum 500 caractères";
  return null;
}

String? validateMontant(String? value) {
  if (value == null || value.trim().isEmpty) return "Montant obligatoire";
  final montant = int.tryParse(value.trim());
  if (montant == null) return "Montant invalide";
  if (montant <= 0) return "Montant doit être positif";
  if (montant > 50000000) return "Montant trop élevé";
  return null;
}

String? validateTelephone(String? value) {
  if (value == null || value.trim().isEmpty) return null; // Optionnel
  final clean = value.replaceAll(RegExp(r'\s+'), '');
  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(clean)) return "Numéro invalide";
  return null;
}
```

### 5.2 Nettoyage avant insert Supabase

```dart
// Toujours trimmer les chaînes
'description': description.trim(),
'ville': ville.trim(),

// Normaliser les nombres
'montant_final': int.parse(montantController.text.trim()),

// Ne jamais passer des champs null non intentionnels
if (quartier.isNotEmpty) map['quartier'] = quartier;
```

### 5.3 Protection contre les doublons

```dart
// Vérifier avant insert d'un avis (pas de UNIQUE en DB)
final existing = await supabase
    .from('avis')
    .select('id')
    .eq('intervention_id', interventionId)
    .eq('client_id', clientId)
    .maybeSingle();

if (existing != null) {
  // Afficher "Vous avez déjà noté cette intervention"
  return;
}
```

---

## 6. SÉCURITÉ SUPABASE STORAGE

### 6.1 Buckets à créer

| Bucket | Accès | Usage |
|--------|-------|-------|
| `photos-profil` | Public (lecture) | Photos profil utilisateurs |
| `documents-identite` | Privé | CNI, diplômes techniciens |
| `factures-pdf` | Privé | PDFs factures |

### 6.2 Politique de naming des fichiers

```dart
// ✅ Toujours inclure l'userId dans le chemin (isolation par utilisateur)
final path = 'photos-profil/$userId/avatar_${timestamp}.jpg';
final path = 'documents-identite/$userId/cni_${timestamp}.jpg';
```

### 6.3 Validation avant upload

```dart
Future<void> uploadPhoto(File file) async {
  // 1. Vérifier la taille (max 5MB)
  final sizeBytes = await file.length();
  if (sizeBytes > 5 * 1024 * 1024) {
    throw Exception("Image trop lourde (max 5MB)");
  }

  // 2. Vérifier l'extension
  final extension = file.path.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
    throw Exception("Format non supporté");
  }

  // 3. Upload
  final path = 'photos-profil/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
  await Supabase.instance.client.storage.from('photos-profil').upload(path, file);

  // 4. Récupérer l'URL publique
  final url = Supabase.instance.client.storage.from('photos-profil').getPublicUrl(path);
  await supabase.from('utilisateurs').update({'photo_profil_url': url}).eq('id', userId);
}
```

---

## 7. PROTECTION ANTI-SPAM / ABUS

### 7.1 Rate limiting naturel

Supabase applique un rate limiting sur les Auth endpoints par défaut.  
Pour les autres tables, utiliser RLS + validation côté Flutter.

### 7.2 Signalements excessifs

```dart
// Vérifier si l'utilisateur a déjà signalé cette personne
final existing = await supabase
    .from('signalements')
    .select('id')
    .eq('signale_par', currentUserId)
    .eq('utilisateur_signale', techId)
    .maybeSingle();

if (existing != null) {
  _showSnackBar("Vous avez déjà signalé ce prestataire");
  return;
}
```

---

## 8. CHECKLIST SÉCURITÉ PRÉ-PRODUCTION

```
BACKEND (Supabase)
□ RLS activé sur TOUTES les tables (vérifier avec la requête pg_tables)
□ Aucune table sans politique RLS
□ Rotation de la service_role_key si exposée accidentellement
□ Confirmation email activée (config.toml : enable_confirmations = true)
□ Mot de passe minimum 8 caractères (config.toml)
□ Buckets Storage créés avec les bonnes politiques d'accès
□ Secrets Edge Functions configurés (FIREBASE_SERVICE_ACCOUNT)

FLUTTER (Mobile)
□ Clés Supabase externalisées via --dart-define
□ Clés Firebase externalisées ou dans google-services.json (non commité si sensible)
□ Validation de tous les champs de formulaire
□ Vérification taille/type fichiers avant upload
□ Pas de données sensibles dans les logs (debugPrint)
□ Désabonnement FCM implémenté dans signOut()
□ Protection anti-doublon sur les avis et signalements

GÉNÉRAL
□ HTTPS uniquement (Supabase force HTTPS par défaut)
□ .gitignore contient : .env, dart_defines.json, google-services.json (si sensible)
□ Pas de debugPrint avec données personnelles en production
□ Code obfusqué pour l'APK release : flutter build apk --obfuscate --split-debug-info=symbols/
```
