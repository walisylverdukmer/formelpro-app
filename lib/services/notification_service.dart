import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  /// Écoute en temps réel les notifications de l'utilisateur connecté
  void listenToNotifications(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
      
      // 1. Filtrer uniquement les notifications non lues
      final nouvellesNotifs = data.where((n) => n['est_lu'] == false).toList();
      
      if (nouvellesNotifs.isNotEmpty) {
        // 2. Trier par date (plus récente en premier)
        nouvellesNotifs.sort((a, b) {
          final dateA = DateTime.parse(a['date_notification'].toString());
          final dateB = DateTime.parse(b['date_notification'].toString());
          return dateB.compareTo(dateA);
        });

        final lastNotif = nouvellesNotifs.first;
        
        // 3. Affichage de l'alerte In-App (SnackBar)
        _showInAppNotification(
          context, 
          lastNotif['titre'] ?? 'Notification', 
          lastNotif['message'] ?? '',
          lastNotif['id'],
        );
      }
    });
  }

  /// Affiche un SnackBar premium
  void _showInAppNotification(BuildContext context, String titre, String message, String notifId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFFE67E22), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre, 
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message, 
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  /// Marque comme lue
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