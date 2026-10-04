"""Render scene.html frame-by-frame with Playwright and pipe to ffmpeg.
usage: python3 render.py OUT_SILENT.mp4 [frame_at_seconds ...]  (extra args = dump PNG stills only)"""
import sys, os, subprocess, pathlib
from playwright.sync_api import sync_playwright
here = pathlib.Path(__file__).parent
FPS = 30
out = sys.argv[1]
stills = [float(x) for x in sys.argv[2:]]
with sync_playwright() as p:
    try:
        b = p.chromium.launch()
    except Exception:
        b = p.chromium.launch(executable_path='/opt/pw-browsers/chromium')
    pg = b.new_page(viewport={'width': 1080, 'height': 1920}, device_scale_factor=1)
    pg.goto((here / 'scene.html').as_uri())
    pg.evaluate('document.fonts.ready')
    pg.wait_for_timeout(500)
    dur = pg.evaluate('window.DURATION')
    if stills:
        for t in stills:
            pg.evaluate(f'seek({t})')
            pg.screenshot(path=f'{out}_{t:05.2f}.png')
        b.close(); sys.exit()
    n = int(dur * FPS)
    ff = subprocess.Popen(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', str(FPS), '-i', '-',
                           '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
    for i in range(n):
        pg.evaluate(f'seek({i / FPS})')
        ff.stdin.write(pg.screenshot(type='png'))
    ff.stdin.close(); ff.wait(); b.close()
