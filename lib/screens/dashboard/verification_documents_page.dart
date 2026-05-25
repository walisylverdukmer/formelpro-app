import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VerificationDocumentsPage extends StatefulWidget {
  final Color accentColor;

  const VerificationDocumentsPage({super.key, required this.accentColor});

  @override
  State<VerificationDocumentsPage> createState() =>
      _VerificationDocumentsPageState();
}

class _VerificationDocumentsPageState
    extends State<VerificationDocumentsPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];
  bool _isIdentiteVerifiee = false;
  String? _uploadingType;
  final Map<String, String> _signedUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        _supabase
            .from('documents_verification')
            .select('id, type_document, document_url, statut, motif_rejet, created_at')
            .eq('user_id', uid)
            .order('created_at', ascending: false),
        _supabase
            .from('utilisateurs')
            .select('is_identite_verifiee')
            .eq('id', uid)
            .single(),
      ]);
      if (mounted) {
        setState(() {
          _documents = List<Map<String, dynamic>>.from(results[0] as List);
          _isIdentiteVerifiee =
              (results[1] as Map<String, dynamic>)['is_identite_verifiee'] ==
                  true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement documents: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolveExt(XFile file) {
    const mimeToExt = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp'};
    if (file.mimeType != null && mimeToExt.containsKey(file.mimeType)) {
      return mimeToExt[file.mimeType]!;
    }
    final parts = file.path.split('.');
    final raw = parts.length > 1 ? parts.last.toLowerCase() : '';
    return raw == 'jpeg' ? 'jpg' : (['jpg', 'png', 'webp'].contains(raw) ? raw : 'jpg');
  }

  String _resolveContentType(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

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

  Future<void> _previewDocument(String path, String label) async {
    final url = await _getSignedUrl(path);
    if (url == null || !mounted) return;
    if (kIsWeb) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
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
              title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) =>
                    p == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(String typeDoc) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) _showSnack("Fichier trop lourd (max 5 Mo)");
      return;
    }
    final String ext = _resolveExt(picked);
    final String contentType = _resolveContentType(ext);

    setState(() => _uploadingType = typeDoc);
    try {
      final path = '$uid/${typeDoc}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      // uploadBinary — compatible Android / iOS / Web (pas de dart:io)
      await _supabase.storage
          .from('documents-techniciens')
          .uploadBinary(path, bytes, fileOptions: FileOptions(upsert: true, contentType: contentType));

      await _supabase.from('documents_verification').insert({
        'user_id': uid,
        'type_document': typeDoc,
        'document_url': path,
        'statut': 'en_attente',
      });

      if (typeDoc == 'cni' || typeDoc == 'passeport') {
        await _supabase.from('utilisateurs').update({
          'document_identite_url': path,
          'type_document': typeDoc == 'cni' ? 'CNI' : 'Passeport',
        }).eq('id', uid);
      }
      // Admins notifiés par trigger_notifier_admins_nouveau_doc (SECURITY DEFINER)

      if (mounted) {
        _showSnack("Document soumis — en attente de validation (24-48h)");
        _loadDocuments();
      }
    } on StorageException catch (e) {
      if (mounted) _showSnack("Erreur upload : ${e.message}");
    } catch (e) {
      if (mounted) _showSnack("Erreur inattendue");
      debugPrint('Upload document erreur: $e');
    } finally {
      if (mounted) setState(() => _uploadingType = null);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Vérification d'identité",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE67E22)))
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              color: widget.accentColor,
              backgroundColor: const Color(0xFF1E293B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHero(),
                    const SizedBox(height: 32),
                    _buildSectionLabel("Documents d'identité"),
                    const SizedBox(height: 12),
                    _buildDocumentCard('cni', "Carte Nationale d'Identité",
                        Icons.credit_card_rounded,
                        required: true),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                        'passeport', "Passeport", Icons.book_rounded,
                        required: false),
                    const SizedBox(height: 28),
                    _buildSectionLabel("Certification professionnelle (optionnel)"),
                    const SizedBox(height: 12),
                    _buildDocumentCard('certificat', "Certificat ou diplôme",
                        Icons.workspace_premium_rounded,
                        required: false),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                        'diplome', "Diplôme d'état", Icons.school_rounded,
                        required: false),
                    const SizedBox(height: 32),
                    _buildBenefitsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusHero() {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (_isIdentiteVerifiee) {
      color = Colors.greenAccent;
      icon = Icons.verified_rounded;
      title = "Identité validée";
      subtitle =
          "Votre badge de confiance est actif — vous apparaissez en priorité dans les résultats.";
    } else if (_documents.any((d) => d['statut'] == 'en_attente')) {
      color = Colors.orange;
      icon = Icons.hourglass_top_rounded;
      title = "Dossier en cours de vérification";
      subtitle =
          "L'équipe FormelPro examine vos documents. Délai habituel : 24 à 48h.";
    } else if (_documents.any((d) => d['statut'] == 'rejete')) {
      color = Colors.redAccent;
      icon = Icons.error_outline_rounded;
      title = "Document refusé";
      subtitle =
          "Un document a été refusé. Consultez le motif ci-dessous et soumettez-en un nouveau.";
    } else {
      color = Colors.white38;
      icon = Icons.shield_outlined;
      title = "Identité non vérifiée";
      subtitle =
          "Soumettez vos documents pour activer votre badge et gagner en visibilité.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color == Colors.white38 ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white54, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String typeDoc, String label, IconData icon,
      {required bool required}) {
    final existing = _documents
        .where((d) => d['type_document'] == typeDoc)
        .toList()
      ..sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
    final latest = existing.isNotEmpty ? existing.first : null;
    final bool isUploading = _uploadingType == typeDoc;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Requis",
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (latest != null)
                  _buildDocStatus(
                    latest['statut'] as String,
                    latest['motif_rejet'] as String?,
                  )
                else
                  Text(
                    "Aucun document soumis",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white38),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (latest != null)
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded,
                        color: Colors.white38, size: 20),
                    onPressed: () => _previewDocument(
                        latest['document_url'] as String, label),
                    tooltip: "Aperçu",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: const Icon(Icons.upload_rounded,
                      color: Colors.white54, size: 22),
                  onPressed: () => _uploadDocument(typeDoc),
                  tooltip: "Soumettre un document",
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDocStatus(String statut, String? motifRejet) {
    final Color color;
    final String label;
    switch (statut) {
      case 'approuve':
        color = Colors.greenAccent;
        label = "✓ Approuvé";
      case 'rejete':
        color = Colors.redAccent;
        label = "✗ Refusé${motifRejet != null ? ' : $motifRejet' : ''}";
      case 'expire':
        color = Colors.orange;
        label = "Document expiré — veuillez soumettre à nouveau";
      default:
        color = Colors.amber;
        label = "En attente de validation";
    }
    return Text(
      label,
      style: GoogleFonts.inter(
          fontSize: 12, color: color, fontWeight: FontWeight.w500),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBenefitsCard() {
    const items = [
      (Icons.verified_rounded, "Badge « Vérifié » visible sur votre profil"),
      (Icons.trending_up_rounded, "Priorité dans les résultats de recherche"),
      (Icons.star_rounded, "Accès aux missions et clients premium"),
      (Icons.shield_rounded, "Confiance accrue auprès des clients"),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withValues(alpha: 0.12),
            widget.accentColor.withValues(alpha: 0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Avantages de la vérification",
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(item.$1, size: 18, color: widget.accentColor),
                  const SizedBox(width: 10),
                  Text(
                    item.$2,
                    style:
                        GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white24,
          letterSpacing: 1.5,
        ),
      );
}
