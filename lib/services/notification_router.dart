import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:formelpro/screens/admin/admin_documents_page.dart';
import 'package:formelpro/screens/chat/chat_screen.dart';
import 'package:formelpro/screens/dashboard/verification_documents_page.dart';
import 'package:formelpro/screens/interventions/intervention_detail_page.dart';
import 'package:formelpro/screens/interventions/mission_detail_page.dart';

/// Navigator key partagé — référencé dans MaterialApp pour permettre
/// la navigation depuis les callbacks FCM (hors arbre de widgets).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Payload reçu lors d'un tap sur notif avec l'app fermée (terminated state).
/// Stocké ici, consommé une fois dans MainDashboardPage.initState().
Map<String, dynamic>? pendingNotificationData;

Future<void> routeFromNotification(Map<String, dynamic> data) async {
  final type = data['type'] as String?;
  switch (type) {
    case 'message':
      await _routeToChat(data);
    case 'intervention':
    case 'accord':
    case 'devis':
      await _routeToIntervention(data);
    case 'doc_soumis':
      await _routeToAdminDocs();
    case 'doc_approuve':
    case 'doc_rejete':
      await _routeToVerificationDocs();
    default:
      debugPrint('FCM router: type non géré — $type');
  }
}

Future<void> _routeToChat(Map<String, dynamic> data) async {
  final conversationId = data['conversation_id'] as String?;
  if (conversationId == null) return;

  final nav = navigatorKey.currentState;
  if (nav == null) return;

  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final conv = await Supabase.instance.client
        .from('conversations')
        .select('client_id, tech_id')
        .eq('id', conversationId)
        .single();

    final receiverId = conv['client_id'] == currentUser.id
        ? conv['tech_id'] as String
        : conv['client_id'] as String;

    final receiver = await Supabase.instance.client
        .from('utilisateurs')
        .select('nom_complet, pays')
        .eq('id', receiverId)
        .single();

    final pays = receiver['pays'] as String? ?? 'CIV';
    final accentColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFE74C3C);

    nav.push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversationId: conversationId,
        receiverName: receiver['nom_complet'] as String? ?? 'Utilisateur',
        receiverId: receiverId,
        accentColor: accentColor,
      ),
    ));
  } catch (e) {
    debugPrint('FCM router (chat): $e');
  }
}

Future<void> _routeToVerificationDocs() async {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    final user = await Supabase.instance.client
        .from('utilisateurs')
        .select('pays')
        .eq('id', currentUser.id)
        .single();
    final pays = user['pays'] as String? ?? 'CIV';
    final accentColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFCE1126);
    nav.push(MaterialPageRoute(
      builder: (_) => VerificationDocumentsPage(accentColor: accentColor),
    ));
  } catch (e) {
    debugPrint('FCM router (verif docs): $e');
  }
}

Future<void> _routeToAdminDocs() async {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    final user = await Supabase.instance.client
        .from('utilisateurs')
        .select('pays')
        .eq('id', currentUser.id)
        .single();
    final pays = user['pays'] as String? ?? 'CIV';
    final accentColor =
        pays == 'CIV' ? const Color(0xFFE67E22) : const Color(0xFFCE1126);
    nav.push(MaterialPageRoute(
      builder: (_) => AdminDocumentsPage(accentColor: accentColor),
    ));
  } catch (e) {
    debugPrint('FCM router (admin docs): $e');
  }
}

Future<void> _routeToIntervention(Map<String, dynamic> data) async {
  final interventionId = data['intervention_id'] as String?;
  if (interventionId == null) return;

  final nav = navigatorKey.currentState;
  if (nav == null) return;

  try {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final intervention = await Supabase.instance.client
        .from('interventions')
        .select('id, titre_service, statut, description, date_prevue, montant_final, client_id, tech_id, ville, commune')
        .eq('id', interventionId)
        .single();

    final isTechnicien = intervention['tech_id'] == currentUser.id;

    nav.push(MaterialPageRoute(
      builder: (_) => isTechnicien
          ? MissionDetailPage(intervention: intervention)
          : InterventionDetailPage(
              intervention: intervention,
              isLookingAtTech: false,
            ),
    ));
  } catch (e) {
    debugPrint('FCM router (intervention): $e');
  }
}
