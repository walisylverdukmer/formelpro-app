import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// --- IMPORTS ALIGNÉS SUR VOTRE ARCHITECTURE ---
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/widgets/category_picker.dart'; // Assure-toi que ce fichier existe

final supabase = Supabase.instance.client;

class CompleteProfilPage extends StatefulWidget {
  final String role;
  final String paysCode;

  const CompleteProfilPage({super.key, required this.role, required this.paysCode});

  @override
  State<CompleteProfilPage> createState() => _CompleteProfilPageState();
}

class _CompleteProfilPageState extends State<CompleteProfilPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de texte
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _nomCompletController = TextEditingController();
  final TextEditingController _savoirFaireController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();

  // Variables pour le CategoryPicker
  String? _selectedJob;
  String? _selectedCategoryId;

  bool _isLoading = false;
  bool _uploadingDoc = false;
  String? _documentUrl;
  String? _errorMessage;

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fichier trop lourd (max 5 Mo)")));
      return;
    }

    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Format non supporté (jpg, png, webp)")));
      return;
    }

    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _uploadingDoc = true);
    try {
      final path = '$uid/cni_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('documents-identite')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('documents-identite').getPublicUrl(path);
      if (mounted) setState(() => _documentUrl = url);
    } on StorageException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur upload : ${e.message}")));
    } catch (e) {
      debugPrint("Upload doc erreur: $e");
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire pour le technicien
    if (widget.role == 'technicien' && (_selectedJob == null || _selectedJob!.isEmpty)) {
      setState(() => _errorMessage = "Veuillez sélectionner ou saisir votre métier.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = supabase.auth.currentUser;

    if (user == null) {
      _errorMessage = 'Utilisateur non connecté.';
      if (mounted) setState(() => _isLoading = false);
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

      // Ajout des champs spécifiques au technicien (Métier + Catégorie + Détails)
      if (widget.role == 'technicien') {
        updateData['metier_personnalise'] = _selectedJob;
        updateData['categorie_id'] = _selectedCategoryId;
        updateData['savoir_faire'] = _savoirFaireController.text.trim();
        if (_documentUrl != null) {
          updateData['document_identite_url'] = _documentUrl;
          updateData['type_document'] = 'CNI';
        }
      }

      // Ajout de la commune uniquement pour la Côte d'Ivoire
      if (widget.paysCode == 'CIV') {
        updateData['commune'] = _communeController.text.trim();
      }

      await supabase.from('utilisateurs').update(updateData).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );

        // Navigation vers le Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainDashboardPage()), 
        );
      }
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'Une erreur est survenue: $error';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = widget.paysCode == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Finalisation du Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Presque terminé !',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Complétez vos informations pour accéder au réseau.',
                style: GoogleFonts.inter(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              _buildTextField(_prenomController, 'Prénom', Icons.person_outline, false),
              const SizedBox(height: 15),
              _buildTextField(_nomCompletController, 'Nom de famille', Icons.badge_outlined, false),
              const SizedBox(height: 15),
              _buildTextField(_ageController, 'Âge', Icons.calendar_today_outlined, true),
              const SizedBox(height: 15),
              
              // --- SECTION MÉTIER (POUR LES TECHNICIENS) ---
              if (widget.role == 'technicien') ...[
                CategoryPicker(
                  accentColor: primaryColor,
                  onChanged: (jobName, catId) {
                    setState(() {
                      _selectedJob = jobName;
                      _selectedCategoryId = catId;
                    });
                  },
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  _savoirFaireController,
                  'Précisez vos spécialités (ex: Pose de clim)',
                  Icons.build_circle_outlined,
                  false,
                  maxLines: 2
                ),
                const SizedBox(height: 15),
                _buildDocumentUpload(primaryColor),
                const SizedBox(height: 15),
              ],

              _buildTextField(_villeController, 'Ville', Icons.location_city, false),
              const SizedBox(height: 15),
              
              if (widget.paysCode == 'CIV') ...[
                _buildTextField(_communeController, 'Commune', Icons.map_outlined, false),
                const SizedBox(height: 15),
              ],
              
              _buildTextField(_quartierController, 'Quartier', Icons.near_me_outlined, false),
              
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Enregistrer mon profil', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(Color primaryColor) {
    return GestureDetector(
      onTap: _uploadingDoc ? null : _pickDocument,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _documentUrl != null ? primaryColor : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.document_scanner_outlined,
                color: _documentUrl != null ? primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pièce d'identité (optionnel)",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    _documentUrl != null
                        ? "Document ajouté ✓"
                        : "Ajouter CNI / Passeport",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _documentUrl != null ? primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            _uploadingDoc
                ? SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                  )
                : Icon(
                    _documentUrl != null ? Icons.check_circle_rounded : Icons.upload_rounded,
                    color: _documentUrl != null ? primaryColor : Colors.grey,
                    size: 22,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isNumber, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
    );
  }
}