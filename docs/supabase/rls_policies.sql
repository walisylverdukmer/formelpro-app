-- =============================================================================
-- FORMELPRO — POLITIQUES RLS (Row Level Security)
-- =============================================================================
-- STATUT : ✅ APPLIQUÉ le 2026-05-20
-- À exécuter dans Supabase SQL Editor après avoir créé les tables.
-- Activer RLS sur chaque table AVANT d'ajouter les politiques.
--
-- PRINCIPE GÉNÉRAL :
--   - Un utilisateur ne voit et ne modifie que ses propres données
--   - Les profils et catégories sont lisibles par tous (annuaire public)
--   - Les admins n'ont pas de rôle spécial côté DB (géré via Supabase Studio)
-- =============================================================================


-- =============================================================================
-- 1. UTILISATEURS
-- =============================================================================

ALTER TABLE public.utilisateurs ENABLE ROW LEVEL SECURITY;

-- Lecture publique des profils (nécessaire pour afficher la liste des techs)
CREATE POLICY "utilisateurs_select_public"
    ON public.utilisateurs FOR SELECT
    USING (true);

-- Un utilisateur ne peut modifier que son propre profil
CREATE POLICY "utilisateurs_update_own"
    ON public.utilisateurs FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Insertion : uniquement pour son propre id (géré par le trigger handle_new_user)
CREATE POLICY "utilisateurs_insert_own"
    ON public.utilisateurs FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Suppression interdite côté client (gérer via Supabase Admin uniquement)
-- Pas de politique DELETE → refusé par défaut


-- =============================================================================
-- 2. CATEGORIES_SERVICES
-- =============================================================================

ALTER TABLE public.categories_services ENABLE ROW LEVEL SECURITY;

-- Lecture publique (catalogue accessible à tous)
CREATE POLICY "categories_select_public"
    ON public.categories_services FOR SELECT
    USING (true);

-- Écriture réservée aux admins (via service_role uniquement, pas de policy INSERT/UPDATE/DELETE)


-- =============================================================================
-- 3. TECHNICIEN_CATEGORIES
-- =============================================================================

ALTER TABLE public.technicien_categories ENABLE ROW LEVEL SECURITY;

-- Lecture publique (permet d'afficher les spécialités d'un tech)
CREATE POLICY "tech_categories_select_public"
    ON public.technicien_categories FOR SELECT
    USING (true);

-- Un technicien gère ses propres catégories
CREATE POLICY "tech_categories_insert_own"
    ON public.technicien_categories FOR INSERT
    WITH CHECK (auth.uid() = technicien_id);

CREATE POLICY "tech_categories_delete_own"
    ON public.technicien_categories FOR DELETE
    USING (auth.uid() = technicien_id);


-- =============================================================================
-- 4. CONVERSATIONS
-- =============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Voir uniquement ses propres conversations (client ou tech)
CREATE POLICY "conversations_select_participant"
    ON public.conversations FOR SELECT
    USING (auth.uid() = client_id OR auth.uid() = tech_id);

-- Seul le client peut initier une conversation
CREATE POLICY "conversations_insert_client"
    ON public.conversations FOR INSERT
    WITH CHECK (auth.uid() = client_id);

-- Mise à jour du dernier_message (les deux participants)
CREATE POLICY "conversations_update_participant"
    ON public.conversations FOR UPDATE
    USING (auth.uid() = client_id OR auth.uid() = tech_id);


-- =============================================================================
-- 5. MESSAGES
-- =============================================================================

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Voir les messages de ses propres conversations uniquement
CREATE POLICY "messages_select_participant"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_id
              AND (c.client_id = auth.uid() OR c.tech_id = auth.uid())
        )
    );

-- Envoyer uniquement en son propre nom
CREATE POLICY "messages_insert_own"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = expediteur_id);

-- Pas de modification ni suppression de messages


-- =============================================================================
-- 6. INTERVENTIONS
-- =============================================================================

ALTER TABLE public.interventions ENABLE ROW LEVEL SECURITY;

-- Client et tech assigné voient l'intervention
CREATE POLICY "interventions_select_participant"
    ON public.interventions FOR SELECT
    USING (auth.uid() = client_id OR auth.uid() = tech_id);

-- Seul le client crée une intervention
CREATE POLICY "interventions_insert_client"
    ON public.interventions FOR INSERT
    WITH CHECK (auth.uid() = client_id);

-- Client et tech peuvent mettre à jour le statut
CREATE POLICY "interventions_update_participant"
    ON public.interventions FOR UPDATE
    USING (auth.uid() = client_id OR auth.uid() = tech_id);

-- Suppression : seul le client peut annuler (statut en_attente uniquement — gérer dans l'app)
CREATE POLICY "interventions_delete_client"
    ON public.interventions FOR DELETE
    USING (auth.uid() = client_id);


-- =============================================================================
-- 7. FAVORIS
-- =============================================================================

ALTER TABLE public.favoris ENABLE ROW LEVEL SECURITY;

-- Un client voit et gère ses propres favoris
CREATE POLICY "favoris_select_own"
    ON public.favoris FOR SELECT
    USING (auth.uid() = client_id);

CREATE POLICY "favoris_insert_own"
    ON public.favoris FOR INSERT
    WITH CHECK (auth.uid() = client_id);

CREATE POLICY "favoris_delete_own"
    ON public.favoris FOR DELETE
    USING (auth.uid() = client_id);


-- =============================================================================
-- 8. FACTURES
-- =============================================================================

ALTER TABLE public.factures ENABLE ROW LEVEL SECURITY;

-- Client et tech de l'intervention concernée voient la facture
CREATE POLICY "factures_select_participant"
    ON public.factures FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.interventions i
            WHERE i.id = intervention_id
              AND (i.client_id = auth.uid() OR i.tech_id = auth.uid())
        )
    );

-- Création facture : uniquement par le tech de l'intervention
CREATE POLICY "factures_insert_tech"
    ON public.factures FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.interventions i
            WHERE i.id = intervention_id
              AND i.tech_id = auth.uid()
        )
    );

-- Mise à jour (est_payee, url_pdf) par les deux participants
CREATE POLICY "factures_update_participant"
    ON public.factures FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.interventions i
            WHERE i.id = intervention_id
              AND (i.client_id = auth.uid() OR i.tech_id = auth.uid())
        )
    );


-- =============================================================================
-- 9. AVIS
-- =============================================================================

ALTER TABLE public.avis ENABLE ROW LEVEL SECURITY;

-- Lecture publique des avis (transparence, visible sur profil tech)
CREATE POLICY "avis_select_public"
    ON public.avis FOR SELECT
    USING (true);

-- Seul le client de l'intervention peut laisser un avis
CREATE POLICY "avis_insert_client"
    ON public.avis FOR INSERT
    WITH CHECK (
        auth.uid() = client_id
        AND EXISTS (
            SELECT 1 FROM public.interventions i
            WHERE i.id = intervention_id
              AND i.client_id = auth.uid()
              AND i.statut = 'termine'
        )
    );

-- Pas de modification ni suppression d'un avis déposé


-- =============================================================================
-- 10. NOTIFICATIONS
-- =============================================================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Un utilisateur voit uniquement ses propres notifications
CREATE POLICY "notifications_select_own"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

-- Marquer comme lu (UPDATE est_lu)
CREATE POLICY "notifications_update_own"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Insertion autorisée uniquement via service_role (triggers, Edge Functions)
-- Pas de policy INSERT côté client

-- Suppression (nettoyage) par l'utilisateur
CREATE POLICY "notifications_delete_own"
    ON public.notifications FOR DELETE
    USING (auth.uid() = user_id);


-- =============================================================================
-- 11. TRANSACTIONS (table à créer d'abord)
-- =============================================================================

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Client et tech voient leurs propres transactions
CREATE POLICY "transactions_select_participant"
    ON public.transactions FOR SELECT
    USING (auth.uid() = client_id OR auth.uid() = tech_id);

-- Le client initie le paiement
CREATE POLICY "transactions_insert_client"
    ON public.transactions FOR INSERT
    WITH CHECK (auth.uid() = client_id);

-- Le tech confirme la réception du paiement (statut → 'confirme')
CREATE POLICY "transactions_update_tech"
    ON public.transactions FOR UPDATE
    USING (auth.uid() = tech_id)
    WITH CHECK (auth.uid() = tech_id);


-- =============================================================================
-- 12. SIGNALEMENTS (table à créer d'abord)
-- =============================================================================

ALTER TABLE public.signalements ENABLE ROW LEVEL SECURITY;

-- Un utilisateur voit ses propres signalements envoyés
CREATE POLICY "signalements_select_own"
    ON public.signalements FOR SELECT
    USING (auth.uid() = signale_par);

-- Tout utilisateur connecté peut signaler
CREATE POLICY "signalements_insert_auth"
    ON public.signalements FOR INSERT
    WITH CHECK (auth.uid() = signale_par);


-- =============================================================================
-- VÉRIFICATION — requête de contrôle post-application
-- =============================================================================
-- Exécuter cette requête pour vérifier que toutes les tables ont RLS activé :
--
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;
--
-- Toutes les lignes doivent afficher rowsecurity = true
-- =============================================================================
