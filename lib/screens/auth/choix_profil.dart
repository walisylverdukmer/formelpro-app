import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'auth_email_mdp.dart'; // Assurez-vous que ce fichier existe

// --- ÉTAPE 1 : SÉLECTION DU PAYS ---
class ChoixProfilPage extends StatelessWidget {
  const ChoixProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image de fond fixe
          Positioned.fill(
            child: Image.asset(
              "assets/images/choix_drapeau.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // Framework Centralisé
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.handyman_rounded,
                            size: 60,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "FormelPro",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choisissez votre zone d'intervention",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _buildPaysOption(context, "Côte d'Ivoire", 'CIV', "assets/images/ci.jpg"),
                            const SizedBox(width: 16),
                            _buildPaysOption(context, "Cameroun", 'CMR', "assets/images/cmr.jpg"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // COPYRIGHT EN BAS
          _buildCopyright(),
        ],
      ),
    );
  }

  Widget _buildPaysOption(BuildContext context, String nom, String code, String imagePath) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChoixRolePage(paysCode: code)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Utilisation de l'image au lieu de l'émoji
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(imagePath, width: 50, height: 35, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                nom,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ÉTAPE 2 : SÉLECTION DU RÔLE ---
class ChoixRolePage extends StatefulWidget {
  final String paysCode;
  const ChoixRolePage({super.key, required this.paysCode});

  @override
  State<ChoixRolePage> createState() => _ChoixRolePageState();
}

class _ChoixRolePageState extends State<ChoixRolePage> {
  String? roleSelectionne;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  final List<String> _imagesFond = [
    "assets/images/fond_1.jpeg",
    "assets/images/fond_2.jpeg",
    "assets/images/fond_3.jpeg",
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _imagesFond.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.paysCode == 'CIV' 
        ? const Color(0xFFE67E22) 
        : const Color(0xFFE74C3C);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _imagesFond.length,
              itemBuilder: (context, index) => Image.asset(
                _imagesFond[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Profil ${widget.paysCode == 'CIV' ? 'Ivoirien' : 'Camerounais'}",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Quel est votre statut ?",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        _buildRoleOption("Je suis Client", 'client', Icons.person, accentColor),
                        const SizedBox(height: 16),
                        _buildRoleOption("Je suis Technicien", 'technicien', Icons.handyman, accentColor),
                        
                        const SizedBox(height: 32),
                        
                        if (roleSelectionne != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AuthEmailMdpPage(
                                      paysCode: widget.paysCode,
                                      role: roleSelectionne!,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                "Continuer",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          _buildCopyright(),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String titre, String code, IconData icon, Color accentColor) {
    bool isSelected = roleSelectionne == code;
    return GestureDetector(
      onTap: () => setState(() => roleSelectionne = code),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              titre,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: accentColor),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET GLOBAL : COPYRIGHT ---
Widget _buildCopyright() {
  return Positioned(
    bottom: 20,
    left: 0,
    right: 0,
    child: Column(
      children: [
        Text(
          "Développé par Lionel Nguekam Walisylver",
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Copyright Abidjan - 2026",
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}