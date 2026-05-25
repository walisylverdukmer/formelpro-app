# Vérification & Certification Techniciens — Suivi d'évolution

**Statut global : ✅ Complet — SQL §13+§14 exécutés, bucket Storage à créer**
*Dernière mise à jour : 2026-05-20 — Session 5 : SQL §13 (documents_verification) + §14 (is_admin, trigger) exécutés sans erreur*

---

# OBJECTIF GLOBAL

Garantir :

* confiance utilisateurs,
* sécurité plateforme,
* qualité techniciens,
* différenciation premium FormelPro.

---

# ÉTAT GLOBAL

| Domaine                       | État       |
| ----------------------------- | ---------- |
| Colonnes DB vérification      | ✅ Stable   |
| Structure inline utilisateurs | ✅ Stable   |
| Table `documents_verification` | ✅ Créée (SQL §13 exécuté 2026-05-20) |
| Badge UI | ✅ Implémenté (`accueil_technicien.dart` + `carte_technicien.dart`) |
| Upload documents Flutter | ✅ Page dédiée `verification_documents_page.dart` (CNI, passeport, certificat, diplôme) |
| Bucket Storage `documents-techniciens` | ✅ Créé (privé, policies appliquées) |
| Workflow validation admin | ✅ `admin_documents_page.dart` — SQL §14 exécuté |
| Trigger `sync_identite_verifiee` | ✅ Actif (SQL §14 exécuté 2026-05-20) |
| Blocage missions non vérifiés | ✅ Limite 3 missions actives si non vérifié (mission_detail_page.dart) |
| Notifications admin → nouveau doc soumis | ✅ Trigger SQL §15 (SECURITY DEFINER) |
| Notifications tech → validation/rejet | ✅ Insert notifications dans _approuver/_rejeter (admin_documents_page.dart) |
| Premium certification | 🟡 Préparé (colonne `certificat_confiance` existante) |

---

# ARCHITECTURE ACTUELLE

## Structure retenue

✅ Vérification directement intégrée dans :

```text id="jlwm2"
table utilisateurs
```

### Avantage

* architecture simple,
* moins de jointures,
* plus rapide côté Flutter.

---

# COLONNES EXISTANTES

## Table `utilisateurs`

| Colonne                 | Fonction                     |
| ----------------------- | ---------------------------- |
| `type_document`         | Type document soumis         |
| `document_identite_url` | URL Supabase Storage         |
| `is_identite_verifiee`  | Validation identité admin    |
| `certificat_confiance`  | Badge professionnel certifié |

---

# NIVEAUX DE CONFIANCE

| Niveau                 | Conditions                | Badge      |
| ---------------------- | ------------------------- | ---------- |
| Standard               | Compte créé               | —          |
| Identité vérifiée      | CNI validée               | ✓ Vérifié  |
| Professionnel certifié | Diplôme/certificat validé | ⭐ Certifié |
| Premium                | Certifié + abonnement     | 🏆 Premium |

---

# RÈGLES MÉTIER IMPORTANTES

## Objectif plateforme

Un technicien :

* peut créer profil librement,
* mais certaines fonctionnalités peuvent être limitées tant qu’il n’est pas vérifié.

---

# STRATÉGIE RECOMMANDÉE

## Phase 1

Accès libre plateforme

* badge simple
* pas de blocage total

## Phase 2

Restrictions progressives

* missions limitées
* visibilité réduite
* priorisation profils vérifiés

## Phase 3

Premium marketplace

* boost visibilité
* badge premium
* confiance renforcée

---

# FLUTTER — À IMPLÉMENTER

## Upload Documents

### Implémentation actuelle (✅ basique)

Upload CNI intégré dans `complete_profil_page.dart` et `profil_tab.dart` :
- Upload image → `document_identite_url`
- Sélection `type_document`
- Badge si `is_identite_verifiee = true`

### Écran dédié futur

`verification_documents_page.dart`

### Fonctionnalités à ajouter

* upload passeport
* upload diplôme
* aperçu document
* statut validation visible utilisateur

### Dépendances Flutter

* image_picker
* file_picker
* Supabase Storage

---

# UX RECOMMANDÉE

## Upload documents

### Important

* processus ultra simple,
* mobile-first,
* faible friction.

### Recommandations UX

* caméra directe
* compression image auto
* feedback upload progression
* statut clair :

  * en attente
  * approuvé
  * rejeté

---

# BADGES UI

## État actuel

⚠️ Partiellement implémenté

### Prévu

* badge vérifié
* badge certifié
* badge premium

### Zones affichage

* carte technicien
* profil technicien
* résultats recherche
* chat/interventions

---

# BLOCAGE MISSIONS

## État actuel

🔲 Non implémenté

### Recommandation

Ne PAS bloquer totalement dès le début.

### Meilleure stratégie

Limiter progressivement :

* nombre missions,
* visibilité,
* priorisation.

---

# SUPABASE STORAGE

## Bucket requis

```text id="jlwm3"
documents-techniciens
```

### Configuration recommandée

* bucket privé
* accès restreint admin
* signed URLs temporaires

---

# SÉCURITÉ CRITIQUE

## Toujours vérifier

### Backend

* propriétaire upload
* type fichier
* taille fichier
* MIME type

### Jamais autoriser

* accès public documents identité
* URL permanentes publiques

---

# RECOMMANDATION IMPORTANTE

⚠️ Incohérence détectée dans ancien document :

Le fichier mentionne :

* structure inline utilisateurs
* MAIS aussi création future :
  `documents_verification`

---

# RECOMMANDATION ARCHITECTURE

## Option recommandée

Conserver :

* informations simples dans `utilisateurs`

ET créer :

```text id="jlwm6"
documents_verification
```

pour :

* historique documents,
* multi-documents,
* workflow admin,
* rejets,
* audit.

---

# TABLE FUTURE RECOMMANDÉE

## `documents_verification`

```sql id="jlwm0"
id
user_id
type_document
document_url
status
motif_rejet
validated_by
validated_at
created_at
```

---

# STATUTS VALIDATION

| Statut       | Description     |
| ------------ | --------------- |
| `en_attente` | Soumis          |
| `approuve`   | Vérifié         |
| `rejete`     | Refusé          |
| `expire`     | Document expiré |

---

# ADMIN & MODÉRATION

## À implémenter

### Fonctionnalités

* liste documents attente
* aperçu documents
* validation/rejet
* motif refus
* historique actions

### Notifications prévues

* admin :

  * nouveau document soumis
* technicien :

  * validation
  * rejet

---

# PRIORITÉS FUTURES

## Haute priorité

* upload documents
* bucket sécurisé
* badges UI
* validation admin

## Moyenne priorité

* workflow approbation
* notifications
* restrictions missions

## Faible priorité

* OCR automatique
* détection fraude
* IA vérification documents

---

# IMPACT BUSINESS

Le système vérification est :

* essentiel confiance marketplace,
* différenciateur premium,
* levier monétisation,
* protection anti-fraude.

---

# NOTES IA

* Ne jamais exposer publiquement documents identité.
* Toute validation critique doit être backend/admin.
* Toujours tester :

  * upload mobile
  * permissions fichiers
  * réseau faible
  * signed URLs
* Préserver UX ultra simple pour artisans terrain.
* Prioriser sécurité avant automatisation avancée.
