// Tiny static file server with SPA fallback, used by the PWA e2e project: the service worker only exists
// in the production build, so those tests run against `dist/` instead of the dev server.
//   node e2e/serve-dist.mjs <directory> <port>
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve } from 'node:path';

const [directory, port] = process.argv.slice(2);
if (!directory || !port) throw new Error('usage: node serve-dist.mjs <directory> <port>');

const root = resolve(directory);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

createServer((request, response) => {
  const pathname = decodeURIComponent(new URL(request.url ?? '/', 'http://localhost').pathname);
  let file = normalize(join(root, pathname));
  // Never serve outside the build directory; unknown paths fall back to index.html (client-side routing).
  if (!file.startsWith(root) || !existsSync(file) || statSync(file).isDirectory()) file = join(root, 'index.html');
  response.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream', 'cache-control': 'no-cache' });
  createReadStream(file).pipe(response);
}).listen(Number(port), () => {
  process.stdout.write(`serving ${root} on http://localhost:${port}\n`);
});
