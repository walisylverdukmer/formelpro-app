import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAnalyticsPage extends StatefulWidget {
  final Color accentColor;
  const AdminAnalyticsPage({super.key, required this.accentColor});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final _sb = Supabase.instance.client;
  bool _loading = true;

  int _totalTechs = 0, _totalClients = 0;
  int _civTechs = 0, _cmrTechs = 0;
  int _premium = 0, _verifies = 0, _references = 0;
  List<MapEntry<String, int>> _topMetiers = [];
  List<MapEntry<String, int>> _topCommunes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _sb
          .from('utilisateurs')
          .select(
            'role, pays, commune, metier_personnalise, '
            'is_premium, is_identite_verifiee, is_reference_formelpro',
          )
          .neq('is_admin', true)
          .limit(2000);

      final data = List<Map<String, dynamic>>.from(rows as List);

      final techs = data.where((u) => u['role'] == 'technicien').toList();
      final clients = data.where((u) => u['role'] == 'client').toList();

      // Groupement métiers
      final metiersCount = <String, int>{};
      for (final u in techs) {
        final m = (u['metier_personnalise'] as String?)?.trim();
        if (m != null && m.isNotEmpty) {
          metiersCount[m] = (metiersCount[m] ?? 0) + 1;
        }
      }

      // Groupement communes (techniciens seulement)
      final communesCount = <String, int>{};
      for (final u in techs) {
        final c = (u['commune'] as String?)?.trim();
        if (c != null && c.isNotEmpty) {
          communesCount[c] = (communesCount[c] ?? 0) + 1;
        }
      }

      final sortedMetiers = metiersCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedCommunes = communesCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _totalTechs  = techs.length;
          _totalClients = clients.length;
          _civTechs    = techs.where((u) => u['pays'] == 'CIV').length;
          _cmrTechs    = techs.where((u) => u['pays'] == 'CMR').length;
          _premium     = data.where((u) => u['is_premium'] == true).length;
          _verifies    = data.where((u) => u['is_identite_verifiee'] == true).length;
          _references  = data.where((u) => u['is_reference_formelpro'] == true).length;
          _topMetiers  = sortedMetiers.take(10).toList();
          _topCommunes = sortedCommunes.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminAnalytics: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 22),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: accent,
              backgroundColor: const Color(0xFF1E293B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaysSection(accent),
                    const SizedBox(height: 28),
                    _buildQualitySection(accent),
                    const SizedBox(height: 28),
                    _buildMetiersSection(accent),
                    const SizedBox(height: 28),
                    _buildCommunesSection(accent),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaysSection(Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Répartition par pays'),
      const SizedBox(height: 12),
      Row(children: [
        _paysStat('🇨🇮 Côte d\'Ivoire', _civTechs, _totalTechs,
            const Color(0xFFE67E22), 'prestataires'),
        const SizedBox(width: 10),
        _paysStat('🇨🇲 Cameroun', _cmrTechs, _totalTechs,
            const Color(0xFFCE1126), 'prestataires'),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _miniStat('Clients', _totalClients, const Color(0xFF3B82F6)),
            _miniStat('Prestataires', _totalTechs, accent),
            _miniStat('Total', _totalTechs + _totalClients, Colors.white70),
          ],
        ),
      ),
    ]);
  }

  Widget _buildQualitySection(Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Indicateurs qualité'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _qualityCard('Vérifiés', _verifies, _totalTechs,
            const Color(0xFF10B981), Icons.verified_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _qualityCard('Premium', _premium, _totalTechs,
            Colors.amber, Icons.workspace_premium_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _qualityCard('Référencés', _references, _totalTechs,
            Colors.amber, Icons.star_rounded)),
      ]),
    ]);
  }

  Widget _buildMetiersSection(Color accent) {
    if (_topMetiers.isEmpty) return const SizedBox.shrink();
    final maxVal = _topMetiers.first.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Top 10 métiers (prestataires)'),
      const SizedBox(height: 12),
      ..._topMetiers.asMap().entries.map((e) {
        final rank = e.key + 1;
        final entry = e.value;
        final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 22,
                child: Text('$rank',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(entry.key,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${entry.value}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: accent, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accent.withValues(alpha: 0.7)),
                    minHeight: 5,
                  ),
                ),
              ]),
            ),
          ]),
        );
      }),
    ]);
  }

  Widget _buildCommunesSection(Color accent) {
    if (_topCommunes.isEmpty) return const SizedBox.shrink();
    final maxVal = _topCommunes.first.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Top 10 communes actives'),
      const SizedBox(height: 12),
      ..._topCommunes.asMap().entries.map((e) {
        final rank = e.key + 1;
        final entry = e.value;
        final pct = maxVal > 0 ? entry.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 22,
                child: Text('$rank',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(entry.key,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${entry.value}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF06B6D4), fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                    minHeight: 5,
                  ),
                ),
              ]),
            ),
          ]),
        );
      }),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
      );

  Widget _paysStat(
      String label, int count, int total, Color color, String unit) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('$unit · $pct%',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) => Column(children: [
        Text('$value',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
      ]);

  Widget _qualityCard(String label, int value, int total, Color color, IconData icon) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text('$value',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text('$pct%',
            style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
