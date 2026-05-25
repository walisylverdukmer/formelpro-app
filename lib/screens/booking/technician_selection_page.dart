import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianSelectionPage extends StatefulWidget {
  final String categoryName; // Ex: 'Plomberie'
  final Color accentColor;

  const TechnicianSelectionPage({
    super.key, 
    required this.categoryName, 
    required this.accentColor
  });

  @override
  State<TechnicianSelectionPage> createState() => _TechnicianSelectionPageState();
}

class _TechnicianSelectionPageState extends State<TechnicianSelectionPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _technicians = [];

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    try {
      // On récupère les techniciens qui ont cette spécialité
      // Le tri se fait d'abord par 'est_en_ligne' puis par 'commune'
      final response = await supabase
          .from('utilisateurs')
          .select()
          .eq('role', 'technicien')
          .ilike('specialites', '%${widget.categoryName}%')
          .order('est_en_ligne', ascending: false)
          .order('commune', ascending: true);

      setState(() {
        _technicians = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.accentColor))
          : _technicians.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _technicians.length,
                  itemBuilder: (context, index) {
                    final tech = _technicians[index];
                    return _buildTechCard(tech);
                  },
                ),
    );
  }

  Widget _buildTechCard(Map<String, dynamic> tech) {
    final bool isOnline = tech['est_en_ligne'] ?? false;
    final String photoUrl = tech['photo_profil_url'] ?? tech['photo_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          "${tech['prenom'] ?? ''} ${tech['nom_complet'] ?? ''}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: widget.accentColor),
                const SizedBox(width: 4),
                Text("${tech['commune'] ?? 'Zone non précisée'}", style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isOnline ? "Disponible maintenant" : "Hors ligne",
              style: GoogleFonts.inter(
                fontSize: 12, 
                color: isOnline ? Colors.green : Colors.red[300],
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_rounded, color: widget.accentColor, size: 20),
        ),
        onTap: () => _startConversation(tech),
      ),
    );
  }

  void _startConversation(Map<String, dynamic> tech) {
    // Prochaine étape : Logique pour créer la conversation et ouvrir le ChatScreen
    print("Démarrer chat avec ${tech['id']}");
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("Aucun technicien disponible pour ce métier."),
    );
  }
}