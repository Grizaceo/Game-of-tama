# Dev Change Log

## 2026-03-08

1. Re-alineación de contrato `FirebaseManager` con tests y docs.
- Contrato canónico: `auth_ready`, `auth_failed`, `sync_success(collection)`, `sync_failed(collection, reason)`.
- Tests dejaron de depender de APIs inexistentes (`set_identity`, `load_local_config`, `project_id`, `_id_token`, `user_sync_success`).
- Archivos: `godot_project/src/network/FirebaseManager.gd`, `godot_project/tests/TestRunner.gd`, `godot_project/tests/FirebaseE2E.gd`.

2. Endurecimiento de validaciones de sync.
- `sync_pet` rechaza `pet_id` vacío.
- `_sync_document` valida `doc_id`, presencia de nodos Auth/Firestore y creación de task antes de registrar contexto.
- Archivo: `godot_project/src/network/FirebaseManager.gd`.

3. Corrección de entrada principal y contrato de datos v1.
- `Main.tscn` ahora ejecuta `src/Main.gd`.
- Payload de ejemplo usa `schema_version` entero y `genome` válido vía `PetState`.
- Archivos: `godot_project/Main.tscn`, `godot_project/src/Main.gd`.

4. Flujo E2E simplificado y consistente.
- E2E valida auth + sync de `users` y `pets` por señales del manager.
- Se eliminó la verificación REST directa basada en token interno no expuesto por el manager actual.
- Archivo: `godot_project/tests/FirebaseE2E.gd`.

5. Generador ZIP actualizado para evitar deriva.
- `generar_genagotchi.py` deja de mantener plantillas embebidas y empaqueta el árbol real `genagotchi/` con exclusiones explícitas.

## Nota histórica

Entradas anteriores que mencionaban `load_local_config`/`set_identity` y verificación REST directa ya no representaban el estado real del código. Este log refleja el contrato vigente a partir de 2026-03-08.
