import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/widgets/carte_technicien.dart';
import 'package:formelpro/widgets/categories_chips.dart';
import 'package:formelpro/widgets/filtres_techniciens.dart';
import 'package:formelpro/widgets/zone_stats_widget.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';

class AccueilClient extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AccueilClient({super.key, required this.userData});

  @override
  State<AccueilClient> createState() => _AccueilClientState();
}

class _AccueilClientState extends State<AccueilClient>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _techniciens = [];
  List<Map<String, dynamic>> _topCategories = [];
  bool _isFetching = true;
  FiltresTechniciens _filtres = const FiltresTechniciens();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _shimmerController;

  static const _textShadows = [
    Shadow(offset: Offset(0, 1.5), blurRadius: 4.0, color: Color(0xBF000000)),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCountryModal();
      _loadTopCategories();
      _fetchTechniciens();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopCategories() async {
    try {
      final cats = await supabase
          .from('categories_services')
          .select('id, nom')
          .eq('est_valide', true)
          .order('ordre_affichage')
          .limit(8);
      if (mounted) {
        setState(() => _topCategories = List<Map<String, dynamic>>.from(cats));
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories chips: $e');
    }
  }

  Future<void> _fetchTechniciens() async {
    setState(() => _isFetching = true);
    try {
      final String pays = widget.userData['pays'] ?? 'CIV';
      final String search = _searchController.text.trim();

      List<String>? techIdsFiltres;
      if (_filtres.categorieId != null) {
        final techCats = await supabase
            .from('technicien_categories')
            .select('technicien_id')
            .eq('categorie_id', _filtres.categorieId!);
        techIdsFiltres =
            techCats.map<String>((t) => t['technicien_id'].toString()).toList();
        if (techIdsFiltres.isEmpty) {
          if (mounted) setState(() { _techniciens = []; _isFetching = false; });
          return;
        }
      } else if (_filtres.categorieNom != null) {
        final cats = await supabase
            .from('categories_services')
            .select('id')
            .ilike('nom', '%${_filtres.categorieNom}%')
            .eq('est_valide', true);
        if (cats.isEmpty) {
          if (mounted) setState(() { _techniciens = []; _isFetching = false; });
          return;
        }
        final catIds = cats.map<String>((c) => c['id'].toString()).toList();
        final techCats = await supabase
            .from('technicien_categories')
            .select('technicien_id')
            .inFilter('categorie_id', catIds);
        techIdsFiltres =
            techCats.map<String>((t) => t['technicien_id'].toString()).toList();
        if (techIdsFiltres.isEmpty) {
          if (mounted) setState(() { _techniciens = []; _isFetching = false; });
          return;
        }
      }

      var query = supabase
          .from('utilisateurs')
          .select(
            'id, nom_complet, metier_personnalise, photo_profil_url, score_global, note_moyenne, ville, commune, quartier, disponible, is_premium, premium_level, est_en_ligne, telephone, is_identite_verifiee',
          )
          .eq('role', 'technicien')
          .eq('pays', pays);

      if (techIdsFiltres != null) query = query.inFilter('id', techIdsFiltres);
      if (_filtres.disponibleSeulement) query = query.eq('disponible', true);
      if (_filtres.noteMin > 0) query = query.gte('note_moyenne', _filtres.noteMin);
      if (search.isNotEmpty) {
        query = query.or(
          'nom_complet.ilike.%$search%,metier_personnalise.ilike.%$search%',
        );
      }

      final response = await query
          .order('is_premium', ascending: false)
          .order('est_en_ligne', ascending: false)
          .order('score_global', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _techniciens = List<Map<String, dynamic>>.from(response);
          _isFetching = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch techniciens: $e');
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _ouvrirFiche(Map<String, dynamic> tech, Color primaryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsTechnicien(tech: tech, accentColor: primaryColor),
      ),
    );
  }

  Future<void> _openFiltres(Color accentColor) async {
    final result = await showFiltresSheet(context, accentColor, _filtres);
    if (result != null && mounted) {
      setState(() => _filtres = result);
      _fetchTechniciens();
    }
  }

  void _resetFilters() {
    setState(() {
      _filtres = const FiltresTechniciens();
      _searchController.clear();
    });
    _fetchTechniciens();
  }

  void _showCountryModal() {
    final String pays = widget.userData['pays'] ?? 'CIV';
    final bool isCI = pays == 'CIV';
    final Color accentColor =
        isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String flagPath =
        isCI ? "assets/images/ci.jpg" : "assets/images/cmr.jpg";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(flagPath,
                    width: 70, height: 45, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text(
                isCI ? "FormelPro Côte d'Ivoire" : "FormelPro Cameroun",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor),
              ),
              const SizedBox(height: 12),
              Text(
                isCI
                    ? "Trouvez les artisans qualifiés de proximité."
                    : "Accédez au réseau certifié au Cameroun.",
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Continuer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userDisplayName = widget.userData['prenom'] ?? 'Client';
    final String pays = widget.userData['pays'] ?? 'CIV';
    final Color primaryColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String flagPath =
        pays == 'CIV' ? "assets/images/ci.jpg" : "assets/images/cmr.jpg";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Bonjour $userDisplayName",
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white,
                            shadows: _textShadows),
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(flagPath,
                            width: 24, height: 16, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                  Text(
                    "Besoin d'un pro ?",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: _textShadows,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildSearchBar(primaryColor),
              const SizedBox(height: 16),
              ZoneStatsWidget(
                pays: pays,
                commune: widget.userData['commune'] as String?,
                accentColor: primaryColor,
              ),
              const SizedBox(height: 25),
              _buildSectionHeader("Catégories populaires"),
              const SizedBox(height: 15),
              CategoriesChips(
                pays: pays,
                shimmerController: _shimmerController,
                activeCatId: _filtres.categorieId,
                categories: _topCategories,
                onSelect: (id, nom) {
                  setState(() {
                    _filtres = _filtres.categorieId == id
                        ? FiltresTechniciens(
                            disponibleSeulement: _filtres.disponibleSeulement,
                            noteMin: _filtres.noteMin,
                          )
                        : FiltresTechniciens(
                            categorieId: id,
                            categorieNom: nom,
                            disponibleSeulement: _filtres.disponibleSeulement,
                            noteMin: _filtres.noteMin,
                          );
                  });
                  _fetchTechniciens();
                },
              ),
              const SizedBox(height: 35),
              _buildSectionHeader("Techniciens recommandés"),
              const SizedBox(height: 15),
              _buildTechList(primaryColor),
              const SizedBox(height: 40),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _fetchTechniciens(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: "Rechercher un artisan...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E293B)),
          suffixIcon: GestureDetector(
            onTap: () => _openFiltres(primaryColor),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _filtres.actif
                      ? primaryColor
                      : const Color(0xFF94A3B8),
                ),
                if (_filtres.actif)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTechList(Color primaryColor) {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_techniciens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _filtres.actif ? Icons.filter_list_off_rounded : Icons.search_off_rounded,
                size: 48,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              Text(
                _filtres.actif
                    ? "Aucun technicien pour ces critères."
                    : "Aucun technicien disponible.",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_filtres.actif) ...[
                const SizedBox(height: 6),
                Text(
                  "Essayez d'élargir vos filtres.",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _techniciens.length,
      itemBuilder: (context, i) => CarteTechnicien(
        tech: _techniciens[i],
        accentColor: primaryColor,
        clientId: widget.userData['id']?.toString(),
        onTap: () => _ouvrirFiche(_techniciens[i], primaryColor),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: _textShadows,
          ),
        ),
        TextButton(
          onPressed: _resetFilters,
          child: const Text(
            "Tout voir",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            "FormelPro par Solution Makers",
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const Text(
            "© 2026 - Côte d'Ivoire & Cameroun",
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
