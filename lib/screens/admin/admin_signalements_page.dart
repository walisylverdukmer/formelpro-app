import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSignalementsPage extends StatefulWidget {
  final Color accentColor;

  const AdminSignalementsPage({super.key, required this.accentColor});

  @override
  State<AdminSignalementsPage> createState() => _AdminSignalementsPageState();
}

class _AdminSignalementsPageState extends State<AdminSignalementsPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _onlyPending = true;
  List<Map<String, dynamic>> _signalements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var query = _supabase
          .from('signalements')
          .select('id, raison, statut, created_at, signale_par, utilisateur_signale');

      if (_onlyPending) query = query.eq('statut', 'en_attente');

      final rows = await query.order('created_at', ascending: false).limit(100);
      final data = List<Map<String, dynamic>>.from(rows as List);

      if (data.isEmpty) {
        if (mounted) setState(() { _signalements = []; _loading = false; });
        return;
      }

      final allIds = data
          .expand((r) => [r['signale_par'] as String?, r['utilisateur_signale'] as String?])
          .whereType<String>()
          .toSet()
          .toList();

      final profiles = await _supabase
          .from('utilisateurs')
          .select('id, nom_complet, photo_profil_url')
          .inFilter('id', allIds);

      final profileMap = <String, Map<String, dynamic>>{
        for (final p in (profiles as List)) p['id'] as String: p as Map<String, dynamic>
      };

      final enriched = data.map((r) => {
        ...r,
        '_reporter': profileMap[r['signale_par'] as String?] ?? {},
        '_reported': profileMap[r['utilisateur_signale'] as String?] ?? {},
      }).toList();

      if (mounted) setState(() { _signalements = enriched; _loading = false; });
    } catch (e) {
      debugPrint('Admin signalements erreur: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatut(String id, String statut) async {
    try {
      await _supabase.from('signalements').update({'statut': statut}).eq('id', id);
      if (mounted) {
        setState(() {
          final idx = _signalements.indexWhere((s) => s['id'] == id);
          if (idx != -1) {
            if (_onlyPending) {
              _signalements.removeAt(idx);
            } else {
              _signalements[idx] = {..._signalements[idx], 'statut': statut};
            }
          }
        });
        _showSnack(statut == 'traite' ? "Marqué comme traité" : "Signalement fermé");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Signalements",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            if (!_loading)
              Text("${_signalements.length} résultats",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text("En attente",
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onlyPending ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600)),
              selected: _onlyPending,
              onSelected: (v) {
                setState(() => _onlyPending = v);
                _load();
              },
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              selectedColor: widget.accentColor.withValues(alpha: 0.25),
              checkmarkColor: widget.accentColor,
              side: BorderSide(
                  color: _onlyPending
                      ? widget.accentColor.withValues(alpha: 0.5)
                      : Colors.white12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _signalements.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accentColor,
                  backgroundColor: const Color(0xFF1E293B),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _signalements.length,
                    itemBuilder: (_, i) => _buildCard(_signalements[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final reporter = s['_reporter'] as Map<String, dynamic>? ?? {};
    final reported = s['_reported'] as Map<String, dynamic>? ?? {};
    final String statut = s['statut'] as String? ?? 'en_attente';
    final String id = s['id'] as String;
    final String raison = s['raison'] as String? ?? '—';
    final String? raw = s['created_at'] as String?;
    final String dateStr = raw != null
        ? DateFormat('d MMM yyyy • HH:mm', 'fr')
            .format(DateTime.parse(raw).toLocal())
        : '—';

    final Color statutColor = switch (statut) {
      'traite' => Colors.greenAccent,
      'ferme' => Colors.white38,
      _ => Colors.amber,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statut == 'en_attente' ? 'En attente' : statut == 'traite' ? 'Traité' : 'Fermé',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: statutColor),
                  ),
                ),
                const Spacer(),
                Text(dateStr,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(raison,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.4)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _buildUserChip("Signaleur", reporter, Colors.blue),
                const SizedBox(width: 10),
                _buildUserChip("Signalé", reported, Colors.redAccent),
              ],
            ),
          ),

          if (statut == 'en_attente')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatut(id, 'ferme'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white38,
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text("Fermer",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatut(id, 'traite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text("Traité",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildUserChip(String label, Map<String, dynamic> user, Color color) {
    final String name = user['nom_complet'] as String? ?? 'Inconnu';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.15),
              backgroundImage: (user['photo_profil_url'] as String?)?.isNotEmpty == true
                  ? NetworkImage(user['photo_profil_url'] as String)
                  : null,
              child: (user['photo_profil_url'] as String?)?.isNotEmpty != true
                  ? Icon(Icons.person, color: color, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          color: color.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text("Aucun signalement",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            _onlyPending
                ? "Aucun signalement en attente de traitement."
                : "Aucun signalement enregistré.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
