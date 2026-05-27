import 'dart:math' as math;

class DistanceUtils {
  static double haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371.0;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  static String format(double km) {
    if (km < 1.0) return '< 1 km';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  static double? fromTechData(
      double? clientLat, double? clientLng, Map<String, dynamic> tech) {
    if (clientLat == null || clientLng == null) return null;
    final techLat = (tech['latitude'] as num?)?.toDouble();
    final techLng = (tech['longitude'] as num?)?.toDouble();
    if (techLat == null || techLng == null) return null;
    return haversineKm(clientLat, clientLng, techLat, techLng);
  }
}
