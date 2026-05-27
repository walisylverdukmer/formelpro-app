import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_bubble.dart';
import 'proforma_card.dart';
import 'system_message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final String? currentUserId;
  final Color accentColor;
  final void Function(String msgId, String content) onProformaAccept;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.accentColor,
    required this.onProformaAccept,
  });

  static bool isSystemMessage(String content) =>
      content.startsWith('✅ OFFRE') ||
      content.startsWith('❌ OFFRE') ||
      content.startsWith('✅ Intervention') ||
      content.startsWith('✅ Mission');

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return _buildEmpty();
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final isMe = msg['expediteur_id'] == currentUserId;
        final content = (msg['contenu'] as String?) ?? '';
        final rawDate = msg['cree_le'];
        final timestamp = rawDate != null
            ? DateTime.tryParse(rawDate.toString())
            : null;

        if (isSystemMessage(content)) {
          return SystemMessageBubble(text: content);
        }
        if (msg['est_proposition_intervention'] == true) {
          return ProformaCard(
            msg: msg,
            isMe: isMe,
            accentColor: accentColor,
            onAccept: onProformaAccept,
          );
        }
        return ChatBubble(
          text: content,
          isMe: isMe,
          accentColor: accentColor,
          timestamp: timestamp,
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 52, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 14),
        Text(
          'Démarrez la conversation',
          style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Échangez avant de convenir d\'une prestation',
          style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1), fontSize: 13),
        ),
      ]),
    );
  }
}
