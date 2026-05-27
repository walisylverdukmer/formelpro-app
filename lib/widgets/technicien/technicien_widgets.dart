import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── TechnicienStatCard ──────────────────────────────────────────────────────

class TechnicienStatCard extends StatelessWidget {
  final double rating;
  final int jobs;
  final bool? estEnLigne;
  final bool? disponible;

  const TechnicienStatCard({
    super.key,
    required this.rating,
    required this.jobs,
    this.estEnLigne,
    this.disponible,
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
          _vDivider(),
          _StatItem("Missions", "$jobs",
              Icons.check_circle_rounded, const Color(0xFF22C55E)),
          if (estEnLigne != null) ...[
            _vDivider(),
            _StatusStatItem(
                estEnLigne: estEnLigne!, disponible: disponible ?? false),
          ],
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 30, color: const Color(0xFFE2E8F0));
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
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }
}

class _StatusStatItem extends StatelessWidget {
  final bool estEnLigne;
  final bool disponible;

  const _StatusStatItem(
      {required this.estEnLigne, required this.disponible});

  @override
  Widget build(BuildContext context) {
    final Color color = estEnLigne
        ? const Color(0xFF22C55E)
        : disponible
            ? const Color(0xFF3B82F6)
            : const Color(0xFF94A3B8);
    final String label =
        estEnLigne ? 'En ligne' : disponible ? 'Dispo' : 'Indispo';

    return Column(
      children: [
        Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 4),
        const Text("Statut",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }
}

// ── TechnicienPremiumBanner ─────────────────────────────────────────────────

class TechnicienPremiumBanner extends StatelessWidget {
  final int premiumLevel;

  const TechnicienPremiumBanner({super.key, required this.premiumLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            premiumLevel >= 2
                ? Icons.workspace_premium_rounded
                : Icons.star_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            premiumLevel >= 2
                ? 'Prestataire FormelPro Pro'
                : 'Prestataire FormelPro Premium',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
          const Spacer(),
          const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }
}

// ── TechnicienContactSection ────────────────────────────────────────────────

class TechnicienContactSection extends StatelessWidget {
  final bool isSensible;
  final Color accentColor;
  final VoidCallback onContact;
  final VoidCallback onDemande;

  const TechnicienContactSection({
    super.key,
    required this.isSensible,
    required this.accentColor,
    required this.onContact,
    required this.onDemande,
  });

  @override
  Widget build(BuildContext context) {
    if (isSensible) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Color(0xFF22C55E), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ce profil nécessite une validation FormelPro. '
                    'Faites une demande encadrée pour être mis en relation.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF166534),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          TechnicienActionButton(
            label: 'Faire une demande encadrée',
            icon: Icons.assignment_ind_rounded,
            backgroundColor: const Color(0xFF22C55E),
            textColor: Colors.white,
            onTap: onDemande,
          ),
        ],
      );
    }
    return Column(
      children: [
        TechnicienActionButton(
          label: 'Contacter par message',
          icon: Icons.chat_bubble_rounded,
          backgroundColor: accentColor,
          textColor: Colors.white,
          onTap: onContact,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded,
                size: 13, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              "L'appel se débloque après échange dans le chat",
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }
}

// ── TechnicienAvisSection ───────────────────────────────────────────────────

class TechnicienAvisSection extends StatelessWidget {
  final List<Map<String, dynamic>> avis;
  final bool loading;

  const TechnicienAvisSection(
      {super.key, required this.avis, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFCBD5E1)),
        ),
      );
    }
    if (avis.isEmpty) {
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Aucun avis pour le moment.',
          style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
      );
    }
    return Column(
      children: avis.map((a) => _AvisItem(avis: a)).toList(),
    );
  }
}

class _AvisItem extends StatelessWidget {
  final Map<String, dynamic> avis;

  const _AvisItem({required this.avis});

  @override
  Widget build(BuildContext context) {
    final int note = (avis['note'] as num?)?.toInt() ?? 5;
    final String commentaire = avis['commentaire']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < note
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 14,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(avis['date_avis']),
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (commentaire.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              commentaire,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ── TechnicienInfoChip ──────────────────────────────────────────────────────

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

// ── TechnicienActionButton ──────────────────────────────────────────────────

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
