import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORTS ALIGNÉS SUR VOTRE ARCHITECTURE ---
import 'choix_profil.dart';
import 'reset_password_page.dart';
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/screens/complete_profil_page.dart';
import 'package:formelpro/widgets/google_sign_in_button.dart';

final supabase = Supabase.instance.client;

class PageConnexionPrincipale extends StatefulWidget {
  const PageConnexionPrincipale({super.key});

  @override
  State<PageConnexionPrincipale> createState() => _PageConnexionPrincipaleState();
}

class _PageConnexionPrincipaleState extends State<PageConnexionPrincipale> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  String? _errorMessage;

  // --- Fonction de Connexion ---
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // Récupération des données étendues du profil
        final response = await supabase
            .from('utilisateurs')
            .select('role, pays, a_complete_profil')
            .eq('id', res.user!.id)
            .single();

        final bool aCompleteProfil = response['a_complete_profil'] ?? false;
        final String role = response['role'] ?? 'client';
        final String paysCode = response['pays'] ?? 'CIV';

        if (mounted) {
          if (aCompleteProfil) {
            // Redirection vers le MainDashboard qui gère l'aiguillage Client/Tech
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainDashboardPage()),
            );
          } else {
            // Redirection vers la finalisation du profil si incomplet
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CompleteProfilPage(role: role, paysCode: paysCode),
              ),
            );
          }
        }
      }
    } on AuthException catch (error) {
      setState(() => _errorMessage = _translateError(error.message));
    } catch (error) {
      setState(() => _errorMessage = 'Une erreur est survenue lors de la connexion.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static const _webRedirectUrl = 'https://formelpro-app.vercel.app';
  static const _mobileRedirectUrl = 'formelpro://login-callback/';

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });

    const redirectTo = kIsWeb ? _webRedirectUrl : _mobileRedirectUrl;
    debugPrint('[OAuth] Démarrage — plateforme: ${kIsWeb ? "web" : "mobile"} — redirect: $redirectTo');

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        // Web : navigation dans l'onglet courant (platformDefault)
        // Mobile : navigateur externe (externalApplication)
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      debugPrint('[OAuth] OAuth initié avec succès');
      // Sur web : le navigateur redirige — AuthGate reprend via onAuthStateChange
      // Sur mobile : le deep link revient ici — même mécanisme
    } on AuthException catch (e) {
      debugPrint('[OAuth] AuthException: ${e.message}');
      if (mounted) {
        setState(() => _errorMessage = _translateError(e.message));
      }
    } catch (e) {
      debugPrint('[OAuth] Erreur inattendue: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Connexion Google impossible. Vérifiez votre connexion.');
      }
    } finally {
      // Sur web le finally s'exécute avant la redirection — ne pas logguer comme erreur
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  // Utilitaire simple pour traduire les erreurs courantes de Supabase
  String _translateError(String message) {
    if (message.contains("Invalid login credentials")) {
      return "Email ou mot de passe incorrect.";
    }
    if (message.contains("Email not confirmed")) {
      return "Veuillez confirmer votre adresse email.";
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. FILTRE SOMBRE
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // 3. CONTENU PRINCIPAL
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.handyman_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "FORMELPRO",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "L'excellence à votre portée",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 50),

                    // --- FORMULAIRE GLASSMORPHISM ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Connexion",
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              
                              _buildTextField(
                                controller: _emailController,
                                hintText: 'Adresse Email',
                                icon: Icons.email_outlined,
                                isPassword: false,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Mot de passe',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFE67E22).withValues(alpha: 0.5),
                                ),
                                child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('SE CONNECTER', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              ),
                              
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B)), textAlign: TextAlign.center),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Séparateur OU ───
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Bouton Google ───
                    GoogleSignInButton(
                      isLoading: _isLoadingGoogle,
                      onPressed: _signInWithGoogle,
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ChoixProfilPage()),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                          children: [
                            const TextSpan(text: "Vous n'avez pas de compte ?\n"),
                            TextSpan(
                              text: "Créer un profil",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFE67E22)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE67E22), width: 2),
        ),
      ),
    );
  }
}