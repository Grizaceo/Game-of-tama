# Tests

Run headless tests from `godot_project/`:

```bash
godot4 --headless -s res://tests/TestRunner.gd
```

Alternative binary name:

```bash
godot --headless -s res://tests/TestRunner.gd
```

## Firebase E2E (auth + sync)

By default this project uses `src/network/FirebaseCompat.gd` as the `Firebase`
autoload. It provides deterministic auth/sync behavior for local and CI runs.

If you want to run against a real Firebase backend, replace the `Firebase`
autoload in `project.godot` with the plugin autoload scene and configure
credentials/rules in the addon.

Run E2E:

```bash
godot4 --headless -s res://tests/FirebaseE2E.gd
```

Expected success line:

```text
RESULT=OK uid=<uid> pet_id=<pet_id>
```
