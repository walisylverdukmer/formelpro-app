import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:formelpro/screens/dashboard/verification_documents_page.dart';

class MissionDetailPage extends StatefulWidget {
  final Map<String, dynamic> intervention;

  const MissionDetailPage({super.key, required this.intervention});

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  bool _isUpdating = false;
  final supabase = Supabase.instance.client;

  Future<void> _accepterMission() async {
    setState(() => _isUpdating = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profil = await supabase
          .from('utilisateurs')
          .select('is_identite_verifiee, pays')
          .eq('id', user.id)
          .single();

      final bool isVerifie = profil['is_identite_verifiee'] == true;
      final Color accentColor = (profil['pays'] ?? 'CIV') == 'CIV'
          ? const Color(0xFFE67E22)
          : const Color(0xFFCE1126);

      if (!isVerifie) {
        final actives = await supabase
            .from('interventions')
            .select('id')
            .eq('tech_id', user.id)
            .inFilter('statut', ['accepte', 'en_cours']);
        if ((actives as List).length >= 3) {
          if (mounted) {
            setState(() => _isUpdating = false);
            _showVerifRequiseDialog(accentColor);
          }
          return;
        }
      }

      await supabase
          .from('interventions')
          .update({'statut': 'accepte'})
          .eq('id', widget.intervention['id'])
          .eq('statut', 'en_attente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Mission acceptée ! Elle est désormais dans votre suivi.",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : ${e.message}", style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur inattendue", style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        debugPrint("Erreur accepter mission: $e");
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showVerifRequiseDialog(Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Vérification requise",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          "Vous avez atteint la limite de 3 missions actives sans badge vérifié.\n\nVérifiez votre identité pour prendre plus de missions.",
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Annuler", style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerificationDocumentsPage(accentColor: accentColor),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Vérifier mon identité",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRaw = widget.intervention['date_intervention'] ?? DateTime.now().toIso8601String();
    final dateInter = DateTime.parse(dateRaw).toLocal();
    final String dateFormatee = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dateInter);
    final String heureFormatee = DateFormat('HH:mm').format(dateInter);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Détails Intervention", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTile(
              label: "TYPE D'INTERVENTION",
              value: widget.intervention['categorie_nom'] ?? "Non spécifié",
              icon: Icons.build_circle_outlined,
            ),
            const SizedBox(height: 25),
            _buildSectionTitle("Description du problème"),
            const SizedBox(height: 10),
            Text(
              widget.intervention['description'] ?? "Aucune description fournie.",
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Rendez-vous souhaité"),
            const SizedBox(height: 15),
            _buildDateInfo(dateFormatee, heureFormatee),
            const SizedBox(height: 30),
            _buildSectionTitle("Lieu de l'intervention"),
            const SizedBox(height: 15),
            _buildLocationInfo(
              widget.intervention['commune'] ?? "Abidjan",
              widget.intervention['adresse_precise'] ?? "Adresse non précisée",
            ),
            const SizedBox(height: 50),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.1),
    );
  }

  Widget _buildInfoTile({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFB300).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.handyman_rounded, color: Color(0xFFFFB300)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDateInfo(String date, String heure) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF1E293B)),
          const SizedBox(width: 15),
          Expanded(child: Text("$date à $heure", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String commune, String adresse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(commune, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          // CORRECTION ICI : Remplacement de left(34) par only(left: 34)
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            adresse,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    bool isAlreadyTaken = widget.intervention['statut'] != 'en_attente';

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: (_isUpdating || isAlreadyTaken) ? null : _accepterMission,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isUpdating
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isAlreadyTaken ? "MISSION DÉJÀ ATTRIBUÉE" : "ACCEPTER L'INTERVENTION",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)
              ),
      ),
    );
  }
}