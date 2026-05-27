import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/filtres_techniciens.dart';

class TechnicienService {
  static final _db = Supabase.instance.client;

  static const _cols =
      'id, nom_complet, metier_personnalise, savoir_faire, photo_profil_url, '
      'score_global, note_moyenne, ville, commune, quartier, disponible, '
      'is_premium, premium_level, est_en_ligne, telephone, is_identite_verifiee, '
      'latitude, longitude, competences';

  static const int pageSize = 20;

  static Future<List<Map<String, dynamic>>> fetchTechniciens({
    required String pays,
    required FiltresTechniciens filtres,
    String search = '',
    int offset = 0,
  }) async {
    List<String>? techIds;

    if (filtres.categorieId != null) {
      techIds = await _idsByCategId(filtres.categorieId!);
      if (techIds.isEmpty) return [];
    } else if (filtres.categorieNom != null) {
      techIds = await _idsByCategorieNom(filtres.categorieNom!);
      if (techIds.isEmpty) return [];
    }

    var query = _db
        .from('utilisateurs')
        .select(_cols)
        .eq('role', 'technicien')
        .eq('pays', pays);

    if (techIds != null) {
      query = query.inFilter('id', techIds);
    } else if (filtres.categorieNom != null && search.isEmpty) {
      query = query.or(
        'metier_personnalise.ilike.%${filtres.categorieNom}%,'
        'savoir_faire.ilike.%${filtres.categorieNom}%',
      );
    }

    if (filtres.disponibleSeulement) query = query.eq('disponible', true);
    if (filtres.noteMin > 0) query = query.gte('note_moyenne', filtres.noteMin);
    if (filtres.commune?.isNotEmpty ?? false) {
      query = query.ilike('commune', '%${filtres.commune}%');
    }
    if (filtres.quartier?.isNotEmpty ?? false) {
      query = query.ilike('quartier', '%${filtres.quartier}%');
    }
    if (filtres.competences != null && filtres.competences!.isNotEmpty) {
      final quoted =
          filtres.competences!.map((c) => '"$c"').join(',');
      query = query.filter('competences', 'ov', '{$quoted}');
    }
    if (search.isNotEmpty) {
      query = query.or(
        'nom_complet.ilike.%$search%,metier_personnalise.ilike.%$search%',
      );
    }

    final response = await query
        .order('is_premium', ascending: false)
        .order('est_en_ligne', ascending: false)
        .order('score_global', ascending: false)
        .range(offset, offset + pageSize - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> fetchTopCategories() async {
    final cats = await _db
        .from('categories_services')
        .select('id, nom')
        .eq('est_valide', true)
        .order('ordre_affichage')
        .limit(8);
    return List<Map<String, dynamic>>.from(cats);
  }

  static Future<List<String>> _idsByCategId(String categId) async {
    final rows = await _db
        .from('technicien_categories')
        .select('technicien_id')
        .eq('categorie_id', categId);
    return rows.map<String>((r) => r['technicien_id'].toString()).toList();
  }

  static Future<List<String>> _idsByCategorieNom(String nom) async {
    final cats = await _db
        .from('categories_services')
        .select('id')
        .ilike('nom', '%$nom%')
        .eq('est_valide', true);
    if (cats.isEmpty) return [];
    final catIds = cats.map<String>((c) => c['id'].toString()).toList();
    final rows = await _db
        .from('technicien_categories')
        .select('technicien_id')
        .inFilter('categorie_id', catIds);
    return rows.map<String>((r) => r['technicien_id'].toString()).toList();
  }
}
