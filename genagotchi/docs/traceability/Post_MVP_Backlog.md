# Post-MVP Backlog (para siguiente proyecto)

Fecha: 2026-03-03
Contexto: este backlog asume MVP basico cerrado con auth anonima + sync de `users/{uid}` y `pets/{pet_id}`.

## 1) Prioridad Alta - Diversion genetica

1. Expandir `GeneCatalog` a 12 tags maximo (limite MVP-safe del spec).
2. Definir 8-12 reglas de mutacion deterministas iniciales (hoy solo hay 1 regla de oxido).
3. Diseñar sinergias por combinacion de tags (ej. `FUEGO + VIENTO => plasma`).
4. Introducir "tiers" de genes visibles para progresion de descubrimiento.
5. Balancear ritmo de mutacion por tick para sesiones de 30-90 segundos.

## 2) Prioridad Alta - UX jugable

1. Implementar escenas base: `Main`, `PetView`, `BreedingView`.
2. HUD con hunger/oxidation + alertas de umbral.
3. Feedback audiovisual minimo: animacion accion + evento mutacion.
4. Timeline de cambios geneticos y eventos de sync.

## 3) Prioridad Media - Calidad y producto

1. Tests de replay determinista a N ticks (snapshot/hash final).
2. Contratos de datos user/pet con fixtures canonicos.
3. Politica de merge offline/server formal por campo.
4. Telemetria de eventos a backend (hoy buffer local).

## 4) Prioridad Media - Economia y progresion

1. Cap de breeding por mascota (`breed_count` canonico).
2. Costos de breeding escalados por contador.
3. Primer sink de genes (transmutacion simple).

## 5) Prioridad Baja - V2

1. Cloud Functions autoritativas para breeding/mutacion.
2. Ajuste dinamico de tasas por `config/global`.
3. Social/PvP/mercado (fuera de MVP por diseno).

## Definicion de listo para pasar a bloque genetico

1. E2E verde: `RESULT=OK uid=... pet_id=...`.
2. Firestore contiene ambos documentos:
- `users/{uid}`
- `pets/{pet_id}`
3. Al menos 2 sesiones consecutivas preservan estado sin corrupcion temporal.

