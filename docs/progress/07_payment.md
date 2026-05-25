# Paiement Mobile Money — Suivi d'évolution

**Statut global : 🟡 Architecture préparée**
*Dernière mise à jour : 2026-05-20*

---

# OBJECTIF GLOBAL

Permettre aux clients de payer les techniciens directement depuis FormelPro via Mobile Money.

## Pays ciblés

### Côte d’Ivoire

* Orange Money
* Wave
* MTN MoMo

### Cameroun

* MTN MoMo
* Orange Money

---

# VISION PRODUIT

Le paiement doit être :

* ultra simple,
* rapide,
* mobile-first,
* sécurisé,
* compatible terrain/réseau faible.

---

# ÉTAT GLOBAL

| Domaine                             | État        |
| ----------------------------------- | ----------- |
| Structure interventions             | ✅ Stable    |
| Champ budget                        | ✅ Stable    |
| Historique transactions utilisateur | ⚠️ Partiel  |
| Architecture backend paiement       | 🟡 Préparée |
| Intégration Mobile Money            | 🔲 À faire  |
| Webhooks paiement                   | 🔲 À faire  |
| Historique paiements                | 🔲 À faire  |
| Escrow / séquestre                  | 🔲 Futur    |
| Facturation PDF                     | 🔲 Futur    |

---

# EXISTANT ACTUEL

## Table `interventions`

### Fonctionnel

* champ `budget`
* montant saisi client
* cycle mission déjà existant

### Limites actuelles

* aucun lien transactionnel réel
* pas de statut paiement
* pas de preuve paiement

---

## Table `utilisateurs`

### Fonctionnel

* `total_transactions`

### Limites

* pas encore synchronisé paiements réels

---

# ARCHITECTURE RECOMMANDÉE

## Flux paiement cible

```text id="jlwm5"
Client valide intervention
→ Choix opérateur Mobile Money
→ Paiement initié
→ Edge Function Supabase
→ API opérateur
→ Webhook confirmation
→ Validation transaction
→ Mise à jour intervention
→ Notification client/technicien
```

---

# TABLES SQL RECOMMANDÉES

## Table `transactions`

### Statut

🔲 À créer

### Structure recommandée

```sql id="jlwm8"
id
intervention_id
client_id
technicien_id
montant
currency
provider
numero_paiement
transaction_ref
external_ref
status
frais
created_at
paid_at
```

---

# STATUTS TRANSACTIONS

| Statut       | Description          |
| ------------ | -------------------- |
| `pending`    | Paiement initié      |
| `processing` | En attente opérateur |
| `success`    | Paiement validé      |
| `failed`     | Paiement échoué      |
| `cancelled`  | Annulé utilisateur   |
| `refunded`   | Remboursé            |

---

# FLUTTER — FRONTEND

## Fonctionnalités à implémenter

### Paiement

* choix opérateur
* saisie numéro
* confirmation paiement
* loader transaction

### Historique

* liste transactions
* statut paiement
* détails paiement

### UX importante

* montant en FCFA
* confirmation claire
* erreurs explicites
* retry paiement

---

# ÉCRANS FUTURS

| Écran                   | État |
| ----------------------- | ---- |
| PaymentSelectionPage    | 🔲   |
| PaymentConfirmationPage | 🔲   |
| PaymentSuccessPage      | 🔲   |
| TransactionHistoryPage  | 🔲   |

---

# BACKEND SUPABASE

## Edge Functions

### À créer

* initiation paiement
* vérification transaction
* réception webhooks
* synchronisation états

### Sécurité critique

* signature webhook
* validation montants
* protection double paiement

---

# APIs MOBILE MONEY

| Opérateur    | Pays    | État                  |
| ------------ | ------- | --------------------- |
| Orange Money | CIV     | 🔲 Partenariat requis |
| Wave         | CIV     | 🔲 Marchand requis    |
| MTN MoMo     | CIV/CMR | 🔲 Developer Portal   |

---

# CONTRAINTES BUSINESS

⚠️ Les APIs nécessitent :

* compte marchand,
* validation entreprise,
* documents administratifs,
* délai validation opérateurs.

---

# STRATÉGIE RECOMMANDÉE

## Phase 1

Paiement manuel assisté

* preuve paiement
* validation admin
* historique simple

## Phase 2

API Mobile Money réelles

* automatisation complète
* webhooks
* notifications

## Phase 3

Escrow FormelPro

* argent bloqué temporairement
* libération après mission

---

# PREMIUM & MONÉTISATION

## Prévu

### Revenus plateforme

* commissions transactions
* abonnements premium
* boost visibilité techniciens

### Premium techniciens

* badge premium
* mise en avant dashboard
* priorité résultats recherche

---

# SÉCURITÉ

## Critique

### Toujours vérifier

* montant réel
* utilisateur propriétaire
* intervention valide
* webhook signé

### Ne jamais faire

* validation frontend seule
* stockage secret API Flutter
* logique paiement uniquement client

---

# PRIORITÉS FUTURES

## Haute priorité

* table transactions
* architecture Edge Functions
* historique paiements
* statuts paiement

## Moyenne priorité

* intégration opérateur unique
* notifications paiement
* reçus transactions

## Faible priorité

* escrow
* remboursements
* analytics financiers
* factures PDF

---

# NOTES IA

* Ne jamais stocker secrets opérateurs dans Flutter.
* Toute logique paiement critique doit être backend.
* Toujours tester :

  * réseau faible
  * timeout
  * double clic paiement
  * webhook retardé
* Préserver UX ultra simple pour utilisateurs terrain.
* Prioriser stabilité avant complexité financière avancée.
