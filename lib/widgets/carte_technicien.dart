import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarteTechnicien extends StatefulWidget {
  final Map<String, dynamic> tech;
  final VoidCallback onTap;
  final Color accentColor;
  final String? clientId;

  const CarteTechnicien({
    super.key,
    required this.tech,
    required this.onTap,
    required this.accentColor,
    this.clientId,
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
          padding: const EdgeInsets.all(12),
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
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: widget.accentColor.withValues(alpha: 0.1),
                    backgroundImage: widget.tech['photo_profil_url'] != null
                        ? NetworkImage(widget.tech['photo_profil_url'])
                        : null,
                    child: widget.tech['photo_profil_url'] == null
                        ? Icon(Icons.person, color: widget.accentColor)
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 12,
                        height: 12,
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
                          _PremiumBadge(level: premiumLevel),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
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
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
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
                            color: Color(0xFF94A3B8), size: 13),
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
                      ],
                    ),
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

class _PremiumBadge extends StatelessWidget {
  final int level;
  const _PremiumBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level >= 2
                ? Icons.workspace_premium_rounded
                : Icons.star_rounded,
            color: Colors.white,
            size: 9,
          ),
          const SizedBox(width: 2),
          Text(
            level >= 2 ? "Pro" : "Premium",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
