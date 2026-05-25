import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:formelpro/screens/auth/page_connexion_principale.dart';
import 'package:formelpro/screens/complete_profil_page.dart';
import 'package:formelpro/screens/dashboard/main_dashboard.dart';
import 'package:formelpro/services/notification_router.dart';

// Handler des messages reçus quand l'app est en arrière-plan / fermée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Le message est affiché automatiquement par FCM en notification système
}

Future<void> main() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(
    supabaseUrl.isNotEmpty,
    'SUPABASE_URL non défini — lancer avec : flutter run --dart-define-from-file=dart_defines.json',
  );
  assert(
    supabaseAnonKey.isNotEmpty,
    'SUPABASE_ANON_KEY non défini — lancer avec : flutter run --dart-define-from-file=dart_defines.json',
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Firebase non supporté sur Web sans firebase_options.dart — mobile uniquement
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const FormelProApp());
}

class FormelProApp extends StatefulWidget {
  const FormelProApp({super.key});

  @override
  State<FormelProApp> createState() => _FormelProAppState();
}

class _FormelProAppState extends State<FormelProApp> {
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
      home: const AuthGate(),
    );
  }
}

// =============================================================================
// AUTHGATE — Gère la persistance de connexion et l'abonnement FCM
// =============================================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      return await Supabase.instance.client
          .from('utilisateurs')
          .select('role, pays, a_complete_profil')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint("Erreur AuthGate (Profil): $e");
      return null;
    }
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

            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              return const PageConnexionPrincipale();
            }

            final data = profileSnapshot.data!;
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
            const CircularProgressIndicator(color: Color(0xFFE67E22), strokeWidth: 3),
            const SizedBox(height: 25),
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
