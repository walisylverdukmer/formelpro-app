import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPrefsPage extends StatefulWidget {
  final String uid;
  final Color accentColor;

  const NotificationPrefsPage({
    super.key,
    required this.uid,
    required this.accentColor,
  });

  @override
  State<NotificationPrefsPage> createState() => _NotificationPrefsPageState();
}

class _NotificationPrefsPageState extends State<NotificationPrefsPage> {
  final _sb = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  // Préférences par catégorie
  bool _messages   = true;
  bool _demandes   = true;
  bool _documents  = true;
  bool _marketing  = false;
  bool _systeme    = true;
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final row = await _sb
          .from('utilisateurs')
          .select('push_enabled, notification_preferences')
          .eq('id', widget.uid)
          .single();

      final prefs = (row['notification_preferences'] as Map<String, dynamic>?) ?? {};

      if (mounted) {
        setState(() {
          _pushEnabled = row['push_enabled'] as bool? ?? true;
          _messages  = prefs['messages']  as bool? ?? true;
          _demandes  = prefs['demandes']  as bool? ?? true;
          _documents = prefs['documents'] as bool? ?? true;
          _marketing = prefs['marketing'] as bool? ?? false;
          _systeme   = prefs['systeme']   as bool? ?? true;
          _loading   = false;
        });
      }
    } catch (e) {
      debugPrint('NotifPrefs._load: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _sb.from('utilisateurs').update({
        'push_enabled': _pushEnabled,
        'notification_preferences': {
          'messages':  _messages,
          'demandes':  _demandes,
          'documents': _documents,
          'marketing': _marketing,
          'systeme':   _systeme,
        },
      }).eq('id', widget.uid);
      if (mounted) _snack('Préférences sauvegardées');
    } catch (e) {
      if (mounted) _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ));

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Enregistrer',
                  style: GoogleFonts.inter(
                      color: accent, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMasterToggle(accent),
                  const SizedBox(height: 28),
                  _buildCategoriesSection(accent),
                  const SizedBox(height: 28),
                  _buildInfoBanner(),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterToggle(Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pushEnabled
            ? accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _pushEnabled
              ? accent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (_pushEnabled ? accent : Colors.white38).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _pushEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: _pushEnabled ? accent : Colors.white38,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notifications push',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              _pushEnabled
                  ? 'Activées — vous recevez toutes les alertes'
                  : 'Désactivées — aucune notification',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
          ]),
        ),
        Switch(
          value: _pushEnabled,
          onChanged: (v) => setState(() => _pushEnabled = v),
          activeThumbColor: accent,
          activeTrackColor: accent.withValues(alpha: 0.4),
        ),
      ]),
    );
  }

  Widget _buildCategoriesSection(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Par catégorie',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 12),
        _PrefCard(
          enabled: _pushEnabled,
          children: [
            _PrefTile(
              icon: Icons.chat_bubble_rounded,
              title: 'Messages',
              subtitle: 'Nouveaux messages dans vos conversations',
              color: accent,
              value: _messages,
              enabled: _pushEnabled,
              onChanged: (v) => setState(() => _messages = v),
            ),
            const _PrefDivider(),
            _PrefTile(
              icon: Icons.work_rounded,
              title: 'Demandes',
              subtitle: 'Nouvelles missions, interventions, devis',
              color: const Color(0xFF10B981),
              value: _demandes,
              enabled: _pushEnabled,
              onChanged: (v) => setState(() => _demandes = v),
            ),
            const _PrefDivider(),
            _PrefTile(
              icon: Icons.verified_user_rounded,
              title: 'Documents',
              subtitle: 'Validation et rejet de vos pièces d\'identité',
              color: Colors.amber,
              value: _documents,
              enabled: _pushEnabled,
              onChanged: (v) => setState(() => _documents = v),
            ),
            const _PrefDivider(),
            _PrefTile(
              icon: Icons.campaign_rounded,
              title: 'Marketing',
              subtitle: 'Promotions, nouveautés et offres FormelPro',
              color: const Color(0xFF8B5CF6),
              value: _marketing,
              enabled: _pushEnabled,
              onChanged: (v) => setState(() => _marketing = v),
            ),
            const _PrefDivider(),
            _PrefTile(
              icon: Icons.info_rounded,
              title: 'Système',
              subtitle: 'Mises à jour importantes, sécurité, maintenance',
              color: const Color(0xFF06B6D4),
              value: _systeme,
              enabled: _pushEnabled,
              onChanged: (v) => setState(() => _systeme = v),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.phone_android_rounded, color: Colors.white24, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Les notifications push nécessitent que FormelPro soit installé '
            'sur votre appareil Android ou iOS. '
            'Sur navigateur, les notifications sont affichées dans l\'application.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, height: 1.5),
          ),
        ),
      ]),
    );
  }
}

// ─── Composants internes ──────────────────────────────────────────────────────

class _PrefCard extends StatelessWidget {
  final bool enabled;
  final List<Widget> children;
  const _PrefCard({required this.enabled, required this.children});

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(children: children),
        ),
      );
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.value, required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
            Text(subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: color,
          activeTrackColor: color.withValues(alpha: 0.4),
        ),
      ]),
    );
  }
}

class _PrefDivider extends StatelessWidget {
  const _PrefDivider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, color: Color(0xFF1E293B), indent: 16, endIndent: 16);
}
