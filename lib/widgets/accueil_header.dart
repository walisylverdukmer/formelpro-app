import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'location_picker_widget.dart';

class AccueilHeader extends StatelessWidget {
  final String prenom;
  final String flagPath;
  final Color primaryColor;
  final String paysCode;
  final String? commune;
  final int filtresCount;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onOpenFiltres;
  final void Function(Map<String, dynamic>)? onLocationPicked;

  const AccueilHeader({
    super.key,
    required this.prenom,
    required this.flagPath,
    required this.primaryColor,
    required this.paysCode,
    required this.searchController,
    required this.onSearch,
    required this.onOpenFiltres,
    this.commune,
    this.filtresCount = 0,
    this.onLocationPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Bonjour $prenom 👋",
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFF64748B)),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  flagPath,
                  width: 28,
                  height: 18,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Besoin d'un pro ?",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildLocationRow(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: searchController,
        onSubmitted: (_) => onSearch(),
        textInputAction: TextInputAction.search,
        style:
            GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: "Rechercher un artisan, un métier...",
          hintStyle: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF94A3B8)),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          suffixIcon: GestureDetector(
            onTap: onOpenFiltres,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: filtresCount > 0
                      ? primaryColor
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
                if (filtresCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          filtresCount.toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerWidget(
              accentColor: primaryColor,
              paysCode: paysCode,
            ),
          ),
        );
        if (result != null) {
          onLocationPicked?.call(result);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            (commune != null && commune!.isNotEmpty) ? commune! : 'Partout',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
