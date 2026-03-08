# Genagotchi - Art Spec Base por Especie + Cosméticos 2D v1

Fecha: 2026-03-08  
Estado: Activo para producción de sprites  
Ámbito: MVP + escalado a coleccionables

## 1) Objetivo
Definir un contrato de arte 2D para que cada especie tenga una base reutilizable y permita equipar cosméticos por capas sin redibujar combinaciones completas.

Este documento está diseñado para que un agente/artista pueda producir múltiples opciones de sprite de forma consistente.

## 2) Principio de diseño
- La especie se dibuja una vez (base).
- Los cosméticos se dibujan aparte (slots).
- En runtime se componen por capas.
- Todas las piezas respetan la misma malla, anclas y orden de render.

## 3) Resolución y formato (obligatorio)
- Canvas estándar por frame: `128x128 px`.
- Fondo: transparente real (alpha), nunca checkerboard baked.
- Export: `.png`.
- Estilo de píxel: sin blur, sin antialias de subpixel.
- Margen de seguridad: mantener contenido dentro de `x: 8..120`, `y: 8..120`.
- Punto de apoyo visual en suelo (ground contact): cercano a `y = 108`.

## 4) Estructura de carpetas (obligatoria)
```text
assets/sprites/species/<species_id>/base/
assets/sprites/species/<species_id>/masks/
assets/sprites/species/<species_id>/meta/

assets/sprites/cosmetics/<slot_id>/<item_id>/
assets/sprites/cosmetics/<slot_id>/<item_id>/meta/
```

Ejemplo:
```text
assets/sprites/species/salchicha/base/base_idle_00.png
assets/sprites/species/salchicha/base/base_idle_01.png
assets/sprites/species/salchicha/masks/mask_primary_00.png
assets/sprites/species/salchicha/meta/species_manifest.json

assets/sprites/cosmetics/headwear/cap_red/item_idle_00.png
assets/sprites/cosmetics/headwear/cap_red/meta/item_manifest.json
```

## 5) Entregables mínimos por especie
- `base_idle_00.png` (mínimo absoluto MVP).
- Recomendado: `base_idle_00..03.png` (loop 4 frames).
- `species_manifest.json` con anclas y metadata.
- Opcional para recolor: `mask_primary_00..03.png`, `mask_secondary_00..03.png`.

## 6) Slots cosméticos estándar
Slots habilitados:
- `headwear`
- `eyewear`
- `face`
- `neckwear`
- `bodywear`
- `backwear`
- `tail`
- `aura`
- `fx_front`

Si una especie no usa un slot, igual se declara en manifest con `enabled: false`.

## 7) Orden de capas (render order)
Orden obligatorio de abajo hacia arriba:
1. `shadow`
2. `base_body_back`
3. `backwear`
4. `base_body_main`
5. `bodywear`
6. `neckwear`
7. `face`
8. `eyewear`
9. `headwear`
10. `tail`
11. `fx_front`
12. `aura`

Regla: todo ítem debe indicar su `slot_id` y respetar este orden global.

## 8) Sistema de anclas (anchor points)
Cada especie debe definir coordenadas (en pixel del canvas 128x128):
- `anchor_head`
- `anchor_face`
- `anchor_neck`
- `anchor_body_center`
- `anchor_back`
- `anchor_tail`
- `anchor_ground`

Convención de coordenadas:
- Origen `(0,0)` arriba-izquierda.
- `x` hacia derecha, `y` hacia abajo.

Ejemplo recomendado de base (ajustar por especie):
- `anchor_head: [64, 42]`
- `anchor_face: [64, 58]`
- `anchor_neck: [60, 68]`
- `anchor_body_center: [64, 76]`
- `anchor_back: [50, 70]`
- `anchor_tail: [92, 76]`
- `anchor_ground: [64, 108]`

## 9) Reglas de animación y sincronía
- Perfil MVP: `1 frame` (`idle_00`).
- Perfil recomendado: `4 frames` (`idle_00..03`).
- Si un ítem tiene animación, debe tener exactamente los mismos frames que la base activa.
- Nombres de frame por convención:
  - `*_idle_00.png`
  - `*_idle_01.png`
  - `*_idle_02.png`
  - `*_idle_03.png`

## 10) Reglas por slot (dimensión orientativa)
Sobre canvas 128x128:
- `headwear`: máx `72x48`, centrado en `anchor_head`.
- `eyewear`: máx `56x24`, centrado en `anchor_face`.
- `face`: máx `56x28`, centrado en `anchor_face`.
- `neckwear`: máx `64x28`, centrado en `anchor_neck`.
- `bodywear`: máx `88x56`, centrado en `anchor_body_center`.
- `backwear`: máx `84x56`, centrado en `anchor_back`.
- `tail`: máx `40x40`, centrado en `anchor_tail`.
- `aura`: puede ocupar hasta `128x128`, nunca ocultar completamente la base.
- `fx_front`: overlays puntuales, alpha parcial.

## 11) Nomenclatura
- `species_id`: `snake_case`, sin espacios. Ej: `salchicha`, `fiu`, `condor`.
- `item_id`: `snake_case` con variante. Ej: `cap_red`, `glasses_round_gold`.
- Rareza sugerida en metadata: `common`, `rare`, `epic`, `legendary`.

## 12) Manifest de especie (plantilla)
`assets/sprites/species/<species_id>/meta/species_manifest.json`

```json
{
  "species_id": "salchicha",
  "canvas": [128, 128],
  "frame_count": 4,
  "animation": "idle",
  "anchors": {
    "anchor_head": [64, 42],
    "anchor_face": [64, 58],
    "anchor_neck": [60, 68],
    "anchor_body_center": [64, 76],
    "anchor_back": [50, 70],
    "anchor_tail": [92, 76],
    "anchor_ground": [64, 108]
  },
  "slots": {
    "headwear": true,
    "eyewear": true,
    "face": true,
    "neckwear": true,
    "bodywear": true,
    "backwear": true,
    "tail": true,
    "aura": true,
    "fx_front": true
  }
}
```

## 13) Manifest de ítem cosmético (plantilla)
`assets/sprites/cosmetics/<slot_id>/<item_id>/meta/item_manifest.json`

```json
{
  "item_id": "cap_red",
  "slot_id": "headwear",
  "rarity": "common",
  "frame_count": 4,
  "canvas": [128, 128],
  "anchor_target": "anchor_head",
  "offset": [0, 0],
  "tags": ["cute", "starter"]
}
```

## 14) Pipeline de producción recomendado
1. Crear base de especie (`idle_00..03`) con anclas definidas.
2. Validar que la silueta no salga de safe area.
3. Crear cosméticos por slot respetando ancla objetivo.
4. Exportar PNGs con fondo transparente.
5. Generar manifests.
6. Validar combinaciones extremas (ej: headwear + eyewear + aura + backwear).

## 15) Checklist QA (obligatorio antes de aprobar pack)
- Todos los PNG en `128x128`.
- Sin checkerboard ni fondo sólido accidental.
- Anclas presentes y coherentes en `species_manifest.json`.
- Frame count consistente entre base e ítems animados.
- No clipping crítico en combinación de 4+ slots.
- El personaje se lee claro en escala 1x y 2x.
- Naming cumple convención (`snake_case`).

## 16) Paquete mínimo para arrancar contenido coleccionable
Por cada especie nueva:
- 1 base (`idle_00`) o ideal 4 frames (`idle_00..03`).
- 3 `headwear`
- 3 `eyewear`
- 3 `neckwear`
- 3 `bodywear`
- 2 `backwear`
- 2 `aura`

Total recomendado inicial por especie: `16 ítems`.

## 17) Brief listo para otro agente generador
Usar este prompt base por especie:

```text
Genera sprites 2D pixel-art para Genagotchi.
Canvas 128x128 transparente, estilo consistente con base existente.
No antialias subpixel, bordes limpios.
Crea: base idle (4 frames) + cosméticos por slots (headwear, eyewear, neckwear, bodywear, backwear, aura).
Respeta anclas del species_manifest.
Entrega archivos con naming snake_case y manifests JSON.
Evita clipping en combinaciones.
```

## 18) Definición de terminado (Definition of Done)
Un pack de especie está terminado cuando:
- Pasa checklist QA completo.
- Tiene base + cosméticos mínimos.
- Se puede equipar en runtime por capas sin ajustes manuales por ítem.
- El resultado visual mantiene legibilidad y estética coleccionable.
