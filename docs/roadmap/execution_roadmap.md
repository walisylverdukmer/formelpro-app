# Roadmap d'Exécution IA — FormelPro

*Dernière mise à jour : 2026-05-25*  
*Format optimisé pour agents IA et développeurs humains*

---

## COMMENT LIRE CE DOCUMENT

Chaque phase est **auto-suffisante** : un agent IA peut reprendre n'importe quelle tâche en lisant uniquement ce fichier + les fichiers référencés.

**Colonnes :**
- **Tâche** — Ce qu'il faut faire exactement
- **Fichiers** — Fichiers à créer ou modifier
- **Backend** — Tables/fonctions Supabase concernées
- **Dépendances** — Ce qui doit être fait avant
- **Risques** — Points d'attention
- **Priorité** — 🔴 Bloquant / 🟡 Important / 🟢 Nice-to-have

---

## PHASE 0 — SÉCURITÉ & STABILITÉ

**Objectif :** Rendre l'app deployable en production sans risque.

| # | Tâche | Fichiers | Backend | Dépendances | Risques | Priorité | Statut |
|---|-------|----------|---------|-------------|---------|----------|--------|
| 0.1 | Appliquer RLS | `rls_policies.sql` | Toutes tables | — | Casser requêtes si politiques trop restrictives | 🔴 | ✅ Fait |
| 0.2 | Vérifier colonnes `utilisateurs` manquantes (`quartier`, `disponible`) | Supabase SQL Editor | `utilisateurs` | 0.1 | Crashes Flutter si colonnes absentes | 🔴 | 🔲 À vérifier en DB |
| 0.3 | Filtres pays `'CIV'`/`'CMR'` — vérifiés corrects dans tout le code | — | — | — | — | 🔴 | ✅ Vérifié |
| 0.3b | `metier_principal` → `metier_personnalise` dans `complete_profil_page.dart` | `complete_profil_page.dart` | — | — | Techs affichaient "Prestataire" | 🔴 | ✅ Fait |
| 0.3c | Filtre catégorie brisé (IDs numériques) → requête via `technicien_categories` | `accueil_client.dart` | `technicien_categories` | — | Filtre retournait toujours vide | 🔴 | ✅ Fait |
| 0.4 | Ajouter `url_launcher` au pubspec | `pubspec.yaml` | — | — | Crash runtime au tap itinéraire | 🔴 | ✅ Fait |
| 0.5 | Externaliser clés Supabase + Firebase | `main.dart`, `dart_defines.json` | — | — | Exposition credentials en prod | 🔴 | ✅ Fait |
| 0.6 | Unifier `photo_url` → `photo_profil_url` + `.select()` sans colonnes corrigé | `user_model.dart`, `accueil_client.dart`, `main_dashboard.dart` | — | — | Images brisées | 🟡 | ✅ Fait |
| 0.7 | Firebase `kIsWeb` guard — initApp conditionnel (page blanche Chrome) | `main.dart`, `web/firebase-messaging-sw.js` | — | — | App blanche sur Flutter Web | 🔴 | ✅ Fait |

**Prérequis production :** Tous les points 0.x complétés.

---

## PHASE 1 — QUICK WINS (backend prêt)

**Objectif :** Connecter le Flutter aux tables déjà existantes. Zéro SQL à écrire.

### 1.1 Modal de notation post-intervention

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Afficher un bouton/modal "Laisser un avis" quand `statut = 'termine'` |
| **Fichiers** | `lib/screens/interventions/mes_interventions_page.dart` + `avis_modal.dart` |
| **Backend** | Table `avis` (existante) + trigger `calculer_reputation_technicien` (existant) |
| **Dépendances** | — |
| **Risques** | Pas de UNIQUE en DB → protection anti-doublon côté UI ✅ |
| **Priorité** | 🔴 |
| **Statut** | ✅ **IMPLÉMENTÉ** |

---

### 1.2 Système de favoris

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Bouton cœur sur carte technicien + liste favoris dans profil |
| **Fichiers** | `widgets/carte_technicien.dart`, `profil_tab.dart` |
| **Backend** | Table `favoris` (existante) |
| **Dépendances** | — |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** |

**Instructions d'implémentation :**
```
1. widgets/carte_technicien.dart : ajouter IconButton cœur en haut à droite
   - FutureBuilder qui vérifie si favori via .from('favoris').select('client_id').eq(...)
   - onTap : toggle (insert si absent, delete si présent)
2. profil_tab.dart : ajouter section "Mes favoris" (client uniquement)
   - StreamBuilder .from('favoris').stream(['client_id']).eq('client_id', uid)
   - Afficher carte technicien pour chaque favori (jointure via FutureBuilder)
```

---

### 1.3 Affichage facture

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Bouton "Voir la facture PDF" quand url_pdf disponible |
| **Fichiers** | `screens/interventions/intervention_detail_page.dart` |
| **Backend** | Table `factures` (existante) |
| **Dépendances** | `url_launcher` (Phase 0.4 ✅) |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** (+ fix colonnes utilisateurs : avatar_url→photo_profil_url, nom→nom_complet, note→score_global, etc.) |

**Instructions :**
```
1. Dans intervention_detail_page.dart : charger la facture liée
   → .from('factures').select('url_pdf, est_payee, montant').eq('intervention_id', id).maybeSingle()
2. Si url_pdf != null → afficher bouton "Ouvrir la facture"
   → launchUrl(Uri.parse(facture['url_pdf']))
3. Badge "Payée" / "En attente" selon est_payee
```

---

### 1.4 Upload photo de profil

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Permettre à l'utilisateur de changer sa photo de profil |
| **Fichiers** | `screens/dashboard/profil_tab.dart` |
| **Backend** | Supabase Storage bucket `photos-profil`, colonne `photo_profil_url` |
| **Dépendances** | Ajouter `image_picker: ^1.0.7` au pubspec |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** |

**Instructions :**
```
1. Ajouter image_picker au pubspec.yaml
2. Dans profil_tab.dart : tap sur avatar → ImagePicker().pickImage(source: ImageSource.gallery)
3. Valider taille (max 5MB) et format
4. Upload: storage.from('photos-profil').upload('$userId/avatar_$timestamp.jpg', file)
5. Récupérer URL publique → UPDATE utilisateurs SET photo_profil_url = url
6. Permissions Android: AndroidManifest READ_EXTERNAL_STORAGE
   Permissions iOS: NSPhotoLibraryUsageDescription dans Info.plist
```

---

### 1.5 Badge vérification identité technicien

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Upload CNI + badge "Identité vérifiée" si `is_identite_verifiee = true` |
| **Fichiers** | `screens/complete_profil_page.dart`, `screens/dashboard/profil_tab.dart` |
| **Backend** | Colonnes `type_document`, `document_identite_url`, `is_identite_verifiee` dans `utilisateurs` |
| **Dépendances** | 1.4 (pattern upload), Storage bucket `documents-identite` |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** |

---

## PHASE 2 — NOUVELLES FONCTIONNALITÉS CORE

### 2.1 Créer table `transactions`

```sql
-- Exécuter dans Supabase SQL Editor
-- Voir docs/supabase/migrations.sql § 11
```

### 2.2 Créer table `signalements`

```sql
-- ✅ Déjà créé en DB + RLS appliqué
-- Bouton Signaler ✅ Implémenté dans details_technicien.dart
```

### 2.3 Paiement Mobile Money

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Permettre au client de payer via Orange Money ou MTN MoMo |
| **Fichiers** | Nouveau `screens/payment/payment_page.dart`, Edge Function `process-payment` |
| **Backend** | Table `transactions` (Phase 2.1) + `factures` |
| **Dépendances** | 2.1, API marchande Orange Money ou MTN MoMo (partenariat requis) |
| **Risques** | Délai administratif opérateurs (3-8 semaines), sandbox vs prod |
| **Priorité** | 🔴 |

---

### 2.4 Notifications push — routing sur tap

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Naviguer vers le bon écran au tap d'une notification push |
| **Fichiers** | `lib/services/notification_router.dart` (nouveau), `main.dart` (StatefulWidget), `main_dashboard.dart` |
| **Backend** | Payload FCM doit contenir `data.type` + `data.conversation_id` ou `data.intervention_id` |
| **Dépendances** | FCM déjà configuré ✅ |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** — background tap + terminated state (`pendingNotificationData`), routing vers `ChatScreen` / `MissionDetailPage` / `InterventionDetailPage` |

---

### 2.6 Vérification identité technicien — page dédiée

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Page complète upload CNI/passeport/certificat avec statut par document |
| **Fichiers** | `screens/dashboard/verification_documents_page.dart` (nouveau) |
| **Backend** | Table `documents_verification` (migrations.sql §13) + bucket `documents-techniciens` |
| **Dépendances** | SQL §13 ✅ exécuté — bucket Storage `documents-techniciens` à créer |
| **Priorité** | 🔴 |
| **Statut** | ✅ **COMPLET** — SQL §13 exécuté 2026-05-20, bucket Storage restant |

---

### 2.7 Espace admin — validation documents

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Interface admin pour valider/rejeter les documents soumis par les techniciens |
| **Fichiers** | `screens/admin/admin_documents_page.dart` (nouveau), `profil_tab.dart` (section admin conditionnelle) |
| **Backend** | `is_admin` colonne + `is_admin()` fonction + trigger `sync_identite_verifiee` (migrations.sql §14) |
| **Dépendances** | SQL §13 + §14 ✅ exécutés. Activer un admin : `UPDATE utilisateurs SET is_admin=true WHERE id='<uuid>'` |
| **Priorité** | 🔴 |
| **Statut** | ✅ **COMPLET** — SQL §14 exécuté 2026-05-20, activer admin via UPDATE |

---

### 2.5 Reset mot de passe

| Attribut | Valeur |
|----------|--------|
| **Tâche** | Formulaire "Mot de passe oublié" avec email de reset |
| **Fichiers** | Nouveau `screens/auth/reset_password_page.dart`, lien depuis `page_connexion_principale.dart` |
| **Backend** | `supabase.auth.resetPasswordForEmail(email)` |
| **Dépendances** | Activer confirmation email en production (config.toml) |
| **Priorité** | 🟡 |
| **Statut** | ✅ **IMPLÉMENTÉ** (page dark + état succès + lien "Mot de passe oublié ?" dans login) |

---

## PHASE 3 — UX & CROISSANCE

| # | Tâche | Complexité | Priorité | Statut |
|---|-------|-----------|----------|--------|
| 3.1 | Filtres avancés dans AccueilClient (catégorie, disponibilité, note min, recherche texte) | Moyenne | 🟡 | ✅ **COMPLET** — chips DB-driven (categorieId réel), icon mapper par nom, `_loadTopCategories()` dans `accueil_client.dart` |
| 3.1b | Restrictions missions non vérifiés — limite 3 actives, dialog CTA vérification | Faible | 🟡 | ✅ **COMPLET** — `mission_detail_page.dart` : statut `'accepte'`, `isAlreadyTaken` fix, `_showVerifRequiseDialog()` |
| 3.1c | `withOpacity` → `.withValues(alpha:)` — migration globale (~130 remplacements, 20 fichiers) | Faible | 🟢 | ✅ **COMPLET** — script PowerShell session 6 |
| 3.2 | Dashboard stats technicien (revenus, graphiques) | Haute | 🟡 | ✅ **IMPLÉMENTÉ** — `stats_dashboard_tech.dart` chargé dans `accueil_technicien.dart` |
| 3.3 | Profil premium (badge, mise en avant, abonnement) | Haute | 🟡 | 🔲 |
| 3.4 | Espace admin (validation docs, signalements) | Haute | 🟡 | ✅ **IMPLÉMENTÉ** — voir Phase 2.7 |
| 3.5 | Écran splash + onboarding 1ère ouverture | Faible | 🟢 | 🔲 |
| 3.6 | Migration vers Riverpod + Repository pattern | Très haute | 🟢 | 🔲 |
| 3.7 | Tests automatisés (widget + integration) | Haute | 🟢 | 🔲 |
| 3.8 | Mode hors-ligne (cache local) | Haute | 🟢 | 🔲 |

---

## PRÉREQUIS PRODUCTION

```
□ Phase 0 entièrement complétée
□ RLS vérifié sur toutes les tables (y compris transactions, signalements)
□ Clés externalisées (--dart-define + CI/CD secrets)
□ Confirmation email activée (config.toml)
□ Mot de passe minimum 8 caractères
□ APK obfusqué (flutter build apk --obfuscate --split-debug-info=symbols/)
□ Buckets Storage créés avec RLS
□ FIREBASE_SERVICE_ACCOUNT configuré dans Supabase secrets
□ google-services.json et GoogleService-Info.plist en place
□ Désabonnement FCM implémenté dans signOut()
□ Tests manuels sur iPhone SE (375px) + Android mid-range
□ Vérification manuelle flux CIV et CMR séparément
```

---

## QUICK WINS — Ordre recommandé pour session courte

Si une session de travail est courte (< 2h), prendre dans cet ordre :

1. **0.2** — Vérifier colonnes `utilisateurs` (15 min — SQL uniquement)
2. **0.3** — Corriger filtres pays `'CIV'`/`'CMR'` (20 min — grep + replace)
3. **1.1** — Modal notation (1h — Flutter pur, backend prêt)
4. **1.3** — Affichage facture (30 min — simple FutureBuilder)

---

## DETTE TECHNIQUE CRITIQUE

| Problème | Impact | Effort | Recommandation |
|----------|--------|--------|----------------|
| Clés hardcodées dans `main.dart` | Fuite credentials en production | 30 min | Faire avant déploiement |
| Doublon `accueil_technicien.dart` / `tech_dashboard.dart` | Maintenabilité | 1h | Fusion lors prochain sprint |
| Fichiers mal placés dans `services/` | Confusion architecture | 30 min | Déplacer en `screens/` |
| `photo_url` vs `photo_profil_url` | Bugs images | 1h | Audit + unification |
| Pas de tests | Regressions invisibles | — | Ajouter en Phase 3 |
