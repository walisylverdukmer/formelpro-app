# Guide Schéma Supabase — FormelPro

*Dernière mise à jour : 2026-05-20 — Schéma vérifié depuis DDL exporté*

---

## CONVENTIONS GÉNÉRALES

| Règle | Détail |
|-------|--------|
| Nommage tables | `snake_case` pluriel (`utilisateurs`, `interventions`) |
| Nommage colonnes | `snake_case` singulier (`client_id`, `est_lu`) |
| IDs | `UUID` avec `uuid_generate_v4()` par défaut |
| Dates | `TIMESTAMPTZ` avec `timezone('utc', now())` |
| Booléens | `BOOLEAN` avec `DEFAULT false` ou `true` explicite |
| Montants | `INTEGER` en **FCFA** (jamais de décimales) |
| Texte enum-like | `TEXT` + contrainte `CHECK` explicite |
| Soft delete | Non utilisé — suppression physique avec `ON DELETE CASCADE` |

### Index recommandés systématiquement
- FK souvent filtrées (`client_id`, `tech_id`, `user_id`)
- Colonnes de tri fréquentes (`created_at`, `score_global`)
- Booléens filtrés fréquemment (`est_lu`, `est_valide`, `disponible`)

---

## TABLE 1 — `utilisateurs`

**Rôle :** Profils enrichis liés à `auth.users`. Centrale dans toute la logique de l'app.

### Colonnes

| Colonne | Type | Nullable | Défaut | Description |
|---------|------|----------|--------|-------------|
| `id` | UUID | NOT NULL | — | PK = `auth.users.id` |
| `role` | TEXT | NOT NULL | — | `'client'` ou `'technicien'` |
| `pays` | TEXT | NOT NULL | — | `'CIV'` ou `'CMR'` |
| `email` | TEXT | NULL | — | Email de connexion |
| `prenom` | TEXT | NULL | — | Prénom |
| `nom_complet` | TEXT | NULL | — | Nom complet affiché |
| `age` | INTEGER | NULL | — | Âge |
| `photo_url` | TEXT | NULL | — | Ancienne colonne photo (⚠️ vérifier si encore utilisée) |
| `photo_profil_url` | TEXT | NULL | — | URL Supabase Storage photo profil |
| `ville` | TEXT | NULL | — | Ville |
| `commune` | TEXT | NULL | — | Commune (important CIV) |
| `quartier` | TEXT | NULL | — | Quartier (⚠️ absent du DDL — à vérifier) |
| `savoir_faire` | TEXT | NULL | — | Description libre compétences |
| `specialites` | TEXT | NULL | — | Spécialités formatées |
| `metier_personnalise` | TEXT | NULL | — | Métier affiché (remplace `metier_principal`) |
| `categorie_id` | UUID | NULL | — | FK → `categories_services.id` |
| `telephone` | TEXT | NULL | — | Numéro de téléphone |
| `adresse_complete` | TEXT | NULL | — | Adresse texte complète |
| `adresse_precise` | TEXT | NULL | — | Adresse précise |
| `latitude` | DOUBLE | NULL | — | Coordonnée GPS |
| `longitude` | DOUBLE | NULL | — | Coordonnée GPS |
| `est_en_ligne` | BOOLEAN | NULL | false | Statut en ligne temps réel |
| `disponible` | BOOLEAN | NULL | true | Disponible pour missions |
| `a_complete_profil` | BOOLEAN | NULL | false | Profil entièrement rempli |
| `is_premium` | BOOLEAN | NULL | false | Compte premium actif |
| `premium_until` | TIMESTAMPTZ | NULL | — | Expiration abonnement premium |
| `certificat_confiance` | BOOLEAN | NULL | false | Badge "Certifié" |
| `type_document` | TEXT | NULL | — | Type document identité soumis |
| `document_identite_url` | TEXT | NULL | — | URL document identité (Storage) |
| `is_identite_verifiee` | BOOLEAN | NULL | false | Identité validée par admin |
| `note_moyenne` | NUMERIC(2,1) | NULL | 0.0 | Alimentée par trigger `calculer_reputation_technicien` |
| `score_global` | NUMERIC(3,2) | NULL | 5.00 | Score pondéré (notes + volume) |
| `total_transactions` | INTEGER | NULL | 0 | Nb transactions confirmées |
| `points_infraction` | INTEGER | NULL | 0 | Pour système de sanctions |
| `demande_migration_active` | BOOLEAN | NULL | — | Migration client↔technicien en cours |
| `date_migration` | TIMESTAMPTZ | NULL | — | Date demande migration |
| `date_inscription` | TIMESTAMPTZ | NULL | `now()` | Date création compte |

### Contraintes
```sql
CHECK pays IN ('CIV', 'CMR')
CHECK role IN ('client', 'technicien')
FK categorie_id → categories_services(id)
```

### RLS (appliquées)
- SELECT public (profils lisibles par tous)
- UPDATE uniquement `auth.uid() = id`
- INSERT uniquement `auth.uid() = id`

### Usage Flutter
```dart
// Charger profil complet
.from('utilisateurs').select('id, nom_complet, metier_personnalise, photo_profil_url, score_global, ville, telephone, is_identite_verifiee').eq('id', uid).single()

// Liste techniciens (accueil client)
.from('utilisateurs').select('id, nom_complet, metier_personnalise, photo_profil_url, score_global, ville, commune, disponible, is_premium')
  .eq('pays', pays).eq('role', 'technicien')
  .order('is_premium', ascending: false)
  .order('score_global', ascending: false)
  .limit(50)
```

---

## TABLE 2 — `categories_services`

**Rôle :** Catalogue des catégories de services disponibles. Données de référence.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `nom` | TEXT UNIQUE | Nom affiché |
| `slug` | TEXT UNIQUE | Identifiant URL-friendly |
| `description` | TEXT | Description longue |
| `ordre_affichage` | INTEGER | Ordre dans les listes |
| `est_valide` | BOOLEAN | Actif ou archivé |
| `ajoute_par` | UUID | FK → `utilisateurs.id` (admin) |
| `date_creation` | TIMESTAMPTZ | Date création |
| `groupe_parent` | TEXT | Groupe (`'urgence'`, `'maison'`, `'evenements'`, `'logistique'`) |

### Index
```sql
idx_cat_valide ON (est_valide)
```

### RLS : SELECT public, INSERT/UPDATE via service_role uniquement

---

## TABLE 3 — `technicien_categories`

**Rôle :** Association many-to-many technicien ↔ catégories de services.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `technicien_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `categorie_id` | UUID | FK → `categories_services.id` ON DELETE CASCADE |

**PK composite :** `(technicien_id, categorie_id)`

### RLS
- SELECT public
- INSERT/DELETE : `auth.uid() = technicien_id`

### Usage Flutter
```dart
// Catégories d'un technicien
.from('technicien_categories')
  .select('categorie_id, categories_services(nom, slug)')
  .eq('technicien_id', techId)
```

---

## TABLE 4 — `conversations`

**Rôle :** Fils de discussion entre un client et un technicien (1 seul par paire).

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `client_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `tech_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `dernier_message` | TEXT | Aperçu dernier message |
| `mis_a_jour_le` | TIMESTAMPTZ | Date mise à jour |

**Contrainte unique :** `UNIQUE(client_id, tech_id)`

### RLS
- SELECT : `auth.uid() = client_id OR auth.uid() = tech_id`
- INSERT : `auth.uid() = client_id`
- UPDATE : les deux participants

### Usage Flutter
```dart
// Trouver ou créer une conversation
await supabase.from('conversations')
  .upsert({'client_id': clientId, 'tech_id': techId}, onConflict: 'client_id,tech_id')
  .select().single();
```

---

## TABLE 5 — `messages`

**Rôle :** Messages individuels dans une conversation.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `conversation_id` | UUID | FK → `conversations.id` ON DELETE CASCADE |
| `expediteur_id` | UUID | FK → `utilisateurs.id` |
| `contenu` | TEXT NOT NULL | Texte du message |
| `est_proposition_intervention` | BOOLEAN | Message = proposition d'intervention |
| `cree_le` | TIMESTAMPTZ | ⚠️ `cree_le` (pas `created_at`) |

### Realtime
`supabase_realtime` activé sur cette table.

### RLS
- SELECT : participant de la conversation (via JOIN conversations)
- INSERT : `auth.uid() = expediteur_id`

### Usage Flutter
```dart
// Stream messages d'une conversation
.from('messages')
  .stream(primaryKey: ['id'])
  .eq('conversation_id', convId)
  // ORDER BY cree_le via .order('cree_le') — vérifier support stream
```

---

## TABLE 6 — `interventions`

**Rôle :** Missions créées par les clients, acceptées et exécutées par les techniciens.

### Colonnes

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `id` | UUID PK | NOT NULL | Identifiant |
| `client_id` | UUID | NOT NULL | FK → `utilisateurs.id` |
| `tech_id` | UUID | **NOT NULL** | FK → `utilisateurs.id` (⚠️ obligatoire à la création) |
| `titre_service` | TEXT | NOT NULL | Titre/type du service |
| `description` | TEXT | NOT NULL | Détail de la demande |
| `statut` | TEXT | NULL | `'en_attente'`, `'accepte'`, `'en_cours'`, `'termine'`, `'annule'` |
| `ville` | TEXT | NULL | Ville d'intervention |
| `commune` | TEXT | NULL | Commune |
| `montant_final` | INTEGER | NULL | **Montant en FCFA** (pas `budget`) |
| `date_prevue` | TIMESTAMPTZ | NOT NULL | Date/heure prévue |
| `date_creation` | TIMESTAMPTZ | NULL | `now()` |
| `date_intervention` | TIMESTAMPTZ | NULL | Date réelle d'exécution |

### Contrainte statuts
```sql
CHECK statut IN ('en_attente', 'accepte', 'en_cours', 'termine', 'annule')
```

### Index
```sql
idx_inter_client ON (client_id)
idx_inter_tech ON (tech_id)
idx_inter_statut ON (statut)
```

### RLS
- SELECT : `client_id = uid OR tech_id = uid`
- INSERT : `client_id = uid`
- UPDATE : les deux participants

### Usage Flutter
```dart
// Demandes client
.from('interventions')
  .stream(primaryKey: ['id'])
  .eq('client_id', uid)

// Missions technicien
.from('interventions')
  .stream(primaryKey: ['id'])
  .eq('tech_id', uid)

// Insert (tech_id OBLIGATOIRE)
.from('interventions').insert({
  'client_id': clientId,
  'tech_id': techId,              // NE PAS OUBLIER
  'titre_service': titre,
  'description': desc,
  'date_prevue': datePrevue.toIso8601String(),
  'montant_final': montant,       // Pas 'budget'
})
```

---

## TABLE 7 — `favoris`

**Rôle :** Techniciens favoris d'un client.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `client_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `tech_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `date_ajout` | TIMESTAMPTZ | Date d'ajout |

**PK composite :** `(client_id, tech_id)`

### RLS : client uniquement pour ses propres favoris

### Usage Flutter (✅ implémenté — `widgets/carte_technicien.dart` + `profil_tab.dart`)
```dart
// Ajouter favori
.from('favoris').insert({'client_id': uid, 'tech_id': techId})

// Supprimer favori
.from('favoris').delete().eq('client_id', uid).eq('tech_id', techId)

// Vérifier si favori
.from('favoris').select('client_id').eq('client_id', uid).eq('tech_id', techId).maybeSingle()
```

---

## TABLE 8 — `avis`

**Rôle :** Notes et commentaires post-intervention. Alimente le score des techniciens.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `intervention_id` | UUID | FK → `interventions.id` ON DELETE CASCADE |
| `client_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `tech_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `note` | INTEGER | 1 à 5 (CHECK note BETWEEN 1 AND 5) |
| `commentaire` | TEXT | Commentaire optionnel |
| `date_avis` | TIMESTAMPTZ | ⚠️ `date_avis` (pas `created_at`) |

### Trigger
`trigger_update_reputation` → `calculer_reputation_technicien()` après INSERT/UPDATE  
Met à jour `utilisateurs.note_moyenne` et `utilisateurs.score_global`.

### ⚠️ Point d'attention
Pas de UNIQUE sur `intervention_id` → plusieurs avis possibles par intervention.  
L'UI Flutter doit vérifier si un avis existe avant d'en créer un.

### Index
```sql
idx_avis_tech ON (tech_id)
```

### RLS
- SELECT public
- INSERT : `auth.uid() = client_id` ET intervention `statut = 'termine'`

---

## TABLE 9 — `notifications`

**Rôle :** Notifications utilisateur. Alimentée par les triggers Supabase. Consommée en realtime.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `user_id` | UUID | FK → `utilisateurs.id` ON DELETE CASCADE |
| `titre` | TEXT NOT NULL | Titre notification |
| `message` | TEXT NOT NULL | Corps du message |
| `est_lu` | BOOLEAN | false par défaut |
| `type` | TEXT | `'general'`, `'message'`, `'intervention'`, `'accord'`, `'paiement'`, `'systeme'` |
| `date_notification` | TIMESTAMPTZ | `now()` |

### Trigger
`send-push-on-insert` → HTTP POST Edge Function → FCM push notification

### Realtime
`supabase_realtime` activé sur cette table.

### Index
```sql
idx_notif_user ON (user_id)
```

### RLS
- SELECT : `auth.uid() = user_id`
- UPDATE : `auth.uid() = user_id` (marquer lu)
- INSERT : via service_role uniquement (triggers, Edge Functions)

---

## TABLE 10 — `factures`

**Rôle :** Factures générées après une intervention.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `intervention_id` | UUID | FK → `interventions.id` ON DELETE CASCADE |
| `montant` | INTEGER NOT NULL | Montant FCFA |
| `url_pdf` | TEXT | URL Storage PDF facture |
| `est_payee` | BOOLEAN | false par défaut |
| `date_emission` | TIMESTAMPTZ | `now()` |

### RLS
- SELECT : participants de l'intervention (via JOIN)
- INSERT : technicien de l'intervention
- UPDATE : les deux participants

---

## TABLE 11 — `transactions` *(à créer — Phase 2.1)*

**Rôle :** Paiements Mobile Money liés aux factures/interventions.

Voir [migrations.sql § 11](migrations.sql) pour le DDL complet.

### Colonnes clés

| Colonne | Type | Description |
|---------|------|-------------|
| `operateur` | TEXT | `'orange_money'`, `'mtn_momo'`, `'wave'`, `'autre'` |
| `statut` | TEXT | `'en_attente'`, `'confirme'`, `'echoue'`, `'rembourse'` |
| `reference_externe` | TEXT | Référence retournée par l'opérateur |
| `pays` | TEXT | `'CIV'` ou `'CMR'` |

---

## TABLE 12 — `signalements`

**Rôle :** Signalements d'utilisateurs abusifs ou frauduleux.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID PK | Identifiant |
| `signale_par` | UUID | FK → `utilisateurs.id` |
| `utilisateur_signale` | UUID | FK → `utilisateurs.id` |
| `raison` | TEXT NOT NULL | Raison du signalement |
| `statut` | TEXT | `'en_attente'`, `'traite'`, `'ferme'` |
| `created_at` | TIMESTAMPTZ | `now()` |

### RLS
- SELECT : `auth.uid() = signale_par`
- INSERT : `auth.uid() = signale_par`

---

## OPTIMISATION DES REQUÊTES

### Requêtes à optimiser impérativement

```dart
// ❌ Trop large
.from('utilisateurs').select()

// ✅ Ciblé
.from('utilisateurs').select('id, nom_complet, score_global, photo_profil_url')
  .eq('pays', pays).eq('role', 'technicien').limit(50)

// ✅ Jointure Supabase (remplace deux requêtes séparées)
.from('interventions')
  .select('id, titre_service, statut, date_prevue, utilisateurs!tech_id(nom_complet, photo_profil_url)')
  .eq('client_id', uid)
```

### Index recommandés (non encore tous créés)

```sql
-- Utilisateurs
CREATE INDEX idx_users_pays_role ON utilisateurs(pays, role);
CREATE INDEX idx_users_score ON utilisateurs(score_global DESC);
CREATE INDEX idx_users_disponible ON utilisateurs(disponible) WHERE disponible = true;

-- Messages
CREATE INDEX idx_messages_conv_date ON messages(conversation_id, cree_le ASC);

-- Notifications
CREATE INDEX idx_notif_unread ON notifications(user_id, est_lu) WHERE est_lu = false;
```
