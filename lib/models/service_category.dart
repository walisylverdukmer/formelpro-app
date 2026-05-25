class ServiceCategory {
  final String id;
  final String nom;
  final String slug;
  final String? description;
  final String groupeParent;
  final bool estValide;

  ServiceCategory({
    required this.id,
    required this.nom,
    required this.slug,
    this.description,
    required this.groupeParent,
    this.estValide = true,
  });

  // Convertit le format JSON de Supabase en objet Dart
  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'],
      nom: map['nom'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'],
      groupeParent: map['groupe_parent'] ?? 'Autres',
      estValide: map['est_valide'] ?? true,
    );
  }

  // Fonction utilitaire pour récupérer l'image locale correspondante
  // Basée sur vos fichiers : fond_3.jpeg, fond_hy.jpg, fond_ga.jpg, fond_lo.jpg
  String get localImageAsset {
    switch (groupeParent) {
      case 'Urgence & Travaux':
        return 'assets/images/fond_3.jpeg';
      case 'Maison & Hygiène':
        return 'assets/images/fond_hy.jpg';
      case 'Évènements & Gastro':
        return 'assets/images/fond_ga.jpg';
      case 'Logistique & Gaz':
        return 'assets/images/fond_lo.jpg';
      default:
        return 'assets/images/fond_3.jpeg'; // Image par défaut
    }
  }
}