import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../interventions/mission_detail_page.dart';

class MissionsTab extends StatefulWidget {
  final Color accentColor;
  final Map<String, dynamic>? userData; // Optionnel pour adapter le fond au pays

  const MissionsTab({super.key, required this.accentColor, this.userData});

  @override
  State<MissionsTab> createState() => _MissionsTabState();
}

class _MissionsTabState extends State<MissionsTab> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    
    // Détermination de l'image de fond selon le pays
    final String pays = widget.userData?['pays'] ?? 'CIV';
    final String bgImage = pays == 'CIV' 
        ? 'assets/images/tech_ci.jpg' 
        : 'assets/images/tech_cmr.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fond sombre de secours
      body: Stack(
        children: [
          // 1. Fond avec Glassmorphism
          Positioned.fill(
            child: Image.asset(bgImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
              ),
            ),
          ),

          // 2. Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Mes Missions",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Suivi de vos interventions acceptées",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.5), 
                      fontSize: 14
                    ),
                  ),
                  const SizedBox(height: 25),

                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('interventions')
                          .stream(primaryKey: ['id'])
                          .eq('tech_id', user?.id ?? '') 
                          .order('date_intervention', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: widget.accentColor),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }

                        final interventions = snapshot.data ?? [];

                        if (interventions.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          itemCount: interventions.length,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 10, bottom: 100),
                          itemBuilder: (context, index) {
                            return _buildMissionCard(interventions[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, size: 70, color: Colors.white.withValues(alpha: 0.1)),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune mission active",
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: Colors.white.withValues(alpha: 0.7)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vous n'avez pas encore\naccepté de missions.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            "Erreur de données", 
            style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            error, 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade300, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    String dateStr = mission['date_intervention'] ?? DateTime.now().toIso8601String();
    DateTime date = DateTime.parse(dateStr).toLocal();
    String formattedDate = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
    String statut = mission['statut'] ?? 'Acceptée';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showMissionDetails(mission),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(statut),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${mission['prix_estimé'] ?? '0'} FCFA",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, 
                          color: widget.accentColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  mission['categorie_nom'] ?? 'Intervention',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${mission['commune'] ?? 'Abidjan'} - ${mission['adresse_precise'] ?? ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5), 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.1)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RENDEZ-VOUS PRÉVU", 
                          style: GoogleFonts.inter(
                            fontSize: 10, 
                            color: Colors.white.withValues(alpha: 0.3), 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          )
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate, 
                          style: GoogleFonts.inter(
                            fontSize: 13, 
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          )
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: widget.accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'acceptée':
      case 'confirmé':
        color = Colors.blueAccent;
        break;
      case 'en cours':
        color = Colors.orangeAccent;
        break;
      case 'terminée':
        color = Colors.greenAccent;
        break;
      default:
        color = Colors.white24;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              color: color, 
              fontWeight: FontWeight.bold, 
              fontSize: 10, 
              letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }

  void _showMissionDetails(Map<String, dynamic> mission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionDetailPage(intervention: mission),
      ),
    );
  }
}