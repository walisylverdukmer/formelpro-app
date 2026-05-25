# Notation & Avis — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20*

---

# ÉTAT GLOBAL

| Domaine                         | État       |
| ------------------------------- | ---------- |
| Table avis Supabase             | ✅ Stable   |
| Trigger réputation              | ✅ Stable   |
| Score global techniciens        | ✅ Stable   |
| Affichage étoiles UI            | ✅ Stable   |
| Dépôt avis Flutter              | ✅ Stable   |
| Protection anti-doublon UI      | ✅ Stable   |
| Validation backend anti-doublon | ⚠️ Partiel |
| Historique avis utilisateur     | 🔲 À faire |
| Réponses techniciens aux avis   | 🔲 À faire |
| Modération avis                 | 🔲 À faire |

---

# ARCHITECTURE ACTUELLE

## Objectif métier

Permettre :

* aux clients d’évaluer les techniciens,
* d’alimenter la réputation publique,
* de renforcer confiance plateforme,
* de prioriser les meilleurs experts.

---

# TABLE `avis`

## État actuel

✅ En production

### Structure

```sql id="jlwm9"
id
intervention_id
client_id
tech_id
note
commentaire
date_avis
```

### Fonctionnel

* note 1 → 5
* commentaire optionnel
* liaison intervention
* liaison client/technicien

---

# TRIGGER RÉPUTATION

## Fonctionnel

✅ Automatique

### Trigger

`trigger_update_reputation`

### Fonction associée

`calculer_reputation_technicien()`

### Effets

* recalcul :

  * note_moyenne
  * score_global
  * nb_avis

### Table impactée

`utilisateurs`

---

# FORMULE SCORE GLOBAL

## Fonction actuelle

score_{global}=(note_{moyenne}\times0.6)+\left(\frac{\min(nb_{avis},100)}{100}\times0.4\times5\right)

---

# INTERPRÉTATION

Le score favorise :

* qualité réelle des avis,
* ancienneté/régularité,
* techniciens actifs.

---

# AFFICHAGE UI

## Carte Technicien

**Fichier :**
`widgets/carte_technicien.dart`

### Fonctionnel

* lecture `score_global`
* affichage étoiles
* tri réputation

### UX actuelle

* visibilité immédiate réputation
* impact confiance utilisateur

---

# FLUTTER — AVIS CLIENT

## Détection intervention terminée

**Fichier :**
`mes_interventions_page.dart`

### Fonctionnel

* détection :
  `statut = 'termine'`
* affichage bouton :
  `Évaluer`

---

# MODAL AVIS

## AvisModal

**Fichier :**
`lib/screens/interventions/avis_modal.dart`

### Fonctionnel

* sélection étoiles
* labels contextuels
* commentaire optionnel
* limite 300 caractères
* validation formulaire

### UX actuelle

* rapide
* mobile-first
* faible friction

### Évolutions futures

* emojis satisfaction
* tags prédéfinis
* photos réalisation

---

# INSERTION AVIS

## Fonctionnel

* insertion table `avis`
* liaison intervention/client/tech
* feedback utilisateur SnackBar

### UX actuelle

* confirmation immédiate
* refresh automatique

---

# PROTECTION ANTI-DOUBLON

## État actuel

⚠️ Protection frontend uniquement

### Fonctionnel

* `_avisDeposes`
* `Set<String>`
* badge :
  `Avis déposé`

### Limite critique

Pas de contrainte SQL UNIQUE.

---

# RECOMMANDATION CRITIQUE

## Ajouter contrainte backend

### Recommandé

```sql id="jlwm1"
UNIQUE(intervention_id, client_id)
```

### Pourquoi

La protection frontend seule est insuffisante :

* multi-device,
* requêtes manuelles,
* API directes,
* race conditions.

---

# DETTE TECHNIQUE

| Problème                     | Priorité | Action                      |
| ---------------------------- | -------- | --------------------------- |
| Pas de contrainte SQL UNIQUE | Haute    | Ajouter contrainte          |
| Pas de modération avis       | Moyenne  | Ajouter système signalement |
| Pas d’historique avis profil | Moyenne  | Ajouter écran dédié         |
| Pas de réponses techniciens  | Faible   | Ajouter replies             |

---

# ÉVOLUTIONS FUTURES

## Haute priorité

* sécurisation backend anti-doublon
* historique avis
* analytics réputation

## Moyenne priorité

* réponses techniciens
* filtres avis
* badges réputation

## Faible priorité

* IA analyse satisfaction
* recommandations automatiques
* score confiance avancé

---

# IMPACT BUSINESS

Le système avis est :

* critique pour confiance,
* essentiel marketplace,
* facteur clé conversion,
* levier premium futur.

---

# NOTES IA

* Ne jamais casser :

  * trigger réputation
  * score_global
  * affichage étoiles
* Toujours tester :

  * recalcul réputation
  * multi-device
  * refresh UI
  * interventions terminées
* Toute sécurité critique doit être backend SQL et non frontend uniquement.
* Préserver UX ultra rapide après mission terminée.
