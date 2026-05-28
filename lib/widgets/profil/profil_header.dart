import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilHeader extends StatelessWidget {
  final Map<String, dynamic> localUserData;
  final Color accentColor;
  final bool uploadEnCours;
  final VoidCallback onUpload;

  const ProfilHeader({
    super.key,
    required this.localUserData,
    required this.accentColor,
    required this.uploadEnCours,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = localUserData['photo_profil_url'];
    final String role = localUserData['role'] ?? 'client';
    final double rating = localUserData['score_global'] != null
        ? double.parse(localUserData['score_global'].toString())
        : 5.0;

    return Column(
      children: [
        GestureDetector(
          onTap: uploadEnCours ? null : onUpload,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              uploadEnCours
                  ? CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      child: CircularProgressIndicator(
                          color: accentColor, strokeWidth: 2),
                    )
                  : CircleAvatar(
                      key: ValueKey(avatarUrl), // force re-render quand URL change
                      radius: 55,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person, size: 55, color: Colors.white24)
                          : null,
                    ),
              if (!uploadEnCours)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: Colors.white),
                ),
              if (localUserData['is_identite_verifiee'] == true)
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "${localUserData['prenom'] ?? ''} ${localUserData['nom_complet'] ?? ''}",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        if (role == 'technicien') ...[
          const SizedBox(height: 5),
          Text(
            (localUserData['metier_personnalise'] ?? "PRESTATAIRE")
                .toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
