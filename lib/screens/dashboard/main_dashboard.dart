import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/screens/tabs/missions_tab.dart';
import 'package:formelpro/screens/tabs/demandes_tab.dart';
import 'package:formelpro/screens/dashboard/profil_tab.dart';
import 'package:formelpro/screens/dashboard/accueil_technicien.dart';
import 'package:formelpro/screens/dashboard/accueil_client.dart';
import 'package:formelpro/screens/admin/accueil_admin.dart';
import 'package:formelpro/screens/chat/conversations_tab.dart';

import 'package:formelpro/services/notification_service.dart';
import 'package:formelpro/services/notification_router.dart';
import 'package:formelpro/services/presence_service.dart';
import 'package:formelpro/widgets/notification_badge.dart';

final supabase = Supabase.instance.client;

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();
  final _presenceService = PresenceService();
  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadCount.dispose();
    _presenceService.stop();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[Dashboard] AppLifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      // Relancer le heartbeat de présence sans rebuild de l'UI
      final uid = _userData?['id'] as String?;
      if (uid != null) _presenceService.start(uid);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();
    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    final data = pendingNotificationData;
    if (data == null) return;
    pendingNotificationData = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      routeFromNotification(data);
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('utilisateurs')
            .select(
              'id, role, pays, prenom, nom_complet, photo_profil_url, ville, commune, quartier, score_global, note_moyenne, total_transactions, is_premium, premium_until, metier_personnalise, disponible, is_identite_verifiee, a_complete_profil, telephone, savoir_faire, is_admin',
            )
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _userData = response;
            _isLoading = false;
          });
          _presenceService.start(user.id);
          _notificationService.listenToNotifications(context);
        }
      }
    } catch (e) {
      debugPrint("Erreur récupération profil: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.handyman_rounded,
                  size: 64,
                  color: Color(0xFFE67E22),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFFE67E22),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    final bool isCI = _userData!['pays'] == 'CIV';
    final Color accentColor =
        isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String role =
        _userData!['role']?.toString().toLowerCase() ?? 'client';
    final String uid = _userData!['id']?.toString() ?? '';

    final bool isAdmin = _userData!['is_admin'] == true;

    final List<Widget> pages = [
      isAdmin
          ? AccueilAdmin(userData: _userData!, accentColor: accentColor)
          : role == 'technicien'
              ? AccueilTechnicien(userData: _userData!)
              : AccueilClient(userData: _userData!),
      ConversationsTab(
        accentColor: accentColor,
        uid: uid,
        unreadNotifier: _unreadCount,
      ),
      role == 'technicien'
          ? MissionsTab(accentColor: accentColor)
          : DemandesTab(accentColor: accentColor),
      ProfilTab(userData: _userData!, accentColor: accentColor),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            Text(
              isAdmin
                  ? "Admin"
                  : role == 'technicien'
                      ? "Espace Technicien"
                      : "FormelPro",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBadge(),
          SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(accentColor, role),
    );
  }

  Widget _buildMessageIcon(IconData icon) {
    return ValueListenableBuilder<int>(
      valueListenable: _unreadCount,
      builder: (_, count, __) {
        if (count == 0) return Icon(icon);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(Color accentColor, String role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: accentColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: _buildMessageIcon(Icons.chat_bubble_outline_rounded),
            activeIcon: _buildMessageIcon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment),
            label: role == 'technicien' ? 'Missions' : 'Suivi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
