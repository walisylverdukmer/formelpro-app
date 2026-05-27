import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaiementPage extends StatefulWidget {
  final Map<String, dynamic> intervention;
  final Map<String, dynamic> userData;

  const PaiementPage({
    super.key,
    required this.intervention,
    required this.userData,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  final _supabase = Supabase.instance.client;
  final _referenceController = TextEditingController();
  String? _operateurSelectionne;
  bool _loading = false;

  static const _operateursCIV = [
    {'id': 'orange_money', 'nom': 'Orange Money', 'code': '#144#'},
    {'id': 'wave', 'nom': 'Wave', 'code': 'Application Wave'},
    {'id': 'mtn_momo', 'nom': 'MTN MoMo', 'code': '*133#'},
  ];

  static const _operateursCMR = [
    {'id': 'mtn_momo', 'nom': 'MTN Mobile Money', 'code': '*126#'},
    {'id': 'orange_money', 'nom': 'Orange Money', 'code': '*150#'},
  ];

  List<Map<String, String>> get _operateurs {
    final pays = widget.userData['pays'] ?? 'CIV';
    final list = pays == 'CMR' ? _operateursCMR : _operateursCIV;
    return list.map((e) => Map<String, String>.from(e)).toList();
  }

  Color get _accentColor => (widget.userData['pays'] ?? 'CIV') == 'CIV'
      ? const Color(0xFFE67E22)
      : const Color(0xFFCE1126);

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _confirmerPaiement() async {
    if (_operateurSelectionne == null) {
      _showSnack("Sélectionnez un opérateur de paiement");
      return;
    }
    final ref = _referenceController.text.trim();
    if (ref.isEmpty) {
      _showSnack("Entrez votre référence de transaction");
      return;
    }
    if (ref.length < 4) {
      _showSnack("Référence invalide (minimum 4 caractères)");
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = _supabase.auth.currentUser!.id;
      final interventionId = widget.intervention['id'].toString();
      final techId = widget.intervention['tech_id'].toString();
      final montant = (widget.intervention['montant_final'] ?? 0) as int;
      final pays = widget.userData['pays'] ?? 'CIV';
      final nomOp = _operateurs.firstWhere(
        (o) => o['id'] == _operateurSelectionne,
        orElse: () => {'nom': _operateurSelectionne!},
      )['nom']!;
      final titreService = widget.intervention['titre_service'] ?? 'intervention';

      await _supabase.from('transactions').insert({
        'intervention_id': interventionId,
        'client_id': uid,
        'tech_id': techId,
        'montant': montant,
        'operateur': _operateurSelectionne,
        'statut': 'en_attente',
        'reference_externe': ref,
        'pays': pays,
      });

      await _supabase.from('notifications').insert({
        'user_id': techId,
        'titre': 'Paiement déclaré',
        'message':
            'Un paiement de $montant FCFA via $nomOp a été déclaré pour "$titreService". '
            'Confirmez la réception dans vos interventions.',
        'type': 'paiement',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Paiement déclaré. En attente de confirmation du technicien.",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack("Erreur inattendue");
      debugPrint("Erreur paiement: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final montant = (widget.intervention['montant_final'] ?? 0) as int;
    final titre = widget.intervention['titre_service'] ?? 'Intervention';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Paiement Mobile Money",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSummaryCard(titre, montant),
            const SizedBox(height: 28),
            _buildOperateurSection(),
            if (_operateurSelectionne != null) ...[
              const SizedBox(height: 24),
              _buildInstructionsSection(montant),
              const SizedBox(height: 24),
              _buildReferenceField(),
            ],
            const SizedBox(height: 32),
            _buildConfirmButton(montant),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String titre, int montant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INTERVENTION",
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            titre,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Montant à régler",
                style:
                    GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
              Text(
                "$montant FCFA",
                style: GoogleFonts.poppins(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperateurSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Opérateur de paiement",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ..._operateurs.map(_buildOperateurTile),
      ],
    );
  }

  Widget _buildOperateurTile(Map<String, String> op) {
    final selected = _operateurSelectionne == op['id'];
    return GestureDetector(
      onTap: () => setState(() => _operateurSelectionne = op['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _accentColor.withValues(alpha: 0.12)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _accentColor
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? _accentColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.phone_android,
                color: selected ? _accentColor : Colors.white38,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    op['nom']!,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                  Text(
                    "Code : ${op['code']!}",
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected ? _accentColor : Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(int montant) {
    final op = _operateurs.firstWhere(
      (o) => o['id'] == _operateurSelectionne,
      orElse: () => {'code': ''},
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                "Comment payer",
                style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep("1", "Composez ${op['code']} sur votre téléphone"),
          _buildStep("2", "Envoyez $montant FCFA au numéro FormelPro"),
          _buildStep("3", "Notez la référence de la transaction"),
          _buildStep("4", "Entrez-la ci-dessous et confirmez"),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.inter(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Référence de transaction",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _referenceController,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: "Ex : TXN123456789",
            hintStyle: GoogleFonts.inter(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accentColor),
            ),
            prefixIcon:
                const Icon(Icons.tag, color: Colors.white38, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(int montant) {
    final enabled = _operateurSelectionne != null && !_loading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _confirmerPaiement : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                "Confirmer le paiement — $montant FCFA",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
      ),
    );
  }
}
