import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminDocCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isProcessing;
  final Color accentColor;
  final Future<String?> Function(String path) getSignedUrl;
  final void Function(String path, String label) onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const AdminDocCard({
    super.key,
    required this.doc,
    required this.isProcessing,
    required this.accentColor,
    required this.getSignedUrl,
    required this.onView,
    required this.onApprove,
    required this.onReject,
  });

  String _typLabel(String typeDoc) => switch (typeDoc) {
        'cni' => 'CNI',
        'passeport' => 'Passeport',
        'certificat' => 'Certificat',
        'diplome' => 'Diplôme',
        _ => typeDoc.toUpperCase(),
      };

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy • HH:mm', 'fr')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = doc['utilisateurs'] as Map<String, dynamic>? ?? {};
    final String typeDoc = doc['type_document'] as String? ?? '';
    final String docUrl = doc['document_url'] as String? ?? '';
    final String createdAt = doc['created_at'] as String? ?? '';
    final String typLabel = _typLabel(typeDoc);
    final String dateStr =
        createdAt.isNotEmpty ? _formatDate(createdAt) : '—';
    final String? photoUrl = user['photo_profil_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accentColor.withValues(alpha: 0.2),
                  backgroundImage: photoUrl?.isNotEmpty == true
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl?.isNotEmpty != true
                      ? Icon(Icons.person, color: accentColor, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nom_complet'] as String? ?? 'Inconnu',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      Text(
                        user['metier_personnalise'] as String? ?? 'Prestataire',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: accentColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(typLabel,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber)),
                ),
              ],
            ),
          ),
          if (docUrl.isNotEmpty)
            GestureDetector(
              onTap: () => onView(docUrl, typLabel),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 160,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black26,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<String?>(
                      future: getSignedUrl(docUrl),
                      builder: (_, snap) {
                        if (snap.hasData && snap.data != null) {
                          return Image.network(snap.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        color: Colors.white24, size: 40),
                                  ));
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.zoom_in_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.white24),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(dateStr,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white24)),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text('Refuser',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text('Valider',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
