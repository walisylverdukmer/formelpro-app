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
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEF4444),
      'query': 'gaz',
    },
    {
      'label': 'Courses',
      'icon': Icons.shopping_basket_rounded,
      'color': Color(0xFF10B981),
      'query': 'courses',
    },
    {
      'label': 'Femme de\nménage',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF8B5CF6),
      'query': 'ménage',
    },
    {
      'label': 'Plombier',
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF3B82F6),
      'query': 'plomberie',
    },
    {
      'label': 'Électricien',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFFF59E0B),
      'query': 'électricité',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _services.length,
            itemBuilder: (context, i) {
              final s = _services[i];
              return _ServiceCard(
                label: s['label'] as String,
                icon: s['icon'] as IconData,
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
