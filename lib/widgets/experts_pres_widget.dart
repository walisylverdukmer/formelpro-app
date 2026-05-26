import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';
import 'package:formelpro/screens/booking/technician_selection_page.dart';

class ExpertsPresWidget extends StatefulWidget {
  final String pays;
  final String? commune;
  final Color accentColor;
  final String? clientId;

  const ExpertsPresWidget({
    super.key,
    required this.pays,
    required this.accentColor,
    this.commune,
    this.clientId,
  });

  @override
  State<ExpertsPresWidget> createState() => _ExpertsPresWidgetState();
}

class _ExpertsPresWidgetState extends State<ExpertsPresWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _experts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchExperts();
  }

  @override
  void didUpdateWidget(ExpertsPresWidget old) {
    super.didUpdateWidget(old);
    if (old.commune != widget.commune || old.pays != widget.pays) {
      _fetchExperts();
    }
  }

  Future<void> _fetchExperts() async {
    setState(() => _loading = true);
    try {
      var filterQuery = _supabase
          .from('utilisateurs')
          .select(
            'id, nom_complet, metier_personnalise, photo_profil_url, score_global, '
            'commune, ville, disponible, est_en_ligne, is_premium, is_identite_verifiee',
          )
          .eq('role', 'technicien')
          .eq('pays', widget.pays)
          .or('est_en_ligne.eq.true,disponible.eq.true');

      if (widget.commune != null && widget.commune!.isNotEmpty) {
        filterQuery = filterQuery.ilike('commune', '%${widget.commune}%');
      }

      final data = await filterQuery
          .order('est_en_ligne', ascending: false)
          .order('is_premium', ascending: false)
          .order('score_global', ascending: false)
          .limit(12);
      if (mounted) {
        setState(() {
          _experts = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ExpertsPresWidget error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Experts près de vous',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.commune != null && widget.commune!.isNotEmpty)
                    Text(
                      widget.commune!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (!_loading && _experts.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicianSelectionPage(
                        categoryName: 'Disponibles maintenant',
                        categoryId: '',
                        pays: widget.pays,
                        accentColor: widget.accentColor,
                        clientId: widget.clientId,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Voir plus',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: widget.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: _loading
              ? _buildShimmer()
              : _experts.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _experts.length,
                      itemBuilder: (context, i) => _ExpertCard(
                        tech: _experts[i],
                        accentColor: widget.accentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailsTechnicien(
                              tech: _experts[i],
                              accentColor: widget.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.accentColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 36, color: widget.accentColor.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(
              'Aucun expert disponible\ndans votre zone',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final Map<String, dynamic> tech;
  final Color accentColor;
  final VoidCallback onTap;

  const _ExpertCard({
    required this.tech,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline = tech['est_en_ligne'] == true;
    final bool dispo = tech['disponible'] == true;
    final bool isPremium = tech['is_premium'] == true;
    final bool isVerified = tech['is_identite_verifiee'] == true;
    final String? photoUrl = tech['photo_profil_url'] as String?;
    final String nom = tech['nom_complet'] ?? 'Expert';
    final String metier = tech['metier_personnalise'] ?? 'Prestataire';
    final String lieu = tech['commune'] ?? tech['ville'] ?? '';
    final double note =
        (tech['score_global'] as num?)?.toDouble() ?? 5.0;

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
            // Photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
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
                // Badge en ligne / dispo
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StatusBadge(isOnline: isOnline, dispo: dispo),
                ),
                // Badge vérifié
                if (isVerified)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.verified_rounded,
                        color: Color(0xFF3B82F6), size: 16),
                  ),
              ],
            ),
            // Infos
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
                      if (lieu.isNotEmpty) ...[
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

class _StatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool dispo;
  const _StatusBadge({required this.isOnline, required this.dispo});

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
