import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/chat_actions.dart';
import '../../widgets/chat/audio_recording_bar.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/chat_message_list.dart';
import '../../widgets/chat/chat_security_banner.dart';
import '../../widgets/chat/proforma_sheet.dart';
import '../../widgets/chat/security_confirm_dialog.dart';

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
  late final RealtimeChannel _typingChannel;
  late final ChatActions _actions;
  Timer? _typingTimer;
  bool _receiverTyping = false;
  bool _showBanner = true;
  bool _uploadingImage = false;
  bool _isRecording = false;

  bool get _hasProforma =>
      _messages.any((m) => m['est_proposition_intervention'] == true);
  bool get _callUnlocked => _messages.length >= 3 || _hasProforma;

  @override
  void initState() {
    super.initState();
    _actions = ChatActions(
      conversationId: widget.conversationId,
      receiverId: widget.receiverId,
    );
    _msgSub = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('cree_le', ascending: false)
        .limit(100)
        .listen((msgs) {
      if (mounted) setState(() => _messages = msgs);
      final uid = _supabase.auth.currentUser?.id;
      if (uid != null &&
          msgs.any((m) => m['expediteur_id'] != uid && m['est_lu'] == false)) {
        _actions.markMessagesRead();
      }
    });
    _initTypingChannel();
  }

  void _initTypingChannel() {
    final uid = _supabase.auth.currentUser?.id ?? '';
    _typingChannel = _supabase.channel('chat_typing:${widget.conversationId}')
      ..onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (payload['user_id'] == uid) return;
            final isTyping = payload['typing'] == true;
            _typingTimer?.cancel();
            if (mounted) setState(() => _receiverTyping = isTyping);
            if (isTyping) {
              _typingTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _receiverTyping = false);
              });
            }
          })
      ..subscribe();
  }

  @override
  void dispose() {
    _msgSub.cancel();
    _typingChannel.unsubscribe();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _onTypingChanged(String text) {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _typingTimer?.cancel();
    _typingChannel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': uid, 'typing': text.isNotEmpty});
    if (text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _typingChannel.sendBroadcastMessage(
            event: 'typing', payload: {'user_id': uid, 'typing': false});
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;
    _msgCtrl.clear();
    _onTypingChanged('');
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

  Future<void> _sendImage() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);
    if (file == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      await _actions.uploadAndSendImage(bytes, ext);
    } catch (_) {
      if (mounted) _showSnackBar('Impossible d\'envoyer la photo');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _startRecording() => setState(() => _isRecording = true);
  void _cancelRecording() => setState(() => _isRecording = false);

  Future<void> _onAudioReady(
      Uint8List bytes, int seconds, String ext) async {
    setState(() => _isRecording = false);
    try {
      await _actions.sendAudio(bytes, seconds, ext);
    } catch (_) {
      if (mounted) _showSnackBar('Impossible d\'envoyer le vocal');
    }
  }

  Future<void> _sendProforma({
    required String service,
    required String prix,
    required String lieu,
    required String date,
  }) async {
    if (prix.isEmpty || service.isEmpty) return;
    try {
      await _actions.sendProforma(
          service: service, prix: prix, lieu: lieu, date: date);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur proforma: $e');
    }
  }

  void _showSecurityDialog(String msgId, String content) =>
      showSecurityConfirmDialog(
        context,
        content: content,
        onConfirm: () => _confirmIntervention(content),
      );

  Future<void> _confirmIntervention(String content) async {
    try {
      await _actions.confirmIntervention(content);
      if (mounted) _showSnackBar('Intervention confirmée !');
    } on PostgrestException catch (e) {
      if (mounted) _showSnackBar('Erreur : ${e.message}');
    } catch (e) {
      debugPrint('Erreur confirmation: $e');
    }
  }

  void _showSnackBar(String msg, {int seconds = 3}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: Duration(seconds: seconds),
      ));

  void _showCallLocked() => _showSnackBar(
      'Échangez d\'abord quelques messages pour débloquer l\'appel.',
      seconds: 4);

  void _showProformaDialog() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ProformaSheet(
            accentColor: widget.accentColor, onSend: _sendProforma),
      );

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _receiverTyping
                      ? Text(
                          'En train d\'écrire...',
                          key: const ValueKey('typing'),
                          style: GoogleFonts.inter(
                              color: widget.accentColor,
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                        )
                      : Text(
                          'Conversation sécurisée',
                          key: const ValueKey('secure'),
                          style: GoogleFonts.inter(
                              color: const Color(0xFF22C55E),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
          ),
        ]),
        actions: [
          if (phoneAvail)
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
                    ? () =>
                        launchUrl(Uri(scheme: 'tel', path: widget.receiverPhone!))
                    : _showCallLocked,
              ),
            ),
        ],
      ),
      body: Column(children: [
        if (_showBanner)
          ChatSecurityBanner(
              onDismiss: () => setState(() => _showBanner = false)),
        Expanded(
          child: ChatMessageList(
            messages: _messages,
            currentUserId: _supabase.auth.currentUser?.id,
            accentColor: widget.accentColor,
            onProformaAccept: _showSecurityDialog,
          ),
        ),
        if (_isRecording)
          AudioRecordingBar(
            accentColor: widget.accentColor,
            onSend: _onAudioReady,
            onCancel: _cancelRecording,
          )
        else
          ChatInputBar(
            controller: _msgCtrl,
            accentColor: widget.accentColor,
            onSend: _sendMessage,
            onProforma: _showProformaDialog,
            onImage: _sendImage,
            onMic: _startRecording,
            uploadingImage: _uploadingImage,
            onChanged: _onTypingChanged,
          ),
      ]),
    );
  }
}
