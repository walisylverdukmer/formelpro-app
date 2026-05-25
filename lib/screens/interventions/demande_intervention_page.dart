import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DemandeInterventionPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final Color accentColor;

  const DemandeInterventionPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.accentColor,
  });

  @override
  State<DemandeInterventionPage> createState() => _DemandeInterventionPageState();
}

class _DemandeInterventionPageState extends State<DemandeInterventionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _communeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _budgetController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _issubmitting = false;
  final supabase = Supabase.instance.client;

  // Fonction pour choisir la date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: widget.accentColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Fonction pour choisir l'heure
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _envoyerDemande() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir une date et une heure")),
      );
      return;
    }

    setState(() => _issubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      
      // Fusion de la date et de l'heure
      final DateTime dateComplete = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await supabase.from('interventions').insert({
        'client_id': user!.id,
        'categorie_id': widget.categoryId,
        'categorie_nom': widget.categoryName,
        'description': _descriptionController.text.trim(),
        'commune': _communeController.text.trim(),
        'adresse_precise': _adresseController.text.trim(),
        'prix_estimé': int.tryParse(_budgetController.text) ?? 0,
        'date_intervention': dateComplete.toIso8601String(), // Nouveau champ
        'statut': 'En attente',
        'ville': 'Abidjan',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Demande publiée !"), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _issubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Détails du besoin", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 30),
              
              _buildLabel("Quand souhaitez-vous l'intervention ?"),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.calendar_today_rounded,
                      text: _selectedDate == null 
                          ? "Choisir date" 
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.access_time_rounded,
                      text: _selectedTime == null 
                          ? "Choisir heure" 
                          : _selectedTime!.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              _buildLabel("Description de l'intervention"),
              _buildTextField(_descriptionController, "Précisez votre problème...", maxLines: 3),
              
              const SizedBox(height: 20),
              _buildLabel("Commune & Adresse"),
              _buildTextField(_communeController, "Ex: Cocody, Angré..."),
              const SizedBox(height: 12),
              _buildTextField(_adresseController, "Précisions (ex: Rue L84...)"),
              
              const SizedBox(height: 20),
              _buildLabel("Budget approximatif (FCFA)"),
              _buildTextField(_budgetController, "Ex: 25000", keyboardType: TextInputType.number),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _issubmitting ? null : _envoyerDemande,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _issubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("PUBLIER MA DEMANDE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: widget.accentColor),
            const SizedBox(width: 8),
            Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.handyman_rounded, color: widget.accentColor, size: 24),
          const SizedBox(width: 12),
          Text(widget.categoryName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (v) => v == null || v.isEmpty ? "Champ requis" : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.1))),
      ),
    );
  }
}