# Notifications — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20*

---

# ÉTAT GLOBAL

| Domaine                           | État       |
| --------------------------------- | ---------- |
| Notifications temps réel Supabase | ✅ Stable   |
| Badge notifications               | ✅ Stable   |
| SnackBars in-app                  | ✅ Stable   |
| Firebase Cloud Messaging          | 🟡 Avancé  |
| Topics utilisateurs               | ✅ Stable   |
| Notifications foreground          | ✅ Stable   |
| Notifications background          | ✅ Stable   |
| Tap notification routing          | ⚠️ Partiel |
| Préférences notifications         | 🔲 À faire |
| Deep linking notifications        | 🔲 À faire |

---

# NOTIFICATIONS TEMPS RÉEL

## NotificationService

**Fichier :**
`services/notification_service.dart`

### Fonctionnel

* écoute table `notifications`
* stream realtime Supabase
* affichage SnackBar in-app
* notifications non lues
* marquage automatique `est_lu`

### UX actuelle

* SnackBars style Soft Premium
* notifications instantanées
* affichage non intrusif

### Types actuels

* message
* intervention
* accord

### Dette technique

* logique notifications centralisée partiellement
* pas de throttling
* pas de préférences utilisateur

### Risques

* doublons realtime + FCM
* accumulation streams
* race conditions multi-device

---

# BADGE NOTIFICATIONS

## NotificationBadge

**Fichier :**
`widgets/notification_badge.dart`

### Fonctionnel

* compteur notifications
* IconButton badge
* modal bottom sheet
* liste notifications

### UX actuelle

* accès rapide
* compteur visible
* navigation simple

### Évolutions futures

* catégories notifications
* filtres
* archivage
* suppression swipe

---

# FIREBASE CLOUD MESSAGING

## Edge Function

**Dossier :**
`supabase/functions/send-push-notification/`

### Fonctionnel

* envoi push Firebase
* génération JWT Firebase Service Account
* push vers topics utilisateurs

### Architecture actuelle

```text id="fgjlwm"
Supabase Trigger
→ Edge Function
→ Firebase FCM
→ Topic utilisateur
→ Flutter App
```

### Avantages

* scalable
* découplé
* multi-device
* compatible mobile/web futur

---

# CONFIGURATION FIREBASE

## Variables requises

| Variable                   | Emplacement      | Description                   |
| -------------------------- | ---------------- | ----------------------------- |
| `FIREBASE_SERVICE_ACCOUNT` | Supabase Secrets | JSON Service Account Firebase |
| Topic FCM                  | Flutter App      | `user_{uid}`                  |

---

# CONFIGURATION FLUTTER

## État actuel

✅ Fonctionnel

### Packages installés

```yaml id="9rvw9n"
firebase_core
firebase_messaging
```

### Fonctionnel

* `_initFCM()`
* permissions notifications
* abonnement topics
* foreground handler
* background handler
* onMessageOpenedApp

---

# INITIALISATION FCM

## AuthGate

**Fichier :**
`main.dart`

### Fonctionnel

* abonnement :
  `subscribeToTopic('user_$uid')`
* init FCM après auth
* handlers notifications

### Handlers actuels

| Handler          | État         |
| ---------------- | ------------ |
| foreground       | ✅            |
| background       | ✅            |
| terminated app   | ⚠️ Partiel   |
| notification tap | ⚠️ Hook prêt |

---

# TABLE NOTIFICATIONS

## Structure actuelle

```sql id="jlwm7"
id
user_id
titre
message
est_lu
type
date_notification
```

---

# TYPES NOTIFICATIONS ACTUELS

## Fonctionnels

* nouveau message
* nouvelle intervention
* mission acceptée
* intervention terminée

## Futurs

* paiement reçu
* badge premium
* vérification identité
* promotions
* rappels RDV

---

# ROUTING NOTIFICATIONS

## État actuel

⚠️ Partiellement implémenté

### Prévu

* ouverture chat
* ouverture intervention
* ouverture profil
* ouverture dashboard ciblé

### Dépendances

* onMessageOpenedApp
* Navigator routes
* payload `message.data`

### Recommandation

Créer :

* NotificationRouterService

---

# PRÉFÉRENCES UTILISATEUR

## Non implémenté

### Prévu

Activer/désactiver :

* messages
* interventions
* promotions
* rappels
* push sonores

### Recommandation DB

```sql id="qjlwm8"
notification_preferences
- user_id
- push_messages
- push_interventions
- push_promotions
```

---

# DETTE TECHNIQUE

| Problème                        | Priorité | Action                 |
| ------------------------------- | -------- | ---------------------- |
| Routing notifications incomplet | Haute    | Finaliser deep linking |
| Pas de préférences utilisateur  | Moyenne  | Ajouter settings       |
| Risque doublons realtime/FCM    | Haute    | Centraliser logique    |
| Pas de catégorisation avancée   | Faible   | Ajouter types enrichis |

---

# PRIORITÉS FUTURES

## Haute priorité

* routing notifications
* deep linking
* stabilisation multi-device
* optimisation realtime/FCM

## Moyenne priorité

* préférences notifications
* catégories
* historique complet

## Faible priorité

* notifications silencieuses
* résumés intelligents
* analytics notifications

---

# NOTES IA

* Ne jamais casser :

  * Firebase.initializeApp
  * AuthGate
  * topics utilisateurs
  * NotificationService
* Toujours tester :

  * foreground
  * background
  * app fermée
  * multi-device
* Éviter doublons :

  * SnackBar realtime
  * push FCM
* Préserver UX légère et non intrusive.
