# Genagotchi — Base Spec (Spec‑Driven Development) v1

**Fecha:** 2026-03-01  
**Estado:** DRAFT‑READY  
**Alcance:** MVP Single‑Player + Contrato de Datos + Firebase/Firestore

---

## 1. Contexto y Fuente de Requisitos

Esta especificación se deriva del chat consolidado en el archivo “Game of tama.docx”.  
Se adopta como canon de MVP:

- motor de mutación tipo “Juego de la Vida” basado en **etiquetas** implementadas como **bitmasks** sobre enteros;
- herencia mendeliana por **slot** (dom/rec) con selección determinista tipo **“Huella de Caos”**;
- contrato de datos inmutable desde el día 1;
- Firebase/Firestore como backend.

**Objetivo de esta spec:** dejar un documento único que permita desarrollar sin ambigüedades (SDD), con dependencias, contratos, criterios de aceptación y límites de alcance para evitar *scope creep*.

---

## 2. Evaluación Ejecutiva (viabilidad, diferenciación, riesgos)

### 2.1 Lo que hace que Genagotchi sea defendible

- Retención sin “muerte permanente”: el abandono gatilla **oxidación**/degradación en vez de kill‑switch.
- Profundidad emergente (*hardcore‑discoverable*): sistema determinista con alta combinatoria; no depende de RNG puro.
- Economía centrada en genes (loot + colección): genes como unidad de progreso (y futura moneda social).
- Arquitectura de datos limpia (enteros + bitmasks): performance, queries y estabilidad del contrato.

### 2.2 Riesgos principales y mitigaciones

- **Scope creep** (social/arena/mercado/historia a la vez): se bloquea por “corte MVP” (Sección 3).
- **Inflación genética** al abrir mercado: requiere *sinks* (esterilidad, costos, burn, límites). Se deja V2‑ready (Sección 8).
- **Cheat/integridad** si todo se computa client‑side: MVP acepta integridad “soft” (single player). V2 requiere server‑authoritative.
- **Complejidad de balance:** se impone versionado de engine + unit tests + telemetría mínima.

---

## 3. Alcance y No‑Alcance (MVP freeze)

### 3.1 MVP (incluido)

- 1 mascota principal por usuario (opcional: 2–3 ranuras, sin mercado).
- Ciclo de cuidado: alimentar, limpiar, jugar (acciones incrementan *valid_clicks*).
- Oxidación por inactividad: degradación progresiva de rasgos (no muerte).
- Mutación “Juego de la Vida” (epigenética): reglas deterministas por tags/bitmasks aplicadas en *ticks*.
- Reproducción local (breeding): herencia mendeliana por slot con selección determinista basada en “Huella de Caos”.
- Persistencia: Firestore (users + pets) y caché local offline.
- Contrato de datos v1 (inmutable): schemas + validaciones mínimas + versionado.
- Export Android (APK/AAB) con pipeline reproducible.

### 3.2 No‑Alcance (bloqueado en MVP)

- Arena/PvP online, apuestas, ranking.
- Intercambio directo de genes/huevos entre usuarios.
- Mercado / Auction House / monetización por trade.
- Inventario global compartido de consumibles/genes.
- Cloud Functions obligatorias para cálculo autoritativo (reservadas V2).

---

## 4. Definiciones y Principios de Diseño

### 4.1 Principio: determinismo controlado

- Toda transición de estado debe ser reproducible dado *(estado anterior + inputs + contador de caos)*.
- La aleatoriedad aparente se logra con “Huella de Caos” determinista (no RNG verdadero).
- Reglas deben ser inspeccionables por el equipo (debuggable), aunque el jugador no las conozca.

### 4.2 Principio: contrato de datos inmutable + versionado

- Toda entidad persistida incluye `schema_version` y `engine_version(s)`.
- Cambios rompedores requieren nuevo `schema_version` + migración explícita (fuera de MVP).

---

## 5. Modelo de Juego (loop, estados, sistemas)

### 5.1 Loop principal (MVP)

1. Login → sync estado desde Firestore → aplicar *tick* (si corresponde) → render mascota → acciones → persistir.
2. Breeding (opcional): seleccionar 2 padres (en MVP puede ser “mascota + clon”) → producir cría → elegir conservar o descartar → persistir.

### 5.2 Estados mínimos de la mascota

- `hunger ∈ [0,100]`
- `hygiene ∈ [0,100]` *(opcional MVP)*
- `happiness ∈ [0,100]` *(opcional MVP)*
- `oxidation_level ∈ [0,100]` (crece con inactividad; reduce/“rompe” rasgos)
- `last_interaction` (server timestamp preferido)

---

## 6. Genética: Representación, Mutación, Herencia

### 6.1 Representación del genoma (slots + alelos)

Cada mascota tiene 3 slots (`head/body/aura`) y, en cada slot, dos alelos: dominante (activo/visible) y recesivo (oculto).  
Los genes se representan por IDs enteros. Los tags se representan por bitmasks (potencias de 2).

```text
GenomeV1:
  head: { dom: int, rec: int }
  body: { dom: int, rec: int }
  aura: { dom: int, rec: int }

Tags (bitmask): FUEGO=1<<0, VIENTO=1<<1, AGUA=1<<2, TIERRA=1<<3, OXIDO=1<<4, ...
GeneDB: gene_id -> tag_mask
```

### 6.2 Motor de Mutación (epigenética “Juego de la Vida”)

- Entrada: `PetState + GenomeV1`.
- Construye `ecosystem_hash = OR` bitwise de las máscaras de los genes dominantes activos.
- Inyecta tags por entorno (p.ej., `OXIDO` si `oxidation_level > umbral`).
- Aplica reglas deterministas (priorizadas) que transforman **genes dominantes** (`dom`) por slot.
- El alelo recesivo **no se toca** en mutación (para no colisionar con Mendel).
- Salida: `GenomeV1` actualizado + `ecosystem_hash` recalculado.

### 6.3 Herencia Mendeliana + “Huella de Caos”

Para cada slot se calculan las 4 combinaciones del cuadro de Punnett.  
La selección entre las 4 ramas se hace con:

- `chaos_index = (valid_clicks_total + hash(pet_id opcional)) % 4`

En MVP se usa el contador de clics válidos del usuario (monótono).  
La dominancia fenotípica se resuelve por regla simple (p.ej. mayor `gene_id` domina) **o** por tabla explícita.

```text
Punnett(slot):
  0: A_dom + B_dom
  1: A_dom + B_rec
  2: A_rec + B_dom
  3: A_rec + B_rec

chaos_index = PlayerData.valid_clicks_total % 4
```

### 6.4 Reglas anti‑explosión de complejidad (MVP)

- Número de slots fijo = 3 (no añadir más en MVP).
- Número de tags inicial ≤ 12.
- Reglas de mutación: máximo 20 reglas duras en MVP; el resto vía composición en V2.

---

## 7. Contrato de Datos (Firestore)

### 7.1 Colecciones y documentos

- `users/{uid}`
- `pets/{pet_id}` (con `owner_id = uid`)
- `gene_catalog/v1` (solo lectura; describe IDs y masks)
- `config/global` (parámetros de balance; futuros *daily_rates*)

### 7.2 Esquema Pet (canonical JSON)

```json
{
  "schema_version": 1,
  "pet_id": "string",
  "owner_id": "string",
  "generation": 1,
  "engine": { "mutation_v": 1, "breeding_v": 1 },
  "ecosystem_hash": 0,
  "genome": {
    "head": { "dom": 101, "rec": 100 },
    "body": { "dom": 202, "rec": 101 },
    "aura": { "dom": 305, "rec": 102 }
  },
  "status": {
    "hunger": 100,
    "oxidation_level": 0,
    "last_interaction": 1709015760
  },
  "telemetry": { "valid_clicks_snapshot": 1542 }
}
```

### 7.3 Esquema User (mínimo)

```json
{
  "schema_version": 1,
  "uid": "string",
  "created_at": 1709010000,
  "valid_clicks_total": 0,
  "active_pet_id": "gen_8f7a9b",
  "settings": { "sound": true }
}
```

### 7.4 Reglas de Seguridad (MVP)

En MVP, las reglas se centran en control de acceso y validación de tipos/rangos. La validación autoritativa del engine se reserva para V2 (Cloud Functions).

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    match /pets/{petId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.owner_id;
      allow create: if request.auth != null && request.resource.data.owner_id == request.auth.uid;
      allow update: if request.auth != null
                    && request.auth.uid == resource.data.owner_id
                    && request.resource.data.status.oxidation_level >= 0
                    && request.resource.data.status.oxidation_level <= 100;
    }
  }
}
```

---

## 8. Economía y Balance (MVP‑safe + V2‑ready)

### 8.1 Principio: evitar inflación genética al abrir trade

- MVP no abre mercado; se diseñan campos y límites para soportar *sinks*.
- V2 *sinks* recomendados: (i) límite de breeding por mascota (esterilidad), (ii) costo de breeding, (iii) burn/craft.

### 8.2 Precedente útil (breeding cap + costos)

En economías de breeding, el control típico es: costo por cruce + límite de reproducciones por individuo, para contener hiper‑inflación.

### 8.3 Sinks concretos propuestos (para especificar en V2)

1. Esterilidad por contador de cruces: `pet.breed_count ∈ [0,7]`.
2. Costo de cruce: moneda blanda + (opcional) moneda dura; escala por `breed_count`.
3. Reforja/Transmutación: destruir 3 genes del mismo tag para crear 1 gen refinado.

---

## 9. Backend: Integración Firestore vía REST (Godot)

### 9.1 Autenticación

- MVP: Firebase Auth anónimo → obtiene **ID token**.
- Todas las llamadas REST a Firestore usan header: `Authorization: Bearer <Firebase ID token>`.

### 9.2 Serialización Firestore (Value types)

Firestore REST usa tipos explícitos (`integerValue`, `stringValue`, `mapValue`, `arrayValue`, etc.). La implementación debe tener un único serializador (contrato) para evitar drift.  
**Nota:** `integerValue` se serializa como string (int64).

```text
fields: {
  "owner_id": {"stringValue": "uid"},
  "ecosystem_hash": {"integerValue": "3"},
  "genome": {"mapValue": {"fields": { ... }} }
}
```

### 9.3 Estrategia offline (fallback)

- Guardar `local_save.json` con el último PetState.
- Si falla sync, operar en modo local y reintentar con backoff (máx N intentos por sesión).
- Resolver conflictos con `last_interaction` + `client_updated_at` (política en Pendientes).

---

## 10. Calidad: Tests, Telemetría, Criterios de Aceptación

### 10.1 Tests obligatorios (unit + contract)

- Contract tests: serialización Firestore produce el mismo JSON (orden canónico) para input fijo.
- Mutation tests: dado PetState/Genome fijo, `apply_tick` produce salida exacta.
- Breeding tests: dado (parentA, parentB, `clicks_total`), `child_genome` es exacto.
- Invariants: `oxidation_level ∈ [0,100]`; `dom/rec` son int; `ecosystem_hash` corresponde a genes dom.
- Replay test: con clicks guardados, reproducir N ticks y comparar hash final.

### 10.2 Observabilidad mínima

- Events: `login_success`, `tick_applied`, `action_feed/clean/play`, `breeding_start`, `breeding_result`, `sync_fail`, `sync_success`.
- KPIs MVP: D1/D7 retention, sesiones/día, acciones/sesión, fallos de sync, distribución de `oxidation_level`.

### 10.3 Criterios de aceptación (MVP)

1. Crear usuario anónimo y persistirlo en `users/{uid}`.
2. Crear mascota inicial y persistir `pets/{pet_id}` con `schema_version=1`.
3. Tras 24h sin interacción, `oxidation_level` aumenta y al menos 1 regla de degradación puede aplicar.
4. Breeding determinista: repetir con mismos inputs produce mismo resultado.
5. Offline: el juego sigue operando y sincroniza al recuperar conexión.

---

## 11. Dependencias y Toolchain (reproducible)

### 11.1 Godot/Android

- Godot Engine 4.2+ (rama estable).
- OpenJDK 17 (recomendado por docs para export Android).
- Android SDK + build‑tools compatibles con export Android.

### 11.2 Firebase

- Firebase Authentication (Anonymous).
- Cloud Firestore (Native mode).
- Reglas versionadas en repo (`firestore.rules`).
- Opcional V2: Cloud Functions (breeding/mutation autoritativo + cron daily rates).

---

## 12. Roadmap sugerido (SDD)

1. Fase 0 — Repo + Spec freeze: lock del contrato Pet/User y versiones.
2. Fase 1 — Core local: PetState + UI mínima + contador de clics.
3. Fase 2 — MutationEngine (tick + reglas + tests).
4. Fase 3 — BreedingEngine (punnett + caos + tests).
5. Fase 4 — FirebaseManager (Auth + REST + serialización + reglas).
6. Fase 5 — Offline mode + backoff + conflict policy.
7. Fase 6 — Instrumentación (eventos + dashboard simple).

---

## 13. Apéndice — Prompt de investigación (mercado + riesgos)

```text
Actúa como Lead Game Designer + Game Economist.
Analiza Genagotchi (mascota virtual + genética determinista con bitmasks + breeding mendeliano + oxidación en vez de muerte).
1) Encuentra y resume precedentes comparables (p.ej., Flight Rising, Monster Rancher, juegos de breeding móviles) y sus lecciones.
2) Riesgos económicos: inflación genética, farming, arbitraje, ‘pay-to-win’ por mercado.
3) Propón sinks/faucets y límites de breeding para estabilizar economía (ej. esterilidad, costos escalados, burn por craft).
4) Retención: compara con juegos de baja fricción (p.ej., Neko Atsume) y propone variantes de oxidación que no generen churn.
Entrega: 10 lecciones accionables + 5 decisiones de diseño recomendadas para MVP y 5 para V2.
```

---

## 14. Referencias (técnicas, para trazabilidad)

- Chat fuente: `Game of tama.docx` (consolidado interno).
- Godot Docs — Exporting for Android (recomienda JDK 17).
- Google Cloud Firestore REST — `Value` types (`integerValue` como string; `mapValue/arrayValue`).
- Firebase Docs — Firestore Security Rules (validación y control de acceso).
- Economía de breeding: Axie (costos + límites como patrón; usar solo como precedente).
- Retención baja fricción: Neko Atsume (patrón de “no castigo duro”).

---

## Pendientes

1. **Política de conflicto offline→online:** regla exacta de merge (`last_interaction` vs `client_updated_at`) y qué campos son “server‑wins”.
2. **Dominancia fenotípica:** confirmar si “ID mayor domina” queda como canon MVP o si habrá tabla explícita por gen.
3. **Modelo de oxidación:** definir si la degradación es aleatoria por semana o determinista por tags/umbrales.
4. **Integridad MVP vs V2:** declarar el punto de corte donde breeding/mutación pasan a ser **server‑authoritative** (Cloud Functions) para habilitar mercado/PvP sin inyección.
