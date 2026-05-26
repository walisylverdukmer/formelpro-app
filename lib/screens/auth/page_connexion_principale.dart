import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'choix_profil.dart';
import 'reset_password_page.dart';
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/screens/complete_profil_page.dart';
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

  @override
  void dispose() {
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
        if (mounted) {
          if (aCompleteProfil) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainDashboardPage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    CompleteProfilPage(role: role, paysCode: paysCode),
              ),
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

  static const _mobileRedirectUrl = 'formelpro://login-callback/';
  static const _productionWebUrl = 'https://formelpro-app.vercel.app';

  String get _webRedirectUrl {
    if (!kIsWeb) return _mobileRedirectUrl;
    // En release (build web Vercel) : URL de production fixe
    if (kReleaseMode) return _productionWebUrl;
    // En dev local : origine dynamique (localhost:xxxx)
    return Uri.base.origin;
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirectUrl,
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
