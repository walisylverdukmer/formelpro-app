# Favoris, Factures & Authentification — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20 (session 3)*

---

# ÉTAT GLOBAL

| Domaine                    | État        |
| -------------------------- | ----------- |
| Favoris techniciens        | ✅ Stable    |
| Factures PDF               | 🟡 Avancé   |
| Reset mot de passe         | ✅ Stable    |
| Historique favoris         | ⚠️ Partiel  |
| Génération PDF automatique | 🔲 À faire  |
| Paiement lié factures      | 🔲 À faire  |
| Sécurité reset password    | 🟡 Préparée |

---

# 1. FAVORIS TECHNICIENS

## OBJECTIF

Permettre aux clients :

* sauvegarder techniciens préférés,
* retrouver rapidement experts fiables,
* améliorer rétention plateforme.

---

# BACKEND FAVORIS

## Table `favoris`

### Colonnes actuelles

```sql id="jlwm5"
client_id
tech_id
date_ajout
```

### État actuel

✅ Fonctionnel

### Limite actuelle

⚠️ Pas de contrainte UNIQUE backend documentée.

---

# RECOMMANDATION CRITIQUE

Ajouter :

```sql id="jlwm2"
UNIQUE(client_id, tech_id)
```

### Pourquoi

La protection frontend seule est insuffisante :

* multi-device,
* appels API directs,
* race conditions.

---

# FLUTTER — FAVORIS

## CarteTechnicien

**Fichier :**
`widgets/carte_technicien.dart`

### Fonctionnel

* StatefulWidget
* check favori initial
* toggle favoris
* spinner chargement
* cœur dynamique

### UX actuelle

* interaction rapide
* feedback immédiat
* rétrocompatibilité conservée

### Fonctionnalités

* favori :
  ❤️ rouge
* non favori :
  🤍 vide

---

# ACCUEIL CLIENT

## Intégration favoris

**Fichier :**
`screens/dashboard/accueil_client.dart`

### Fonctionnel

* transmission `clientId`
* activation favoris contextuels

### UX actuelle

* favoris accessibles directement recherche

---

# ONGLET PROFIL — FAVORIS

## ProfilTab

**Fichier :**
`screens/dashboard/profil_tab.dart`

### Fonctionnel

* chargement favoris
* affichage liste techniciens
* navigation profil technicien
* état vide géré

### UX actuelle

* section dédiée :
  `Mes Favoris`
* uniquement rôle client

### Dette technique

* double requête Supabase
* pas pagination
* pas cache local

---

# ÉVOLUTIONS FUTURES FAVORIS

## Haute priorité

* contrainte SQL UNIQUE
* optimisation requêtes
* pagination favoris

## Moyenne priorité

* tri favoris récents
* favoris premium
* suggestions similaires

## Faible priorité

* collections favoris
* notes privées client
* IA recommandations

---

# 2. FACTURES PDF

## OBJECTIF

Permettre :

* suivi paiements,
* preuves interventions,
* historique financier,
* futur système premium.

---

# BACKEND FACTURES

## Table `factures`

### Structure actuelle

```sql id="jlwm0"
intervention_id
url_pdf
est_payee
montant
```

### État actuel

🟡 Partiellement exploité

---

# FLUTTER — FACTURES

## InterventionDetailPage

**Fichier :**
`screens/interventions/intervention_detail_page.dart`

### Fonctionnel

* chargement parallèle :
  `Future.wait`
* affichage facture
* badge paiement
* ouverture PDF externe

### Corrections déjà effectuées

* mapping colonnes Supabase
* select explicites
* fix profils utilisateurs

### UX actuelle

* consultation simple
* badge paiement visible
* ouverture PDF externe

---

# BADGES FACTURES

## États actuels

| Statut             | Affichage    |
| ------------------ | ------------ |
| `est_payee = true` | ✅ Payée      |
| `false`            | ⏳ En attente |

---

# DETTE TECHNIQUE FACTURES

| Problème                 | Priorité | Action                     |
| ------------------------ | -------- | -------------------------- |
| Génération PDF absente   | Haute    | Ajouter génération backend |
| Pas stockage structuré   | Moyenne  | Bucket dédié               |
| Pas de signature facture | Faible   | Ajouter validation PDF     |

---

# ÉVOLUTIONS FUTURES FACTURES

## Haute priorité

* génération PDF automatique
* téléchargement local
* historique complet

## Moyenne priorité

* logo FormelPro
* reçu paiement
* partage facture

## Faible priorité

* QR validation
* signature numérique
* analytics financiers

---

# 3. RESET MOT DE PASSE

## OBJECTIF

Permettre récupération compte utilisateur sécurisée.

---

# BACKEND AUTH

## Supabase natif

### Fonction utilisée

```dart id="jlwm8"
supabase.auth.resetPasswordForEmail(email)
```

### État

✅ Fonctionnel

---

# PRÉREQUIS PRODUCTION

⚠️ Important :

Activer :

* confirmation email,
* SMTP production,
* templates emails.

---

# FLUTTER — RESET PASSWORD

## ResetPasswordPage

**Fichier :**
`screens/auth/reset_password_page.dart`

### Fonctionnel

* saisie email
* envoi lien reset
* état succès
* gestion erreurs

### UX actuelle

* thème dark cohérent auth
* feedback utilisateur clair
* navigation retour connexion

### Gestion erreurs

* AuthException
* SnackBar flottant

---

# PAGE CONNEXION

## Intégration

**Fichier :**
`screens/auth/page_connexion_principale.dart`

### Fonctionnel

* lien :
  `Mot de passe oublié ?`
* navigation reset password

---

# SÉCURITÉ AUTH

## Important

### Production

* SMTP réel
* anti-spam
* limitation tentatives
* expiration liens reset

### Jamais faire

* afficher si email existe
* exposer erreurs sensibles

---

# PRIORITÉS FUTURES

## Haute priorité

* génération PDF automatique
* contrainte SQL favoris
* SMTP production

## Moyenne priorité

* historique factures
* téléchargements offline
* analytics favoris

## Faible priorité

* favoris intelligents
* IA recommandations
* reçus avancés

---

# NOTES IA

* Ne jamais casser :

  * auth Supabase
  * reset password
  * favoris client
  * ouverture factures
* Toujours tester :

  * multi-device
  * états favoris
  * liens reset
  * PDFs externes
* Toute sécurité auth doit rester backend-first.
* Préserver UX simple et rapide pour utilisateurs terrain.
