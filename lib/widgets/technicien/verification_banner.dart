import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationBanner extends StatelessWidget {
  final bool isVerifie;
  final Color accentColor;
  final VoidCallback onVerify;

  const VerificationBanner({
    super.key,
    required this.isVerifie,
    required this.accentColor,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    if (isVerifie) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: Colors.greenAccent, size: 18),
            const SizedBox(width: 10),
            Text(
              "Identité validée — badge actif",
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onVerify,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vérifiez votre identité",
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Gagnez en visibilité et accédez aux missions premium",
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }
}
