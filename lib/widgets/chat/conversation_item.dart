import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationItem extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String lastMsg;
  final bool unread;
  final String formattedTime;
  final Color accentColor;
  final VoidCallback onTap;

  const ConversationItem({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.lastMsg,
    required this.unread,
    required this.formattedTime,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                backgroundImage: photoUrl?.isNotEmpty == true
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl?.isNotEmpty != true
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      )
                    : null,
              ),
              if (unread)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight:
                                unread ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: unread ? accentColor : Colors.white38,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: unread ? Colors.white60 : Colors.white30,
                      fontWeight:
                          unread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
