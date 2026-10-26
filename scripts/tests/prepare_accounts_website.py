"""Copy the verified release export into the existing website release checkout."""
from pathlib import Path
import json
import re
import shutil

source = Path(r'H:\Codex\Projects\IdleElite\outputs\accounts-preview')
destination = Path(r'H:\Codex\Projects\Brian-Website-release\projects\idle-elite\play')
assert (source / 'build-kind.txt').read_text().strip() == 'release'
assert destination.is_dir()
files = [
    'index.apple-touch-icon.png', 'index.audio.position.worklet.js',
    'index.audio.worklet.js', 'index.html', 'index.icon.png',
    'index.js', 'index.pck', 'index.png', 'index.wasm',
]
html = (source / 'web/index.html').read_text(encoding='utf-8')
assert '(DEBUG)' not in html
config = json.loads(re.search(r'const GODOT_CONFIG = (.*);', html).group(1))
assert config['args'] == []
for name, size in config['fileSizes'].items():
    assert (source / 'web' / name).stat().st_size == size
html = html.replace('<head>', '<head>\n\t\t<base href="/projects/idle-elite/play/">\n\t\t<link rel="canonical" href="https://www.futurebrian.com/projects/idle-elite/play/">', 1)
html = html.replace('const engine = new Engine(GODOT_CONFIG);', '''// Optional silent browser previews preserve normal game audio by default.
if (new URLSearchParams(location.search).get('mute') === '1') {
    GODOT_CONFIG.args.push('--audio-driver', 'Dummy');
}
const engine = new Engine(GODOT_CONFIG);''', 1)
for name in files:
    if name != 'index.html':
        shutil.copyfile(source / 'web' / name, destination / name)
(destination / 'index.html').write_text(html, encoding='utf-8')
print('Website release prepared with Google accounts and optional muted preview')
