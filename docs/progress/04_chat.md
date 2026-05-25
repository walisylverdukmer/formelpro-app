# Chat & Messagerie — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20*

---

# ÉTAT GLOBAL

| Domaine                      | État       |
| ---------------------------- | ---------- |
| Chat temps réel              | ✅ Stable   |
| Création conversations       | ✅ Stable   |
| Messages texte               | ✅ Stable   |
| Partage localisation         | ✅ Stable   |
| Propositions interventions   | ✅ Stable   |
| Scroll automatique           | ✅ Stable   |
| Notifications push chat      | ⚠️ Partiel |
| Liste conversations          | ✅ Fait — conversations_tab.dart (realtime + badge non-lus) |
| Messages multimédias         | 🔲 À faire |
| Indicateurs présence/lecture | 🔲 À faire |

---

# CHAT TEMPS RÉEL

## ChatScreen

**Fichier :**
`screens/chat/chat_screen.dart`

### Fonctionnel

* stream realtime `messages`
* filtrage `conversation_id`
* envoi messages texte
* scroll automatique dernier message
* affichage conversation dynamique

### Dépendances critiques

* Supabase realtime
* table `messages`
* table `conversations`

### UX actuelle

* mise à jour instantanée
* navigation simple
* discussion fluide

### Dette technique

* logique realtime directement dans UI
* absence pagination
* gestion erreurs réseau limitée

### Risques

* accumulation messages mémoire
* rebuilds excessifs
* streams multiples ouverts

---

# CONVERSATIONS UNIQUES

## Structure actuelle

### Table `conversations`

```sql id="2i5czn"
id
client_id
tech_id
dernier_message
mis_a_jour_le

UNIQUE(client_id, tech_id)
```

### Fonctionnel

* une seule conversation par couple :

  * client
  * technicien
* réutilisation conversation existante
* création automatique si absente

### Avantage métier

* évite doublons chat
* simplifie historique
* navigation cohérente

---

# MESSAGES

## Table `messages`

```sql id="jlwm4"
id
conversation_id
expediteur_id
contenu
est_proposition_intervention
created_at
```

### Fonctionnel

* messages texte
* propositions intervention
* messages localisation GPS

### Évolutions futures

* type_message
* image_url
* audio_url
* est_lu
* reply_to_message_id

---

# PROPOSITIONS D’INTERVENTION

## Fonctionnalité intégrée chat

### Fonctionnel

* bouton "Proposer"
* message structuré intervention
* confirmation création intervention
* liaison chat ↔ intervention

### Backend associé

* table `interventions`
* création dynamique depuis chat

### UX importante

* workflow rapide
* négociation naturelle
* réduction friction utilisateur

### Évolutions futures

* devis rapide
* pré-estimation automatique
* acceptation/refus inline

---

# PARTAGE DE LOCALISATION

## LocationPickerWidget

**Fichier :**
`widgets/location_picker_widget.dart`

### Fonctionnel

* sélection position GPS
* partage coordonnées
* intégration flutter_map

### Dépendances

* geolocator
* flutter_map
* latlong2

### UX actuelle

* partage simple
* localisation terrain rapide

### Dette technique

* pas de preview map message
* pas d’adresse humaine inverse

### Évolutions futures

* reverse geocoding
* mini map preview
* partage live location
* itinéraire direct

---

# NOTIFICATIONS CHAT

## État actuel

⚠️ Partiellement implémenté

### Fonctionnel

* infrastructure Firebase prête
* topics utilisateur existants

### À finaliser

* push nouveau message
* deep linking conversation
* badge non lus

### Dépendances

* Firebase Messaging
* NotificationService
* Supabase realtime

---

# LISTE DES CONVERSATIONS

## État actuel

🔲 Non implémenté

### Prévu

* écran conversations
* aperçu dernier message
* tri activité récente
* badge non lus

### UX recommandée

* style WhatsApp/Messenger
* avatars
* indicateurs statut
* recherche rapide

---

# INDICATEURS TEMPS RÉEL

## À implémenter

### Lecture messages

* simple check
* double check
* message vu

### Présence utilisateur

* en ligne
* hors ligne
* dernière activité

### Typing indicator

* "en train d’écrire"

---

# MULTIMÉDIA FUTUR

## Priorités futures

* photos panne
* documents
* audio court
* vidéos courtes

### Backend prévu

* Supabase Storage

### Contraintes

* compression obligatoire
* optimisation mobile réseau faible

---

# PRIORITÉS FUTURES

## Haute priorité

* liste conversations
* notifications push messages
* système messages lus
* pagination chat

## Moyenne priorité

* photos
* preview localisation
* présence utilisateur
* typing indicator

## Faible priorité

* audio
* vidéos
* réponses messages
* réactions emoji

---

# NOTES IA

* Ne jamais casser le realtime chat.
* Toujours tester :

  * web
  * mobile
  * streams multiples
  * navigation conversation
* Éviter logique Supabase directement dans widgets.
* Préparer migration future vers ChatRepository.
* Optimiser mémoire et performances Web.
* Préserver UX ultra rapide style messagerie moderne.
