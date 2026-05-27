import 'package:flutter/material.dart';
import 'package:formelpro/utils/distance_utils.dart';

class TechnicianDisponibiliteBadge extends StatelessWidget {
  final bool disponible;
  final bool isOnline;

  const TechnicianDisponibiliteBadge({
    super.key,
    required this.disponible,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) return _chip(const Color(0xFF22C55E), 'En ligne maintenant');
    if (disponible) return _chip(const Color(0xFF3B82F6), 'Disponible');
    return _chip(const Color(0xFF94A3B8), 'Indisponible');
  }

  Widget _chip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class TechnicianPremiumBadge extends StatelessWidget {
  final int level;

  const TechnicianPremiumBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level >= 2
                ? Icons.workspace_premium_rounded
                : Icons.star_rounded,
            color: Colors.white,
            size: 9,
          ),
          const SizedBox(width: 2),
          Text(
            level >= 2 ? 'Pro' : 'Premium',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicianDistanceBadge extends StatelessWidget {
  final double km;

  const TechnicianDistanceBadge({super.key, required this.km});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
      ),
      child: Text(
        DistanceUtils.format(km),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }
}
