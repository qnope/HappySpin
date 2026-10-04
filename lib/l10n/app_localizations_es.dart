// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settings => 'Ajustes';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get wheelColors => 'Colores de la ruleta';

  @override
  String get paletteFestive => 'Festivo';

  @override
  String get paletteOcean => 'Océano';

  @override
  String get paletteForest => 'Bosque';

  @override
  String get paletteCandy => 'Caramelo';

  @override
  String get choicesSection => 'Opciones';

  @override
  String get weightedChoices => 'Dar peso a las opciones';

  @override
  String get weightedChoicesHint =>
      'Una opción con más peso ocupa más espacio en la ruleta y tiene más probabilidades de salir.';

  @override
  String get elimination => 'Modo eliminación';

  @override
  String get eliminationHint =>
      'La opción elegida sale de la ruleta en los siguientes giros, hasta que la vuelvas a poner.';

  @override
  String get confirmElimination => 'Preguntar antes de quitar';

  @override
  String get confirmEliminationHint =>
      'Después de cada giro, eliges si mantener la opción o sacarla de la ruleta.';

  @override
  String get soundsSection => 'Sonidos';

  @override
  String get sounds => 'Sonidos y vibraciones';

  @override
  String get soundsHint =>
      'Un clic en cada clavo, una campanita al parar y vibraciones en el móvil.';

  @override
  String get language => 'Idioma';

  @override
  String get languageDevice => 'Dispositivo';

  @override
  String get newList => 'Nueva lista';

  @override
  String get create => 'Crear';

  @override
  String get renameList => 'Renombrar la lista';

  @override
  String get rename => 'Renombrar';

  @override
  String get deleteListQuestion => '¿Eliminar la lista?';

  @override
  String deleteListWarning(String name) {
    return '«$name» y sus opciones se perderán.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteList => 'Eliminar la lista';

  @override
  String get resultTitle => 'La suerte ha elegido';

  @override
  String get eliminationAsk => '¿Sacarla de la ruleta para los próximos giros?';

  @override
  String get eliminationNote => 'Sale de la ruleta para los próximos giros.';

  @override
  String get keepChoice => 'Mantenerla';

  @override
  String get eliminateChoice => 'Sacarla';

  @override
  String get great => '¡Genial!';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get switchList => 'Cambiar de lista';

  @override
  String choiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opciones',
      one: '1 opción',
      zero: 'Ninguna opción',
    );
    return '$_temp0';
  }

  @override
  String get allChoicesOut => 'Todas las opciones han salido.';

  @override
  String onlyChoiceLeft(String choice) {
    return '¡Solo queda «$choice»!';
  }

  @override
  String get restoreAllWheel => 'Volver a poner todo en la ruleta';

  @override
  String get addAtLeastTwo => 'Añade al menos 2 opciones';

  @override
  String get spin => 'Girar';

  @override
  String get lessLikely => 'Menos probable';

  @override
  String get moreLikely => 'Más probable';

  @override
  String get newChoice => 'Nueva opción';

  @override
  String get add => 'Añadir';

  @override
  String eliminatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opciones fuera',
      one: '1 opción fuera',
    );
    return '$_temp0';
  }

  @override
  String get restoreAll => 'Volver a poner todo';

  @override
  String get noChoicesYet => 'Todavía no hay opciones.';

  @override
  String get eliminated => 'Fuera de la ruleta';

  @override
  String get restore => 'Volver a poner en la ruleta';

  @override
  String get remove => 'Quitar';

  @override
  String percent(String value) {
    return '$value %';
  }

  @override
  String get listName => 'Nombre de la lista';

  @override
  String get listNameHint => 'Ej.: Planes del finde';

  @override
  String get defaultListName => 'Comidas';

  @override
  String get defaultChoices => 'Pizza|Sushi|Hamburguesa|Ensalada';
}
