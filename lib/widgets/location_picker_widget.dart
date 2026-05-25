import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final Color accentColor;

  const LocationPickerWidget({
    super.key, 
    required this.onLocationSelected, 
    required this.accentColor
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  // Coordonnées par défaut (Abidjan)
  LatLng _currentCenter = const LatLng(5.3261, -4.0197); 
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // On lance la géolocalisation après le premier rendu pour éviter les conflits de context
    WidgetsBinding.instance.addPostFrameCallback((_) => _determinePosition());
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        
        // Vérification si le widget est toujours affiché (mounted)
        if (!mounted) return;

        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentCenter, 15.0);
        });
      }
    } catch (e) {
      debugPrint("Erreur GPS : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text("Pointer le lieu", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                widget.onLocationSelected(_currentCenter);
                Navigator.pop(context, _currentCenter); // On renvoie explicitement les coordonnées
              },
              child: Text("VALIDER", style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                final center = position.center;
                if (hasGesture && center != null) {
                  setState(() {
                    _currentCenter = center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.formelpro.app',
              ),
            ],
          ),
          // Marqueur fixe au centre
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, color: widget.accentColor, size: 45),
            ),
          ),
          // Bouton Recentre
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              mini: false,
              backgroundColor: Colors.white,
              onPressed: _determinePosition,
              child: Icon(Icons.my_location, color: widget.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}