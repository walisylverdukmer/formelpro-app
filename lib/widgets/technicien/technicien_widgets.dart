import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicienStatCard extends StatelessWidget {
  final double rating;
  final int jobs;

  const TechnicienStatCard({
    super.key,
    required this.rating,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem("Note", rating.toStringAsFixed(1),
              Icons.star_rounded, Colors.amber),
          Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
          _StatItem("Missions", "$jobs",
              Icons.check_circle_rounded, const Color(0xFF22C55E)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ]),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }
}

class TechnicienInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accentColor;

  const TechnicienInfoChip({
    super.key,
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF475569), fontSize: 14)),
        ],
      ),
    );
  }
}

class TechnicienActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const TechnicienActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasShadow = textColor == Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
