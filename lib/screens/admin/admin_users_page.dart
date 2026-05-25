import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  final Color accentColor;

  const AdminUsersPage({super.key, required this.accentColor});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('utilisateurs')
          .select('id, nom_complet, telephone, role, pays, is_suspendu, is_identite_verifiee, photo_profil_url, metier_personnalise')
          .neq('is_admin', true)
          .order('nom_complet')
          .limit(200);

      final data = List<Map<String, dynamic>>.from(rows as List);
      if (mounted) {
        setState(() {
          _users = data;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      debugPrint('Admin users erreur: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_users)
          : _users
              .where((u) =>
                  (u['nom_complet'] as String? ?? '').toLowerCase().contains(q) ||
                  (u['telephone'] as String? ?? '').contains(q))
              .toList();
    });
  }

  Future<void> _toggleSuspension(Map<String, dynamic> user) async {
    final String id = user['id'] as String;
    final bool current = user['is_suspendu'] as bool? ?? false;
    final bool next = !current;

    final confirmed = await _showConfirmDialog(
      next
          ? "Suspendre ${user['nom_complet'] ?? 'cet utilisateur'} ?"
          : "Réactiver ${user['nom_complet'] ?? 'cet utilisateur'} ?",
      next
          ? "Son compte sera désactivé immédiatement. Il ne pourra plus se connecter."
          : "Son compte sera restauré et il pourra se reconnecter.",
      next ? Colors.redAccent : Colors.greenAccent,
      next ? "Suspendre" : "Réactiver",
    );

    if (!confirmed) return;
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));

    try {
      await _supabase
          .from('utilisateurs')
          .update({'is_suspendu': next})
          .eq('id', id);

      if (mounted) {
        final idx = _users.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          setState(() {
            _users[idx] = {..._users[idx], 'is_suspendu': next};
          });
          _applyFilter();
        }
        _showSnack(next ? "Utilisateur suspendu" : "Utilisateur réactivé");
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : $e");
      debugPrint('Toggle suspension erreur: $e');
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<bool> _showConfirmDialog(
      String title, String body, Color color, String confirmLabel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5)),
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
            child: Text(confirmLabel,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Gestion Utilisateurs",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 22),
            onPressed: _load,
            tooltip: "Rafraîchir",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Rechercher par nom ou téléphone…",
                hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${_filtered.length} utilisateur${_filtered.length > 1 ? 's' : ''}",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE67E22)))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.accentColor,
                        backgroundColor: const Color(0xFF1E293B),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildUserTile(_filtered[i]),
                        ),
                      ),
          ),
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
    final bool isProcessing = _processing.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: widget.accentColor.withValues(alpha: 0.15),
            backgroundImage: photoUrl?.isNotEmpty == true
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl?.isNotEmpty != true
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                        fontSize: 16),
                  )
                : null,
          ),
          if (isSuspendu)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                ),
              ),
            ),
        ]),
        title: Row(
          children: [
            Flexible(
              child: Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSuspendu ? Colors.white38 : Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isVerifie) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
            ],
          ],
        ),
        subtitle: Text(
          "${role == 'technicien' ? 'Technicien' : 'Client'} • $pays${isSuspendu ? ' • Suspendu' : ''}",
          style: GoogleFonts.inter(
              fontSize: 11,
              color: isSuspendu
                  ? Colors.redAccent.withValues(alpha: 0.7)
                  : Colors.white38),
        ),
        trailing: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white38),
              )
            : IconButton(
                icon: Icon(
                  isSuspendu
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
                  color: isSuspendu ? Colors.greenAccent : Colors.redAccent,
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
          const Icon(Icons.people_outline_rounded, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text("Aucun résultat",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("Aucun utilisateur correspondant.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
        ],
      ),
    );
  }
}
