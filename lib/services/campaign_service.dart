import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gestion de la campagne de lancement FormelPro (01/06/2026 – 31/07/2026).
///
/// Pendant la campagne : tous les nouveaux comptes sont Premium sans limitation.
/// Après la campagne :
///   - Client : blocage après 5 demandes validées
///   - Prestataire : blocage après 3 prestations confirmées
class CampaignService {
  static final _supabase = Supabase.instance.client;

  static final _start = DateTime(2026, 6, 1);
  static final _end = DateTime(2026, 7, 31, 23, 59, 59);

  /// Date de fin de campagne (exposée pour usage externe).
  static DateTime get campaignEnd => _end;

  // Limite client : 5 demandes validées/terminées
  static const int limitClient = 5;
  // Limite prestataire : 3 prestations confirmées/terminées
  static const int limitTech = 3;

  /// Vérifie si la campagne lancement est active aujourd'hui.
  static bool isActiveCampaign() {
    final now = DateTime.now();
    return now.isAfter(_start) && now.isBefore(_end);
  }

  /// Applique le statut Premium gratuit au nouvel utilisateur si en campagne.
  /// À appeler après la création du compte.
  static Future<void> applyLaunchPremium(String userId) async {
    if (!isActiveCampaign()) return;
    try {
      await _supabase.from('utilisateurs').update({
        'is_premium': true,
        'premium_until': _end.toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('CampaignService.applyLaunchPremium error: $e');
    }
  }

  /// Retourne le nombre de demandes validées/terminées du client.
  static Future<int> getClientUsageCount(String userId) async {
    try {
      final data = await _supabase
          .from('interventions')
          .select('id')
          .eq('client_id', userId)
          .inFilter('statut', ['termine', 'valide', 'en_cours']);
      return data.length;
    } catch (e) {
      debugPrint('CampaignService.getClientUsageCount error: $e');
      return 0;
    }
  }

  /// Retourne le nombre de prestations confirmées/terminées du technicien.
  static Future<int> getTechUsageCount(String userId) async {
    try {
      final data = await _supabase
          .from('interventions')
          .select('id')
          .eq('tech_id', userId)
          .inFilter('statut', ['termine', 'valide', 'en_cours']);
      return data.length;
    } catch (e) {
      debugPrint('CampaignService.getTechUsageCount error: $e');
      return 0;
    }
  }

  /// Vérifie si le client est bloqué (limite atteinte post-campagne).
  static Future<bool> isClientBlocked(String userId) async {
    if (isActiveCampaign()) return false;
    final count = await getClientUsageCount(userId);
    return count >= limitClient;
  }

  /// Vérifie si le technicien est bloqué (limite atteinte post-campagne).
  static Future<bool> isTechBlocked(String userId) async {
    if (isActiveCampaign()) return false;
    final count = await getTechUsageCount(userId);
    return count >= limitTech;
  }

  /// Tente de débloquer un compte via un code promo admin.
  /// Retourne true si le code est valide et le compte débloqué.
  static Future<bool> unlockWithCode(String userId, String code) async {
    try {
      // Architecture : vérification du code dans la table promo_codes
      final rows = await _supabase
          .from('promo_codes')
          .select('id, max_uses, uses_count')
          .eq('code', code.trim().toUpperCase())
          .eq('is_active', true)
          .limit(1);

      if (rows.isEmpty) return false;
      final promo = rows.first;
      final maxUses = (promo['max_uses'] as int?) ?? 0;
      final usesCount = (promo['uses_count'] as int?) ?? 0;
      if (maxUses > 0 && usesCount >= maxUses) return false;

      // Appliquer le déblocage : redonner 1 mois de premium
      final newEnd = DateTime.now().add(const Duration(days: 30));
      await _supabase.from('utilisateurs').update({
        'is_premium': true,
        'premium_until': newEnd.toIso8601String(),
      }).eq('id', userId);

      // Incrémenter le compteur d'utilisation
      await _supabase
          .from('promo_codes')
          .update({'uses_count': usesCount + 1}).eq('id', promo['id']);

      return true;
    } catch (e) {
      debugPrint('CampaignService.unlockWithCode error: $e');
      return false;
    }
  }

  /// Texte d'info campagne pour affichage dans le dashboard.
  static String? getCampaignBannerText() {
    if (!isActiveCampaign()) return null;
    return '🎉 Offre de lancement — Compte Premium GRATUIT jusqu\'au 31 juillet 2026 !';
  }
}
