import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPresencePage extends StatefulWidget {
  final Color accentColor;
  const AdminPresencePage({super.key, required this.accentColor});

  @override
  State<AdminPresencePage> createState() => _AdminPresencePageState();
}

class _AdminPresencePageState extends State<AdminPresencePage> {
  final _sb = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _online = [];
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final since = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

      final results = await Future.wait([
        _sb
            .from('utilisateurs')
            .select('id, nom_complet, role, pays, commune, photo_profil_url, '
                'metier_personnalise, est_en_ligne, disponible, '
                'is_identite_verifiee, is_premium')
            .eq('est_en_ligne', true)
            .neq('is_admin', true)
            .order('role')
            .limit(200),
        _sb
            .from('utilisateurs')
            .select('id, nom_complet, role, pays, photo_profil_url, '
                'metier_personnalise, est_en_ligne, disponible')
            .eq('est_en_ligne', false)
            .neq('is_admin', true)
            .gte('date_inscription', since)
            .order('date_inscription', ascending: false)
            .limit(50),
      ]);

      if (mounted) {
        setState(() {
          _online = List<Map<String, dynamic>>.from(results[0] as List);
          _recent = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminPresence: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final techs = _online.where((u) => u['role'] == 'technicien').toList();
    final clients = _online.where((u) => u['role'] == 'client').toList();
    final dispos = techs.where((u) => u['disponible'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Présence Temps Réel',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Actualisé à ${DateFormat('HH:mm').format(DateTime.now())}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        ]),
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
                    _buildStats(accent, techs.length, clients.length, dispos.length),
                    const SizedBox(height: 24),
                    if (_online.isNotEmpty) ...[
                      _sectionTitle('En ligne maintenant (${_online.length})'),
                      const SizedBox(height: 12),
                      ..._online.map((u) => _buildUserTile(u, online: true)),
                    ],
                    if (_recent.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionTitle('Inscrits récemment — hors ligne'),
                      const SizedBox(height: 12),
                      ..._recent.map((u) => _buildUserTile(u, online: false)),
                    ],
                    if (_online.isEmpty && _recent.isEmpty)
                      _buildEmpty(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStats(Color accent, int techs, int clients, int dispos) {
    return Row(children: [
      _statCard('En ligne', _online.length.toString(), Colors.greenAccent, Icons.wifi_rounded),
      const SizedBox(width: 10),
      _statCard('Prestataires', techs.toString(), accent, Icons.engineering_rounded),
      const SizedBox(width: 10),
      _statCard('Disponibles', dispos.toString(), const Color(0xFF10B981), Icons.check_circle_rounded),
    ]);
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
      );

  Widget _buildUserTile(Map<String, dynamic> u, {required bool online}) {
    final name = u['nom_complet'] as String? ?? 'Inconnu';
    final role = u['role'] as String? ?? 'client';
    final pays = u['pays'] as String? ?? '';
    final commune = u['commune'] as String? ?? '';
    final photoUrl = u['photo_profil_url'] as String?;
    final metier = u['metier_personnalise'] as String?;
    final dispo = u['disponible'] as bool? ?? false;
    final isVerifie = u['is_identite_verifiee'] as bool? ?? false;
    final isPremium = u['is_premium'] as bool? ?? false;
    final isTech = role == 'technicien';
    final roleColor = isTech ? widget.accentColor : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: online
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: roleColor, fontSize: 14))
                : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 9, height: 9,
              decoration: BoxDecoration(
                color: online ? Colors.greenAccent : Colors.white24,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
              if (isVerifie)
                const Padding(padding: EdgeInsets.only(left: 3),
                    child: Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 12)),
              if (isPremium)
                const Padding(padding: EdgeInsets.only(left: 2),
                    child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 12)),
            ]),
            Text(
              isTech
                  ? [if (metier != null && metier.isNotEmpty) metier, pays].join(' · ')
                  : ['Client', pays].join(' · '),
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: online
                  ? Colors.greenAccent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              online ? '🟢 En ligne' : '⚫ Hors ligne',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: online ? Colors.greenAccent : Colors.white38),
            ),
          ),
          if (isTech && online) ...[
            const SizedBox(height: 4),
            Text(
              dispo ? 'Disponible' : 'Occupé',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: dispo ? const Color(0xFF10B981) : Colors.amber,
                  fontWeight: FontWeight.w600),
            ),
          ],
          if (commune.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(commune, style: GoogleFonts.inter(fontSize: 10, color: Colors.white24)),
          ],
        ]),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white12),
          const SizedBox(height: 14),
          Text('Aucun utilisateur en ligne',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Aucune activité détectée pour le moment.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
