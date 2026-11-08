// Servidor estático mínimo para el visor de comprobación (geo/visor/index.html), con peticiones
// por rangos (HTTP 206), que es lo que necesita PMTiles. Sin dependencias: solo Node.
// Uso, desde la carpeta del proyecto:  node geo/visor/servir.mjs [puerto]
// y abrir http://localhost:8765/geo/visor/ (sirve la carpeta del proyecto, solo en esta máquina).

import { createServer } from "node:http";
import { createReadStream, statSync } from "node:fs";
import { dirname, extname, join, normalize, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const raiz = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");   // carpeta del proyecto
const puerto = Number(process.argv[2] || 8765);
const tipos = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".mjs": "text/javascript",
  ".css": "text/css", ".json": "application/json", ".csv": "text/csv; charset=utf-8",
  ".pmtiles": "application/octet-stream", ".woff2": "font/woff2", ".svg": "image/svg+xml", ".png": "image/png"
};

createServer((req, res) => {
  if (req.method !== "GET" && req.method !== "HEAD") { res.writeHead(405).end(); return; }
  let ruta = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
  if (ruta.endsWith("/")) ruta += "index.html";
  const fichero = normalize(join(raiz, ruta));
  if (fichero !== raiz && !fichero.startsWith(raiz + sep)) { res.writeHead(403).end(); return; }
  let datos;
  try { datos = statSync(fichero); } catch { res.writeHead(404).end("No encontrado"); return; }
  if (!datos.isFile()) { res.writeHead(404).end("No encontrado"); return; }

  const cabeceras = { "Content-Type": tipos[extname(fichero)] || "application/octet-stream",
                      "Accept-Ranges": "bytes", "Cache-Control": "no-store" };
  const rango = /^bytes=(\d*)-(\d*)$/.exec(req.headers.range || "");
  if (rango && (rango[1] || rango[2])) {
    let inicio = rango[1] ? Number(rango[1]) : datos.size - Number(rango[2]);
    let fin = rango[1] && rango[2] ? Number(rango[2]) : datos.size - 1;
    inicio = Math.max(0, inicio); fin = Math.min(fin, datos.size - 1);
    if (inicio > fin) { res.writeHead(416, { "Content-Range": `bytes */${datos.size}` }).end(); return; }
    res.writeHead(206, { ...cabeceras, "Content-Range": `bytes ${inicio}-${fin}/${datos.size}`,
                         "Content-Length": fin - inicio + 1 });
    if (req.method === "HEAD") { res.end(); return; }
    createReadStream(fichero, { start: inicio, end: fin }).pipe(res);
  } else {
    res.writeHead(200, { ...cabeceras, "Content-Length": datos.size });
    if (req.method === "HEAD") { res.end(); return; }
    createReadStream(fichero).pipe(res);
  }
}).listen(puerto, "127.0.0.1", () => {
  console.log(`Sirviendo ${raiz} en http://localhost:${puerto}/geo/visor/  (Ctrl+C para parar)`);
});
