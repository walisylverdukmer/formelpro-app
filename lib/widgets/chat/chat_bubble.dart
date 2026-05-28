import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color accentColor;
  final DateTime? timestamp;
  final bool isRead;
  final String? imageUrl;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.accentColor,
    this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

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
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: _hasImage
                ? null
                : BoxDecoration(
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
            child: _hasImage
                ? _buildImageContent()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timestamp != null)
                  Text(
                    _formatTime(timestamp!),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFB0B7C3)),
                  ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: isRead ? accentColor : const Color(0xFFB0B7C3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 0),
        bottomRight: Radius.circular(isMe ? 0 : 18),
      ),
      child: Image.network(
        imageUrl!,
        width: 220,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: 220,
                height: 160,
                color: Colors.black12,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 120,
          color: Colors.black12,
          child: const Icon(
              Icons.broken_image, color: Colors.white38, size: 48),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
