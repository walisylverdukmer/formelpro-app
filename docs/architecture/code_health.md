# Code Health & Dette Technique — FormelPro

*Dernière mise à jour : 2026-05-26 — Session 8 : UI refonte visuelle, portail web, Vercel fix, SQL idempotent*

---

## RÉSUMÉ EXÉCUTIF

| Catégorie | Score | Détail |
|-----------|-------|--------|
| Architecture | 8/10 | Séparation screens/widgets/services propre — doublons résolus, web/ séparé |
| Qualité code | 8/10 | Cohérent, lisible, `withValues(alpha:)` 100%, `flutter analyze` 0 issues |
| Sécurité | 7/10 | RLS ✅, secrets dart_defines ✅, bucket Storage et <SERVICE_ROLE_KEY> à finaliser |
| Maintenabilité | 8/10 | Conventions respectées, documentation à jour, migrations idempotentes |
| Performance | 7/10 | StreamBuilders corrects, quelques requêtes trop larges |

---

## 1. DOUBLONS À FUSIONNER

### 1.1 ~~`accueil_technicien.dart` + `tech_dashboard.dart`~~ ✅ RÉSOLU

`tech_dashboard.dart` supprimé. `accueil_technicien.dart` est la version unique et correcte.
Dashboard stats intégré via `widgets/stats_dashboard_tech.dart`.

---

### 1.2 ~~Fichiers mal placés dans `services/`~~ ✅ RÉSOLU

- `request_form_page.dart` → supprimé (code mort, aucun import)
- `sub_categories_page.dart` → déplacé vers `lib/screens/booking/`, import MAJ dans `main_dashboard.dart`

---

## 2. INCOHÉRENCES DÉTECTÉES

### 2.1 Colonnes manquantes potentielles dans `utilisateurs`

Le code Flutter utilise ces colonnes, mais elles sont absentes du DDL fourni :

| Colonne | Utilisée dans | À vérifier |
|---------|---------------|------------|
| `quartier` | `details_technicien.dart`, `profil_tab.dart`, `complete_profil_page.dart` | Existe-t-elle en DB ? |
| `disponible` | `accueil_client.dart` (filtre), `accueil_technicien.dart` (toggle) | Existe-t-elle en DB ? |
| `metier_principal` | Références dans certains fichiers | Remplacé par `metier_personnalise` ? |

**Action :**
```sql
-- Vérifier dans Supabase SQL Editor
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'utilisateurs'
ORDER BY column_name;
```

### 2.2 Double colonne photo

| Colonne | Statut |
|---------|--------|
| `photo_url` | Ancienne colonne — peut-être inutilisée |
| `photo_profil_url` | Nouvelle colonne principale |

**Code Flutter utilise :** `tech['photo_profil_url']` dans `details_technicien.dart`

**Action :** Grep toutes les utilisations, unifier sur `photo_profil_url`.

### 2.3 Statuts d'intervention incohérents

| Dans la DB (CHECK) | Dans le code Flutter (valeurs envoyées) |
|--------------------|----------------------------------------|
| `'accepte'` | `'accepte'` ✅ |
| — | `'Confirmé'` ⚠️ dans `mission_detail_page.dart` — à corriger |

**Action :**
```dart
// mission_detail_page.dart ligne ~27 : 'Confirmé' → 'accepte'
```

> Note : `accueil_technicien.dart` utilise déjà `'accepte'` (corrigé session 2).

### 2.4 Filtres pays potentiellement incorrects

Le filtre `.eq('pays', 'CI')` (ou `'CM'`) dans le code Flutter ne correspondrait pas aux valeurs DB (`'CIV'`, `'CMR'`).

**Action :** Grep dans tout `lib/` :
```bash
grep -r "eq('pays'" lib/
grep -r "'pays': " lib/
```
Remplacer toute valeur `'CI'` par `'CIV'` et `'CM'` par `'CMR'`.

---

## 3. FICHIERS SURDIMENSIONNÉS

Fichiers dépassant 300 lignes — candidats à l'extraction de sous-widgets :

| Fichier | Lignes | À extraire |
|---------|--------|------------|
| `chat_screen.dart` | ~384 | Widget `_MessageBubble`, widget `_ChatInput` |
| `main_dashboard.dart` | ~360 | Widget `_DashboardTab`, logique FCM → service |
| `profil_tab.dart` | ~354 | Widget `_EditModal`, widget `_ProfileHeader` |
| `accueil_client.dart` | ~380 | Widget `_TechFilter`, logique chargement → service |
| `web/devenir-prestataire.html` | ~350 | HTML monolithique — acceptable car standalone |

---

## 4. PATTERNS À HARMONISER

### 4.1 Appels Supabase directs dans les widgets

Plusieurs écrans appellent `Supabase.instance.client` directement dans `build()` ou des méthodes inline. Cible : centraliser dans des méthodes de service.

```dart
// Actuel (dispersé dans widgets)
final data = await Supabase.instance.client.from('interventions')...

// Cible (dans un service)
class InterventionService {
  Future<List<Map<String, dynamic>>> getClientInterventions(String clientId) async {
    return await Supabase.instance.client
        .from('interventions')
        .select('id, titre_service, statut, date_prevue, montant_final')
        .eq('client_id', clientId)
        .order('date_creation', ascending: false);
  }
}
```

### 4.2 Nommage inconsistant des méthodes async

```
Existant : _chargerDonnees, _loadTech, _fetchInterventions, _getData
Recommandé : _load[NomRessource] (ex: _loadInterventions, _loadTechniciens)
```

### 4.3 Gestion d'erreurs incomplète

Certains `try/catch` n'affichent pas d'erreur à l'utilisateur — ils `debugPrint` uniquement.

```dart
// ❌ Silencieux pour l'utilisateur
} catch (e) {
  debugPrint("Erreur: $e");
}

// ✅ Feedback visible
} catch (e) {
  debugPrint("Erreur: $e");
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Une erreur est survenue"), backgroundColor: Colors.red.shade800),
    );
  }
}
```

---

## 5. PLAN DE REFACTORING RECOMMANDÉ

### Priorité immédiate
1. ~~Corriger le statut `'Confirmé'` → `'accepte'`~~ ✅ corrigé
2. ~~Corriger les filtres pays `'CI'`/`'CM'` → `'CIV'`/`'CMR'`~~ ✅ corrigé
3. Remplacer `<SERVICE_ROLE_KEY>` dans migrations.sql ligne ~307

### Sprint refactoring dédié (1 journée)
1. ~~Supprimer `tech_dashboard.dart`~~ ✅ fait
2. ~~Déplacer `request_form_page.dart` + `sub_categories_page.dart`~~ ✅ fait
3. Unifier `photo_url` → `photo_profil_url` (vérifier les quelques usages résiduels)

### Refactoring progressif (au fil des features)
1. Extraire les sous-widgets des gros fichiers lors des modifications
2. Créer `InterventionService`, `ChatService`, `UserService`
3. Préparer la transition Riverpod

---

## 6. CHECKLIST QUALITÉ PAR NOUVELLE FEATURE

Avant de soumettre/valider une nouvelle fonctionnalité :

```
□ Fichier < 350 lignes (sinon extraire des widgets)
□ Tous les const utilisés (widgets statiques)
□ Null safety : aucun ! forcé, tous les ?? renseignés
□ États loading / error / empty gérés
□ mounted vérifié avant setState/SnackBar post-async
□ Streams annulés dans dispose()
□ Requêtes Supabase ciblées (pas de select *)
□ Filtre pays appliqué sur les listes de techniciens
□ Validation inputs présente sur les formulaires
□ SnackBar style "Soft Premium" (fond #1E293B, floating, rounded)
□ BorderRadius et spacing cohérents avec design system
□ GoogleFonts.poppins pour titres, GoogleFonts.inter pour corps
```
