import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'filtres_techniciens.dart'; // kCompetences

class CompetencesEditorSheet extends StatefulWidget {
  final List<String> current;
  final Color accentColor;

  const CompetencesEditorSheet({
    super.key,
    required this.current,
    required this.accentColor,
  });

  @override
  State<CompetencesEditorSheet> createState() =>
      _CompetencesEditorSheetState();
}

class _CompetencesEditorSheetState extends State<CompetencesEditorSheet> {
  final _supabase = Supabase.instance.client;
  late List<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.current);
  }

  Future<void> _sauvegarder() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _supabase
          .from('utilisateurs')
          .update({'competences': _selected})
          .eq('id', uid);
      if (mounted) Navigator.pop(context, List<String>.from(_selected));
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message, style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde compétences: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Mes Compétences',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Sélectionnez vos savoir-faire pour apparaître dans les recherches spécialisées.',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white54, height: 1.5),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: kCompetences.map((c) {
                  final sel = _selected.contains(c);
                  return GestureDetector(
                    onTap: () => setState(() {
                      sel ? _selected.remove(c) : _selected.add(c);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel
                            ? widget.accentColor
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel
                              ? widget.accentColor
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[
                            const Icon(Icons.check, size: 13,
                                color: Colors.white),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            c,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _sauvegarder,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    widget.accentColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selected.isEmpty
                          ? 'Effacer les compétences'
                          : 'Sauvegarder (${_selected.length})',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
