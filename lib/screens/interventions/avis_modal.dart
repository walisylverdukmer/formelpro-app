import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvisModal extends StatefulWidget {
  final String interventionId;
  final String techId;
  final String titreService;
  final Color accentColor;
  final VoidCallback onAvisDepose;

  const AvisModal({
    super.key,
    required this.interventionId,
    required this.techId,
    required this.titreService,
    required this.accentColor,
    required this.onAvisDepose,
  });

  @override
  State<AvisModal> createState() => _AvisModalState();
}

class _AvisModalState extends State<AvisModal> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _commentaireController = TextEditingController();
  int _note = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (_note == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sélectionnez une note entre 1 et 5 étoiles", style: GoogleFonts.inter()),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clientId = _supabase.auth.currentUser!.id;

      await _supabase.from('avis').insert({
        'intervention_id': widget.interventionId,
        'client_id': clientId,
        'tech_id': widget.techId,
        'note': _note,
        'commentaire': _commentaireController.text.trim().isEmpty
            ? null
            : _commentaireController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onAvisDepose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Merci pour votre avis !", style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de drag
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Évaluer l'intervention",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.titreService,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Sélecteur d'étoiles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _note = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    star <= _note ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: star <= _note ? widget.accentColor : Colors.white24,
                    size: 46,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _note == 0 ? "Appuyez pour noter" : _getNoteLabel(_note),
              key: ValueKey(_note),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _note == 0 ? Colors.white38 : widget.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Champ commentaire
          TextField(
            controller: _commentaireController,
            maxLines: 3,
            maxLength: 300,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Commentaire (optionnel)...",
              hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              counterStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _soumettre,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.accentColor.withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "Envoyer mon avis",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNoteLabel(int note) {
    switch (note) {
      case 1: return "Très insatisfait";
      case 2: return "Insatisfait";
      case 3: return "Correct";
      case 4: return "Satisfait";
      case 5: return "Excellent !";
      default: return "";
    }
  }
}
