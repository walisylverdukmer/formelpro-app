import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProformaCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final Color accentColor;
  final void Function(String msgId, String content) onAccept;

  const ProformaCard({
    super.key,
    required this.msg,
    required this.isMe,
    required this.accentColor,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final lines = (msg['contenu'] as String? ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.startsWith('📋'))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.description_rounded, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'PROPOSITION DE PRESTATION',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: accentColor,
                  letterSpacing: 0.5),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(line,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: const Color(0xFF334155))),
                ),
              )),
          const SizedBox(height: 10),
          if (!isMe) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 14, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Validez toujours dans FormelPro. Les paiements hors application ne sont pas couverts.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF3B82F6),
                            height: 1.4),
                      ),
                    ),
                  ]),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    onAccept(msg['id'] as String, msg['contenu'] as String),
                icon: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  "Accepter l'offre",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'En attente de confirmation du client...',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: accentColor),
              ),
            ),
        ],
      ),
    );
  }
}
