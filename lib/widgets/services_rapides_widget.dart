import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/booking/demande_service_domestique_page.dart';

// Callback étendu : query métier + typePrestation optionnel + disponibleSeulement
typedef OnServiceTap = void Function(
  String categorieNom, {
  String? typePrestation,
  bool disponibleSeulement,
});

class ServicesRapidesWidget extends StatelessWidget {
  final Color accentColor;
  final OnServiceTap onServiceTap;
  final String? commune; // commune de l'utilisateur pour le contexte gaz

  const ServicesRapidesWidget({
    super.key,
    required this.accentColor,
    required this.onServiceTap,
    this.commune,
  });

  static const List<Map<String, dynamic>> _services = [
    {
      'label': 'Livraison\ngaz',
      'image': 'assets/images/metiers/fond_lovraison_gaz.jpg',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEF4444),
      'query': 'gaz',
      'type': 'gaz',
    },
    {
      'label': 'Femme de\nménage',
      'image': 'assets/images/metiers/fond_menagegère.jpg',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF8B5CF6),
      'query': 'ménage',
      'type': 'menage',
      'securise': true,
    },
    {
      'label': 'Électricien',
      'image': 'assets/images/metiers/Fond_electricité.jpg',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFFF59E0B),
      'query': 'électricité',
      'type': 'standard',
    },
    {
      'label': 'Plombier',
      'image': null,
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF3B82F6),
      'query': 'plomberie',
      'type': 'standard',
    },
    {
      'label': 'Menuisier',
      'image': null,
      'icon': Icons.carpenter_rounded,
      'color': Color(0xFF92400E),
      'query': 'menuiserie',
      'type': 'standard',
    },
  ];

  void _handleTap(BuildContext context, Map<String, dynamic> service) {
    final String query = service['query'] as String;
    final String type = service['type'] as String;
    final Color color = service['color'] as Color;

    if (type == 'gaz') {
      _showGazSheet(context, query, color);
    } else if (type == 'menage') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandServiceDomestiquePage(accentColor: color),
        ),
      );
    } else {
      onServiceTap(query, disponibleSeulement: false);
    }
  }

  void _showGazSheet(BuildContext context, String query, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GazSheet(
        accentColor: color,
        commune: commune,
        onConfirm: (bool dipoNow) {
          onServiceTap(
            query,
            disponibleSeulement: dipoNow,
          );
        },
      ),
    );
  }

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
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _services.length,
            itemBuilder: (context, i) {
              final s = _services[i];
              return _ServiceCard(
                label: s['label'] as String,
                imagePath: s['image'] as String?,
                iconData: s['icon'] as IconData,
                color: s['color'] as Color,
                securise: s['securise'] as bool? ?? false,
                onTap: () => _handleTap(context, s),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Sheet contextuelle : Livraison Gaz ───────────────────────────────────────

class _GazSheet extends StatefulWidget {
  final Color accentColor;
  final String? commune;
  final void Function(bool disponibleNow) onConfirm;

  const _GazSheet({
    required this.accentColor,
    required this.onConfirm,
    this.commune,
  });

  @override
  State<_GazSheet> createState() => _GazSheetState();
}

class _GazSheetState extends State<_GazSheet> {
  bool _dipoNow = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Livraison de gaz',
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A)),
                  ),
                  if (widget.commune != null && widget.commune!.isNotEmpty)
                    Text(
                      'Zone : ${widget.commune}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chips info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoBadge(Icons.flash_on_rounded, 'Livraison rapide',
                  const Color(0xFFEF4444)),
              _infoBadge(Icons.location_on_outlined, 'Zone desservie',
                  const Color(0xFF3B82F6)),
              _infoBadge(Icons.access_time_rounded, 'Sur demande',
                  const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponibles maintenant uniquement',
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF1E293B)),
              ),
              Switch(
                value: _dipoNow,
                onChanged: (v) => setState(() => _dipoNow = v),
                activeThumbColor: widget.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(_dipoNow);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Trouver un livreur',
                style:
                    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final String? imagePath;
  final IconData iconData;
  final Color color;
  final bool securise;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.label,
    required this.imagePath,
    required this.iconData,
    required this.color,
    required this.onTap,
    this.securise = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
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
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: color.withValues(alpha: 0.12)),
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black
                          .withValues(alpha: imagePath != null ? 0.6 : 0.0),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
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
                    color: imagePath != null
                        ? Colors.white
                        : const Color(0xFF0F172A),
                    height: 1.3,
                    shadows: imagePath != null
                        ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                        : null,
                  ),
                ),
              ),
              if (imagePath == null)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Icon(iconData, color: color, size: 20),
                    ),
                  ),
                ),
              if (securise)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: Colors.white, size: 7),
                        SizedBox(width: 2),
                        Text('Sécurisé',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.bold)),
                      ],
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
