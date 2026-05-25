# Espace Admin & Modération — Suivi d'évolution

**Statut global : ✅ Backend prêt — is_admin + trigger sync_identite_verifiee actifs**
*Dernière mise à jour : 2026-05-20 — Session 5 : SQL §14 exécuté (is_admin, is_admin(), trigger, RLS admin)*

---

# OBJECTIF GLOBAL

Créer un système d’administration permettant :

* modération plateforme,
* validation techniciens,
* gestion litiges,
* supervision activité,
* protection anti-abus,
* pilotage business FormelPro.

---

# ÉTAT GLOBAL

| Domaine                   | État        |
| ------------------------- | ----------- |
| Signalements utilisateurs | ✅ Stable    |
| Table signalements        | ✅ Stable    |
| RLS signalements          | ✅ Stable    |
| Architecture rôles        | 🟡 Préparée |
| Dashboard admin           | 🔲 À faire  |
| Validation techniciens    | ✅ Backend prêt — Flutter `admin_documents_page.dart` opérationnel |
| Gestion litiges           | 🔲 À faire  |
| Suspension utilisateurs   | 🔲 À faire  |
| Analytics plateforme      | 🔲 À faire  |

---

# STRATÉGIE RECOMMANDÉE

## Phase MVP

### Option recommandée

✅ Utiliser Supabase Studio.

### Pourquoi

* ultra rapide,
* sécurisé,
* zéro développement,
* parfait MVP.

### Actions admin possibles immédiatement

* consulter utilisateurs
* consulter interventions
* modifier flags validation
* modérer signalements

---

# ARCHITECTURE FUTURE

## Option A — Dashboard Admin Web séparé

✅ Recommandé long terme

### Avantages

* sécurité meilleure
* séparation claire
* scalable
* analytics avancés

### Stack future possible

* Flutter Web Admin
* Next.js Admin
* React Admin

---

## Option B — Admin intégré Flutter

⚠️ Possible mais plus risqué

### Fonctionnement

* rôle :
  `admin`
* écrans cachés
* accès conditionnels

### Risques

* sécurité navigation
* reverse engineering mobile
* logique admin exposée frontend

---

# RÔLES UTILISATEURS

## Table `utilisateurs`

### Colonne actuelle

```text id="jlwm4"
role
```

### Valeurs prévues

| Rôle         | Description       |
| ------------ | ----------------- |
| `client`     | Demandeur         |
| `technicien` | Prestataire       |
| `admin`      | Administration    |
| `moderateur` | Modération future |

---

# MODÉRATION UTILISATEURS

## SIGNALER PRESTATAIRE

### État actuel

✅ Fonctionnel

### Fichier

`details_technicien.dart`

### Fonctionnel

* bouton signalement
* modal raisons
* commentaire libre
* insertion `signalements`

### UX actuelle

* discret
* rapide
* non intrusif

---

# TABLE `signalements`

## État

✅ Créée

### Fonctionnel

* stockage signalements
* RLS appliqué

### Évolutions futures

* priorités gravité
* historique sanctions
* auto-moderation IA

---

# VALIDATION TECHNICIENS

## État actuel

🔲 Non implémenté

### Prévu

* liste documents attente
* validation admin
* rejet avec motif
* badges vérifiés

### Dépendances

* documents_verification
* Supabase Storage

---

# GESTION UTILISATEURS

## Fonctionnalités futures

### Suspendre utilisateur

* blocage connexion
* désactivation missions
* suspension temporaire

### Bannissement

* désactivation complète
* blacklist téléphone/email

### Colonnes recommandées

```sql id="jlwm7"
is_suspended
suspension_reason
suspended_at
banned_at
```

---

# SUPERVISION INTERVENTIONS

## À implémenter

### Vue admin globale

* interventions actives
* interventions bloquées
* interventions litigieuses

### Filtres futurs

* pays
* commune/quartier
* statut
* technicien

---

# LITIGES

## État actuel

🔲 Non implémenté

### Table recommandée

```sql id="jlwm9"
litiges
- intervention_id
- client_id
- technicien_id
- motif
- statut
- resolution
```

### Statuts recommandés

| Statut    | Description    |
| --------- | -------------- |
| `ouvert`  | Nouveau litige |
| `analyse` | En cours       |
| `resolu`  | Résolu         |
| `rejete`  | Refusé         |

---

# ANALYTICS ADMIN

## Futur dashboard

### KPIs importants

* utilisateurs actifs
* techniciens actifs
* missions/jour
* revenus
* taux réussite
* taux litiges
* temps réponse tech

---

# SÉCURITÉ ADMIN

## Critique

### Toujours vérifier backend

* rôle admin réel
* RLS strictes
* accès sécurisé
* audit actions admin

### Jamais faire

* sécurité uniquement frontend
* routes admin publiques
* bypass rôle côté Flutter

---

# RLS RECOMMANDÉES

## Admin

### Peut :

* lire signalements
* lire utilisateurs
* lire interventions
* modifier validations

### Ne doit PAS :

* accéder secrets système
* bypass authentification

---

# NOTIFICATIONS ADMIN

## Futures notifications

### Admin

* nouveau signalement
* document soumis
* litige ouvert

### Utilisateurs

* suspension
* validation identité
* rejet document

---

# PRIORITÉS FUTURES

## Haute priorité

* workflow validation techniciens
* gestion signalements
* restrictions utilisateurs
* dashboard admin minimal

## Moyenne priorité

* litiges
* analytics
* modération avancée

## Faible priorité

* IA modération
* scoring confiance
* détection fraude

---

# IMPACT BUSINESS

Le système admin est :

* critique pour confiance,
* indispensable marketplace,
* essentiel sécurité,
* nécessaire scaling production.

---

# NOTES IA

* Toute sécurité admin doit être backend-first.
* Toujours tester :

  * rôles
  * permissions
  * RLS
  * accès routes cachées
* Préserver séparation claire :

  * utilisateur
  * technicien
  * admin.
* Prioriser sécurité avant confort admin avancé.
