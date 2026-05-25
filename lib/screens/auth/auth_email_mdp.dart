import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Importations nécessaires
import 'package:formelpro/screens/complete_profil_page.dart'; 
import 'package:formelpro/screens/auth/page_connexion_principale.dart'; 

final supabase = Supabase.instance.client;

class AuthEmailMdpPage extends StatefulWidget {
  final String paysCode;
  final String role;

  const AuthEmailMdpPage({super.key, required this.paysCode, required this.role});

  @override
  State<AuthEmailMdpPage> createState() => _AuthEmailMdpPageState();
}

class _AuthEmailMdpPageState extends State<AuthEmailMdpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  bool _isLoading = false;
  String? _errorMessage;

  // --- FONCTION : INSCRIPTION ---
  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Les mots de passe ne correspondent pas.";
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = "Le mot de passe doit contenir au moins 6 caractères.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (res.user != null) {
        await supabase.from('utilisateurs').upsert({
          'id': res.user!.id,
          'role': widget.role,
          'pays': widget.paysCode,
          'email': res.user!.email,
        }, onConflict: 'id');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CompleteProfilPage(
                role: widget.role,
                paysCode: widget.paysCode,
              ),
            ),
          );
        }
      }
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'Une erreur inattendue est survenue.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Définition de la couleur d'accentuation et du chemin du drapeau
    bool isCI = widget.paysCode == 'CIV';
    Color accentColor = isCI ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);
    String flagPath = isCI ? "assets/images/ci.jpg" : "assets/images/cmr.jpg";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Positioned.fill(
            child: Image.asset(
              "assets/images/login_bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // BOUTON RETOUR
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 2. FRAMEWORK CENTRALISÉ
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // AJOUT DU DRAPEAU DYNAMIQUE
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                width: 60,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: AssetImage(flagPath),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                              ),
                            ),
                            Text(
                              'Finalisation',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 26, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Profil ${widget.role} • ${widget.paysCode}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13, 
                                color: Colors.white.withValues(alpha: 0.7)
                              ),
                            ),
                            const SizedBox(height: 25),
                            
                            _buildGlassTextField(
                              controller: _emailController,
                              label: 'Adresse email',
                              icon: Icons.email_outlined,
                              accentColor: accentColor,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildGlassTextField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              icon: Icons.lock_outline,
                              accentColor: accentColor,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),

                            _buildGlassTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmer le mot de passe',
                              icon: Icons.lock_reset_outlined,
                              accentColor: accentColor,
                              obscureText: true,
                            ),
                            const SizedBox(height: 25),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                              ),
                              child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Créer mon compte', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            ),

                            // LIEN VERS LA PAGE DE CONNEXION
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const PageConnexionPrincipale())
                                );
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: "Vous avez déjà un compte ? ",
                                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: "Connectez-vous",
                                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. COPYRIGHT EN BAS DE PAGE
          Positioned(
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
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}