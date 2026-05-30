import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatActions {
  final SupabaseClient _s = Supabase.instance.client;
  final String conversationId;
  final String receiverId;

  ChatActions({required this.conversationId, required this.receiverId});

  String get _uid => _s.auth.currentUser!.id;

  Future<void> markMessagesRead() async {
    final uid = _s.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _s
          .from('messages')
          .update({'est_lu': true})
          .eq('conversation_id', conversationId)
          .neq('expediteur_id', uid)
          .eq('est_lu', false);
    } catch (_) {}
  }

  Future<void> uploadAndSendImage(Uint8List bytes, String ext) async {
    final path =
        'chat/$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _s.storage.from('chat-images').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: 'image/$ext'));
    final url = _s.storage.from('chat-images').getPublicUrl(path);
    await _s.from('messages').insert({
      'conversation_id': conversationId,
      'expediteur_id': _uid,
      'contenu': '📷 Photo',
      'image_url': url,
      'est_proposition_intervention': false,
    });
    await _updateConversation('📷 Photo');
  }

  Future<void> sendAudio(
      Uint8List bytes, int durationSeconds, String ext) async {
    final path =
        'chat-audio/$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mime = ext == 'webm' ? 'audio/webm' : 'audio/m4a';
    await _s.storage.from('chat-audio').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: mime));
    final url = _s.storage.from('chat-audio').getPublicUrl(path);
    await _s.from('messages').insert({
      'conversation_id': conversationId,
      'expediteur_id': _uid,
      'contenu': '🎤 Vocal',
      'message_type': 'audio',
      'audio_url': url,
      'audio_duration': durationSeconds,
      'est_proposition_intervention': false,
    });
    await _updateConversation('🎤 Vocal');
  }

  Future<void> sendProforma({
    required String service,
    required String prix,
    required String lieu,
    required String date,
  }) async {
    final text = '📋 PROPOSITION DE PRESTATION\n'
        '🔧 Service : $service\n'
        '💰 Montant : $prix FCFA\n'
        '📍 Lieu : ${lieu.isEmpty ? 'À confirmer' : lieu}\n'
        '📅 Date : ${date.isEmpty ? 'À convenir' : date}';
    await _s.from('messages').insert({
      'conversation_id': conversationId,
      'expediteur_id': _uid,
      'contenu': text,
      'est_proposition_intervention': true,
    });
  }

  Future<void> confirmIntervention(String content) async {
    await _s.from('interventions').insert({
      'client_id': _uid,
      'tech_id': receiverId,
      'titre_service': 'Accord via messagerie',
      'statut': 'en_attente',
      'description': content,
      'date_prevue':
          DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    });
    await _s.from('messages').insert({
      'conversation_id': conversationId,
      'expediteur_id': _uid,
      'contenu': "✅ OFFRE ACCEPTÉE. L'intervention est enregistrée.",
      'est_proposition_intervention': false,
    });
  }

  Future<void> _updateConversation(String lastMsg) async {
    await _s.from('conversations').update({
      'dernier_message': lastMsg,
      'mis_a_jour_le': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }
}
