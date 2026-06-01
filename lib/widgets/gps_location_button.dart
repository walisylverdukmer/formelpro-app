import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

/// Bouton GPS premium avec pulsation douce et badge "Recommandé".
/// Détecte automatiquement la position → commune/quartier via Nominatim.
class GpsLocationButton extends StatefulWidget {
  final Color accentColor;
  final String paysCode;
  final void Function(Map<String, dynamic> result) onLocationDetected;
  final VoidCallback? onOpenMap;

  const GpsLocationButton({
    super.key,
    required this.accentColor,
    required this.paysCode,
    required this.onLocationDetected,
    this.onOpenMap,
  });

  @override
  State<GpsLocationButton> createState() => _GpsLocationButtonState();
}

class _GpsLocationButtonState extends State<GpsLocationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  bool _loading = false;
  String? _detectedLabel;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detectPosition() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          _showError('Activez la localisation dans les paramètres.');
        }
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) _showError('Permission de localisation refusée.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );

      final result = await _reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;

      final commune = result['commune'] ?? '';
      final ville = result['ville'] ?? '';
      final label = commune.isNotEmpty ? commune : ville;
      setState(() => _detectedLabel = label.isNotEmpty ? label : null);
      widget.onLocationDetected(result);
    } on TimeoutException {
      if (mounted) _showError('Délai dépassé. Réessayez.');
    } catch (e) {
      if (mounted) _showError('Position indisponible.');
      debugPrint('GPS error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _reverseGeocode(
      double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$lat&lon=$lon&accept-language=fr',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': 'FormelPro/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return {};
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      String commune = address['suburb'] as String? ??
          address['district'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          '';
      String ville = address['city'] as String? ??
          address['county'] as String? ??
          '';
      String quartier = address['neighbourhood'] as String? ??
          address['quarter'] as String? ??
          '';

      if (widget.paysCode == 'CIV') {
        return {'ville': ville, 'commune': commune, 'quartier': quartier};
      } else {
        return {
          'ville': ville.isNotEmpty ? ville : commune,
          'commune': commune,
          'quartier': quartier,
        };
      }
    } catch (_) {
      return {};
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool detected = _detectedLabel != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(
              scale: _loading ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
              child: GestureDetector(
                onTap: _detectPosition,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: detected
                        ? LinearGradient(
                            colors: [
                              widget.accentColor,
                              widget.accentColor.withValues(alpha: 0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              widget.accentColor.withValues(alpha: 0.10),
                              widget.accentColor.withValues(alpha: 0.06),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.accentColor.withValues(
                          alpha: detected ? 0.0 : 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor
                            .withValues(alpha: detected ? 0.35 : 0.12),
                        blurRadius: detected ? 20 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _loading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: detected
                                    ? Colors.white
                                    : widget.accentColor,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              detected
                                  ? Icons.location_on_rounded
                                  : Icons.my_location_rounded,
                              color: detected
                                  ? Colors.white
                                  : widget.accentColor,
                              size: 22,
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detected
                                  ? '📍 Position détectée'
                                  : '📍 Utiliser ma position actuelle',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: detected
                                    ? Colors.white
                                    : widget.accentColor,
                              ),
                            ),
                            if (_detectedLabel != null)
                              Text(
                                _detectedLabel!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              )
                            else
                              Text(
                                'Détection automatique de votre commune',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: widget.accentColor
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        detected
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: detected
                            ? Colors.white
                            : widget.accentColor.withValues(alpha: 0.6),
                        size: detected ? 20 : 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Badge "Recommandé"
            if (!detected)
              Positioned(
                top: -10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '⭐ Recommandé',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.onOpenMap != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: widget.onOpenMap,
            child: Center(
              child: Text(
                'Ou choisir sur la carte →',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.accentColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor:
                      widget.accentColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
