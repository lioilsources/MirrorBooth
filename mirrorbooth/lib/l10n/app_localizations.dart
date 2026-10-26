import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

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
    Locale('ar'),
    Locale('cs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('tr'),
  ];

  /// Filter chip: no filter
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get filterNone;

  /// Filter chip label, keep very short
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get filterGlow;

  /// No description provided for @filterSlim.
  ///
  /// In en, this message translates to:
  /// **'Slim'**
  String get filterSlim;

  /// No description provided for @filterDoll.
  ///
  /// In en, this message translates to:
  /// **'Doll'**
  String get filterDoll;

  /// No description provided for @filterChibi.
  ///
  /// In en, this message translates to:
  /// **'Chibi'**
  String get filterChibi;

  /// No description provided for @filterLips.
  ///
  /// In en, this message translates to:
  /// **'Lips'**
  String get filterLips;

  /// No description provided for @filterBigNose.
  ///
  /// In en, this message translates to:
  /// **'Nose'**
  String get filterBigNose;

  /// No description provided for @filterAlien.
  ///
  /// In en, this message translates to:
  /// **'Alien'**
  String get filterAlien;

  /// No description provided for @filterMelt.
  ///
  /// In en, this message translates to:
  /// **'Melt'**
  String get filterMelt;

  /// No description provided for @filterBigEars.
  ///
  /// In en, this message translates to:
  /// **'Ears'**
  String get filterBigEars;

  /// No description provided for @filterLongNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get filterLongNeck;

  /// No description provided for @filterPencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get filterPencil;

  /// No description provided for @filterComic.
  ///
  /// In en, this message translates to:
  /// **'Comic'**
  String get filterComic;

  /// No description provided for @filterGlitch.
  ///
  /// In en, this message translates to:
  /// **'Glitch'**
  String get filterGlitch;

  /// No description provided for @filterNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get filterNeon;

  /// No description provided for @filterThermal.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get filterThermal;

  /// No description provided for @filterOil.
  ///
  /// In en, this message translates to:
  /// **'Oil'**
  String get filterOil;

  /// No description provided for @filterCrt.
  ///
  /// In en, this message translates to:
  /// **'CRT'**
  String get filterCrt;

  /// No description provided for @filterPopArt.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get filterPopArt;

  /// No description provided for @filterVampire.
  ///
  /// In en, this message translates to:
  /// **'Vamp'**
  String get filterVampire;

  /// No description provided for @filterZombie.
  ///
  /// In en, this message translates to:
  /// **'Zombie'**
  String get filterZombie;

  /// No description provided for @filterGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost'**
  String get filterGhost;

  /// No description provided for @filterDemon.
  ///
  /// In en, this message translates to:
  /// **'Demon'**
  String get filterDemon;

  /// No description provided for @filterCyborg.
  ///
  /// In en, this message translates to:
  /// **'Cyborg'**
  String get filterCyborg;

  /// No description provided for @filterFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frost'**
  String get filterFrozen;

  /// Filter collection name (tab, shown uppercased)
  ///
  /// In en, this message translates to:
  /// **'Pretty'**
  String get collectionPretty;

  /// No description provided for @collectionUgly.
  ///
  /// In en, this message translates to:
  /// **'Ugly'**
  String get collectionUgly;

  /// No description provided for @collectionArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get collectionArt;

  /// No description provided for @collectionFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get collectionFantasy;

  /// Audio effect chip: original sound
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get audioEffectNone;

  /// No description provided for @audioEffectChiptune.
  ///
  /// In en, this message translates to:
  /// **'8-bit'**
  String get audioEffectChiptune;

  /// No description provided for @audioEffectSlowMo.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get audioEffectSlowMo;

  /// No description provided for @audioEffectChipmunk.
  ///
  /// In en, this message translates to:
  /// **'Chipmunk'**
  String get audioEffectChipmunk;

  /// No description provided for @audioEffectEcho.
  ///
  /// In en, this message translates to:
  /// **'Echo'**
  String get audioEffectEcho;

  /// No description provided for @audioEffectUnderwater.
  ///
  /// In en, this message translates to:
  /// **'Underwater'**
  String get audioEffectUnderwater;

  /// No description provided for @audioEffectRobot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get audioEffectRobot;

  /// No description provided for @audioEffectReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get audioEffectReverse;

  /// Very short label for the left mirror side on a small round button
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get mirrorSideLeftShort;

  /// Very short label for the right mirror side on a small round button
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get mirrorSideRightShort;

  /// No description provided for @mirrorSideLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get mirrorSideLeft;

  /// No description provided for @mirrorSideRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get mirrorSideRight;

  /// Tiny uppercase label on the camera switch button: front camera active
  ///
  /// In en, this message translates to:
  /// **'FRONT'**
  String get lensFront;

  /// Tiny uppercase label on the camera switch button: back camera active
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get lensBack;

  /// No description provided for @photoSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not save photo'**
  String get photoSaveFailedTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @galleryAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access to the photo library was denied.'**
  String get galleryAccessDenied;

  /// No description provided for @galleryNotEnoughSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space.'**
  String get galleryNotEnoughSpace;

  /// No description provided for @galleryUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This file format is not supported.'**
  String get galleryUnsupportedFormat;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @shaderLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load filters: {error}'**
  String shaderLoadError(String error);

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// No description provided for @noCamerasAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cameras available'**
  String get noCamerasAvailable;

  /// No description provided for @cameraStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the camera.'**
  String get cameraStartFailed;

  /// Gesture hint in the info overlay; keep the symbols ⊙ and ●
  ///
  /// In en, this message translates to:
  /// **'drag = rotate  •  ⊙ = photo  •  ● = video'**
  String get controlsHint;

  /// Hardware volume-button hint
  ///
  /// In en, this message translates to:
  /// **'vol = photo  •  vol hold = video'**
  String get controlsHintVolume;

  /// No description provided for @collectionUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{collection} collection unlocked ✓'**
  String collectionUnlocked(String collection);

  /// Paywall sheet title
  ///
  /// In en, this message translates to:
  /// **'{collection} filters'**
  String collectionFilters(String collection);

  /// No description provided for @paywallPreviewFree.
  ///
  /// In en, this message translates to:
  /// **'Preview is free. Unlock to save photos and videos.'**
  String get paywallPreviewFree;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store unavailable'**
  String get storeUnavailable;

  /// No description provided for @loadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Loading price…'**
  String get loadingPrice;

  /// Purchase button
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String unlockFor(String price);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// No description provided for @discardVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard video?'**
  String get discardVideoTitle;

  /// No description provided for @discardVideoBody.
  ///
  /// In en, this message translates to:
  /// **'This recording has not been saved to your camera roll.'**
  String get discardVideoBody;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @applyingEffect.
  ///
  /// In en, this message translates to:
  /// **'Applying effect…'**
  String get applyingEffect;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved ✓'**
  String get saved;

  /// No description provided for @saveToCameraRoll.
  ///
  /// In en, this message translates to:
  /// **'Save to Camera Roll'**
  String get saveToCameraRoll;

  /// No description provided for @micPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required for video recording.'**
  String get micPermissionRequired;

  /// No description provided for @recordingTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording too short — hold longer.'**
  String get recordingTooShort;

  /// No description provided for @videoAssemblyFailed.
  ///
  /// In en, this message translates to:
  /// **'Video assembly failed. Please try again.'**
  String get videoAssemblyFailed;

  /// No description provided for @audioEffectFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio effect failed.'**
  String get audioEffectFailed;

  /// No description provided for @roomEntryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a room ID to start a mirrored video call.'**
  String get roomEntryPrompt;

  /// No description provided for @roomIdHint.
  ///
  /// In en, this message translates to:
  /// **'Room ID'**
  String get roomIdHint;

  /// No description provided for @mirrorSideTitle.
  ///
  /// In en, this message translates to:
  /// **'Mirror side'**
  String get mirrorSideTitle;

  /// No description provided for @joinCall.
  ///
  /// In en, this message translates to:
  /// **'Join call'**
  String get joinCall;

  /// No description provided for @failedToJoin.
  ///
  /// In en, this message translates to:
  /// **'Failed to join: {error}'**
  String failedToJoin(String error);

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'cs',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
