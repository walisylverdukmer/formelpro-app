import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServicesRapidesWidget extends StatelessWidget {
  final Color accentColor;
  final Function(String categorieNom) onServiceTap;

  const ServicesRapidesWidget({
    super.key,
    required this.accentColor,
    required this.onServiceTap,
  });

  static const List<Map<String, dynamic>> _services = [
    {
      'label': 'Livraison\ngaz',
      'image': 'assets/images/metiers/fond_lovraison_gaz.jpg',
      'color': Color(0xFFEF4444),
      'query': 'gaz',
    },
    {
      'label': 'Femme de\nménage',
      'image': 'assets/images/metiers/fond_menagegère.jpg',
      'color': Color(0xFF8B5CF6),
      'query': 'ménage',
    },
    {
      'label': 'Électricien',
      'image': 'assets/images/metiers/Fond_electricité.jpg',
      'color': Color(0xFFF59E0B),
      'query': 'électricité',
    },
    {
      'label': 'Plombier',
      'image': null,
      'color': Color(0xFF3B82F6),
      'query': 'plomberie',
    },
    {
      'label': 'Menuisier',
      'image': null,
      'color': Color(0xFF92400E),
      'query': 'menuiserie',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Services rapides',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1 clic',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _services.length,
            itemBuilder: (context, i) {
              final s = _services[i];
              return _ServiceCard(
                label: s['label'] as String,
                imagePath: s['image'] as String?,
                color: s['color'] as Color,
                onTap: () => onServiceTap(s['query'] as String),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fond image ou couleur
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withValues(alpha: 0.12),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),

              // Overlay sombre en bas
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: imagePath != null ? 0.6 : 0.0),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Label
              Positioned(
                left: 6,
                right: 6,
                bottom: 10,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: imagePath != null ? Colors.white : const Color(0xFF0F172A),
                    height: 1.3,
                    shadows: imagePath != null
                        ? const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),

              // Dot couleur en haut si pas d'image
              if (imagePath == null)
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.handyman_rounded, color: color, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
