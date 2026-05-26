import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'filtres_techniciens.dart';

class TechnicienEmptyState extends StatelessWidget {
  final FiltresTechniciens filtres;
  final Color primaryColor;
  final VoidCallback onReset;

  const TechnicienEmptyState({
    super.key,
    required this.filtres,
    required this.primaryColor,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = filtres.actif;
    final bool hasCat =
        filtres.categorieNom != null || filtres.categorieId != null;

    final String title;
    final String subtitle;
    final IconData icon;

    if (hasCat) {
      title = "Aucun expert trouvé pour ce métier";
      subtitle =
          "Aucun prestataire certifié n'est encore référencé pour ce service dans votre zone.";
      icon = Icons.person_search_rounded;
    } else if (hasFilter) {
      title = "Aucun résultat";
      subtitle =
          "Aucun technicien ne correspond à vos critères de recherche.";
      icon = Icons.filter_list_off_rounded;
    } else {
      title = "Aucun technicien disponible";
      subtitle =
          "Aucun prestataire n'est encore référencé dans votre zone. Revenez bientôt !";
      icon = Icons.groups_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 48, color: primaryColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF334155),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilter) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Réinitialiser les filtres"),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
