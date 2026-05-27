import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formelpro/screens/booking/technician_selection_page.dart';

class SubCategoriesPage extends StatefulWidget {
  final String groupName;
  final String? groupId;
  final Color accentColor;
  final String pays;
  final String? clientId;

  const SubCategoriesPage({
    super.key,
    required this.groupName,
    required this.accentColor,
    required this.pays,
    this.groupId,
    this.clientId,
  });

  @override
  State<SubCategoriesPage> createState() => _SubCategoriesPageState();
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _subCategories = [];
  String? _errorMessage;

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
        n.contains('bâtiment') || n.contains('batiment')) {
      return Icons.foundation_rounded;
    }
    if (n.contains('mécan') || n.contains('mecan') || n.contains('auto')) return Icons.settings_suggest_rounded;
    if (n.contains('froid') || n.contains('clima') || n.contains('frigori')) return Icons.ac_unit_rounded;
    if (n.contains('menuis') || n.contains('bois')) return Icons.handyman_rounded;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<dynamic> response;
      if (widget.groupId != null) {
        // Recherche par parent_id si disponible
        response = await supabase
            .from('categories_services')
            .select('id, nom, description')
            .eq('parent_id', widget.groupId!)
            .order('nom');
      } else {
        // Fallback : recherche par nom de groupe
        response = await supabase
            .from('categories_services')
            .select('id, nom, description')
            .eq('groupe_parent', widget.groupName)
            .order('nom');
      }

      if (mounted) {
        setState(() {
          _subCategories = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur sous-catégories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les services.';
        });
      }
    }
  }

  void _navigateToTechs(Map<String, dynamic> sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianSelectionPage(
          categoryName: sub['nom'] as String? ?? '',
          categoryId: sub['id'].toString(),
          pays: widget.pays,
          accentColor: widget.accentColor,
          clientId: widget.clientId,
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
        title: Text(
          widget.groupName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 19,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : _buildGrid(),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56,
                color: widget.accentColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 15),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadSubCategories,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
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

  Widget _buildGrid() {
    if (_subCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category_outlined,
                    size: 40, color: widget.accentColor.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun service disponible',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun service n\'est encore référencé dans cette catégorie.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 14, height: 1.5),
              ),
            ],
          ),
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToTechs(sub),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Voir les techniciens',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: iconColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
