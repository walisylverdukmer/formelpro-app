import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'choix_profil.dart';
import 'google_onboarding_page.dart';
import 'reset_password_page.dart';
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/screens/complete_profil_page.dart';
import 'package:formelpro/screens/public/landing_page.dart';
import 'package:formelpro/widgets/google_sign_in_button.dart';

final supabase = Supabase.instance.client;

class PageConnexionPrincipale extends StatefulWidget {
  const PageConnexionPrincipale({super.key});

  @override
  State<PageConnexionPrincipale> createState() =>
      _PageConnexionPrincipaleState();
}

class _PageConnexionPrincipaleState extends State<PageConnexionPrincipale> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingGoogle = false;
  bool _showPassword = false;
  String? _errorMessage;
  bool _hasNavigated = false;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen(_onAuthChange);
  }

  Future<void> _onAuthChange(AuthState data) async {
    if (!mounted || _hasNavigated) return;
    if (data.event != AuthChangeEvent.signedIn) return;
    final user = data.session?.user;
    if (user == null) return;
    _hasNavigated = true;

    try {
      final response = await supabase
          .from('utilisateurs')
          .select('role, pays, a_complete_profil')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      if (response == null) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const GoogleOnboardingPage()), (r) => false);
      } else if (response['a_complete_profil'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const MainDashboardPage()), (r) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(CompleteProfilPage(
            role: response['role'] ?? 'client',
            paysCode: response['pays'] ?? 'CIV',
          )),
          (r) => false,
        );
      }
    } catch (e) {
      debugPrint('Post-auth navigation error: $e');
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        final response = await supabase
            .from('utilisateurs')
            .select('role, pays, a_complete_profil')
            .eq('id', res.user!.id)
            .single();
        final bool aCompleteProfil = response['a_complete_profil'] ?? false;
        final String role = response['role'] ?? 'client';
        final String paysCode = response['pays'] ?? 'CIV';
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          if (aCompleteProfil) {
            Navigator.of(context).pushAndRemoveUntil(
              _fadeRoute(const MainDashboardPage()), (r) => false);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              _fadeRoute(CompleteProfilPage(role: role, paysCode: paysCode)),
              (r) => false,
            );
          }
        }
      }
    } on AuthException catch (error) {
      setState(() => _errorMessage = _translateError(error.message));
    } catch (error) {
      setState(
        () => _errorMessage = 'Une erreur est survenue lors de la connexion.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static Route<void> _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  static const _mobileRedirectUrl = 'formelpro://login-callback/';

  // Runtime getter — lit l'origine réelle du navigateur, immune aux dart-defines
  // En prod : https://formelpro-app.vercel.app  /  En dev : http://localhost:PORT
  static String get _webRedirectUrl =>
      kIsWeb ? Uri.base.origin : 'https://formelpro-app.vercel.app';

  String get _oauthRedirectUrl =>
      kIsWeb ? _webRedirectUrl : _mobileRedirectUrl;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _translateError(e.message));
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Connexion Google impossible. Vérifiez votre connexion.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  String _translateError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre adresse email.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x77000000), Color(0xDD0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 40),
                  _buildCard(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  GoogleSignInButton(
                    isLoading: _isLoadingGoogle,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 28),
                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
          // Bouton retour — en dernier pour être au-dessus de tout
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 20),
              tooltip: "Retour à l'accueil",
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LandingPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.handyman_rounded,
            size: 72,
            color: Color(0xFFE67E22),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'FormelPro',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "L'excellence à votre portée",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Connexion',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          _buildField(
            _emailController,
            'Adresse email',
            Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildField(
            _passwordController,
            'Mot de passe',
            Icons.lock_outline,
            isPassword: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordPage(),
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.red.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E22),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Se connecter',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && !_showPassword,
        keyboardType: keyboard,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChoixProfilPage()),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
            children: const [
              TextSpan(text: "Pas encore de compte ? "),
              TextSpan(
                text: 'Créer un profil',
                style: TextStyle(
                  color: Color(0xFFE67E22),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
