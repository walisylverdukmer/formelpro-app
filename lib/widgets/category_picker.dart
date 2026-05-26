import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryPicker extends StatefulWidget {
  final Color accentColor;
  final Function(String jobName, String? categoryId) onChanged;

  const CategoryPicker({
    super.key,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _selectedId;
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _customController.dispose();
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
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('CategoryPicker: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectCategory(String id, String nom) {
    setState(() {
      _selectedId = _selectedId == id ? null : id;
      _isCustom = false;
    });
    widget.onChanged(_selectedId == null ? '' : nom, _selectedId);
  }

  void _toggleCustom() {
    setState(() {
      _isCustom = !_isCustom;
      _selectedId = null;
    });
    if (!_isCustom) widget.onChanged('', null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Votre métier principal",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Sélectionnez dans la liste ou saisissez librement.",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 12),
        if (_loading)
          _buildLoading()
        else
          _buildChips(),
        if (_isCustom) ...[
          const SizedBox(height: 14),
          _buildCustomField(),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        6,
        (_) => Container(
          width: 90,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._categories.map(
          (cat) => _buildChip(
            cat['id'].toString(),
            cat['nom'].toString(),
          ),
        ),
        _buildCustomChip(),
      ],
    );
  }

  Widget _buildChip(String id, String label) {
    final bool selected = _selectedId == id;
    return GestureDetector(
      onTap: () => _selectCategory(id, label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? widget.accentColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? widget.accentColor
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    return GestureDetector(
      onTap: _toggleCustom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isCustom ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isCustom
                ? const Color(0xFF1E293B)
                : const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_rounded,
              size: 13,
              color: _isCustom ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              "Autre / Préciser",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isCustom ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _customController,
        autofocus: true,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Ex: Réparateur VRV, Soudeur inox, Technicien solaire...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            Icons.work_outline_rounded,
            color: widget.accentColor,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 4,
          ),
        ),
        onChanged: (val) => widget.onChanged(val.trim(), null),
      ),
    );
  }
}
