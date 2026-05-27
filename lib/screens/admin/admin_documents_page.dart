import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin/admin_doc_card.dart';

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
    final String docId = doc['id'] as String;
    return AdminDocCard(
      doc: doc,
      isProcessing: _processing.contains(docId),
      accentColor: widget.accentColor,
      getSignedUrl: _getSignedUrl,
      onView: _openImageViewer,
      onApprove: () => _approuver(docId),
      onReject: () => _rejeter(docId),
    );
  }
}
