import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formelpro/screens/interventions/demande_intervention_page.dart';

class SubCategoriesPage extends StatefulWidget {
  final String groupName;
  final Color accentColor;

  const SubCategoriesPage({
    super.key,
    required this.groupName,
    required this.accentColor,
  });

  @override
  State<SubCategoriesPage> createState() => _SubCategoriesPageState();
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _subCategories = [];

  static const List<Color> _palette = [
    Color(0xFF1E8449),
    Color(0xFFD35400),
    Color(0xFF2471A3),
    Color(0xFF7D3C98),
    Color(0xFFB7950B),
    Color(0xFF1F618D),
    Color(0xFF922B21),
    Color(0xFF117A65),
  ];

  static IconData _iconFor(String nom) {
    final n = nom.toLowerCase();
    if (n.contains('plomb')) return Icons.water_drop_rounded;
    if (n.contains('élec') || n.contains('electr')) return Icons.electric_bolt_rounded;
    if (n.contains('maçon') || n.contains('macon') ||
        n.contains('bâtiment') || n.contains('batiment')) { return Icons.foundation_rounded; }
    if (n.contains('mécan') || n.contains('mecan') || n.contains('auto')) return Icons.settings_suggest_rounded;
    if (n.contains('froid') || n.contains('clima') || n.contains('frigori')) return Icons.ac_unit_rounded;
    if (n.contains('menuis') || n.contains('bois') || n.contains('carpen')) return Icons.handyman_rounded;
    if (n.contains('peinture') || n.contains('déco') || n.contains('deco')) return Icons.format_paint_rounded;
    if (n.contains('jardin')) return Icons.park_rounded;
    if (n.contains('soudure') || n.contains('métal') || n.contains('metal')) return Icons.hardware_rounded;
    if (n.contains('inform') || n.contains('réseau') || n.contains('reseau')) return Icons.computer_rounded;
    if (n.contains('chauffage') || n.contains('sanitaire')) return Icons.thermostat_rounded;
    if (n.contains('toiture') || n.contains('couver')) return Icons.roofing_rounded;
    if (n.contains('serrur')) return Icons.lock_rounded;
    if (n.contains('ménage') || n.contains('menage') || n.contains('nettoy')) return Icons.cleaning_services_rounded;
    return Icons.build_rounded;
  }

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    try {
      final response = await supabase
          .from('categories_services')
          .select('id, nom, description')
          .eq('groupe_parent', widget.groupName)
          .eq('est_valide', true)
          .order('nom');

      if (mounted) {
        setState(() {
          _subCategories = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur sous-catégories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: Text(
          widget.groupName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 19,
          ),
        ),
      ),
      body: _isLoading ? _buildLoading() : _buildGrid(),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_subCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              'Aucun service disponible pour le moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: _subCategories.length,
      itemBuilder: (context, index) =>
          _buildCategoryCard(_subCategories[index], index),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> sub, int index) {
    final Color iconColor = _palette[index % _palette.length];
    final IconData icon = _iconFor(sub['nom'] as String? ?? '');
    final String nom = sub['nom'] as String? ?? '';
    final String? description = sub['description'] as String?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeInterventionPage(
            categoryName: nom,
            categoryId: sub['id'].toString(),
            accentColor: widget.accentColor,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DemandeInterventionPage(
                  categoryName: nom,
                  categoryId: sub['id'].toString(),
                  accentColor: widget.accentColor,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    nom,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
