# FORMELPRO — MODÈLE GLOBAL OFFICIEL

## Vision du projet

FormelPro est une plateforme africaine de services locaux permettant de connecter rapidement des clients à des prestataires de confiance dans les métiers techniques, domestiques et les services rapides.

L’objectif n’est pas seulement de créer un annuaire de techniciens, mais une véritable plateforme sécurisée de mise en relation, conversation, validation et suivi des prestations.

La plateforme doit être :

* mobile-first,
* simple,
* visuelle,
* adaptée aux réalités africaines,
* optimisée pour les utilisateurs peu techniques,
* sécurisée,
* scalable.

---

# 1. TYPES D’UTILISATEURS

## A. CLIENT

Le client peut :

* rechercher un technicien,
* rechercher un service rapide,
* discuter avec un prestataire,
* recevoir une proposition/proforma,
* valider une prestation,
* payer plus tard dans l’application,
* noter un prestataire,
* gérer ses demandes.

---

## B. PRESTATAIRE

Le prestataire peut :

* créer un profil,
* définir ses métiers et spécialités,
* recevoir des demandes,
* discuter avec les clients,
* envoyer des propositions,
* gérer sa disponibilité,
* recevoir des paiements futurs,
* améliorer sa réputation.

IMPORTANT :
Un prestataire peut aussi être client.

Le système doit permettre :

* changement de mode dynamique,
* sans création de plusieurs comptes.

Exemple :

* un plombier peut commander du gaz,
* un électricien peut chercher un maçon.

---

## C. ADMINISTRATEUR

L’administrateur gère :

* validation prestataires,
* validation documents,
* métiers sensibles,
* enquêtes moralité,
* signalements,
* litiges,
* statistiques,
* sécurité plateforme,
* transactions futures,
* gestion localisation,
* gestion catégories,
* modération générale.

---

# 2. ARCHITECTURE GLOBALE

## A. LANDING PAGE PUBLIQUE

Objectif :

* acquisition clients,
* acquisition prestataires,
* accès rapide services.

La landing page doit être :

* simple,
* très visuelle,
* mobile-first,
* accessible sans connexion.

Contenu :

* Hero section,
* quelques grands cadres services,
* experts proches,
* bouton recherche technicien,
* bouton devenir prestataire,
* bouton entrer dans l’application.

---

## B. LANDING PRESTATAIRES

Route :
/devenir-prestataire

Objectif :
recrutement rapide de prestataires via :

* Facebook,
* WhatsApp,
* TikTok,
* QR codes,
* terrain.

Le formulaire doit être :

* ultra simple,
* rapide,
* mobile-first.

Après inscription :

* création compte,
* email accès,
* onboarding prestataire.

---

## C. APPLICATION AUTHENTIFIÉE

Contient :

* dashboard client,
* dashboard prestataire,
* dashboard admin,
* chat,
* historique,
* notifications,
* demandes,
* validations,
* profil,
* favoris.

---

# 3. FLOW CLIENT GLOBAL

## FLOW PRINCIPAL

Landing
→ choix service
→ choix commune/quartier
→ liste techniciens disponibles
→ chat sécurisé
→ proforma/prestation
→ validation future
→ paiement futur
→ intervention
→ notation.

---

## FLOW “RECHERCHER UN TECHNICIEN”

### Étape 1

Choisir domaine/service.

### Étape 2

Choisir :

* ma commune,
* autre commune.

### Étape 3

Afficher immédiatement :

* techniciens disponibles,
* proximité,
* disponibilité,
* réputation.

### Étape 4

Décrire précisément le besoin.

### Étape 5

Ouvrir chat sécurisé.

---

# 4. CHAT — CŒUR DU SYSTÈME

Le chat devient :

* espace discussion,
* espace négociation,
* espace sécurité,
* espace preuve,
* espace proforma,
* espace validation.

IMPORTANT :
Le contact direct immédiat doit être limité.

Le bouton appel doit être débloqué seulement :

* après échanges,
* ou validation prestation,
* ou accord.

---

# 5. PROFORMA / TRACE CONTRACTUELLE

Pendant les échanges :
le système doit garder une trace structurée :

* type prestation,
* montant,
* localisation,
* date,
* accord,
* technicien concerné.

Ces informations servent de :

* mini contrat,
* preuve conversationnelle,
* sécurité plateforme.

---

# 6. MESSAGE SÉCURITÉ

Avant validation prestation :
afficher automatiquement :

“Pour votre sécurité, effectuez toujours les paiements et validations directement dans FormelPro.
Les accords effectués en dehors de l’application ne sont pas couverts par FormelPro.”

---

# 7. LOCALISATION AFRIQUE-FIRST

## CÔTE D’IVOIRE

Structure :

* Région,
* Commune,
* Quartier manuel,
* Point de repère.

---

## CAMEROUN

Structure :

* Ville,
* Quartier manuel,
* Point de repère.

IMPORTANT :
Le quartier doit toujours être libre/manuellement saisissable.

Le GPS sert uniquement :

* d’assistance,
* de proximité,
* de suggestion.

---

# 8. SERVICES RAPIDES

Services prioritaires :

* Livraison gaz,
* Plombier,
* Électricien,
* Homme à tout faire,
* Courses,
* Ménage.

Ces services doivent être :

* visibles immédiatement,
* accessibles en un clic,
* très simples d’utilisation.

---

# 9. MÉTIERS SENSIBLES

Métiers concernés :

* Femme de ménage,
* Servante de maison,
* Serveuse de bar,
* Nounou,
* Aide à domicile.

IMPORTANT :
Ces métiers nécessitent :

* validation humaine,
* enquête moralité,
* vérification renforcée.

---

## FLOW SPÉCIAL

Le client :

* laisse coordonnées,
* décrit le besoin,
* soumet une demande.

Ensuite :
FormelPro recontacte les deux parties avant mise en relation.

Aucun :

* appel direct,
* chat direct,
* WhatsApp direct.

---

# 10. DASHBOARDS

## A. DASHBOARD CLIENT

Contient :

* demandes,
* favoris,
* historiques,
* chats,
* notifications,
* prestations.

---

## B. DASHBOARD PRESTATAIRE

Contient :

* disponibilité,
* demandes reçues,
* réputation,
* revenus futurs,
* historique,
* validations.

---

## C. DASHBOARD ADMIN

Modules :

* utilisateurs,
* prestataires,
* documents,
* métiers sensibles,
* signalements,
* litiges,
* statistiques,
* localisations,
* transactions,
* modération.

---

# 11. UX / UI

Style :

* fond clair premium,
* mobile-first,
* grosses cartes visuelles,
* beaucoup d’images,
* peu de texte,
* navigation simple,
* très lisible,
* optimisé Android faible puissance.

---

# 12. PWA

FormelPro doit fonctionner :

* Android,
* Flutter Web,
* PWA installable,
* desktop web.

Le bouton d’installation doit disparaître si l’application est déjà installée.

---

# 13. AUTHENTIFICATION

Méthodes :

* email/password,
* Google OAuth,
* futur Facebook OAuth.

IMPORTANT :
Le routing Web doit être stable :

* landing,
* deep links,
* routes Vercel,
* Flutter Web SPA.

---

# 14. ARCHITECTURE IMAGES

assets/images/

* categories/
* metiers/
* onboarding/
* banners/
* avatars/
* illustrations/
* localisation/
* empty_states/

IMPORTANT :
Les images remplacent progressivement les icônes.

---

# 15. OBJECTIF FINAL

FormelPro doit devenir :

“la plateforme africaine sécurisée de services locaux et métiers informels.”

Et non simplement :
“un annuaire de techniciens”.
