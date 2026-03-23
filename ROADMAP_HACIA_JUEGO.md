# Genagotchi — Roadmap hacia un juego jugable

Fecha: 2026-03-23
Estado de partida: infraestructura técnica cerrada, capa de juego inexistente.

---

## Diagnóstico rápido

| Capa | Estado actual |
|---|---|
| Auth anónima + Firestore sync | ✅ Funciona (E2E verde) |
| Motor de ticks (`TickManager`) | ✅ Implementado |
| Estado de mascota (`PetState`) | ✅ Implementado |
| Motor de mutación (`MutationEngine`) | ✅ 1 regla (oxidación), falta expandir |
| Motor de crianza (`BreedingEngine`) | ✅ Lógica Punnett determinista |
| Catálogo de genes (`GeneCatalog`) | ⚠️ Funcional pero limitado (7 tags, lejos de los 12 del spec) |
| Catálogo de especies (`PetCatalog`) | ⚠️ Variantes 2D fijas, sin renderer guiado por manifests |
| Escenas de juego (UI/UX) | ❌ No existen |
| HUD / feedback al jugador | ❌ No existe |
| Sprites / animaciones activas | ❌ Manifests versionados con `runtime_enabled: false` |
| Sonido / SFX | ❌ Assets en carpeta, sin conectar |
| Onboarding / progresión | ❌ No existe |

---

## Etapas ordenadas por prioridad

### ETAPA 1 — Experiencia base jugable (P0)
> Sin esto no es un juego. Duración estimada: 1-2 semanas.

**Objetivo:** que alguien pueda abrir el proyecto, ver su mascota y hacer algo con ella.

- [ ] Crear escena `PetView.tscn`: zona sprite + zona estado + zona acciones.
- [ ] Conectar botones Feed / Clean / Play a `PetState` y `TickManager`.
- [ ] HUD básico: barra de hunger, barra de oxidation, indicador de ticks pendientes.
- [ ] Feedback inmediato por acción: color flash + número que cambia (sin animación aún).
- [ ] Mostrar nombre de la mascota y generación actual.
- [ ] Mensajería de sesión: "pasaron X horas desde tu última visita, se aplicaron Y ticks".
- [ ] Sprite estático funcional en pantalla (cualquier placeholder visible).

**Criterio de salida:** un humano puede abrir el juego, hacer feed/clean/play y ver que algo cambia.

---

### ETAPA 2 — Sistema genético mínimamente visible (P0)
> Sin esto la mascota "no tiene alma". Paralela o inmediatamente posterior a Etapa 1.

**Objetivo:** que el jugador vea genes y entienda que mutan.

- [ ] Expandir `GeneCatalog` a 12 tags (completar `METAL`, `PAPEL`, `MADERA`, `CRISTAL`, `HIELO`).
- [ ] Implementar las 5 reglas de mutación del `Genetic_Combinatorics_Audit_v1.md` (hoy solo hay oxidación).
- [ ] Panel de genes visible en `PetView`: 3 slots dom/rec con nombre de tag.
- [ ] Evento visual de mutación: flash + etiqueta con el rasgo que cambió.
- [ ] Balancear ritmo de mutación por tick para que ocurra visiblemente en sesiones de 30-90s.

**Criterio de salida:** el jugador ve sus genes, juega 2 minutos y observa al menos una mutación.

---

### ETAPA 3 — Crianza funcional y comprensible (P1)
> El loop central diferenciador del juego.

**Objetivo:** que el jugador pueda cruzar dos mascotas y entender el resultado.

- [ ] Crear escena `BreedingView.tscn`: Padre A + Padre B + cuadro Punnett + botón "Crear cría".
- [ ] Preview determinista: mostrar las 4 posibles crías según `valid_clicks_total % 4`.
- [ ] Reveal animado del resultado al confirmar crianza.
- [ ] Mostrar "Huella de Caos" actual (contador de clicks) para que el jugador entienda el determinismo.
- [ ] Implementar cap de breeding: `breed_count` canónico por mascota.
- [ ] Costos de breeding escalados por `breed_count`.
- [ ] Persistir la cría nueva en Firestore (`pets/{new_pet_id}`).

**Criterio de salida:** el jugador puede cruzar dos mascotas, ver el resultado predicho y conservarlo.

---

### ETAPA 4 — Sprites y animaciones reales (P1)
> El juego necesita verse como juego, no como debug output.

**Objetivo:** reemplazar placeholders con arte funcional.

- [ ] Activar renderer guiado por manifests (`runtime_enabled: true` en al menos 3 especies base).
- [ ] Implementar 3 animaciones por especie: `idle`, `action` (feed/play/clean), `mutation`.
- [ ] Conectar `PetView` al renderer de sprites dinámico.
- [ ] Ajustar manifests en `assets/sprites/species` y `assets/sprites/cosmetics`.
- [ ] 1 loop de música ambiente + 4 SFX funcionales (feed, clean, play, mutación).

**Criterio de salida:** cada acción tiene una respuesta visual y sonora reconocible.

---

### ETAPA 5 — Retención y progresión mínima (P1)
> Sin esto el jugador no vuelve al día siguiente.

**Objetivo:** que haya razón para regresar.

- [ ] Micro-objetivos diarios: 3 acciones, 1 sesión de cuidado, 1 intento de crianza.
- [ ] Sistema de "álbum genético": registro visual de variantes descubiertas.
- [ ] Tiers de genes visibles: genes de nivel 1 desbloqueados al inicio, tiers superiores por mutación/crianza.
- [ ] Política de recuperación sin castigo duro: bonus de recuperación tras inactividad (no muerte permanente en MVP).
- [ ] Diario de cambios genéticos: timeline de últimas 10 mutaciones/crianzas.

**Criterio de salida:** un jugador vuelve al segundo día porque tiene algo que descubrir o completar.

---

### ETAPA 6 — Calidad técnica para distribución (P2)
> Antes de dar el juego a otros.

- [ ] Tests de replay determinista a N ticks (snapshot/hash final).
- [ ] Política de merge offline/server formal por campo (hoy indefinida).
- [ ] Telemetría de eventos conectada a backend (hoy solo buffer local).
- [ ] Contratos de datos user/pet con fixtures canónicos completos.
- [ ] Export funcional (export_presets.cfg ya existe, validar build web/desktop).

---

### ETAPA 7 — V2 / Post-lanzamiento (baja prioridad, no bloquea)

- [ ] Cloud Functions autoritativas para breeding/mutación (mover lógica del cliente al servidor).
- [ ] Ajuste dinámico de tasas por `config/global` (remote config Firebase).
- [ ] Social / PvP / mercado de genes.
- [ ] Sinergias avanzadas por combinación de tags (`FUEGO + VIENTO => plasma`).

---

## Definición de "esto ya es un juego"

El proyecto puede considerarse un juego cuando cumple las tres condiciones:

1. **Loop core completo**: el jugador puede cuidar, mutar y criar una mascota en una sola sesión sin salir del juego para leer código.
2. **Feedback legible**: cada acción produce una respuesta visual y sonora antes de 500ms.
3. **Razón para volver**: existe al menos un objetivo pendiente visible cuando el jugador cierra el juego.

Esto corresponde a tener las **Etapas 1, 2 y 3 completas** con sprites básicos funcionales (puede ser placeholder con arte final parcial).

---

## Archivos de referencia

| Documento | Ruta |
|---|---|
| Spec base del MVP | `Genagotchi_SDD_BaseSpec_v1.md` |
| Auditoría genética y tablas de combinatoria | `genagotchi/docs/design/Genetic_Combinatorics_Audit_v1.md` |
| Auditoría UX y guía de pantallas | `genagotchi/docs/design/UX_Game_Design_Audit_v1.md` |
| Backlog post-MVP (granularidad técnica) | `genagotchi/docs/traceability/Post_MVP_Backlog.md` |
| Log de cambios del codebase | `genagotchi/docs/traceability/Dev_Change_Log.md` |
| Contrato de datos v1 | `genagotchi/docs/data_contracts/v1/pet_schema_v1.json` |
