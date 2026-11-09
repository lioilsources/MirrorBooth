// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get filterNone => 'Inget';

  @override
  String get filterGlow => 'Glöd';

  @override
  String get filterSlim => 'Smal';

  @override
  String get filterDoll => 'Docka';

  @override
  String get filterChibi => 'Chibi';

  @override
  String get filterLips => 'Läppar';

  @override
  String get filterBigNose => 'Näsa';

  @override
  String get filterAlien => 'Utomjording';

  @override
  String get filterMelt => 'Smält';

  @override
  String get filterBigEars => 'Öron';

  @override
  String get filterLongNeck => 'Hals';

  @override
  String get filterPencil => 'Blyerts';

  @override
  String get filterComic => 'Serie';

  @override
  String get filterGlitch => 'Glitch';

  @override
  String get filterNeon => 'Neon';

  @override
  String get filterThermal => 'Värme';

  @override
  String get filterOil => 'Olja';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => 'Pop';

  @override
  String get filterVampire => 'Vampyr';

  @override
  String get filterZombie => 'Zombie';

  @override
  String get filterGhost => 'Spöke';

  @override
  String get filterDemon => 'Demon';

  @override
  String get filterCyborg => 'Cyborg';

  @override
  String get filterFrozen => 'Frost';

  @override
  String get collectionPretty => 'Snyggt';

  @override
  String get collectionUgly => 'Fult';

  @override
  String get collectionArt => 'Konst';

  @override
  String get collectionFantasy => 'Fantasy';

  @override
  String get audioEffectNone => 'Normal';

  @override
  String get audioEffectChiptune => '8-bit';

  @override
  String get audioEffectSlowMo => 'Slow motion';

  @override
  String get audioEffectChipmunk => 'Jordekorre';

  @override
  String get audioEffectEcho => 'Eko';

  @override
  String get audioEffectUnderwater => 'Under vatten';

  @override
  String get audioEffectRobot => 'Robot';

  @override
  String get audioEffectReverse => 'Baklänges';

  @override
  String get mirrorSideLeftShort => 'V';

  @override
  String get mirrorSideRightShort => 'H';

  @override
  String get mirrorSideLeft => 'Vänster';

  @override
  String get mirrorSideRight => 'Höger';

  @override
  String get lensFront => 'FRAM';

  @override
  String get lensBack => 'BAK';

  @override
  String get photoSaveFailedTitle => 'Det gick inte att spara bilden';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Åtkomst till bildbiblioteket nekades.';

  @override
  String get galleryNotEnoughSpace => 'Inte tillräckligt med lagringsutrymme.';

  @override
  String get galleryUnsupportedFormat => 'Filformatet stöds inte.';

  @override
  String get genericError => 'Något gick fel. Försök igen.';

  @override
  String shaderLoadError(String error) {
    return 'Det gick inte att läsa in filtren: $error';
  }

  @override
  String get cameraPermissionDenied => 'Kameraåtkomst nekad';

  @override
  String get noCamerasAvailable => 'Ingen kamera tillgänglig';

  @override
  String get cameraStartFailed => 'Det gick inte att starta kameran.';

  @override
  String get controlsHint => 'dra = rotera  •  ⊙ = bild  •  ● = video';

  @override
  String get controlsHintVolume => 'volym = bild  •  håll volym = video';

  @override
  String collectionUnlocked(String collection) {
    return 'Samlingen $collection upplåst ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Filter: $collection';
  }

  @override
  String get paywallPreviewFree =>
      'Förhandsvisningen är gratis. Lås upp för att spara bilder och videor.';

  @override
  String get storeUnavailable => 'Butiken är inte tillgänglig';

  @override
  String get loadingPrice => 'Hämtar pris…';

  @override
  String unlockFor(String price) {
    return 'Lås upp för $price';
  }

  @override
  String get restorePurchases => 'Återställ köp';

  @override
  String get purchaseFailed => 'Köpet misslyckades';

  @override
  String get discardVideoTitle => 'Släng videon?';

  @override
  String get discardVideoBody =>
      'Inspelningen har inte sparats i kamerarullen.';

  @override
  String get keep => 'Behåll';

  @override
  String get discard => 'Släng';

  @override
  String get processing => 'Bearbetar…';

  @override
  String get applyingEffect => 'Lägger på effekt…';

  @override
  String get saved => 'Sparad ✓';

  @override
  String get saveToCameraRoll => 'Spara i kamerarullen';

  @override
  String get micPermissionRequired =>
      'Mikrofonåtkomst krävs för videoinspelning.';

  @override
  String get recordingTooShort => 'Inspelningen är för kort – håll längre.';

  @override
  String get videoAssemblyFailed =>
      'Det gick inte att skapa videon. Försök igen.';

  @override
  String get audioEffectFailed => 'Ljudeffekten misslyckades.';

  @override
  String get roomEntryPrompt =>
      'Ange ett rums-ID för att starta ett speglat videosamtal.';

  @override
  String get roomIdHint => 'Rums-ID';

  @override
  String get mirrorSideTitle => 'Spegelsida';

  @override
  String get joinCall => 'Gå med i samtal';

  @override
  String failedToJoin(String error) {
    return 'Kunde inte gå med: $error';
  }

  @override
  String get connecting => 'Ansluter…';

  @override
  String get share => 'Dela';

  @override
  String shareMessage(String url) {
    return 'Gjord med Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Ta bild';

  @override
  String get a11yStartRecording => 'Starta videoinspelning';

  @override
  String get a11yStopRecording => 'Stoppa inspelning';

  @override
  String get a11ySwitchCamera => 'Byt kamera';

  @override
  String get a11yMirrorAxis => 'Spegelaxel';

  @override
  String get a11yRotation => 'Bildrotation';

  @override
  String a11yDegrees(int degrees) {
    return '$degrees grader';
  }

  @override
  String get a11yClose => 'Stäng';

  @override
  String get a11yToggleLog => 'Visa eller dölj loggen';

  @override
  String unlockAllFor(String price) {
    return 'Alla filter för $price';
  }
}
