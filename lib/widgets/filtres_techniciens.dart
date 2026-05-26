import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FiltresTechniciens {
  final bool disponibleSeulement;
  final double noteMin;
  final String? categorieId;
  final String? categorieNom;
  final String? commune;
  final String? quartier;
  final String? typePrestation; // ex: 'résidente', 'journalière', 'ponctuelle'

  const FiltresTechniciens({
    this.disponibleSeulement = false,
    this.noteMin = 0.0,
    this.categorieId,
    this.categorieNom,
    this.commune,
    this.quartier,
    this.typePrestation,
  });

  bool get actif =>
      disponibleSeulement ||
      noteMin > 0 ||
      categorieId != null ||
      categorieNom != null ||
      commune != null ||
      quartier != null ||
      typePrestation != null;

  int get count =>
      (disponibleSeulement ? 1 : 0) +
      (noteMin > 0 ? 1 : 0) +
      (categorieId != null || categorieNom != null ? 1 : 0) +
      (commune != null ? 1 : 0) +
      (typePrestation != null ? 1 : 0);

  FiltresTechniciens copyWith({
    bool? disponibleSeulement,
    double? noteMin,
    String? categorieId,
    String? categorieNom,
    String? commune,
    String? quartier,
    String? typePrestation,
  }) {
    return FiltresTechniciens(
      disponibleSeulement: disponibleSeulement ?? this.disponibleSeulement,
      noteMin: noteMin ?? this.noteMin,
      categorieId: categorieId ?? this.categorieId,
      categorieNom: categorieNom ?? this.categorieNom,
      commune: commune ?? this.commune,
      quartier: quartier ?? this.quartier,
      typePrestation: typePrestation ?? this.typePrestation,
    );
  }
}

Future<FiltresTechniciens?> showFiltresSheet(
  BuildContext context,
  Color accentColor,
  FiltresTechniciens filtres,
) {
  return showModalBottomSheet<FiltresTechniciens>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FiltresSheet(accentColor: accentColor, current: filtres),
  );
}

class _FiltresSheet extends StatefulWidget {
  final Color accentColor;
  final FiltresTechniciens current;
  const _FiltresSheet({required this.accentColor, required this.current});
  @override
  State<_FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<_FiltresSheet> {
  late bool _disponibleSeulement;
  late double _noteMin;
  String? _categorieId;
  String? _categorieNom;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _disponibleSeulement = widget.current.disponibleSeulement;
    _noteMin = widget.current.noteMin;
    _categorieId = widget.current.categorieId;
    _categorieNom = widget.current.categorieNom;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await Supabase.instance.client
          .from('categories_services')
          .select('id, nom')
          .eq('est_valide', true)
          .order('ordre_affichage')
          .limit(20);
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(cats);
          _loadingCats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
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
      child: SingleChildScrollView(
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
              'Filtres',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disponibles uniquement',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
                Switch(
                  value: _disponibleSeulement,
                  onChanged: (v) => setState(() => _disponibleSeulement = v),
                  activeThumbColor: widget.accentColor,
                  activeTrackColor: widget.accentColor.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _noteMin == 0
                  ? 'Note minimum : Toutes'
                  : 'Note minimum : ${_noteMin.toStringAsFixed(1)} ★',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            Slider(
              value: _noteMin,
              min: 0,
              max: 5,
              divisions: 10,
              activeColor: widget.accentColor,
              inactiveColor: Colors.white12,
              onChanged: (v) => setState(() => _noteMin = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Catégorie',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _loadingCats
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(null, 'Toutes'),
                      ..._categories.map(
                        (c) => _buildChip(c['id'].toString(), c['nom'].toString()),
                      ),
                    ],
                  ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const FiltresTechniciens()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Réinitialiser', style: GoogleFonts.inter()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      FiltresTechniciens(
                        disponibleSeulement: _disponibleSeulement,
                        noteMin: _noteMin,
                        categorieId: _categorieId,
                        categorieNom: _categorieNom,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Appliquer',
                      style:
                          GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String? id, String label) {
    final bool selected = _categorieId == id;
    return GestureDetector(
      onTap: () => setState(() {
        _categorieId = id;
        _categorieNom = id == null ? null : label;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? widget.accentColor
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? widget.accentColor
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
