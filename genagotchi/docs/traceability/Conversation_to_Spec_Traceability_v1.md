# Genagotchi - Trazabilidad Conversacion -> Spec -> Implementacion (v1)

Fecha: 2026-03-02
Fuente primaria: `Game of tama.docx`
Spec usado como canon actual: `Genagotchi_SDD_BaseSpec_v1.md` (no se encontro `dev.md` en raiz al momento de este documento)

## Resumen ejecutivo
- La mayor parte de los requerimientos nucleares del chat quedaron capturados en el spec base.
- El repositorio implementa una parte tecnica del core (estado, tick, mutacion, breeding, serializacion, offline).
- Falta la capa de experiencia de juego (escenas UI/UX, feedback audiovisual, onboarding) y los sistemas sociales/competitivos, que estan fuera de MVP por diseno.

## Matriz de trazabilidad

| ID | Origen en conversacion (.docx) | Requisito consolidado | Spec (evidencia) | Estado repo actual | Evidencia codigo / docs | Cambio ad hoc recomendado |
|---|---|---|---|---|---|---|
| C01 | "Oxidacion en vez de muerte" | Penalizacion por inactividad sin muerte permanente | Secciones 2.1, 3.1, 5.2 | Parcial implementado | `TickManager.gd`, `PetState.gd` | Agregar UX de recuperacion y feedback visual de oxidacion |
| C02 | "Genetica activa con herencia" | Genoma por slots + dom/rec | Seccion 6.1 | Implementado (base) | `PetState.gd` | Extender catalogo y fenotipos visibles |
| C03 | "Juego de la Vida / reglas deterministas" | Mutacion por tags/bitmask y reglas deterministas por tick | Secciones 6.2, 4.1 | Parcial implementado | `MutationEngine.gd`, `GeneCatalog.gd` | Aumentar reglas y cobertura de tests |
| C04 | "Beneficiarnos de proporciones y trabajar en enteros" | IDs enteros + bitmasks para eficiencia/consulta | Secciones 1, 6.1, 9.2 | Implementado | `GeneCatalog.gd`, `Serializer.gd` | Agregar `config/global` para tasas dinamicas V2 |
| C05 | "Cruza mendeliana con control" | Cuadro de Punnett + Huella de Caos determinista | Seccion 6.3 | Implementado | `BreedingEngine.gd` | Mostrar preview de 4 ramas en UI de breeding |
| C06 | "Contrato de datos inamovible" | `schema_version` + contratos v1 | Secciones 4.2, 7 | Implementado (v1) | `pet_schema_v1.json`, `PetState.gd` | Crear contract tests automatizados |
| C07 | "Godot + Firebase" | Cliente Godot y persistencia Firestore con auth | Secciones 9 y 11 | Parcial implementado | `Serializer.gd`, `OfflineSync.gd`, `FirebaseManager.gd` (stub) | Implementar Auth anonima + REST real |
| C08 | "Offline primero" | Guardado local + politica de merge | Seccion 9.3 | Parcial implementado | `OfflineSync.gd` | Formalizar politica de conflictos en spec final |
| C09 | "Arena / intercambio / granjas" | Sistemas sociales y competitivos | Seccion 3.2 (fuera de MVP) | No implementado (intencional) | Spec freeze MVP | Mantener bloqueado hasta V2 |
| C10 | "Pixel art moderno + particulas" | Direccion estetica y feedback de alto impacto | Seccion 5 (implicito), roadmap | No implementado | N/A | Crear pipeline de arte + escenas y VFX MVP |
| C11 | "Monetizacion etica" | Cosmeticos sin P2W | Seccion 4/8 (linea economica) | No implementado (MVP temprano) | N/A | Definir catalogo cosmetico para V2 |
| C12 | "Evitar inflacion genetica" | Sinks (cap de breeding, costos, burn) | Seccion 8 | Parcial (solo contador base) | `PetState.gd` (`breed_count`) | Aplicar cap canonico y costo escalado |
| C13 | "Retencion baja friccion tipo Neko Atsume" | Sesiones cortas y retorno amable | Secciones 2, 10 | No implementado en UX | N/A | Diseñar loops de 30-90s + recompensas de retorno |
| C14 | "Telemetria para aprender" | Eventos minimos + KPIs D1/D7 | Seccion 10.2 | Parcial implementado | `Telemetry.gd` (buffer local) | Enviar eventos a backend/analytics |

## Hallazgos de alineacion
1. El nucleo determinista que origino el proyecto si esta reflejado en arquitectura y codigo base.
2. El recorte de alcance a MVP se esta respetando (social/PvP fuera).
3. La principal brecha es de experiencia de producto: hoy hay motor, pero no hay interfaz jugable que materialice la fantasia de "mascota viva".

## Backlog recomendado (orden de ejecucion)
1. Construir escena jugable minima (`Main`, `PetView`, `BreedingView`) y conectar al core.
2. Implementar Firebase Auth anonima + sincronizacion REST real.
3. Añadir tests de contrato (serializer), mutacion y breeding determinista.
4. Formalizar y documentar politica offline/merge (server-wins por campos criticos).
5. Diseñar capa audiovisual MVP (animaciones por accion y mutacion).

## Nota de fuente
La extraccion del `.docx` se realizo desde `word/document.xml` y esta trazabilidad resume los puntos tecnicos y de producto mas repetidos en la conversacion original.
