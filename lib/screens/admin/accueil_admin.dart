import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_documents_page.dart';
import 'admin_signalements_page.dart';
import 'admin_users_page.dart';
import 'contacts_admin_page.dart';
import '../../widgets/admin/admin_widgets.dart';

class AccueilAdmin extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Color accentColor;

  const AccueilAdmin(
      {super.key, required this.userData, required this.accentColor});

  @override
  State<AccueilAdmin> createState() => _AccueilAdminState();
}

class _AccueilAdminState extends State<AccueilAdmin> {
  final _supabase = Supabase.instance.client;

  int _totalUsers = 0;
  int _totalTechs = 0;
  int _pendingDocs = 0;
  int _pendingSignals = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _supabase
            .from('utilisateurs')
            .select('id')
            .eq('is_admin', false)
            .limit(9999),
        _supabase
            .from('utilisateurs')
            .select('id')
            .eq('role', 'technicien')
            .eq('is_admin', false)
            .limit(9999),
        _supabase
            .from('documents_verification')
            .select('id')
            .eq('statut', 'en_attente')
            .limit(9999),
        _supabase
            .from('signalements')
            .select('id')
            .eq('statut', 'en_attente')
            .limit(9999),
      ]);
      if (mounted) {
        setState(() {
          _totalUsers = (results[0] as List).length;
          _totalTechs = (results[1] as List).length;
          _pendingDocs = (results[2] as List).length;
          _pendingSignals = (results[3] as List).length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin KPI erreur: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigate(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _loadKpis());
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final prenom = widget.userData['prenom'] as String? ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadKpis,
          color: accent,
          backgroundColor: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accent, prenom),
                const SizedBox(height: 28),
                _buildKpiSection(accent),
                const SizedBox(height: 32),
                _buildModulesSection(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, String prenom) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bonjour $prenom',
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Centre de supervision FormelPro',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white38),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: Colors.white38, size: 22),
          onPressed: _loadKpis,
        ),
      ],
    );
  }

  Widget _buildKpiSection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Indicateurs clés',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            AdminKpiCard(
              label: 'Utilisateurs',
              value: _totalUsers,
              icon: Icons.people_rounded,
              color: const Color(0xFF3B82F6),
              loading: _loading,
            ),
            AdminKpiCard(
              label: 'Techniciens',
              value: _totalTechs,
              icon: Icons.engineering_rounded,
              color: accent,
              loading: _loading,
            ),
            AdminKpiCard(
              label: 'Docs en attente',
              value: _pendingDocs,
              icon: Icons.folder_open_rounded,
              color: Colors.amber,
              loading: _loading,
              urgent: true,
            ),
            AdminKpiCard(
              label: 'Signalements',
              value: _pendingSignals,
              icon: Icons.flag_rounded,
              color: Colors.redAccent,
              loading: _loading,
              urgent: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModulesSection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modules',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        AdminModuleCard(
          title: 'Validation Documents',
          subtitle: 'Approuver ou rejeter les pièces d\'identité',
          icon: Icons.verified_user_rounded,
          accentColor: Colors.amber,
          badge: _pendingDocs > 0 ? _pendingDocs : null,
          onTap: () => _navigate(AdminDocumentsPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Gestion Utilisateurs',
          subtitle: 'Suspendre, réactiver, consulter les comptes',
          icon: Icons.manage_accounts_rounded,
          accentColor: const Color(0xFF3B82F6),
          onTap: () => _navigate(AdminUsersPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Signalements & Litiges',
          subtitle: 'Traiter les signalements actifs',
          icon: Icons.report_problem_rounded,
          accentColor: Colors.redAccent,
          badge: _pendingSignals > 0 ? _pendingSignals : null,
          onTap: () => _navigate(AdminSignalementsPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Contacts & Inscriptions',
          subtitle: 'Emails, téléphones, localisations, statuts',
          icon: Icons.contacts_rounded,
          accentColor: const Color(0xFF10B981),
          onTap: () => _navigate(ContactsAdminPage(accentColor: accent)),
        ),
      ],
    );
  }
}
