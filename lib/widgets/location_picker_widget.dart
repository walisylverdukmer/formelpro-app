import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class LocationPickerWidget extends StatefulWidget {
  final Color accentColor;
  final String paysCode;

  const LocationPickerWidget({
    super.key,
    required this.accentColor,
    required this.paysCode,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  static const _defaultCIV = LatLng(5.3544, -4.0023);
  static const _defaultCMR = LatLng(3.8480, 11.5021);

  final _mapController = MapController();
  final _villeCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();

  Timer? _debounce;
  bool _useMap = true;
  bool _gpsLoading = false;
  bool _geocoding = false;

  late LatLng _center;
  String _ville = '';
  String _commune = '';
  String _quartier = '';

  bool get _isCI => widget.paysCode == 'CIV';

  @override
  void initState() {
    super.initState();
    _center = _isCI ? _defaultCIV : _defaultCMR;
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectGPS());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _villeCtrl.dispose();
    _communeCtrl.dispose();
    _quartierCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectGPS() async {
    if (!mounted) return;
    setState(() => _gpsLoading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12),
        );
        if (!mounted) return;
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() => _center = loc);
        _mapController.move(loc, 15.0);
        await _reverseGeocode(loc);
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng loc) async {
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=${loc.latitude}&lon=${loc.longitude}&accept-language=fr',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': 'FormelPro/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? {};
        final ville =
            addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? '';
        final commune = addr['city_district'] ?? addr['suburb'] ?? '';
        var quartier =
            addr['neighbourhood'] ?? addr['quarter'] ?? addr['suburb'] ?? '';
        if (quartier == commune && commune.isNotEmpty) quartier = '';
        setState(() {
          _ville = ville.toString();
          _commune = commune.toString();
          _quartier = quartier.toString();
        });
      }
    } catch (e) {
      debugPrint('Geocode error: $e');
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _onPositionChanged(MapPosition position, bool hasGesture) {
    final center = position.center;
    if (hasGesture && center != null) {
      setState(() => _center = center);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 900), () {
        _reverseGeocode(center);
      });
    }
  }

  void _confirm() {
    final String ville;
    final String commune;
    final String quartier;
    if (_useMap) {
      ville = _ville;
      commune = _isCI ? _commune : '';
      quartier = _quartier;
    } else {
      ville = _villeCtrl.text.trim();
      commune = _communeCtrl.text.trim();
      quartier = _quartierCtrl.text.trim();
    }
    Navigator.pop(context, {
      'ville': ville,
      'commune': commune,
      'quartier': quartier,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ma localisation',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          _buildModeToggle(),
          Expanded(child: _useMap ? _buildMapView() : _buildManualView()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildChip('Carte', Icons.map_outlined, true),
          const SizedBox(width: 8),
          _buildChip('Saisie manuelle', Icons.edit_outlined, false),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isMap) {
    final sel = _useMap == isMap;
    return GestureDetector(
      onTap: () => setState(() => _useMap = isMap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? widget.accentColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: sel ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14.0,
            onPositionChanged: _onPositionChanged,
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
                  color: widget.accentColor,
                  size: 48,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
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
        if (_geocoding)
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
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        color: widget.accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recherche adresse…',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                      ),
                    ),
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
            onPressed: _gpsLoading ? null : _detectGPS,
            child: _gpsLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: widget.accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: widget.accentColor,
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField(_villeCtrl, 'Ville', Icons.location_city_outlined),
          if (_isCI) ...[
            const SizedBox(height: 14),
            _buildTextField(_communeCtrl, 'Commune', Icons.map_outlined),
          ],
          const SizedBox(height: 14),
          _buildTextField(
            _quartierCtrl,
            'Quartier / Zone',
            Icons.near_me_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
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
          borderSide:
              BorderSide(color: widget.accentColor.withValues(alpha: 0.6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasPreview = _useMap &&
        (_ville.isNotEmpty || _commune.isNotEmpty || _quartier.isNotEmpty);
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
          if (hasPreview) ...[
            _buildAddressPreview(),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Valider cette localisation',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          Icon(Icons.place_outlined, color: widget.accentColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              [
                if (_ville.isNotEmpty) _ville,
                if (_isCI && _commune.isNotEmpty) _commune,
                if (_quartier.isNotEmpty) _quartier,
              ].join(', '),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
