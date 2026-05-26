import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TypeServiceDomestique { menagere, servante, serveuse }

({
  String label,
  IconData icon,
  Color color,
  List<String> prestations,
}) infoServiceDomestique(TypeServiceDomestique t) => switch (t) {
      TypeServiceDomestique.menagere => (
        label: 'Femme de ménage',
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFF8B5CF6),
        prestations: const ['Résidente', 'Journalière', 'Ponctuelle'],
      ),
      TypeServiceDomestique.servante => (
        label: 'Servante de maison',
        icon: Icons.home_rounded,
        color: const Color(0xFF0EA5E9),
        prestations: const ['Temps plein', 'Résidente'],
      ),
      TypeServiceDomestique.serveuse => (
        label: 'Serveuse de bar',
        icon: Icons.local_bar_rounded,
        color: const Color(0xFFEC4899),
        prestations: const ['Temps plein', 'Temps partiel', 'Événementiel'],
      ),
    };

class DemandServiceDomestiquePage extends StatefulWidget {
  final Color accentColor;

  const DemandServiceDomestiquePage({super.key, required this.accentColor});

  @override
  State<DemandServiceDomestiquePage> createState() =>
      _DemandServiceDomestiquePageState();
}

class _DemandServiceDomestiquePageState
    extends State<DemandServiceDomestiquePage> {
  final _supabase = Supabase.instance.client;

  int _step = 0;
  TypeServiceDomestique? _type;
  String? _prestation;

  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    _communeCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await _supabase
          .from('utilisateurs')
          .select('nom_complet, telephone, ville, commune')
          .eq('id', uid)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _nomCtrl.text = data['nom_complet'] ?? '';
          _telCtrl.text = data['telephone'] ?? '';
          _villeCtrl.text = data['ville'] ?? '';
          _communeCtrl.text = data['commune'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty || _type == null) return;
    setState(() => _submitting = true);
    try {
      await _supabase.from('demandes_service_domestique').insert({
        'demandeur_id': _supabase.auth.currentUser!.id,
        'type_service': _type!.name,
        'type_prestation': _prestation,
        'nom_demandeur': _nomCtrl.text.trim(),
        'telephone_demandeur': _telCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        'commune': _communeCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'date_souhaitee': _dateCtrl.text.trim(),
        'statut': 'en_attente_validation',
      });
    } catch (e) {
      debugPrint('Demande domestique: $e');
    } finally {
      if (mounted) setState(() { _submitting = false; _step = 2; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _type != null ? infoServiceDomestique(_type!) : null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        leading: _step == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    setState(() { _type = null; _prestation = null; _step = 0; }),
              )
            : null,
        title: Text(
          _step == 0
              ? 'Services domestiques'
              : _step == 1
                  ? (info?.label ?? '')
                  : 'Confirmation',
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
        ),
        actions: [
          if (_step < 2)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _step == 0
            ? _buildTypeSelection()
            : _step == 1
                ? _buildForm(info!)
                : _buildConfirmation(),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_user_rounded,
                color: Color(0xFF22C55E), size: 16),
            const SizedBox(width: 8),
            Text('Service encadré — Validation humaine',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF22C55E))),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Quel service recherchez-vous ?',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(
          "Ces prestations font l'objet d'une vérification rigoureuse de notre équipe avant toute mise en relation.",
          style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
        ),
        const SizedBox(height: 24),
        ...TypeServiceDomestique.values.map((t) => _DomesticTypeCard(
              type: t,
              onTap: () =>
                  setState(() { _type = t; _prestation = null; _step = 1; }),
            )),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.shield_rounded,
                color: Color(0xFF3B82F6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pourquoi un processus spécial ?',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(
                      'Ces profils accèdent à votre domicile. FormelPro effectue une vérification d\'identité et une enquête de moralité avant toute mise en relation.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.5),
                    ),
                  ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildForm(
      ({String label, IconData icon, Color color, List<String> prestations})
          info) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Type de contrat',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: info.prestations.map((p) {
            final sel = _prestation == p;
            return GestureDetector(
              onTap: () => setState(() => _prestation = p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? info.color : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? info.color : const Color(0xFFE2E8F0)),
                ),
                child: Text(p,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF64748B))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _field(_nomCtrl, 'Nom complet *', Icons.person_rounded),
        const SizedBox(height: 12),
        _field(_telCtrl, 'Téléphone *', Icons.phone_rounded,
            keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _field(_villeCtrl, 'Ville', Icons.location_city_rounded)),
          const SizedBox(width: 10),
          Expanded(
              child: _field(_communeCtrl, 'Commune', Icons.map_rounded)),
        ]),
        const SizedBox(height: 12),
        _field(_dateCtrl, 'Date de début souhaitée',
            Icons.calendar_today_rounded),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: _deco(
              'Description (logement, horaires, tâches...)', Icons.notes_rounded),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            const Icon(Icons.shield_rounded,
                color: Color(0xFF3B82F6), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vos données sont protégées. Aucun contact direct avant validation par notre équipe.',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF3B82F6),
                    height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_nomCtrl.text.trim().isEmpty || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: info.color,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Envoyer ma demande',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _buildConfirmation() {
    return Center(
      key: const ValueKey(2),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Demande enregistrée',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Merci.\nVotre demande a bien été enregistrée.\nNotre équipe vous recontactera après vérification et étude de votre besoin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  height: 1.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _badge(Icons.verified_user_rounded, 'Enquête effectuée',
                const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _badge(Icons.people_rounded, 'Sélection humaine',
                const Color(0xFF8B5CF6)),
          ]),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("Retour à l'accueil",
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        keyboardType: keyboard,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: _deco(hint, icon),
      );

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: widget.accentColor),
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );

  Widget _badge(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ── Carte type de service ──────────────────────────────────────────────────────

class _DomesticTypeCard extends StatelessWidget {
  final TypeServiceDomestique type;
  final VoidCallback onTap;

  const _DomesticTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = infoServiceDomestique(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: info.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.label,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A))),
                      Text(info.prestations.join(' · '),
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B))),
                    ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: info.color.withValues(alpha: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
