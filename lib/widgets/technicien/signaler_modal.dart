import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignalerModal extends StatefulWidget {
  final String techId;
  final String signalerParId;
  final Color accentColor;

  const SignalerModal({
    super.key,
    required this.techId,
    required this.signalerParId,
    required this.accentColor,
  });

  @override
  State<SignalerModal> createState() => _SignalerModalState();
}

class _SignalerModalState extends State<SignalerModal> {
  static const _raisons = [
    "Comportement inapproprié",
    "Fausse identité / faux profil",
    "Arnaque ou fraude",
    "Harcèlement",
    "Qualité de travail dangereuse",
    "Autre",
  ];

  String? _raisonSelectionnee;
  final _autreController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_raisonSelectionnee == null) return;
    final raison =
        _raisonSelectionnee == "Autre" && _autreController.text.trim().isNotEmpty
            ? _autreController.text.trim()
            : _raisonSelectionnee!;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.from('signalements').insert({
        'signale_par': widget.signalerParId,
        'utilisateur_signale': widget.techId,
        'raison': raison,
        'statut': 'en_attente',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Signalement envoyé. Notre équipe l'examinera sous 48h.",
              style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Row(children: [
            const Icon(Icons.flag_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Text("Signaler ce prestataire",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(
            "Votre signalement est confidentiel et sera traité par notre équipe.",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._raisons.map((r) => _buildRaisonTile(r)),
          if (_raisonSelectionnee == "Autre") ...[
            const SizedBox(height: 8),
            TextField(
              controller: _autreController,
              style: GoogleFonts.inter(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Décrivez le problème...",
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _raisonSelectionnee == null || _loading ? null : _envoyer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text("Envoyer le signalement",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaisonTile(String raison) {
    final selected = _raisonSelectionnee == raison;
    return GestureDetector(
      onTap: () => setState(() => _raisonSelectionnee = raison),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.red.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? Colors.red : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(raison,
              style: GoogleFonts.inter(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}
