import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> localUserData;
  final Color accentColor;
  final Future<void> Function(Map<String, String> updates) onSave;

  const EditProfileSheet({
    super.key,
    required this.localUserData,
    required this.accentColor,
    required this.onSave,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _metierCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _villeCtrl;
  late final TextEditingController _communeCtrl;
  late final TextEditingController _quartierCtrl;

  @override
  void initState() {
    super.initState();
    _metierCtrl = TextEditingController(
        text: widget.localUserData['metier_personnalise'] ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.localUserData['telephone'] ?? '');
    _villeCtrl =
        TextEditingController(text: widget.localUserData['ville'] ?? '');
    _communeCtrl =
        TextEditingController(text: widget.localUserData['commune'] ?? '');
    _quartierCtrl =
        TextEditingController(text: widget.localUserData['quartier'] ?? '');
  }

  @override
  void dispose() {
    _metierCtrl.dispose();
    _phoneCtrl.dispose();
    _villeCtrl.dispose();
    _communeCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            Text("Modifier mon profil",
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 25),
            _field(_metierCtrl, "Votre Métier / Spécialité", Icons.handyman),
            _field(_phoneCtrl, "Numéro de téléphone", Icons.phone),
            _field(_villeCtrl, "Ville", Icons.location_city),
            _field(_communeCtrl, "Commune", Icons.business),
            _field(_quartierCtrl, "Quartier", Icons.map),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final updates = {
                    'telephone': _phoneCtrl.text.trim(),
                    'ville': _villeCtrl.text.trim(),
                    'commune': _communeCtrl.text.trim(),
                    'quartier': _quartierCtrl.text.trim(),
                    'metier_personnalise': _metierCtrl.text.trim(),
                    'a_complete_profil': 'true',
                  };
                  final navigator = Navigator.of(context);
                  await widget.onSave(updates);
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Enregistrer les modifications",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, color: widget.accentColor, size: 20),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: widget.accentColor)),
        ),
      ),
    );
  }
}
