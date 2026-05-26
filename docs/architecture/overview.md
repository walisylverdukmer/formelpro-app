# Architecture Système — FormelPro

*Dernière mise à jour : 2026-05-26 — Session 8*

---

## 1. VUE GLOBALE SYSTÈME

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP                               │
│                    Flutter (iOS / Android)                      │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Screens │  │ Widgets  │  │ Services │  │    Models    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       └─────────────┴─────────────┘                │           │
│                           │                        │           │
│                    Supabase Flutter SDK             │           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
        ┌───────────────────┼─────────────────────┐
        │                   │                     │
        ▼                   ▼                     ▼
┌──────────────┐  ┌──────────────────┐  ┌─────────────────┐
│  Supabase    │  │  Supabase        │  │  Supabase       │
│  Auth        │  │  PostgreSQL DB   │  │  Storage        │
│              │  │  + Realtime      │  │  (images, docs) │
│  JWT tokens  │  │  + RLS           │  │                 │
└──────────────┘  └────────┬─────────┘  └─────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Supabase   │
                    │  Edge       │
                    │  Functions  │
                    │  (Deno)     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Firebase   │
                    │  Cloud      │
                    │  Messaging  │
                    │  (FCM)      │
                    └─────────────┘
```

---

## 2. FLUX APPLICATIFS

### 2.1 Flux Authentification

```
App Launch
    │
    ▼
AuthGate (main.dart)
    │
    ├── auth.onAuthStateChange → session == null
    │       └── PageConnexionPrincipale
    │               ├── [Nouveau] → ChoixProfil (pays CIV/CMR)
    │               │                └── AuthEmailMdp (email + password)
    │               │                        └── [Insert utilisateurs]
    │               │                                └── CompleteProfilPage
    │               │                                        └── [Update a_complete_profil = true]
    │               │                                                └── MainDashboardPage ✅
    │               └── [Existant] → Login → check a_complete_profil
    │                                   ├── false → CompleteProfilPage
    │                                   └── true  → MainDashboardPage ✅
    │
    └── session != null → _getUserProfile()
            └── FCM: _initFCM(userId) → subscribeToTopic('user_$uid')
                └── MainDashboardPage / CompleteProfilPage
```

### 2.2 Flux Intervention

```
Client (AccueilClient)
    │
    ├── Parcourt la liste des techniciens (filtrée par pays + rôle)
    ├── Tap sur un tech → DetailsTechnicien
    │       ├── Message → ChatScreen
    │       ├── Appeler → url_launcher tel:
    │       └── Signaler → _SignalerModal → insert signalements
    │
    └── Sélectionner catégorie → TechnicianSelectionPage
            └── Tap tech → DemandeInterventionPage
                    └── [Insert interventions: client_id, tech_id, titre, date_prevue]
                            │
                            ▼
                    CYCLE DE VIE INTERVENTION
                    en_attente → accepte → en_cours → termine → [avis]
                         │           │
                    (Tech voit    (Tech accepte
                    MissionsTab)  MissionDetailPage)
```

### 2.3 Flux Chat

```
Client → DetailsTechnicien → "Message"
    │
    ├── Cherche conversation existante (UNIQUE client_id, tech_id)
    ├── Crée si inexistante → insert conversations
    └── ChatScreen(conversationId)
            │
            ├── Stream messages WHERE conversation_id = X ORDER BY cree_le
            ├── TextField → onSend → insert messages
            ├── Bouton "Proposer" → message formaté est_proposition_intervention = true
            │       └── "Confirmer" → insert interventions depuis le message
            └── LocationPicker → envoie coordonnées GPS dans contenu
```

### 2.4 Flux Notifications

```
Déclencheur (Supabase)
    │
    ├── Insert dans table notifications
    │       └── Trigger "send-push-on-insert"
    │               └── HTTP POST → Edge Function send-push-notification
    │                       └── Firebase Admin SDK
    │                               └── FCM → Appareil (topic user_$uid)
    │
    └── Realtime Stream (NotificationService)
            └── .stream(['id']).eq('user_id', uid).eq('est_lu', false)
                    └── SnackBar "Soft Premium" (foreground)
                    └── Marque est_lu = true

Client FCM (main.dart)
    ├── onMessage → silencieux (doublon SnackBar évité)
    ├── onBackgroundMessage → notification système automatique
    └── onMessageOpenedApp → routing futur Phase 3
```

### 2.5 Flux Notation

```
MesInterventionsPage
    └── statut = 'termine'
            └── Bouton "Laisser un avis"
                    └── Modal notation (étoiles 1-5 + commentaire)
                            └── insert avis
                                    └── Trigger calculer_reputation_technicien()
                                            └── UPDATE utilisateurs SET note_moyenne, score_global
```

### 2.6 Flux Portail Recrutement Web

```
Facebook / WhatsApp / TikTok / QR Code
    └── https://formelpro-app.vercel.app/devenir-prestataire
            └── web/devenir-prestataire.html (HTML standalone)
                    ├── Formulaire : prénom, nom, email, téléphone, pays, ville, métier
                    ├── supabase.auth.signUp(email, password généré)
                    ├── if session → supabase.from('utilisateurs').insert(role: 'technicien')
                    └── Écran succès : email + mot de passe temporaire (tap-to-copy)
```

---

## 3. STRUCTURE DES DOSSIERS

```
lib/
├── main.dart                    RÔLE: AuthGate + init Firebase/Supabase + FCM
│
├── models/                      RÔLE: Structures de données (fromMap/toMap)
│   ├── user_model.dart          → UserModel
│   └── service_category.dart   → ServiceCategory
│
├── services/                    RÔLE: Logique métier découplée des widgets
│   ├── auth_service.dart        → signUp, signIn, signOut, getCurrentProfile
│   ├── notification_service.dart → Stream notif + SnackBar temps réel
│   └── notification_router.dart → navigatorKey global + routeFromNotification()
│
├── screens/                     RÔLE: Écrans (1 fichier = 1 page)
│   ├── auth/
│   │   ├── choix_profil.dart          → Étape 1 : choix pays (glassmorphism)
│   │   ├── auth_email_mdp.dart        → Étape 2 : inscription
│   │   ├── page_connexion_principale.dart → Login — fond image login_bg.jpeg
│   │   └── reset_password_page.dart   → Réinitialisation mot de passe
│   │
│   ├── dashboard/
│   │   ├── main_dashboard.dart        → Orchestrateur TabBar (rôle + pays)
│   │   ├── accueil_client.dart        → Liste techs + shimmer — fond fond_ci.jpeg/fond_cmr.jpeg
│   │   ├── accueil_technicien.dart    → Dashboard tech — fond fond_ci_T.jpeg/fond_cmr_T.jpeg
│   │   ├── details_technicien.dart    → Profil tech + Signaler
│   │   ├── profil_tab.dart            → Profil éditable + toggle rôle + section admin
│   │   └── verification_documents_page.dart → Upload docs identité tech
│   │
│   ├── admin/
│   │   └── admin_documents_page.dart  → Validation/rejet docs (is_admin=true)
│   │
│   ├── interventions/
│   │   ├── demande_intervention_page.dart  → Créer intervention
│   │   ├── mes_interventions_page.dart     → Liste + statuts + itinéraire
│   │   ├── mission_detail_page.dart        → Détail (tech) + accepter
│   │   └── intervention_detail_page.dart   → Contact + appel
│   │
│   ├── booking/
│   │   ├── sub_categories_page.dart        → Sous-catégories de services
│   │   └── technician_selection_page.dart  → Sélection tech par catégorie
│   │
│   ├── chat/
│   │   └── chat_screen.dart               → Chat RT + proposition + GPS
│   │
│   ├── tabs/
│   │   ├── missions_tab.dart              → Onglet missions (tech)
│   │   └── demandes_tab.dart              → Onglet demandes (client)
│   │
│   └── complete_profil_page.dart          → Finalisation profil
│
├── widgets/                     RÔLE: Composants réutilisables multi-écrans
│   ├── notification_badge.dart        → Badge + modal notifs
│   ├── location_picker_widget.dart    → Carte GPS + sélection
│   ├── carte_technicien.dart          → Card technicien — avatar 76×76px arrondi + badge disponibilité
│   ├── categories_chips.dart          → Cartes image 96×116px DB-driven — categorieId, fallback gradient
│   ├── services_rapides_widget.dart   → 5 boutons 1-clic avec images métiers + fallback icône
│   ├── stats_dashboard_tech.dart      → Revenus FCFA, missions, graphique mensuel
│   ├── filtres_techniciens.dart       → Model FiltresTechniciens + bottom sheet filtres
│   └── category_picker.dart           → Dropdown métiers
│
web/                             RÔLE: Pages HTML standalone (hors Flutter)
└── devenir-prestataire.html          → Portail recrutement — mobile-first, Supabase JS CDN
                                        URL: formelpro-app.vercel.app/devenir-prestataire
```

---

## 4. ARCHITECTURE ACTUELLE vs ARCHITECTURE CIBLE

### 4.1 Actuelle (Flutter + Supabase direct)

```
Widget (StatefulWidget)
    └── build() / méthodes async
            └── Supabase.instance.client.from('table').select(...)
```

**Avantages :** Simple, rapide à écrire  
**Inconvénients :** Couplage fort, tests difficiles, duplication, pas de cache

### 4.2 Cible recommandée (Riverpod + Repository)

```
Widget (ConsumerWidget)
    └── ref.watch(interventionsProvider)
            └── InterventionsNotifier (StateNotifier/AsyncNotifier)
                    └── InterventionsRepository
                            └── SupabaseClient
```

**Migration progressive recommandée :**
1. Ne pas tout migrer d'un coup
2. Commencer par les nouvelles fonctionnalités (paiement, notation)
3. Migrer les existants lors de refactors planifiés

### 4.3 Services cibles à créer

| Service | Responsabilité |
|---------|----------------|
| `UserService` | Profil, mise à jour, upload photo |
| `InterventionService` | CRUD interventions, suivi statuts |
| `ChatService` | Conversations, messages, propositions |
| `NotificationService` | (existe déjà — à refactorer) |
| `StorageService` | Upload images, documents |
| `PaymentService` | (Phase 2) Transactions Mobile Money |

---

## 5. DIAGRAMMES TECHNIQUES

### 5.1 Auth Flow simplifié

```
onAuthStateChange
    │
    ├─ null ──────────────────────► PageConnexionPrincipale
    │                                       │
    │                              [signup] │ [signin]
    │                                       ▼
    └─ session ──► _getUserProfile()   AuthEmailMdp
                        │
                   a_complete_profil?
                        │
              ┌─────────┴──────────┐
              │ false              │ true
              ▼                   ▼
       CompleteProfilPage   MainDashboardPage
              │
              └──[mark complete]──► MainDashboardPage
```

### 5.2 Realtime Stack

```
PostgreSQL Table
    │ (INSERT/UPDATE)
    ▼
Supabase Realtime Server (WebSocket)
    │
    ▼
Flutter supabase_flutter SDK
    │
    └── .stream(primaryKey: ['id'])
              │
              ▼
        StreamBuilder
              │
              └── Widget rebuild
```

### 5.3 FCM Push Stack

```
Supabase PostgreSQL
    │ INSERT INTO notifications
    │
    ▼
Trigger "send-push-on-insert"
    │
    ▼
Edge Function (Deno) — send-push-notification
    │ Firebase Admin JWT + FCM v1 API
    ▼
Firebase Cloud Messaging
    │ topic: user_{userId}
    ▼
Device (iOS/Android)
    ├── App foreground → onMessage (silencieux — SnackBar Supabase prioritaire)
    ├── App background → Notification système automatique
    └── App fermée    → Notification système + onMessageOpenedApp au tap
```
