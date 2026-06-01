# PROJECT_CONTEXT.md — FormelPro

> **NOUVELLE SESSION ? Lis d'abord [CLAUDE.md](../CLAUDE.md)** pour les conventions de code, puis reviens ici pour l'état du projet.

> Ce fichier est le **point d'entrée de toute nouvelle session de travail**.  
> Il décrit l'état exact du projet, ce qui est fait, ce qui est en cours, et ce qui reste à faire.  
> Mis à jour au fil des sessions.

---

## 0. INDEX DOCUMENTATION

| Document | Rôle |
|----------|------|
| **CLAUDE.md** (ce dossier) | Conventions code, Supabase, UI, sécurité, performance |
| [docs/architecture/overview.md](docs/architecture/overview.md) | Architecture système, flux applicatifs, diagrammes |
| [docs/architecture/code_health.md](docs/architecture/code_health.md) | Dette technique, doublons, incohérences, refactoring |
| [docs/supabase/schema_guide.md](docs/supabase/schema_guide.md) | Toutes les tables : colonnes, RLS, usages Flutter |
| [docs/supabase/migrations.sql](docs/supabase/migrations.sql) | Schéma SQL exécutable complet |
| [docs/supabase/rls_policies.sql](docs/supabase/rls_policies.sql) | Politiques RLS (✅ appliquées) |
| [docs/design_system/design_system.md](docs/design_system/design_system.md) | Couleurs, spacing, typographie, composants |
| [docs/realtime/realtime_guide.md](docs/realtime/realtime_guide.md) | Streams Supabase, FCM, chat temps réel |
| [docs/security/security_guide.md](docs/security/security_guide.md) | RLS, secrets, validation, checklist prod |
| [docs/roadmap/execution_roadmap.md](docs/roadmap/execution_roadmap.md) | Plan d'exécution IA par phase avec instructions |
| [docs/progress/](docs/progress/) | Suivi détaillé par module fonctionnel |

---

## 1. VISION PRODUIT

**FormelPro** est une application mobile Flutter (iOS/Android) de **mise en relation géolocalisée et sécurisée** entre clients et techniciens certifiés en Afrique.

- **Pays couverts :** Côte d'Ivoire (CIV) + Cameroun (CMR)
- **Backend :** Supabase (Auth, DB PostgreSQL, Realtime, Edge Functions)
- **Rôles utilisateurs :** Client et Technicien (switchable dans le profil)
- **Identité visuelle :** "Soft Premium" — coins arrondis, ombres légères, fond clair (#F8FAFC)
- **Thème par pays :** Orange #E67E22 (CIV) / Rouge #CE1126 (CMR)
- **Devises :** FCFA

---

## 2. STACK TECHNIQUE

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart SDK ≥ 3.0) |
| Backend | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| Cartes | flutter_map + latlong2 + geolocator |
| Notifications push | Firebase Cloud Messaging (FCM) via Edge Function Supabase |
| Typo | Google Fonts |
| Dates | intl (locale fr) |
| Stockage local | shared_preferences |

---

## 3. ARCHITECTURE PROJET

```
lib/
├── main.dart                        → AuthGate (point d'entrée, routes selon session)
├── models/
│   ├── user_model.dart              → UserModel (client/tech, fromMap/toMap)
│   └── service_category.dart        → ServiceCategory (catégories services)
├── services/
│   ├── auth_service.dart            → signUp, signIn, profil, signOut
│   ├── notification_service.dart    → Stream table notifications, SnackBar temps réel
│   ├── notification_router.dart     → navigatorKey + routeFromNotification() + pendingNotificationData (5 types de route)
│   └── fcm_service.dart             → Singleton FCM : token, topics, foreground SnackBar (kIsWeb guard)
├── screens/
│   ├── auth/
│   │   ├── choix_profil.dart        → ÉTAPE 1 : choix pays + glassmorphism
│   │   ├── auth_email_mdp.dart      → ÉTAPE 2 : email/password inscription
│   │   └── page_connexion_principale.dart → Login + routing post-auth
│   ├── dashboard/
│   │   ├── main_dashboard.dart      → TabBar orchestrateur (rôle + pays)
│   │   ├── accueil_client.dart      → Liste techniciens filtrés + shimmer
│   │   ├── accueil_technicien.dart  → Dashboard tech (dispo, stats, CTA vérification)
│   │   ├── details_technicien.dart  → Modal profil tech + démarrer conversation
│   │   ├── profil_tab.dart          → Profil éditable + toggle rôle + section admin
│   │   └── verification_documents_page.dart → Upload docs identité, statut par document
│   ├── splash_screen.dart              → Animation logo + tagline → AuthGate (mobile uniquement)
│   ├── admin/
│   │   ├── accueil_admin.dart          → Cockpit : 8 KPIs + 9 modules + bannière urgence
│   │   ├── admin_prestataires_page.dart → Gestion avancée : premium, +30j, badge, référencement ⭐, suspension
│   │   ├── admin_presence_page.dart    → Présence temps réel : en ligne, disponibles, récents
│   │   ├── admin_analytics_page.dart   → Analytics : top métiers, communes, répartition pays
│   │   ├── admin_notifications_page.dart → Architecture push (audiences, preview, guide FCM)
│   │   ├── admin_documents_page.dart   → Validation/rejet docs (accès is_admin=true)
│   │   ├── admin_signalements_page.dart → Gestion signalements utilisateurs
│   │   ├── admin_users_page.dart       → Vue globale suspension/réactivation comptes
│   │   ├── contacts_admin_page.dart    → Contacts, filtres, export CSV
│   │   └── admin_demandes_domestiques_page.dart → Workflow demandes ménagère/servante/serveuse
│   ├── interventions/
│   │   ├── demande_intervention_page.dart   → Créer intervention (client)
│   │   ├── mes_interventions_page.dart      → Liste + suivi statuts + itinéraire
│   │   ├── mission_detail_page.dart         → Détail mission (tech) + accepter
│   │   └── intervention_detail_page.dart    → Contact (client/tech) + appel
│   ├── booking/
│   │   ├── sub_categories_page.dart         → Sous-catégories de services
│   │   └── technician_selection_page.dart   → Sélection tech par catégorie
│   ├── chat/
│   │   └── chat_screen.dart         → Chat RT + proposition intervention + GPS
│   ├── tabs/
│   │   ├── missions_tab.dart        → Onglet missions (tech)
│   │   └── demandes_tab.dart        → Onglet demandes (client)
│   └── complete_profil_page.dart    → Finalisation profil post-inscription
└── widgets/
    ├── notification_badge.dart      → Badge + modal bottom sheet notifications
    ├── stats_dashboard_tech.dart    → Revenus FCFA, missions, graphique mensuel
    ├── filtres_techniciens.dart     → Model FiltresTechniciens (commune, quartier, typePrestation ajoutés) + bottom sheet filtres
    ├── categories_chips.dart        → Cartes image 96×116px DB-driven — categorieId direct, fallback gradient
    ├── services_rapides_widget.dart → 5 boutons 1-clic avec images métiers — typedef OnServiceTap, bottom sheets Gaz + Ménagère
    ├── experts_pres_widget.dart     → Liste horizontale experts dispo (est_en_ligne/disponible) — cartes 148px, filtre commune
    ├── location_picker_widget.dart  → Carte flutter_map + GPS + Nominatim — retourne ville/commune/quartier
    ├── carte_technicien.dart        → Card technicien — avatar 76×76px, compétences chips, badge sécurisé
    ├── competences_editor_sheet.dart → Sélection multi-compétences "Homme à tout faire" (technicien)
    └── category_picker.dart         → Dropdown métiers
```

---

## 4. TABLES SUPABASE (schéma vérifié le 2026-05-20)

### Tables existantes en production

| Table | Rôle | Clés notables |
|-------|------|---------------|
| `auth.users` | Gestion native Supabase Auth | — |
| `utilisateurs` | Profils enrichis client/tech | pays = `'CIV'`/`'CMR'`, rôle = `'client'`/`'technicien'` |
| `categories_services` | Catégories de services | `slug` unique, `groupe_parent` |
| `technicien_categories` | Jointure many-to-many tech↔catégories | PK composite |
| `conversations` | Fils de discussion | UNIQUE(client_id, tech_id) |
| `messages` | Messages chat | colonne date = `cree_le` |
| `interventions` | Missions | `tech_id` NOT NULL, montant = `montant_final`, titre = `titre_service` |
| `favoris` | Techniciens favoris d'un client | PK composite |
| `factures` | Factures liées aux interventions | `est_payee`, `url_pdf` |
| `avis` | Notes client→tech post-intervention | trigger `calculer_reputation_technicien()` |
| `notifications` | Notifications temps réel | trigger push FCM sur INSERT |

### Tables à créer

| Table | Rôle | Fichier suivi |
|-------|------|---------------|
| `transactions` | Paiements Mobile Money | [07_payment.md](docs/progress/07_payment.md) |
| `signalements` | Signalements utilisateurs | [10_admin.md](docs/progress/10_admin.md) |

### Points d'attention schéma

| Point | Impact |
|-------|--------|
| `pays` = `'CIV'`/`'CMR'` (pas `'CI'`/`'CM'`) | Vérifier les filtres `.eq('pays', ...)` dans le code Flutter |
| `tech_id` NOT NULL dans `interventions` | Le tech doit être sélectionné avant la création de l'intervention |
| Vérification identité inline dans `utilisateurs` | Pas de table séparée : `type_document`, `document_identite_url`, `is_identite_verifiee` |
| Colonnes à confirmer dans `utilisateurs` | `quartier`, `disponible`, `metier_principal` — présents dans le code mais absents du DDL |
| `photo_url` vs `photo_profil_url` | Deux colonnes — vérifier laquelle est utilisée côté Flutter |

> **Schéma complet :** [docs/supabase/migrations.sql](docs/supabase/migrations.sql)

---

## 5. ÉTAT ACTUEL DU PROJET (au 2026-06-01, mis à jour session 20)

### ✅ FONCTIONNEL ET COMPLET

| Module | Détail |
|--------|--------|
| **Auth flow complet** | Choix pays → Inscription → Login → Complétion profil |
| **Dashboard client** | Liste techs filtrés par pays, tri premium/score, shimmer loading — fond image `fond_ci.jpeg`/`fond_cmr.jpeg` |
| **Dashboard technicien** | Toggle disponibilité, stats, réputation — fond image `fond_ci_T.jpeg`/`fond_cmr_T.jpeg` |
| **Interventions CRUD** | Créer, accepter, suivre statuts, itinéraire Maps |
| **Chat temps réel** | Messagerie RT + propositions intervention + partage lieu |
| **Notifications RT** | Stream Supabase + FCM Edge Function Firebase |
| **Profil utilisateur** | Édition infos + switch rôle client↔tech |
| **Géolocalisation** | GPS device + carte flutter_map + sélection lieu |
| **Multi-pays** | UI et couleurs adaptées CIV/CMR |
| **Notation post-intervention** | Modal étoiles 1-5 + commentaire → `avis` + trigger réputation auto |
| **Filtre catégorie techniciens** | Chips 100% DB-driven (`categories_services` → `technicien_categories`) — cartes image 96×116px, `categorieId` direct, plus de ilike |
| **Services rapides enrichis** | 5 boutons 1-clic avec images réelles + bottom sheets contextuels : Gaz (toggle dispo + infos livraison), Ménagère (3 types : Résidente/Journalière/Ponctuelle) — `OnServiceTap` typedef avec `typePrestation` |
| **Experts près de vous** | Widget horizontal `ExpertsPresWidget` — jusqu'à 12 experts en ligne/dispos, cartes 148px avec photo/badge statut/note, filtre par commune, "Voir plus" → `TechnicianSelectionPage` |
| **Localisation contextuelle** | Bouton commune dans l'en-tête `accueil_client.dart` → ouvre `LocationPickerWidget` → met à jour `_filtres.commune`/`quartier` et relance `_fetchTechniciens` |
| **Filtrage proximité** | `_fetchTechniciens` applique `.ilike('commune', ...)` et `.ilike('quartier', ...)` depuis `FiltresTechniciens` |
| **Recherche & filtres avancés** | Disponibilité, note min, catégorie (chips DB + bottom sheet DB), commune, quartier, typePrestation, recherche texte OR (`nom_complet`/`metier_personnalise`) |
| **FCM routing notifications** | Tap notif → `ChatScreen` ou `MissionDetailPage`/`InterventionDetailPage` selon `data['type']` ; gestion background + terminated (`pendingNotificationData`) |
| **Vérification identité tech** | Page dédiée `verification_documents_page.dart` : upload CNI/passeport/certificat, statut par document (en_attente/approuvé/refusé+motif) ✅ SQL §13 exécuté — bucket Storage à créer |
| **Espace admin validation docs** | `admin_documents_page.dart` : liste docs en attente, visionneuse, valider/refuser avec motif, trigger DB auto `is_identite_verifiee` ✅ SQL §14 exécuté — activer admin via UPDATE |
| **Portail recrutement web** | `web/devenir-prestataire.html` — page HTML standalone, zéro Flutter, mobile-first, Supabase JS CDN — URL: `https://formelpro-app.vercel.app/devenir-prestataire` |
| **Flutter Web + Vercel routing** | Build web fonctionnel — `vercel.json` corrigé (`outputDirectory: build/web`, SPA catch-all → `index.html`) |
| **PWA auto-update / cache** | `vercel.json` headers Cache-Control par type — `index.html`/`flutter_bootstrap.js` → `no-store`, `main.dart.js` → `no-cache`, assets → `immutable`. `web/index.html` polling version toutes les 3 min + bannière "Nouvelle version" + auto-reload 10s + listener `controllerchange` SW + `visibilitychange` |
| **Migrations SQL idempotentes** | 5 triggers avec `DROP TRIGGER IF EXISTS` avant création — plus d'erreur "already exists" |
| **Messages lus/non lus** | `est_lu BOOLEAN` + accusés de lecture ✓/✓✓ dans les bulles, `_markMessagesRead()` automatique à l'ouverture du chat — SQL §18 à exécuter |
| **GPS prioritaire inscription** | `GpsLocationButton` — bouton premium pulsant + badge "Recommandé" dans `complete_profil_page.dart` — détection directe GPS + Nominatim → remplit ville/commune/quartier sans ouvrir la carte |
| **Auto-détect commune accueil** | `AccueilClient._autoDetectCommune()` — détecte la commune GPS au démarrage si non renseignée → applique aux filtres + rechargement techniciens |
| **Techniciens près de vous GPS** | `TechniciensPresWidget.onElargi` — bouton "Élargir ma recherche" quand filtré par commune — par défaut commune GPS |
| **Confirmation déconnexion** | Dialog "Êtes-vous sûr ?" avant déconnexion — dans `ProfilLogoutButton` (`profil_widgets.dart`) ET `AccueilClient._logout()` |
| **Campagne lancement** | `CampaignService` — 01/06/2026–31/07/2026 : Premium automatique à l'inscription — limites post-campagne : client 5 demandes / tech 3 prestations — déblocage code promo ou paiement |
| **Photos dans le chat** | Bouton "Photo" dans ChatInputBar → ImagePicker → Storage bucket `chat-images` → `image_url` dans messages — bucket à créer dans Supabase Dashboard |
| **Messages vocaux** | `AudioRecordingBar` (enregistrement avec timer + annuler/envoyer) + `AudioMessageBubble` (play/pause/slider WhatsApp-style) + `ChatActions` service (upload + insert) — Format m4a (mobile) / webm (web) — SQL §19 + bucket `chat-audio` à créer — Mic button quand champ vide, send button quand texte présent |
| **En-tête dashboard client enrichi** | `AccueilHeader` — `CircleAvatar` photo profil + `NotificationBadge` paramétrable (iconColor/badgeBorderColor) + bouton déconnexion (FCM unsubscribe + signOut + redirect) — `accueil_client.dart` passe `photoProfilUrl` + `onLogout` |
| **Contact WhatsApp FormelPro** | `showWhatsAppContactSheet` dans profil — 2 numéros : Support client +225 07 13 53 66 02 / Support prestataire +225 07 10 75 00 88 — extrait dans `profil_widgets.dart` |
| **Copyright landing page** | `landing_page.dart` — footer mis à jour : `© 2026 FormelPro by Walisylver. Tous droits réservés.` |

### ⚠️ PROBLÈMES CONNUS / DETTE TECHNIQUE

| Problème | Priorité | Fichier | Statut |
|----------|----------|---------|--------|
| Clés Supabase en dur dans le code | 🔴 HAUTE | `lib/main.dart` | ✅ Migré vers `dart_defines.json` |
| Doublon `accueil_technicien.dart` / `tech_dashboard.dart` | 🟡 MOYENNE | `screens/dashboard/` | ✅ Résolu |
| `request_form_page.dart` dans `services/` (mauvais dossier) | 🟡 MOYENNE | `lib/services/` | ✅ Supprimé (code mort) |
| `sub_categories_page.dart` dans `services/` (mauvais dossier) | 🟡 MOYENNE | `lib/services/` | ✅ Déplacé → `screens/booking/` |
| `withOpacity` déprécié → utiliser `.withValues(alpha:)` | 🟢 BASSE | Tous les fichiers | ✅ 100% migré |
| ~~WhatsApp.zip + assets orphelins~~ | 🟢 BASSE | `assets/images/` | ✅ 11 fichiers supprimés (zip, jpeg WhatsApp, fond_*old*, choix_drapeau*, fond_.jpeg) |
| Colonnes `utilisateurs` à confirmer en DB (`quartier`, `disponible`) | 🔴 HAUTE | Supabase console | 🔲 |
| Bucket Storage `documents` à créer (privé) | 🔴 HAUTE | Supabase Dashboard | 🔲 |
| `<SERVICE_ROLE_KEY>` placeholder dans migrations.sql ligne ~307 | 🔴 HAUTE | `docs/supabase/migrations.sql` | 🔲 |

### 🔲 FONCTIONNALITÉS À CONSTRUIRE (backlog)

| Fonctionnalité | Description | Priorité |
|----------------|-------------|----------|
| **Système de paiement** | Paiement manuel assisté ✅, historique transactions ✅ — API Mobile Money (Orange Money, MTN) à intégrer | 🔴 HAUTE |
| ~~**Onboarding technicien**~~ | ✅ Page vérif docs + espace admin validation — SQL §13+§14 à exécuter | ✅ |
| ~~**Recherche & filtres avancés**~~ | ✅ Implémenté — disponibilité, note min, catégorie DB, recherche texte | ✅ |
| ~~**Historique & rapports**~~ | ✅ Stats technicien implémentées (revenus FCFA, missions, en cours, graphique mensuel) | ✅ |
| ~~**FCM notification routing**~~ | ✅ Routing tap notif → bon écran (chat / intervention) | ✅ |
| **Profil premium tech** | Badge, mise en avant, abonnement mensuel | 🟡 MOYENNE |
| **Signalement / modération** | Signaler un utilisateur (✅ bouton fait), panel admin complet | 🟡 MOYENNE |
| ~~**Restrictions missions non vérifiés**~~ | ✅ Limite 3 missions actives si non vérifié — dialog CTA vers vérification (`mission_detail_page.dart`) | ✅ |
| ~~**Notifications admin**~~ | ✅ Triggers SQL §15 SECURITY DEFINER — admins notifiés au soumission doc, tech notifié à la validation | ✅ |
| ~~**Écran d'accueil (splash)**~~ | ✅ `SplashScreen` — logo fade+scale, tagline, auto-navigate vers AuthGate | ✅ |
| **Mode hors-ligne** | Cache local minimal, retry si connexion perdue | 🟢 BASSE |
| **Tests automatisés** | Widget tests + integration tests | 🟢 BASSE |

---

## 6. PLAN DE ROUTE

---

### PHASE 0 — Sécurité & Stabilité `[EN COURS]`
> Bloquer en priorité avant toute mise en production.

| # | Tâche | Où | Statut |
|---|-------|----|--------|
| 0.1 | **Appliquer les RLS** sur toutes les tables | [rls_policies.sql](docs/supabase/rls_policies.sql) | ✅ Fait |
| 0.2 | **Vérifier colonnes manquantes** dans `utilisateurs` (`quartier`, `disponible`) | Supabase SQL Editor | 🔲 À vérifier en DB |
| 0.3 | **Filtres pays** vérifiés — déjà `'CIV'`/`'CMR'` partout dans le code | — | ✅ Vérifié |
| 0.3b | **Corriger `metier_principal` → `metier_personnalise`** dans `complete_profil_page.dart` | `complete_profil_page.dart` | ✅ Fait |
| 0.3c | **Corriger filtre catégorie** — remplacé par requête via `technicien_categories` | `accueil_client.dart` | ✅ Fait |
| 0.4 | **Ajouter `url_launcher`** au pubspec.yaml | `pubspec.yaml` | ✅ Fait |
| 0.5 | **Unifier `photo_url` → `photo_profil_url`** + `.select()` ciblés | `user_model.dart`, `accueil_client.dart`, `main_dashboard.dart` | ✅ Fait |

---

### PHASE 1 — Brancher les fonctionnalités dont le backend est prêt `[QUICK WINS]`
> Tables et triggers déjà en place. Uniquement du Flutter à écrire.

| # | Tâche | Fichier à créer/modifier | Statut |
|---|-------|--------------------------|--------|
| 1.1 | **Modal de notation** après `statut = 'termine'` (étoiles 1-5 + commentaire → insert `avis`) | `mes_interventions_page.dart` + `avis_modal.dart` | ✅ Fait |
| 1.2 | **Écran Favoris** — bouton cœur sur `carte_technicien.dart` + liste favoris dans profil | `widgets/carte_technicien.dart` + `profil_tab.dart` | ✅ Fait |
| 1.3 | **Affichage facture** après intervention terminée (lien PDF si `url_pdf` renseigné) | `intervention_detail_page.dart` | ✅ Fait |
| 1.4 | **Upload photo de profil** — picker image → Supabase Storage → `photo_profil_url` | `profil_tab.dart` | ✅ Fait |
| 1.5 | **Vérification identité tech** — upload CNI → `document_identite_url` + badge si `is_identite_verifiee` | `complete_profil_page.dart` + `profil_tab.dart` | ✅ Fait |

---

### PHASE 2 — Nouvelles tables + fonctionnalités core `[MOYEN TERME]`
> Nécessite la création des tables `transactions` et `signalements` dans Supabase.

| # | Tâche | Dépendance | Statut |
|---|-------|------------|--------|
| 2.1 | **Créer table `transactions`** dans Supabase | [migrations.sql](docs/supabase/migrations.sql) § 11 | 🔲 À faire |
| 2.2 | **Créer table `signalements`** dans Supabase | [migrations.sql](docs/supabase/migrations.sql) § 12 | 🔲 À faire |
| 2.3 | **Intégration paiement Mobile Money** — Orange Money (CIV) / MTN MoMo (CMR) | Phase 2.1 | 🔲 À faire |
| 2.4 | **Bouton Signaler** un utilisateur depuis son profil | Phase 2.2 | ✅ Fait |
| 2.5 | **Notifications push côté Flutter** — abonnement topic FCM `user_{uid}` au login | `main.dart` / `auth_service.dart` | ✅ Fait (config Firebase fichiers restants) |

---

### PHASE 2 (suite) — Nouvelles fonctionnalités core

| # | Tâche | Statut |
|---|-------|--------|
| 2.4 | **FCM routing** — tap notif → `ChatScreen` / `MissionDetailPage` / `InterventionDetailPage` | ✅ Fait (`notification_router.dart`) |
| 2.6 | **Onboarding tech** — page dédiée vérification docs, CTA bannière dashboard | ✅ Fait (`verification_documents_page.dart`) — SQL §13 ✅ exécuté |
| 2.7 | **Espace admin** — validation/rejet docs, trigger `is_identite_verifiee` | ✅ Fait (`admin_documents_page.dart`) — SQL §14 ✅ exécuté |
| 2.8 | **Notifications workflow docs** — triggers §15 notifient admins (soumission) + tech (validation/rejet) | ✅ Fait — SQL §15 à exécuter dans Supabase |
| 2.9 | **Restrictions missions** — limite 3 actives si non vérifié, dialog CTA vérification | ✅ Fait (`mission_detail_page.dart`) |

---

### PHASE 3 — UX & Croissance `[LONG TERME]`

| # | Tâche | Statut |
|---|-------|--------|
| 3.1 | Recherche & filtres avancés (catégorie, disponibilité, note min, recherche texte) | ✅ Fait |
| 3.2 | Dashboard stats technicien (revenus, nb missions, graphiques) | ✅ Fait |
| 3.3 | Profil premium — badge, mise en avant, abonnement mensuel | 🔲 À faire |
| 3.4 | Espace admin léger (validation documents, gestion signalements, demandes domestiques) | ✅ Fait (AdminDocumentsPage, AdminSignalementsPage + RLS admin fix, AdminDemandesDomestiquesPage) |
| 3.5 | Écran splash + onboarding 1ère ouverture | ✅ Fait (SplashScreen mobile) |
| 3.6 | Reset mot de passe | 🔲 À faire |

---

### DETTE TECHNIQUE À RÉSORBER (en parallèle)

| Problème | Action | Priorité |
|----------|--------|----------|
| ~~Doublon `accueil_technicien.dart` / `tech_dashboard.dart`~~ | ✅ Fusionné, tech_dashboard.dart supprimé | ✅ |
| ~~`request_form_page.dart` dans `services/`~~ | ✅ Supprimé (code mort, 0 import) | ✅ |
| ~~`sub_categories_page.dart` dans `services/`~~ | ✅ Déplacé → `screens/booking/` + import MAJ | ✅ |
| Clés Supabase hardcodées dans `main.dart` | Utiliser `--dart-define` ou `.env` | 🔴 |

---

## 7. FLUX NAVIGATION (résumé)

```
Lancement app
    └── AuthGate (main.dart)
          ├── Pas de session → PageConnexionPrincipale
          │     └── Nouveau → ChoixProfil → AuthEmailMdp → CompleteProfilPage
          └── Session active
                ├── profil incomplet → CompleteProfilPage
                └── profil complet → MainDashboardPage
                      ├── Tab "Accueil" → AccueilClient / AccueilTechnicien
                      ├── Tab "Demandes" / "Missions" → DemandesTab / MissionsTab
                      └── Tab "Profil" → ProfilTab
```

---

## 8. CONVENTIONS & RAPPELS

- **Couleurs :** Orange `#E67E22` (CIV), Rouge `#CE1126` (CMR), Dark `#1E293B`, Light `#F8FAFC`
- **Toujours vérifier la nullité** des données Supabase (`?? 'défaut'`)
- **BorderRadius** standard : `BorderRadius.circular(20)` ou `22`
- **Montants :** toujours suffixés "FCFA"
- **Localisation :** `Localizations` FR configuré dans main.dart
- **Pattern Stream :** `.stream(primaryKey: ['id']).eq('user_id', uid)` pour temps réel

---

*Dernière mise à jour : 2026-06-01 — Session 22 : PWA cache fix + auto-update — `vercel.json` : headers Cache-Control par type (`/index.html` + `/flutter_bootstrap.js` + `/flutter_service_worker.js` → `no-store, must-revalidate`, `/main.dart.js` → `public, no-cache`, `/flutter.js` + `/canvaskit/*` → `immutable`). `web/index.html` : 3 meta anti-cache + bannière `#fp-update-banner` + IIFE de surveillance version (polling `/flutter_bootstrap.js?{timestamp}` toutes les 3 min, compare `serviceWorkerVersion`, affiche bannière + auto-reload 10s si non fermé) + listener `controllerchange` SW (reload immédiat) + listener `visibilitychange` (reload au retour en avant-plan). Aucun Flutter modifié. Actions restantes : `flutter build web` + push Vercel pour appliquer les nouveaux headers.*

*Dernière mise à jour : 2026-06-01 — Session 21 : Phase UX géolocalisation + campagne lancement — `GpsLocationButton` (pulsation + badge "Recommandé", détection GPS directe + Nominatim, option carte), `complete_profil_page.dart` intègre GPS bouton premium, `AccueilClient._autoDetectCommune()` (GPS auto au démarrage, filtre commune), `_logout()` dialog confirmation "Êtes-vous sûr de vouloir vous déconnecter ?", `ProfilLogoutButton` idem, `TechniciensPresWidget.onElargi` bouton "Élargir ma recherche" + icône localisation commune, `CampaignService` (isActiveCampaign, applyLaunchPremium, isClientBlocked/isTechBlocked limites 5/3, unlockWithCode promo), `auth_email_mdp.dart` applique is_premium+premium_until si campagne active à l'upsert, SQL §22 (premium_until, is_compte_bloque, table promo_codes RLS, trigger auto_premium_campagne_lancement, vue v_usage_utilisateurs). flutter analyze 0 issues.*

*Dernière mise à jour : 2026-06-01 — Session 20 : Polissage UI — `AccueilHeader` enrichi (CircleAvatar photo profil + NotificationBadge paramétrable iconColor/badgeBorderColor + bouton déconnexion), `accueil_client.dart` ajoute `_logout()` (FCM unsubscribe + signOut + redirect) + passe `photoProfilUrl`/`onLogout`, `profil_widgets.dart` + `showWhatsAppContactSheet` (Support client +225 07 13 53 66 02 / Support prestataire +225 07 10 75 00 88), `landing_page.dart` copyright → `© 2026 FormelPro by Walisylver`, texte "Besoin d'un pro ?" → "Besoin d'un technicien ?", micro-fix voice recording (kIsWeb guard + `onPermissionDenied` callback). flutter analyze 0 issues.*

*Dernière mise à jour : 2026-05-30 — Session 19 : Push Notifications V1 — `fcm_service.dart` (singleton FCM : token, 5 topics, foreground SnackBar, kIsWeb guard), `notification_prefs_page.dart` (5 toggles JSONB : messages/demandes/documents/marketing/système, master switch push_enabled), `main.dart` refactorisé (FcmService.instance.init() avec role+isPremium, is_premium dans query profil), `notification_router.dart` (3 nouvelles routes : nouveau_prestataire→AdminPrestatairesPage, demande_service/demande_sensible→AdminDemandesDomestiquesPage), `profil_tab.dart` (section Paramètres + lien NotificationPrefsPage), `web/firebase-messaging-sw.js` (service worker FCM complet avec importScripts, onBackgroundMessage, notificationclick). SQL §21 (fcm_token, push_enabled, notification_preferences, table notifications_push, 2 triggers SECURITY DEFINER). flutter analyze 0 issues. Buckets chat-images, chat-audio, documents + SQL §18–§21 + is_reference_formelpro à exécuter en DB.*

*Dernière mise à jour : 2026-05-30 — Session 18 : Dashboard Admin professionnel — `AccueilAdmin` refait (8 KPIs + 9 modules + bannière urgence), `AdminPrestatairesPage` (premium/prolonger/badge vérifié/référencement ⭐ FormelPro/suspension via bottom sheet), `AdminPresencePage` (StreamBuilder en ligne + stats), `AdminAnalyticsPage` (top métiers/communes, répartition pays, qualité), `AdminNotificationsPage` (audiences/prévisualisation/guide FCM, envoi désactivé en attente Edge Function). SQL §20 `is_reference_formelpro` ajouté à migrations.sql. flutter analyze 0 issues.*

*Session 17 précédente : Messages vocaux — `AudioRecordingBar` (timer pulsant, cancel/send, cross-platform bytes), `AudioMessageBubble` (play/pause/slider/duration WhatsApp-style, `audioplayers` UrlSource streaming), `ChatActions` service (uploadAndSendImage, sendAudio, sendProforma, confirmIntervention, markMessagesRead — extrait de chat_screen), `ChatInputBar` mic↔send toggle via `ValueListenableBuilder`, `ChatMessageList` route `message_type=='audio'` → `AudioMessageBubble`, `chat_screen.dart` refactorisé (367→257L). Permissions RECORD_AUDIO (Android) + NSMicrophoneUsageDescription (iOS). Dépendances : record ^5.1.3, audioplayers ^6.1.0, path_provider ^2.1.4. SQL §19 + Storage `chat-audio` à créer + RLS Storage dans Supabase.*

*Dernière mise à jour : 2026-05-28 — Session 16 : Option B polissage — Onboarding 3 slides (`OnboardingScreen` dark, PageView, dot indicator, SharedPreferences `onboarding_done`, skip/suivant/commencer), `SplashScreen._navigate()` async + check flag, Logout FCM (`unsubscribeFromTopic('user_$uid')` avant `signOut()` dans `ProfilLogoutButton`), nettoyage 11 assets orphelins (`WhatsApp.zip`, anciens fonds, `choix_drapeau*`). flutter analyze 0 issues.*

*Dernière mise à jour : 2026-05-28 — Session 15 : Option A chat — Messages lus/non lus (`est_lu BOOLEAN` + index + RLS UPDATE §18, `_markMessagesRead()` auto dans stream listener, accusés ✓/✓✓ dans `ChatBubble`) + Photos dans chat (bouton Photo dans `ChatInputBar`, ImagePicker galerie, upload Storage bucket `chat-images`, `image_url` dans messages, rendu `Image.network` avec loading/error states). SQL §18 à exécuter dans Supabase SQL Editor. Bucket `chat-images` (public) à créer dans Supabase Dashboard > Storage. flutter analyze 0 issues.*

*Dernière mise à jour : 2026-05-27 — Session 13 : Phase 5.7 Homme à tout faire + Phase 4.3 Admin demandes domestiques — SQL §17 colonne `competences TEXT[]` + index GIN + catégorie DB, `TechnicienService` filtre `ov` overlap, `FiltresTechniciens` champ `competences`, `FiltresSheet` section multi-select 12 compétences, `CarteTechnicien` badges chips max 3, `CompetencesEditorSheet` modal édition tech, `ProfilTab` section "Mes Compétences" + lien admin, `AdminDemandesDomestiquesPage` gestion workflow (prendre en charge/enquête/affecter/annuler), flutter analyze 0 issues. SQL §17 à exécuter dans Supabase SQL Editor.*

*Dernière mise à jour : 2026-05-27 — Session 12 : Phase 7 paiements — `PaiementPage` (sélection opérateur CIV/CMR, instructions, saisie référence, insert `transactions`), `mes_interventions_page.dart` refactorisé (bouton "Payer" client → PaiementPage, bouton "Confirmer réception" tech → UPDATE transactions.statut='confirme', badges état paiement), RLS `transactions_update_tech` ajouté dans rls_policies.sql, flutter analyze 0 issues. Table `transactions` SQL §11 à exécuter dans Supabase SQL Editor.*

*Dernière mise à jour précédente : 2026-05-26 — Session 11 : Services domestiques sensibles (ménagère/servante/serveuse) — DemandServiceDomestiquePage (3 étapes : sélection type → formulaire → confirmation), blocage contact direct dans details_technicien (`_isServiceSensible` checker), badge "Sécurisé" sur card services rapides, routing ménagère vers nouvelle page (suppression _MenagereSheet/_TypeOption), migration SQL §16 `demandes_service_domestique` + RLS + index, flutter analyze 0 issues.*

*Session 10 — Ajustement stratégique majeur — Flow chat sécurisé. Chat devient centre du système : stream unique (StreamSubscription), proforma enrichi (service/prix/lieu/date), appel conditionnel (déblocage après 3 messages OU proforma), alerte sécurité avant confirmation offre, `receiverPhone` passé depuis `details_technicien`. Suppression appel direct depuis profil tech (bouton "Contacter" unique + note explicative). Flow ménagère 3-étapes : choix type → formulaire adresse/message → confirmation automatique (sans routing vers liste techs). flutter analyze 0 issues*
