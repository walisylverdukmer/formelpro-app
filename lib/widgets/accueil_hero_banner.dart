import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccueilHeroBanner extends StatefulWidget {
  final String pays;
  final Color primaryColor;
  final VoidCallback? onExplore;

  const AccueilHeroBanner({
    super.key,
    required this.pays,
    required this.primaryColor,
    this.onExplore,
  });

  @override
  State<AccueilHeroBanner> createState() => _AccueilHeroBannerState();
}

class _AccueilHeroBannerState extends State<AccueilHeroBanner> {
  final _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  static const _slides = [
    _HeroSlide(
      title: 'Trouvez un technicien\nprès de chez vous',
      subtitle: 'Techniciens certifiés disponibles maintenant',
      cta: 'Explorer',
      icon: Icons.search_rounded,
    ),
    _HeroSlide(
      title: 'Services du quotidien\nen 1 clic',
      subtitle: 'Gaz, électricité, plomberie, ménage...',
      cta: 'Voir les services',
      icon: Icons.bolt_rounded,
    ),
    _HeroSlide(
      title: 'Prestataires vérifiés\nidentité validée',
      subtitle: 'Chaque profil contrôlé par FormelPro',
      cta: 'Découvrir',
      icon: Icons.verified_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _pageController.animateToPage(
        (_currentPage + 1) % _slides.length,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroImage = widget.pays == 'CIV'
        ? 'assets/images/fond_ci.jpeg'
        : 'assets/images/fond_cmr.jpeg';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Image de fond pays
            Positioned.fill(
              child: Image.asset(
                heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Gradient : fort à gauche, transparent à droite
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.92),
                      const Color(0xFF0F172A).withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            // Slides de contenu
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _SlideContent(
                slide: _slides[i],
                primaryColor: widget.primaryColor,
                onTap: widget.onExplore,
              ),
            ),
            // Indicateurs de page animés
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle slide (const) ─────────────────────────────────────────────────────

class _HeroSlide {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;

  const _HeroSlide({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
  });
}

// ─── Contenu d'un slide ───────────────────────────────────────────────────────

class _SlideContent extends StatelessWidget {
  final _HeroSlide slide;
  final Color primaryColor;
  final VoidCallback? onTap;

  const _SlideContent({
    required this.slide,
    required this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 100, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            slide.subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(slide.icon, size: 13, color: primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    slide.cta,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
