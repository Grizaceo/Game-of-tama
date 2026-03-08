# Genagotchi - UX/Game Design Audit v1

Fecha: 2026-03-02
Base: Genagotchi_SDD_BaseSpec_v1.md

## Objetivo
Convertir el core sistémico actual (mutación, crianza, sync) en una experiencia jugable con identidad fuerte, feedback claro y retención saludable en MVP.

## Diagnóstico breve
- Fortaleza: base determinista sólida y auditable.
- Debilidad: ausencia total de capa de experiencia (UI, escena, feedback audiovisual, onboarding).
- Riesgo: si se lanza solo como sistema lógico, percepción de "prototipo técnico" y churn temprano.

## Dirección de producto (MVP)
- Fantasía central: "cuidar una criatura viva cuyos rasgos cambian con tu ritmo de juego".
- Tono: laboratorio afectivo + criatura doméstica.
- Promesa al jugador: progreso visible por sesión corta, sin castigo terminal.

## Cambios ad hoc recomendados (prioridad)

### P0 - Experiencia base jugable (1-2 semanas)
1. Escena principal con 3 zonas: Mascota, Estado, Acciones.
2. HUD explícito para hunger/oxidation y estado de mutación inminente.
3. Feedback inmediato por acción (feed/clean/play): animación + SFX + cambio numérico.
4. Evento visual de mutación (flash + etiqueta de rasgo cambiado).
5. Mensajería de sesión: "pasaron X horas", "se aplicaron Y ticks".

### P1 - Claridad sistémica (siguiente sprint)
1. Diario de cambios genéticos (timeline simple de últimas 10 mutaciones).
2. Vista de crianza con preview determinista de 4 ramas Punnett.
3. Indicador de "Huella de Caos" para reducir sensación de arbitrariedad.

### P2 - Retención saludable
1. Micro-objetivos diarios (3 acciones, 1 sesión de cuidado, 1 intento de crianza).
2. Recompensa por retorno sin castigo duro: bonus de recuperación tras inactividad.
3. "Álbum genético" (colección visual de variantes descubiertas).

## Especificación UX mínima por pantalla

### 1) Home/Pet Screen
- Header: nombre mascota, generación.
- Centro: sprite/animación idle-reactiva.
- Footer: botones grandes Feed, Clean, Play, Breed.
- Panel lateral o modal: genes dom/rec por slot.

### 2) Breeding Screen
- Padre A y B con slots comparables en paralelo.
- Cuadro Punnett resumido (4 celdas).
- CTA: "Crear cría" con semilla actual (`valid_clicks_total % 4`).
- Resultado: reveal animado + opción conservar/descartar.

### 3) Timeline/History
- Lista cronológica: ticks aplicados, oxidación acumulada, mutaciones, crianzas.
- Filtros: "mutación", "cuidado", "sync".

## UI Style Guide (MVP)
- Color: paleta óxido/naturaleza (amber, teal, carbón) para conectar con la mecánica.
- Tipografía: display expresiva para títulos + sans legible para HUD.
- Motion: 3 animaciones clave (idle, acción, mutación), no más en MVP.
- Sonido: 1 loop ambiente + 4 SFX funcionales.

## KPIs de diseño a validar
1. Time-to-first-fun < 60s.
2. Al menos 1 mutación visible en primeras 24h simuladas.
3. Tasa de comprensión de crianza > 70% en test cualitativo.
4. D1 retention objetivo inicial: >= 25% en prueba cerrada.

## Checklist de implementación inmediata
1. Crear escenas Godot: `Main.tscn`, `PetView.tscn`, `BreedingView.tscn`.
2. Conectar botones a `PetState` y `TickManager`.
3. Emitir eventos `Telemetry.log_event` para todas las acciones clave.
4. Añadir HUD de estado y panel de cambios recientes.
5. Ejecutar test de usabilidad con 3-5 usuarios y ajustar copy/UI.
