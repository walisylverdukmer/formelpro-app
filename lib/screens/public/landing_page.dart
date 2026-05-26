import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/page_connexion_principale.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _kAccent = Color(0xFFE67E22);
  static const _kDark = Color(0xFF0F172A);
  static const _kNavy = Color(0xFF1E293B);
  static const _kSlate = Color(0xFF94A3B8);
  static const _kMuted = Color(0xFF64748B);

  static const _services = <_ServiceDef>[
    _ServiceDef(Icons.electrical_services_rounded, 'Électricien', Color(0xFFF59E0B)),
    _ServiceDef(Icons.water_drop_outlined, 'Plombier', Color(0xFF3B82F6)),
    _ServiceDef(Icons.cleaning_services_rounded, 'Ménage', Color(0xFF8B5CF6)),
    _ServiceDef(Icons.local_fire_department_rounded, 'Livraison gaz', Color(0xFFEF4444)),
    _ServiceDef(Icons.build_rounded, 'Menuisier', Color(0xFF92400E)),
    _ServiceDef(Icons.phone_android_rounded, 'Électronique', Color(0xFF0EA5E9)),
  ];

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PageConnexionPrincipale()),
    );
  }

  Future<void> _openPrestataire() async {
    if (!kIsWeb) return;
    final uri = Uri.base.resolve('/devenir-prestataire');
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 640;
    return Scaffold(
      backgroundColor: _kDark,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildHero(context, isWide),
            _buildServices(),
            _buildHowItWorks(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: _kNavy,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.handyman_rounded, color: _kAccent, size: 36),
          ),
          const SizedBox(width: 10),
          Text(
            'FormelPro',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _goToLogin(context),
            child: Text(
              'Se connecter',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _kAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isWide ? 80 : 48, 24, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kNavy, _kDark],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Côte d\'Ivoire · Cameroun',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kAccent),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Trouvez un professionnel\nde confiance',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWide ? 42 : 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Électriciens, plombiers, techniciens certifiés.\nDisponibles près de vous en quelques minutes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: _kSlate, height: 1.6),
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWide ? 360 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Trouver un technicien',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _openPrestataire,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Devenir prestataire',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServices() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: _kDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nos services',
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Tous les métiers de votre quotidien',
            style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _services.map((s) => _ServiceChip(def: s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: _kNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ça marche ?',
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const _StepRow(
            number: '1',
            title: 'Créez votre compte',
            subtitle: 'Inscription rapide en 2 minutes',
          ),
          const SizedBox(height: 20),
          const _StepRow(
            number: '2',
            title: 'Trouvez un professionnel',
            subtitle: 'Filtrez par métier, note et disponibilité',
          ),
          const SizedBox(height: 20),
          const _StepRow(
            number: '3',
            title: 'Échangez et planifiez',
            subtitle: 'Proforma, devis, suivi en temps réel',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: const Color(0xFF020617),
      child: Column(
        children: [
          Text(
            '© 2025 FormelPro. Tous droits réservés.',
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _goToLogin(context),
            child: Text(
              'Connexion / Inscription',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kAccent,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _ServiceDef {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceDef(this.icon, this.label, this.color);
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ServiceChip extends StatelessWidget {
  final _ServiceDef def;
  const _ServiceChip({required this.def});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: def.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: def.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(def.icon, color: def.color, size: 18),
          const SizedBox(width: 8),
          Text(
            def.label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE67E22)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
