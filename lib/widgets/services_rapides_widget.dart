import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      'color': Color(0xFFEF4444),
      'query': 'gaz',
      'type': 'gaz',
    },
    {
      'label': 'Femme de\nménage',
      'image': 'assets/images/metiers/fond_menagegère.jpg',
      'color': Color(0xFF8B5CF6),
      'query': 'ménage',
      'type': 'menage',
    },
    {
      'label': 'Électricien',
      'image': 'assets/images/metiers/Fond_electricité.jpg',
      'color': Color(0xFFF59E0B),
      'query': 'électricité',
      'type': 'standard',
    },
    {
      'label': 'Plombier',
      'image': null,
      'color': Color(0xFF3B82F6),
      'query': 'plomberie',
      'type': 'standard',
    },
    {
      'label': 'Menuisier',
      'image': null,
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
      _showMenageSheet(context, query, color);
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

  void _showMenageSheet(BuildContext context, String query, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenagereSheet(
        accentColor: color,
        onSelect: (String type) {
          onServiceTap(
            query,
            typePrestation: type,
            disponibleSeulement: false,
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

// ─── Sheet contextuelle : Femme de ménage ─────────────────────────────────────

class _MenagereSheet extends StatefulWidget {
  final Color accentColor;
  final void Function(String typePrestation) onSelect;

  const _MenagereSheet({
    required this.accentColor,
    required this.onSelect,
  });

  @override
  State<_MenagereSheet> createState() => _MenagereSheetState();
}

class _MenagereSheetState extends State<_MenagereSheet> {
  static const List<Map<String, dynamic>> _types = [
    {
      'label': 'Résidente',
      'subtitle': "Vit à domicile chez l'employeur",
      'icon': Icons.home_rounded,
      'color': Color(0xFF8B5CF6),
      'value': 'résidente',
    },
    {
      'label': 'Journalière',
      'subtitle': 'Travaille et rentre chaque soir',
      'icon': Icons.wb_sunny_rounded,
      'color': Color(0xFFF59E0B),
      'value': 'journalière',
    },
    {
      'label': 'Ponctuelle',
      'subtitle': 'Ménage, vaisselle, lessive à la demande',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF22C55E),
      'value': 'ponctuelle',
    },
  ];

  // null = étape 1 (choix type), non-null = étape 2 (formulaire)
  String? _selectedType;

  final _adresseCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _onTypeSelected(String type) {
    setState(() => _selectedType = type);
  }

  void _onConfirm() {
    setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _confirmed
            ? _buildConfirmation()
            : _selectedType == null
                ? _buildTypeSelection()
                : _buildForm(),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      key: const ValueKey('type'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandle(),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cleaning_services_rounded,
                color: Color(0xFF8B5CF6), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Type de prestation',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A)),
          ),
        ]),
        const SizedBox(height: 20),
        ..._types.map((t) => _TypeOption(
              label: t['label'] as String,
              subtitle: t['subtitle'] as String,
              icon: t['icon'] as IconData,
              color: t['color'] as Color,
              onTap: () => _onTypeSelected(t['value'] as String),
            )),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSelect('ménage');
          },
          child: Text('Voir toutes les ménagères',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandle(),
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _selectedType = null),
            child: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ménagère ${_selectedType ?? ''}',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A)),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Confirmez vos informations pour que notre équipe vous contacte.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _adresseCtrl,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Votre adresse / quartier *',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(Icons.location_on_rounded,
                color: widget.accentColor, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.accentColor)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtrl,
          style: GoogleFonts.inter(fontSize: 13),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Message complémentaire (horaires, exigences...)',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.accentColor)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _adresseCtrl.text.trim().isEmpty ? null : _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Envoyer ma demande',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        // Le bouton déclenche la confirmation sans aller vers la liste des techs
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF8B5CF6), size: 36),
        ),
        const SizedBox(height: 16),
        Text('Demande envoyée !',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
          ),
          child: Text(
            'Merci.\nNotre équipe vous recontactera sous peu pour un entretien et une sélection adaptée de ménagère.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF334155), height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Fermer',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: color.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card service rapide ───────────────────────────────────────────────────────

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
                      child:
                          Icon(Icons.handyman_rounded, color: color, size: 18),
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
