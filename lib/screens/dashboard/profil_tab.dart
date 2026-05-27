import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/screens/dashboard/verification_documents_page.dart';
import 'package:formelpro/screens/admin/admin_documents_page.dart';
import 'package:formelpro/screens/admin/admin_signalements_page.dart';
import 'package:formelpro/screens/admin/admin_users_page.dart';
import 'package:formelpro/screens/admin/admin_demandes_domestiques_page.dart';
import 'package:formelpro/widgets/profil/profil_header.dart';
import 'package:formelpro/widgets/profil/edit_profile_sheet.dart';
import 'package:formelpro/widgets/profil/profil_widgets.dart';
import 'package:formelpro/widgets/competences_editor_sheet.dart';

class ProfilTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Color accentColor;

  const ProfilTab(
      {super.key, required this.userData, required this.accentColor});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  late Map<String, dynamic> _localUserData;
  bool _isLoading = false;
  bool _uploadEnCours = false;
  List<Map<String, dynamic>> _favoris = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _localUserData = Map<String, dynamic>.from(widget.userData);
    if ((_localUserData['role'] ?? 'client') == 'client') _chargerFavoris();
  }

  Future<void> _chargerFavoris() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await supabase
          .from('favoris')
          .select('tech_id')
          .eq('client_id', uid)
          .order('date_ajout', ascending: false)
          .limit(50);
      if (rows.isEmpty) return;
      final techIds = rows.map((r) => r['tech_id'].toString()).toList();
      final techs = await supabase
          .from('utilisateurs')
          .select(
              'id, nom_complet, metier_personnalise, photo_profil_url, score_global, commune')
          .inFilter('id', techIds);
      if (mounted) {
        setState(() => _favoris = List<Map<String, dynamic>>.from(techs));
      }
    } catch (e) {
      debugPrint('Erreur favoris: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _uploadPhoto() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
      if (mounted) _showSnackBar("Image trop lourde (max 5 Mo)");
      return;
    }
    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (mounted) _showSnackBar("Format non supporté (jpg, png, webp)");
      return;
    }
    setState(() => _uploadEnCours = true);
    try {
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('photos-profil')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('photos-profil').getPublicUrl(path);
      await supabase
          .from('utilisateurs')
          .update({'photo_profil_url': url}).eq('id', uid);
      if (mounted) {
        setState(() => _localUserData['photo_profil_url'] = url);
        _showSnackBar("Photo de profil mise à jour !");
      }
    } on StorageException catch (e) {
      if (mounted) _showSnackBar("Erreur upload : ${e.message}");
    } catch (e) {
      if (mounted) _showSnackBar("Erreur inattendue");
      debugPrint("Upload photo erreur: $e");
    } finally {
      if (mounted) setState(() => _uploadEnCours = false);
    }
  }

  Future<void> _basculerRole() async {
    setState(() => _isLoading = true);
    final actuelRole = _localUserData['role'];
    final nouveauRole = (actuelRole == 'client') ? 'technicien' : 'client';
    try {
      await supabase
          .from('utilisateurs')
          .update({'role': nouveauRole}).eq('id', _localUserData['id']);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/main_dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ouvrirCompetences() async {
    final comps = (_localUserData['competences'] as List?)?.cast<String>() ?? [];
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompetencesEditorSheet(
        current: comps,
        accentColor: widget.accentColor,
      ),
    );
    if (result != null && mounted) {
      setState(() => _localUserData['competences'] = result);
      _showSnackBar("Compétences mises à jour !");
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        localUserData: _localUserData,
        accentColor: widget.accentColor,
        onSave: (updates) async {
          await supabase
              .from('utilisateurs')
              .update({...updates, 'a_complete_profil': true}).eq(
                  'id', _localUserData['id']);
          if (mounted) setState(() => _localUserData.addAll(updates));
          _showSnackBar("Profil mis à jour !");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pays = _localUserData['pays'] ?? 'CIV';
    final String bgImage = pays == 'CIV'
        ? 'assets/images/tech_ci.jpg'
        : 'assets/images/tech_cmr.jpg';
    final String role = _localUserData['role'] ?? 'client';
    final bool isPremium = _localUserData['is_premium'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85)),
            ),
          ),
          _isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: widget.accentColor))
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        ProfilHeader(
                          localUserData: _localUserData,
                          accentColor: widget.accentColor,
                          uploadEnCours: _uploadEnCours,
                          onUpload: _uploadPhoto,
                        ),
                        const SizedBox(height: 35),
                        const ProfilSectionTitle(title: "Activité & Mode"),
                        ProfilGlassCard(children: [
                          ProfilActionTile(
                            icon: Icons.sync_alt_rounded,
                            title: role == 'client'
                                ? "Devenir Technicien"
                                : "Passer en mode Client",
                            subtitle:
                                "Accéder à l'interface ${role == 'client' ? 'prestataire' : 'utilisateur'}",
                            accentColor: widget.accentColor,
                            onTap: _basculerRole,
                          ),
                          if (role == 'technicien') ...[
                            const ProfilDivider(),
                            ProfilInfoTile(
                              icon: Icons.rocket_launch_rounded,
                              label: "Statut Visibilité",
                              value: isPremium
                                  ? "Boost Prioritaire Actif"
                                  : "Visibilité Standard",
                              trailing: isPremium
                                  ? const Icon(Icons.verified,
                                      color: Colors.amber, size: 20)
                                  : null,
                            ),
                          ],
                        ]),
                        const SizedBox(height: 25),
                        const ProfilSectionTitle(title: "Mes Coordonnées"),
                        ProfilGlassCard(children: [
                          ProfilInfoTile(
                              icon: Icons.phone,
                              label: "Téléphone",
                              value: _localUserData['telephone'] ??
                                  "Non renseigné"),
                          const ProfilDivider(),
                          ProfilInfoTile(
                              icon: Icons.location_on,
                              label: "Localisation",
                              value:
                                  "${_localUserData['quartier'] ?? ''} ${_localUserData['commune'] ?? 'N/A'}, ${_localUserData['ville'] ?? ''}"),
                        ]),
                        const SizedBox(height: 25),
                        const ProfilSectionTitle(title: "Sécurité & Compte"),
                        ProfilGlassCard(children: [
                          ProfilActionTile(
                            icon: Icons.edit_note_rounded,
                            title: "Modifier mon profil",
                            accentColor: widget.accentColor,
                            onTap: _showEditProfileModal,
                          ),
                          const ProfilDivider(),
                          ProfilActionTile(
                            icon: Icons.document_scanner_rounded,
                            title: "Vérification d'identité",
                            accentColor: widget.accentColor,
                            subtitle: (_localUserData['is_identite_verifiee'] ==
                                    true)
                                ? "✓ Identité vérifiée"
                                : ((_localUserData['document_identite_url'] ??
                                            '')
                                        .isNotEmpty)
                                    ? "Document soumis — en attente"
                                    : "Soumettre un document d'identité",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerificationDocumentsPage(
                                    accentColor: widget.accentColor),
                              ),
                            ),
                          ),
                        ]),
                        if (role == 'technicien') ...[
                          const SizedBox(height: 25),
                          const ProfilSectionTitle(title: "Mes Compétences"),
                          ProfilGlassCard(children: [
                            ProfilActionTile(
                              icon: Icons.construction_rounded,
                              title: "Homme à tout faire",
                              subtitle: () {
                                final c = (_localUserData['competences']
                                        as List?)
                                    ?.cast<String>() ??
                                    [];
                                if (c.isEmpty) {
                                  return "Ajoutez vos savoir-faire polyvalents";
                                }
                                final preview = c.take(3).join(' · ');
                                return c.length > 3
                                    ? '$preview +${c.length - 3}'
                                    : preview;
                              }(),
                              accentColor: widget.accentColor,
                              onTap: _ouvrirCompetences,
                            ),
                          ]),
                        ],
                        if (role == 'client') ...[
                          const SizedBox(height: 25),
                          const ProfilSectionTitle(title: "Mes Favoris"),
                          ProfilGlassCard(
                            children: _favoris.isEmpty
                                ? [
                                    const ProfilInfoTile(
                                        icon: Icons.favorite_border_rounded,
                                        label: "Favoris",
                                        value: "Aucun technicien ajouté")
                                  ]
                                : _favoris
                                    .asMap()
                                    .entries
                                    .expand((e) => [
                                          FavoriTile(
                                              tech: e.value,
                                              accentColor: widget.accentColor),
                                          if (e.key < _favoris.length - 1)
                                            const ProfilDivider(),
                                        ])
                                    .toList(),
                          ),
                        ],
                        if (_localUserData['is_admin'] == true) ...[
                          const SizedBox(height: 25),
                          const ProfilSectionTitle(title: "Administration"),
                          ProfilGlassCard(children: [
                            ProfilActionTile(
                              icon: Icons.admin_panel_settings_rounded,
                              title: "Validation des documents",
                              subtitle: "Vérifier les identités en attente",
                              accentColor: widget.accentColor,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AdminDocumentsPage(accentColor: widget.accentColor))),
                            ),
                            const ProfilDivider(),
                            ProfilActionTile(
                              icon: Icons.flag_rounded,
                              title: "Signalements",
                              subtitle: "Traiter les signalements utilisateurs",
                              accentColor: widget.accentColor,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AdminSignalementsPage(accentColor: widget.accentColor))),
                            ),
                            const ProfilDivider(),
                            ProfilActionTile(
                              icon: Icons.manage_accounts_rounded,
                              title: "Gestion utilisateurs",
                              subtitle: "Suspendre ou réactiver des comptes",
                              accentColor: widget.accentColor,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AdminUsersPage(accentColor: widget.accentColor))),
                            ),
                            const ProfilDivider(),
                            ProfilActionTile(
                              icon: Icons.home_work_rounded,
                              title: "Demandes domestiques",
                              subtitle: "Ménagère, servante, serveuse — en attente",
                              accentColor: widget.accentColor,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AdminDemandesDomestiquesPage(accentColor: widget.accentColor))),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 40),
                        const ProfilLogoutButton(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
