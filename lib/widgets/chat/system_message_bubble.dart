import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemMessageBubble extends StatelessWidget {
  final String text;

  const SystemMessageBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isSuccess = text.contains('ACCEPTÉE') || text.contains('enregistrée');
    final color =
        isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final bg = isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final icon = isSuccess
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _cleanText(text),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSuccess
                        ? const Color(0xFF166534)
                        : const Color(0xFF991B1B),
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll('✅ ', '')
        .replaceAll('❌ ', '')
        .trim();
  }
}
