import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ZoneStatsWidget extends StatefulWidget {
  final String pays;
  final String? commune;
  final Color accentColor;

  const ZoneStatsWidget({
    super.key,
    required this.pays,
    this.commune,
    required this.accentColor,
  });

  @override
  State<ZoneStatsWidget> createState() => _ZoneStatsWidgetState();
}

class _ZoneStatsWidgetState extends State<ZoneStatsWidget> {
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final result = await _supabase.rpc('stats_zone', params: {
        'p_pays': widget.pays,
        'p_commune': widget.commune ?? '',
      });
      if (mounted) {
        setState(() {
          _stats = (result as Map?)?.cast<String, dynamic>();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ZoneStats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_stats == null) return const SizedBox.shrink();

    final bool hasCommune =
        widget.commune != null && widget.commune!.isNotEmpty;
    final int online = hasCommune
        ? (_stats!['commune_online'] as num?)?.toInt() ?? 0
        : (_stats!['pays_online'] as num?)?.toInt() ?? 0;
    final int total = (_stats!['pays_total'] as num?)?.toInt() ?? 0;
    final String zoneLabel = hasCommune ? widget.commune! : widget.pays;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online > 0
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFCBD5E1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: online > 0
                ? Text(
                    "$online technicien${online > 1 ? 's' : ''} en ligne · $zoneLabel",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    "Aucun technicien en ligne · $zoneLabel",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$total dispo",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: widget.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
