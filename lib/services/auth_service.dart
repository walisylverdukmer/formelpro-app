import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Inscription avec Email et Mot de Passe
  Future<AuthResponse> signUp(String email, String password, String role, String pays) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        // Ces métadonnées sont utiles pour l'AuthGate lors de la première redirection
        data: {
          'role': role, 
          'pays': pays,
          'a_complete_profil': false, // Initialisé à faux par défaut
        },
      );
      return response;
    } catch (e) {
      debugPrint("Erreur Inscription: $e");
      rethrow;
    }
  }

  // 2. Connexion
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Erreur Connexion: $e");
      rethrow;
    }
  }

  // 3. Récupérer les données du profil de l'utilisateur actuel
  // Retourne un objet UserModel pour une manipulation facile dans l'app
  Future<UserModel?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final data = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromMap(data);
    } catch (e) {
      debugPrint("Erreur profil: $e");
      return null;
    }
  }

  // 4. Mettre à jour le statut du profil (utile après CompleteProfilPage)
  Future<void> markProfileAsComplete(String userId) async {
    try {
      await _supabase
          .from('utilisateurs')
          .update({'a_complete_profil': true})
          .eq('id', userId);
    } catch (e) {
      debugPrint("Erreur mise à jour profil: $e");
      rethrow;
    }
  }

  static const _webRedirectUrl = 'https://formelpro-app.vercel.app';
  static const _mobileRedirectUrl = 'formelpro://login-callback/';

  // 5. Connexion via Google OAuth (Supabase Auth)
  Future<void> signInWithGoogle() async {
    const redirectTo = kIsWeb ? _webRedirectUrl : _mobileRedirectUrl;
    debugPrint('[OAuth] signInWithGoogle — redirect: $redirectTo');
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  // 6. Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Erreur Déconnexion: $e");
    }
  }

  // 7. Récupérer l'ID de l'utilisateur actuel (Helper)
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // 8. Stream sur l'état de l'authentification (Utile pour réagir en temps réel)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}