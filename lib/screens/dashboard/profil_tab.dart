import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:formelpro/screens/auth/page_connexion_principale.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';
import 'package:formelpro/screens/dashboard/verification_documents_page.dart';
import 'package:formelpro/screens/admin/admin_documents_page.dart';
import 'package:formelpro/screens/admin/admin_signalements_page.dart';
import 'package:formelpro/screens/admin/admin_users_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Color accentColor;

  const ProfilTab({super.key, required this.userData, required this.accentColor});

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
          .select('id, nom_complet, metier_personnalise, photo_profil_url, score_global, commune')
          .inFilter('id', techIds);
      if (mounted) setState(() => _favoris = List<Map<String, dynamic>>.from(techs));
    } catch (e) {
      debugPrint('Erreur favoris: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
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
      await supabase.from('utilisateurs').update({'photo_profil_url': url}).eq('id', uid);
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

  // --- LOGIQUE : BASCULE DE RÔLE ---
  Future<void> _basculerRole() async {
    setState(() => _isLoading = true);
    final actuelRole = _localUserData['role'];
    final nouveauRole = (actuelRole == 'client') ? 'technicien' : 'client';

    try {
      await supabase
          .from('utilisateurs')
          .update({'role': nouveauRole})
          .eq('id', _localUserData['id']);

      if (mounted) {
        // On force un rafraîchissement global de l'app pour charger le bon Dashboard
        Navigator.pushNamedAndRemoveUntil(context, '/main_dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI : MODALE D'ÉDITION ---
  void _showEditProfileModal() {
    // Utilisation des noms de colonnes exacts de ton SQL
    final phoneController = TextEditingController(text: _localUserData['telephone']);
    final villeController = TextEditingController(text: _localUserData['ville']);
    final communeController = TextEditingController(text: _localUserData['commune']);
    final quartierController = TextEditingController(text: _localUserData['quartier']);
    final metierController = TextEditingController(text: _localUserData['metier_personnalise'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Plus sombre pour le contraste
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Modifier mon profil", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 25),
              _buildEditField(metierController, "Votre Métier / Spécialité", Icons.handyman),
              _buildEditField(phoneController, "Numéro de téléphone", Icons.phone),
              _buildEditField(villeController, "Ville", Icons.location_city),
              _buildEditField(communeController, "Commune", Icons.business),
              _buildEditField(quartierController, "Quartier", Icons.map),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updates = {
                      'telephone': phoneController.text.trim(),
                      'ville': villeController.text.trim(),
                      'commune': communeController.text.trim(),
                      'quartier': quartierController.text.trim(),
                      'metier_personnalise': metierController.text.trim(),
                      'a_complete_profil': true,
                    };
                    final navigator = Navigator.of(context);
                    try {
                      await supabase.from('utilisateurs').update(updates).eq('id', _localUserData['id']);
                      if (!mounted) return;
                      setState(() => _localUserData.addAll(updates));
                      navigator.pop();
                      _showSnackBar("Profil mis à jour !");
                    } catch (e) {
                      debugPrint("Erreur update: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pays = _localUserData['pays'] ?? 'CIV';
    final String bgImage = pays == 'CIV' ? 'assets/images/tech_ci.jpg' : 'assets/images/tech_cmr.jpg';
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
              child: Container(color: const Color(0xFF0F172A).withValues(alpha: 0.85)),
            ),
          ),
          _isLoading 
            ? Center(child: CircularProgressIndicator(color: widget.accentColor))
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildProfileHeader(role),
                      const SizedBox(height: 35),
                      
                      _buildSectionTitle("Activité & Mode"),
                      _buildGlassCard([
                        _buildActionTile(
                          Icons.sync_alt_rounded, 
                          role == 'client' ? "Devenir Technicien" : "Passer en mode Client", 
                          _basculerRole,
                          subtitle: "Accéder à l'interface ${role == 'client' ? 'prestataire' : 'utilisateur'}",
                        ),
                        if (role == 'technicien') ...[
                          _buildDivider(),
                          _buildInfoTile(
                            Icons.rocket_launch_rounded, 
                            "Statut Visibilité", 
                            isPremium ? "Boost Prioritaire Actif" : "Visibilité Standard",
                            trailing: isPremium ? const Icon(Icons.verified, color: Colors.amber, size: 20) : null,
                          ),
                        ],
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Mes Coordonnées"),
                      _buildGlassCard([
                        _buildInfoTile(Icons.phone, "Téléphone", _localUserData['telephone'] ?? "Non renseigné"),
                        _buildDivider(),
                        _buildInfoTile(Icons.location_on, "Localisation", "${_localUserData['quartier'] ?? ''} ${_localUserData['commune'] ?? 'N/A'}, ${_localUserData['ville'] ?? ''}"),
                      ]),

                      const SizedBox(height: 25),
                      _buildSectionTitle("Sécurité & Compte"),
                      _buildGlassCard([
                        _buildActionTile(Icons.edit_note_rounded, "Modifier mon profil", _showEditProfileModal),
                        _buildDivider(),
                        _buildActionTile(
                          Icons.document_scanner_rounded,
                          "Vérification d'identité",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerificationDocumentsPage(
                                  accentColor: widget.accentColor),
                            ),
                          ),
                          subtitle: (_localUserData['is_identite_verifiee'] == true)
                              ? "✓ Identité vérifiée"
                              : ((_localUserData['document_identite_url'] ?? '').isNotEmpty)
                                  ? "Document soumis — en attente"
                                  : "Soumettre un document d'identité",
                        ),
                      ]),

                      if (role == 'client') ...[
                        const SizedBox(height: 25),
                        _buildSectionTitle("Mes Favoris"),
                        _buildGlassCard(
                          _favoris.isEmpty
                              ? [_buildInfoTile(Icons.favorite_border_rounded, "Favoris", "Aucun technicien ajouté")]
                              : _favoris.asMap().entries.expand((e) => [
                                  _buildFavoriTile(e.value),
                                  if (e.key < _favoris.length - 1) _buildDivider(),
                                ]).toList(),
                        ),
                      ],

                      if (_localUserData['is_admin'] == true) ...[
                        const SizedBox(height: 25),
                        _buildSectionTitle("Administration"),
                        _buildGlassCard([
                          _buildActionTile(
                            Icons.admin_panel_settings_rounded,
                            "Validation des documents",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminDocumentsPage(
                                    accentColor: widget.accentColor),
                              ),
                            ),
                            subtitle: "Vérifier les identités en attente",
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            Icons.flag_rounded,
                            "Signalements",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminSignalementsPage(
                                    accentColor: widget.accentColor),
                              ),
                            ),
                            subtitle: "Traiter les signalements utilisateurs",
                          ),
                          _buildDivider(),
                          _buildActionTile(
                            Icons.manage_accounts_rounded,
                            "Gestion utilisateurs",
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminUsersPage(
                                    accentColor: widget.accentColor),
                              ),
                            ),
                            subtitle: "Suspendre ou réactiver des comptes",
                          ),
                        ]),
                      ],

                      const SizedBox(height: 40),
                      _buildLogoutButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // --- WIDGETS DE COMPOSANTS ---

  Widget _buildProfileHeader(String role) {
    final String? avatarUrl = _localUserData['photo_profil_url'];
    // On s'assure que le score est un double valide
    final double rating = (_localUserData['score_global'] != null) 
        ? double.parse(_localUserData['score_global'].toString()) 
        : 5.0;

    return Column(
      children: [
        GestureDetector(
          onTap: _uploadEnCours ? null : _uploadPhoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              _uploadEnCours
                  ? CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      child: CircularProgressIndicator(color: widget.accentColor, strokeWidth: 2),
                    )
                  : CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 55, color: Colors.white24) : null,
                    ),
              if (!_uploadEnCours)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              if (_localUserData['is_identite_verifiee'] == true)
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "${_localUserData['prenom'] ?? ''} ${_localUserData['nom_complet'] ?? ''}",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        if (role == 'technicien') ...[
          const SizedBox(height: 5),
          Text(
            (_localUserData['metier_personnalise'] ?? "PRESTATAIRE").toUpperCase(),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: widget.accentColor, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          _buildRatingStars(rating),
        ],
      ],
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 10),
        child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
      title: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
      subtitle: Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      trailing: trailing,
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: widget.accentColor, size: 18),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white24)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => Icon(
        index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
        color: Colors.amber, size: 18,
      )),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, color: widget.accentColor, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: widget.accentColor)),
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.white.withAlpha(13), indent: 55);

  Widget _buildFavoriTile(Map<String, dynamic> tech) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsTechnicien(tech: tech, accentColor: widget.accentColor)),
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: widget.accentColor.withAlpha(25),
        backgroundImage: tech['photo_profil_url'] != null ? NetworkImage(tech['photo_profil_url']) : null,
        child: tech['photo_profil_url'] == null ? Icon(Icons.person, color: widget.accentColor, size: 18) : null,
      ),
      title: Text(tech['nom_complet'] ?? 'Anonyme',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      subtitle: Text(tech['metier_personnalise'] ?? 'Prestataire',
          style: GoogleFonts.inter(fontSize: 12, color: widget.accentColor)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await supabase.auth.signOut();
          if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const PageConnexionPrincipale()), (route) => false);
        },
        icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
        label: const Text("Déconnexion du compte", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2))),
        ),
      ),
    );
  }
}