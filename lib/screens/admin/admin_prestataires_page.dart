import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Filtre { tous, premium, verifies, references, suspendus }

class AdminPrestatairesPage extends StatefulWidget {
  final Color accentColor;
  const AdminPrestatairesPage({super.key, required this.accentColor});

  @override
  State<AdminPrestatairesPage> createState() => _AdminPrestatairesPageState();
}

class _AdminPrestatairesPageState extends State<AdminPrestatairesPage> {
  final _sb = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  final Set<String> _processing = {};
  _Filtre _filtre = _Filtre.tous;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _sb
          .from('utilisateurs')
          .select(
            'id, nom_complet, telephone, pays, commune, photo_profil_url, '
            'metier_personnalise, is_suspendu, is_premium, premium_until, '
            'is_identite_verifiee, is_reference_formelpro, '
            'score_global, total_transactions, est_en_ligne',
          )
          .eq('role', 'technicien')
          .neq('is_admin', true)
          .order('nom_complet')
          .limit(500);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminPrestataires: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _data;
    switch (_filtre) {
      case _Filtre.premium:
        list = list.where((u) => u['is_premium'] == true).toList();
      case _Filtre.verifies:
        list = list.where((u) => u['is_identite_verifiee'] == true).toList();
      case _Filtre.references:
        list = list.where((u) => u['is_reference_formelpro'] == true).toList();
      case _Filtre.suspendus:
        list = list.where((u) => u['is_suspendu'] == true).toList();
      case _Filtre.tous:
        break;
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) =>
          (u['nom_complet'] ?? '').toString().toLowerCase().contains(q) ||
          (u['telephone'] ?? '').toString().contains(q) ||
          (u['metier_personnalise'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _toggle(String id, String field, bool newVal) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    try {
      final update = <String, dynamic>{field: newVal};
      if (field == 'is_premium' && !newVal) update['premium_until'] = null;
      await _sb.from('utilisateurs').update(update).eq('id', id);
      if (mounted) {
        final idx = _data.indexWhere((u) => u['id'] == id);
        if (idx != -1) setState(() => _data[idx] = {..._data[idx], ...update});
        _snack(_label(field, newVal));
      }
    } catch (e) {
      if (mounted) _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _extendPremium(String id, String? currentUntil) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    try {
      DateTime base;
      try {
        base = currentUntil != null ? DateTime.parse(currentUntil) : DateTime.now();
      } catch (_) {
        base = DateTime.now();
      }
      final next = base.isAfter(DateTime.now()) ? base : DateTime.now();
      final newUntil = next.add(const Duration(days: 30));
      await _sb.from('utilisateurs').update({
        'is_premium': true,
        'premium_until': newUntil.toIso8601String(),
      }).eq('id', id);
      if (mounted) {
        final idx = _data.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          setState(() => _data[idx] = {
            ..._data[idx],
            'is_premium': true,
            'premium_until': newUntil.toIso8601String(),
          });
        }
        _snack('Premium prolongé → ${DateFormat('dd/MM/yyyy').format(newUntil)}');
      }
    } catch (e) {
      if (mounted) _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  String _label(String field, bool v) => switch (field) {
        'is_suspendu' => v ? 'Compte suspendu' : 'Compte réactivé',
        'is_premium' => v ? 'Premium activé' : 'Premium retiré',
        'is_identite_verifiee' => v ? 'Badge Vérifié accordé' : 'Badge Vérifié retiré',
        'is_reference_formelpro' => v ? '⭐ Référencement FormelPro accordé' : 'Référencement retiré',
        _ => 'Mis à jour',
      };

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ));

  void _showActions(Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionsSheet(
        user: u,
        accent: widget.accentColor,
        isProcessing: _processing.contains(u['id'] as String),
        onToggle: (field, val) { Navigator.pop(context); _toggle(u['id'] as String, field, val); },
        onExtend: () { Navigator.pop(context); _extendPremium(u['id'] as String, u['premium_until'] as String?); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final filtered = _filtered;
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
          Text('Gestion Prestataires',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          if (!_loading)
            Text('${filtered.length} prestataire${filtered.length > 1 ? 's' : ''}',
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
      body: Column(children: [
        _buildSearch(accent),
        _buildFilters(accent),
        Expanded(child: _buildList(accent, filtered)),
      ]),
    );
  }

  Widget _buildSearch(Color accent) => Container(
        color: const Color(0xFF1E293B),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nom, téléphone, métier...',
            hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
        ),
      );

  Widget _buildFilters(Color accent) {
    const labels = {
      _Filtre.tous: 'Tous',
      _Filtre.premium: '⭐ Premium',
      _Filtre.verifies: '✓ Vérifiés',
      _Filtre.references: '⭐ Référencés',
      _Filtre.suspendus: '🚫 Suspendus',
    };
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: _Filtre.values.map((f) {
            final sel = _filtre == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filtre = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? accent : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(labels[f]!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : Colors.white54)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(Color accent, List<Map<String, dynamic>> filtered) {
    if (_loading) return Center(child: CircularProgressIndicator(color: accent));
    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.engineering_outlined, size: 56, color: Colors.white12),
          const SizedBox(height: 14),
          Text('Aucun prestataire',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Aucun résultat pour ce filtre.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _buildTile(filtered[i]),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> u) {
    final name = u['nom_complet'] as String? ?? 'Inconnu';
    final metier = u['metier_personnalise'] as String? ?? '';
    final pays = u['pays'] as String? ?? '';
    final commune = u['commune'] as String? ?? '';
    final photoUrl = u['photo_profil_url'] as String?;
    final isSuspendu = u['is_suspendu'] as bool? ?? false;
    final isPremium = u['is_premium'] as bool? ?? false;
    final isVerifie = u['is_identite_verifiee'] as bool? ?? false;
    final isRef = u['is_reference_formelpro'] as bool? ?? false;
    final isOnline = u['est_en_ligne'] as bool? ?? false;
    final score = (u['score_global'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => _showActions(u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSuspendu
              ? Colors.redAccent.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuspendu
                ? Colors.redAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: widget.accentColor.withValues(alpha: 0.15),
              backgroundImage:
                  photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
              child: photoUrl?.isNotEmpty != true
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                          fontSize: 16))
                  : null,
            ),
            if (isOnline)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
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
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isSuspendu ? Colors.white38 : Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isVerifie)
                  const Padding(padding: EdgeInsets.only(left: 3),
                      child: Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 13)),
                if (isRef)
                  const Padding(padding: EdgeInsets.only(left: 2),
                      child: Icon(Icons.star_rounded, color: Colors.amber, size: 13)),
                if (isPremium)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.workspace_premium_rounded,
                        color: widget.accentColor, size: 13),
                  ),
              ]),
              if (metier.isNotEmpty)
                Text(metier,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: widget.accentColor, fontWeight: FontWeight.w600)),
              Text(
                [if (commune.isNotEmpty) commune, pays].join(' · '),
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (score > 0)
              Row(children: [
                const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                const SizedBox(width: 2),
                Text(score.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w700)),
              ]),
            const SizedBox(height: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
          ]),
        ]),
      ),
    );
  }
}

// ─── Bottom sheet actions prestataire ────────────────────────────────────────

class _ActionsSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final Color accent;
  final bool isProcessing;
  final void Function(String field, bool val) onToggle;
  final VoidCallback onExtend;

  const _ActionsSheet({
    required this.user, required this.accent, required this.isProcessing,
    required this.onToggle, required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['nom_complet'] as String? ?? 'Prestataire';
    final metier = user['metier_personnalise'] as String?;
    final photoUrl = user['photo_profil_url'] as String?;
    final isSuspendu = user['is_suspendu'] as bool? ?? false;
    final isPremium = user['is_premium'] as bool? ?? false;
    final isVerifie = user['is_identite_verifiee'] as bool? ?? false;
    final isRef = user['is_reference_formelpro'] as bool? ?? false;
    final premiumUntil = user['premium_until'] as String?;

    String? premiumExpiry;
    if (isPremium && premiumUntil != null) {
      try {
        premiumExpiry = 'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(premiumUntil).toLocal())}';
      } catch (_) {}
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent.withValues(alpha: 0.15),
            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(name[0].toUpperCase(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: accent, fontSize: 16))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            if (metier != null && metier.isNotEmpty)
              Text(metier, style: GoogleFonts.inter(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
          ])),
          if (isProcessing) const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
        ]),
        const SizedBox(height: 16),
        const Divider(color: Colors.white12),
        const SizedBox(height: 4),
        _Row(icon: isSuspendu ? Icons.lock_open_rounded : Icons.block_rounded,
            label: isSuspendu ? 'Réactiver le compte' : 'Suspendre le compte',
            color: isSuspendu ? Colors.greenAccent : Colors.redAccent,
            onTap: isProcessing ? null : () => onToggle('is_suspendu', !isSuspendu)),
        _Row(icon: isPremium ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
            label: isPremium ? 'Retirer le premium' : 'Activer le premium',
            sublabel: premiumExpiry,
            color: Colors.amber,
            onTap: isProcessing ? null : () => onToggle('is_premium', !isPremium)),
        _Row(icon: Icons.schedule_rounded,
            label: 'Prolonger premium +30 jours',
            color: const Color(0xFF10B981),
            onTap: isProcessing ? null : onExtend),
        _Row(icon: isVerifie ? Icons.gpp_bad_rounded : Icons.verified_rounded,
            label: isVerifie ? 'Retirer le badge Vérifié' : 'Accorder le badge Vérifié ✓',
            color: const Color(0xFF3B82F6),
            onTap: isProcessing ? null : () => onToggle('is_identite_verifiee', !isVerifie)),
        _Row(icon: isRef ? Icons.star_rounded : Icons.star_outline_rounded,
            label: isRef ? 'Retirer le référencement FormelPro' : '⭐ Référencer FormelPro',
            color: Colors.amber,
            onTap: isProcessing ? null : () => onToggle('is_reference_formelpro', !isRef)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback? onTap;

  const _Row({required this.icon, required this.label, required this.color, required this.onTap, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
              if (sublabel != null)
                Text(sublabel!, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white24),
          ]),
        ),
      ),
    );
  }
}
