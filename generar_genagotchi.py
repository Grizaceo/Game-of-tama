from __future__ import annotations

import argparse
from pathlib import Path
import zipfile

DEFAULT_OUTPUT = "genagotchi_project.zip"

# Keep local credentials out of distribution artifacts.
EXACT_EXCLUDES = {
    "genagotchi/godot_project/config/firebase_dev.json",
}

DIR_EXCLUDES = {
    ".git",
    ".godot",
    "__pycache__",
}

SUFFIX_EXCLUDES = {
    ".pyc",
}

REQUIRED_ENTRIES = [
    "genagotchi/godot_project/project.godot",
    "genagotchi/godot_project/src/core/PetState.gd",
    "genagotchi/godot_project/src/network/FirebaseManager.gd",
    "genagotchi/godot_project/tests/TestRunner.gd",
]


def _should_include(file_path: Path, repo_root: Path) -> bool:
    rel = file_path.relative_to(repo_root).as_posix()
    if rel in EXACT_EXCLUDES:
        return False

    rel_parts = Path(rel).parts
    if any(part in DIR_EXCLUDES for part in rel_parts):
        return False

    if file_path.suffix in SUFFIX_EXCLUDES:
        return False

    return True


def _iter_source_files(source_dir: Path, repo_root: Path):
    for path in sorted(source_dir.rglob("*")):
        if path.is_file() and _should_include(path, repo_root):
            yield path


def _verify_zip_contents(output_zip: Path) -> None:
    with zipfile.ZipFile(output_zip, "r") as zf:
        names = set(zf.namelist())

    missing = [entry for entry in REQUIRED_ENTRIES if entry not in names]
    if missing:
        raise RuntimeError("ZIP missing required entries: %s" % ", ".join(missing))


def build_zip(repo_root: Path, output_zip: Path) -> int:
    source_dir = repo_root / "genagotchi"
    if not source_dir.exists():
        raise FileNotFoundError("Source directory not found: %s" % source_dir)

    count = 0
    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for file_path in _iter_source_files(source_dir, repo_root):
            arcname = file_path.relative_to(repo_root).as_posix()
            zf.write(file_path, arcname)
            count += 1

    _verify_zip_contents(output_zip)
    return count


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build genagotchi distribution zip from repository sources.")
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT,
        help="Output zip path (default: genagotchi_project.zip)",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    repo_root = Path(__file__).resolve().parent

    output_zip = Path(args.output)
    if not output_zip.is_absolute():
        output_zip = (repo_root / output_zip).resolve()

    files_written = build_zip(repo_root, output_zip)
    print("[OK] ZIP generated: %s" % output_zip)
    print("[OK] Files included: %d" % files_written)


if __name__ == "__main__":
    main()
