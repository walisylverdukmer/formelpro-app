# Interventions — Suivi d'évolution

**Statut global : ✅ Stable**
*Dernière mise à jour : 2026-05-25*

---

# ÉTAT GLOBAL

| Domaine                    | État       |
| -------------------------- | ---------- |
| Création intervention      | ✅ Stable   |
| Flux client                | ✅ Stable   |
| Flux technicien            | ✅ Stable   |
| Gestion statuts            | ✅ Stable   |
| Détails mission            | ✅ Stable   |
| Contact client/technicien  | ✅ Stable   |
| Navigation intervention    | ✅ Stable   |
| Notifications automatiques | ⚠️ Partiel |
| Historique avancé          | 🔲 À faire |
| Paiement lié intervention  | 🔲 À faire |

---

# CYCLE DE VIE ACTUEL

```text
Client crée
→ Technicien reçoit
→ Technicien accepte
→ Intervention en cours
→ Intervention terminée
→ Notation future
```

---

# STATUTS ACTUELS

| Statut DB    | Affichage UI | Responsable         |
| ------------ | ------------ | ------------------- |
| `en_attente` | En attente   | Système             |
| `accepte`    | Accepté      | Technicien ✅ fixé session 6 |
| `en_cours`   | En cours     | Client / Technicien |
| `termine`    | Terminé      | Client / Technicien |
| `annule`     | Annulé       | Client / Technicien |

Flux unifié :

```text
en_attente → accepte → en_cours → termine → annule
```

---

# CRÉATION INTERVENTION

## Demande Intervention

**Fichier :**
`screens/interventions/demande_intervention_page.dart`

### Fonctionnel

* description problème
* commune/quartier
* adresse
* budget
* date/heure
* insertion Supabase

### UX actuelle

* formulaire simple
* validation basique
* workflow rapide

### Contraintes métier

* CIV :

  * commune obligatoire
  * quartier recommandé
* CMR :

  * quartier prioritaire

### Dette technique

* validation formulaire perfectible
* pas d’upload photo panne
* pas de GPS automatique
* gestion erreurs réseau limitée

### Évolutions futures

* upload photos/videos
* pré-devis intelligent
* géolocalisation auto
* suggestions catégories IA

---

# LISTE INTERVENTIONS CLIENT

## Demandes Client

**Fichier :**
`screens/tabs/demandes_tab.dart`

### Fonctionnel

* stream Supabase realtime
* filtrage `client_id`
* affichage statut
* affichage date formatée

### UX actuelle

* mise à jour temps réel
* historique visible

### Améliorations futures

* filtres période
* recherche
* historique avancé
* archivage

---

# LISTE MISSIONS TECHNICIEN

## Missions Technicien

**Fichier :**
`screens/tabs/missions_tab.dart`

### Fonctionnel

* stream missions technicien
* filtrage `tech_id`
* accès détails mission

### UX actuelle

* navigation rapide
* statut visible

### Évolutions futures

* planning journalier
* vue calendrier
* tri urgence
* estimation revenus

---

# DÉTAIL MISSION TECHNICIEN

## MissionDetailPage

**Fichier :**
`screens/interventions/mission_detail_page.dart`

### Fonctionnel (mis à jour session 6)

* type intervention, description panne, date/heure, budget, localisation
* bouton accepter mission
* **✅ Statut écrit en DB : `'accepte'`** (corrigé — était `'Confirmé'`)
* **✅ `isAlreadyTaken` basé sur `statut != 'en_attente'`** (corrigé — était `tech_id != null`, toujours true)
* **✅ Limite 3 missions actives** si `is_identite_verifiee = false` — dialog avec CTA vers `VerificationDocumentsPage`
* **✅ SnackBar design system** — floating, rounded, dark background
* **✅ Import `VerificationDocumentsPage`** ajouté

### Backend associé

* `UPDATE interventions SET statut = 'accepte' WHERE id = ... AND statut = 'en_attente'`
* Vérification préalable : `SELECT is_identite_verifiee, pays FROM utilisateurs`
* Count missions actives : `SELECT id FROM interventions WHERE tech_id = uid AND statut IN ('accepte', 'en_cours')`

### UX importante

* CTA visibles, guard conditions claires
* Dialog de restriction redirige vers vérification identité (parcours fluide)

### Évolutions futures

* itinéraire intelligent
* appel direct
* checklists intervention
* pièces jointes

---

# DÉTAIL INTERVENTION / CONTACT

## InterventionDetailPage

**Fichier :**
`screens/interventions/intervention_detail_page.dart`

### Fonctionnel

* profil contact
* photo utilisateur
* informations principales
* bouton appel

### Dépendances

* utilisateurs
* conversations
* chat

### Évolutions futures

* WhatsApp direct
* partage localisation
* appels VoIP
* pièces jointes

---

# SUIVI DES STATUTS

## MesInterventionsPage

**Fichier :**
`screens/interventions/mes_interventions_page.dart`

### Fonctionnel

* changement statuts
* confirmations dialogues
* ouverture Google Maps
* ouverture Apple Maps

### UX actuelle

* suivi simple
* navigation rapide

### Dette technique

* logique statuts dispersée
* transitions non centralisées

### Recommandation

Créer :

* enum centralisé
* service intervention_status_manager

---

# NOTIFICATIONS LIÉES

## État actuel

⚠️ Partiellement implémenté

### Prévu

* push :

  * mission acceptée
  * technicien en route
  * mission terminée
  * nouveau message

### Dépendances

* Firebase Messaging
* Supabase realtime
* NotificationService

---

# PRIORITÉS FUTURES

## Haute priorité

* harmoniser statuts
* notifications automatiques
* notation après mission
* historique interventions

## Moyenne priorité

* upload photos panne
* géolocalisation précise
* filtres avancés
* dashboard missions

## Faible priorité

* pré-devis IA
* estimation temps trajet
* analytics interventions

---

# NOTES IA

* Ne jamais casser le flux realtime interventions.
* Toujours tester :

  * client
  * technicien
  * changement statuts
  * notifications
* Éviter logique statut dispersée dans UI.
* Préparer migration future vers service/repository dédié.
* Préserver navigation ultra simple pour utilisateurs terrain.
