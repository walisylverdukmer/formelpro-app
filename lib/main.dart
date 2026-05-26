import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:formelpro/screens/auth/google_onboarding_page.dart';
import 'package:formelpro/screens/auth/page_connexion_principale.dart';
import 'package:formelpro/screens/complete_profil_page.dart';
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/screens/public/landing_page.dart';
import 'package:formelpro/services/notification_router.dart';

// Handler des messages reçus quand l'app est en arrière-plan / fermée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Le message est affiché automatiquement par FCM en notification système
}

Future<void> main() async {
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://elsweibfytmvaeasekaf.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsc3dlaWJmeXRtdmFlYXNla2FmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwMTA1NjIsImV4cCI6MjA4ODU4NjU2Mn0.jpmz7n0BXmEtneTvl2aHVhhqkfqC_vrvqJDe_NiDo4o',
  );

  debugPrint('[Config] Supabase URL: $supabaseUrl');
  debugPrint('[Config] Clé anon: ${supabaseAnonKey.substring(0, 20)}...');

  WidgetsFlutterBinding.ensureInitialized();

  // Firebase non supporté sur Web sans firebase_options.dart — mobile uniquement
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const FormelProApp());
}

class FormelProApp extends StatefulWidget {
  const FormelProApp({super.key});

  @override
  State<FormelProApp> createState() => _FormelProAppState();
}

class _FormelProAppState extends State<FormelProApp> {
  // Resolves the initial widget based on the web URL path.
  // On mobile, always returns AuthGate (no URL routing).
  Widget get _home {
    if (!kIsWeb) return const AuthGate();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return const AuthGate();
    final path = Uri.base.path;
    return switch (path) {
      '/' || '' => const LandingPage(),
      '/login' => const PageConnexionPrincipale(),
      _ => const AuthGate(),
    };
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _setupFCMRouting();
  }

  Future<void> _setupFCMRouting() async {
    // Background tap (app en mémoire, non au premier plan)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      routeFromNotification(message.data);
    });

    // Tap depuis app fermée — stocker pour consommation après login
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      pendingNotificationData = initialMessage.data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormelPro',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          primary: const Color(0xFFE67E22),
          secondary: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: _home,
    );
  }
}

// =============================================================================
// AUTHGATE — Gère la persistance de connexion et l'abonnement FCM
// =============================================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Pas de try-catch : les erreurs remontent dans FutureBuilder.hasError
  // maybeSingle() retourne null si aucune ligne (nouveau user Google)
  Future<Map<String, dynamic>?> _getUserProfile(String userId) {
    return Supabase.instance.client
        .from('utilisateurs')
        .select('role, pays, a_complete_profil')
        .eq('id', userId)
        .maybeSingle();
  }

  // Demande la permission et abonne l'appareil au topic FCM de l'utilisateur
  Future<void> _initFCM(String userId) async {
    if (kIsWeb) return; // FCM non disponible sur Web
    try {
      final messaging = FirebaseMessaging.instance;

      // Demande permission (iOS + Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Abonnement au topic personnel de l'utilisateur
        await messaging.subscribeToTopic('user_$userId');
        debugPrint("FCM: abonné au topic user_$userId");
      }

      // Gérer les messages reçus quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          debugPrint("FCM foreground: ${notification.title} — ${notification.body}");
          // Le NotificationService Supabase gère déjà l'affichage via SnackBar.
          // FCM foreground est donc silencieux ici pour éviter les doublons.
        }
      });

    } catch (e) {
      debugPrint("Erreur init FCM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return const PageConnexionPrincipale();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserProfile(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            // Erreur réseau / DB : retour à la page de connexion
            if (profileSnapshot.hasError) {
              debugPrint("AuthGate erreur profil: ${profileSnapshot.error}");
              return const PageConnexionPrincipale();
            }

            final data = profileSnapshot.data;

            // Pas de ligne dans utilisateurs → nouvel utilisateur Google
            if (data == null) {
              final provider =
                  session.user.appMetadata['provider'] as String? ?? '';
              if (provider == 'google') {
                return const GoogleOnboardingPage();
              }
              // Cas anormal (email sans profil) → retour login
              return const PageConnexionPrincipale();
            }

            final bool aCompleteProfil = data['a_complete_profil'] ?? false;

            // Abonnement FCM dès que l'utilisateur est authentifié
            _initFCM(session.user.id);

            if (aCompleteProfil) {
              return const MainDashboardPage();
            } else {
              return CompleteProfilPage(
                role: data['role'] ?? 'client',
                paysCode: data['pays'] ?? 'CIV',
              );
            }
          },
        );
      },
    );
  }
}

// =============================================================================
// LOADING SCREEN
// =============================================================================
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.handyman_rounded,
                size: 80,
                color: Color(0xFFE67E22),
              ),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: Color(0xFFE67E22), strokeWidth: 3),
            const SizedBox(height: 20),
            Text(
              "Chargement de FormelPro...",
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
