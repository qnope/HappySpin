// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get wheelColors => 'Wheel colors';

  @override
  String get paletteFestive => 'Festive';

  @override
  String get paletteOcean => 'Ocean';

  @override
  String get paletteForest => 'Forest';

  @override
  String get paletteCandy => 'Candy';

  @override
  String get choicesSection => 'Choices';

  @override
  String get weightedChoices => 'Give choices a weight';

  @override
  String get weightedChoicesHint =>
      'A heavier choice gets a bigger slice of the wheel and a better chance of coming up.';

  @override
  String get elimination => 'Elimination mode';

  @override
  String get eliminationHint =>
      'Each spin eliminates the picked choice, and the last one left wins.';

  @override
  String get confirmElimination => 'Ask before removing';

  @override
  String get confirmEliminationHint =>
      'After each spin, you choose to keep the choice or take it off the wheel.';

  @override
  String get soundsSection => 'Sounds';

  @override
  String get sounds => 'Sounds and vibrations';

  @override
  String get soundsHint =>
      'A tick at every peg, a little chime when it stops, and vibrations on mobile.';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Device';

  @override
  String get newList => 'New list';

  @override
  String get create => 'Create';

  @override
  String get renameList => 'Rename list';

  @override
  String get rename => 'Rename';

  @override
  String get deleteListQuestion => 'Delete the list?';

  @override
  String deleteListWarning(String name) {
    return '“$name” and its choices will be lost.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteList => 'Delete list';

  @override
  String get resultTitle => 'Fate has chosen';

  @override
  String get eliminatedTitle => 'Eliminated';

  @override
  String get eliminateQuestion => 'Eliminate this choice?';

  @override
  String get eliminationAsk => 'Take it off the wheel for the next spins?';

  @override
  String get eliminationNote => 'It leaves the wheel for the next spins.';

  @override
  String get keepChoice => 'Keep it';

  @override
  String get eliminateChoice => 'Eliminate it';

  @override
  String get great => 'Great!';

  @override
  String get next => 'Continue';

  @override
  String get clearAll => 'Clear all';

  @override
  String get switchList => 'Switch list';

  @override
  String choiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choices',
      one: '1 choice',
      zero: 'No choices',
    );
    return '$_temp0';
  }

  @override
  String get allChoicesOut => 'All the choices are out.';

  @override
  String lastChoiceWins(String choice) {
    return '“$choice” wins!';
  }

  @override
  String get restoreAllWheel => 'Put everything back on the wheel';

  @override
  String get addAtLeastTwo => 'Add at least 2 choices';

  @override
  String get spin => 'Spin';

  @override
  String get lessLikely => 'Less likely';

  @override
  String get moreLikely => 'More likely';

  @override
  String get newChoice => 'New choice';

  @override
  String get add => 'Add';

  @override
  String eliminatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choices out',
      one: '1 choice out',
    );
    return '$_temp0';
  }

  @override
  String get restoreAll => 'Put all back';

  @override
  String get noChoicesYet => 'No choices yet.';

  @override
  String get eliminated => 'Off the wheel';

  @override
  String get restore => 'Put back on the wheel';

  @override
  String get remove => 'Remove';

  @override
  String percent(String value) {
    return '$value%';
  }

  @override
  String get listName => 'List name';

  @override
  String get listNameHint => 'E.g. Weekend outings';

  @override
  String get defaultListName => 'Meals';

  @override
  String get defaultChoices => 'Pizza|Sushi|Burger|Salad';
}
