import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Filtre rôle / statut ────────────────────────────────────────────────────
enum _RoleFiltre { tous, clients, techniciens, hatf, sensibles }
enum _VerifFiltre { tous, verifies, nonVerifies }

// ─── Page principale ─────────────────────────────────────────────────────────
class ContactsAdminPage extends StatefulWidget {
  final Color accentColor;
  const ContactsAdminPage({super.key, required this.accentColor});

  @override
  State<ContactsAdminPage> createState() => _ContactsAdminPageState();
}

class _ContactsAdminPageState extends State<ContactsAdminPage> {
  final _sb = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const _limit = 50;

  _RoleFiltre _role = _RoleFiltre.tous;
  _VerifFiltre _verif = _VerifFiltre.tous;
  String _pays = 'Tous';
  bool _recents = false;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Sécurité : vérifie is_admin avant tout chargement ───────────────────────
  Future<void> _verifyAdmin() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { if (mounted) Navigator.pop(context); return; }
    final row = await _sb.from('utilisateurs')
        .select('is_admin').eq('id', uid).maybeSingle();
    if (row?['is_admin'] != true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Accès refusé'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }
    _load(reset: true);
  }

  // ── Chargement paginé avec filtres serveur ───────────────────────────────────
  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() { _loading = true; _offset = 0; _data = []; _hasMore = true; });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      var q = _sb.from('utilisateurs')
          .select('id, nom_complet, prenom, telephone, email, role, '
              'metier_personnalise, commune, quartier, ville, pays, '
              'created_at, is_identite_verifiee, is_suspendu')
          .neq('is_admin', true);

      // Filtres serveur
      if (_pays == 'CIV') q = q.eq('pays', 'CIV');
      if (_pays == 'CMR') q = q.eq('pays', 'CMR');

      switch (_role) {
        case _RoleFiltre.clients:
          q = q.eq('role', 'client'); break;
        case _RoleFiltre.techniciens:
        case _RoleFiltre.hatf:
        case _RoleFiltre.sensibles:
          q = q.eq('role', 'technicien'); break;
        default: break;
      }

      if (_verif == _VerifFiltre.verifies) q = q.eq('is_identite_verifiee', true);
      if (_verif == _VerifFiltre.nonVerifies) q = q.eq('is_identite_verifiee', false);

      if (_recents) {
        q = q.gte('created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      }

      final rows = await q
          .order('created_at', ascending: false)
          .range(_offset, _offset + _limit - 1);

      final list = List<Map<String, dynamic>>.from(rows as List);
      if (mounted) {
        setState(() {
          if (reset) { _data = list; } else { _data.addAll(list); }
          _offset += list.length;
          _hasMore = list.length == _limit;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('ContactsAdmin: $e');
      if (mounted) setState(() { _loading = false; _loadingMore = false; });
    }
  }

  // ── Filtre local (search + HATF/sensibles) ───────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    var list = _data;

    if (_role == _RoleFiltre.hatf) {
      list = list.where((c) {
        final m = (c['metier_personnalise'] ?? '').toString().toLowerCase();
        return m.contains('tout faire') || m.contains('bricolage') ||
            m.contains('polyvalent') || m.contains('montage') || m.contains('multi');
      }).toList();
    } else if (_role == _RoleFiltre.sensibles) {
      list = list.where((c) {
        final m = (c['metier_personnalise'] ?? '').toString().toLowerCase();
        return m.contains('ménag') || m.contains('servante') ||
            m.contains('serveuse') || m.contains('cuisine') || m.contains('domestique');
      }).toList();
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
          (c['nom_complet'] ?? '').toString().toLowerCase().contains(q) ||
          (c['prenom'] ?? '').toString().toLowerCase().contains(q) ||
          (c['telephone'] ?? '').toString().contains(q) ||
          (c['email'] ?? '').toString().toLowerCase().contains(q) ||
          (c['commune'] ?? '').toString().toLowerCase().contains(q) ||
          (c['metier_personnalise'] ?? '').toString().toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  // ── Utilitaires ──────────────────────────────────────────────────────────────
  static String fmtDate(dynamic v) {
    if (v == null) return '';
    try {
      final d = DateTime.parse(v.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return ''; }
  }

  static String _q(dynamic v) {
    if (v == null) return '""';
    return '"${v.toString().replaceAll('"', '""')}"';
  }

  Future<void> _call(String? tel) async {
    if (tel == null || tel.isEmpty) return;
    await launchUrl(Uri.parse('tel:$tel'));
  }

  Future<void> _whatsapp(String? tel) async {
    if (tel == null || tel.isEmpty) return;
    final clean = tel.replaceAll(RegExp(r'[^\d+]'), '');
    await launchUrl(Uri.parse('https://wa.me/$clean'),
        mode: LaunchMode.externalApplication);
  }

  void _exportCsv() {
    if (!kIsWeb) {
      _snack('Export CSV disponible sur la version web uniquement');
      return;
    }
    final buf = StringBuffer();
    buf.writeln('Nom,Prénom,Téléphone,Email,Rôle,Métier,'
        'Commune,Quartier,Pays,Date inscription,Vérifié,Suspendu');
    for (final c in _filtered) {
      buf.writeln([
        _q(c['nom_complet']), _q(c['prenom']), _q(c['telephone']),
        _q(c['email']), _q(c['role']), _q(c['metier_personnalise']),
        _q(c['commune']), _q(c['quartier']), _q(c['pays']),
        _q(fmtDate(c['created_at'])),
        c['is_identite_verifiee'] == true ? 'Oui' : 'Non',
        c['is_suspendu'] == true ? 'Oui' : 'Non',
      ].join(','));
    }
    final encoded = Uri.encodeComponent(buf.toString());
    launchUrl(Uri.parse('data:text/csv;charset=utf-8,$encoded'));
    _snack('Export en cours...');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build principal ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contacts & Inscriptions',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A))),
            Text('${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: accent, size: 22),
            tooltip: 'Exporter CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: accent, size: 22),
            onPressed: () => _load(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(accent),
          _buildFilters(accent),
          Expanded(child: _buildList(accent, filtered)),
        ],
      ),
    );
  }

  // ── Barre de recherche ───────────────────────────────────────────────────────
  Widget _buildSearch(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Nom, téléphone, email, commune, métier...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF94A3B8), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18,
                      color: Color(0xFF94A3B8)),
                  onPressed: _searchCtrl.clear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // ── Filtres ──────────────────────────────────────────────────────────────────
  Widget _buildFilters(Color accent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          children: [
            // Rôle chips
            ..._RoleFiltre.values.map((f) => _roleChip(f, accent)),
            _divider(),
            // Vérif chips
            ..._VerifFiltre.values.map((f) => _verifChip(f, accent)),
            _divider(),
            // Pays chips
            ...['Tous', 'CIV', 'CMR'].map((p) => _paysChip(p, accent)),
            _divider(),
            // Récents toggle
            _toggleChip('Récents 30j', _recents, accent, () {
              setState(() => _recents = !_recents);
              _load(reset: true);
            }),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 22, color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _roleChip(_RoleFiltre f, Color accent) {
    const labels = {
      _RoleFiltre.tous: 'Tous',
      _RoleFiltre.clients: 'Clients',
      _RoleFiltre.techniciens: 'Techniciens',
      _RoleFiltre.hatf: 'HATF',
      _RoleFiltre.sensibles: 'Sensibles',
    };
    final sel = _role == f;
    return _chip(labels[f]!, sel, accent, () {
      setState(() => _role = f);
      _load(reset: true);
    });
  }

  Widget _verifChip(_VerifFiltre f, Color accent) {
    const labels = {
      _VerifFiltre.tous: 'Tout statut',
      _VerifFiltre.verifies: '✅ Vérifiés',
      _VerifFiltre.nonVerifies: '⏳ Non vérifiés',
    };
    final sel = _verif == f;
    return _chip(labels[f]!, sel, const Color(0xFF3B82F6), () {
      setState(() => _verif = f);
      _load(reset: true);
    });
  }

  Widget _paysChip(String pays, Color accent) {
    final sel = _pays == pays;
    final label = pays == 'CIV' ? '🇨🇮 CIV' : pays == 'CMR' ? '🇨🇲 CMR' : pays;
    return _chip(label, sel, const Color(0xFF0F172A), () {
      setState(() => _pays = pays);
      _load(reset: true);
    });
  }

  Widget _toggleChip(String label, bool active, Color accent, VoidCallback onTap) =>
      _chip(label, active, Colors.purple, onTap);

  Widget _chip(String label, bool sel, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ── Liste contacts ───────────────────────────────────────────────────────────
  Widget _buildList(Color accent, List<Map<String, dynamic>> filtered) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: accent, strokeWidth: 2));
    }
    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.contacts_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Aucun contact',
              style: GoogleFonts.inter(
                  color: Colors.grey.shade400, fontSize: 14)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        itemCount: filtered.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == filtered.length) {
            if (_loadingMore) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton(
                onPressed: () => _load(reset: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Charger plus',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            );
          }
          final c = filtered[i];
          return _ContactCard(
            contact: c,
            accentColor: accent,
            onTap: () => _showDetail(c),
            onCall: () => _call(c['telephone']),
            onWhatsApp: () => _whatsapp(c['telephone']),
          );
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(
        contact: c,
        accentColor: widget.accentColor,
        onCall: () { Navigator.pop(context); _call(c['telephone']); },
        onWhatsApp: () { Navigator.pop(context); _whatsapp(c['telephone']); },
      ),
    );
  }
}

// ─── Card contact (liste) ─────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _ContactCard({
    required this.contact, required this.accentColor,
    required this.onTap, required this.onCall, required this.onWhatsApp,
  });

  String get _nom => [contact['prenom'], contact['nom_complet']]
      .where((s) => s != null && s.toString().isNotEmpty).join(' ');
  String get _initials => _nom.trim().isNotEmpty ? _nom.trim()[0].toUpperCase() : '?';
  bool get _isTech => (contact['role'] ?? '') == 'technicien';
  bool get _verified => contact['is_identite_verifiee'] == true;
  bool get _suspendu => contact['is_suspendu'] == true;
  bool get _hasTel => (contact['telephone'] ?? '').toString().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final roleColor = _isTech ? accentColor : const Color(0xFF3B82F6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _suspendu ? Colors.red.shade100 : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withValues(alpha: 0.12),
              child: Text(_initials,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold, color: roleColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      _nom.isEmpty ? 'Sans nom' : _nom,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_verified) const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(Icons.verified_rounded,
                        color: Color(0xFF3B82F6), size: 15),
                  ),
                  if (_suspendu) const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.block_rounded, color: Colors.red, size: 13),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  _badge(_isTech ? 'Technicien' : 'Client', roleColor),
                  if (_isTech && (contact['metier_personnalise'] ?? '').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contact['metier_personnalise'],
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 5, children: [
            if (_hasTel) _info(Icons.phone_rounded, contact['telephone']),
            if ((contact['commune'] ?? '').isNotEmpty)
              _info(Icons.location_on_outlined,
                  '${contact['commune']} · ${contact['pays'] ?? ''}'),
            _info(Icons.calendar_today_outlined,
                _ContactsAdminPageState.fmtDate(contact['created_at'])),
          ]),
          if (_hasTel) ...[
            const SizedBox(height: 10),
            Row(children: [
              _actionBtn(Icons.phone_rounded, 'Appeler',
                  const Color(0xFF10B981), onCall),
              const SizedBox(width: 8),
              _actionBtn(Icons.chat_rounded, 'WhatsApp',
                  const Color(0xFF25D366), onWhatsApp),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _info(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
    ],
  );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}

// ─── Bottom sheet détail contact ──────────────────────────────────────────────
class _ContactSheet extends StatelessWidget {
  final Map<String, dynamic> contact;
  final Color accentColor;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _ContactSheet({
    required this.contact, required this.accentColor,
    required this.onCall, required this.onWhatsApp,
  });

  String get _nom => [contact['prenom'], contact['nom_complet']]
      .where((s) => s != null && s.toString().isNotEmpty).join(' ');
  String get _initials => _nom.trim().isNotEmpty ? _nom.trim()[0].toUpperCase() : '?';
  bool get _isTech => (contact['role'] ?? '') == 'technicien';

  @override
  Widget build(BuildContext context) {
    final roleColor = _isTech ? accentColor : const Color(0xFF3B82F6);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: roleColor.withValues(alpha: 0.12),
              child: Text(_initials,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: roleColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_nom.isEmpty ? 'Sans nom' : _nom,
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A))),
                Text(
                  _isTech
                      ? (contact['metier_personnalise'] ?? 'Technicien')
                      : 'Client',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: accentColor,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          _section('Coordonnées'),
          _row(Icons.phone_rounded, 'Téléphone', contact['telephone']),
          _row(Icons.email_outlined, 'Email', contact['email']),
          const SizedBox(height: 16),
          _section('Localisation'),
          _row(Icons.location_city_rounded, 'Commune', contact['commune']),
          _row(Icons.map_outlined, 'Quartier', contact['quartier']),
          _row(Icons.store_rounded, 'Ville', contact['ville']),
          _row(Icons.public_rounded, 'Pays',
              contact['pays'] == 'CIV'
                  ? '🇨🇮 Côte d\'Ivoire'
                  : contact['pays'] == 'CMR'
                      ? '🇨🇲 Cameroun'
                      : contact['pays']),
          const SizedBox(height: 16),
          _section('Statut compte'),
          _row(Icons.verified_rounded, 'Identité vérifiée',
              contact['is_identite_verifiee'] == true ? '✅ Oui' : '❌ Non'),
          _row(Icons.block_rounded, 'Suspendu',
              contact['is_suspendu'] == true ? '⚠️ Suspendu' : '✅ Actif'),
          _row(Icons.calendar_today_rounded, 'Inscrit le',
              _ContactsAdminPageState.fmtDate(contact['created_at'])),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone_rounded, size: 16),
                label: Text('Appeler',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: Text('WhatsApp',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
  );

  Widget _row(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFF94A3B8))),
            Text(value.toString(),
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A))),
          ]),
        ),
      ]),
    );
  }
}
