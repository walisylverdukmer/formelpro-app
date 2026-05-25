import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDocumentsPage extends StatefulWidget {
  final Color accentColor;

  const AdminDocumentsPage({super.key, required this.accentColor});

  @override
  State<AdminDocumentsPage> createState() => _AdminDocumentsPageState();
}

class _AdminDocumentsPageState extends State<AdminDocumentsPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pending = [];
  final Set<String> _processing = {};
  final Map<String, String> _signedUrlCache = {};

  Future<String?> _getSignedUrl(String path) async {
    if (_signedUrlCache.containsKey(path)) return _signedUrlCache[path];
    try {
      final url = await _supabase.storage
          .from('documents-techniciens')
          .createSignedUrl(path, 3600);
      _signedUrlCache[path] = url;
      return url;
    } catch (e) {
      debugPrint('Erreur signed URL: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('documents_verification')
          .select('id, type_document, document_url, created_at, user_id, utilisateurs(id, nom_complet, metier_personnalise, photo_profil_url)')
          .eq('statut', 'en_attente')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _pending = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin: erreur chargement docs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approuver(String docId) async {
    if (_processing.contains(docId)) return;
    setState(() => _processing.add(docId));
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase.from('documents_verification').update({
        'statut': 'approuve',
        'validated_by': adminId,
        'validated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', docId);
      // trigger_notifier_tech_statut_doc (SECURITY DEFINER) envoie la notification

      if (mounted) {
        setState(() => _pending.removeWhere((d) => d['id'] == docId));
        _showSnack("✓ Document approuvé", success: true);
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : $e");
      debugPrint('Admin approve erreur: $e');
    } finally {
      if (mounted) setState(() => _processing.remove(docId));
    }
  }

  Future<void> _rejeter(String docId) async {
    final motif = await _showMotifDialog();
    if (motif == null) return;
    if (_processing.contains(docId)) return;
    setState(() => _processing.add(docId));
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase.from('documents_verification').update({
        'statut': 'rejete',
        'motif_rejet': motif.trim(),
        'validated_by': adminId,
        'validated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', docId);
      // trigger_notifier_tech_statut_doc (SECURITY DEFINER) envoie la notification

      if (mounted) {
        setState(() => _pending.removeWhere((d) => d['id'] == docId));
        _showSnack("Document refusé", success: false);
      }
    } catch (e) {
      if (mounted) _showSnack("Erreur : $e");
      debugPrint('Admin reject erreur: $e');
    } finally {
      if (mounted) setState(() => _processing.remove(docId));
    }
  }

  Future<String?> _showMotifDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Motif du refus",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Ex : Photo floue, document expiré, CNI illisible…",
            hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Annuler",
                style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Refuser",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor:
          success ? const Color(0xFF166534) : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _openImageViewer(String storagePath, String label) async {
    final url = await _getSignedUrl(storagePath);
    if (url == null || !mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(label,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white38, size: 60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Validation Documents",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            if (!_isLoading)
              Text(
                "${_pending.length} en attente",
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white38),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 22),
            onPressed: _loadPending,
            tooltip: "Rafraîchir",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : _pending.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPending,
                  color: widget.accentColor,
                  backgroundColor: const Color(0xFF1E293B),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pending.length,
                    itemBuilder: (_, i) => _buildDocCard(_pending[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt_rounded,
              size: 64, color: Colors.greenAccent),
          const SizedBox(height: 16),
          Text("Tout est traité !",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text("Aucun document en attente de validation.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final user = doc['utilisateurs'] as Map<String, dynamic>? ?? {};
    final String docId = doc['id'] as String;
    final String typeDoc = doc['type_document'] as String? ?? '—';
    final String docUrl = doc['document_url'] as String? ?? '';
    final String createdAt = doc['created_at'] as String? ?? '';
    final bool isProcessing = _processing.contains(docId);

    final String typLabel = switch (typeDoc) {
      'cni' => 'CNI',
      'passeport' => 'Passeport',
      'certificat' => 'Certificat',
      'diplome' => 'Diplôme',
      _ => typeDoc.toUpperCase(),
    };

    final String dateStr = createdAt.isNotEmpty
        ? DateFormat('d MMM yyyy • HH:mm', 'fr').format(
            DateTime.parse(createdAt).toLocal())
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête technicien
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: widget.accentColor.withValues(alpha: 0.2),
                  backgroundImage: (user['photo_profil_url'] as String?)
                              ?.isNotEmpty ==
                          true
                      ? NetworkImage(user['photo_profil_url'] as String)
                      : null,
                  child: (user['photo_profil_url'] as String?)?.isEmpty != false
                      ? Icon(Icons.person, color: widget.accentColor, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nom_complet'] as String? ?? 'Inconnu',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      Text(
                        user['metier_personnalise'] as String? ?? 'Prestataire',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: widget.accentColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    typLabel,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),

          // Miniature du document (URL signée — bucket privé)
          if (docUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _openImageViewer(docUrl, typLabel),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 160,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black26,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<String?>(
                      future: _getSignedUrl(docUrl),
                      builder: (_, snap) {
                        if (snap.hasData && snap.data != null) {
                          return Image.network(
                            snap.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: Colors.white24, size: 40),
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.zoom_in_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Date + boutons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.white24),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white24),
                  ),
                ),
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white38),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => _rejeter(docId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text("Refuser",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _approuver(docId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text("Valider",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
