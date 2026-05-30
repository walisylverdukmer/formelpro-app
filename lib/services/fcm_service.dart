import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_router.dart';

/// Service FCM singleton — token, topics, notifications foreground.
/// Se désactive silencieusement sur Web (kIsWeb = true).
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _sb = Supabase.instance.client;
  final _fm = FirebaseMessaging.instance;

  bool _initialized = false;

  // ── API publique ─────────────────────────────────────────────────────────────

  /// Appeler après login avec les données du profil utilisateur.
  Future<void> init({
    required String uid,
    required String role,
    required bool isPremium,
  }) async {
    if (kIsWeb) return;
    try {
      final settings = await _fm.requestPermission(
        alert: true, badge: true, sound: true,
        announcement: false, carPlay: false, criticalAlert: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FcmService: permission refusée');
        return;
      }
      await _saveToken(uid);
      await _setupTopics(uid, role, isPremium);
      if (!_initialized) {
        _listenTokenRefresh(uid);
        _listenForeground();
        _initialized = true;
      }
      debugPrint('FcmService: initialisé (role=$role, premium=$isPremium)');
    } catch (e) {
      debugPrint('FcmService.init: $e');
    }
  }

  /// À appeler avant déconnexion (désabonnement topics + effacement token).
  Future<void> dispose(String uid) async {
    if (kIsWeb) return;
    try {
      await Future.wait([
        _fm.unsubscribeFromTopic('user_$uid'),
        _fm.unsubscribeFromTopic('broadcast'),
        _fm.unsubscribeFromTopic('clients'),
        _fm.unsubscribeFromTopic('prestataires'),
        _fm.unsubscribeFromTopic('premium'),
      ]);
      await _sb.from('utilisateurs').update({'fcm_token': null}).eq('id', uid);
      _initialized = false;
      debugPrint('FcmService: désabonné');
    } catch (e) {
      debugPrint('FcmService.dispose: $e');
    }
  }

  // ── Privé ────────────────────────────────────────────────────────────────────

  Future<void> _saveToken(String uid) async {
    try {
      final token = await _fm.getToken();
      if (token == null) return;
      await _sb
          .from('utilisateurs')
          .update({'fcm_token': token})
          .eq('id', uid);
      debugPrint('FcmService: token sauvegardé');
    } catch (e) {
      debugPrint('FcmService._saveToken: $e');
    }
  }

  Future<void> _setupTopics(
      String uid, String role, bool isPremium) async {
    try {
      await _fm.subscribeToTopic('user_$uid');
      await _fm.subscribeToTopic('broadcast');
      if (role == 'technicien') {
        await _fm.subscribeToTopic('prestataires');
      } else {
        await _fm.subscribeToTopic('clients');
      }
      if (isPremium) {
        await _fm.subscribeToTopic('premium');
      }
    } catch (e) {
      debugPrint('FcmService._setupTopics: $e');
    }
  }

  void _listenTokenRefresh(String uid) {
    _fm.onTokenRefresh.listen((newToken) async {
      try {
        await _sb
            .from('utilisateurs')
            .update({'fcm_token': newToken})
            .eq('id', uid);
        debugPrint('FcmService: token rafraîchi');
      } catch (e) {
        debugPrint('FcmService._listenTokenRefresh: $e');
      }
    });
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _showForegroundBanner(
        notification.title ?? 'FormelPro',
        notification.body ?? '',
        message.data,
      );
    });
  }

  void _showForegroundBanner(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Color(0xFFE67E22), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13)),
                if (body.isNotEmpty)
                  Text(body,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: data.isNotEmpty
            ? SnackBarAction(
                label: 'Ouvrir',
                textColor: const Color(0xFFE67E22),
                onPressed: () => routeFromNotification(data),
              )
            : null,
      ),
    );
  }
}
