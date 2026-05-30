import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_analytics_page.dart';
import 'admin_demandes_domestiques_page.dart';
import 'admin_documents_page.dart';
import 'admin_notifications_page.dart';
import 'admin_presence_page.dart';
import 'admin_prestataires_page.dart';
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
  final _sb = Supabase.instance.client;

  int _totalUsers = 0, _totalClients = 0, _totalTechs = 0;
  int _premium = 0, _verifies = 0, _enLigne = 0;
  int _inscritsAujourdhui = 0, _conversations = 0;
  int _pendingDocs = 0, _pendingSignals = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis() async {
    setState(() => _loading = true);
    try {
      final todayStr = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).toIso8601String();

      final r = await Future.wait([
        _sb.from('utilisateurs').select('id').neq('is_admin', true).limit(9999),
        _sb.from('utilisateurs').select('id').eq('role', 'client').neq('is_admin', true).limit(9999),
        _sb.from('utilisateurs').select('id').eq('role', 'technicien').neq('is_admin', true).limit(9999),
        _sb.from('utilisateurs').select('id').eq('is_premium', true).limit(9999),
        _sb.from('utilisateurs').select('id').eq('is_identite_verifiee', true).limit(9999),
        _sb.from('utilisateurs').select('id').eq('est_en_ligne', true).limit(9999),
        _sb.from('utilisateurs').select('id').neq('is_admin', true).gte('date_inscription', todayStr).limit(999),
        _sb.from('conversations').select('id').limit(9999),
        _sb.from('documents_verification').select('id').eq('statut', 'en_attente').limit(9999),
        _sb.from('signalements').select('id').eq('statut', 'en_attente').limit(9999),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers        = (r[0] as List).length;
          _totalClients      = (r[1] as List).length;
          _totalTechs        = (r[2] as List).length;
          _premium           = (r[3] as List).length;
          _verifies          = (r[4] as List).length;
          _enLigne           = (r[5] as List).length;
          _inscritsAujourdhui = (r[6] as List).length;
          _conversations     = (r[7] as List).length;
          _pendingDocs       = (r[8] as List).length;
          _pendingSignals    = (r[9] as List).length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin KPI: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nav(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page))
          .then((_) => _loadKpis());

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
                _buildKpiGrid(accent),
                const SizedBox(height: 20),
                if (!_loading && (_pendingDocs > 0 || _pendingSignals > 0))
                  _buildUrgentBanner(),
                if (!_loading && (_pendingDocs > 0 || _pendingSignals > 0))
                  const SizedBox(height: 20),
                _buildModules(accent),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'COCKPIT ADMIN',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: accent, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Text('Bonjour $prenom',
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Centre opérationnel FormelPro',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 22),
          onPressed: _loadKpis,
        ),
      ],
    );
  }

  Widget _buildKpiGrid(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Indicateurs clés',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            AdminKpiCard(label: 'Utilisateurs', value: _totalUsers,
                icon: Icons.people_rounded, color: const Color(0xFF3B82F6), loading: _loading),
            AdminKpiCard(label: 'Clients', value: _totalClients,
                icon: Icons.person_rounded, color: const Color(0xFF8B5CF6), loading: _loading),
            AdminKpiCard(label: 'Prestataires', value: _totalTechs,
                icon: Icons.engineering_rounded, color: accent, loading: _loading),
            AdminKpiCard(label: 'Premium', value: _premium,
                icon: Icons.workspace_premium_rounded, color: Colors.amber, loading: _loading),
            AdminKpiCard(label: 'Vérifiés', value: _verifies,
                icon: Icons.verified_rounded, color: const Color(0xFF10B981), loading: _loading),
            AdminKpiCard(label: 'En ligne', value: _enLigne,
                icon: Icons.wifi_rounded, color: Colors.greenAccent, loading: _loading),
            AdminKpiCard(label: 'Inscrits aujourd\'hui', value: _inscritsAujourdhui,
                icon: Icons.person_add_rounded, color: const Color(0xFF06B6D4), loading: _loading),
            AdminKpiCard(label: 'Conversations', value: _conversations,
                icon: Icons.chat_bubble_rounded, color: const Color(0xFFF97316), loading: _loading),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actions requises',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: Colors.redAccent)),
                const SizedBox(height: 2),
                if (_pendingDocs > 0)
                  Text(
                    '$_pendingDocs document${_pendingDocs > 1 ? 's' : ''} en attente de validation',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
                if (_pendingSignals > 0)
                  Text(
                    '$_pendingSignals signalement${_pendingSignals > 1 ? 's' : ''} à traiter',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModules(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modules',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 12),
        AdminModuleCard(
          title: 'Gestion Prestataires',
          subtitle: 'Premium, référencement ⭐, badges, suspension',
          icon: Icons.engineering_rounded,
          accentColor: accent,
          onTap: () => _nav(AdminPrestatairesPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Présence Temps Réel',
          subtitle: 'Utilisateurs connectés, activité, disponibilité',
          icon: Icons.wifi_rounded,
          accentColor: Colors.greenAccent,
          badge: _enLigne > 0 ? _enLigne : null,
          onTap: () => _nav(AdminPresencePage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Validation Documents',
          subtitle: 'CNI, Passeport, Diplôme — approuver ou rejeter',
          icon: Icons.verified_user_rounded,
          accentColor: Colors.amber,
          badge: _pendingDocs > 0 ? _pendingDocs : null,
          onTap: () => _nav(AdminDocumentsPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Signalements & Litiges',
          subtitle: 'Traiter les signalements et sanctions',
          icon: Icons.report_problem_rounded,
          accentColor: Colors.redAccent,
          badge: _pendingSignals > 0 ? _pendingSignals : null,
          onTap: () => _nav(AdminSignalementsPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Services Sensibles',
          subtitle: 'Ménagères, nounous — validation humaine obligatoire',
          icon: Icons.security_rounded,
          accentColor: const Color(0xFF8B5CF6),
          onTap: () => _nav(AdminDemandesDomestiquesPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Contacts & Inscriptions',
          subtitle: 'Emails, téléphones, localisations — export CSV',
          icon: Icons.contacts_rounded,
          accentColor: const Color(0xFF10B981),
          onTap: () => _nav(ContactsAdminPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Analytics',
          subtitle: 'Métiers populaires, communes actives, taux activité',
          icon: Icons.analytics_rounded,
          accentColor: const Color(0xFF06B6D4),
          onTap: () => _nav(AdminAnalyticsPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Tous les Utilisateurs',
          subtitle: 'Vue globale clients et prestataires',
          icon: Icons.manage_accounts_rounded,
          accentColor: const Color(0xFF3B82F6),
          onTap: () => _nav(AdminUsersPage(accentColor: accent)),
        ),
        AdminModuleCard(
          title: 'Notifications Push',
          subtitle: 'Architecture prête — envoi FCM à connecter',
          icon: Icons.notifications_rounded,
          accentColor: const Color(0xFFF97316),
          onTap: () => _nav(AdminNotificationsPage(accentColor: accent)),
        ),
      ],
    );
  }
}
