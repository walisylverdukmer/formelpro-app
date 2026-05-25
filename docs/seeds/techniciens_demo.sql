-- ============================================================
-- SEED DATA — Techniciens démonstration FormelPro
-- Exécuter dans : Supabase SQL Editor (service_role requis)
-- CES DONNÉES SONT FICTIVES — usage dev/démo uniquement
-- UUIDs fixes préfixés d0000000- pour identification aisée
-- ============================================================

-- ── ÉTAPE 1 : Créer les comptes auth (service_role requis) ──
INSERT INTO auth.users (
  id, instance_id, aud, role,
  email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token,
  created_at, updated_at
) VALUES
  -- CIV Techniciens
  ('d0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'kouame.plombier@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000002-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'ama.electricien@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000003-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'koffi.climatisation@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000004-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'adjoua.menage@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000005-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'yao.peinture@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  -- CMR Techniciens
  ('d0000006-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'mbarga.electricien@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000007-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'ngo.plomberie@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000008-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'fotso.menuiserie@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000009-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'mvondo.informatique@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now()),

  ('d0000010-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
   'biya.climatisation@demo.formelpro.test', crypt('Demo2026!', gen_salt('bf')), now(), '', '', now(), now())

ON CONFLICT (id) DO NOTHING;


-- ── ÉTAPE 2 : Créer les profils utilisateurs ──
INSERT INTO utilisateurs (
  id, role, pays, prenom, nom_complet,
  telephone, ville, commune, quartier,
  metier_personnalise, savoir_faire,
  score_global, note_moyenne, total_transactions,
  disponible, est_en_ligne,
  is_premium, premium_level,
  is_identite_verifiee,
  a_complete_profil,
  photo_profil_url
) VALUES

  -- ── CÔTE D'IVOIRE (CIV) ──

  (
    'd0000001-0000-0000-0000-000000000001',
    'technicien', 'CIV', 'Kouamé', 'Kouamé Assi Bernardin',
    '+2250758123456', 'Abidjan', 'Cocody', 'Riviera 2',
    'Plombier certifié',
    'Réparations fuites, installation sanitaires, débouchage canalisation, cumulus électriques',
    4.9, 4.9, 47,
    true, true,
    true, 2,
    true,
    true,
    null
  ),

  (
    'd0000002-0000-0000-0000-000000000002',
    'technicien', 'CIV', 'Ama', 'Ama Kouassi Bénédicte',
    '+2250707654321', 'Abidjan', 'Yopougon', 'Selmer',
    'Électricienne industrielle',
    'Installation tableau électrique, dépannage panne générale, câblage bâtiment, prises et interrupteurs',
    4.7, 4.7, 31,
    true, false,
    true, 1,
    true,
    true,
    null
  ),

  (
    'd0000003-0000-0000-0000-000000000003',
    'technicien', 'CIV', 'Koffi', 'Koffi N''Guessan Serge',
    '+2250505111222', 'Abidjan', 'Plateau', 'Centre',
    'Technicien climatisation',
    'Installation split, entretien climatiseurs, recharge gaz, dépannage toutes marques',
    4.5, 4.5, 22,
    false, false,
    false, 1,
    true,
    true,
    null
  ),

  (
    'd0000004-0000-0000-0000-000000000004',
    'technicien', 'CIV', 'Adjoua', 'Adjoua Konan Marie-Claire',
    '+2250777888999', 'Abidjan', 'Marcory', 'Zone 4',
    'Femme de ménage professionnelle',
    'Ménage complet, nettoyage vitrerie, repassage, service cuisine, gardiennage maison',
    4.8, 4.8, 63,
    true, true,
    true, 2,
    false,
    true,
    null
  ),

  (
    'd0000005-0000-0000-0000-000000000005',
    'technicien', 'CIV', 'Yao', 'Yao Koné Franck',
    '+2250101234567', 'Bouaké', 'Centre', 'Commerce',
    'Peintre décorateur',
    'Peinture intérieure et extérieure, enduit, ravalement façade, papier peint, décoration murale',
    4.2, 4.2, 18,
    true, false,
    false, 1,
    false,
    true,
    null
  ),

  -- ── CAMEROUN (CMR) ──

  (
    'd0000006-0000-0000-0000-000000000006',
    'technicien', 'CMR', 'Jean-Baptiste', 'Mbarga Jean-Baptiste',
    '+237691234567', 'Yaoundé', 'Bastos', 'Bastos',
    'Électricien bâtiment',
    'Câblage neuf, rénovation installation électrique, groupe électrogène, domotique simple',
    4.8, 4.8, 39,
    true, true,
    true, 2,
    true,
    true,
    null
  ),

  (
    'd0000007-0000-0000-0000-000000000007',
    'technicien', 'CMR', 'Cécile', 'Ngo Biyik Cécile',
    '+237677654321', 'Douala', 'Akwa', 'Bali',
    'Plombière sanitaire',
    'Plomberie complète, installation douche, WC, lavabo, réparations urgentes fuites',
    4.6, 4.6, 27,
    true, false,
    false, 1,
    true,
    true,
    null
  ),

  (
    'd0000008-0000-0000-0000-000000000008',
    'technicien', 'CMR', 'Pierre', 'Fotso Kamdem Pierre',
    '+237655111333', 'Yaoundé', 'Mendong', 'Mendong',
    'Menuisier-ébéniste',
    'Fabrication meubles sur mesure, portes, fenêtres PVC et aluminium, parquet, rénovation bois',
    4.4, 4.4, 15,
    false, false,
    false, 1,
    false,
    true,
    null
  ),

  (
    'd0000009-0000-0000-0000-000000000009',
    'technicien', 'CMR', 'Francis', 'Mvondo Essomba Francis',
    '+237699876543', 'Douala', 'Bonanjo', 'Bonaparte',
    'Technicien informatique',
    'Réparation PC, installation réseau, dépannage imprimante, récupération données, sécurité WiFi',
    4.9, 4.9, 52,
    true, true,
    true, 2,
    true,
    true,
    null
  ),

  (
    'd0000010-0000-0000-0000-000000000010',
    'technicien', 'CMR', 'Sylvain', 'Biya Nguele Sylvain',
    '+237650555444', 'Yaoundé', 'Nlongkak', 'Tsinga',
    'Technicien froid & climatisation',
    'Climatiseurs résidentiels et industriels, entretien préventif, recharge fluide frigorigène',
    4.3, 4.3, 21,
    true, false,
    false, 1,
    false,
    true,
    null
  )

ON CONFLICT (id) DO UPDATE SET
  metier_personnalise = EXCLUDED.metier_personnalise,
  savoir_faire = EXCLUDED.savoir_faire,
  score_global = EXCLUDED.score_global,
  disponible = EXCLUDED.disponible;


-- ── ÉTAPE 3 (optionnel) : Nettoyer les données demo ──
-- Pour supprimer toutes les données demo plus tard :
-- DELETE FROM utilisateurs WHERE id::text LIKE 'd0000%';
-- DELETE FROM auth.users WHERE id::text LIKE 'd0000%';
