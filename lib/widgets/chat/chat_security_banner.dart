import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatSecurityBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const ChatSecurityBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded,
              size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation sécurisée FormelPro',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Convenez des détails ici, puis utilisez Proforma pour formaliser la prestation. Ne partagez jamais votre argent en dehors de l\'app.',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF3B82F6),
                      height: 1.4),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
