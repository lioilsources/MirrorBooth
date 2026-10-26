// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get filterNone => '없음';

  @override
  String get filterGlow => '글로우';

  @override
  String get filterSlim => '슬림';

  @override
  String get filterDoll => '인형';

  @override
  String get filterChibi => '치비';

  @override
  String get filterLips => '입술';

  @override
  String get filterBigNose => '코';

  @override
  String get filterAlien => '외계인';

  @override
  String get filterMelt => '녹아내림';

  @override
  String get filterBigEars => '귀';

  @override
  String get filterLongNeck => '목';

  @override
  String get filterPencil => '연필';

  @override
  String get filterComic => '코믹';

  @override
  String get filterGlitch => '글리치';

  @override
  String get filterNeon => '네온';

  @override
  String get filterThermal => '열화상';

  @override
  String get filterOil => '유화';

  @override
  String get filterCrt => 'CRT';

  @override
  String get filterPopArt => '팝';

  @override
  String get filterVampire => '뱀파이어';

  @override
  String get filterZombie => '좀비';

  @override
  String get filterGhost => '유령';

  @override
  String get filterDemon => '악마';

  @override
  String get filterCyborg => '사이보그';

  @override
  String get filterFrozen => '서리';

  @override
  String get collectionPretty => '예쁨';

  @override
  String get collectionUgly => '못난이';

  @override
  String get collectionArt => '아트';

  @override
  String get collectionFantasy => '판타지';

  @override
  String get audioEffectNone => '기본';

  @override
  String get audioEffectChiptune => '8비트';

  @override
  String get audioEffectSlowMo => '슬로우';

  @override
  String get audioEffectChipmunk => '다람쥐';

  @override
  String get audioEffectEcho => '에코';

  @override
  String get audioEffectUnderwater => '수중';

  @override
  String get audioEffectRobot => '로봇';

  @override
  String get audioEffectReverse => '거꾸로';

  @override
  String get mirrorSideLeftShort => '좌';

  @override
  String get mirrorSideRightShort => '우';

  @override
  String get mirrorSideLeft => '왼쪽';

  @override
  String get mirrorSideRight => '오른쪽';

  @override
  String get lensFront => '전면';

  @override
  String get lensBack => '후면';

  @override
  String get photoSaveFailedTitle => '사진을 저장할 수 없습니다';

  @override
  String get ok => '확인';

  @override
  String get galleryAccessDenied => '사진 보관함 접근이 거부되었습니다.';

  @override
  String get galleryNotEnoughSpace => '저장 공간이 부족합니다.';

  @override
  String get galleryUnsupportedFormat => '지원되지 않는 파일 형식입니다.';

  @override
  String get genericError => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String shaderLoadError(String error) {
    return '필터를 불러올 수 없습니다: $error';
  }

  @override
  String get cameraPermissionDenied => '카메라 권한이 거부되었습니다';

  @override
  String get noCamerasAvailable => '사용 가능한 카메라가 없습니다';

  @override
  String get cameraStartFailed => '카메라를 시작할 수 없습니다.';

  @override
  String get controlsHint => '드래그 = 회전  •  ⊙ = 사진  •  ● = 동영상';

  @override
  String get controlsHintVolume => '볼륨 = 사진  •  볼륨 길게 = 동영상';

  @override
  String collectionUnlocked(String collection) {
    return '$collection 컬렉션 잠금 해제됨 ✓';
  }

  @override
  String collectionFilters(String collection) {
    return '$collection 필터';
  }

  @override
  String get paywallPreviewFree => '미리보기는 무료입니다. 사진과 동영상을 저장하려면 잠금을 해제하세요.';

  @override
  String get storeUnavailable => '스토어를 사용할 수 없음';

  @override
  String get loadingPrice => '가격 불러오는 중…';

  @override
  String unlockFor(String price) {
    return '$price에 잠금 해제';
  }

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get purchaseFailed => '구매 실패';

  @override
  String get discardVideoTitle => '동영상을 삭제할까요?';

  @override
  String get discardVideoBody => '이 녹화는 카메라 롤에 저장되지 않았습니다.';

  @override
  String get keep => '유지';

  @override
  String get discard => '삭제';

  @override
  String get processing => '처리 중…';

  @override
  String get applyingEffect => '효과 적용 중…';

  @override
  String get saved => '저장됨 ✓';

  @override
  String get saveToCameraRoll => '카메라 롤에 저장';

  @override
  String get micPermissionRequired => '동영상을 녹화하려면 마이크 권한이 필요합니다.';

  @override
  String get recordingTooShort => '녹화가 너무 짧습니다. 더 길게 녹화하세요.';

  @override
  String get videoAssemblyFailed => '동영상을 만들지 못했습니다. 다시 시도해 주세요.';

  @override
  String get audioEffectFailed => '오디오 효과 적용에 실패했습니다.';

  @override
  String get roomEntryPrompt => '룸 ID를 입력해 미러 영상 통화를 시작하세요.';

  @override
  String get roomIdHint => '룸 ID';

  @override
  String get mirrorSideTitle => '미러 방향';

  @override
  String get joinCall => '통화 참여';

  @override
  String failedToJoin(String error) {
    return '참여 실패: $error';
  }

  @override
  String get connecting => '연결 중…';
}
