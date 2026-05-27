import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'carte_technicien_badges.dart';

class CarteTechnicien extends StatefulWidget {
  final Map<String, dynamic> tech;
  final VoidCallback onTap;
  final Color accentColor;
  final String? clientId;
  final double? distanceKm;

  const CarteTechnicien({
    super.key,
    required this.tech,
    required this.onTap,
    required this.accentColor,
    this.clientId,
    this.distanceKm,
  });

  @override
  State<CarteTechnicien> createState() => _CarteTechnicienState();
}

class _CarteTechnicienState extends State<CarteTechnicien> {
  final _supabase = Supabase.instance.client;
  bool _isFavori = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) _checkFavori();
  }

  Future<void> _checkFavori() async {
    try {
      final result = await _supabase
          .from('favoris')
          .select('client_id')
          .eq('client_id', widget.clientId!)
          .eq('tech_id', widget.tech['id'].toString())
          .maybeSingle();
      if (mounted) setState(() => _isFavori = result != null);
    } catch (e) {
      debugPrint('Erreur check favori: $e');
    }
  }

  Future<void> _toggleFavori() async {
    if (widget.clientId == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      if (_isFavori) {
        await _supabase
            .from('favoris')
            .delete()
            .eq('client_id', widget.clientId!)
            .eq('tech_id', widget.tech['id'].toString());
      } else {
        await _supabase.from('favoris').insert({
          'client_id': widget.clientId!,
          'tech_id': widget.tech['id'].toString(),
        });
      }
      if (mounted) setState(() => _isFavori = !_isFavori);
    } catch (e) {
      debugPrint('Erreur toggle favori: $e');
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.person_rounded, color: widget.accentColor, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = widget.tech['is_premium'] == true;
    final int premiumLevel = (widget.tech['premium_level'] as num?)?.toInt() ?? 1;
    final bool isOnline = widget.tech['est_en_ligne'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPremium
                ? const Color(0xFFFFFDF5)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: isPremium
                ? Border.all(color: const Color(0xFFD4AF37), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: isPremium
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isPremium ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar grand format ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.tech['photo_profil_url'] != null
                        ? Image.network(
                            widget.tech['photo_profil_url'],
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(),
                          )
                        : _buildAvatarFallback(),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + badges
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.tech['nom_complet'] ?? 'Anonyme',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.tech['is_identite_verifiee'] == true) ...[
                          const SizedBox(width: 4),
                          const Tooltip(
                            message: "Identité vérifiée",
                            child: Icon(Icons.verified_rounded,
                                color: Color(0xFF3B82F6), size: 14),
                          ),
                        ],
                        if (isPremium) ...[
                          const SizedBox(width: 4),
                          TechnicianPremiumBadge(level: premiumLevel),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Métier
                    Text(
                      widget.tech['metier_personnalise'] ?? 'Prestataire',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.tech['savoir_faire'] != null &&
                        (widget.tech['savoir_faire'] as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.tech['savoir_faire'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 7),
                    // Note + localisation + distance
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          "${widget.tech['score_global'] ?? '5.0'}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            color: Color(0xFF94A3B8), size: 12),
                        Flexible(
                          child: Text(
                            " ${widget.tech['commune'] ?? widget.tech['ville'] ?? '—'}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.distanceKm != null) ...[
                          const SizedBox(width: 6),
                          TechnicianDistanceBadge(km: widget.distanceKm!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Badge disponibilité
                    TechnicianDisponibiliteBadge(
                      disponible: widget.tech['disponible'] == true,
                      isOnline: isOnline,
                    ),
                    // Badges compétences (max 3)
                    Builder(builder: (_) {
                      final comps = (widget.tech['competences'] as List?)
                              ?.cast<String>() ??
                          [];
                      if (comps.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: comps.take(3).map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.accentColor
                                    .withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: widget.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (widget.clientId != null)
                GestureDetector(
                  onTap: _toggleFavori,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _toggling
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: widget.accentColor),
                          )
                        : Icon(
                            _isFavori
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavori
                                ? Colors.redAccent
                                : Colors.black26,
                            size: 22,
                          ),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.black12, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

