"""Subset the Noto fonts into app/assets/fonts (see app/design/design-system.md, Fonts).

Usage, from a folder outside the repo (so the repo's uv version pin doesn't apply):
    uv run --no-project --no-config --with fonttools python -I <repo>/app/tool/subset_fonts.py <dir with the original Noto files>
Re-run whenever the zh ARB gains new characters.

Sources: notofonts/notofonts.github.io (NotoSans, NotoSansTamil, unhinted static TTF) and
notofonts/noto-cjk Sans/SubsetOTF/SC (NotoSansSC Regular and Bold). All OFL 1.1.
"""

import re
import sys
from pathlib import Path

from fontTools import subset

APP = Path(__file__).resolve().parents[1]
OUT = APP / "assets" / "fonts"

LATIN = "U+0000-007F,U+00A0-00FF,U+0100-017F,U+2000-206F,U+20AC,U+2122"
TAMIL = "U+0B80-0BFF,U+200C,U+200D,U+25CC," + LATIN


def gb2312_level1() -> set[str]:
    # GB2312 level-1 hanzi (3,755 most common characters): rows 0xB0-0xD7.
    chars = set()
    for hi in range(0xB0, 0xD8):
        for lo in range(0xA1, 0xFF):
            try:
                chars.add(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                pass
    return chars


def arb_han() -> set[str]:
    text = "".join(p.read_text(encoding="utf-8") for p in APP.glob("lib/**/*.arb"))
    return set(re.findall(r"[　-〿一-鿿＀-￯]", text))


def run(src: Path, name: str, out_name: str, unicodes: str | None = None, text: str | None = None) -> None:
    args = [str(src / name), f"--output-file={OUT / out_name}", "--layout-features=*", "--name-IDs=*"]
    if unicodes:
        args.append(f"--unicodes={unicodes}")
    if text:
        args.append(f"--text={text}")
    subset.main(args)
    print(f"{out_name}: {(OUT / out_name).stat().st_size // 1024} KB")


def main() -> None:
    src = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    for w in ("Regular", "SemiBold", "ExtraBold"):
        run(src, f"NotoSans-{w}.ttf", f"NotoSans-{w}.ttf", unicodes=LATIN)
        run(src, f"NotoSansTamil-{w}.ttf", f"NotoSansTamil-{w}.ttf", unicodes=TAMIL)
    han = "".join(sorted(gb2312_level1() | arb_han()))
    for w in ("Regular", "Bold"):
        run(src, f"NotoSansSC-{w}.otf", f"NotoSansSC-{w}.otf", unicodes=LATIN, text=han)
    (OUT / "OFL.txt").write_bytes((src / "OFL.txt").read_bytes())


if __name__ == "__main__":
    main()
