# MirrorBooth — Real-Time Grafické Filtry (GLSL Fragment Shadery)

## Context

Přidáváme sadu GPU-akcelerovaných grafických filtrů aplikovaných živě na camera preview i na uložené fotky. Filtry běží jako GLSL fragment shadery na Impelleru (Flutter 3.x+), volitelné přes horizontální strip tlačítek ve spodní části obrazovky.

---

## Architektura

### Proč ne `AnimatedSampler`

`AnimatedSampler` z `flutter_shaders` zachytává child widget přes `OffsetLayer.toImageSync()`. `CameraPreview` interně používá `Texture` widget, jehož obsah (`TextureLayer`) se do tohoto offscreen renderu nezahrne — shader dostane prázdný/černý vstup.

**Fungující přístup:** `RepaintBoundary.toImage()` kameru zachytí správně (stejný mechanismus jako ukládání fotek). Ticker každý vsync snímek zavolá `toImage()`, výsledek jako `dart:ui.Image` pošle `CustomPainter`, ten přes shader překryje celý canvas.

### Pipeline

```
Camera → MirrorCanvas (CameraPreview) → RepaintBoundary
                                              │
                                    Ticker.toImage() ~60fps
                                              │
                                          ui.Image
                                              │
                                    CustomPaint(_FilterShaderPainter)
                                              │
                                        fragmentShader
                                              │
                                         Display
```

### Proč filtr funguje i na uložené fotce

`_canvasKey` RepaintBoundary v `mirror_preview_screen.dart` obaluje celý `FilteredMirrorCanvas`. Při focení `toImage()` zachytí Stack s `CustomPaint` overlayem — filtr je automaticky zapečen do JPEG bez extra kódu.

---

## Soubory

### Nové soubory

| Soubor | Účel |
|--------|------|
| `lib/core/mirror_filter.dart` | Enum `MirrorFilter` (none/pencil/comic/celShade/glitch/pixelArt) |
| `lib/core/shader_provider.dart` | Riverpod `FutureProvider<ShaderCache>` — načte všechny `FragmentProgram` jednou při startu |
| `lib/features/mirror_preview/filtered_mirror_canvas.dart` | `StatefulWidget` s Tickerem, `RepaintBoundary.toImage()`, `CustomPainter` + `_FilterShaderPainter` |
| `lib/features/mirror_preview/filter_strip.dart` | Horizontální `ListView` chip strip pro výběr filtru |
| `shaders/filter_pencil.frag` | Sobel edge detection → bílý papír + černé linky |
| `shaders/filter_comic.frag` | 4-úrovňová posterizace (black/red/yellow/white) + Sobel obrysy |
| `shaders/filter_cel_shade.frag` | 3-pásové toon shading (shadow/mid/highlight) + saturace + kontury |
| `shaders/filter_glitch.frag` | Animovaný RGB shift + scanline tearing + block displacement + šum |
| `shaders/filter_pixel_art.frag` | 6×6 px bloky + 3-bit kvantizace (7/7/3 kroků na kanál) |

### Upravené soubory

| Soubor | Změna |
|--------|-------|
| `pubspec.yaml` | Registrace 5 nových shader assetů pod `flutter: shaders:` |
| `mirror_preview_controller.dart` | `selectedFilter` pole v `MirrorPreviewState` + `setFilter()` metoda |
| `mirror_preview_screen.dart` | `shaderCacheProvider` watch, `MirrorCanvas` → `FilteredMirrorCanvas`, `FilterStrip` nad bottom controls |

---

## GLSL Uniform Contract

Všechny shadery sdílí stejné pořadí uniformů (Impeller vyžaduje přesné pořadí: samplery před floaty):

| Index | Dart | GLSL |
|-------|------|------|
| sampler 0 | `shader.setImageSampler(0, image)` | `uniform sampler2D uTexture;` |
| float 0 | `shader.setFloat(0, size.width)` | `uniform vec2 uResolution;` — x |
| float 1 | `shader.setFloat(1, size.height)` | `uniform vec2 uResolution;` — y |
| float 2 (glitch only) | `shader.setFloat(2, elapsedSeconds)` | `uniform float uTime;` |

`FlutterFragCoord()` a `size` jsou oba v logických pixelech → `uv = FlutterFragCoord().xy / uResolution` dá [0,1]×[0,1]. `toImage(pixelRatio: devicePixelRatio)` zachytí fyzické rozlišení, sampler normalizované UV zpracuje správně.

---

## Technické poznámky

- **Po změně `.frag` souboru:** nutný full restart (`flutter run`), hot-reload shadery nepřekompiluje.
- **`shaderCacheProvider`** je `FutureProvider` — loading spinner dokud se nenačtou všechny programy (~ < 1s při startu).
- **1-frame latence:** `toImage()` je async; `_capturing` flag zabraňuje hromadění volání. Při 30fps kameře efektivní update rate ~30fps.
- **Přechod filtrů:** `_frame` vždy obsahuje nefiltrovaný snímek (výstup `MirrorCanvas`) — nový shader se aplikuje okamžitě na další zachycený snímek.
- **Memory:** `_frame?.dispose()` před každou aktualizací zamezí GPU memory leakům.
