#!/usr/bin/env python3
"""Development-only: export PNG sizes from true-vector LiteRight SVG assets."""
from __future__ import annotations
import io
import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from PIL import Image
import cairosvg

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / 'assets/logo/LiteRight.svg'
SMALL = ROOT / 'assets/logo/LiteRight-small.svg'
BAR = ROOT / 'assets/menubar/LiteRightMenuBar.svg'
OUT = ROOT / 'LiteRightApp/Assets.xcassets/AppIcon.appiconset'

def svg_image(source: Path, resolution: int) -> Image.Image:
    exe = shutil.which('inkscape')
    if exe:
        with tempfile.TemporaryDirectory() as tmp:
            rendered = Path(tmp) / 'render.png'
            subprocess.run(
                [exe, str(source), f'--export-filename={rendered}', f'--export-width={resolution}', f'--export-height={resolution}'],
                check=True, capture_output=True, text=True,
            )
            with Image.open(rendered) as image:
                return image.convert('RGBA').copy()
    data = cairosvg.svg2png(url=str(source), output_width=resolution, output_height=resolution)
    return Image.open(io.BytesIO(data)).convert('RGBA')

def save(image: Image.Image, path: Path, pixels: int) -> None:
    image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(path, optimize=True)

def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    master = svg_image(MASTER, 2048)
    small = svg_image(SMALL, 512)
    bar = svg_image(BAR, 512)
    specs = []
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            pixel = size * scale
            suffix = '@2x' if scale == 2 else ''
            filename = f'icon_{size}x{size}{suffix}.png'
            save(small if pixel <= 32 else master, OUT / filename, pixel)
            specs.append({'idiom':'mac','size':f'{size}x{size}','scale':f'{scale}x','filename':filename})
    (OUT / 'Contents.json').write_text(json.dumps({'images': specs, 'info': {'author':'xcode','version':1}}, indent=2) + '\n')
    save(master, ROOT / 'assets/logo/LiteRight-preview-1024.png', 1024)
    for pixels in (18, 20, 36, 40, 64):
        save(bar, ROOT / f'assets/menubar/LiteRightMenuBar-{pixels}px.png', pixels)
    print(f'Exported {len(specs)} app icon representations and 5 menu bar variants')

if __name__ == '__main__':
    main()
