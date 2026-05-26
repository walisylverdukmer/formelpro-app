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

  static const _mainServices = <_ServiceData>[
    _ServiceData(
      icon: Icons.handyman_rounded,
      label: 'Homme à\ntout faire',
      sub: 'Bricolage, montage, réparations',
      color: Color(0xFFF59E0B),
    ),
    _ServiceData(
      icon: Icons.local_fire_department_rounded,
      label: 'Livraison\ngaz',
      sub: 'Rapide & sécurisé',
      color: Color(0xFFEF4444),
    ),
    _ServiceData(
      icon: Icons.water_drop_outlined,
      label: 'Plombier\nurgent',
      sub: 'Disponible maintenant',
      color: Color(0xFF3B82F6),
    ),
    _ServiceData(
      icon: Icons.cleaning_services_rounded,
      label: 'Ménage\n& maison',
      sub: 'Nettoyage professionnel',
      color: Color(0xFF8B5CF6),
    ),
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
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 640;
    return Scaffold(
      backgroundColor: _kDark,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildHero(context, isWide),
            _buildServiceCards(context, isWide),
            _buildStats(),
            _buildHowItWorks(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: _kNavy,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.handyman_rounded, color: _kAccent, size: 34),
          ),
          const SizedBox(width: 10),
          Text(
            'FormelPro',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _goToLogin(context),
            child: Text(
              'Entrer dans l\'app',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, isWide ? 72 : 44, 24, 56),
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
              '🇨🇮 Côte d\'Ivoire  ·  🇨🇲 Cameroun',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kAccent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Le pro qu\'il vous faut,\nquand il vous faut.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWide ? 40 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Électriciens, plombiers, hommes à tout faire.\nDisponibles près de vous en quelques minutes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: _kSlate, height: 1.6),
          ),
          const SizedBox(height: 36),
          ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWide ? 360 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _goToLogin(context),
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: Text(
                    'Rechercher un technicien',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openPrestataire,
                  icon:
                      const Icon(Icons.badge_outlined, size: 18),
                  label: Text(
                    'Devenir prestataire',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        const BorderSide(color: Color(0xFF475569), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCards(BuildContext context, bool isWide) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
      color: _kDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services disponibles',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text('Trouvez le bon professionnel en 1 clic',
              style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: _mainServices
                .map((s) => _ServiceCard(data: s, onTap: () => _goToLogin(context)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      color: _kNavy,
      child: Column(
        children: [
          Text(
            'Déjà actif en Afrique',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(value: '500+', label: 'Experts'),
              _StatChip(value: '2', label: 'Pays'),
              _StatChip(value: '10+', label: 'Métiers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      color: _kDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ça marche ?',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 28),
          const _StepRow(number: '1', title: 'Créez votre compte',
              subtitle: 'Inscription rapide en 2 minutes'),
          const SizedBox(height: 18),
          const _StepRow(number: '2', title: 'Trouvez un expert',
              subtitle: 'Filtrez par métier, commune et disponibilité'),
          const SizedBox(height: 18),
          const _StepRow(number: '3', title: 'Discutez & planifiez',
              subtitle: 'Chat sécurisé, proforma, suivi en temps réel'),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      color: const Color(0xFF020617),
      child: Column(
        children: [
          Text(
            'Prêt à trouver un professionnel ?',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('Commencer maintenant',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
          Text('© 2025 FormelPro. Tous droits réservés.',
              style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _ServiceData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _ServiceData(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceData data;
  final VoidCallback onTap;
  const _ServiceCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: data.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              data.label,
              style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(data.sub,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE67E22))),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF94A3B8))),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  const _StepRow(
      {required this.number, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(number,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE67E22))),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}
