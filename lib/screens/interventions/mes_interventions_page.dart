import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'avis_modal.dart';

class MesInterventionsPage extends StatefulWidget {
  const MesInterventionsPage({super.key});

  @override
  State<MesInterventionsPage> createState() => _MesInterventionsPageState();
}

class _MesInterventionsPageState extends State<MesInterventionsPage> {
  final supabase = Supabase.instance.client;

  // IDs d'interventions déjà évaluées par ce client
  Set<String> _avisDeposes = {};

  @override
  void initState() {
    super.initState();
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) _chargerAvisDeposes(uid);
  }

  Future<void> _chargerAvisDeposes(String clientId) async {
    try {
      final data = await supabase
          .from('avis')
          .select('intervention_id')
          .eq('client_id', clientId);
      if (mounted) {
        setState(() {
          _avisDeposes = {for (final row in data) row['intervention_id'].toString()};
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement avis: $e");
    }
  }

  void _ouvrirAvisModal(Map<String, dynamic> intv, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvisModal(
        interventionId: intv['id'].toString(),
        techId: intv['tech_id'].toString(),
        titreService: intv['titre_service'] ?? 'Intervention',
        accentColor: accentColor,
        onAvisDepose: () {
          final uid = supabase.auth.currentUser?.id;
          if (uid != null) _chargerAvisDeposes(uid);
        },
      ),
    );
  }

  // --- LOGIQUE GPS ---
  Future<void> _ouvrirItineraire(String description) async {
    try {
      final regExp = RegExp(r"([-+]?\d+\.\d+),\s*([-+]?\d+\.\d+)");
      final match = regExp.firstMatch(description);

      if (match != null) {
        final lat = match.group(1);
        final lng = match.group(2);
        final url = Uri.parse("google.navigation:q=$lat,$lng&mode=d");

        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          final appleUrl = Uri.parse("http://maps.apple.com/?daddr=$lat,$lng");
          await launchUrl(appleUrl);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coordonnées GPS introuvables dans la description.")),
        );
      }
    } catch (e) {
      debugPrint("Erreur GPS: $e");
    }
  }

  // --- LOGIQUE MISE À JOUR STATUT ---
  Future<void> _updateStatus(String interventionId, String nouveauStatut) async {
    try {
      await supabase
          .from('interventions')
          .update({'statut': nouveauStatut})
          .eq('id', interventionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Statut mis à jour : ${nouveauStatut.toUpperCase()}"),
            backgroundColor: _getStatusColor(nouveauStatut),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur mise à jour statut: $e");
    }
  }

  void _confirmerChangementStatut(String id, String statutActuel) {
    String prochainStatut = _getNextStatus(statutActuel);
    String message = "";

    switch (statutActuel) {
      case 'en_attente': message = "Accepter cette mission ?"; break;
      case 'accepte': message = "Démarrer l'intervention maintenant ?"; break;
      case 'en_cours': message = "Marquer l'intervention comme terminée ?"; break;
      default: return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Mise à jour", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(prochainStatut),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _updateStatus(id, prochainStatut);
              Navigator.pop(context);
            },
            child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- HELPERS VISUELS ---
  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'accepte': return Colors.blue;
      case 'en_cours': return Colors.purple;
      case 'termine': return Colors.green;
      case 'annule': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getNextStatus(String current) {
    if (current == 'en_attente') return 'accepte';
    if (current == 'accepte') return 'en_cours';
    return 'termine';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser!.id;

    // Couleur accent récupérée depuis les données utilisateur si disponibles
    const Color accentColor = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Mes Interventions", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('interventions')
            .stream(primaryKey: ['id'])
            .order('date_creation', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final mesInterventions = snapshot.data!.where((intv) => 
            intv['client_id'] == currentUserId || intv['tech_id'] == currentUserId
          ).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mesInterventions.length,
            itemBuilder: (context, index) {
              final intv = mesInterventions[index];
              final bool isTech = intv['tech_id'] == currentUserId;
              final DateTime datePrevue = DateTime.parse(intv['date_prevue']);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(intv['statut']).withValues(alpha: 0.1),
                        child: Icon(isTech ? Icons.handyman : Icons.person, 
                          color: _getStatusColor(intv['statut'])),
                      ),
                      title: Text(intv['titre_service'] ?? "Intervention", 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        "Le ${DateFormat('dd/MM/yyyy à HH:mm').format(datePrevue.toLocal())}",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(intv['statut']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          intv['statut'].toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: _getStatusColor(intv['statut'])
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        intv['description'] ?? "",
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${intv['commune']}, ${intv['ville']}", 
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                          const Spacer(),
                          Text("${intv['montant_final']} FCFA", 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- SECTION ACTIONS (TECHNICIEN) ---
                    if (isTech && intv['statut'] != 'termine' && intv['statut'] != 'annule')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            if (intv['statut'] == 'accepte' || intv['statut'] == 'en_cours')
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _ouvrirItineraire(intv['description']),
                                  icon: const Icon(Icons.navigation, size: 18),
                                  label: const Text("GPS"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            if (intv['statut'] == 'accepte' || intv['statut'] == 'en_cours')
                              const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmerChangementStatut(intv['id'], intv['statut']),
                                icon: Icon(_getNextIcon(intv['statut']), color: Colors.white),
                                label: Text(_getNextLabel(intv['statut']).toUpperCase(),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getStatusColor(_getNextStatus(intv['statut'])),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- SECTION ÉVALUATION (CLIENT — intervention terminée) ---
                    if (!isTech && intv['statut'] == 'termine')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _avisDeposes.contains(intv['id'].toString())
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.withAlpha(60)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Avis déposé",
                                      style: GoogleFonts.inter(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _ouvrirAvisModal(intv, accentColor),
                                  icon: const Icon(Icons.star_rounded, size: 18),
                                  label: Text(
                                    "Évaluer l'intervention",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helpers pour les textes et icônes dynamiques
  String _getNextLabel(String current) {
    if (current == 'en_attente') return 'Accepter';
    if (current == 'accepte') return 'Démarrer';
    return 'Clôturer';
  }

  IconData _getNextIcon(String current) {
    if (current == 'en_attente') return Icons.check_circle;
    if (current == 'accepte') return Icons.play_arrow;
    return Icons.done_all;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune intervention enregistrée", 
            style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}