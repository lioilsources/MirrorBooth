# Fix: Photo → Real-time Video + Alignment

## Problém

Po prvním spuštění aplikace kamera zobrazovala statické obrázky místo živého videa.

### Příčina: AnimatedSampler nemůže zachytit External Texture

Původní `MirrorCanvas` používal `flutter_shaders` `AnimatedSampler`:

```
CameraPreview (external texture / SurfaceTexture)
  → AnimatedSampler.toImageSync()   ← PROBLÉM
  → FragmentShader (mirror.frag)
  → display
```

`AnimatedSampler` volá `RenderRepaintBoundary.toImageSync()` na každý vsync.
Na Androidu se snapshot external texture (SurfaceTexture z CameraX) nepropaguje
do snapshotu — vrátí prázdný nebo zmrzlý `ui.Image`. Výsledek: statické fotky.

---

## Fix 1: Photo → Video (commit 1)

**Soubor:** `lib/features/mirror_preview/mirror_canvas.dart`

Nahradit `AnimatedSampler` + shader za **dva `CameraPreview` widgety** sdílející
stejný `textureId`. Flutter compositor čte GPU texturu přímo bez snapshotování.

```
CameraPreview (external texture)  ←─── oba panely čtou stejnou GPU texturu
  → OverflowBox (posunutí)
  → ClipRect (ořez na panel)
  → Transform.flip (jeden panel)
  → display                         ← plynulé 60fps ✓
```

### Jak funguje OverflowBox + ClipRect + Transform.flip

Každý panel je `W/2` pixels wide. Camera je `camW` pixels wide (vypočítáno
pomocí BoxFit.cover sémantiky pro celou obrazovku).

```
┌─── panel W/2 ──────┐┌─── panel W/2 ──────┐
│  ClipRect          ││  ClipRect           │
│  ┌── camW ───────  ││  ┌── camW ───────   │
│  │ OverflowBox   │ ││  │ OverflowBox    │  │
│  │ alignment=(ax)│ ││  │ alignment=(ax) │  │
│  │ CameraPreview │ ││  │ CameraPreview  │  │
│  └───────────────  ││  └────────────────  │
│   no flip          ││   Transform.flip    │
└────────────────────┘└────────────────────┘
```

### Cover-size výpočet

```dart
final portraitAspect = 1.0 / controller.value.aspectRatio;
final fullW = panelW * 2;
double camW, camH;
if (fullW / panelH > portraitAspect) {
  camW = fullW;
  camH = fullW / portraitAspect;
} else {
  camH = panelH;
  camW = panelH * portraitAspect;
}
```

---

## Fix 2: Alignment — nos na švu (commit 2)

Po Fix 1 se obě půlky nespojovaly uprostřed — nos obličeje se zobrazoval
na krajích obrazovky místo na švu.

### Příčina: špatné znaménko v alignment výpočtu

OverflowBox používá tuto formuli pro pozici dítěte:
```
child_left = (panelW − camW) × (1 + alignX) / 2
```

Cíl: nos (camera center = `camW/2`) musí být přesně na švu (pravý okraj levého panelu).
→ `child_left = panelW − camW/2`

Správné `alignX`:
```
alignX = −panelW / (camW − panelW)     ← pro side=left (záporné)
alignX = +panelW / (camW − panelW)     ← pro side=right (kladné)
```

Původní kód měl znaménka **přehozená** (`+` pro left, `−` pro right), takže
oba panely ukazovaly pravý okraj kamery na švu místo středu obličeje.

```dart
// ŠPATNĚ (commit 1):
final double alignX = side.isLeft
    ? (panelW / denominator).clamp(-1.0, 1.0)   // + → pravý okraj na švu
    : -(panelW / denominator).clamp(-1.0, 1.0);  // − → špatná strana

// SPRÁVNĚ (commit 2):
final double alignX = side.isLeft
    ? -(panelW / denominator).clamp(-1.0, 1.0)  // − → nos přesně na švu ✓
    : (panelW / denominator).clamp(-1.0, 1.0);  // + → nos přesně na švu ✓
```

### Výsledek po obou fixech

```
Levý panel (side=left):      Pravý panel (side=left):
camera x = (camW/2−W/2)      camera x = (camW/2−W/2)
         .. camW/2            ..camW/2, překlopen
         │                   │
         └── šev = nos ───────┘
```

Pixel na švu: `camera_x = camW/2` (střed obličeje) na obou stranách → bezešvé spojení ✓
