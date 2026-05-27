import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showSecurityConfirmDialog(
  BuildContext context, {
  required String content,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.shield_rounded,
            color: Color(0xFF3B82F6), size: 22),
        const SizedBox(width: 10),
        Text('Votre sécurité',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: Text(
        'Pour votre sécurité, effectuez toujours le paiement et la '
        'validation directement dans FormelPro.\n\n'
        'Les paiements hors application ne sont pas couverts.',
        style: GoogleFonts.inter(
            fontSize: 13, height: 1.5, color: const Color(0xFF334155)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('Confirmer',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
