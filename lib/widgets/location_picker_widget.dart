import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'location_picker_subwidgets.dart';

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
  final _quartierCtrl = TextEditingController();
  final _repereCtrl = TextEditingController();

  Timer? _debounce;
  bool _useMap = true;
  bool _gpsLoading = false;
  bool _geocoding = false;

  late LatLng _center;
  String _ville = '';
  String _commune = '';
  String _quartier = '';

  String? _selectedRegion;
  String? _selectedCommune;
  String? _selectedVilleCMR;

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
    _quartierCtrl.dispose();
    _repereCtrl.dispose();
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
    final String region;
    if (_useMap) {
      ville = _ville;
      commune = _isCI ? _commune : '';
      quartier = _quartier;
      region = '';
    } else if (_isCI) {
      region = _selectedRegion ?? '';
      commune = _selectedCommune ?? '';
      ville = region;
      quartier = _quartierCtrl.text.trim();
    } else {
      region = '';
      ville = _selectedVilleCMR ?? '';
      commune = '';
      quartier = _quartierCtrl.text.trim();
    }
    Navigator.pop(context, {
      'ville': ville,
      'commune': commune,
      'quartier': quartier,
      'region': region,
      'repere': _repereCtrl.text.trim(),
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
          Expanded(
            child: _useMap
                ? LocationMapView(
                    mapController: _mapController,
                    center: _center,
                    accentColor: widget.accentColor,
                    geocoding: _geocoding,
                    gpsLoading: _gpsLoading,
                    onGps: _detectGPS,
                    onPositionChanged: _onPositionChanged,
                  )
                : LocationManualForm(
                    isCI: _isCI,
                    accentColor: widget.accentColor,
                    selectedRegion: _selectedRegion,
                    selectedCommune: _selectedCommune,
                    selectedVilleCMR: _selectedVilleCMR,
                    quartierCtrl: _quartierCtrl,
                    repereCtrl: _repereCtrl,
                    onRegionChanged: (v) =>
                        setState(() => _selectedRegion = v),
                    onCommuneChanged: (v) =>
                        setState(() => _selectedCommune = v),
                    onVilleCMRChanged: (v) =>
                        setState(() => _selectedVilleCMR = v),
                  ),
          ),
          LocationBottomBar(
            useMap: _useMap,
            ville: _ville,
            commune: _commune,
            quartier: _quartier,
            isCI: _isCI,
            accentColor: widget.accentColor,
            repereCtrl: _repereCtrl,
            onConfirm: _confirm,
          ),
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
}
