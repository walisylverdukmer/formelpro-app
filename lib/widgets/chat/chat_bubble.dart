import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color accentColor;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.accentColor,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? accentColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 5)
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 6, left: 4, right: 4),
              child: Text(
                _formatTime(timestamp!),
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFFB0B7C3)),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
