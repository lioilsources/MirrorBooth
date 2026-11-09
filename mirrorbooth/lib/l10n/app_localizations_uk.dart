// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get filterNone => 'Немає';

  @override
  String get filterGlow => 'Сяйво';

  @override
  String get filterSlim => 'Стрункість';

  @override
  String get filterDoll => 'Лялька';

  @override
  String get filterChibi => 'Чібі';

  @override
  String get filterLips => 'Губи';

  @override
  String get filterBigNose => 'Ніс';

  @override
  String get filterAlien => 'Прибулець';

  @override
  String get filterMelt => 'Танення';

  @override
  String get filterBigEars => 'Вуха';

  @override
  String get filterLongNeck => 'Шия';

  @override
  String get filterPencil => 'Олівець';

  @override
  String get filterComic => 'Комікс';

  @override
  String get filterGlitch => 'Глітч';

  @override
  String get filterNeon => 'Неон';

  @override
  String get filterThermal => 'Тепло';

  @override
  String get filterOil => 'Олія';

  @override
  String get filterCrt => 'ЕПТ';

  @override
  String get filterPopArt => 'Поп';

  @override
  String get filterVampire => 'Вампір';

  @override
  String get filterZombie => 'Зомбі';

  @override
  String get filterGhost => 'Привид';

  @override
  String get filterDemon => 'Демон';

  @override
  String get filterCyborg => 'Кіборг';

  @override
  String get filterFrozen => 'Мороз';

  @override
  String get collectionPretty => 'Краса';

  @override
  String get collectionUgly => 'Потворність';

  @override
  String get collectionArt => 'Арт';

  @override
  String get collectionFantasy => 'Фентезі';

  @override
  String get audioEffectNone => 'Звичайний';

  @override
  String get audioEffectChiptune => '8 біт';

  @override
  String get audioEffectSlowMo => 'Повільно';

  @override
  String get audioEffectChipmunk => 'Бурундук';

  @override
  String get audioEffectEcho => 'Луна';

  @override
  String get audioEffectUnderwater => 'Під водою';

  @override
  String get audioEffectRobot => 'Робот';

  @override
  String get audioEffectReverse => 'Задом наперед';

  @override
  String get mirrorSideLeftShort => 'Л';

  @override
  String get mirrorSideRightShort => 'П';

  @override
  String get mirrorSideLeft => 'Ліворуч';

  @override
  String get mirrorSideRight => 'Праворуч';

  @override
  String get lensFront => 'ПЕРЕДНЯ';

  @override
  String get lensBack => 'ЗАДНЯ';

  @override
  String get photoSaveFailedTitle => 'Не вдалося зберегти фото';

  @override
  String get ok => 'OK';

  @override
  String get galleryAccessDenied => 'Доступ до медіатеки заборонено.';

  @override
  String get galleryNotEnoughSpace => 'Недостатньо місця.';

  @override
  String get galleryUnsupportedFormat => 'Цей формат файлу не підтримується.';

  @override
  String get genericError => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String shaderLoadError(String error) {
    return 'Не вдалося завантажити фільтри: $error';
  }

  @override
  String get cameraPermissionDenied => 'Немає доступу до камери';

  @override
  String get noCamerasAvailable => 'Камери недоступні';

  @override
  String get cameraStartFailed => 'Не вдалося запустити камеру.';

  @override
  String get controlsHint => 'тягнути = повернути  •  ⊙ = фото  •  ● = відео';

  @override
  String get controlsHintVolume => 'гучність = фото  •  утримувати = відео';

  @override
  String collectionUnlocked(String collection) {
    return 'Колекцію «$collection» відкрито ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Фільтри «$collection»';
  }

  @override
  String get paywallPreviewFree =>
      'Попередній перегляд безкоштовний. Відкрийте колекцію, щоб зберігати фото й відео.';

  @override
  String get storeUnavailable => 'Магазин недоступний';

  @override
  String get loadingPrice => 'Завантаження ціни…';

  @override
  String unlockFor(String price) {
    return 'Відкрити за $price';
  }

  @override
  String get restorePurchases => 'Відновити покупки';

  @override
  String get purchaseFailed => 'Покупка не вдалася';

  @override
  String get discardVideoTitle => 'Видалити відео?';

  @override
  String get discardVideoBody => 'Цей запис ще не збережено в галерею.';

  @override
  String get keep => 'Залишити';

  @override
  String get discard => 'Видалити';

  @override
  String get processing => 'Обробка…';

  @override
  String get applyingEffect => 'Застосовуємо ефект…';

  @override
  String get saved => 'Збережено ✓';

  @override
  String get saveToCameraRoll => 'Зберегти в галерею';

  @override
  String get micPermissionRequired =>
      'Для запису відео потрібен доступ до мікрофона.';

  @override
  String get recordingTooShort => 'Запис закороткий — утримуйте довше.';

  @override
  String get videoAssemblyFailed =>
      'Не вдалося зібрати відео. Спробуйте ще раз.';

  @override
  String get audioEffectFailed => 'Не вдалося застосувати звуковий ефект.';

  @override
  String get roomEntryPrompt =>
      'Введіть ID кімнати, щоб почати дзеркальний відеодзвінок.';

  @override
  String get roomIdHint => 'ID кімнати';

  @override
  String get mirrorSideTitle => 'Бік дзеркала';

  @override
  String get joinCall => 'Приєднатися';

  @override
  String failedToJoin(String error) {
    return 'Не вдалося приєднатися: $error';
  }

  @override
  String get connecting => 'Підключення…';

  @override
  String get share => 'Поділитися';

  @override
  String shareMessage(String url) {
    return 'Створено в Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Зробити фото';

  @override
  String get a11yStartRecording => 'Почати запис відео';

  @override
  String get a11yStopRecording => 'Зупинити запис';

  @override
  String get a11ySwitchCamera => 'Змінити камеру';

  @override
  String get a11yMirrorAxis => 'Вісь дзеркала';

  @override
  String get a11yRotation => 'Поворот зображення';

  @override
  String a11yDegrees(int degrees) {
    return 'Градусів: $degrees';
  }

  @override
  String get a11yClose => 'Закрити';

  @override
  String get a11yToggleLog => 'Показати або сховати журнал';

  @override
  String unlockAllFor(String price) {
    return 'Усі фільтри за $price';
  }
}
