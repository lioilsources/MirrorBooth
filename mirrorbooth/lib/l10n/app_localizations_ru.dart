// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get filterNone => 'Нет';

  @override
  String get filterGlow => 'Сияние';

  @override
  String get filterSlim => 'Стройность';

  @override
  String get filterDoll => 'Кукла';

  @override
  String get filterChibi => 'Чиби';

  @override
  String get filterLips => 'Губы';

  @override
  String get filterBigNose => 'Нос';

  @override
  String get filterAlien => 'Пришелец';

  @override
  String get filterMelt => 'Плавка';

  @override
  String get filterBigEars => 'Уши';

  @override
  String get filterLongNeck => 'Шея';

  @override
  String get filterPencil => 'Карандаш';

  @override
  String get filterComic => 'Комикс';

  @override
  String get filterGlitch => 'Глитч';

  @override
  String get filterNeon => 'Неон';

  @override
  String get filterThermal => 'Тепло';

  @override
  String get filterOil => 'Масло';

  @override
  String get filterCrt => 'ЭЛТ';

  @override
  String get filterPopArt => 'Поп';

  @override
  String get filterVampire => 'Вампир';

  @override
  String get filterZombie => 'Зомби';

  @override
  String get filterGhost => 'Призрак';

  @override
  String get filterDemon => 'Демон';

  @override
  String get filterCyborg => 'Киборг';

  @override
  String get filterFrozen => 'Мороз';

  @override
  String get collectionPretty => 'Красота';

  @override
  String get collectionUgly => 'Уродство';

  @override
  String get collectionArt => 'Арт';

  @override
  String get collectionFantasy => 'Фэнтези';

  @override
  String get audioEffectNone => 'Обычный';

  @override
  String get audioEffectChiptune => '8 бит';

  @override
  String get audioEffectSlowMo => 'Медленно';

  @override
  String get audioEffectChipmunk => 'Бурундук';

  @override
  String get audioEffectEcho => 'Эхо';

  @override
  String get audioEffectUnderwater => 'Под водой';

  @override
  String get audioEffectRobot => 'Робот';

  @override
  String get audioEffectReverse => 'Задом наперёд';

  @override
  String get mirrorSideLeftShort => 'Л';

  @override
  String get mirrorSideRightShort => 'П';

  @override
  String get mirrorSideLeft => 'Слева';

  @override
  String get mirrorSideRight => 'Справа';

  @override
  String get lensFront => 'ПЕРЕДНЯЯ';

  @override
  String get lensBack => 'ЗАДНЯЯ';

  @override
  String get photoSaveFailedTitle => 'Не удалось сохранить фото';

  @override
  String get ok => 'ОК';

  @override
  String get galleryAccessDenied => 'Доступ к медиатеке запрещён.';

  @override
  String get galleryNotEnoughSpace => 'Недостаточно места.';

  @override
  String get galleryUnsupportedFormat => 'Этот формат файла не поддерживается.';

  @override
  String get genericError => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String shaderLoadError(String error) {
    return 'Не удалось загрузить фильтры: $error';
  }

  @override
  String get cameraPermissionDenied => 'Нет доступа к камере';

  @override
  String get noCamerasAvailable => 'Камеры недоступны';

  @override
  String get cameraStartFailed => 'Не удалось запустить камеру.';

  @override
  String get controlsHint => 'тянуть = повернуть  •  ⊙ = фото  •  ● = видео';

  @override
  String get controlsHintVolume => 'громкость = фото  •  удерживать = видео';

  @override
  String collectionUnlocked(String collection) {
    return 'Коллекция «$collection» открыта ✓';
  }

  @override
  String collectionFilters(String collection) {
    return 'Фильтры «$collection»';
  }

  @override
  String get paywallPreviewFree =>
      'Предпросмотр бесплатный. Откройте коллекцию, чтобы сохранять фото и видео.';

  @override
  String get storeUnavailable => 'Магазин недоступен';

  @override
  String get loadingPrice => 'Загрузка цены…';

  @override
  String unlockFor(String price) {
    return 'Открыть за $price';
  }

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get purchaseFailed => 'Покупка не удалась';

  @override
  String get discardVideoTitle => 'Удалить видео?';

  @override
  String get discardVideoBody => 'Эта запись ещё не сохранена в галерею.';

  @override
  String get keep => 'Оставить';

  @override
  String get discard => 'Удалить';

  @override
  String get processing => 'Обработка…';

  @override
  String get applyingEffect => 'Применяем эффект…';

  @override
  String get saved => 'Сохранено ✓';

  @override
  String get saveToCameraRoll => 'Сохранить в галерею';

  @override
  String get micPermissionRequired =>
      'Для записи видео нужен доступ к микрофону.';

  @override
  String get recordingTooShort =>
      'Запись слишком короткая — удерживайте дольше.';

  @override
  String get videoAssemblyFailed =>
      'Не удалось собрать видео. Попробуйте ещё раз.';

  @override
  String get audioEffectFailed => 'Не удалось применить звуковой эффект.';

  @override
  String get roomEntryPrompt =>
      'Введите ID комнаты, чтобы начать зеркальный видеозвонок.';

  @override
  String get roomIdHint => 'ID комнаты';

  @override
  String get mirrorSideTitle => 'Сторона зеркала';

  @override
  String get joinCall => 'Присоединиться';

  @override
  String failedToJoin(String error) {
    return 'Не удалось присоединиться: $error';
  }

  @override
  String get connecting => 'Подключение…';

  @override
  String get share => 'Поделиться';

  @override
  String shareMessage(String url) {
    return 'Сделано в Mirror Booth: $url';
  }

  @override
  String get a11yTakePhoto => 'Сделать фото';

  @override
  String get a11yStartRecording => 'Начать запись видео';

  @override
  String get a11yStopRecording => 'Остановить запись';

  @override
  String get a11ySwitchCamera => 'Сменить камеру';

  @override
  String get a11yMirrorAxis => 'Ось зеркала';

  @override
  String get a11yRotation => 'Поворот изображения';

  @override
  String a11yDegrees(int degrees) {
    return 'Градусов: $degrees';
  }

  @override
  String get a11yClose => 'Закрыть';

  @override
  String get a11yToggleLog => 'Показать или скрыть журнал';

  @override
  String unlockAllFor(String price) {
    return 'Все фильтры за $price';
  }
}
