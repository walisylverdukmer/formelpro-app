class UserModel {
  final String id;
  final String role;
  final String pays;
  final String? email;
  final String? prenom;
  final String? nomComplet;
  final int? age;
  final String? photoUrl;
  final String? ville;
  final String? commune;
  final String? quartier;
  final String? savoirFaire;
  final bool aCompleteProfil;
  final bool isPremium;
  final double noteMoyenne;
  final DateTime? dateInscription;

  UserModel({
    required this.id,
    required this.role,
    required this.pays,
    this.email,
    this.prenom,
    this.nomComplet,
    this.age,
    this.photoUrl,
    this.ville,
    this.commune,
    this.quartier,
    this.savoirFaire,
    this.aCompleteProfil = false,
    this.isPremium = false,
    this.noteMoyenne = 0.0,
    this.dateInscription,
  });

  // Convertir le JSON de Supabase en objet Dart
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      role: map['role'] ?? 'client',
      pays: map['pays'] ?? 'CIV',
      email: map['email'],
      prenom: map['prenom'],
      nomComplet: map['nom_complet'],
      age: map['age'],
      photoUrl: map['photo_profil_url'],
      ville: map['ville'],
      commune: map['commune'],
      quartier: map['quartier'],
      savoirFaire: map['savoir_faire'],
      aCompleteProfil: map['a_complete_profil'] ?? false,
      isPremium: map['is_premium'] ?? false,
      noteMoyenne: (map['note_moyenne'] as num?)?.toDouble() ?? 0.0,
      dateInscription: map['date_inscription'] != null 
          ? DateTime.parse(map['date_inscription']) 
          : null,
    );
  }

  // Convertir l'objet Dart en JSON pour Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'pays': pays,
      'email': email,
      'prenom': prenom,
      'nom_complet': nomComplet,
      'age': age,
      'photo_profil_url': photoUrl,
      'ville': ville,
      'commune': commune,
      'quartier': quartier,
      'savoir_faire': savoirFaire,
      'a_complete_profil': aCompleteProfil,
      'is_premium': isPremium,
      // note_moyenne et date_inscription sont souvent gérés par le système
    };
  }
}