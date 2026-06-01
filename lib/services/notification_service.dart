import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  /// Écoute les notifications temps réel. Annule toute subscription précédente.
  void listenToNotifications(BuildContext context) {
    _subscription?.cancel();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (!context.mounted) return;
          final nouvellesNotifs =
              data.where((n) => n['est_lu'] == false).toList();
          if (nouvellesNotifs.isEmpty) return;

          nouvellesNotifs.sort((a, b) {
            final dateA =
                DateTime.parse(a['date_notification'].toString());
            final dateB =
                DateTime.parse(b['date_notification'].toString());
            return dateB.compareTo(dateA);
          });

          final lastNotif = nouvellesNotifs.first;
          _showInAppNotification(
            context,
            lastNotif['titre'] ?? 'Notification',
            lastNotif['message'] ?? '',
            lastNotif['id'],
          );
        });
  }

  /// Annule la subscription active (appeler dans dispose() du widget parent).
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _showInAppNotification(
      BuildContext context, String titre, String message, String notifId) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: Color(0xFFE67E22), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "OK",
          textColor: const Color(0xFFE67E22),
          onPressed: () => _markAsRead(notifId),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'est_lu': true})
          .eq('id', id);
    } catch (e) {
      debugPrint("Erreur marquage notification: $e");
    }
  }
}
