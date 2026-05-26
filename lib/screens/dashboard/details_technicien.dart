import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_screen.dart';

class DetailsTechnicien extends StatefulWidget {
  final Map<String, dynamic> tech;
  final Color accentColor;

  const DetailsTechnicien({super.key, required this.tech, required this.accentColor});

  @override
  State<DetailsTechnicien> createState() => _DetailsTechnicienState();
}

class _DetailsTechnicienState extends State<DetailsTechnicien> {
  final _supabase = Supabase.instance.client;

  // --- CHAT ---
  Future<void> _startConversation() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final existingConv = await _supabase
          .from('conversations')
          .select()
          .eq('client_id', currentUser.id)
          .eq('tech_id', widget.tech['id'])
          .maybeSingle();

      String conversationId;
      if (existingConv == null) {
        final newConv = await _supabase.from('conversations').insert({
          'client_id': currentUser.id,
          'tech_id': widget.tech['id'],
          'dernier_message': 'Nouvelle discussion...',
        }).select().single();
        conversationId = newConv['id'];
      } else {
        conversationId = existingConv['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              receiverName: "${widget.tech['prenom'] ?? ''} ${widget.tech['nom_complet'] ?? ''}".trim(),
              receiverId: widget.tech['id'],
              accentColor: widget.accentColor,
              receiverPhone: widget.tech['telephone'] as String?,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- SIGNALER ---
  void _showSignalerModal() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SignalerModal(
        techId: widget.tech['id'],
        signalerParId: currentUserId,
        accentColor: widget.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nom = widget.tech['nom_complet'] ?? widget.tech['prenom'] ?? 'Prestataire';
    final String metier = widget.tech['metier_personnalise'] ?? 'Technicien';
    final String ville = widget.tech['ville'] ?? 'N/A';
    final String quartier = widget.tech['quartier'] ?? '';
    final String? photo = widget.tech['photo_profil_url'];
    final double note = (widget.tech['score_global'] ?? 5.0).toDouble();

    final currentUserId = _supabase.auth.currentUser?.id;
    final bool isOwnProfile = currentUserId == widget.tech['id'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Image de fond
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: photo != null && photo.isNotEmpty
                ? Image.network(photo, fit: BoxFit.cover)
                : Container(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, size: 100, color: Colors.white24),
                  ),
          ),

          // Bouton Retour
          Positioned(
            top: 50, left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // Panneau coulissant
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.55,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Poignée
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Nom + badge vérifié
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nom, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              Text(metier.toUpperCase(), style: GoogleFonts.inter(fontSize: 13, color: widget.accentColor, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        if (widget.tech['is_identite_verifiee'] == true)
                          const Tooltip(
                            message: "Identité vérifiée",
                            child: Icon(Icons.verified, color: Color(0xFF3B82F6), size: 28),
                          ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    _buildStatRow(note, widget.tech['total_transactions'] ?? 0),
                    const SizedBox(height: 30),

                    _buildSectionTitle("À propos du prestataire"),
                    Text(
                      widget.tech['savoir_faire'] ?? "Ce professionnel n'a pas encore ajouté de description détaillée de son expertise.",
                      style: GoogleFonts.inter(color: const Color(0xFF475569), height: 1.6, fontSize: 14),
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("Localisation"),
                    _buildInfoChip(Icons.location_on, "$quartier${quartier.isNotEmpty ? ', ' : ''}$ville"),

                    const SizedBox(height: 35),

                    // BOUTON PRINCIPAL — CONTACTER
                    _buildActionButton(
                      "Contacter par message",
                      Icons.chat_bubble_rounded,
                      widget.accentColor, Colors.white,
                      _startConversation,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          "L'appel se débloque après échange dans le chat",
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),

                    // BOUTON SIGNALER (discret, uniquement si ce n'est pas son propre profil)
                    if (!isOwnProfile) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showSignalerModal,
                          icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.red),
                          label: Text(
                            "Signaler ce prestataire",
                            style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildStatRow(double rating, int jobs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Note", rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
          Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
          _buildStatItem("Missions", "$jobs", Icons.check_circle_rounded, const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              val,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: widget.accentColor, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color bg,
    Color textCol,
    VoidCallback onTap,
  ) {
    final bool hasShadow = textCol == Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textCol, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textCol,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODAL SIGNALEMENT
// =============================================================================

class _SignalerModal extends StatefulWidget {
  final String techId;
  final String signalerParId;
  final Color accentColor;

  const _SignalerModal({
    required this.techId,
    required this.signalerParId,
    required this.accentColor,
  });

  @override
  State<_SignalerModal> createState() => _SignalerModalState();
}

class _SignalerModalState extends State<_SignalerModal> {
  static const _raisons = [
    "Comportement inapproprié",
    "Fausse identité / faux profil",
    "Arnaque ou fraude",
    "Harcèlement",
    "Qualité de travail dangereuse",
    "Autre",
  ];

  String? _raisonSelectionnee;
  final _autreController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_raisonSelectionnee == null) return;

    final raison = _raisonSelectionnee == "Autre" && _autreController.text.trim().isNotEmpty
        ? _autreController.text.trim()
        : _raisonSelectionnee!;

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.from('signalements').insert({
        'signale_par': widget.signalerParId,
        'utilisateur_signale': widget.techId,
        'raison': raison,
        'statut': 'en_attente',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Signalement envoyé. Notre équipe l'examinera sous 48h.",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            ),
          ),

          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.red, size: 22),
              const SizedBox(width: 10),
              Text(
                "Signaler ce prestataire",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Votre signalement est confidentiel et sera traité par notre équipe.",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Liste des raisons
          ..._raisons.map((raison) => _buildRaisonTile(raison)),

          // Champ texte libre si "Autre"
          if (_raisonSelectionnee == "Autre") ...[
            const SizedBox(height: 8),
            TextField(
              controller: _autreController,
              style: GoogleFonts.inter(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Décrivez le problème...",
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _raisonSelectionnee == null || _loading ? null : _envoyer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "Envoyer le signalement",
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaisonTile(String raison) {
    final selected = _raisonSelectionnee == raison;
    return GestureDetector(
      onTap: () => setState(() => _raisonSelectionnee = raison),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.red.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.red : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(raison, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
