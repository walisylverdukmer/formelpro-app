# PLAN.md — FORMELPRO — ROADMAP GLOBAL OFFICIEL

> Référence stratégique principale du projet FormelPro.
> À lire avec :

* MODEL.md
* PROJECT_CONTEXT.md
* docs/progress/

IMPORTANT :
Ce document définit :

* l’ordre officiel de développement,
* les priorités,
* l’architecture cible,
* les dépendances,
* les règles techniques,
* les objectifs business.

---

# ÉTAT GLOBAL ACTUEL

## Niveau MVP estimé :

95% — Phases 1, 2, 3 (chat), 5 (localisation) et 6 (admin) complètes. Bloc restant : paiements Mobile Money.

## Forces actuelles

* Flutter Web fonctionnel
* Supabase realtime opérationnel
* Chat temps réel présent
* Structure marketplace déjà avancée
* Refonte UI démarrée
* Géolocalisation amorcée
* Multi-rôles existants
* PWA fonctionnelle partiellement
* Architecture produit cohérente

## Faiblesses actuelles

* Routing Flutter Web encore fragile
* Dashboard admin incomplet
* Architecture code encore trop monolithique
* Flows sensibles non totalement sécurisés
* Landing pages incomplètes
* Paiement absent
* Matching encore basique
* Dette technique élevée sur gros fichiers Dart

---

# OBJECTIF FINAL

Faire de FormelPro :

> “La plateforme africaine sécurisée de services locaux et métiers informels.”

Et non :

* un simple annuaire,
* une simple messagerie,
* une simple liste de techniciens.

---

# ARCHITECTURE GLOBALE

## 1. LANDING PAGE PUBLIQUE

Route :
/

Objectif :

* acquisition clients,
* accès rapide services,
* image de marque,
* conversion mobile.

Contenu :

* Hero section
* Homme à tout faire
* Livraison gaz
* Plombier urgent
* Ménage & maison
* Experts proches
* CTA recherche technicien
* CTA devenir prestataire
* CTA entrer dans l’application

IMPORTANT :
Cette page est totalement séparée du dashboard.

---

## 2. LANDING PRESTATAIRES

Route :
/devenir-prestataire

Objectif :
recrutement prestataires via :

* Facebook,
* WhatsApp,
* TikTok,
* QR codes,
* terrain.

Flow :

* formulaire rapide,
* création compte,
* onboarding,
* accès dashboard.

---

## 3. APPLICATION AUTHENTIFIÉE

Contient :

* dashboard client,
* dashboard prestataire,
* dashboard admin,
* chat,
* notifications,
* historique,
* prestations,
* profils,
* favoris.

---

# TYPES D’UTILISATEURS

## CLIENT

Recherche services et techniciens.

## PRESTATAIRE

Propose ses services.

IMPORTANT :
Un prestataire peut aussi être client.

Le changement de mode doit être dynamique.

## ADMIN

Supervision totale plateforme.

---

# PHASE 0 — STABILISATION CRITIQUE

> Aucun nouveau développement massif avant stabilisation.

| #   | Tâche                                     | Priorité     | Statut |
| --- | ----------------------------------------- | ------------ | ------ |
| 0.1 | Corriger routing Flutter Web              | 🔴 Critique  | ✅     |
| 0.2 | Stabiliser Vercel + vercel.json           | 🔴 Critique  | ✅     |
| 0.3 | Corriger Google OAuth redirect production | 🔴 Critique  | ✅ Uri.base.origin dynamique |
| 0.4 | Vérifier buckets Supabase Storage         | 🔴 Critique  | 🔲 Action manuelle Supabase Dashboard |
| 0.5 | Vérifier structure DB réelle              | 🔴 Critique  | 🔲 Action manuelle Supabase SQL Editor |
| 0.6 | Corriger PWA install flow                 | 🟡 Important | ✅ beforeinstallprompt + standalone OK |
| 0.7 | Vérifier logout global                    | 🟡 Important | 🔲     |
| 0.8 | flutter analyze = 0 issues                | 🔴 Critique  | ✅     |

---

# PHASE 1 — REFACTORING ARCHITECTURE

> Réduction dette technique.

| #   | Tâche                                 | Statut |
| --- | ------------------------------------- | ------ |
| 1.1 | Découper gros fichiers Dart           | ✅ Tous fichiers < 350L (accueil_client, chat_screen, details_technicien, profil_tab, location_picker, conversations_tab, accueil_technicien) |
| 1.2 | Créer services/repositories propres   | ✅ TechnicienService + pagination offset/range  |
| 1.3 | Réduire logique Supabase dans widgets | ✅ Callbacks + services séparés               |
| 1.4 | Pagination techniciens                | ✅ pageSize=20, offset, bouton "Charger plus" |
| 1.5 | Optimisation streams chat             | ✅ stream messages .limit(100)               |
| 1.6 | Widgets réutilisables UI              | ✅ 15+ widgets extraits dans lib/widgets/    |

IMPORTANT :
Maximum :
350 lignes par fichier Dart.

---

# PHASE 2 — UX CLIENT PRINCIPALE

> Flow recherche technicien.

## FLOW OFFICIEL

Landing
→ choix service
→ commune/quartier
→ techniciens disponibles
→ chat sécurisé
→ proforma
→ validation future
→ paiement futur
→ prestation
→ notation.

---

## TÂCHES

| #   | Tâche                                     | Statut |
| --- | ----------------------------------------- | ------ |
| 2.1 | Finaliser landing publique                | ✅ 4 service cards + stats + CTAs  |
| 2.2 | Ajouter experts proches scroll horizontal | ✅ ExpertsPresWidget — cartes 148px, badge statut, scroll horizontal |
| 2.3 | Finaliser flow “Rechercher un technicien” | ✅ TechnicianSelectionPage — fix categoryId vide (“Disponibles maintenant”) |
| 2.4 | États vides premium                       | ✅ TechnicienEmptyState contextuel (filtres, catégorie, zone) |
| 2.5 | Filtres métiers/localisation              | ✅ Section Commune/Zone + Type mission (Ponctuel/Journalier/Résidentiel) + badge numéroté filtres actifs |
| 2.6 | Fiches techniciens premium                | ✅ Favori cœur, statut 3e stat, bannière premium, avis clients |

---

# PHASE 3 — CHAT & SÉCURITÉ

> Cœur système FormelPro.

## OBJECTIF

Le chat devient :

* espace discussion,
* espace devis,
* espace sécurité,
* espace proforma,
* espace validation.

---

## TÂCHES

| #   | Tâche                              | Statut |
| --- | ---------------------------------- | ------ |
| 3.1 | Blocage appel direct initial       | ✅ phone_locked icon + snackbar explication |
| 3.2 | Déblocage appel après validation   | ✅ débloqué après 3 messages ou proforma    |
| 3.3 | Messages sécurité automatiques     | ✅ ChatSecurityBanner dismissible en haut   |
| 3.4 | Cartes proforma conversationnelles | ✅ ProformaCard + ProformaSheet + confirmation |
| 3.5 | Messages système élégants          | ✅ SystemMessageBubble centré vert/rouge    |
| 3.6 | Photos dans chat                   | 🔲 (Phase suivante — Storage upload)       |
| 3.7 | Messages lus/non lus               | 🔲 (nécessite migration DB est_lu)         |
| 3.8 | Typing indicator                   | ✅ Supabase Realtime broadcast + AnimatedSwitcher |

---

# PHASE 4 — SERVICES SENSIBLES

> Validation humaine obligatoire.

## SERVICES CONCERNÉS

* ménagère,
* servante,
* serveuse,
* nounou,
* aide à domicile.

IMPORTANT :
Aucun contact direct.

---

## FLOW

Client
→ demande
→ coordonnées
→ besoin
→ validation humaine
→ enquête moralité
→ mise en relation.

---

## TÂCHES

| #   | Tâche                           | Statut |
| --- | ------------------------------- | ------ |
| 4.1 | Flow spécial services sensibles | ✅ DemandServiceDomestiquePage (3 étapes) |
| 4.2 | Désactiver contact direct       | ✅ _isServiceSensible dans details_technicien |
| 4.3 | Workflow validation admin       | ✅ AdminDemandesDomestiquesPage — prendre en charge, enquête, affecter, annuler |
| 4.4 | Historique enquêtes             | ✅ onglets statuts dans AdminDemandesDomestiquesPage |
| 4.5 | Badge service sécurisé          | 🔲 (badge sur fiche tech si service sensible) |

---

# PHASE 5 — LOCALISATION AFRIQUE-FIRST

## CÔTE D’IVOIRE

* Région
* Commune
* Quartier manuel
* Repère

## CAMEROUN

* Ville
* Quartier manuel
* Repère

IMPORTANT :
Le quartier reste libre.

---

## TÂCHES

| #   | Tâche                 | Statut |
| --- | --------------------- | ------ |
| 5.1 | Modale map finale     | ✅ LocationPickerWidget — flutter_map OSM + mode map/manuel |
| 5.2 | GPS + géolocalisation | ✅ geolocator + Geolocator.getCurrentPosition() |
| 5.3 | Distance techniciens  | ✅ DistanceUtils.haversineKm — badge distance sur CarteTechnicien + ExpertCard |
| 5.4 | Communes prédéfinies  | ✅ LocationManualForm — regionsCIV (10 régions) + villesCMR (15 villes) |
| 5.5 | Reverse geocoding     | ✅ Nominatim API reverse geocode dans LocationPickerWidget |
| 5.6 | Matching proximité    | ✅ Tri client-side par distance dans ExpertsPresWidget + TechnicianSelectionPage |

---

# PHASE 5.7 — HOMME À TOUT FAIRE

> Profils multi-compétences.

IMPORTANT :
“Homme à tout faire” n’est pas un métier unique.
C’est un profil polyvalent.

---

## OBJECTIF

Créer :

* système multi-compétences,
* matching intelligent,
* badges compétences.

---

## EXEMPLES COMPÉTENCES

* petite plomberie
* petite électricité
* peinture
* bricolage
* montage meubles
* manutention
* jardinage
* nettoyage
* dépannage simple

---

## TÂCHES

| #     | Tâche                                 | Statut |
| ----- | ------------------------------------- | ------ |
| 5.7.1 | Catégorie spéciale homme à tout faire | ✅ SQL §17 — INSERT categories_services 'homme-a-tout-faire' |
| 5.7.2 | Sélection multi-compétences           | ✅ competences_editor_sheet.dart + profil_tab "Mes Compétences" |
| 5.7.3 | Badges compétences                    | ✅ carte_technicien.dart — chips accentColor max 3 |
| 5.7.4 | Filtres compétences                   | ✅ filtres_sheet.dart section "Homme à tout faire" multi-select |
| 5.7.5 | Matching intelligent                  | ✅ TechnicienService — filtre ov (overlap) sur TEXT[] |
| 5.7.6 | Ajout homepage publique               | ✅ catégorie DB-driven → chips accueil_client automatique |

---

# PHASE 6 — DASHBOARD ADMIN

> Centre opérations FormelPro.

## MODULES

* utilisateurs,
* prestataires,
* documents,
* litiges,
* signalements,
* services sensibles,
* transactions,
* analytics,
* localisations.

---

## TÂCHES

| #   | Tâche                | Statut |
| --- | -------------------- | ------ |
| 6.1 | KPIs admin           | ✅ AccueilAdmin — users, techniciens, docs, signalements |
| 6.2 | Gestion prestataires | ✅ AdminUsersPage — suspension/réactivation               |
| 6.3 | Validation documents | ✅ AdminDocumentsPage — approuver/rejeter + signed URLs   |
| 6.4 | Gestion litiges      | ✅ AdminSignalementsPage — signalements en attente        |
| 6.5 | Support utilisateurs | ✅ câblé via is_admin → AccueilAdmin                     |
| 6.6 | Analytics business   | 🔲 Phase future                                          |
| 6.7 | Heatmap activité     | 🔲 Phase future                                          |

---

# PHASE 7 — PAIEMENTS MOBILE MONEY

## OBJECTIF

Paiement sécurisé intégré FormelPro.

---

## ÉTAPES

| #   | Tâche                   | Statut |
| --- | ----------------------- | ------ |
| 7.1 | Paiement manuel assisté | ✅ PaiementPage — sélection opérateur (CIV/CMR), instructions, saisie référence, insert transactions |
| 7.2 | Table transactions      | ✅ SQL §11 migrations.sql + RLS rls_policies.sql (select/insert client + update tech) |
| 7.3 | Edge Functions paiement | 🔲     |
| 7.4 | Orange Money API        | 🔲     |
| 7.5 | MTN MoMo API            | 🔲     |
| 7.6 | Historique transactions | 🔲     |
| 7.7 | Escrow FormelPro        | 🔲     |

IMPORTANT :
Les démarches marchandes doivent commencer tôt.

---

# PHASE 8 — PERFORMANCE & PWA

| #   | Tâche                     | Statut |
| --- | ------------------------- | ------ |
| 8.1 | Renderer HTML Flutter Web | 🔲     |
| 8.2 | Cache images              | 🔲     |
| 8.3 | Lazy loading              | 🔲     |
| 8.4 | Compression WebP          | 🔲     |
| 8.5 | Cache offline minimal     | 🔲     |
| 8.6 | Splash screen premium     | 🔲     |
| 8.7 | Onboarding slides         | 🔲     |

---

# PHASE 9 — CROISSANCE & PREMIUM

| #   | Tâche                | Statut |
| --- | -------------------- | ------ |
| 9.1 | Badge premium        | 🔲     |
| 9.2 | Portfolio technicien | 🔲     |
| 9.3 | Galerie réalisations | 🔲     |
| 9.4 | Recommandations IA   | 🔲     |
| 9.5 | Carte experts        | 🔲     |
| 9.6 | Abonnement premium   | 🔲     |

---

# PHASE BUSINESS — CROISSANCE TERRAIN

| Action                      | Impact                   |
| --------------------------- | ------------------------ |
| recrutement terrain         | acquisition prestataires |
| groupes WhatsApp métiers    | croissance rapide        |
| flyers QR codes             | visibilité               |
| partenariats quincailleries | acquisition locale       |
| partenariats gaz            | services rapides         |

---

# RISQUES PRINCIPAUX

| Risque                     | Impact    |
| -------------------------- | --------- |
| dette technique Dart       | élevé     |
| routing Flutter Web        | critique  |
| Mobile Money délais        | critique  |
| services sensibles         | juridique |
| performances réseau faible | élevé     |
| scaling realtime           | moyen     |

---

# PRIORITÉS IMMÉDIATES

1. ✅ Stabiliser routing + auth
2. ✅ Landing publique stable
3. ✅ Devenir prestataire stable
4. ✅ Flow recherche technicien (pagination + sélection catégorie)
5. ✅ Filtres avancés (2.5) + Fiches premium (2.6)
6. ✅ Chat sécurisé — Phase 3 (blocage appel, proforma, typing, messages système)
7. ✅ Dashboard admin minimal — Phase 6 (KPIs + 3 modules)
8. ✅ Localisation stable — Phase 5 (map, GPS, communes, reverse geocoding, distance, matching)
9. 🔲 Recrutement terrain

---

# RÈGLES PROJET

1. Lire MODEL.md + PLAN.md à chaque session.
2. flutter analyze = 0 issues.
3. Maximum 350 lignes/fichier Dart.
4. Toujours mettre à jour PROJECT_CONTEXT.md.
5. Ne jamais casser Flutter Web.
6. Mobile-first obligatoire.
7. Préserver Supabase realtime.
8. Préserver architecture Afrique-first.

---

# OBJECTIF FINAL BUSINESS

FormelPro doit devenir :

* une plateforme sécurisée,
* une référence africaine,
* un assistant humain local,
* une marketplace métiers/services,
* une solution adaptée aux réalités informelles africaines.

IMPORTANT mise à jour des .md importants après chaque étape