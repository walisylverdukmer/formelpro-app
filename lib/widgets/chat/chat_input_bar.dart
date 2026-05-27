import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final VoidCallback onSend;
  final VoidCallback onProforma;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onSend,
    required this.onProforma,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(children: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.add_circle_rounded,
                  color: accentColor, size: 32),
              onPressed: onProforma,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              'Proforma',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: accentColor),
            ),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  hintStyle:
                      GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: accentColor,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: onSend,
            ),
          ),
        ]),
      ),
    );
  }
}
