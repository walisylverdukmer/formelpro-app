import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../location_picker_widget.dart';

class ProformaSheet extends StatefulWidget {
  final Color accentColor;
  final Future<void> Function({
    required String service,
    required String prix,
    required String lieu,
    required String date,
  }) onSend;

  const ProformaSheet({
    super.key,
    required this.accentColor,
    required this.onSend,
  });

  @override
  State<ProformaSheet> createState() => _ProformaSheetState();
}

class _ProformaSheetState extends State<ProformaSheet> {
  final _serviceCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _prixCtrl.dispose();
    _lieuCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_serviceCtrl.text.trim().isEmpty || _prixCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSend(
        service: _serviceCtrl.text.trim(),
        prix: _prixCtrl.text.trim(),
        lieu: _lieuCtrl.text.trim(),
        date: _dateCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2)),
        ),
        Row(children: [
          Icon(Icons.description_rounded, color: widget.accentColor),
          const SizedBox(width: 10),
          Text(
            'Créer une proposition',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A)),
          ),
        ]),
        const SizedBox(height: 20),
        _field(_serviceCtrl, 'Type de service *', Icons.build_rounded),
        const SizedBox(height: 12),
        _field(_prixCtrl, 'Montant convenu (FCFA) *', Icons.payments_rounded,
            keyboard: TextInputType.number),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => LocationPickerWidget(
                    accentColor: widget.accentColor, paysCode: 'CIV'),
              ),
            );
            if (result != null && mounted) {
              final parts =
                  [result['ville'], result['commune'], result['quartier']]
                      .where((s) => s != null && (s as String).isNotEmpty)
                      .join(', ');
              setState(() => _lieuCtrl.text = parts);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(Icons.map_rounded, color: widget.accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _lieuCtrl.text.isEmpty
                      ? "Lieu d'intervention (optionnel)"
                      : _lieuCtrl.text,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _lieuCtrl.text.isEmpty
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        _field(_dateCtrl, 'Date / heure prévue (optionnel)',
            Icons.calendar_today_rounded),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    'Envoyer la proposition',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: widget.accentColor, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.accentColor)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
