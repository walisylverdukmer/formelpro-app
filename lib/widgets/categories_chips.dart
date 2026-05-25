import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesChips extends StatelessWidget {
  final String pays;
  final AnimationController shimmerController;
  final String? activeCatId;
  final List<Map<String, dynamic>> categories;
  final void Function(String id, String nom) onSelect;

  const CategoriesChips({
    super.key,
    required this.pays,
    required this.shimmerController,
    required this.onSelect,
    required this.categories,
    this.activeCatId,
  });

  static IconData _iconFor(String nom) {
    final n = nom.toLowerCase();
    if (n.contains('plomb')) return Icons.water_drop;
    if (n.contains('élec') || n.contains('electr')) return Icons.electric_bolt;
    if (n.contains('maçon') || n.contains('macon') ||
        n.contains('bâtiment') || n.contains('batiment')) { return Icons.foundation; }
    if (n.contains('mécan') || n.contains('mecan') || n.contains('auto')) {
      return Icons.settings_suggest;
    }
    if (n.contains('froid') || n.contains('clima') || n.contains('frigori')) {
      return Icons.ac_unit;
    }
    if (n.contains('menuis') || n.contains('bois') || n.contains('carpen')) {
      return Icons.handyman;
    }
    if (n.contains('peinture') || n.contains('déco') || n.contains('deco')) {
      return Icons.format_paint;
    }
    if (n.contains('jardin')) return Icons.park;
    if (n.contains('soudure') || n.contains('métal') || n.contains('metal')) {
      return Icons.hardware;
    }
    if (n.contains('inform') || n.contains('réseau') || n.contains('reseau')) {
      return Icons.computer;
    }
    if (n.contains('chauffage') || n.contains('sanitaire')) return Icons.thermostat;
    if (n.contains('toiture') || n.contains('couver')) return Icons.roofing;
    if (n.contains('serrur')) return Icons.lock;
    return Icons.build_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final cat = categories[i];
                return _buildChip(
                  cat['id'].toString(),
                  cat['nom'].toString(),
                  _iconFor(cat['nom'].toString()),
                  i,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String id, String titre, IconData icon, int index) {
    final bool isSelected = activeCatId == id;
    final List<Color> colors = pays == 'CIV'
        ? (index % 2 == 0
            ? [const Color(0xFF1E8449), const Color(0xFF2ECC71)]
            : [const Color(0xFFD35400), const Color(0xFFF39C12)])
        : (index % 2 == 0
            ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
            : [const Color(0xFFC0392B), const Color(0xFFE74C3C)]);

    return GestureDetector(
      onTap: () => onSelect(id, titre),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: shimmerController,
              builder: (context, _) {
                final v = shimmerController.value;
                return Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors[0],
                        colors[1],
                        Colors.white.withValues(alpha: 0.3),
                        colors[0],
                      ],
                      stops: [
                        0.0,
                        (v - 0.2).clamp(0.01, 0.99),
                        v.clamp(0.02, 1.0),
                        (v + 0.2).clamp(0.03, 1.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : null,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(
                titre,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1.5),
                      blurRadius: 4.0,
                      color: Color(0xBF000000),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
