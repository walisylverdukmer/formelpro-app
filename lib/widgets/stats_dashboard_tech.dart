import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsDashboardTech extends StatefulWidget {
  final String uid;
  final Color accentColor;
  final double scoreGlobal;

  const StatsDashboardTech({
    super.key,
    required this.uid,
    required this.accentColor,
    required this.scoreGlobal,
  });

  @override
  State<StatsDashboardTech> createState() => _StatsDashboardTechState();
}

class _StatsDashboardTechState extends State<StatsDashboardTech> {
  bool _loading = true;
  int _totalRevenus = 0;
  int _totalTerminees = 0;
  int _enCours = 0;
  List<int> _countsByMonth = List.filled(6, 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final supabase = Supabase.instance.client;
      final results = await Future.wait([
        supabase
            .from('interventions')
            .select('montant_final, date_creation')
            .eq('tech_id', widget.uid)
            .eq('statut', 'termine'),
        supabase
            .from('interventions')
            .select('id')
            .eq('tech_id', widget.uid)
            .inFilter('statut', ['accepte', 'en_cours']),
      ]);

      final terminees = results[0] as List;
      final actives = results[1] as List;

      int revenus = 0;
      final Map<String, int> parMois = {};
      final now = DateTime.now();

      for (final m in terminees) {
        revenus += (m['montant_final'] ?? 0) as int;
        if (m['date_creation'] != null) {
          final dt = DateTime.parse(m['date_creation'].toString());
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          parMois[key] = (parMois[key] ?? 0) + 1;
        }
      }

      final countsByMonth = List.generate(6, (i) {
        final d = DateTime(now.year, now.month - 5 + i);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        return parMois[key] ?? 0;
      });

      if (mounted) {
        setState(() {
          _totalRevenus = revenus;
          _totalTerminees = terminees.length;
          _enCours = actives.length;
          _countsByMonth = countsByMonth;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur stats tech: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatMontant(int val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}k';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                label: 'Revenus totaux',
                value: '${_formatMontant(_totalRevenus)} FCFA',
                icon: Icons.payments_rounded,
                accent: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                label: 'Missions faites',
                value: '$_totalTerminees',
                icon: Icons.task_alt_rounded,
                accent: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                label: 'En cours',
                value: '$_enCours',
                icon: Icons.pending_actions_rounded,
                accent: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                label: 'Réputation',
                value: '${widget.scoreGlobal.toStringAsFixed(1)} ★',
                icon: Icons.stars_rounded,
                accent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildChart(),
      ],
    );
  }

  Widget _buildCard({
    required String label,
    required String value,
    required IconData icon,
    required bool accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: accent
            ? LinearGradient(
                colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.75)],
              )
            : null,
        color: accent ? null : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent ? Colors.white : Colors.white38, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: accent ? Colors.white70 : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final now = DateTime.now();
    const monthNames = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    final labels = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i);
      return monthNames[d.month - 1];
    });

    final maxCount = _countsByMonth.reduce(max).clamp(1, 999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVITÉ — 6 DERNIERS MOIS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white24,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final count = _countsByMonth[i];
              final barH = count == 0
                  ? 4.0
                  : (count / maxCount * 56).clamp(4.0, 56.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barH,
                    decoration: BoxDecoration(
                      color: count > 0 ? widget.accentColor : Colors.white12,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
