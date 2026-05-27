import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';
import 'package:formelpro/screens/booking/technician_selection_page.dart';
import 'package:formelpro/utils/distance_utils.dart';
import 'package:formelpro/widgets/expert_card.dart';

class ExpertsPresWidget extends StatefulWidget {
  final String pays;
  final String? commune;
  final Color accentColor;
  final String? clientId;
  final double? clientLat;
  final double? clientLng;

  const ExpertsPresWidget({
    super.key,
    required this.pays,
    required this.accentColor,
    this.commune,
    this.clientId,
    this.clientLat,
    this.clientLng,
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
            'commune, ville, disponible, est_en_ligne, is_premium, is_identite_verifiee, '
            'latitude, longitude',
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
          .limit(20);

      List<Map<String, dynamic>> experts =
          List<Map<String, dynamic>>.from(data);

      // 5.6 — Matching proximité : trier par distance quand coords client disponibles
      if (widget.clientLat != null && widget.clientLng != null) {
        experts.sort((a, b) {
          final da = DistanceUtils.fromTechData(
              widget.clientLat, widget.clientLng, a);
          final db = DistanceUtils.fromTechData(
              widget.clientLat, widget.clientLng, b);
          // Online toujours en premier
          final aOnline = a['est_en_ligne'] == true ? 0 : 1;
          final bOnline = b['est_en_ligne'] == true ? 0 : 1;
          if (aOnline != bOnline) return aOnline.compareTo(bOnline);
          // Puis par distance (sans coordonnées → fin de liste)
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      }

      if (mounted) {
        setState(() {
          _experts = experts;
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
                        clientLat: widget.clientLat,
                        clientLng: widget.clientLng,
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
                      itemBuilder: (context, i) => ExpertCard(
                        tech: _experts[i],
                        accentColor: widget.accentColor,
                        distanceKm: DistanceUtils.fromTechData(
                            widget.clientLat, widget.clientLng, _experts[i]),
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

