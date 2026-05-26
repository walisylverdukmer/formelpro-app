import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/location_picker_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverName;
  final String receiverId;
  final Color accentColor;
  final String? receiverPhone;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
    required this.receiverId,
    required this.accentColor,
    this.receiverPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  late StreamSubscription<List<Map<String, dynamic>>> _msgSub;

  bool get _hasProforma =>
      _messages.any((m) => m['est_proposition_intervention'] == true);
  bool get _callUnlocked => _messages.length >= 3 || _hasProforma;

  @override
  void initState() {
    super.initState();
    _msgSub = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('cree_le', ascending: false)
        .listen((msgs) {
      if (mounted) setState(() => _messages = msgs);
    });
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;
    _msgCtrl.clear();
    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': _supabase.auth.currentUser!.id,
        'contenu': content,
        'est_proposition_intervention': false,
      });
      await _supabase.from('conversations').update({
        'dernier_message': content,
        'mis_a_jour_le': DateTime.now().toIso8601String(),
      }).eq('id', widget.conversationId);
    } catch (e) {
      debugPrint('Erreur envoi: $e');
    }
  }

  Future<void> _sendProforma({
    required String service,
    required String prix,
    required String lieu,
    required String date,
  }) async {
    if (prix.isEmpty || service.isEmpty) return;
    final text = '📋 PROPOSITION DE PRESTATION\n'
        '🔧 Service : $service\n'
        '💰 Montant : $prix FCFA\n'
        '📍 Lieu : ${lieu.isEmpty ? 'À confirmer' : lieu}\n'
        '📅 Date : ${date.isEmpty ? 'À convenir' : date}';
    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': _supabase.auth.currentUser!.id,
        'contenu': text,
        'est_proposition_intervention': true,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur proforma: $e');
    }
  }

  void _showSecurityDialog(String msgId, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 22),
          const SizedBox(width: 10),
          Text('Votre sécurité',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Pour votre sécurité, effectuez toujours le paiement et la validation directement dans FormelPro.\n\n'
          'Les paiements effectués en dehors de l\'application ne sont pas couverts par FormelPro.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmIntervention(content);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Confirmer',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmIntervention(String content) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _supabase.from('interventions').insert({
        'client_id': uid,
        'tech_id': widget.receiverId,
        'titre_service': 'Accord via messagerie',
        'statut': 'en_attente',
        'description': content,
        'date_prevue':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': uid,
        'contenu': "✅ OFFRE ACCEPTÉE. L'intervention est officiellement enregistrée.",
        'est_proposition_intervention': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Intervention confirmée !', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.message}', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      debugPrint('Erreur confirmation: $e');
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _showCallLocked() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Échangez d\'abord quelques messages ou proposez une prestation pour débloquer l\'appel.',
        style: GoogleFonts.inter(),
      ),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showProformaDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProformaSheet(
        accentColor: widget.accentColor,
        onSend: _sendProforma,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneAvail =
        widget.receiverPhone != null && widget.receiverPhone!.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(children: [
          CircleAvatar(
            backgroundColor: widget.accentColor.withValues(alpha: 0.1),
            child: Text(
              widget.receiverName.isNotEmpty ? widget.receiverName[0] : '?',
              style: TextStyle(color: widget.accentColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.receiverName,
                  style: GoogleFonts.poppins(
                      color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text('Conversation sécurisée',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        actions: [
          if (phoneAvail)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: _callUnlocked
                    ? 'Appeler ${widget.receiverName}'
                    : 'Échangez d\'abord 3 messages ou proposez une prestation',
                child: IconButton(
                  icon: Icon(
                    _callUnlocked
                        ? Icons.phone_rounded
                        : Icons.phone_locked_rounded,
                    color: _callUnlocked
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                  ),
                  onPressed:
                      _callUnlocked ? () => _makeCall(widget.receiverPhone!) : _showCallLocked,
                ),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        _buildMessageInput(),
      ]),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 52, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 14),
          Text('Démarrez la conversation',
              style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Échangez avant de convenir d\'une prestation',
              style: GoogleFonts.inter(
                  color: const Color(0xFFCBD5E1), fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg['expediteur_id'] == _supabase.auth.currentUser?.id;
        if (msg['est_proposition_intervention'] == true) {
          return _buildProformaCard(msg, isMe);
        }
        return _buildBubble((msg['contenu'] as String?) ?? '', isMe);
      },
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? widget.accentColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)
          ],
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
      ),
    );
  }

  Widget _buildProformaCard(Map<String, dynamic> msg, bool isMe) {
    final lines = (msg['contenu'] as String? ?? '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.startsWith('📋'))
        .toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.description_rounded, color: widget.accentColor, size: 20),
          const SizedBox(width: 8),
          Text('PROPOSITION DE PRESTATION',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: widget.accentColor,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        ...lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(line,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: const Color(0xFF334155))),
              ),
            )),
        const SizedBox(height: 10),
        if (!isMe) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Validez toujours dans FormelPro. Les paiements hors application ne sont pas couverts.',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF3B82F6),
                      height: 1.4),
                ),
              ),
            ]),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSecurityDialog(msg['id'] as String, msg['contenu'] as String),
              icon: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              label: Text("Accepter l'offre",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'En attente de confirmation du client...',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: widget.accentColor),
            ),
          ),
      ]),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(children: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.add_circle_rounded,
                  color: widget.accentColor, size: 32),
              onPressed: _showProformaDialog,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text('Proforma',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor)),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  hintStyle:
                      GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: widget.accentColor,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Bottom Sheet Proforma ──────────────────────────────────────────────────────

class _ProformaSheet extends StatefulWidget {
  final Color accentColor;
  final Future<void> Function({
    required String service,
    required String prix,
    required String lieu,
    required String date,
  }) onSend;

  const _ProformaSheet({required this.accentColor, required this.onSend});

  @override
  State<_ProformaSheet> createState() => _ProformaSheetState();
}

class _ProformaSheetState extends State<_ProformaSheet> {
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
    if (_serviceCtrl.text.trim().isEmpty || _prixCtrl.text.trim().isEmpty) return;
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
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
        Row(children: [
          Icon(Icons.description_rounded, color: widget.accentColor),
          const SizedBox(width: 10),
          Text('Créer une proposition',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
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
              final parts = [result['ville'], result['commune'], result['quartier']]
                  .where((s) => s != null && (s as String).isNotEmpty)
                  .join(', ');
              setState(() => _lieuCtrl.text = parts);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        _field(_dateCtrl, 'Date / heure prévue (optionnel)', Icons.calendar_today_rounded),
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
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Envoyer la proposition',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
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
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8), fontSize: 13),
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
