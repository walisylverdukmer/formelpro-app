import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DemandesTab extends StatefulWidget {
  final Color accentColor;

  const DemandesTab({super.key, required this.accentColor});

  @override
  State<DemandesTab> createState() => _DemandesTabState();
}

class _DemandesTabState extends State<DemandesTab> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Ombres pour la lisibilité sur fond dynamique
  final List<Shadow> _textShadows = [
    Shadow(
      offset: const Offset(0, 1.5),
      blurRadius: 4.0,
      color: Colors.black.withValues(alpha: 0.6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent, // Fond transparent pour voir l'image du dashboard
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50), // Espace pour l'AppBar transparente
              Text(
                "Mes Demandes",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: _textShadows,
                ),
              ),
              Text(
                "Suivez l'état de vos interventions en temps réel",
                style: GoogleFonts.inter(
                  color: Colors.white70, 
                  fontSize: 14,
                  shadows: _textShadows,
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('interventions')
                      .stream(primaryKey: ['id'])
                      .eq('client_id', user?.id ?? '')
                      .order('date_intervention', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: widget.accentColor));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Erreur de connexion aux données",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    final demandes = snapshot.data ?? [];

                    if (demandes.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: demandes.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final item = demandes[index];
                        return _buildDemandeCard(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_late_outlined, size: 80, color: Colors.white30),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucune demande trouvée",
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w600, 
              color: Colors.white,
              shadows: _textShadows,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vos demandes d'intervention s'afficheront ici.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, shadows: _textShadows),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => debugPrint("Vers création demande"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
            ),
            child: const Text("Faire une demande", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    String statut = demande['statut'] ?? 'En attente';
    String dateStr = demande['date_intervention'] ?? DateTime.now().toIso8601String();
    DateTime date = DateTime.parse(dateStr).toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92), // Fond blanc semi-opaque
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => debugPrint("Détails demande"),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        demande['categorie_nom']?.toUpperCase() ?? 'INTERVENTION',
                        style: GoogleFonts.inter(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: widget.accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildStatusBadge(statut),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  demande['description'] ?? 'Pas de description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600, 
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: Colors.blueGrey.shade300),
                    const SizedBox(width: 6),
                    Text(
                      "RDV : ${DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(date)}",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (demande['commune'] != null)
                      Text(
                        demande['commune'],
                        style: TextStyle(fontSize: 11, color: widget.accentColor, fontWeight: FontWeight.bold),
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
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'en attente':
        color = Colors.orange.shade700;
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'confirmé':
      case 'acceptée':
        color = Colors.blue.shade700;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'terminée':
        color = Colors.green.shade700;
        icon = Icons.task_alt_rounded;
        break;
      default:
        color = Colors.grey.shade700;
        icon = Icons.info_outline_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}