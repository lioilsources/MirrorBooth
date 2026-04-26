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

**Proč selhalo:** `CameraPreview` se vykresluje skrze platformovou GPU texturu
(SurfaceTexture na Androidu, IOSurface na iOS). Flutter compositor ji čte
přímo z GPU bez prostředníka. `RepaintBoundary.toImage()` ale platformové
textury **nezachytí** — výstupem je černý nebo prázdný obrázek.

```dart
// NEFUNGUJE pro CameraPreview:
final boundary = key.currentContext.findRenderObject() as RenderRepaintBoundary;
final image = await boundary.toImage(pixelRatio: 3.0);
// → black/empty image
```

**Řešení:** použít `controller.takePicture()` který si přímo z native vrstvy
vyžádá JPEG snapshot kamery. Mirror efekt se musí dopočítat softwarově
post-hoc.

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

## Diagnostika: on-screen debug overlay

Protože všechny předchozí silent failures byly skryté za chytaným
exception, finální verze přidává **debug overlay v levém horním rohu**
zobrazující posledních 8 událostí save flow:

```
TAP
takePicture()…
xfile: REC_2026….jpg
read 2847291 B
compose rot=0…
composed 412803 B
wrote temp
Gal.putImage OK ✓
```

Pokud něco selže, je hned vidět **kde**. Vypnutelné ikonkou broučka
vpravo nahoře. `debugPrint` paralelně do `flutter run` console pro release
build.

---

## Souhrn změn

| Soubor                                                    | Co se změnilo                                              |
|-----------------------------------------------------------|------------------------------------------------------------|
| `pubspec.yaml`                                            | + `gal`, `image`, `path_provider`                          |
| `ios/Runner/Info.plist`                                   | + `NSPhotoLibraryAddUsageDescription`                       |
| `lib/features/mirror_preview/mirror_preview_screen.dart`  | full rewrite save flow + isolate + debug overlay           |

## Architektura finálního save flow

```
TAP
  ↓
controller.takePicture()                    ← real camera frame, ne RepaintBoundary
  ↓
xfile.readAsBytes()                          → Uint8List (JPEG)
  ↓
compute(_processPhoto, _PhotoJob{           ← jediný isolate hop
  jpegBytes, sideIsLeft, displayAspect,        primitiva + Uint8List only
  flipForIos, rotateCcwDeg
})
  ├── img.decodeImage()                     ← CPU, ne dart:ui
  ├── img.flipHorizontal() (iOS only)
  ├── img.copyRotate() (landscape)
  ├── img.copyCrop() (display aspect)
  ├── img.copyCrop() + img.flipHorizontal() (mirror split)
  ├── img.compositeImage() × 2
  └── img.encodeJpg()                       → Uint8List
  ↓
File.writeAsBytes(tempDir + uniqueName)     ← path-based gal call
  ↓
Gal.putImage(tempFile.path)                  ← gal řeší permissions sám
  ↓
flash animation + temp file delete
```
