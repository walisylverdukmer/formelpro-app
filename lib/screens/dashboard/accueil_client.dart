import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:formelpro/services/technicien_service.dart';
import 'package:formelpro/widgets/carte_technicien.dart';
import 'package:formelpro/widgets/categories_chips.dart';
import 'package:formelpro/widgets/filtres_techniciens.dart';
import 'package:formelpro/widgets/services_rapides_widget.dart';
import 'package:formelpro/widgets/zone_stats_widget.dart';
import 'package:formelpro/widgets/experts_pres_widget.dart';
import 'package:formelpro/widgets/accueil_header.dart';
import 'package:formelpro/widgets/accueil_hero_banner.dart';
import 'package:formelpro/widgets/technicien_empty_state.dart';
import 'package:formelpro/widgets/shimmer_card.dart';
import 'package:formelpro/widgets/country_welcome_modal.dart';
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
  List<Map<String, dynamic>> _techniciens = [];
  List<Map<String, dynamic>> _topCategories = [];
  bool _isFetching = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _offset = 0;
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
      showCountryWelcomeModal(context, widget.userData);
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
      final cats = await TechnicienService.fetchTopCategories();
      if (mounted) setState(() => _topCategories = cats);
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
    }
  }

  Future<void> _fetchTechniciens() async {
    setState(() { _isFetching = true; _offset = 0; });
    try {
      final techs = await TechnicienService.fetchTechniciens(
        pays: widget.userData['pays'] ?? 'CIV',
        filtres: _filtres,
        search: _searchController.text.trim(),
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _techniciens = techs;
          _isFetching = false;
          _hasMore = techs.length == TechnicienService.pageSize;
          _offset = techs.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch techniciens: $e');
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final more = await TechnicienService.fetchTechniciens(
        pays: widget.userData['pays'] ?? 'CIV',
        filtres: _filtres,
        search: _searchController.text.trim(),
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _techniciens = [..._techniciens, ...more];
          _hasMore = more.length == TechnicienService.pageSize;
          _offset += more.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur load more: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _ouvrirFiche(Map<String, dynamic> tech, Color primaryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailsTechnicien(tech: tech, accentColor: primaryColor),
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
                color: const Color(0xFFF8FAFC).withValues(alpha: 0.88)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccueilHeader(
                    prenom: prenom,
                    flagPath: flagPath,
                    primaryColor: primaryColor,
                    paysCode: pays,
                    commune: _filtres.commune ??
                        widget.userData['commune'] as String?,
                    filtresCount: _filtres.count,
                    searchController: _searchController,
                    onSearch: _fetchTechniciens,
                    onOpenFiltres: () => _openFiltres(primaryColor),
                    onLocationPicked: (result) {
                      if (!mounted) return;
                      setState(() {
                        _filtres = _filtres.copyWith(
                          commune: result['commune'] as String?,
                          quartier: result['quartier'] as String?,
                        );
                      });
                      _fetchTechniciens();
                    },
                  ),
                  const SizedBox(height: 16),
                  AccueilHeroBanner(pays: pays, primaryColor: primaryColor),
                  const SizedBox(height: 20),
                  ServicesRapidesWidget(
                    accentColor: primaryColor,
                    commune: widget.userData['commune'] as String?,
                    onServiceTap: (query,
                        {typePrestation, disponibleSeulement = false}) {
                      setState(() {
                        _filtres = FiltresTechniciens(
                          categorieNom: query,
                          typePrestation: typePrestation,
                          disponibleSeulement: disponibleSeulement,
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
                  ExpertsPresWidget(
                    pays: pays,
                    accentColor: primaryColor,
                    commune: widget.userData['commune'] as String?,
                    clientId: widget.userData['id']?.toString(),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSectionTitle("Catégories populaires",
                        accentColor: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  CategoriesChips(
                    pays: pays,
                    shimmerController: _shimmerController,
                    activeCatId: _filtres.categorieId,
                    categories: _topCategories,
                    onSelect: (id, nom) {
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
        children: List.generate(3, (_) => const ShimmerCard()),
      );
    }
    if (_techniciens.isEmpty) {
      return TechnicienEmptyState(
        filtres: _filtres,
        primaryColor: primaryColor,
        onReset: _resetFilters,
      );
    }
    return Column(
      children: [
        ListView.builder(
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
        ),
        if (_hasMore) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoadingMore ? null : _loadMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoadingMore
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: primaryColor, strokeWidth: 2),
                    )
                  : Text(
                      'Charger plus de techniciens',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            "FormelPro par Solution Makers",
            style:
                GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 4),
          Text(
            "© 2026 — Côte d'Ivoire & Cameroun",
            style:
                GoogleFonts.inter(fontSize: 10, color: const Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}
