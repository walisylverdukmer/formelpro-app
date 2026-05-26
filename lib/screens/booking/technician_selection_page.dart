import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/widgets/carte_technicien.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';

class TechnicianSelectionPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final String pays;
  final Color accentColor;
  final String? clientId;

  const TechnicianSelectionPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.pays,
    required this.accentColor,
    this.clientId,
  });

  @override
  State<TechnicianSelectionPage> createState() =>
      _TechnicianSelectionPageState();
}

class _TechnicianSelectionPageState extends State<TechnicianSelectionPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _technicians = [];

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    try {
      final techCats = await supabase
          .from('technicien_categories')
          .select('technicien_id')
          .eq('categorie_id', widget.categoryId);

      final ids = techCats
          .map<String>((t) => t['technicien_id'].toString())
          .toList();

      if (ids.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await supabase
          .from('utilisateurs')
          .select(
            'id, nom_complet, metier_personnalise, savoir_faire, photo_profil_url, score_global, note_moyenne, ville, commune, quartier, disponible, is_premium, premium_level, est_en_ligne, telephone, is_identite_verifiee',
          )
          .eq('role', 'technicien')
          .eq('pays', widget.pays)
          .inFilter('id', ids)
          .order('is_premium', ascending: false)
          .order('est_en_ligne', ascending: false)
          .order('score_global', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _technicians = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch techniciens catégorie: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ouvrirFiche(Map<String, dynamic> tech) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsTechnicien(
          tech: tech,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                fontSize: 18,
              ),
            ),
            if (!_isLoading)
              Text(
                "${_technicians.length} expert${_technicians.length > 1 ? 's' : ''}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _technicians.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _technicians.length,
      itemBuilder: (context, index) => CarteTechnicien(
        tech: _technicians[index],
        accentColor: widget.accentColor,
        clientId: widget.clientId,
        onTap: () => _ouvrirFiche(_technicians[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded, size: 52,
                  color: widget.accentColor.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 24),
            Text(
              "Aucun expert trouvé\npour ce métier",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Aucun prestataire certifié n'est encore référencé pour « ${widget.categoryName} » dans votre zone.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Retour aux catégories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.accentColor,
                side: BorderSide(color: widget.accentColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
