import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:formelpro/utils/distance_utils.dart';
import 'package:formelpro/widgets/carte_technicien_badges.dart';

class TechnicienCard extends StatelessWidget {
  final Map<String, dynamic> tech;
  final Color accentColor;
  final VoidCallback onTap;
  final double? distanceKm;

  const TechnicienCard({
    super.key,
    required this.tech,
    required this.accentColor,
    required this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline = tech['est_en_ligne'] == true;
    final bool dispo = tech['disponible'] == true;
    final bool isPremium = tech['is_premium'] == true;
    final bool isVerified = tech['is_identite_verifiee'] == true;
    final String? photoUrl = tech['photo_profil_url'] as String?;
    final String nom = tech['nom_complet'] ?? 'Technicien';
    final String metier = tech['metier_personnalise'] ?? 'Prestataire';
    final String lieu = tech['commune'] ?? tech['ville'] ?? '';
    final double note = (tech['score_global'] as num?)?.toDouble() ?? 5.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPremium
              ? Border.all(color: const Color(0xFFD4AF37), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isPremium ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 108,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: TechnicienStatusBadge(isOnline: isOnline, dispo: dispo),
                ),
                if (isVerified)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.verified_rounded,
                        color: Color(0xFF3B82F6), size: 16),
                  ),
                if (isPremium)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: TechnicianPremiumBadge(
                      level: (tech['premium_level'] as num?)?.toInt() ?? 1,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metier,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        note.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.near_me_rounded,
                            size: 10, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            DistanceUtils.format(distanceKm!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B82F6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (lieu.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lieu,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      height: 108,
      color: accentColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.person_rounded,
            color: accentColor.withValues(alpha: 0.4), size: 44),
      ),
    );
  }
}

class TechnicienStatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool dispo;

  const TechnicienStatusBadge({
    super.key,
    required this.isOnline,
    required this.dispo,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isOnline
        ? const Color(0xFF22C55E)
        : dispo
            ? const Color(0xFF3B82F6)
            : const Color(0xFF94A3B8);
    final String label = isOnline ? 'En ligne' : dispo ? 'Dispo' : '';
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
