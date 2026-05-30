import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final VoidCallback onSend;
  final VoidCallback onProforma;
  final VoidCallback onImage;
  final VoidCallback onMic;
  final ValueChanged<String>? onChanged;
  final bool uploadingImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.accentColor,
    required this.onSend,
    required this.onProforma,
    required this.onImage,
    required this.onMic,
    this.onChanged,
    this.uploadingImage = false,
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
          _buildActionButton(
              icon: Icons.add_circle_rounded,
              label: 'Proforma',
              onTap: onProforma),
          const SizedBox(width: 6),
          _buildActionButton(
              icon: Icons.image_rounded,
              label: 'Photo',
              onTap: uploadingImage ? null : onImage),
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
                onChanged: onChanged,
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (uploadingImage) {
                return const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final hasText = value.text.trim().isNotEmpty;
              return CircleAvatar(
                backgroundColor: accentColor,
                radius: 22,
                child: IconButton(
                  icon: Icon(
                    hasText
                        ? Icons.send_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: hasText ? onSend : onMic,
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final color =
        onTap != null ? accentColor : accentColor.withValues(alpha: 0.4);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Icon(icon, color: color, size: 32),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
