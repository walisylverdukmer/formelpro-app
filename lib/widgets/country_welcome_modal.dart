import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCountryWelcomeModal(
    BuildContext context, Map<String, dynamic> userData) {
  final String pays = userData['pays'] ?? 'CIV';
  final bool isCI = pays == 'CIV';
  final Color accentColor =
      isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
  final String flagPath =
      isCI ? "assets/images/ci.jpg" : "assets/images/cmr.jpg";

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                flagPath,
                width: 70,
                height: 45,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isCI ? "FormelPro Côte d'Ivoire" : "FormelPro Cameroun",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isCI
                  ? "Trouvez les artisans qualifiés de proximité."
                  : "Accédez au réseau certifié au Cameroun.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Continuer"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
