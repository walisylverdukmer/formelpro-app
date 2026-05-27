import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'avis_modal.dart';
import '../payment/paiement_page.dart';

class MesInterventionsPage extends StatefulWidget {
  const MesInterventionsPage({super.key});

  @override
  State<MesInterventionsPage> createState() => _MesInterventionsPageState();
}

class _MesInterventionsPageState extends State<MesInterventionsPage> {
  final supabase = Supabase.instance.client;

  Set<String> _avisDeposes = {};
  String _pays = 'CIV';
  // interventionId → statut de transaction ('en_attente' | 'confirme' | 'echoue')
  Map<String, String> _statutsTransactions = {};
  // interventionId → id de transaction (pour confirmation tech)
  Map<String, String> _transactionIds = {};

  @override
  void initState() {
    super.initState();
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      _chargerUserData(uid);
      _chargerAvisDeposes(uid);
      _chargerTransactions(uid);
    }
  }

  Future<void> _chargerUserData(String uid) async {
    try {
      final data = await supabase
          .from('utilisateurs')
          .select('pays')
          .eq('id', uid)
          .single();
      if (mounted) setState(() => _pays = data['pays'] ?? 'CIV');
    } catch (e) {
      debugPrint("Erreur userData: $e");
    }
  }

  Future<void> _chargerAvisDeposes(String clientId) async {
    try {
      final data = await supabase
          .from('avis')
          .select('intervention_id')
          .eq('client_id', clientId);
      if (mounted) {
        setState(() {
          _avisDeposes = {
            for (final row in data) row['intervention_id'].toString()
          };
        });
      }
    } catch (e) {
      debugPrint("Erreur avis: $e");
    }
  }

  Future<void> _chargerTransactions(String uid) async {
    try {
      final data = await supabase
          .from('transactions')
          .select('id, intervention_id, statut')
          .or('client_id.eq.$uid,tech_id.eq.$uid');
      if (mounted) {
        final statuts = <String, String>{};
        final ids = <String, String>{};
        for (final row in data) {
          final iid = row['intervention_id'].toString();
          statuts[iid] = row['statut'].toString();
          ids[iid] = row['id'].toString();
        }
        setState(() {
          _statutsTransactions = statuts;
          _transactionIds = ids;
        });
      }
    } catch (e) {
      debugPrint("Erreur transactions: $e");
    }
  }

  Future<void> _confirmerReceptionPaiement(String interventionId) async {
    final txId = _transactionIds[interventionId];
    if (txId == null) return;
    try {
      await supabase
          .from('transactions')
          .update({
            'statut': 'confirme',
            'confirmed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', txId);
      if (mounted) {
        setState(() => _statutsTransactions[interventionId] = 'confirme');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Paiement confirmé avec succès !",
                style: GoogleFonts.inter()),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      debugPrint("Erreur confirmation paiement: $e");
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
          await launchUrl(Uri.parse("http://maps.apple.com/?daddr=$lat,$lng"));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Coordonnées GPS introuvables.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur GPS: $e");
    }
  }

  Future<void> _updateStatus(
      String interventionId, String nouveauStatut) async {
    try {
      await supabase
          .from('interventions')
          .update({'statut': nouveauStatut})
          .eq('id', interventionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Statut : ${nouveauStatut.toUpperCase()}"),
            backgroundColor: _getStatusColor(nouveauStatut),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur mise à jour statut: $e");
    }
  }

  void _confirmerChangementStatut(String id, String statutActuel) {
    final prochainStatut = _getNextStatus(statutActuel);
    String message;
    switch (statutActuel) {
      case 'en_attente':
        message = "Accepter cette mission ?";
        break;
      case 'accepte':
        message = "Démarrer l'intervention maintenant ?";
        break;
      case 'en_cours':
        message = "Marquer l'intervention comme terminée ?";
        break;
      default:
        return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Mise à jour",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getStatusColor(prochainStatut),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _updateStatus(id, prochainStatut);
              Navigator.pop(ctx);
            },
            child: const Text("Confirmer",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'accepte':
        return Colors.blue;
      case 'en_cours':
        return Colors.purple;
      case 'termine':
        return Colors.green;
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNextStatus(String current) {
    if (current == 'en_attente') return 'accepte';
    if (current == 'accepte') return 'en_cours';
    return 'termine';
  }

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

  Color get _accentColor =>
      _pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFCE1126);

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Mes Interventions",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18)),
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
          final list = snapshot.data!
              .where((intv) =>
                  intv['client_id'] == currentUserId ||
                  intv['tech_id'] == currentUserId)
              .toList();
          if (list.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _buildCard(list[i], currentUserId),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> intv, String currentUserId) {
    final bool isTech = intv['tech_id'] == currentUserId;
    final DateTime datePrevue = DateTime.parse(intv['date_prevue']);
    final String iid = intv['id'].toString();
    final String? statutTx = _statutsTransactions[iid];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  _getStatusColor(intv['statut']).withValues(alpha: 0.1),
              child: Icon(isTech ? Icons.handyman : Icons.person,
                  color: _getStatusColor(intv['statut'])),
            ),
            title: Text(intv['titre_service'] ?? "Intervention",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              "Le ${DateFormat('dd/MM/yyyy à HH:mm').format(datePrevue.toLocal())}",
              style: GoogleFonts.inter(fontSize: 12),
            ),
            trailing: _buildStatusBadge(intv['statut']),
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
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                Text("${intv['montant_final']} FCFA",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tech — actions statuts (en cours)
          if (isTech &&
              intv['statut'] != 'termine' &&
              intv['statut'] != 'annule')
            _buildTechActions(intv),

          // Tech — confirmation paiement reçu
          if (isTech && intv['statut'] == 'termine')
            _buildTechPaymentSection(iid, statutTx),

          // Client — paiement + évaluation
          if (!isTech && intv['statut'] == 'termine')
            _buildClientTermineSection(intv, iid, statutTx),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? statut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(statut).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statut?.toUpperCase() ?? '',
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(statut)),
      ),
    );
  }

  Widget _buildTechActions(Map<String, dynamic> intv) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          if (intv['statut'] == 'accepte' || intv['statut'] == 'en_cours')
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _ouvrirItineraire(intv['description'] ?? ''),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text("GPS"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (intv['statut'] == 'accepte' || intv['statut'] == 'en_cours')
            const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _confirmerChangementStatut(intv['id'], intv['statut']),
              icon: Icon(_getNextIcon(intv['statut']), color: Colors.white),
              label: Text(_getNextLabel(intv['statut']).toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _getStatusColor(_getNextStatus(intv['statut'])),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechPaymentSection(String iid, String? statutTx) {
    if (statutTx == 'confirme') {
      return _buildPaymentBadge(
          Icons.check_circle_outline, "Paiement confirmé ✓", Colors.green);
    }
    if (statutTx == 'en_attente') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ElevatedButton.icon(
          onPressed: () => _confirmerReceptionPaiement(iid),
          icon: const Icon(Icons.verified, color: Colors.white, size: 18),
          label: Text("Confirmer réception paiement",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );
    }
    return _buildPaymentBadge(
        Icons.hourglass_top_rounded,
        "En attente du paiement client",
        Colors.orange);
  }

  Widget _buildClientTermineSection(
      Map<String, dynamic> intv, String iid, String? statutTx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          if (statutTx == 'confirme')
            _buildPaymentBadge(
                Icons.check_circle_outline, "Paiement confirmé ✓", Colors.green)
          else if (statutTx == 'en_attente')
            _buildPaymentBadge(
                Icons.hourglass_top_rounded,
                "Paiement en attente de confirmation",
                Colors.orange)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaiementPage(
                        intervention: intv,
                        userData: {'pays': _pays},
                      ),
                    ),
                  );
                  if (result == true) {
                    final uid = supabase.auth.currentUser?.id;
                    if (uid != null) _chargerTransactions(uid);
                  }
                },
                icon:
                    const Icon(Icons.payment, color: Colors.white, size: 18),
                label: Text("Payer maintenant",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),

          if (statutTx == 'confirme') ...[
            const SizedBox(height: 10),
            _avisDeposes.contains(iid)
                ? _buildPaymentBadge(
                    Icons.check_circle_outline, "Avis déposé", Colors.blue)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _ouvrirAvisModal(intv, _accentColor),
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: Text("Évaluer l'intervention",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(IconData icon, String label, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune intervention enregistrée",
              style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}
