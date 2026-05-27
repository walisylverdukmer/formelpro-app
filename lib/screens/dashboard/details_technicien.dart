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

  List<Map<String, dynamic>> _avis = [];
  bool _loadingAvis = true;
  bool _isFavori = false;
  bool _toggling = false;

  static const _sensibleKeywords = [
    'ménag', 'servante', 'serveuse', 'femme de'
  ];

  bool get _isServiceSensible {
    final metier =
        (widget.tech['metier_personnalise'] ?? '').toString().toLowerCase();
    return _sensibleKeywords.any((kw) => metier.contains(kw));
  }

  @override
  void initState() {
    super.initState();
    _loadAvis();
    _checkFavori();
  }

  Future<void> _loadAvis() async {
    try {
      final data = await _supabase
          .from('avis')
          .select('note, commentaire, date_avis')
          .eq('tech_id', widget.tech['id'])
          .order('date_avis', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _avis = List<Map<String, dynamic>>.from(data);
          _loadingAvis = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAvis = false);
    }
  }

  Future<void> _checkFavori() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await _supabase
          .from('favoris')
          .select('id')
          .eq('client_id', uid)
          .eq('tech_id', widget.tech['id'])
          .maybeSingle();
      if (mounted) setState(() => _isFavori = row != null);
    } catch (_) {}
  }

  Future<void> _toggleFavori() async {
    if (_toggling) return;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _toggling = true);
    try {
      if (_isFavori) {
        await _supabase
            .from('favoris')
            .delete()
            .eq('client_id', uid)
            .eq('tech_id', widget.tech['id']);
      } else {
        await _supabase
            .from('favoris')
            .insert({'client_id': uid, 'tech_id': widget.tech['id']});
      }
      if (mounted) {
        setState(() {
          _isFavori = !_isFavori;
          _toggling = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _startConversation() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    try {
      final existingConv = await _supabase
          .from('conversations')
          .select('id')
          .eq('client_id', currentUser.id)
          .eq('tech_id', widget.tech['id'])
          .maybeSingle();

      String conversationId;
      if (existingConv == null) {
        final newConv = await _supabase.from('conversations').insert({
          'client_id': currentUser.id,
          'tech_id': widget.tech['id'],
          'dernier_message': 'Nouvelle discussion...',
        }).select('id').single();
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
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
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
    final String nom =
        widget.tech['nom_complet'] ?? widget.tech['prenom'] ?? 'Prestataire';
    final String metier = widget.tech['metier_personnalise'] ?? 'Technicien';
    final String ville = widget.tech['ville'] ?? 'N/A';
    final String quartier = widget.tech['quartier'] ?? '';
    final String? photo = widget.tech['photo_profil_url'];
    final double note = (widget.tech['score_global'] ?? 5.0).toDouble();
    final bool estEnLigne = widget.tech['est_en_ligne'] == true;
    final bool disponible = widget.tech['disponible'] == true;
    final int premiumLevel = (widget.tech['premium_level'] ?? 0) as int;
    final bool isPremium = premiumLevel > 0;
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
                    _buildDragRow(isOwnProfile),
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
                    const SizedBox(height: 20),
                    TechnicienStatCard(
                      rating: note,
                      jobs: widget.tech['total_transactions'] ?? 0,
                      estEnLigne: estEnLigne,
                      disponible: disponible,
                    ),
                    if (isPremium) ...[
                      const SizedBox(height: 14),
                      TechnicienPremiumBanner(premiumLevel: premiumLevel),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle("À propos du prestataire"),
                    Text(
                      widget.tech['savoir_faire'] ??
                          "Ce professionnel n'a pas encore ajouté de "
                              "description détaillée de son expertise.",
                      style: GoogleFonts.inter(
                          color: const Color(0xFF475569),
                          height: 1.6,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Localisation"),
                    TechnicienInfoChip(
                      icon: Icons.location_on,
                      text: "$quartier${quartier.isNotEmpty ? ', ' : ''}$ville",
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 28),
                    TechnicienContactSection(
                      isSensible: _isServiceSensible,
                      accentColor: widget.accentColor,
                      onContact: _startConversation,
                      onDemande: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DemandServiceDomestiquePage(
                              accentColor: widget.accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle("Avis clients"),
                    TechnicienAvisSection(
                        avis: _avis, loading: _loadingAvis),
                    if (!isOwnProfile) ...[
                      const SizedBox(height: 16),
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

  Widget _buildDragRow(bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          const Expanded(child: Center(child: _DragHandle())),
          if (!isOwnProfile)
            GestureDetector(
              onTap: _toggleFavori,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isFavori
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(_isFavori),
                  color: _isFavori ? Colors.red : const Color(0xFFCBD5E1),
                  size: 26,
                ),
              ),
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
