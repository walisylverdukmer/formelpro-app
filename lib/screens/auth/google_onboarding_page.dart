import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/screens/complete_profil_page.dart';

class GoogleOnboardingPage extends StatefulWidget {
  const GoogleOnboardingPage({super.key});

  @override
  State<GoogleOnboardingPage> createState() => _GoogleOnboardingPageState();
}

class _GoogleOnboardingPageState extends State<GoogleOnboardingPage> {
  String? _selectedPays;
  String? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  String get _displayName {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return meta['full_name'] as String? ??
        meta['name'] as String? ??
        Supabase.instance.client.auth.currentUser?.email?.split('@').first ??
        'Utilisateur';
  }

  String? get _avatarUrl {
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    return meta['avatar_url'] as String? ?? meta['picture'] as String?;
  }

  Color get _accentColor =>
      _selectedPays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFCE1126);

  Future<void> _createProfile() async {
    if (_selectedPays == null || _selectedRole == null) {
      setState(() => _errorMessage = 'Veuillez sélectionner votre pays et votre rôle.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final meta = user.userMetadata ?? {};

      await Supabase.instance.client.from('utilisateurs').upsert(
        {
          'id': user.id,
          'email': user.email,
          'nom_complet': meta['full_name'] ?? meta['name'] ?? '',
          'photo_profil_url': meta['avatar_url'] ?? meta['picture'],
          'role': _selectedRole,
          'pays': _selectedPays,
          'a_complete_profil': false,
        },
        onConflict: 'id',
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => CompleteProfilPage(
              role: _selectedRole!,
              paysCode: _selectedPays!,
            ),
            transitionDuration: const Duration(milliseconds: 350),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('GoogleOnboarding erreur: $e');
      if (mounted) setState(() => _errorMessage = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/logo.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                _buildAvatar(),
                const SizedBox(height: 20),
                Text(
                  'Bienvenue, $_displayName !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configurez votre compte FormelPro',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildSectionLabel('Votre pays'),
                const SizedBox(height: 12),
                _buildPaysSelector(),
                const SizedBox(height: 28),
                _buildSectionLabel('Votre rôle'),
                const SizedBox(height: 12),
                _buildRoleSelector(),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF6B6B)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedPays != null && _selectedRole != null && !_isLoading)
                        ? _createProfile
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPays != null
                          ? _accentColor
                          : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Continuer',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  Widget _buildAvatar() {
    final url = _avatarUrl;
    return CircleAvatar(
      radius: 44,
      backgroundColor: const Color(0xFF1E293B),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? const Icon(Icons.person, size: 44, color: Colors.white54)
          : null,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPaysSelector() {
    return Row(
      children: [
        _buildPaysOption('Côte d\'Ivoire', 'CIV', const Color(0xFFE67E22)),
        const SizedBox(width: 12),
        _buildPaysOption('Cameroun', 'CMR', const Color(0xFFCE1126)),
      ],
    );
  }

  Widget _buildPaysOption(String nom, String code, Color color) {
    final isSelected = _selectedPays == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPays = code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: isSelected ? color : Colors.white38,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                nom,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      children: [
        _buildRoleOption('Je suis Client', 'client', Icons.person_outline),
        const SizedBox(height: 10),
        _buildRoleOption(
            'Je suis Technicien', 'technicien', Icons.handyman_outlined),
      ],
    );
  }

  Widget _buildRoleOption(String titre, String code, IconData icon) {
    final isSelected = _selectedRole == code;
    final color =
        _selectedPays != null ? _accentColor : const Color(0xFFE67E22);
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? color : Colors.white54, size: 22),
            const SizedBox(width: 14),
            Text(
              titre,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
