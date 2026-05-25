# Dashboards — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20*

---

# ÉTAT GLOBAL

| Domaine               | État       |
| --------------------- | ---------- |
| Dashboard principal   | ✅ Stable   |
| Dashboard client      | ✅ Stable   |
| Dashboard technicien  | 🟡 Avancé  |
| Détails technicien    | ✅ Stable   |
| Profil utilisateur    | ✅ Stable   |
| Navigation par rôles  | ✅ Stable   |
| Thématisation pays    | ✅ Stable   |
| Premium UI            | ⚠️ Partiel |
| Statistiques avancées | 🔲 À faire |
| Carte temps réel      | 🔲 À faire |

---

# STRUCTURE PRINCIPALE

## MainDashboard

**Fichier :**
`screens/dashboard/main_dashboard.dart`

### Fonctionnel

* orchestration des tabs
* adaptation selon rôle :

  * client
  * technicien
* thème dynamique selon pays
* initialisation NotificationService

### Dépendances critiques

* Supabase session
* NotificationService
* profil utilisateur

### Risques

* rebuilds inutiles
* logique métier centralisée excessive

---

# DASHBOARD CLIENT

## Accueil Client

**Fichier :**
`screens/dashboard/accueil_client.dart`

### Fonctionnel

* récupération techniciens par pays
* tri :

  * premium
  * score_global
* shimmer loading
* sélection catégories services
* ouverture profil technicien

### UX actuelle

* navigation fluide
* cards professionnelles
* modal catégories

### Règles métier

* filtrage géographique :

  * CIV → commune/quartier
  * CMR → quartier
* priorité aux profils premium

### Dette technique

* logique filtrage encore dans UI
* requêtes Supabase optimisables
* manque pagination

### Évolutions futures

* filtres avancés
* recherche intelligente
* suggestions IA
* vue carte
* favoris rapides

---

# DASHBOARD TECHNICIEN

## Accueil Technicien

**Fichier :**
`screens/dashboard/accueil_technicien.dart`

### Fonctionnel

* toggle disponibilité
* statistiques missions
* score réputation
* visibilité publique

### Données affichées

* nombre interventions
* score global
* statut disponibilité

### UX future recommandée

* revenus mensuels
* historique missions
* planning hebdomadaire
* graphiques activité

### Dette technique

* doublon partiel avec :
  `tech_dashboard.dart`

### Action recommandée

* fusionner dashboards technicien
* créer widgets réutilisables

---

# PROFIL TECHNICIEN

## Détails Technicien

**Fichier :**
`screens/dashboard/details_technicien.dart`

### Fonctionnel

* modal profil complet
* score réputation
* localisation
* contact
* ouverture conversation

### Backend associé

* table `conversations`
* création/recherche conversation existante

### Fonctionnalités avancées

* badge premium
* badge identité vérifiée
* signalement prestataire

### UX importante

* navigation rapide
* CTA visibles
* accès direct :

  * chat
  * intervention
  * appel futur

### Évolutions futures

* galerie réalisations
* portfolio photos
* certifications
* disponibilité temps réel

---

# ONGLET PROFIL

## Profil Utilisateur

**Fichier :**
`screens/dashboard/profil_tab.dart`

### Fonctionnel

* affichage profil
* édition informations
* switch rôle client/technicien

### Champs actuels

* téléphone
* ville
* commune
* quartier
* métier
* savoir_faire

### Contraintes métier

* CIV :

  * commune + quartier
* CMR :

  * quartier uniquement

### Évolutions futures

* upload avatar
* géolocalisation GPS
* badge premium
* documents identité
* métiers multiples

---

# DETTE TECHNIQUE

| Problème                     | Fichiers concernés                                   | Priorité | Action                   |
| ---------------------------- | ---------------------------------------------------- | -------- | ------------------------ |
| Doublon dashboard technicien | `accueil_technicien.dart` + `tech_dashboard.dart`    | Haute    | Fusionner                |
| Pages dans services/         | `request_form_page.dart`, `sub_categories_page.dart` | Moyenne  | Déplacer vers `screens/` |
| Logique Supabase dans UI     | dashboards multiples                                 | Haute    | Préparer repositories    |
| Requêtes non paginées        | accueil client                                       | Moyenne  | Ajouter pagination       |
| Trop de logique dans widgets | dashboard client                                     | Moyenne  | Découper composants      |

---

# PRIORITÉS FUTURES

## Haute priorité

* optimisation dashboard client
* fusion dashboard technicien
* filtres avancés
* pagination techniciens

## Moyenne priorité

* carte techniciens
* favoris rapides
* portfolio techniciens
* premium UI distinctif

## Faible priorité

* analytics avancés
* recommandations IA
* heatmaps activité

---

# NOTES IA

* Préserver navigation fluide mobile-first.
* Éviter logique métier lourde dans widgets dashboard.
* Préparer migration future vers repositories/providers.
* Toujours optimiser :

  * temps chargement
  * nombre requêtes Supabase
  * rebuilds Flutter.
* Prioriser UX simple et rapide pour utilisateurs terrain.
