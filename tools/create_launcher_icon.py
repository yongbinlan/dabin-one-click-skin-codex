"""Package the approved Dabin Codex Skin artwork as a Windows multi-size ICO."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
PNG_PATH = ASSETS / "dabin-codex-skin-icon.png"
ICO_PATH = ASSETS / "dabin-codex-skin-icon.ico"
ICO_SIZES = [(16, 16), (20, 20), (24, 24), (32, 32), (40, 40), (48, 48), (64, 64), (128, 128), (256, 256)]


def main() -> None:
    if not PNG_PATH.is_file():
        raise FileNotFoundError(f"Approved icon artwork is missing: {PNG_PATH}")

    with Image.open(PNG_PATH) as source:
        artwork = source.convert("RGBA")
        side = min(artwork.size)
        left = (artwork.width - side) // 2
        top = (artwork.height - side) // 2
        icon = artwork.crop((left, top, left + side, top + side))
        icon.save(ICO_PATH, format="ICO", sizes=ICO_SIZES)
    print(PNG_PATH)
    print(ICO_PATH)


if __name__ == "__main__":
    main()
