import 'package:flutter/material.dart';

import 'filtres_sheet.dart';

/// Compétences disponibles pour le profil "Homme à tout faire"
const kCompetences = [
  'Petite plomberie',
  'Petite électricité',
  'Peinture',
  'Bricolage',
  'Montage meubles',
  'Manutention',
  'Jardinage',
  'Nettoyage',
  'Dépannage simple',
  'Soudure légère',
  'Carrelage',
  'Menuiserie',
];

class FiltresTechniciens {
  final bool disponibleSeulement;
  final double noteMin;
  final String? categorieId;
  final String? categorieNom;
  final String? commune;
  final String? quartier;
  final String? typePrestation;
  final List<String>? competences;

  const FiltresTechniciens({
    this.disponibleSeulement = false,
    this.noteMin = 0.0,
    this.categorieId,
    this.categorieNom,
    this.commune,
    this.quartier,
    this.typePrestation,
    this.competences,
  });

  bool get actif =>
      disponibleSeulement ||
      noteMin > 0 ||
      categorieId != null ||
      categorieNom != null ||
      commune != null ||
      quartier != null ||
      typePrestation != null ||
      (competences?.isNotEmpty ?? false);

  int get count =>
      (disponibleSeulement ? 1 : 0) +
      (noteMin > 0 ? 1 : 0) +
      (categorieId != null || categorieNom != null ? 1 : 0) +
      (commune != null ? 1 : 0) +
      (typePrestation != null ? 1 : 0) +
      ((competences?.isNotEmpty ?? false) ? 1 : 0);

  FiltresTechniciens copyWith({
    bool? disponibleSeulement,
    double? noteMin,
    String? categorieId,
    String? categorieNom,
    String? commune,
    String? quartier,
    String? typePrestation,
    List<String>? competences,
  }) {
    return FiltresTechniciens(
      disponibleSeulement: disponibleSeulement ?? this.disponibleSeulement,
      noteMin: noteMin ?? this.noteMin,
      categorieId: categorieId ?? this.categorieId,
      categorieNom: categorieNom ?? this.categorieNom,
      commune: commune ?? this.commune,
      quartier: quartier ?? this.quartier,
      typePrestation: typePrestation ?? this.typePrestation,
      competences: competences ?? this.competences,
    );
  }
}

Future<FiltresTechniciens?> showFiltresSheet(
  BuildContext context,
  Color accentColor,
  FiltresTechniciens filtres,
) {
  return showModalBottomSheet<FiltresTechniciens>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FiltresSheet(accentColor: accentColor, current: filtres),
  );
}
