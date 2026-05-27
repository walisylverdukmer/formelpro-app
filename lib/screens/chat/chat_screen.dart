import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/proforma_card.dart';
import '../../widgets/chat/proforma_sheet.dart';

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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.shield_rounded,
              color: Color(0xFF3B82F6), size: 22),
          const SizedBox(width: 10),
          Text('Votre sécurité',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Pour votre sécurité, effectuez toujours le paiement et la validation directement dans FormelPro.\n\n'
          'Les paiements effectués en dehors de l\'application ne sont pas couverts par FormelPro.',
          style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmIntervention(content);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Confirmer',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
        'contenu':
            "✅ OFFRE ACCEPTÉE. L'intervention est officiellement enregistrée.",
        'est_proposition_intervention': false,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Intervention confirmée !', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Erreur : ${e.message}', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showProformaDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProformaSheet(
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
              widget.receiverName.isNotEmpty
                  ? widget.receiverName[0]
                  : '?',
              style: TextStyle(color: widget.accentColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName,
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
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
                  onPressed: _callUnlocked
                      ? () => _makeCall(widget.receiverPhone!)
                      : _showCallLocked,
                ),
              ),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        ChatInputBar(
          controller: _msgCtrl,
          accentColor: widget.accentColor,
          onSend: _sendMessage,
          onProforma: _showProformaDialog,
        ),
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
        final isMe =
            msg['expediteur_id'] == _supabase.auth.currentUser?.id;
        if (msg['est_proposition_intervention'] == true) {
          return ProformaCard(
            msg: msg,
            isMe: isMe,
            accentColor: widget.accentColor,
            onAccept: _showSecurityDialog,
          );
        }
        return ChatBubble(
          text: (msg['contenu'] as String?) ?? '',
          isMe: isMe,
          accentColor: widget.accentColor,
        );
      },
    );
  }
}
