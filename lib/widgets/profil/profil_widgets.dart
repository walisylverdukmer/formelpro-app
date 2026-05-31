import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:formelpro/screens/dashboard/details_technicien.dart';
import 'package:formelpro/screens/auth/page_connexion_principale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilGlassCard extends StatelessWidget {
  final List<Widget> children;
  const ProfilGlassCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class ProfilSectionTitle extends StatelessWidget {
  final String title;
  const ProfilSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
              letterSpacing: 1.5),
        ),
      ),
    );
  }
}

class ProfilInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const ProfilInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
      subtitle: Text(value,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white)),
      trailing: trailing,
    );
  }
}

class ProfilActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Color accentColor;

  const ProfilActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: accentColor, size: 18),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 11, color: Colors.white24))
          : null,
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }
}

class ProfilDivider extends StatelessWidget {
  const ProfilDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.white.withAlpha(13), indent: 55);
  }
}

class FavoriTile extends StatelessWidget {
  final Map<String, dynamic> tech;
  final Color accentColor;

  const FavoriTile({
    super.key,
    required this.tech,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailsTechnicien(tech: tech, accentColor: accentColor),
        ),
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: accentColor.withAlpha(25),
        backgroundImage: tech['photo_profil_url'] != null
            ? NetworkImage(tech['photo_profil_url'])
            : null,
        child: tech['photo_profil_url'] == null
            ? Icon(Icons.person, color: accentColor, size: 18)
            : null,
      ),
      title: Text(tech['nom_complet'] ?? 'Anonyme',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      subtitle: Text(tech['metier_personnalise'] ?? 'Prestataire',
          style: GoogleFonts.inter(fontSize: 12, color: accentColor)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: Colors.white12),
    );
  }
}

class ProfilLogoutButton extends StatelessWidget {
  const ProfilLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid != null && !kIsWeb) {
            try {
              await FirebaseMessaging.instance
                  .unsubscribeFromTopic('user_$uid');
            } catch (_) {}
          }
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const PageConnexionPrincipale()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.power_settings_new_rounded,
            color: Colors.redAccent),
        label: const Text("Déconnexion du compte",
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}

// ─── WhatsApp contact sheet ───────────────────────────────────────────────────

void showWhatsAppContactSheet(BuildContext context, Color accentColor) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Contacter FormelPro',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez un numéro WhatsApp',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const WhatsAppContactTile(
            label: 'Support client',
            number: '+225 07 13 53 66 02',
            waNumber: '2250713536602',
          ),
          const SizedBox(height: 12),
          const WhatsAppContactTile(
            label: 'Support prestataire',
            number: '+225 07 10 75 00 88',
            waNumber: '2250710750088',
          ),
        ],
      ),
    ),
  );
}

class WhatsAppContactTile extends StatelessWidget {
  final String label;
  final String number;
  final String waNumber;

  const WhatsAppContactTile({
    super.key,
    required this.label,
    required this.number,
    required this.waNumber,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://wa.me/$waNumber'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_rounded,
                color: Color(0xFF25D366), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                Text(number,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded,
              color: Color(0xFF25D366), size: 16),
        ]),
      ),
    );
  }
}
