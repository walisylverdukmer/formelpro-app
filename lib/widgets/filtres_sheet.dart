import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'filtres_techniciens.dart';

class FiltresSheet extends StatefulWidget {
  final Color accentColor;
  final FiltresTechniciens current;

  const FiltresSheet({
    super.key,
    required this.accentColor,
    required this.current,
  });

  @override
  State<FiltresSheet> createState() => _FiltresSheetState();
}

class _FiltresSheetState extends State<FiltresSheet> {
  late bool _disponibleSeulement;
  late double _noteMin;
  String? _categorieId;
  String? _categorieNom;
  String? _typePrestation;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCats = true;
  final _communeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _disponibleSeulement = widget.current.disponibleSeulement;
    _noteMin = widget.current.noteMin;
    _categorieId = widget.current.categorieId;
    _categorieNom = widget.current.categorieNom;
    _typePrestation = widget.current.typePrestation;
    _communeCtrl.text = widget.current.commune ?? '';
    _loadCategories();
  }

  @override
  void dispose() {
    _communeCtrl.dispose();
    super.dispose();
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
                  color: Colors.white),
            ),
            const SizedBox(height: 24),

            // ── Disponibilité ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Disponibles uniquement',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white70)),
                Switch(
                  value: _disponibleSeulement,
                  onChanged: (v) =>
                      setState(() => _disponibleSeulement = v),
                  activeThumbColor: widget.accentColor,
                  activeTrackColor:
                      widget.accentColor.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Note minimum ──────────────────────────────────────────────
            Text(
              _noteMin == 0
                  ? 'Note minimum : Toutes'
                  : 'Note minimum : ${_noteMin.toStringAsFixed(1)} ★',
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.white70),
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

            // ── Catégorie ─────────────────────────────────────────────────
            _sectionLabel('Catégorie'),
            const SizedBox(height: 12),
            _loadingCats
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white54),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCatChip(null, 'Toutes'),
                      ..._categories.map((c) => _buildCatChip(
                          c['id'].toString(), c['nom'].toString())),
                    ],
                  ),
            const SizedBox(height: 20),

            // ── Localisation ──────────────────────────────────────────────
            _sectionLabel('Commune / Zone'),
            const SizedBox(height: 10),
            TextField(
              controller: _communeCtrl,
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex : Cocody, Akwa, Bastos...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white38),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: Colors.white38, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color:
                          widget.accentColor.withValues(alpha: 0.6)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // ── Type de mission ───────────────────────────────────────────
            _sectionLabel('Type de mission'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip(null, 'Tous types'),
                _buildTypeChip('ponctuelle', 'Ponctuel'),
                _buildTypeChip('journalière', 'Journalier'),
                _buildTypeChip('résidente', 'Résidentiel'),
              ],
            ),
            const SizedBox(height: 28),

            // ── Boutons ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                        context, const FiltresTechniciens()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Réinitialiser',
                        style: GoogleFonts.inter()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final commune = _communeCtrl.text.trim();
                      Navigator.pop(
                        context,
                        FiltresTechniciens(
                          disponibleSeulement: _disponibleSeulement,
                          noteMin: _noteMin,
                          categorieId: _categorieId,
                          categorieNom: _categorieNom,
                          commune: commune.isEmpty ? null : commune,
                          typePrestation: _typePrestation,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Appliquer',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 0.5),
      );

  Widget _buildCatChip(String? id, String label) {
    final bool sel = _categorieId == id;
    return GestureDetector(
      onTap: () => setState(() {
        _categorieId = id;
        _categorieNom = id == null ? null : label;
      }),
      child: _chip(label, sel),
    );
  }

  Widget _buildTypeChip(String? value, String label) {
    final bool sel = _typePrestation == value;
    return GestureDetector(
      onTap: () => setState(() => _typePrestation = value),
      child: _chip(label, sel),
    );
  }

  Widget _chip(String label, bool selected) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      );
}
