import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationManualForm extends StatelessWidget {
  final bool isCI;
  final Color accentColor;
  final String? selectedRegion;
  final String? selectedCommune;
  final String? selectedVilleCMR;
  final TextEditingController quartierCtrl;
  final TextEditingController repereCtrl;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onCommuneChanged;
  final ValueChanged<String?> onVilleCMRChanged;

  static const Map<String, List<String>> regionsCIV = {
    'Abidjan': [
      'Abobo', 'Adjamé', 'Attécoubé', 'Cocody', 'Koumassi',
      'Marcory', 'Plateau', 'Port-Bouët', 'Treichville', 'Yopougon'
    ],
    'Yamoussoukro': ['Yamoussoukro Centre'],
    'Bouaké': ['Bouaké Centre', 'Koko', 'Dar-Es-Salam'],
    'Daloa': ['Daloa Centre'],
    'San Pedro': ['San Pedro Centre', 'Bardot'],
    'Korhogo': ['Korhogo Centre'],
    'Man': ['Man Centre'],
    'Gagnoa': ['Gagnoa Centre'],
    'Divo': ['Divo Centre'],
    'Abengourou': ['Abengourou Centre'],
  };

  static const List<String> villesCMR = [
    'Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua',
    'Bafoussam', 'Ngaoundéré', 'Bertoua', 'Kumba', 'Edéa',
    'Nkongsamba', 'Kribi', 'Limbé', 'Buéa', 'Ebolowa',
  ];

  const LocationManualForm({
    super.key,
    required this.isCI,
    required this.accentColor,
    required this.quartierCtrl,
    required this.repereCtrl,
    required this.onRegionChanged,
    required this.onCommuneChanged,
    required this.onVilleCMRChanged,
    this.selectedRegion,
    this.selectedCommune,
    this.selectedVilleCMR,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isCI ? _buildCIVFields() : _buildCMRFields(),
      ),
    );
  }

  List<Widget> _buildCIVFields() {
    final communes = selectedRegion != null
        ? (regionsCIV[selectedRegion] ?? <String>[])
        : <String>[];
    return [
      _label('Région'),
      const SizedBox(height: 6),
      _dropdown<String>(
        value: selectedRegion,
        hint: 'Sélectionner une région',
        icon: Icons.location_on_outlined,
        items: regionsCIV.keys.toList(),
        onChanged: (v) {
          onRegionChanged(v);
          onCommuneChanged(null);
        },
      ),
      const SizedBox(height: 14),
      _label('Commune'),
      const SizedBox(height: 6),
      _dropdown<String>(
        value: selectedCommune,
        hint: communes.isEmpty
            ? 'Choisir une région d\'abord'
            : 'Sélectionner une commune',
        icon: Icons.map_outlined,
        items: communes,
        onChanged: communes.isEmpty ? null : onCommuneChanged,
      ),
      const SizedBox(height: 14),
      _label('Quartier / Zone'),
      const SizedBox(height: 6),
      _textField(
          quartierCtrl, 'Ex: Riviera 2, Zone 4...', Icons.near_me_outlined),
      const SizedBox(height: 14),
      _label('Point de repère (optionnel)'),
      const SizedBox(height: 6),
      _textField(repereCtrl,
          'Ex: Face à la pharmacie, Derrière la mairie...', Icons.place_outlined),
    ];
  }

  List<Widget> _buildCMRFields() {
    return [
      _label('Ville'),
      const SizedBox(height: 6),
      _dropdown<String>(
        value: selectedVilleCMR,
        hint: 'Sélectionner une ville',
        icon: Icons.location_city_outlined,
        items: villesCMR,
        onChanged: onVilleCMRChanged,
      ),
      const SizedBox(height: 14),
      _label('Quartier / Zone'),
      const SizedBox(height: 6),
      _textField(
          quartierCtrl, 'Ex: Bastos, Akwa, Bali...', Icons.near_me_outlined),
      const SizedBox(height: 14),
      _label('Point de repère (optionnel)'),
      const SizedBox(height: 6),
      _textField(repereCtrl,
          'Ex: Près du marché central, Face à l\'église...', Icons.place_outlined),
    ];
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 0.3),
      );

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
  }) {
    final disabled = onChanged == null;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          ),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more_rounded,
                  size: 20, color: Color(0xFF94A3B8)),
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF0F172A)),
              hint: Text(hint,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF94A3B8))),
              padding: const EdgeInsets.only(left: 10, right: 8),
              items: items
                  .map((e) =>
                      DropdownMenuItem<T>(value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
