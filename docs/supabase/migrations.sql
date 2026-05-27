-- =============================================================================
-- FORMELPRO — SCHÉMA SUPABASE RÉEL (synchronisé le 2026-05-20)
-- =============================================================================
-- Schéma reconstruit depuis les DDL exportés de Supabase.
--
-- LÉGENDE :
--   [EXISTANT]   → Table déjà présente en production
--   [À CRÉER]    → Table pas encore créée, à exécuter prochainement
--
-- ORDRE D'EXÉCUTION si reconstruction complète :
--   1. categories_services
--   2. utilisateurs
--   3. technicien_categories
--   4. conversations
--   5. messages
--   6. interventions
--   7. favoris
--   8. factures
--   9. avis
--   10. notifications
--   11. transactions (à créer)
--   12. signalements  (à créer)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- =============================================================================
-- 1. CATEGORIES_SERVICES [EXISTANT]
-- =============================================================================

CREATE TABLE public.categories_services (
    id                  UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    nom                 TEXT        NOT NULL,
    slug                TEXT        NOT NULL,
    description         TEXT        NULL,
    ordre_affichage     INTEGER     NULL DEFAULT 0,
    est_valide          BOOLEAN     NULL DEFAULT true,
    ajoute_par          UUID        NULL,
    date_creation       TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),
    groupe_parent       TEXT        NULL,

    CONSTRAINT categories_services_pkey    PRIMARY KEY (id),
    CONSTRAINT categories_services_nom_key  UNIQUE (nom),
    CONSTRAINT categories_services_slug_key UNIQUE (slug),
    CONSTRAINT categories_services_ajoute_par_fkey
        FOREIGN KEY (ajoute_par) REFERENCES utilisateurs(id)
);

CREATE INDEX IF NOT EXISTS idx_cat_valide
    ON public.categories_services USING btree (est_valide);


-- =============================================================================
-- 2. UTILISATEURS [EXISTANT]
-- =============================================================================
-- Profils enrichis. Vérifié en Supabase le 2026-05-20.
-- Pays : 'CIV' ou 'CMR' (attention — pas 'CI'/'CM')
-- Rôles : 'client' ou 'technicien' (pas 'admin' dans la contrainte actuelle)

CREATE TABLE public.utilisateurs (
    id                          UUID        NOT NULL,
    role                        TEXT        NOT NULL,
    pays                        TEXT        NOT NULL,
    email                       TEXT        NULL,
    prenom                      TEXT        NULL,
    nom_complet                 TEXT        NULL,
    age                         INTEGER     NULL,
    photo_url                   TEXT        NULL,        -- ancienne colonne (remplacée par photo_profil_url ?)
    photo_profil_url            TEXT        NULL,        -- colonne principale photo
    ville                       TEXT        NULL,
    commune                     TEXT        NULL,
    quartier                    TEXT        NULL,        -- non présent dans le DDL fourni — à vérifier
    savoir_faire                TEXT        NULL,
    specialites                 TEXT        NULL,
    metier_personnalise         TEXT        NULL,
    categorie_id                UUID        NULL,
    telephone                   TEXT        NULL,
    adresse_complete            TEXT        NULL,
    adresse_precise             TEXT        NULL,
    latitude                    DOUBLE PRECISION NULL,
    longitude                   DOUBLE PRECISION NULL,
    est_en_ligne                BOOLEAN     NULL DEFAULT false,
    disponible                  BOOLEAN     NULL DEFAULT true,  -- à vérifier si présent
    a_complete_profil           BOOLEAN     NULL DEFAULT false,
    is_premium                  BOOLEAN     NULL DEFAULT false,
    premium_until               TIMESTAMPTZ NULL,
    certificat_confiance        BOOLEAN     NULL DEFAULT false,
    -- Vérification identité (inline, pas de table séparée)
    type_document               TEXT        NULL,
    document_identite_url       TEXT        NULL,
    is_identite_verifiee        BOOLEAN     NULL DEFAULT false,
    -- Scores & stats
    note_moyenne                NUMERIC(2,1) NULL DEFAULT 0.0,
    score_global                NUMERIC(3,2) NULL DEFAULT 5.00,
    total_transactions          INTEGER     NULL DEFAULT 0,
    points_infraction           INTEGER     NULL DEFAULT 0,
    -- Migration de rôle
    demande_migration_active    BOOLEAN     NULL,
    date_migration              TIMESTAMPTZ NULL,
    -- Dates
    date_inscription            TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT utilisateurs_pkey PRIMARY KEY (id),
    CONSTRAINT utilisateurs_categorie_id_fkey
        FOREIGN KEY (categorie_id) REFERENCES categories_services(id),
    CONSTRAINT utilisateurs_pays_check
        CHECK (pays = ANY (ARRAY['CIV'::text, 'CMR'::text])),
    CONSTRAINT utilisateurs_role_check
        CHECK (role = ANY (ARRAY['client'::text, 'technicien'::text]))
);


-- =============================================================================
-- 3. TECHNICIEN_CATEGORIES [EXISTANT]
-- =============================================================================
-- Table de jointure many-to-many : un technicien peut avoir plusieurs catégories

CREATE TABLE public.technicien_categories (
    technicien_id   UUID NOT NULL,
    categorie_id    UUID NOT NULL,

    CONSTRAINT technicien_categories_pkey PRIMARY KEY (technicien_id, categorie_id),
    CONSTRAINT technicien_categories_technicien_id_fkey
        FOREIGN KEY (technicien_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT technicien_categories_categorie_id_fkey
        FOREIGN KEY (categorie_id) REFERENCES categories_services(id) ON DELETE CASCADE
);


-- =============================================================================
-- 4. CONVERSATIONS [EXISTANT]
-- =============================================================================

CREATE TABLE public.conversations (
    id              UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    client_id       UUID        NULL,
    tech_id         UUID        NULL,
    dernier_message TEXT        NULL,
    mis_a_jour_le   TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT conversations_pkey PRIMARY KEY (id),
    CONSTRAINT conversations_client_id_tech_id_key UNIQUE (client_id, tech_id),
    CONSTRAINT conversations_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT conversations_tech_id_fkey
        FOREIGN KEY (tech_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);


-- =============================================================================
-- 5. MESSAGES [EXISTANT]
-- =============================================================================
-- Note : colonne date = 'cree_le' (pas 'created_at')

CREATE TABLE public.messages (
    id                          UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    conversation_id             UUID        NULL,
    expediteur_id               UUID        NULL,
    contenu                     TEXT        NOT NULL,
    est_proposition_intervention BOOLEAN    NULL DEFAULT false,
    cree_le                     TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT messages_pkey PRIMARY KEY (id),
    CONSTRAINT messages_conversation_id_fkey
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    CONSTRAINT messages_expediteur_id_fkey
        FOREIGN KEY (expediteur_id) REFERENCES utilisateurs(id)
);

-- Realtime messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;


-- =============================================================================
-- 6. INTERVENTIONS [EXISTANT]
-- =============================================================================
-- Attention : tech_id est NOT NULL ici (la sélection du tech est obligatoire)
-- Montant : colonne = 'montant_final' (INTEGER), pas 'budget'
-- Titre : colonne = 'titre_service', pas 'categorie_nom'

CREATE TABLE public.interventions (
    id                  UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    client_id           UUID        NOT NULL,
    tech_id             UUID        NOT NULL,       -- obligatoire (tech choisi au départ)
    titre_service       TEXT        NOT NULL,
    description         TEXT        NOT NULL,
    statut              TEXT        NULL DEFAULT 'en_attente',
    ville               TEXT        NULL,
    commune             TEXT        NULL,
    montant_final       INTEGER     NULL DEFAULT 0, -- en FCFA
    date_prevue         TIMESTAMPTZ NOT NULL,
    date_creation       TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),
    date_intervention   TIMESTAMPTZ NULL,

    CONSTRAINT interventions_pkey PRIMARY KEY (id),
    CONSTRAINT interventions_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT interventions_tech_id_fkey
        FOREIGN KEY (tech_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT interventions_statut_check
        CHECK (statut = ANY (ARRAY[
            'en_attente', 'accepte', 'en_cours', 'termine', 'annule'
        ]))
);

CREATE INDEX IF NOT EXISTS idx_inter_client  ON public.interventions USING btree (client_id);
CREATE INDEX IF NOT EXISTS idx_inter_tech    ON public.interventions USING btree (tech_id);
CREATE INDEX IF NOT EXISTS idx_inter_statut  ON public.interventions USING btree (statut);


-- =============================================================================
-- 7. FAVORIS [EXISTANT]
-- =============================================================================
-- Client peut sauvegarder des techniciens en favoris

CREATE TABLE public.favoris (
    client_id   UUID        NOT NULL,
    tech_id     UUID        NOT NULL,
    date_ajout  TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT favoris_pkey PRIMARY KEY (client_id, tech_id),
    CONSTRAINT favoris_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT favoris_tech_id_fkey
        FOREIGN KEY (tech_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);


-- =============================================================================
-- 8. FACTURES [EXISTANT]
-- =============================================================================

CREATE TABLE public.factures (
    id              UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    intervention_id UUID        NOT NULL,
    montant         INTEGER     NOT NULL,    -- en FCFA
    url_pdf         TEXT        NULL,
    est_payee       BOOLEAN     NULL DEFAULT false,
    date_emission   TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT factures_pkey PRIMARY KEY (id),
    CONSTRAINT factures_intervention_id_fkey
        FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON DELETE CASCADE
);


-- =============================================================================
-- 9. AVIS [EXISTANT]
-- =============================================================================
-- Le trigger trigger_update_reputation appelle calculer_reputation_technicien()
-- Note : pas de contrainte UNIQUE sur intervention_id (plusieurs avis possibles)

CREATE TABLE public.avis (
    id              UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    intervention_id UUID        NOT NULL,
    client_id       UUID        NOT NULL,
    tech_id         UUID        NOT NULL,
    note            INTEGER     NULL,
    commentaire     TEXT        NULL,
    date_avis       TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT avis_pkey PRIMARY KEY (id),
    CONSTRAINT avis_intervention_id_fkey
        FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON DELETE CASCADE,
    CONSTRAINT avis_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT avis_tech_id_fkey
        FOREIGN KEY (tech_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    CONSTRAINT avis_note_check CHECK (note >= 1 AND note <= 5)
);

CREATE INDEX IF NOT EXISTS idx_avis_tech ON public.avis USING btree (tech_id);

-- Trigger existant — appelle la fonction calculer_reputation_technicien()
-- (fonction à créer si elle n'existe pas encore — voir bloc FONCTIONS ci-dessous)
DROP TRIGGER IF EXISTS trigger_update_reputation ON public.avis;
CREATE TRIGGER trigger_update_reputation
    AFTER INSERT OR UPDATE ON avis
    FOR EACH ROW EXECUTE FUNCTION calculer_reputation_technicien();


-- =============================================================================
-- 10. NOTIFICATIONS [EXISTANT]
-- =============================================================================
-- Trigger existant : envoie push via Edge Function après chaque INSERT

CREATE TABLE public.notifications (
    id                  UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id             UUID        NOT NULL,
    titre               TEXT        NOT NULL,
    message             TEXT        NOT NULL,
    est_lu              BOOLEAN     NOT NULL DEFAULT false,
    type                TEXT        NULL,
    date_notification   TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_notif_user ON public.notifications USING btree (user_id);

-- Trigger existant : déclenche l'Edge Function send-push-notification
-- (déjà en place en production — NE PAS recréer si la table existe déjà)
DROP TRIGGER IF EXISTS "send-push-on-insert" ON public.notifications;
CREATE TRIGGER "send-push-on-insert"
    AFTER INSERT ON notifications
    FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(
        'https://elsweibfytmvaeasekaf.supabase.co/functions/v1/send-push-notification',
        'POST',
        '{"Content-type":"application/json","Authorization":"Bearer <SERVICE_ROLE_KEY>"}',
        '{}',
        '5000'
    );

-- Realtime notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;


-- =============================================================================
-- 11. TRANSACTIONS [À CRÉER]
-- =============================================================================
-- Enregistrement des paiements Mobile Money
-- Lié à factures (une facture peut avoir une transaction de paiement)

CREATE TABLE public.transactions (
    id                  UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    intervention_id     UUID        NOT NULL,
    facture_id          UUID        NULL,   -- référence à factures si émise
    client_id           UUID        NOT NULL,
    tech_id             UUID        NOT NULL,
    montant             INTEGER     NOT NULL,        -- en FCFA
    operateur           TEXT        NOT NULL
                            CHECK (operateur IN ('orange_money', 'mtn_momo', 'wave', 'autre')),
    statut              TEXT        NOT NULL DEFAULT 'en_attente'
                            CHECK (statut IN ('en_attente', 'confirme', 'echoue', 'rembourse')),
    reference_externe   TEXT        NULL,           -- référence retournée par l'opérateur Mobile Money
    pays                TEXT        NULL
                            CHECK (pays IN ('CIV', 'CMR')),
    created_at          TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),
    confirmed_at        TIMESTAMPTZ NULL,

    CONSTRAINT transactions_pkey PRIMARY KEY (id),
    CONSTRAINT transactions_intervention_id_fkey
        FOREIGN KEY (intervention_id) REFERENCES interventions(id) ON DELETE CASCADE,
    CONSTRAINT transactions_facture_id_fkey
        FOREIGN KEY (facture_id) REFERENCES factures(id) ON DELETE SET NULL,
    CONSTRAINT transactions_client_id_fkey
        FOREIGN KEY (client_id) REFERENCES utilisateurs(id),
    CONSTRAINT transactions_tech_id_fkey
        FOREIGN KEY (tech_id) REFERENCES utilisateurs(id)
);

CREATE INDEX IF NOT EXISTS idx_transactions_intervention ON public.transactions(intervention_id);
CREATE INDEX IF NOT EXISTS idx_transactions_statut ON public.transactions(statut);


-- =============================================================================
-- 12. SIGNALEMENTS [À CRÉER]
-- =============================================================================

CREATE TABLE public.signalements (
    id                      UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    signale_par             UUID        NOT NULL,
    utilisateur_signale     UUID        NOT NULL,
    raison                  TEXT        NOT NULL,
    statut                  TEXT        NOT NULL DEFAULT 'en_attente'
                                CHECK (statut IN ('en_attente', 'traite', 'ferme')),
    created_at              TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT signalements_pkey PRIMARY KEY (id),
    CONSTRAINT signalements_signale_par_fkey
        FOREIGN KEY (signale_par) REFERENCES utilisateurs(id),
    CONSTRAINT signalements_signale_fkey
        FOREIGN KEY (utilisateur_signale) REFERENCES utilisateurs(id)
);


-- =============================================================================
-- FONCTIONS POSTGRESQL
-- =============================================================================

-- Recalcule note_moyenne et score_global du technicien après chaque avis
-- Appelée par trigger_update_reputation sur la table avis
CREATE OR REPLACE FUNCTION public.calculer_reputation_technicien()
RETURNS TRIGGER AS $$
DECLARE
    v_tech_id       UUID;
    v_note_moy      NUMERIC(2,1);
    v_nb_avis       INTEGER;
    v_score         NUMERIC(3,2);
BEGIN
    v_tech_id := NEW.tech_id;

    SELECT
        ROUND(AVG(note)::NUMERIC, 1),
        COUNT(*)
    INTO v_note_moy, v_nb_avis
    FROM public.avis
    WHERE tech_id = v_tech_id;

    -- Score global : pondération note (60%) + volume missions (40%, plafonné à 100)
    v_score := ROUND(
        (COALESCE(v_note_moy, 0) * 0.6 + LEAST(v_nb_avis, 100)::FLOAT / 100 * 0.4 * 5)::NUMERIC
    , 2);

    UPDATE public.utilisateurs
    SET
        note_moyenne = COALESCE(v_note_moy, 0),
        score_global = v_score
    WHERE id = v_tech_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Mise à jour automatique total_transactions après paiement confirmé
CREATE OR REPLACE FUNCTION public.increment_total_transactions()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.statut = 'confirme' AND (OLD.statut IS NULL OR OLD.statut != 'confirme') THEN
        UPDATE public.utilisateurs
        SET total_transactions = total_transactions + 1
        WHERE id = NEW.tech_id;

        -- Marquer la facture liée comme payée
        IF NEW.facture_id IS NOT NULL THEN
            UPDATE public.factures
            SET est_payee = true
            WHERE id = NEW.facture_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_increment_transactions ON public.transactions;
CREATE TRIGGER trigger_increment_transactions
    AFTER UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.increment_total_transactions();


-- =============================================================================
-- 13. DOCUMENTS_VERIFICATION [À CRÉER] — Onboarding technicien
-- =============================================================================
-- Exécuter dans Supabase SQL Editor pour activer la page de vérification docs
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.documents_verification (
    id              UUID        NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES public.utilisateurs(id) ON DELETE CASCADE,
    type_document   TEXT        NOT NULL CHECK (type_document IN ('cni', 'passeport', 'certificat', 'diplome')),
    document_url    TEXT        NOT NULL,
    statut          TEXT        NOT NULL DEFAULT 'en_attente'
                                CHECK (statut IN ('en_attente', 'approuve', 'rejete', 'expire')),
    motif_rejet     TEXT        NULL,
    validated_by    UUID        NULL REFERENCES public.utilisateurs(id),
    validated_at    TIMESTAMPTZ NULL,
    created_at      TIMESTAMPTZ NULL DEFAULT timezone('utc', now()),

    CONSTRAINT documents_verification_pkey PRIMARY KEY (id)
);

ALTER TABLE public.documents_verification ENABLE ROW LEVEL SECURITY;

-- Technicien : lire et créer ses propres documents
CREATE POLICY "tech_own_docs_select" ON public.documents_verification
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "tech_own_docs_insert" ON public.documents_verification
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_docs_verif_user ON public.documents_verification(user_id);
CREATE INDEX IF NOT EXISTS idx_docs_verif_statut ON public.documents_verification(statut);

-- =============================================================================
-- 14. ESPACE ADMIN — Validation documents techniciens [À CRÉER]
-- =============================================================================
-- Exécuter dans Supabase SQL Editor APRÈS la migration §13
-- =============================================================================

-- 14.1 Colonne is_admin dans utilisateurs
ALTER TABLE public.utilisateurs ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- 14.2 Fonction SECURITY DEFINER pour vérifier le statut admin sans récursion RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.utilisateurs WHERE id = auth.uid()),
    false
  );
$$;

-- 14.3 Politiques admin sur documents_verification
--      (complètent les politiques tech existantes — Supabase fait un OR entre elles)
CREATE POLICY "admin_docs_select" ON public.documents_verification
    FOR SELECT USING (public.is_admin());

CREATE POLICY "admin_docs_update" ON public.documents_verification
    FOR UPDATE USING (public.is_admin());

-- 14.4 Trigger : approuver un doc CNI/passeport → is_identite_verifiee = true
--      SECURITY DEFINER bypass RLS pour la mise à jour cross-utilisateur
CREATE OR REPLACE FUNCTION public.sync_identite_verifiee()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.statut = 'approuve' AND NEW.type_document IN ('cni', 'passeport') THEN
    UPDATE public.utilisateurs
    SET is_identite_verifiee = true
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trigger_sync_identite
    AFTER UPDATE OF statut ON public.documents_verification
    FOR EACH ROW EXECUTE FUNCTION public.sync_identite_verifiee();

-- =============================================================================
-- 15. TRIGGERS NOTIFICATIONS DOCUMENTS [À EXÉCUTER]
-- =============================================================================
-- Remplace l'approche Flutter-side (bloquée par RLS INSERT notifications).
-- SECURITY DEFINER → bypass RLS → peut écrire dans notifications.
-- Le trigger FCM send-push-on-insert se déclenche automatiquement après chaque INSERT.
-- =============================================================================

-- 15.1 Notifier les admins quand un tech soumet un document
CREATE OR REPLACE FUNCTION public.notifier_admins_nouveau_doc()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_label TEXT;
  v_tech_nom TEXT;
BEGIN
  v_label := CASE NEW.type_document
    WHEN 'cni'        THEN 'une CNI'
    WHEN 'passeport'  THEN 'un passeport'
    WHEN 'certificat' THEN 'un certificat'
    WHEN 'diplome'    THEN 'un diplôme'
    ELSE 'un document'
  END;

  SELECT nom_complet INTO v_tech_nom
  FROM public.utilisateurs WHERE id = NEW.user_id;

  INSERT INTO public.notifications (user_id, titre, message, type)
  SELECT
    id,
    'Nouveau document à valider',
    COALESCE(v_tech_nom, 'Un technicien') || ' a soumis ' || v_label || ' — en attente de validation.',
    'doc_soumis'
  FROM public.utilisateurs
  WHERE is_admin = true;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notifier_admins_nouveau_doc ON public.documents_verification;
CREATE TRIGGER trigger_notifier_admins_nouveau_doc
  AFTER INSERT ON public.documents_verification
  FOR EACH ROW EXECUTE FUNCTION public.notifier_admins_nouveau_doc();


-- 15.2 Notifier le technicien quand son document est approuvé ou refusé
CREATE OR REPLACE FUNCTION public.notifier_tech_statut_doc()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_label TEXT;
BEGIN
  IF NEW.statut = OLD.statut THEN RETURN NEW; END IF;

  v_label := CASE NEW.type_document
    WHEN 'cni'        THEN 'CNI'
    WHEN 'passeport'  THEN 'Passeport'
    WHEN 'certificat' THEN 'Certificat'
    WHEN 'diplome'    THEN 'Diplôme'
    ELSE 'Document'
  END;

  IF NEW.statut = 'approuve' THEN
    INSERT INTO public.notifications (user_id, titre, message, type)
    VALUES (
      NEW.user_id,
      'Document approuvé ✓',
      'Votre ' || v_label || ' a été validé. Votre badge Vérifié est maintenant actif.',
      'doc_approuve'
    );
  ELSIF NEW.statut = 'rejete' THEN
    INSERT INTO public.notifications (user_id, titre, message, type)
    VALUES (
      NEW.user_id,
      'Document refusé',
      'Votre ' || v_label || ' a été refusé.' ||
        CASE WHEN NEW.motif_rejet IS NOT NULL
          THEN ' Motif : ' || NEW.motif_rejet
          ELSE ''
        END,
      'doc_rejete'
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notifier_tech_statut_doc ON public.documents_verification;
CREATE TRIGGER trigger_notifier_tech_statut_doc
  AFTER UPDATE OF statut ON public.documents_verification
  FOR EACH ROW EXECUTE FUNCTION public.notifier_tech_statut_doc();


-- =============================================================================
-- NOTES IMPORTANTES
-- =============================================================================
--
-- 1. COLONNES À VÉRIFIER DANS utilisateurs
--    - 'quarier' : présent dans le code Flutter mais pas dans le DDL fourni — vérifier
--    - 'disponible' : utilisé dans le code Flutter (toggle) — vérifier si elle existe
--    - 'metier_principal' : présent dans le code Flutter — remplacé par 'metier_personnalise' ?
--    - 'photo_url' vs 'photo_profil_url' : deux colonnes, laquelle est utilisée ?
--
-- 2. PAYS : valeurs = 'CIV' et 'CMR' (et non 'CI'/'CM' — corriger dans le code Flutter si besoin)
--
-- 3. INTERVENTIONS : tech_id est NOT NULL → un tech doit être sélectionné à la création
--    Cela implique que le flux client doit sélectionner un tech AVANT de créer l'intervention.
--
-- 4. AVIS : pas de UNIQUE sur intervention_id → plusieurs avis possibles par intervention
--    À surveiller : risque de doublon si l'UI ne protège pas.
--
-- 5. SÉCURITÉ NOTIFICATION TRIGGER :
--    Le trigger send-push-on-insert contient la service_role_key en clair dans Supabase.
--    C'est acceptable côté Supabase (trigger interne) mais ne jamais exposer cette clé
--    dans le code Flutter ou les logs publics.
--
-- =============================================================================


-- =============================================================================
-- §16: Modération admin
-- À exécuter dans Supabase SQL Editor (une seule fois)
-- =============================================================================

-- Colonne suspension utilisateur
ALTER TABLE public.utilisateurs
  ADD COLUMN IF NOT EXISTS is_suspendu BOOLEAN NOT NULL DEFAULT false;

-- Permettre à l'admin de mettre à jour n'importe quel utilisateur (suspension, etc.)
CREATE POLICY "admin_update_users"
  ON public.utilisateurs FOR UPDATE
  USING (public.is_admin());

-- Permettre à l'admin de voir tous les signalements
CREATE POLICY "admin_signalements_select"
  ON public.signalements FOR SELECT
  USING (public.is_admin());

-- Permettre à l'admin de mettre à jour les signalements (statut : traite, ferme)
CREATE POLICY "admin_signalements_update"
  ON public.signalements FOR UPDATE
  USING (public.is_admin());


-- =============================================================================
-- §17: Présence temps réel
-- À exécuter dans Supabase SQL Editor (une seule fois)
-- Online = last_seen < 2 minutes (cutoff dans stats_zone)
-- Heartbeat Flutter : 60s (marge 60s avant expiration)
-- Flutter Web : paused ne déclenche PAS _ping(false) — expiration naturelle
-- =============================================================================

-- Colonne horodatage dernière activité (last_seen)
ALTER TABLE public.utilisateurs
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;

-- Index partiel : accélère les comptages en ligne par zone
CREATE INDEX IF NOT EXISTS idx_utilisateurs_online_zone
  ON public.utilisateurs(pays, commune, last_seen)
  WHERE est_en_ligne = true;

-- Fonction RPC : stats de zone (renvoie des agrégats, jamais de données personnelles)
-- SECURITY DEFINER : contourne RLS pour les COUNT — seuls des entiers sont exposés
CREATE OR REPLACE FUNCTION public.stats_zone(
  p_pays    TEXT,
  p_commune TEXT DEFAULT ''
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cutoff         TIMESTAMPTZ := now() - INTERVAL '2 minutes';
  v_commune_online INTEGER     := 0;
  v_pays_online    INTEGER     := 0;
  v_pays_total     INTEGER     := 0;
BEGIN
  -- Techniciens en ligne dans la commune (si renseignée)
  IF p_commune IS NOT NULL AND p_commune <> '' THEN
    SELECT COUNT(*) INTO v_commune_online
    FROM public.utilisateurs
    WHERE role = 'technicien'
      AND pays = p_pays
      AND commune = p_commune
      AND est_en_ligne = true
      AND last_seen > v_cutoff;
  END IF;

  -- Techniciens en ligne dans le pays
  SELECT COUNT(*) INTO v_pays_online
  FROM public.utilisateurs
  WHERE role = 'technicien'
    AND pays = p_pays
    AND est_en_ligne = true
    AND last_seen > v_cutoff;

  -- Total techniciens disponibles dans le pays
  SELECT COUNT(*) INTO v_pays_total
  FROM public.utilisateurs
  WHERE role = 'technicien'
    AND pays = p_pays
    AND disponible = true;

  RETURN json_build_object(
    'commune_online', v_commune_online,
    'pays_online',    v_pays_online,
    'pays_total',     v_pays_total
  );
END;
$$;


-- =============================================================================
-- §18: Architecture Premium
-- À exécuter dans Supabase SQL Editor (une seule fois)
-- =============================================================================

-- Date de début d'abonnement premium
ALTER TABLE public.utilisateurs
  ADD COLUMN IF NOT EXISTS premium_since TIMESTAMPTZ;

-- Niveau premium : 1 = Premium, 2 = Pro (extensible)
ALTER TABLE public.utilisateurs
  ADD COLUMN IF NOT EXISTS premium_level SMALLINT NOT NULL DEFAULT 1;

-- Index pour tri premium + réputation sur la liste techniciens
-- Utilisé par la requête accueil_client : ORDER BY is_premium DESC, score_global DESC
CREATE INDEX IF NOT EXISTS idx_utilisateurs_premium_ranking
  ON public.utilisateurs(pays, is_premium DESC, premium_level DESC, score_global DESC)
  WHERE role = 'technicien' AND disponible = true;


-- =============================================================================
-- 16. DEMANDES_SERVICE_DOMESTIQUE [À CRÉER]
-- Services sensibles : ménagère, servante, serveuse — validation humaine obligatoire
-- Exécuter dans Supabase SQL Editor
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.demandes_service_domestique (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  demandeur_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  type_service        TEXT NOT NULL CHECK (type_service IN ('menagere', 'servante', 'serveuse')),
  type_prestation     TEXT,
  nom_demandeur       TEXT NOT NULL,
  telephone_demandeur TEXT,
  ville               TEXT,
  commune             TEXT,
  description         TEXT,
  date_souhaitee      TEXT,
  statut              TEXT DEFAULT 'en_attente_validation'
                        CHECK (statut IN ('en_attente_validation', 'en_cours_traitement', 'affecte', 'annule', 'cloture')),
  enquete_effectuee   BOOLEAN DEFAULT false,
  niveau_validation   INTEGER DEFAULT 0,
  notes_admin         TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.demandes_service_domestique ENABLE ROW LEVEL SECURITY;

-- Demandeur : voir ses propres demandes + en créer
CREATE POLICY "dsd_select_own" ON public.demandes_service_domestique
  FOR SELECT USING (auth.uid() = demandeur_id);

CREATE POLICY "dsd_insert_own" ON public.demandes_service_domestique
  FOR INSERT WITH CHECK (auth.uid() = demandeur_id);

-- Admins : accès complet
CREATE POLICY "dsd_admin_all" ON public.demandes_service_domestique
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.utilisateurs WHERE id = auth.uid() AND is_admin = true)
  );

-- Index pour admin dashboard
CREATE INDEX IF NOT EXISTS idx_dsd_statut ON public.demandes_service_domestique(statut, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dsd_type ON public.demandes_service_domestique(type_service, statut);


-- =============================================================================
-- 17. COMPÉTENCES TECHNICIEN [À EXÉCUTER]
-- =============================================================================
-- Profil polyvalent "Homme à tout faire" — champ tableau texte libre
-- Index GIN pour recherche rapide par overlap (&&)

ALTER TABLE public.utilisateurs
ADD COLUMN IF NOT EXISTS competences TEXT[] DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_utilisateurs_competences
ON public.utilisateurs USING GIN (competences);

-- Catégorie "Homme à tout faire" (idempotente via ON CONFLICT)
INSERT INTO public.categories_services (nom, slug, groupe_parent, est_valide, ordre_affichage)
VALUES ('Homme à tout faire', 'homme-a-tout-faire', 'general', true, 0)
ON CONFLICT (slug) DO NOTHING;
