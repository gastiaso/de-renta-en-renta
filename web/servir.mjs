// Servidor local de la web: sirve la carpeta web/ en http://localhost:8000.
//
// Atiende rangos HTTP (cabecera Range), que el PMTiles necesita para leer solo los trozos del
// fichero que pide el mapa; `python -m http.server` no los atiende. Solo usa Node, sin paquetes.
//
// Uso, desde la raíz del proyecto:   node web/servir.mjs          (puerto 8000)
//                                    node web/servir.mjs 8080     (otro puerto)
// Solo escucha en el propio equipo (127.0.0.1). Ctrl+C para pararlo.

import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = resolve(fileURLToPath(new URL('.', import.meta.url)));
const puerto = Number(process.argv[2] ?? 8000);

const TIPOS = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.geojson': 'application/geo+json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.md': 'text/plain; charset=utf-8',
  '.bin': 'application/octet-stream',
  '.pmtiles': 'application/octet-stream',
};

function responder(res, codigo, texto, cabeceras = {}) {
  res.writeHead(codigo, { 'Content-Type': 'text/plain; charset=utf-8', ...cabeceras });
  res.end(texto);
}

async function atender(pet, res) {
  if (pet.method !== 'GET' && pet.method !== 'HEAD') return responder(res, 405, 'Método no admitido', { Allow: 'GET, HEAD' });

  const ruta = decodeURIComponent(new URL(pet.url, 'http://localhost').pathname);
  let fichero = resolve(join(raiz, ruta));
  if (fichero !== raiz && !fichero.startsWith(raiz + sep)) return responder(res, 403, 'Fuera de la carpeta web');

  let info = await stat(fichero).catch(() => null);
  if (info?.isDirectory()) {
    fichero = join(fichero, 'index.html');
    info = await stat(fichero).catch(() => null);
  }
  if (!info?.isFile()) return responder(res, 404, `No existe: ${ruta}`);

  const cabeceras = {
    'Content-Type': TIPOS[extname(fichero).toLowerCase()] ?? 'application/octet-stream',
    'Accept-Ranges': 'bytes',
    'Cache-Control': 'no-cache',
    'Last-Modified': info.mtime.toUTCString(),
  };
  const total = info.size;
  let inicio = 0;
  let fin = total - 1;
  let codigo = 200;

  const rango = pet.headers.range;
  if (rango) {
    const m = /^bytes=(\d*)-(\d*)$/.exec(rango.trim());
    if (m && (m[1] !== '' || m[2] !== '')) {
      if (m[1] === '') {                       // bytes=-N: los N últimos
        inicio = Math.max(0, total - Number(m[2]));
      } else {
        inicio = Number(m[1]);
        if (m[2] !== '') fin = Math.min(Number(m[2]), total - 1);
      }
    }
    if (!m || inicio > fin || inicio >= total) {
      return responder(res, 416, 'Rango no válido', { 'Content-Range': `bytes */${total}` });
    }
    codigo = 206;
    cabeceras['Content-Range'] = `bytes ${inicio}-${fin}/${total}`;
  }

  cabeceras['Content-Length'] = total === 0 ? 0 : fin - inicio + 1;
  res.writeHead(codigo, cabeceras);
  if (pet.method === 'HEAD' || total === 0) return res.end();
  createReadStream(fichero, { start: inicio, end: fin }).pipe(res);
}

const servidor = createServer((pet, res) => {
  atender(pet, res).catch((error) => {
    console.error(error);
    if (!res.headersSent) responder(res, 500, 'Error del servidor');
    else res.destroy();
  });
});

servidor.on('error', (error) => {
  if (error.code === 'EADDRINUSE') console.error(`El puerto ${puerto} está ocupado: prueba con  node web/servir.mjs ${puerto + 1}`);
  else console.error(error);
  process.exit(1);
});

servidor.listen(puerto, '127.0.0.1', () => {
  console.log(`De renta en renta, en local: http://localhost:${puerto}/   (Ctrl+C para parar)`);
});
