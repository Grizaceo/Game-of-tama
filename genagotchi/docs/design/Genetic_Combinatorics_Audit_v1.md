# Protocolo de Auditoría y Combinatoria Genética v1 — Genagotchi

Este documento define las reglas deterministas que rigen la herencia y mutación. Su objetivo es permitir que un diseñador pueda auditar cualquier nacimiento o cambio de estado mediante una traza de datos fija.

## 1. El Mapa de Tags (Bitmasks)
Cada especie base aporta un "Tag Maestro" que activa reglas en el motor.

| ID | Tag | Especie Fuente | Bitmask (2^n) |
| :--- | :--- | :--- | :--- |
| 1 | `TIERRA` | Sprout-Rex | `1 << 0` (1) |
| 2 | `OXIDO` | Copper-Hound | `1 << 1` (2) |
| 3 | `LUZ` | Starlight-Doe | `1 << 2` (4) |
| 4 | `SOMBRA` | Void-Stalker | `1 << 3` (8) |
| 5 | `VIENTO` | Origami-Drake | `1 << 4` (16) |
| 6 | `AGUA` | Neon-Slime | `1 << 5` (32) |
| 7 | `FUEGO` | Cinder-Lizard | `1 << 6` (64) |

---

## 2. Herencia Mendeliana Determinista (Breeding)
El Breeding NO usa `rand()`. Usa la **"Huella de Caos"** del jugador.

### Fórmula de Selección:
Para cada uno de los 3 slots (`head`, `body`, `aura`), el gen resultante se elige de las 4 combinaciones del cuadro de Punnett:
1. `ParentA_Dom + ParentB_Dom`
2. `ParentA_Dom + ParentB_Rec`
3. `ParentA_Rec + ParentB_Dom`
4. `ParentA_Rec + ParentB_Rec`

**Índice de Selección (Audit):**
`Selection_Index = (PlayerData.valid_clicks_total + Slot_ID) % 4`

> **Nota para Auditoría:** Si un jugador dice "me salió algo raro", el diseñador solo necesita el `valid_clicks_total` en el momento del cruce para replicar el resultado exacto en el editor.

---

## 3. Motor de Mutación "Juego de la Vida" (Epigenética)
Las mutaciones ocurren durante los **Ticks** y dependen del `Ecosystem_Hash` (el `OR` de los tags de los genes dominantes activos).

### Tabla de Prioridad de Combinatoria (Audit Table)
Cuando dos tags interactúan en el `Ecosystem_Hash`, se activan transformaciones en los IDs de los genes.

| Combinación (Tags) | Resultado de Mutación (Visual) | Condición de Auditoría |
| :--- | :--- | :--- |
| `METAL` + `FUEGO` | **Molten (Lava)** | Requiere `Oxidation_Level < 50` |
| `PAPEL` + `FUEGO` | **Ash (Ceniza)** | Transforma ID en `Burned_Variant` |
| `LUZ` + `SOMBRA` | **Eclipse (Vacío)** | Se anulan tags, genera ID `Neutral_Grey` |
| `AGUA` + `TIERRA` | **Clay (Arcilla)** | Aumenta `Oxidation_Resistance` |
| `VIENTO` + `AGUA` | **Mist (Niebla)** | Cambia Alpha del sprite (0.5) |

### Lógica de Auditoría:
`New_Gene_ID = Mutation_Rule(Current_ID, Ecosystem_Hash, Tick_Count)`

---

## 4. Auditoría de Oxidación (Degradación)
La oxidación inyecta el tag `OXIDO` (2) de forma forzada en el motor de mutación cuando el contador de inactividad supera los umbrales.

*   **Umbral 50%:** Activa `Tag_Oxido`. El motor de mutación empieza a degradar IDs de genes estéticos a sus versiones "oxidadas".
*   **Umbral 100%:** Bloquea slots de cosméticos (no se pueden equipar ítems nuevos hasta limpiar).

---

## 5. Ejemplo de Traza de Auditoría (Caso Real)
Un jugador cruza un **Sprout-Rex** con un **Cinder-Lizard**.
*   **Inputs:** 
    *   Padre A: `[Tierra, Tierra]`
    *   Padre B: `[Fuego, Fuego]`
    *   Clicks Totales: `1542`
*   **Proceso:**
    *   `Selection_Index = 1542 % 4 = 2`
    *   Resultado Slot 1: `ParentA_Rec (Tierra) + ParentB_Dom (Fuego)`.
*   **Resultado Genético:** Una cría con genotipo `[Tierra/Fuego]`.
*   **Fenotipo (Mutación):** Al tener `Tierra` y `Fuego` activos, el motor de mutación detecta la regla de **Magma** y cambia el color del sprite a rojo incandescente en el siguiente Tick.

---

## 6. Conclusión para Diseñadores
Para auditar cualquier criatura, se requiere este "Snapshot":
1. `Genome_V1` de ambos padres.
2. `valid_clicks_total` del usuario.
3. `schema_version` y `engine_version`.

Si estos 3 valores coinciden, el resultado **siempre** será el mismo. El "azar" es solo una ilusión creada por la progresión de los clics del jugador.
