# Auth Flow — Suivi d'évolution

**Statut global : 🟡 Avancé**
*Dernière mise à jour : 2026-05-20*

---

# ÉTAT GLOBAL

| Domaine                         | État               |
| ------------------------------- | ------------------ |
| Inscription email/password      | ✅ Stable           |
| Connexion session persistante   | ✅ Stable           |
| Complétion profil               | ✅ Stable           |
| Routing AuthGate                | ✅ Stable           |
| Gestion rôles Client/Technicien | ✅ Stable           |
| Géolocalisation pays            | ✅ Stable           |
| Reset password                  | 🔲 À faire         |
| Vérification email              | 🔲 Production      |
| OAuth Google/Apple              | 🔲 Non prioritaire |
| Hardening sécurité              | ⚠️ Partiel         |

---

# FLUX ACTUELS

## 1. Choix du pays

**Fichier :**
`screens/auth/choix_profil.dart`

### Fonctionnel

* Sélection :

  * Côte d'Ivoire
  * Cameroun
* UI glassmorphism
* Stockage `pays` dans navigation

### Règles métier

* CIV :

  * commune + quartier
* CMR :

  * quartier uniquement

---

## 2. Inscription Email / Mot de passe

**Fichier :**
`screens/auth/auth_email_mdp.dart`

### Fonctionnel

* Création compte Supabase Auth
* Validation password
* Confirmation mot de passe
* Création profil table `utilisateurs`

### Contraintes actuelles

* password min = 6
* email verification désactivée

### Dette technique

* renforcer sécurité password
* meilleurs messages erreurs
* gestion erreurs réseau

---

## 3. Connexion existante

**Fichier :**
`screens/auth/page_connexion_principale.dart`

### Fonctionnel

* Login email/password
* récupération profil
* redirection dashboard
* fallback complétion profil

### À surveiller

* gestion session expirée
* erreurs Supabase réseau

---

## 4. Complétion Profil

**Fichier :**
`lib/screens/complete_profil_page.dart`

### Champs actuels

* prénom
* nom complet
* âge
* ville
* commune (CIV)
* quartier
* savoir_faire

### Flags utilisés

* `a_complete_profil`

### Évolutions futures

* photo profil
* géolocalisation GPS
* documents identité
* badge premium
* métiers multiples

---

## 5. AuthGate

**Fichier :**
`lib/main.dart`

### Fonctionnel

* écoute `onAuthStateChange`
* routing automatique
* session persistante

### Dépendances critiques

* Supabase.initialize
* Firebase.initializeApp

### Risques

* boucles navigation
* loading silencieux
* startup async errors

---

# SERVICE AUTH

## auth_service.dart

### Méthodes actuelles

* signUp
* signIn
* signOut
* getCurrentProfile
* markProfileAsComplete
* currentUserId
* authStateChanges

### Recommandations futures

* centraliser gestion erreurs
* DTO utilisateur
* cache session local
* analytics auth

---

# PRIORITÉS FUTURES

## Haute priorité

* reset password
* email verification
* sécurité password 8+
* validation téléphone

## Moyenne priorité

* OAuth Google
* onboarding premium
* upload avatar

## Faible priorité

* Apple Sign-In
* social login avancé

---

# NOTES IA

* Ne jamais casser AuthGate.
* Toute modification auth doit être testée :

  * mobile
  * web
  * session persistante
* Toujours préserver compatibilité Supabase Auth.
* Éviter logique métier lourde dans UI auth.
