// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Réglages';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get wheelColors => 'Couleurs de la roue';

  @override
  String get paletteFestive => 'Festif';

  @override
  String get paletteOcean => 'Océan';

  @override
  String get paletteForest => 'Forêt';

  @override
  String get paletteCandy => 'Bonbon';

  @override
  String get choicesSection => 'Choix';

  @override
  String get weightedChoices => 'Donner un poids aux choix';

  @override
  String get weightedChoicesHint =>
      'Un choix plus lourd a une plus grande part de la roue et plus de chances de sortir.';

  @override
  String get elimination => 'Mode élimination';

  @override
  String get eliminationHint =>
      'Chaque tirage élimine le choix tiré, et le dernier qui reste l\'emporte.';

  @override
  String get confirmElimination => 'Demander avant de retirer';

  @override
  String get confirmEliminationHint =>
      'Après chaque tirage, tu choisis de garder le choix ou de le sortir de la roue.';

  @override
  String get soundsSection => 'Sons';

  @override
  String get sounds => 'Sons et vibrations';

  @override
  String get soundsHint =>
      'Un tic à chaque clou, un petit carillon à l\'arrêt et des vibrations sur mobile.';

  @override
  String get language => 'Langue';

  @override
  String get languageDevice => 'Appareil';

  @override
  String get newList => 'Nouvelle liste';

  @override
  String get create => 'Créer';

  @override
  String get renameList => 'Renommer la liste';

  @override
  String get rename => 'Renommer';

  @override
  String get deleteListQuestion => 'Supprimer la liste ?';

  @override
  String deleteListWarning(String name) {
    return '« $name » et ses choix seront perdus.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteList => 'Supprimer la liste';

  @override
  String get resultTitle => 'Le sort a choisi';

  @override
  String get eliminatedTitle => 'Éliminé';

  @override
  String get eliminateQuestion => 'Éliminer ce choix ?';

  @override
  String get eliminationAsk =>
      'Le sortir de la roue pour les prochains tirages ?';

  @override
  String get eliminationNote =>
      'Il sort de la roue pour les prochains tirages.';

  @override
  String get keepChoice => 'Le garder';

  @override
  String get eliminateChoice => 'L\'éliminer';

  @override
  String get great => 'Super !';

  @override
  String get next => 'Continuer';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get switchList => 'Changer de liste';

  @override
  String choiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choix',
      one: '1 choix',
      zero: 'Aucun choix',
    );
    return '$_temp0';
  }

  @override
  String get allChoicesOut => 'Tous les choix sont sortis.';

  @override
  String lastChoiceWins(String choice) {
    return '« $choice » l\'emporte !';
  }

  @override
  String get restoreAllWheel => 'Tout remettre dans la roue';

  @override
  String get addAtLeastTwo => 'Ajoute au moins 2 choix';

  @override
  String get spin => 'Faire tourner';

  @override
  String get lessLikely => 'Moins de chances';

  @override
  String get moreLikely => 'Plus de chances';

  @override
  String get newChoice => 'Nouveau choix';

  @override
  String get add => 'Ajouter';

  @override
  String eliminatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choix éliminés',
      one: '1 choix éliminé',
    );
    return '$_temp0';
  }

  @override
  String get restoreAll => 'Tout remettre';

  @override
  String get noChoicesYet => 'Aucun choix pour le moment.';

  @override
  String get eliminated => 'Éliminé';

  @override
  String get restore => 'Remettre dans la roue';

  @override
  String get remove => 'Retirer';

  @override
  String percent(String value) {
    return '$value %';
  }

  @override
  String get listName => 'Nom de la liste';

  @override
  String get listNameHint => 'Ex. : Sorties du week-end';

  @override
  String get defaultListName => 'Repas';

  @override
  String get defaultChoices => 'Pizza|Sushi|Burger|Salade';

  @override
  String get choiceColor => 'Couleur du choix';

  @override
  String get changeColor => 'Changer la couleur';

  @override
  String get restoreDefaultColor => 'Restaurer par défaut';

  @override
  String get renameChoice => 'Renommer le choix';
}
