// Minimal dependency-free static server for the Flutter web build.
// Usage: node .claude/serve_web.js [port]   (serves ./build/web)
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] || 8080);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
  '.txt': 'text/plain',
};

http.createServer((req, res) => {
  const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  let file = path.join(root, urlPath);
  if (!file.startsWith(root)) { res.writeHead(403); return res.end('Forbidden'); }
  const exists = fs.existsSync(file);
  if (exists && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  if (!fs.existsSync(file)) {
    if (path.extname(urlPath) === '') file = path.join(root, 'index.html'); // SPA fallback
    else { res.writeHead(404); return res.end('Not found: ' + urlPath); }
  }
  const ext = path.extname(file).toLowerCase();
  res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream', 'Cache-Control': 'no-store' });
  fs.createReadStream(file).pipe(res);
}).listen(port, 'localhost', () => console.log('Serving ' + root + ' at http://localhost:' + port));
