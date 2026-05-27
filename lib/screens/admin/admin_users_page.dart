import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  final Color accentColor;
  const AdminUsersPage({super.key, required this.accentColor});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  late TabController _tabController;

  bool _loading = true;
  List<Map<String, dynamic>> _allUsers = [];
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('utilisateurs')
          .select(
            'id, nom_complet, telephone, role, pays, is_suspendu, '
            'is_identite_verifiee, photo_profil_url, metier_personnalise',
          )
          .neq('is_admin', true)
          .order('pays')
          .order('nom_complet')
          .limit(500);

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminUsersPage erreur: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String role) {
    final q = _searchController.text.trim().toLowerCase();
    return _allUsers.where((u) {
      if (u['role'] != role) return false;
      if (q.isEmpty) return true;
      return (u['nom_complet'] as String? ?? '').toLowerCase().contains(q) ||
          (u['telephone'] as String? ?? '').contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _byPays(
      List<Map<String, dynamic>> list, String pays) {
    return list.where((u) => (u['pays'] as String? ?? '') == pays).toList();
  }

  Future<void> _toggleSuspension(Map<String, dynamic> user) async {
    final String id = user['id'] as String;
    final bool current = user['is_suspendu'] as bool? ?? false;
    final bool next = !current;

    final confirmed = await _showConfirm(
      next
          ? "Suspendre ${user['nom_complet'] ?? 'cet utilisateur'} ?"
          : "Réactiver ${user['nom_complet'] ?? 'cet utilisateur'} ?",
      next
          ? "Son compte sera désactivé immédiatement."
          : "Son compte sera restauré.",
      next ? Colors.redAccent : Colors.greenAccent,
      next ? "Suspendre" : "Réactiver",
    );
    if (!confirmed || _processing.contains(id)) return;
    setState(() => _processing.add(id));

    try {
      await _supabase
          .from('utilisateurs')
          .update({'is_suspendu': next}).eq('id', id);

      if (mounted) {
        final idx = _allUsers.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          setState(() => _allUsers[idx] = {..._allUsers[idx], 'is_suspendu': next});
        }
        _showSnack(next ? "Utilisateur suspendu" : "Utilisateur réactivé");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : $e");
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<bool> _showConfirm(
      String title, String body, Color color, String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        content: Text(body,
            style: GoogleFonts.inter(
                color: Colors.white60, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Annuler",
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(label,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Gestion Utilisateurs",
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 22),
            onPressed: _load,
            tooltip: "Rafraîchir",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Rechercher par nom ou téléphone…",
                    hintStyle: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.white38),
                    filled: true,
                    fillColor:
                        Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: widget.accentColor,
                labelColor: widget.accentColor,
                unselectedLabelColor: Colors.white38,
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Clients (${_filtered('client').length})',
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.handyman_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Techniciens (${_filtered('technicien').length})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: widget.accentColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList('client'),
                _buildList('technicien'),
              ],
            ),
    );
  }

  Widget _buildList(String role) {
    final all = _filtered(role);
    if (all.isEmpty) return _buildEmpty();

    final civ = _byPays(all, 'CIV');
    final cmr = _byPays(all, 'CMR');

    return RefreshIndicator(
      onRefresh: _load,
      color: widget.accentColor,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (civ.isNotEmpty) ...[
            _countryHeader('🇨🇮', 'Côte d\'Ivoire', civ.length),
            ...civ.map((u) => _buildUserTile(u)),
            const SizedBox(height: 8),
          ],
          if (cmr.isNotEmpty) ...[
            _countryHeader('🇨🇲', 'Cameroun', cmr.length),
            ...cmr.map((u) => _buildUserTile(u)),
          ],
          // Utilisateurs sans pays
          ..._byPays(all, '').map((u) => _buildUserTile(u)),
        ],
      ),
    );
  }

  Widget _countryHeader(String flag, String name, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor)),
          ),
          const Expanded(
              child: Divider(
                  color: Color(0xFF1E293B),
                  indent: 10,
                  thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final String id = user['id'] as String;
    final String name = user['nom_complet'] as String? ?? 'Inconnu';
    final String role = user['role'] as String? ?? 'client';
    final String pays = user['pays'] as String? ?? '';
    final bool isSuspendu = user['is_suspendu'] as bool? ?? false;
    final bool isVerifie = user['is_identite_verifiee'] as bool? ?? false;
    final String? photoUrl = user['photo_profil_url'] as String?;
    final String? metier = user['metier_personnalise'] as String?;
    final bool isProcessing = _processing.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                widget.accentColor.withValues(alpha: 0.15),
            backgroundImage: photoUrl?.isNotEmpty == true
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                        fontSize: 15),
                  )
                : null,
          ),
          if (isSuspendu)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF0F172A), width: 1.5),
                ),
              ),
            ),
        ]),
        title: Row(
          children: [
            Flexible(
              child: Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSuspendu ? Colors.white38 : Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isVerifie) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded,
                  color: Colors.blue, size: 13),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role == 'technicien' && metier != null && metier.isNotEmpty)
              Text(metier,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: widget.accentColor,
                      fontWeight: FontWeight.w600)),
            Text(
              isSuspendu ? 'Suspendu' : pays,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isSuspendu
                      ? Colors.redAccent.withValues(alpha: 0.7)
                      : Colors.white38),
            ),
          ],
        ),
        isThreeLine: role == 'technicien' &&
            metier != null &&
            metier.isNotEmpty,
        trailing: isProcessing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38),
              )
            : IconButton(
                icon: Icon(
                  isSuspendu
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: isSuspendu
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: 22,
                ),
                tooltip: isSuspendu ? "Réactiver" : "Suspendre",
                onPressed: () => _toggleSuspension(user),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 56, color: Colors.white12),
          const SizedBox(height: 14),
          Text("Aucun résultat",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text("Aucun utilisateur correspondant.",
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white38)),
        ],
      ),
    );
  }
}
