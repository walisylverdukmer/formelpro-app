import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/widgets/stats_dashboard_tech.dart';
import 'package:formelpro/screens/dashboard/verification_documents_page.dart';

class AccueilTechnicien extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AccueilTechnicien({super.key, required this.userData});

  @override
  State<AccueilTechnicien> createState() => _AccueilTechnicienState();
}

class _AccueilTechnicienState extends State<AccueilTechnicien> {
  final supabase = Supabase.instance.client;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.userData['disponible'] ?? true;
  }

  Future<void> _toggleAvailability(bool value) async {
    try {
      await supabase
          .from('utilisateurs')
          .update({'disponible': value})
          .eq('id', widget.userData['id']);
      setState(() => _isAvailable = value);
    } catch (e) {
      debugPrint('Erreur disponibilité: $e');
    }
  }

  Future<void> _accepterMission(String missionId) async {
    try {
      await supabase
          .from('interventions')
          .update({'statut': 'accepte'})
          .eq('id', missionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mission acceptée !', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur acceptation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String prenom = widget.userData['prenom'] ?? 'Technicien';
    final String uid = widget.userData['id']?.toString() ?? '';
    final String pays = widget.userData['pays'] ?? 'CIV';
    final Color accentColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String bgImage = pays == 'CIV'
        ? 'assets/images/tech_ci.jpg'
        : 'assets/images/tech_cmr.jpg';
    final double scoreGlobal =
        (widget.userData['score_global'] ?? 5.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(prenom, accentColor),
                  const SizedBox(height: 30),

                  _buildSectionLabel('Ma Performance'),
                  const SizedBox(height: 15),
                  StatsDashboardTech(
                    uid: uid,
                    accentColor: accentColor,
                    scoreGlobal: scoreGlobal,
                  ),

                  const SizedBox(height: 25),
                  _buildVerificationBanner(
                      widget.userData['is_identite_verifiee'] ?? false,
                      accentColor),

                  const SizedBox(height: 35),
                  _buildSectionLabel('Demandes en attente'),
                  const SizedBox(height: 15),
                  _buildMissionsStream(uid, accentColor),

                  const SizedBox(height: 50),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String prenom, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MODE PRESTATAIRE',
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Salut, $prenom !',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        _buildToggle(),
      ],
    );
  }

  Widget _buildToggle() {
    return Column(
      children: [
        Switch(
          value: _isAvailable,
          onChanged: _toggleAvailability,
          activeThumbColor: Colors.greenAccent,
          activeTrackColor: Colors.greenAccent.withValues(alpha: 0.4),
        ),
        Text(
          _isAvailable ? 'EN LIGNE' : 'HORS LIGNE',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _isAvailable ? Colors.greenAccent : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionsStream(String uid, Color color) {
    if (!_isAvailable) {
      return _buildStateMessage('Passez en ligne pour voir vos demandes.');
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('interventions')
          .stream(primaryKey: ['id'])
          .eq('tech_id', uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildStateMessage('Impossible de charger les demandes.');
        }
        final missions = (snapshot.data ?? [])
            .where((m) => m['statut'] == 'en_attente')
            .toList();
        if (missions.isEmpty) {
          return _buildStateMessage('Aucune demande en attente.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: missions.length,
          itemBuilder: (_, i) => _buildMissionItem(missions[i], color),
        );
      },
    );
  }

  Widget _buildMissionItem(Map<String, dynamic> m, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                (m['titre_service'] ?? 'SERVICE').toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                m['commune'] ?? m['ville'] ?? '—',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _accepterMission(m['id'].toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'ACCEPTER',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(bool isVerifie, Color accentColor) {
    if (isVerifie) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: Colors.greenAccent, size: 18),
            const SizedBox(width: 10),
            Text(
              "Identité validée — badge actif",
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VerificationDocumentsPage(accentColor: accentColor),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.shield_outlined, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vérifiez votre identité",
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Gagnez en visibilité et accédez aux missions premium",
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: accentColor),
          ],
        ),
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

  Widget _buildStateMessage(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text(
            msg,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
          ),
        ),
      );

  Widget _buildFooter() => Center(
        child: Text(
          '© 2026 FormelPro — Mode Technicien',
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white10),
        ),
      );
}
