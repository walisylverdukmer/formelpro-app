import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORTS ---
import 'package:formelpro/models/service_category.dart';
import 'package:formelpro/screens/tabs/missions_tab.dart';
import 'package:formelpro/screens/tabs/demandes_tab.dart';
import 'package:formelpro/screens/dashboard/profil_tab.dart';
import 'package:formelpro/screens/booking/sub_categories_page.dart';
import 'package:formelpro/screens/dashboard/accueil_technicien.dart';
import 'package:formelpro/screens/dashboard/accueil_client.dart';
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

class _MainDashboardPageState extends State<MainDashboardPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();
  final _presenceService = PresenceService();
  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  @override
  void dispose() {
    _unreadCount.dispose();
    _presenceService.stop();
    super.dispose();
  }

  // Définition des ombres pour la lisibilité sur fond d'image
  final List<Shadow> _textShadows = [
    Shadow(
      offset: const Offset(0, 1.5),
      blurRadius: 4.0,
      color: Colors.black.withValues(alpha: 0.6),
    ),
  ];

  @override
  void initState() {
    super.initState();
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
            .select('id, role, pays, prenom, nom_complet, photo_profil_url, ville, commune, quartier, score_global, note_moyenne, total_transactions, is_premium, metier_personnalise, disponible, is_identite_verifiee, a_complete_profil, telephone, savoir_faire, is_admin')
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
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
      );
    }

    final bool isCI = _userData!['pays'] == 'CIV';
    final String backgroundImage = isCI ? 'assets/images/fond_ci.jpeg' : 'assets/images/fond_cmr.jpeg';
    final Color accentColor = isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    final String role = _userData!['role']?.toString().toLowerCase() ?? 'client';

    final String uid = _userData!['id']?.toString() ?? '';

    final List<Widget> pages = [
      role == 'technicien'
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
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          role == 'technicien' ? "Espace Technicien" : "FormelPro",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
            color: Colors.white,
            shadows: _textShadows,
          ),
        ),
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // On n'affiche le fond que si on n'est pas sur l'accueil technicien (qui gère son propre fond)
          if (role == 'client' || _currentIndex != 0)
            Positioned.fill(
              child: Image.asset(
                backgroundImage, 
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ],
      ),
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
        color: const Color(0xFF0F172A).withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4), 
            blurRadius: 20, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
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

// --- ONGLET ACCUEIL (CONSERVÉ POUR LA STRUCTURE MAIS REMPLACÉ PAR ACCUEILCLIENT DANS LA LISTE PAGES) ---
class OngletAccueil extends StatefulWidget {
  final String flagPath;
  final Color accentColor;

  const OngletAccueil({super.key, required this.flagPath, required this.accentColor});

  @override
  State<OngletAccueil> createState() => _OngletAccueilState();
}

class _OngletAccueilState extends State<OngletAccueil> {
  List<ServiceCategory> _categories = [];
  bool _loadingCats = true;
  
  final List<Shadow> _shadows = [
    Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: Colors.black.withValues(alpha: 0.5))
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await supabase
          .from('categories_services')
          .select('id, nom, slug, groupe_parent, est_valide')
          .eq('est_valide', true)
          .order('ordre_affichage');

      final List<dynamic> data = response;
      final Map<String, ServiceCategory> uniqueGroups = {};
      
      for (var item in data) {
        final cat = ServiceCategory.fromMap(item);
        if (!uniqueGroups.containsKey(cat.groupeParent)) {
          uniqueGroups[cat.groupeParent] = cat;
        }
      }

      if (mounted) {
        setState(() {
          _categories = uniqueGroups.values.toList();
          _loadingCats = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur catégories: $e");
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60), 
            _buildSectionTitle("De quoi avez-vous besoin ?"),
            const SizedBox(height: 15),
            _buildGrid(),
            const SizedBox(height: 30),
            _buildSectionTitle("Interventions"),
            const SizedBox(height: 15),
            _buildStatButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(), 
      style: GoogleFonts.inter(
        fontSize: 11, 
        fontWeight: FontWeight.w800, 
        color: Colors.white,
        shadows: _shadows,
        letterSpacing: 1.2
      )
    );
  }

  Widget _buildGrid() {
    if (_loadingCats) return const Center(child: CircularProgressIndicator(color: Colors.white));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.3,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
    );
  }

  Widget _buildCategoryCard(ServiceCategory cat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategoriesPage(
              groupName: cat.groupeParent,
              accentColor: widget.accentColor,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: AssetImage(cat.localImageAsset), fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              cat.groupeParent, 
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatButton() {
    return InkWell(
      onTap: () {
        final mainState = context.findAncestorStateOfType<_MainDashboardPageState>();
        mainState?.setState(() => mainState._currentIndex = 1);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.accentColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.pending_actions_rounded, color: widget.accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Suivre mes demandes", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, shadows: _shadows)),
                  Text("Consultez l'état de vos services", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}