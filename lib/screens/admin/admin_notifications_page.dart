import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _Audience { tous, clients, prestataires, premium }

class AdminNotificationsPage extends StatefulWidget {
  final Color accentColor;
  const AdminNotificationsPage({super.key, required this.accentColor});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titreCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  _Audience _audience = _Audience.tous;
  bool _showPreview = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _prepare() {
    if (_titreCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Remplissez le titre et le message.',
            style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    setState(() => _showPreview = true);
  }

  String get _audienceLabel => switch (_audience) {
        _Audience.tous => 'Tous les utilisateurs',
        _Audience.clients => 'Clients uniquement',
        _Audience.prestataires => 'Prestataires uniquement',
        _Audience.premium => 'Prestataires Premium',
      };

  String get _audienceTopic => switch (_audience) {
        _Audience.tous => 'broadcast',
        _Audience.clients => 'clients',
        _Audience.prestataires => 'prestataires',
        _Audience.premium => 'premium',
      };

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications Push',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArchitectureBanner(accent),
            const SizedBox(height: 24),
            _buildAudienceSelector(accent),
            const SizedBox(height: 20),
            _buildTitreField(accent),
            const SizedBox(height: 16),
            _buildMessageField(accent),
            const SizedBox(height: 24),
            _buildPrepareButton(accent),
            if (_showPreview) ...[
              const SizedBox(height: 24),
              _buildPreview(accent),
            ],
            const SizedBox(height: 28),
            _buildFcmGuide(accent),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureBanner(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFF97316), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Architecture prête — Intégration FCM à connecter',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: const Color(0xFFF97316))),
            const SizedBox(height: 4),
            Text(
              'La structure de notification est définie. '
              'L\'envoi réel nécessite la configuration de l\'Edge Function Supabase '
              'avec la Firebase Admin SDK.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, height: 1.5),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAudienceSelector(Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Audience cible',
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _Audience.values.map((a) {
          final sel = _audience == a;
          return GestureDetector(
            onTap: () => setState(() { _audience = a; _showPreview = false; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? accent : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? accent : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                switch (a) {
                  _Audience.tous => '🌐 Tous',
                  _Audience.clients => '👤 Clients',
                  _Audience.prestataires => '🔧 Prestataires',
                  _Audience.premium => '⭐ Premium',
                },
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : Colors.white54),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildTitreField(Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Titre de la notification',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _titreCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            maxLength: 60,
            onChanged: (_) => setState(() => _showPreview = false),
            decoration: InputDecoration(
              hintText: 'ex: FormelPro — Nouveauté',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              counterStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
            ),
          ),
        ],
      );

  Widget _buildMessageField(Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Message',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            maxLength: 200,
            maxLines: 4,
            onChanged: (_) => setState(() => _showPreview = false),
            decoration: InputDecoration(
              hintText: 'Rédigez votre message...',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
              counterStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
            ),
          ),
        ],
      );

  Widget _buildPrepareButton(Color accent) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _prepare,
          icon: const Icon(Icons.preview_rounded, size: 18),
          label: Text('Prévisualiser la notification',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );

  Widget _buildPreview(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.phone_android_rounded, color: accent, size: 18),
          const SizedBox(width: 8),
          Text('Prévisualisation',
              style: GoogleFonts.inter(fontSize: 12, color: accent, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_titreCtrl.text.trim(),
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(_msgCtrl.text.trim(),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 12),
        _previewRow('Audience', _audienceLabel, Icons.group_rounded, accent),
        _previewRow('Topic FCM', _audienceTopic, Icons.label_rounded, Colors.white38),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            const Icon(Icons.lock_rounded, color: Colors.white24, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'L\'envoi est désactivé. Connectez l\'Edge Function Supabase + '
                'Firebase Admin SDK pour activer l\'envoi réel.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _previewRow(String label, String value, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text('$label : ',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildFcmGuide(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Guide d\'intégration FCM',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
        const SizedBox(height: 10),
        _guideStep('1', 'Créer une Edge Function Supabase `send-push`', Colors.white38),
        _guideStep('2', 'Injecter le secret Firebase Admin SDK (`FIREBASE_SERVICE_KEY`)', Colors.white38),
        _guideStep('3', 'Appeler `fcm.send()` avec le topic : `prestataires`, `clients`, `premium`, `broadcast`', Colors.white38),
        _guideStep('4', 'Appeler l\'Edge Function depuis l\'admin panel avec le payload préparé ici', Colors.white38),
      ]),
    );
  }

  Widget _guideStep(String num, String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
            ),
          ),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(fontSize: 12, color: color, height: 1.5)),
          ),
        ]),
      );
}
