"""Local-only preview of the real game, with audio disabled before boot."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import argparse

ROOT = Path(r'H:\Codex\Projects\IdleElite\outputs\accounts-preview\web')

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        # Rebuilds reuse this origin so saved-account tests survive. Never let
        # an old debug engine or pack remain cached after a release rebuild.
        if 'If-Modified-Since' in self.headers:
            del self.headers['If-Modified-Since']
        if self.path.startswith('/release/'):
            self.path = self.path[len('/release'):]
        if self.path.split('?')[0] in ('/', '/index.html'):
            html = (ROOT / 'index.html').read_text().replace('"args":[]', '"args":["--audio-driver","Dummy"]')
            data = html.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(data)
        else:
            super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=5000)
    args = parser.parse_args()
    ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
