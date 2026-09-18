"""Build the portable Dabin Codex Skin release archive."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT.parent / "dabin-one-click-codex-skin-v2.5.3.zip"
ARCHIVE_ROOT = "dabin-one-click-skin"
FILES = [
    ".gitignore",
    "LICENSE",
    "README.md",
    "SKILL.md",
    "agents/openai.yaml",
    "assets/README.md",
    "assets/dabin-codex-skin-icon.ico",
    "assets/dabin-codex-skin-icon.png",
    "assets/default-launcher-background-960x720.png",
    "assets/default-launcher-background.png",
    "docs/images/launcher-interface-v2.png",
    "docs/使用教程.md",
    "scripts/dabin-skin.ps1",
    "scripts/DabinLauncher.ps1",
    "scripts/StartDabinSkin.bat",
    "src/codex-skin.mjs",
]


def main() -> None:
    missing = [relative for relative in FILES if not (ROOT / relative).is_file()]
    if missing:
        raise FileNotFoundError("Missing release files: " + ", ".join(missing))

    with ZipFile(OUTPUT, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for relative in FILES:
            archive.write(ROOT / relative, f"{ARCHIVE_ROOT}/{relative}")
    print(OUTPUT)
    print(f"entries={len(FILES)}")


if __name__ == "__main__":
    main()
