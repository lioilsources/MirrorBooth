# Fix: Tap-to-save photo to gallery

## Problém

Tap kdekoli na obrazovce měl uložit aktuální mirror efekt jako fotku do
galerie. První tři pokusy selhaly tiše — žádná fotka se v galerii neobjevila,
často ani žádný error dialog. Cesta k pracujícímu řešení odhalila několik
nezávislých příčin, které musely být opraveny současně.

---

## Fix 1: Nepoužívat `RepaintBoundary.toImage()` pro CameraPreview

**První pokus:** obalit `MirrorCanvas` v `RepaintBoundary` a zachytit ho přes
`RenderRepaintBoundary.toImage()` → PNG → `Gal.putImageBytes`.

**Proč selhalo (Android):** `CameraPreview` se vykresluje skrze platformovou GPU texturu
(SurfaceTexture na Androidu). Flutter compositor ji čte
přímo z GPU bez prostředníka. `RepaintBoundary.toImage()` na Androidu platformové
textury **nezachytí** — výstupem je černý nebo prázdný obrázek.

```dart
// NEFUNGUJE pro CameraPreview na Androidu:
final boundary = key.currentContext.findRenderObject() as RenderRepaintBoundary;
final image = await boundary.toImage(pixelRatio: 3.0);
// → black/empty image
```

**Řešení (fáze 1):** použít `controller.takePicture()` který si přímo z native vrstvy
vyžádá JPEG snapshot kamery. Mirror efekt se musí dopočítat softwarově
post-hoc.

> **Poznámka (viz Fix 9):** Na iOS s Metal/Impeller renderem `RepaintBoundary.toImage()`
> platformové textury (IOSurface) **zachytí spolehlivě**. Finální architektura
> proto tuto cestu na iOS znovu využívá.

```dart
final xfile = await state.controller!.takePicture();
final rawBytes = await xfile.readAsBytes();
// → real camera frame bytes ✓
```

---

## Fix 2: GPU→CPU readback (`toByteData(png)`) padá s Impellerem

**Druhý pokus:** dekódovat JPEG s `ui.instantiateImageCodec`, složit mirror
efekt na `dart:ui` Canvas přes `PictureRecorder`, exportovat PNG přes
`ui.Image.toByteData(format: png)`.

**Proč selhalo:** Flutter na Androidu defaultně používá Impeller renderer.
GPU→CPU readback (`Picture.toImage().toByteData()`) na Impelleru často vrací
`null` nebo prázdné byty bez vyhození výjimky.

```dart
// NESPOLEHLIVÉ na Androidu/Impelleru:
final image = await recorder.endRecording().toImage(W, H);
final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
// → null  →  silent failure
```

**Řešení:** veškerý compositing přesunout na CPU s `image: ^4.2.0` balíčkem.
Nepoužívat `dart:ui` Canvas — pouze pixel ops na čistě Dart datech.

```dart
import 'package:image/image.dart' as img;

var src = img.decodeImage(jpegBytes);   // EXIF rotation handled
src = img.flipHorizontal(src);
src = img.copyCrop(src, x: ..., y: ..., width: ..., height: ...);
final outBytes = img.encodeJpg(output, quality: 92);
// → reliable on every device ✓
```

---

## Fix 3: `compute()` boundary — předávat jen primitiva + Uint8List

**Třetí pokus:** dva `compute()` calls — první dekódoval JPEG, druhý
provedl compositing. Mezi nimi se předával `img.Image`.

**Proč selhalo:** `compute()` interně používá `Isolate.spawn` a
`SendPort.send`. Custom Dart objekty (`img.Image`, custom args třídy s
non-trivial fields) **se nepřenášejí spolehlivě**. Některé verze Flutteru
to dělají hlubokou kopií, jiné prostě selžou tiše uvnitř isolate.

```dart
// NESPOLEHLIVÉ:
final decoded = await compute(_decode, bytes);   // returns img.Image
final composed = await compute(_compose, _Args(decoded, ...));
// _Args contains img.Image  →  may fail silently
```

**Řešení:** **jediné** `compute()` volání. Argument je třída obsahující
**jen primitiva a `Uint8List`** (oba jsou nativně transferovatelné). Veškerá
logika včetně decode + composite + encode běží v isolate.

```dart
class _PhotoJob {
  final Uint8List jpegBytes;          // nativně transferovatelné
  final bool sideIsLeft;
  final double displayAspect;
  final bool flipForIos;
  final int rotateCcwDeg;
  // žádné img.Image, žádné komplexní typy
}

final outBytes = await compute(_processPhoto, job);  // Uint8List → Uint8List
```

---

## Fix 4: `Gal.putImageBytes` přes method channel — použij file path

**Čtvrtý pokus:** finální `outBytes` (PNG) předat přes
`Gal.putImageBytes(bytes)`.

**Proč selhalo:** velký byte array (>1 MB) přes Flutter method channel je
nespolehlivý — některé Android zařízení časují nebo zahazují. Plus PNG je
zbytečně velký pro fotku.

**Řešení:** zapsat do temp souboru přes `path_provider` a uložit přes
`Gal.putImage(path)` (předává jen string path nativně).

```dart
final dir = await getTemporaryDirectory();
final tempFile = File('${dir.path}/mb_${ts}.jpg');
await tempFile.writeAsBytes(outBytes);
await Gal.putImage(tempFile.path);   // path-based ✓
tempFile.delete().ignore();
```

---

## Fix 5: `Permission.storage` na Androidu 13+ blokovala save

**Pátý pokus** (po Fix 1–4 fotky stále nešly): někdo přidal preventivní
`Permission.storage.request()` před `Gal.putImage`.

**Proč selhalo:** `Permission.storage` je **na Androidu 13+ (API 33)
deprecated** — Google ji rozdělil na `Permission.photos`,
`Permission.videos`, `Permission.audio`. Volání `Permission.storage.request()`
na novém Androidu vrací `PermissionStatus.denied` bez zobrazení dialogu →
celý save flow se přeskočí.

```dart
// ŠPATNĚ — vždy false na Android 13+:
if (await Permission.storage.request().isGranted) {
  await Gal.putImage(tempFile.path);
} else {
  _showError('Storage permission denied');
}
```

**Řešení:** `gal` 1.9+ si interně volá `requestAccess` přesně podle
platformy a verze (PHPhotoLibrary na iOS, MediaStore na Androidu 10+,
`WRITE_EXTERNAL_STORAGE` na starších). Manuální check je zbytečný a škodlivý.

```dart
// SPRÁVNĚ — gal řeší permissions sám:
await Gal.putImage(tempFile.path);
```

iOS ale stále potřebuje **`NSPhotoLibraryAddUsageDescription`** v
`Info.plist` (jinak iOS 14+ zabije aplikaci s entitlement crash):

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>MirrorBooth saves your mirror photo to the photo library.</string>
```

---

## Fix 6: GestureDetector hit testing přes inner transformy

**Šestý pokus:** v rámci landscape-mode iterace byl `MirrorCanvas` obalen
ve vnějším `Transform.rotate` + `Transform.scale` + `OverflowBox`. Tap
přestal pronikat.

**Proč selhalo:** `OverflowBox` s `maxWidth: double.infinity` má hit-test
problémy — Flutter neví, na jakou plochu má hit-testovat. `Transform`
sice transformuje hit pozice, ale v kombinaci s nekonečným OverflowBoxem
může hit-test "spadnout do prázdna".

**Řešení:** přesunout `GestureDetector` mimo všechny transformy jako
top-level `Positioned.fill` ve Stacku, **pod** controly (které jsou
v Stacku posledně → on top → captureují svoje tapy první). Použít
`HitTestBehavior.opaque` aby zachytil tapy i na transparentní ploše.

```dart
return Stack(children: [
  MirrorCanvas(...),                              // background
  Positioned.fill(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,           // catch even transparent area
      onTap: _captureAndSave,
    ),
  ),
  // controls (last = on top, capture their own taps first)
  Positioned(bottom: 60, child: SideToggleButton(...)),
  Positioned(top: 16, right: 20, child: _CallButton()),
]);
```

---

## Fix 7: `displayAspect` byl height/width místo width/height

Při refaktoringu si někdo prohodil pořadí v `mq.size.width / mq.size.height`
na `mq.size.height / mq.size.width`. Crop math v `_processPhoto` to
interpretovala jako landscape display a ořezala kameru úplně mimo obličej.

```dart
// ŠPATNĚ:
final displayAspect = mq.size.height / mq.size.width;   // > 1 → "landscape"

// SPRÁVNĚ:
final displayAspect = mq.size.width / mq.size.height;   // < 1 → portrait ✓
```

---

## Fix 8: Front camera flip — iOS vs Android

`takePicture()` se chová na obou platformách jinak:

| Platforma | Live preview               | `takePicture()` výstup       |
|-----------|----------------------------|------------------------------|
| iOS       | Mirrored (jako zrcadlo)    | Raw sensor (NE-mirrored)     |
| Android   | Mirrored                   | Mirrored (matches preview)   |

Aby se uložená fotka shodovala s tím, co uživatel viděl v preview, musíme
na iOS zdroj **horizontálně překlopit** před compositingem. Na Androidu ne.

```dart
if (Platform.isIOS) src = img.flipHorizontal(src);
```

---

## Fix 9: iOS — `permission_handler` macros chybějí v Podfile

**Symptom:** kamera vždy vrací `PermissionStatus.denied` i po schválení
dialogu. Error "Camera permission denied" se zobrazí hned při startu.

**Příčina:** `permission_handler` plugin pro iOS je zkompilovaný s feature
flags. Bez explicitního opt-in v `GCC_PREPROCESSOR_DEFINITIONS` v Podfile
plugin při buildu vyřadí celou implementaci dané permission — vrací vždy
`denied` bez ohledu na `Info.plist` nebo dialog.

**Řešení:** do `post_install` bloku Podfile přidat preprocessor definice pro
každou permission, kterou aplikace používá:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_PHOTOS_ADD_ONLY=1',
      ]
    end
  end
end
```

Po změně nutno spustit `pod install` (ne jen `flutter pub get`).

---

## Fix 10: iOS 13 — chybí `NSPhotoLibraryUsageDescription`

**Symptom:** `Gal.putImage` crashi na iOS 13 zařízení s:
`"This app has crashed because it attempted to access privacy-sensitive data
without a usage description."`

**Příčina:** Pro iOS 14+ stačí `NSPhotoLibraryAddUsageDescription` (write-only
access). Ale pro iOS 13 (minimum deployment target projektu = 13.0) API ještě
nezná `.addOnly` access level — potřebuje plnou `NSPhotoLibraryUsageDescription`.

**Řešení:** přidat oba klíče do `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>MirrorBooth saves your mirror photo to the photo library.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MirrorBooth saves your mirror photo to the photo library.</string>
```

---

## Fix 11: Compositing neodpovídal preview — přechod na `RepaintBoundary.toImage()`

**Symptom (iOS):** uložená fotka neodpovídala tomu, co bylo na obrazovce.
Dvě poloviny image neseděly na spoji.

**Příčina:** `_processPhoto` pipeline měla několik provázaných problémů:
1. `img.decodeImage()` v balíčku `image` 4.x **neaplikuje EXIF orientaci
   automaticky** — pixely zůstávají v nativní landscape orientaci senzoru.
   Bez explicitního `img.bakeOrientation()` se obraz zpracovával nastojato
   a split probíhal na špatné ose (nahoře/dole místo vlevo/vpravo).
2. Jakákoli drobná odchylka v `displayAspect`, crop math nebo pixel rounding
   způsobila posunutí split bodu mimo střed obličeje.

```dart
// ŠPATNĚ — EXIF se neaplikuje automaticky:
var src = img.decodeImage(jpegBytes);
// src je stále v landscape orientaci senzoru!

// SPRÁVNĚ by bylo:
src = img.bakeOrientation(src);  // nutné volat explicitně
```

**Finální řešení:** na iOS s Metal/Impeller renderem
`RepaintBoundary.toImage()` **zachytí i platformové IOSurface textury**
(na rozdíl od Androidu, kde to nefunguje). Proto celý `_processPhoto`
pipeline byl nahrazen přímým screenshotem widgetu — zaručeně pixel-perfect
shoda s preview, nulová matematika orientací/cropů.

```dart
final boundary =
    _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
final pixelRatio = MediaQuery.of(context).devicePixelRatio;
final uiImage = await boundary.toImage(pixelRatio: pixelRatio);
final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
// → encode to JPEG in compute isolate
```

Seam indicator (bílá čára uprostřed) je umístěn **mimo** `RepaintBoundary`
ve Stacku — do uložené fotky se nedostane.

> **Import:** `RenderRepaintBoundary` vyžaduje explicitní
> `import 'package:flutter/rendering.dart';` — přes `material.dart` samo
> se nevytáhne při buildu.

---

## Diagnostika: on-screen debug overlay

Protože všechny předchozí silent failures byly skryté za chytaným
exception, finální verze přidává **debug overlay v levém horním rohu**
zobrazující posledních 8 událostí save flow:

```
TAP
capturing 1179×2556…
captured 1179×2556
encoding JPEG…
encoded 412803 B
wrote temp
Gal.putImage OK ✓
```

Pokud něco selže, je hned vidět **kde**. Vypnutelné ikonkou broučka
vpravo nahoře. `debugPrint` paralelně do `flutter run` console.

---

## Souhrn změn

| Soubor                                                    | Co se změnilo                                                         |
|-----------------------------------------------------------|-----------------------------------------------------------------------|
| `pubspec.yaml`                                            | + `gal`, `image`, `path_provider`                                     |
| `ios/Runner/Info.plist`                                   | + `NSPhotoLibraryAddUsageDescription`, + `NSPhotoLibraryUsageDescription` |
| `ios/Podfile`                                             | + `PERMISSION_CAMERA/MICROPHONE/PHOTOS/PHOTOS_ADD_ONLY` macros        |
| `lib/features/mirror_preview/mirror_preview_screen.dart`  | rewrite save flow: RepaintBoundary screenshot + compute JPEG encode   |

---

## Architektura finálního save flow (iOS)

```
TAP
  ↓
RepaintBoundary.toImage(pixelRatio)     ← screenshot MirrorCanvas widgetu
  ↓                                       pixel-perfect shoda s preview
uiImage.toByteData(rawRgba)             ← RGBA bytes (na UI thread)
  ↓
compute(_encodeToJpeg, _EncodeJob{      ← izolát: jen Uint8List + int primitiva
  rgbaBytes, width, height
})
  └── img.Image.fromBytes(rgba)
  └── img.encodeJpg(quality: 92)        → Uint8List
  ↓
File.writeAsBytes(tempDir/mb_*.jpg)     ← path-based gal call
  ↓
Gal.putImage(tempFile.path)             ← gal řeší iOS permissions sám
  ↓
flash animation + temp file delete
```
