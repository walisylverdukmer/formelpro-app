import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../chat/chat_screen.dart';
import '../booking/demande_service_domestique_page.dart';
import '../../widgets/technicien/signaler_modal.dart';
import '../../widgets/technicien/technicien_widgets.dart';

class DetailsTechnicien extends StatefulWidget {
  final Map<String, dynamic> tech;
  final Color accentColor;

  const DetailsTechnicien(
      {super.key, required this.tech, required this.accentColor});

  @override
  State<DetailsTechnicien> createState() => _DetailsTechnicienState();
}

class _DetailsTechnicienState extends State<DetailsTechnicien> {
  final _supabase = Supabase.instance.client;

  static const _sensibleKeywords = ['ménag', 'servante', 'serveuse', 'femme de'];

  bool get _isServiceSensible {
    final metier =
        (widget.tech['metier_personnalise'] ?? '').toString().toLowerCase();
    return _sensibleKeywords.any((kw) => metier.contains(kw));
  }

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
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              receiverName:
                  "${widget.tech['prenom'] ?? ''} ${widget.tech['nom_complet'] ?? ''}"
                      .trim(),
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
          SnackBar(
              content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSignalerModal() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SignalerModal(
        techId: widget.tech['id'],
        signalerParId: currentUserId,
        accentColor: widget.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nom = widget.tech['nom_complet'] ??
        widget.tech['prenom'] ??
        'Prestataire';
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
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: photo != null && photo.isNotEmpty
                ? Image.network(photo, fit: BoxFit.cover)
                : Container(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    child: const Icon(Icons.person,
                        size: 100, color: Colors.white24),
                  ),
          ),
          Positioned(
            top: 50,
            left: 20,
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
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.55,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  controller: scrollController,
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nom,
                                  style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A))),
                              Text(metier.toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: widget.accentColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        if (widget.tech['is_identite_verifiee'] == true)
                          const Tooltip(
                            message: "Identité vérifiée",
                            child: Icon(Icons.verified,
                                color: Color(0xFF3B82F6), size: 28),
                          ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TechnicienStatCard(
                        rating: note,
                        jobs: widget.tech['total_transactions'] ?? 0),
                    const SizedBox(height: 30),
                    _buildSectionTitle("À propos du prestataire"),
                    Text(
                      widget.tech['savoir_faire'] ??
                          "Ce professionnel n'a pas encore ajouté de description détaillée de son expertise.",
                      style: GoogleFonts.inter(
                          color: const Color(0xFF475569),
                          height: 1.6,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle("Localisation"),
                    TechnicienInfoChip(
                      icon: Icons.location_on,
                      text:
                          "$quartier${quartier.isNotEmpty ? ', ' : ''}$ville",
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 35),
                    if (_isServiceSensible) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  color: Color(0xFF22C55E), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ce profil nécessite une validation FormelPro. Faites une demande encadrée pour être mis en relation.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF166534),
                                      height: 1.4),
                                ),
                              ),
                            ]),
                      ),
                      TechnicienActionButton(
                        label: 'Faire une demande encadrée',
                        icon: Icons.assignment_ind_rounded,
                        backgroundColor: const Color(0xFF22C55E),
                        textColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DemandServiceDomestiquePage(
                                accentColor: widget.accentColor),
                          ),
                        ),
                      ),
                    ] else ...[
                      TechnicienActionButton(
                        label: 'Contacter par message',
                        icon: Icons.chat_bubble_rounded,
                        backgroundColor: widget.accentColor,
                        textColor: Colors.white,
                        onTap: _startConversation,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded,
                              size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            "L'appel se débloque après échange dans le chat",
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                    if (!isOwnProfile) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showSignalerModal,
                          icon: const Icon(Icons.flag_outlined,
                              size: 16, color: Colors.red),
                          label: Text("Signaler ce prestataire",
                              style: GoogleFonts.inter(
                                  color: Colors.red, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
    );
  }
}
