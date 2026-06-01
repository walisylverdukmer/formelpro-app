import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/widgets/category_picker.dart';
import 'package:formelpro/widgets/gps_location_button.dart';
import 'package:formelpro/widgets/location_picker_widget.dart';

final supabase = Supabase.instance.client;

class CompleteProfilPage extends StatefulWidget {
  final String role;
  final String paysCode;

  const CompleteProfilPage({
    super.key,
    required this.role,
    required this.paysCode,
  });

  @override
  State<CompleteProfilPage> createState() => _CompleteProfilPageState();
}

class _CompleteProfilPageState extends State<CompleteProfilPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomCompletController = TextEditingController();
  final TextEditingController _savoirFaireController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();

  String? _selectedJob;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _uploadingDoc = false;
  String? _documentUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomCompletController.dispose();
    _savoirFaireController.dispose();
    _ageController.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          accentColor:
              widget.paysCode == 'CIV'
                  ? const Color(0xFFE67E22)
                  : const Color(0xFFE74C3C),
          paysCode: widget.paysCode,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final ville = result['ville'] as String? ?? '';
    final commune = result['commune'] as String? ?? '';
    final quartier = result['quartier'] as String? ?? '';
    setState(() {
      if (ville.isNotEmpty) _villeController.text = ville;
      if (commune.isNotEmpty) _communeController.text = commune;
      if (quartier.isNotEmpty) _quartierController.text = quartier;
    });
  }

  Future<void> _pickDocument() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked == null) return;

    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fichier trop lourd (max 5 Mo)")),
        );
      }
      return;
    }

    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Format non supporté (jpg, png, webp)")),
        );
      }
      return;
    }

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _uploadingDoc = true);
    try {
      final path = '$uid/cni_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('documents-identite').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final url =
          supabase.storage.from('documents-identite').getPublicUrl(path);
      if (mounted) setState(() => _documentUrl = url);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur upload : ${e.message}")),
        );
      }
    } catch (e) {
      debugPrint("Upload doc erreur: $e");
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.role == 'technicien' &&
        (_selectedJob == null || _selectedJob!.isEmpty)) {
      setState(
        () => _errorMessage = "Veuillez sélectionner ou saisir votre métier.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Utilisateur non connecté.';
        _isLoading = false;
      });
      return;
    }

    try {
      final Map<String, dynamic> updateData = {
        'prenom': _prenomController.text.trim(),
        'nom_complet': _nomCompletController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'ville': _villeController.text.trim(),
        'quartier': _quartierController.text.trim(),
        'a_complete_profil': true,
      };

      if (widget.role == 'technicien') {
        updateData['metier_personnalise'] = _selectedJob;
        updateData['categorie_id'] = _selectedCategoryId;
        updateData['savoir_faire'] = _savoirFaireController.text.trim();
        if (_documentUrl != null) {
          updateData['document_identite_url'] = _documentUrl;
          updateData['type_document'] = 'CNI';
        }
      }

      if (widget.paysCode == 'CIV') {
        updateData['commune'] = _communeController.text.trim();
      }

      await supabase.from('utilisateurs').update(updateData).eq('id', user.id);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainDashboardPage(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );
      }
    } on PostgrestException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(() => _errorMessage = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCI = widget.paysCode == 'CIV';
    final Color accent =
        isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final bool isTech = widget.role == 'technicien';

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          "Finalisation du profil",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isTech ? 'Prestataire' : 'Client',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(
                "Informations personnelles",
                Icons.person_outline_rounded,
                accent,
              ),
              const SizedBox(height: 14),
              _buildField(_prenomController, 'Prénom', Icons.person_outline),
              const SizedBox(height: 12),
              _buildField(
                _nomCompletController,
                'Nom de famille',
                Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                _ageController,
                'Âge',
                Icons.calendar_today_outlined,
                isNumber: true,
                isRequired: false,
              ),
              if (isTech) ...[
                const SizedBox(height: 28),
                _buildSectionHeader(
                  "Votre métier",
                  Icons.handyman_rounded,
                  accent,
                ),
                const SizedBox(height: 14),
                CategoryPicker(
                  accentColor: accent,
                  onChanged: (jobName, catId) {
                    setState(() {
                      _selectedJob = jobName.isEmpty ? null : jobName;
                      _selectedCategoryId = catId;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  _savoirFaireController,
                  'Décrivez vos spécialités (ex: Pose de climatiseur)',
                  Icons.build_circle_outlined,
                  maxLines: 2,
                  isRequired: false,
                ),
                const SizedBox(height: 12),
                _buildDocumentUpload(accent),
              ],
              const SizedBox(height: 28),
              _buildSectionHeader(
                isCI
                    ? "Localisation (Commune + Quartier)"
                    : "Localisation (Ville + Quartier)",
                Icons.location_on_outlined,
                accent,
              ),
              const SizedBox(height: 18),
              GpsLocationButton(
                accentColor: accent,
                paysCode: widget.paysCode,
                onLocationDetected: (result) {
                  if (!mounted) return;
                  setState(() {
                    final ville = result['ville'] as String? ?? '';
                    final commune = result['commune'] as String? ?? '';
                    final quartier = result['quartier'] as String? ?? '';
                    if (ville.isNotEmpty) _villeController.text = ville;
                    if (commune.isNotEmpty) _communeController.text = commune;
                    if (quartier.isNotEmpty) _quartierController.text = quartier;
                  });
                },
                onOpenMap: _openLocationPicker,
              ),
              const SizedBox(height: 18),
              _buildField(_villeController, 'Ville', Icons.location_city),
              if (isCI) ...[
                const SizedBox(height: 12),
                _buildField(
                  _communeController,
                  'Commune',
                  Icons.map_outlined,
                  isRequired: isCI,
                ),
              ],
              const SizedBox(height: 12),
              _buildField(
                _quartierController,
                'Quartier',
                Icons.near_me_outlined,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            color: Colors.red.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Enregistrer mon profil',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUpload(Color accent) {
    return GestureDetector(
      onTap: _uploadingDoc ? null : _pickDocument,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _documentUrl != null
                ? accent
                : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.document_scanner_outlined,
              color: _documentUrl != null ? accent : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pièce d'identité (optionnel)",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    _documentUrl != null
                        ? "Document ajouté ✓"
                        : "Ajouter CNI / Passeport",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _documentUrl != null
                          ? accent
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            _uploadingDoc
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _documentUrl != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_rounded,
                    color: _documentUrl != null ? accent : const Color(0xFF94A3B8),
                    size: 22,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFE67E22).withValues(alpha: 0.6),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: isRequired
          ? (value) =>
              value == null || value.isEmpty ? 'Ce champ est obligatoire' : null
          : null,
    );
  }
}
