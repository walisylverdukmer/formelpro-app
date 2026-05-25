import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InterventionDetailPage extends StatelessWidget {
  final Map<String, dynamic> intervention;
  final bool isLookingAtTech;

  const InterventionDetailPage({
    super.key,
    required this.intervention,
    required this.isLookingAtTech,
  });

  Future<void> _passerAppel(String? telephone) async {
    if (telephone == null || telephone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<List<dynamic>> _chargerDonnees(String targetId) => Future.wait([
        _getUtilisateur(targetId),
        _getFacture(intervention['id'].toString()),
      ]);

  Future<Map<String, dynamic>?> _getUtilisateur(String uid) =>
      Supabase.instance.client
          .from('utilisateurs')
          .select('id, nom_complet, metier_personnalise, photo_profil_url, score_global, total_transactions, telephone, is_identite_verifiee, savoir_faire')
          .eq('id', uid)
          .maybeSingle();

  Future<Map<String, dynamic>?> _getFacture(String interventionId) =>
      Supabase.instance.client
          .from('factures')
          .select('url_pdf, est_payee, montant')
          .eq('intervention_id', interventionId)
          .maybeSingle();

  @override
  Widget build(BuildContext context) {
    final String targetId =
        isLookingAtTech ? intervention['tech_id'] : intervention['client_id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isLookingAtTech ? "Profil du Technicien" : "Profil du Client",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _chargerDonnees(targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.hasData || snapshot.data![0] == null) {
            return const Center(child: Text("Utilisateur introuvable"));
          }

          final user = snapshot.data![0] as Map<String, dynamic>;
          final facture = snapshot.data![1] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildProfilHeader(user),
                const SizedBox(height: 30),
                _buildStats(user),
                const SizedBox(height: 35),
                _buildInfoSection("À propos", user['savoir_faire'] ?? "Aucune description fournie."),
                _buildInfoSection(
                  "Zone d'intervention",
                  "${intervention['commune'] ?? ''}, ${intervention['ville'] ?? ''}",
                ),
                if (facture != null) _buildFactureSection(facture),
                const SizedBox(height: 30),
                _buildActions(user),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilHeader(Map<String, dynamic> user) {
    final String? avatarUrl = user['photo_profil_url'];
    final String? initiale = (user['nom_complet'] as String?)?.isNotEmpty == true
        ? (user['nom_complet'] as String)[0].toUpperCase()
        : null;

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue.withAlpha(25),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(initiale ?? "?",
                        style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold))
                    : null,
              ),
              if (user['is_identite_verifiee'] == true)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 15),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(user['nom_complet'] ?? "Utilisateur",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(
            isLookingAtTech ? (user['metier_personnalise'] ?? "Technicien") : "Client",
            style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(Icons.star, user['score_global']?.toString() ?? "N/A", "Note"),
        _buildStatCard(Icons.verified, isLookingAtTech ? "Pro" : "Client", "Type"),
        _buildStatCard(Icons.task_alt, user['total_transactions']?.toString() ?? "0", "Missions"),
      ],
    );
  }

  Widget _buildActions(Map<String, dynamic> user) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("MESSAGE"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _passerAppel(user['telephone']),
            icon: const Icon(Icons.phone, color: Colors.white),
            label: const Text("APPELER"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactureSection(Map<String, dynamic> facture) {
    final bool estPayee = facture['est_payee'] == true;
    final int montant = (facture['montant'] ?? 0) as int;
    final String? urlPdf = facture['url_pdf'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Facture", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Montant", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                  Text("$montant FCFA",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Statut", style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (estPayee ? Colors.green : Colors.orange).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estPayee ? Icons.check_circle_outline : Icons.hourglass_empty,
                          size: 14,
                          color: estPayee ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estPayee ? "Payée" : "En attente",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: estPayee ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (urlPdf != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(urlPdf);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    label: Text("Ouvrir la facture PDF",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 40, thickness: 1, color: Colors.black12),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(height: 5),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.inter(color: Colors.black54, height: 1.5, fontSize: 14)),
          const Divider(height: 40, thickness: 1, color: Colors.black12),
        ],
      ),
    );
  }
}
