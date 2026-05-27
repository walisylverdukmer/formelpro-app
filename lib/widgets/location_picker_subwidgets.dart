import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

// ── LocationMapView ───────────────────────────────────────────────────────────

class LocationMapView extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final Color accentColor;
  final bool geocoding;
  final bool gpsLoading;
  final VoidCallback onGps;
  final void Function(MapPosition, bool) onPositionChanged;

  const LocationMapView({
    super.key,
    required this.mapController,
    required this.center,
    required this.accentColor,
    required this.geocoding,
    required this.gpsLoading,
    required this.onGps,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14.0,
            onPositionChanged: onPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.formelpro.app',
            ),
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: accentColor,
                  size: 48,
                  shadows: const [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3))
                  ],
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (geocoding)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          color: accentColor, strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('Recherche adresse…',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF475569))),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: gpsLoading ? null : onGps,
            child: gpsLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: accentColor, strokeWidth: 2))
                : Icon(Icons.my_location_rounded,
                    color: accentColor, size: 22),
          ),
        ),
      ],
    );
  }
}

// ── LocationManualForm ────────────────────────────────────────────────────────

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
      _textField(quartierCtrl, 'Ex: Riviera 2, Zone 4...', Icons.near_me_outlined),
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
      _textField(quartierCtrl, 'Ex: Bastos, Akwa, Bali...', Icons.near_me_outlined),
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

  Widget _textField(TextEditingController ctrl, String label, IconData icon) {
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

// ── LocationBottomBar ─────────────────────────────────────────────────────────

class LocationBottomBar extends StatelessWidget {
  final bool useMap;
  final String ville;
  final String commune;
  final String quartier;
  final bool isCI;
  final Color accentColor;
  final TextEditingController repereCtrl;
  final VoidCallback onConfirm;

  const LocationBottomBar({
    super.key,
    required this.useMap,
    required this.ville,
    required this.commune,
    required this.quartier,
    required this.isCI,
    required this.accentColor,
    required this.repereCtrl,
    required this.onConfirm,
  });

  bool get _hasPreview =>
      useMap && (ville.isNotEmpty || commune.isNotEmpty || quartier.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasPreview) ...[
            _buildAddressPreview(),
            const SizedBox(height: 10),
          ],
          if (useMap) ...[
            _buildRepereField(context),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Valider cette localisation',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.place_outlined, color: accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              [
                if (ville.isNotEmpty) ville,
                if (isCI && commune.isNotEmpty) commune,
                if (quartier.isNotEmpty) quartier,
              ].join(', '),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepereField(BuildContext context) {
    return TextFormField(
      controller: repereCtrl,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: 'Point de repère (optionnel)',
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.place_outlined,
            size: 20, color: Color(0xFF94A3B8)),
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
