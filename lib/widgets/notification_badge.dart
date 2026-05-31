import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationBadge extends StatelessWidget {
  final Color iconColor;
  final Color badgeBorderColor;

  const NotificationBadge({
    super.key,
    this.iconColor = Colors.white,
    this.badgeBorderColor = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .order('date_notification', ascending: false),
      builder: (context, snapshot) {
        // Filtrage manuel pour l'utilisateur actuel
        final allNotifs = snapshot.data ?? [];
        final userNotifs = allNotifs.where((n) => n['user_id'] == userId).toList();
        final int count = userNotifs.where((n) => n['est_lu'] == false).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, size: 24, color: iconColor),
              onPressed: () => _showNotificationSheet(context, userId, userNotifs),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeBorderColor, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, String userId, List<Map<String, dynamic>> notifications) {
    final supabase = Supabase.instance.client;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Notifications", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (notifications.any((n) => n['est_lu'] == false))
                        TextButton(
                          onPressed: () => supabase.from('notifications').update({'est_lu': true}).eq('user_id', userId),
                          child: const Text("Tout lire", style: TextStyle(color: Color(0xFFE67E22))),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: notifications.isEmpty
                      ? const Center(child: Text("Aucune notification", style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            final bool isRead = n['est_lu'] ?? false;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isRead ? Colors.white10 : const Color(0xFFE67E22).withValues(alpha: 0.2),
                                child: Icon(
                                  _getIconByType(n['type']), 
                                  size: 18, 
                                  color: isRead ? Colors.white24 : const Color(0xFFE67E22)
                                ),
                              ),
                              title: Text(n['titre'] ?? 'Notification', 
                                  style: GoogleFonts.inter(
                                    color: Colors.white, 
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold, 
                                    fontSize: 14)),
                              subtitle: Text(n['message'] ?? '', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                              onTap: () {
                                if (!isRead) {
                                  supabase.from('notifications').update({'est_lu': true}).eq('id', n['id']);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconByType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline_rounded;
      case 'intervention': return Icons.build_circle_outlined;
      case 'accord': return Icons.handshake_outlined;
      default: return Icons.notifications_none_rounded;
    }
  }
}