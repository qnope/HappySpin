import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @wheelColors.
  ///
  /// In fr, this message translates to:
  /// **'Couleurs de la roue'**
  String get wheelColors;

  /// No description provided for @paletteFestive.
  ///
  /// In fr, this message translates to:
  /// **'Festif'**
  String get paletteFestive;

  /// No description provided for @paletteOcean.
  ///
  /// In fr, this message translates to:
  /// **'Océan'**
  String get paletteOcean;

  /// No description provided for @paletteForest.
  ///
  /// In fr, this message translates to:
  /// **'Forêt'**
  String get paletteForest;

  /// No description provided for @paletteCandy.
  ///
  /// In fr, this message translates to:
  /// **'Bonbon'**
  String get paletteCandy;

  /// No description provided for @choicesSection.
  ///
  /// In fr, this message translates to:
  /// **'Choix'**
  String get choicesSection;

  /// No description provided for @weightedChoices.
  ///
  /// In fr, this message translates to:
  /// **'Donner un poids aux choix'**
  String get weightedChoices;

  /// No description provided for @weightedChoicesHint.
  ///
  /// In fr, this message translates to:
  /// **'Un choix plus lourd a une plus grande part de la roue et plus de chances de sortir.'**
  String get weightedChoicesHint;

  /// No description provided for @elimination.
  ///
  /// In fr, this message translates to:
  /// **'Mode élimination'**
  String get elimination;

  /// No description provided for @eliminationHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque tirage élimine le choix tiré, et le dernier qui reste l\'emporte.'**
  String get eliminationHint;

  /// No description provided for @confirmElimination.
  ///
  /// In fr, this message translates to:
  /// **'Demander avant de retirer'**
  String get confirmElimination;

  /// No description provided for @confirmEliminationHint.
  ///
  /// In fr, this message translates to:
  /// **'Après chaque tirage, tu choisis de garder le choix ou de le sortir de la roue.'**
  String get confirmEliminationHint;

  /// No description provided for @soundsSection.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get soundsSection;

  /// No description provided for @sounds.
  ///
  /// In fr, this message translates to:
  /// **'Sons et vibrations'**
  String get sounds;

  /// No description provided for @soundsHint.
  ///
  /// In fr, this message translates to:
  /// **'Un tic à chaque clou, un petit carillon à l\'arrêt et des vibrations sur mobile.'**
  String get soundsHint;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get languageDevice;

  /// No description provided for @newList.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle liste'**
  String get newList;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @renameList.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la liste'**
  String get renameList;

  /// No description provided for @rename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get rename;

  /// No description provided for @deleteListQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liste ?'**
  String get deleteListQuestion;

  /// No description provided for @deleteListWarning.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » et ses choix seront perdus.'**
  String deleteListWarning(String name);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteList.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liste'**
  String get deleteList;

  /// No description provided for @resultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le sort a choisi'**
  String get resultTitle;

  /// No description provided for @eliminatedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Éliminé'**
  String get eliminatedTitle;

  /// No description provided for @eliminateQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Éliminer ce choix ?'**
  String get eliminateQuestion;

  /// No description provided for @eliminationAsk.
  ///
  /// In fr, this message translates to:
  /// **'Le sortir de la roue pour les prochains tirages ?'**
  String get eliminationAsk;

  /// No description provided for @eliminationNote.
  ///
  /// In fr, this message translates to:
  /// **'Il sort de la roue pour les prochains tirages.'**
  String get eliminationNote;

  /// No description provided for @keepChoice.
  ///
  /// In fr, this message translates to:
  /// **'Le garder'**
  String get keepChoice;

  /// No description provided for @eliminateChoice.
  ///
  /// In fr, this message translates to:
  /// **'L\'éliminer'**
  String get eliminateChoice;

  /// No description provided for @great.
  ///
  /// In fr, this message translates to:
  /// **'Super !'**
  String get great;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get next;

  /// No description provided for @clearAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get clearAll;

  /// No description provided for @switchList.
  ///
  /// In fr, this message translates to:
  /// **'Changer de liste'**
  String get switchList;

  /// No description provided for @choiceCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun choix} =1{1 choix} other{{count} choix}}'**
  String choiceCount(int count);

  /// No description provided for @allChoicesOut.
  ///
  /// In fr, this message translates to:
  /// **'Tous les choix sont sortis.'**
  String get allChoicesOut;

  /// No description provided for @lastChoiceWins.
  ///
  /// In fr, this message translates to:
  /// **'« {choice} » l\'emporte !'**
  String lastChoiceWins(String choice);

  /// No description provided for @restoreAllWheel.
  ///
  /// In fr, this message translates to:
  /// **'Tout remettre dans la roue'**
  String get restoreAllWheel;

  /// No description provided for @addAtLeastTwo.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins 2 choix'**
  String get addAtLeastTwo;

  /// No description provided for @spin.
  ///
  /// In fr, this message translates to:
  /// **'Faire tourner'**
  String get spin;

  /// No description provided for @lessLikely.
  ///
  /// In fr, this message translates to:
  /// **'Moins de chances'**
  String get lessLikely;

  /// No description provided for @moreLikely.
  ///
  /// In fr, this message translates to:
  /// **'Plus de chances'**
  String get moreLikely;

  /// No description provided for @newChoice.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau choix'**
  String get newChoice;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @eliminatedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 choix éliminé} other{{count} choix éliminés}}'**
  String eliminatedCount(int count);

  /// No description provided for @restoreAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout remettre'**
  String get restoreAll;

  /// No description provided for @noChoicesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun choix pour le moment.'**
  String get noChoicesYet;

  /// No description provided for @eliminated.
  ///
  /// In fr, this message translates to:
  /// **'Éliminé'**
  String get eliminated;

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Remettre dans la roue'**
  String get restore;

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @percent.
  ///
  /// In fr, this message translates to:
  /// **'{value} %'**
  String percent(String value);

  /// No description provided for @listName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la liste'**
  String get listName;

  /// No description provided for @listNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Sorties du week-end'**
  String get listNameHint;

  /// No description provided for @defaultListName.
  ///
  /// In fr, this message translates to:
  /// **'Repas'**
  String get defaultListName;

  /// The choices of the first list, separated by |.
  ///
  /// In fr, this message translates to:
  /// **'Pizza|Sushi|Burger|Salade'**
  String get defaultChoices;

  /// No description provided for @choiceColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur du choix'**
  String get choiceColor;

  /// No description provided for @changeColor.
  ///
  /// In fr, this message translates to:
  /// **'Changer la couleur'**
  String get changeColor;

  /// No description provided for @restoreDefaultColor.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer par défaut'**
  String get restoreDefaultColor;

  /// No description provided for @renameChoice.
  ///
  /// In fr, this message translates to:
  /// **'Renommer le choix'**
  String get renameChoice;

  /// No description provided for @hue.
  ///
  /// In fr, this message translates to:
  /// **'Teinte'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In fr, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @lightness.
  ///
  /// In fr, this message translates to:
  /// **'Luminosité'**
  String get lightness;

  /// No description provided for @colorCode.
  ///
  /// In fr, this message translates to:
  /// **'Code couleur'**
  String get colorCode;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
