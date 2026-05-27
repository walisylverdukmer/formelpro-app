import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HommeToutFaireSection extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const HommeToutFaireSection({
    super.key,
    required this.accentColor,
    required this.onTap,
  });

  static const _skills = [
    _Skill(Icons.plumbing_rounded, 'Plomberie'),
    _Skill(Icons.electrical_services_rounded, 'Électricité'),
    _Skill(Icons.format_paint_rounded, 'Peinture'),
    _Skill(Icons.handyman_rounded, 'Bricolage'),
    _Skill(Icons.chair_rounded, 'Meubles'),
    _Skill(Icons.grass_rounded, 'Jardinage'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
          border: Border.all(
            color: const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône principale
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(
                Icons.construction_rounded,
                color: accentColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Texte + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Homme à tout faire',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MULTI',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Un artisan, toutes les compétences',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Chips compétences
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: _skills
                        .map((s) => _SkillChip(skill: s))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Flèche CTA
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: accentColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle skill ─────────────────────────────────────────────────────────────

class _Skill {
  final IconData icon;
  final String label;

  const _Skill(this.icon, this.label);
}

// ─── Chip individuel ──────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final _Skill skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(skill.icon, size: 9, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            skill.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
