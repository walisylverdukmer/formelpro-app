import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/choix_profil.dart';
import '../auth/page_connexion_principale.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _accent = Color(0xFFE67E22);
  static const _bg = Color(0xFFF8FAFC);
  static const _dark = Color(0xFF0F172A);
  static const _navy = Color(0xFF1E293B);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _slate = Color(0xFF64748B);
  static const _muted = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);

  static const _services = <_SvcData>[
    _SvcData(
      icon: Icons.handyman_rounded,
      label: 'Homme à\ntout faire',
      sub: 'Bricolage, montage, réparations',
      color: Color(0xFFF59E0B),
    ),
    _SvcData(
      icon: Icons.local_fire_department_rounded,
      label: 'Livraison\ngaz',
      sub: 'Rapide & sécurisé',
      color: Color(0xFFEF4444),
    ),
    _SvcData(
      icon: Icons.water_drop_outlined,
      label: 'Plombier\nurgent',
      sub: 'Disponible maintenant',
      color: Color(0xFF3B82F6),
    ),
    _SvcData(
      icon: Icons.cleaning_services_rounded,
      label: 'Ménage\n& maison',
      sub: 'Nettoyage professionnel',
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const _mockTechs = <Map<String, Object>>[
    {'nom': 'Kouamé J.', 'metier': 'Plombier', 'note': '4.9', 'lieu': 'Cocody', 'online': true},
    {'nom': 'Bello S.', 'metier': 'Électricien', 'note': '4.8', 'lieu': 'Plateau', 'online': false},
    {'nom': 'Ama K.', 'metier': 'Ménagère', 'note': '4.9', 'lieu': 'Yopougon', 'online': true},
    {'nom': 'Diop M.', 'metier': 'Gaz', 'note': '4.7', 'lieu': 'Marcory', 'online': true},
    {'nom': 'Cissé B.', 'metier': 'Électricien', 'note': '4.8', 'lieu': 'Adjamé', 'online': false},
  ];

  static const _competencesHATF = <String>[
    'Bricolage', 'Peinture', 'Montage meubles', 'Petite plomberie',
    'Petite électricité', 'Jardinage', 'Déménagement', 'Fixations murales',
  ];

  static const _sensitiveServices = <_SensData>[
    _SensData(icon: Icons.home_rounded, label: 'Ménagère', sub: 'Entretien quotidien du foyer'),
    _SensData(icon: Icons.supervisor_account_rounded, label: 'Servante', sub: 'Aide domestique à domicile'),
    _SensData(icon: Icons.restaurant_rounded, label: 'Serveuse', sub: 'Service en restaurant ou événement'),
  ];

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PageConnexionPrincipale()),
    );
  }

  void _inscrireTechnicien(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChoixProfilPage(preselectedRole: 'technicien'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool isWide = w > 640;
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildHero(context, isWide),
            _buildServicesRapides(context, isWide),
            _buildTechniciensSection(context),
            _buildRechercheSection(context),
            _buildHommeAToutFaire(context),
            _buildServicesSensibles(context),
            _buildStats(isWide),
            _buildDevenirPrestataire(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ─── 1. Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.handyman_rounded, color: _accent, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FormelPro',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold, color: _dark),
              ),
              Text(
                'Le bon technicien près de chez vous',
                style: GoogleFonts.inter(fontSize: 9.5, color: _muted),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _goToLogin(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Connexion',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _accent),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () => _inscrireTechnicien(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Postuler comme technicien',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Hero ──────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, bool isWide) {
    return SizedBox(
      height: isWide ? 500 : 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/fond_ci.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _navy),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _dark.withValues(alpha: 0.82),
                  _dark.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, isWide ? 72 : 44, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pays badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇨🇮', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text('Côte d\'Ivoire',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accent)),
                      Container(
                        width: 1,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: _accent.withValues(alpha: 0.4),
                      ),
                      const Text('🇨🇲', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text('Cameroun',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Titre principal
                Text(
                  'Trouvez rapidement un\nprofessionnel\nprès de chez vous',
                  style: GoogleFonts.poppins(
                    fontSize: isWide ? 36 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Plombier, gaz, ménage, électricité,\ndépannage et bien plus.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white70, height: 1.6),
                ),
                const SizedBox(height: 28),
                // CTAs
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _goToLogin(context),
                      icon: const Icon(Icons.search_rounded, size: 17),
                      label: Text('Rechercher un technicien',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: _accent.withValues(alpha: 0.4),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _inscrireTechnicien(context),
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: Text('Postuler comme technicien',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white54, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Badges de confiance
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroBadge(Icons.verified_rounded, _green, 'Profils vérifiés'),
                    _heroBadge(Icons.near_me_rounded, _blue, 'Géolocalisé'),
                    _heroBadge(Icons.bolt_rounded, _accent, 'Disponible maintenant'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ─── 3. Services rapides ──────────────────────────────────────────────────

  Widget _buildServicesRapides(BuildContext context, bool isWide) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('NOS SERVICES', _accent),
          const SizedBox(height: 6),
          Text('Services disponibles',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _dark)),
          const SizedBox(height: 4),
          Text('Trouvez le bon professionnel en 1 clic',
              style: GoogleFonts.inter(fontSize: 13, color: _slate)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: isWide ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 0.88 : 0.92,
            children: _services
                .map((s) => _ServiceCard(
                      data: s,
                      accent: _accent,
                      onTap: () => _goToLogin(context),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── 4. Techniciens près de vous ─────────────────────────────────────────

  Widget _buildTechniciensSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('À PROXIMITÉ', _green),
                    const SizedBox(height: 6),
                    Text('Techniciens près de vous',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _dark)),
                  ],
                ),
                TextButton(
                  onPressed: () => _goToLogin(context),
                  style: TextButton.styleFrom(minimumSize: Size.zero),
                  child: Row(
                    children: [
                      Text('Voir plus',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _accent,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: _accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _mockTechs.length,
              itemBuilder: (_, i) => _TechPreviewCard(
                data: _mockTechs[i],
                accent: _accent,
                onTap: () => _goToLogin(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _goToLogin(context),
              icon: const Icon(Icons.people_alt_rounded, size: 16),
              label: Text('Voir tous les techniciens',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Recherche ─────────────────────────────────────────────────────────

  Widget _buildRechercheSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.05),
            _blue.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('RECHERCHE', _blue),
          const SizedBox(height: 8),
          Text(
            'Dans quel domaine\nrecherchez-vous un technicien ?',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _dark,
                height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Décrivez votre besoin et trouvez le professionnel idéal',
            style: GoogleFonts.inter(fontSize: 13, color: _slate),
          ),
          const SizedBox(height: 24),
          // Search bar
          GestureDetector(
            onTap: () => _goToLogin(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: _muted, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Plombier, électricien, ménage...',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: _muted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text('Rechercher',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Plombier', 'Électricien', 'Gaz',
              'Ménagère', 'Maçon', 'Peintre',
            ]
                .map((s) => GestureDetector(
                      onTap: () => _goToLogin(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 12, color: _accent),
                            const SizedBox(width: 4),
                            Text(s,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _dark)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── 6. Homme à tout faire ────────────────────────────────────────────────

  Widget _buildHommeAToutFaire(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('POLYVALENT', const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          Text('Homme à tout faire',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 4),
          Text(
            'Petits travaux, bricolage, réparations — tout en un seul professionnel',
            style: GoogleFonts.inter(fontSize: 13, color: _slate, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.handyman_rounded,
                          color: Color(0xFFF59E0B), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Multi-compétences',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _dark)),
                          Text('Petits travaux du quotidien',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: _slate)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Populaire',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _competencesHATF
                      .map((c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.35)),
                            ),
                            child: Text(c,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E))),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _goToLogin(context),
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: Text('Trouver un homme à tout faire',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Services sensibles ────────────────────────────────────────────────

  Widget _buildServicesSensibles(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _label('SERVICES SÉCURISÉS', _green),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security_rounded, size: 11, color: _green),
                    const SizedBox(width: 4),
                    Text('Service sécurisé',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Services domestiques',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
          const SizedBox(height: 4),
          Text(
            'Aucun contact direct — Sélection et vérification assurées par FormelPro',
            style: GoogleFonts.inter(fontSize: 13, color: _slate, height: 1.5),
          ),
          const SizedBox(height: 20),
          ..._sensitiveServices.map(
            (s) => _SensCard(
              data: s,
              accent: _green,
              onTap: () => _goToLogin(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 8. Statistiques ──────────────────────────────────────────────────────

  Widget _buildStats(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_dark, _navy],
        ),
      ),
      child: Column(
        children: [
          Text('FormelPro en chiffres',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text('Une plateforme africaine en pleine croissance',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 36),
          const Wrap(
            spacing: 16,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _StatItem(value: '500+', label: 'Techniciens\nactifs'),
              _StatItem(value: '1 200+', label: 'Demandes\ntraitées'),
              _StatItem(value: '2', label: 'Pays\ncouvertes'),
              _StatItem(value: '10+', label: 'Zones\ncouvertes'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 9. Devenir prestataire ───────────────────────────────────────────────

  Widget _buildDevenirPrestataire(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFD46B0E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text('Profil vérifié & mis en avant',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Postulez pour devenir\ntechnicien de FormelPro',
            style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            'Rejoignez notre réseau, recevez des missions qualifiées et développez votre clientèle en Côte d\'Ivoire et au Cameroun.',
            style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.6),
          ),
          const SizedBox(height: 14),
          ...[
            'Visibilité sur 2 pays (Côte d\'Ivoire + Cameroun)',
            'Clients vérifiés & qualifiés',
            'Paiement sécurisé & suivi en temps réel',
          ].map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 11),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.90))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _inscrireTechnicien(context),
              icon: const Icon(Icons.how_to_reg_rounded, size: 18),
              label: Text('Postuler maintenant',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 10. Footer ───────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 36),
      color: _dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: _accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text('FormelPro',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Le bon technicien près de chez vous',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FooterCol(
                  title: 'SERVICES',
                  items: const ['Plomberie', 'Électricité', 'Gaz', 'Ménage', 'Bricolage'],
                  onTap: (_) => _goToLogin(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FooterCol(
                  title: 'LIENS',
                  items: const ['À propos', 'Postuler technicien', 'Support', 'Contact'],
                  onTap: (s) => s == 'Postuler technicien'
                      ? _inscrireTechnicien(context)
                      : _goToLogin(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ZONES',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: _accent)),
                    const SizedBox(height: 10),
                    const Text('🇨🇮  Côte d\'Ivoire',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 6),
                    const Text('🇨🇲  Cameroun',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded,
                            size: 12, color: Colors.white38),
                        const SizedBox(width: 5),
                        Text('contact@formelpro.com',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2025 FormelPro. Tous droits réservés.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white24)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _goToLogin(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Entrer dans l\'app',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _accent)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper ────────────────────────────────────────────────────────────────

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _SvcData {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _SvcData(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});
}

class _SensData {
  final IconData icon;
  final String label;
  final String sub;
  const _SensData(
      {required this.icon, required this.label, required this.sub});
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _SvcData data;
  final Color accent;
  final VoidCallback onTap;
  const _ServiceCard(
      {required this.data, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: data.color.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            const Spacer(),
            Text(data.label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.25)),
            const SizedBox(height: 4),
            Text(data.sub,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Réserver',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: data.color)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded, size: 11, color: data.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechPreviewCard extends StatelessWidget {
  final Map<String, Object> data;
  final Color accent;
  final VoidCallback onTap;
  const _TechPreviewCard(
      {required this.data, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool online = data['online'] as bool? ?? false;
    final String nom = data['nom'] as String? ?? '';
    final String metier = data['metier'] as String? ?? '';
    final String note = data['note'] as String? ?? '5.0';
    final String lieu = data['lieu'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 108,
                    color: accent.withValues(alpha: 0.08),
                    child: Center(
                      child: Icon(Icons.person_rounded,
                          color: accent.withValues(alpha: 0.35), size: 52),
                    ),
                  ),
                ),
                if (online)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('En ligne',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.verified_rounded,
                      color: Color(0xFF3B82F6), size: 16),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(metier,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text(note,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B))),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(lieu,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensCard extends StatelessWidget {
  final _SensData data;
  final Color accent;
  final VoidCallback onTap;
  const _SensCard(
      {required this.data, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.label,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded,
                                size: 10, color: accent),
                            const SizedBox(width: 3),
                            Text('Sécurisé',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(data.sub,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE67E22))),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                  height: 1.4)),
        ],
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(String) onTap;
  const _FooterCol(
      {required this.title, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFFE67E22))),
        const SizedBox(height: 10),
        ...items.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onTap(s),
              child: Text(s,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white54)),
            ),
          ),
        ),
      ],
    );
  }
}
