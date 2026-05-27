import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final Color accentColor;
  final VoidCallback onAccept;

  const MissionCard({
    super.key,
    required this.mission,
    required this.accentColor,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                (mission['titre_service'] ?? 'SERVICE').toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                mission['commune'] ?? mission['ville'] ?? '—',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mission['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'ACCEPTER',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
