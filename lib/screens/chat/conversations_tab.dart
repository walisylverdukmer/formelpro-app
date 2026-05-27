import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import '../../widgets/chat/conversation_item.dart';

class ConversationsTab extends StatefulWidget {
  final Color accentColor;
  final String uid;
  final ValueNotifier<int>? unreadNotifier;

  const ConversationsTab({
    super.key,
    required this.accentColor,
    required this.uid,
    this.unreadNotifier,
  });

  @override
  State<ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<ConversationsTab> {
  final _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;

  bool _loading = true;
  List<Map<String, dynamic>> _conversations = [];
  final Map<String, DateTime> _lastOpened = {};

  @override
  void initState() {
    super.initState();
    _loadLastOpened();
    _fetchConversations();
    _channel = _supabase
        .channel('conv_tab_${widget.uid}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => _fetchConversations(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _loadLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, DateTime> map = {};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('conv_opened_')) continue;
      final ts = prefs.getInt(key);
      if (ts != null) {
        map[key.replaceFirst('conv_opened_', '')] =
            DateTime.fromMillisecondsSinceEpoch(ts);
      }
    }
    if (!mounted) return;
    setState(() => _lastOpened.addAll(map));
    _updateUnreadCount();
  }

  Future<void> _fetchConversations() async {
    try {
      final convData = await _supabase
          .from('conversations')
          .select('id, client_id, tech_id, dernier_message, mis_a_jour_le')
          .or('client_id.eq.${widget.uid},tech_id.eq.${widget.uid}')
          .order('mis_a_jour_le', ascending: false)
          .limit(50);

      final convs = List<Map<String, dynamic>>.from(convData as List);

      if (convs.isEmpty) {
        if (mounted) setState(() { _conversations = []; _loading = false; });
        _updateUnreadCount();
        return;
      }

      final otherIds = convs
          .map((c) => (c['client_id'] == widget.uid
              ? c['tech_id']
              : c['client_id']) as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final profiles = await _supabase
          .from('utilisateurs')
          .select('id, nom_complet, photo_profil_url')
          .inFilter('id', otherIds);

      final profileMap = <String, Map<String, dynamic>>{
        for (final p in (profiles as List))
          p['id'] as String: p as Map<String, dynamic>
      };

      final enriched = convs.map((c) {
        final otherId =
            (c['client_id'] == widget.uid ? c['tech_id'] : c['client_id'])
                as String? ??
                '';
        return {...c, '_other_id': otherId, '_other': profileMap[otherId] ?? {}};
      }).toList();

      if (mounted) {
        setState(() { _conversations = enriched; _loading = false; });
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Erreur conversations: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateUnreadCount() {
    widget.unreadNotifier?.value = _conversations.where(_hasUnread).length;
  }

  Future<void> _markOpened(String convId) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('conv_opened_$convId', now.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(() => _lastOpened[convId] = now);
    _updateUnreadCount();
  }

  bool _hasUnread(Map<String, dynamic> conv) {
    final raw = conv['mis_a_jour_le'] as String?;
    if (raw == null) return false;
    final misAJour = DateTime.tryParse(raw);
    if (misAJour == null) return false;
    final opened = _lastOpened[conv['id'] as String];
    return opened == null || misAJour.isAfter(opened);
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "${diff.inMinutes}min";
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return "Hier";
    if (diff.inDays < 7) return DateFormat('EEE', 'fr').format(dt);
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                "Messages",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(child: _loading ? _buildShimmer() : _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_conversations.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _fetchConversations,
      color: widget.accentColor,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.05),
          height: 1,
          indent: 72,
        ),
        itemBuilder: (_, i) => _buildItem(_conversations[i]),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> conv) {
    final other = conv['_other'] as Map<String, dynamic>? ?? {};
    final String otherId = conv['_other_id'] as String? ?? '';
    final String name = other['nom_complet'] as String? ?? 'Utilisateur';
    final String? photoUrl = other['photo_profil_url'] as String?;
    final String lastMsg =
        conv['dernier_message'] as String? ?? 'Nouvelle conversation';
    final bool unread = _hasUnread(conv);
    final String convId = conv['id'] as String;

    return ConversationItem(
      name: name,
      photoUrl: photoUrl,
      lastMsg: lastMsg,
      unread: unread,
      formattedTime: _formatTime(conv['mis_a_jour_le'] as String?),
      accentColor: widget.accentColor,
      onTap: () {
        _markOpened(convId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              receiverName: name,
              receiverId: otherId,
              accentColor: widget.accentColor,
            ),
          ),
        ).then((_) => _markOpened(convId));
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: widget.accentColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Aucune conversation",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Contactez un technicien depuis\nl'accueil pour démarrer.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white38,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
