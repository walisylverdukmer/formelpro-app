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

  // Mapper catégorie → image asset
  static String? _imageFor(String nom) {
    final n = nom.toLowerCase();
    if (n.contains('élec') || n.contains('electr') ||
        n.contains('énergi') || n.contains('energi')) {
      return 'assets/images/categories/fond_energie.jpg';
    }
    if (n.contains('bâtiment') || n.contains('batiment') ||
        n.contains('maçon') || n.contains('macon') ||
        n.contains('menuis') || n.contains('soudure') ||
        n.contains('métal') || n.contains('metal')) {
      return 'assets/images/categories/fond_batiment.jpg';
    }
    if (n.contains('livraison') || n.contains('transport') || n.contains('gaz')) {
      return 'assets/images/categories/fond_livraison.jpg';
    }
    if (n.contains('ménage') || n.contains('menage') ||
        n.contains('nettoyage') || n.contains('service') ||
        n.contains('coiffure') || n.contains('beauté') ||
        n.contains('beaute')) {
      return 'assets/images/categories/fond_services.jpg';
    }
    if (n.contains('plomb') || n.contains('maison') ||
        n.contains('jardin') || n.contains('serrur') ||
        n.contains('froid') || n.contains('clima') ||
        n.contains('peinture') || n.contains('déco') ||
        n.contains('deco') || n.contains('chauffage') ||
        n.contains('sanitaire')) {
      return 'assets/images/categories/fond_maison.jpg';
    }
    return null;
  }

  // Gradient de fallback par type de catégorie
  static List<Color> _gradientFor(String nom, String pays) {
    final n = nom.toLowerCase();
    if (n.contains('élec') || n.contains('electr')) {
      return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    }
    if (n.contains('plomb')) {
      return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
    if (n.contains('bâtiment') || n.contains('maçon') || n.contains('menuis')) {
      return [const Color(0xFF64748B), const Color(0xFF475569)];
    }
    if (n.contains('ménage') || n.contains('menage') || n.contains('nettoyage')) {
      return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
    if (n.contains('jardin')) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
    if (n.contains('froid') || n.contains('clima')) {
      return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
    }
    if (n.contains('peinture') || n.contains('déco')) {
      return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
    }
    return pays == 'CIV'
        ? [const Color(0xFFE67E22), const Color(0xFFD35400)]
        : [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: List.generate(categories.length, (i) {
            final cat = categories[i];
            return _buildCard(cat['id'].toString(), cat['nom'].toString());
          }),
        ),
      ),
    );
  }

  Widget _buildCard(String id, String nom) {
    final bool isSelected = activeCatId == id;
    final String? imagePath = _imageFor(nom);
    final List<Color> grad = _gradientFor(nom, pays);
    final Color accentColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);

    return GestureDetector(
      onTap: () => onSelect(id, nom),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 96,
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: accentColor, width: 2.5)
                : Border.all(color: Colors.transparent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.09),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fond image ou gradient
                if (imagePath != null)
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildGradient(grad),
                  )
                else
                  _buildGradient(grad),

                // Overlay dégradé sombre en bas
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.25, 1.0],
                    ),
                  ),
                ),

                // Teinte sélection
                if (isSelected)
                  Container(
                    color: accentColor.withValues(alpha: 0.22),
                  ),

                // Nom de la catégorie en bas
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 10,
                  child: Text(
                    nom,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Coche sélection en haut droite
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient(List<Color> grad) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
      ),
    );
  }
}
