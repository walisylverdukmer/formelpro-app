import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/widgets/carte_technicien.dart';
import 'package:formelpro/widgets/categories_chips.dart';
import 'package:formelpro/widgets/filtres_techniciens.dart';
import 'package:formelpro/widgets/services_rapides_widget.dart';
import 'package:formelpro/widgets/zone_stats_widget.dart';
import 'package:formelpro/screens/dashboard/details_technicien.dart';
import 'package:formelpro/screens/booking/technician_selection_page.dart';

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
          if (mounted) {
            setState(() {
              _techniciens = [];
              _isFetching = false;
            });
          }
          return;
        }
      } else if (_filtres.categorieNom != null) {
        final cats = await supabase
            .from('categories_services')
            .select('id')
            .ilike('nom', '%${_filtres.categorieNom}%')
            .eq('est_valide', true);
        if (cats.isEmpty) {
          if (mounted) {
            setState(() {
              _techniciens = [];
              _isFetching = false;
            });
          }
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
          if (mounted) {
            setState(() {
              _techniciens = [];
              _isFetching = false;
            });
          }
          return;
        }
      }

      var query = supabase
          .from('utilisateurs')
          .select(
            'id, nom_complet, metier_personnalise, savoir_faire, photo_profil_url, score_global, note_moyenne, ville, commune, quartier, disponible, is_premium, premium_level, est_en_ligne, telephone, is_identite_verifiee',
          )
          .eq('role', 'technicien')
          .eq('pays', pays);

      if (techIdsFiltres != null) query = query.inFilter('id', techIdsFiltres);
      // Fallback: filtre par nom de catégorie quand categorieId absent (services rapides)
      if (techIdsFiltres == null && _filtres.categorieNom != null && search.isEmpty) {
        query = query.or(
          'metier_personnalise.ilike.%${_filtres.categorieNom}%,savoir_faire.ilike.%${_filtres.categorieNom}%',
        );
      }
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
                child: Image.asset(
                  flagPath,
                  width: 70,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isCI ? "FormelPro Côte d'Ivoire" : "FormelPro Cameroun",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isCI
                    ? "Trouvez les artisans qualifiés de proximité."
                    : "Accédez au réseau certifié au Cameroun.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    final String pays = widget.userData['pays'] ?? 'CIV';
    final String prenom = widget.userData['prenom'] ?? 'vous';
    final Color primaryColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String flagPath =
        pays == 'CIV' ? "assets/images/ci.jpg" : "assets/images/cmr.jpg";

    final String bgImage = pays == 'CIV'
        ? 'assets/images/fond_ci.jpeg'
        : 'assets/images/fond_cmr.jpeg';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF8FAFC).withValues(alpha: 0.88),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _buildHeader(prenom, flagPath, primaryColor),
              const SizedBox(height: 16),
              _buildHeroBanner(pays, primaryColor),
              const SizedBox(height: 20),
              ServicesRapidesWidget(
                accentColor: primaryColor,
                onServiceTap: (query) {
                  setState(() {
                    _filtres = FiltresTechniciens(
                      categorieNom: query,
                      disponibleSeulement: _filtres.disponibleSeulement,
                      noteMin: _filtres.noteMin,
                    );
                  });
                  _fetchTechniciens();
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ZoneStatsWidget(
                  pays: pays,
                  commune: widget.userData['commune'] as String?,
                  accentColor: primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSectionTitle(
                  "Catégories populaires",
                  accentColor: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              CategoriesChips(
                pays: pays,
                shimmerController: _shimmerController,
                activeCatId: _filtres.categorieId,
                categories: _topCategories,
                onSelect: (id, nom) {
                  // Premier tap : filtre en place + scroll vers les résultats
                  // Deuxième tap sur la même carte : ouvre la page dédiée
                  if (_filtres.categorieId == id) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TechnicianSelectionPage(
                          categoryName: nom,
                          categoryId: id,
                          pays: pays,
                          accentColor: primaryColor,
                          clientId: widget.userData['id']?.toString(),
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _filtres = FiltresTechniciens(
                        categorieId: id,
                        categorieNom: nom,
                        disponibleSeulement: _filtres.disponibleSeulement,
                        noteMin: _filtres.noteMin,
                      );
                    });
                    _fetchTechniciens();
                  }
                },
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSectionTitle(
                  "Techniciens recommandés",
                  accentColor: primaryColor,
                  onMore: _resetFilters,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTechList(primaryColor),
              ),
              const SizedBox(height: 32),
              _buildFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildHeader(String prenom, String flagPath, Color primaryColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Bonjour $prenom 👋",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  flagPath,
                  width: 28,
                  height: 18,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Besoin d'un pro ?",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(primaryColor),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _fetchTechniciens(),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: "Rechercher un artisan, un métier...",
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          suffixIcon: GestureDetector(
            onTap: () => _openFiltres(primaryColor),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _filtres.actif ? primaryColor : const Color(0xFF94A3B8),
                  size: 20,
                ),
                if (_filtres.actif)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 7,
                      height: 7,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(String pays, Color primaryColor) {
    final heroImage = pays == 'CIV'
        ? 'assets/images/fond_ci.jpeg'
        : 'assets/images/fond_cmr.jpeg';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(heroImage),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF0F172A).withValues(alpha: 0.78),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Experts certifiés",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Proches de vous",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 13, color: primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    "Explorer",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    Color? accentColor,
    VoidCallback? onMore,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              "Tout voir",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: accentColor ?? const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTechList(Color primaryColor) {
    if (_isFetching) {
      return Column(
        children: List.generate(3, (_) => _buildShimmerCard()),
      );
    }
    if (_techniciens.isEmpty) {
      return _buildEmptyState(primaryColor);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _techniciens.length,
      itemBuilder: (context, i) => CarteTechnicien(
        tech: _techniciens[i],
        accentColor: primaryColor,
        clientId: widget.userData['id']?.toString(),
        onTap: () => _ouvrirFiche(_techniciens[i], primaryColor),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final bool hasFilter = _filtres.actif;
    final bool hasCat = _filtres.categorieNom != null || _filtres.categorieId != null;

    String title;
    String subtitle;
    IconData icon;

    if (hasCat) {
      title = "Aucun expert trouvé pour ce métier";
      subtitle = "Aucun prestataire certifié n'est encore référencé pour ce service dans votre zone.";
      icon = Icons.person_search_rounded;
    } else if (hasFilter) {
      title = "Aucun résultat";
      subtitle = "Aucun technicien ne correspond à vos critères de recherche.";
      icon = Icons.filter_list_off_rounded;
    } else {
      title = "Aucun technicien disponible";
      subtitle = "Aucun prestataire n'est encore référencé dans votre zone. Revenez bientôt !";
      icon = Icons.groups_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: primaryColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF334155),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilter) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Réinitialiser les filtres"),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            "FormelPro par Solution Makers",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "© 2026 — Côte d'Ivoire & Cameroun",
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
