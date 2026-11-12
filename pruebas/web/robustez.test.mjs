// Robustez de la web (revisión del 11-nov-2026): lo que falló o podía fallar y ya no. Lógica sin DOM
// y comprobaciones sobre los ficheros de la web:
//   - el sueldo escrito se lee igual en la portada y en «Tu sueldo» del mapa («1.500» son mil quinientos);
//   - la vista de la dirección, dentro de lo que admite el mapa;
//   - la muestra de datos inventados solo es reserva en local y solo si el manifiesto no existe;
//   - en un recorrido, en pantallas estrechas, la página se coloca con el mapa arriba;
//   - las cuatro páginas y la plantilla llevan dirección canónica, idiomas y tarjeta para compartir;
//   - hay página de «no existe» y no depende de rutas relativas.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/robustez.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const SITIO = 'https://gastiaso.github.io/de-renta-en-renta/';

test('el sueldo escrito: un punto seguido de tres cifras es de millar, también en «Tu sueldo» del mapa', async () => {
  const { leerSueldo } = await modulo('web/js/sueldo.js');
  assert.equal(leerSueldo('1.500'), 1500);
  assert.equal(leerSueldo('1500'), 1500);
  assert.equal(leerSueldo('1.500,50'), 1500.5);
  assert.equal(leerSueldo('1500,5'), 1500.5);
  assert.equal(leerSueldo('1500.5'), 1500.5);   // como lo escribe un enlace compartido
  assert.equal(leerSueldo(' 1 500 € '), 1500);
  for (const mal of ['', 'mil', '1500 al mes', '-3', '0', '1.50.0', '200000']) assert.equal(leerSueldo(mal), null, mal);
  // Un solo lector: la portada reexporta el de sueldo.js y el panel del mapa lo usa
  const portada = await modulo('web/js/portada.js');
  assert.equal(portada.leerSueldo, leerSueldo);
  const panel = leerTexto('web', 'js', 'panel_sueldo.js');
  assert.match(panel, /const numero = \(input\) => leerSueldo\(input\.value\);/);
  assert.match(panel, /aria-invalid/);
  assert.match(leerTexto('web', 'mapa.html'), /<p id="sueldo-error" class="nota sueldo-error" role="alert" hidden data-i18n="interfaz\.sueldo\.error">/);
});

test('la vista de la dirección: zoom, latitud y longitud dentro de lo que admite el mapa', async () => {
  const { esValida, leerEstado } = await modulo('web/js/estado.js');
  for (const bien of ['11.30/40.42000/-3.70000', '4.6/39.8/-3.7', '0/0/0', '24/-90/180', '5/28.1/-15.4']) assert.ok(esValida('vista', bien), bien);
  for (const mal of ['5/95/0', '5/-91/0', '5/40/181', '25/40/-3', '5/40', 'a/b/c', '5/40/-3/2']) assert.ok(!esValida('vista', mal), mal);
  assert.equal(leerEstado('?vista=5/95/0&mapa=alquiler_mes').vista, undefined);
  assert.equal(leerEstado('?vista=5/40.4/-3.7').vista, '5/40.4/-3.7');
});

test('datos de ejemplo: solo en local y solo si el manifiesto no existe; nunca por un fallo', async () => {
  const { cargarManifiesto } = await modulo('web/js/datos.js');
  const servidor = (respuestas) => {
    const pedidas = [];
    const leer = async (ruta) => {
      pedidas.push(ruta);
      const r = respuestas[ruta] ?? { status: 404 };
      return { ok: r.status >= 200 && r.status < 300, status: r.status, json: async () => r.cuerpo };
    };
    return { leer, pedidas };
  };
  const ejemplo = { 'datos/ejemplo/manifiesto.json': { status: 200, cuerpo: { ejemplo: true, mapas: {} } } };
  // En local, sin manifiesto del pipeline (404): la muestra
  let s = servidor(ejemplo);
  assert.equal((await cargarManifiesto({ local: true, leer: s.leer })).ejemplo, true);
  assert.deepEqual(s.pedidas, ['datos/manifiesto.json', 'datos/ejemplo/manifiesto.json']);
  // En local, con el manifiesto caído (503): error, no la muestra
  s = servidor({ ...ejemplo, 'datos/manifiesto.json': { status: 503 } });
  await assert.rejects(cargarManifiesto({ local: true, leer: s.leer }), /datos\/manifiesto\.json: 503/);
  assert.deepEqual(s.pedidas, ['datos/manifiesto.json']);
  // En el sitio publicado: ni con 404 ni con 503 se pide la muestra
  for (const status of [404, 503]) {
    s = servidor({ ...ejemplo, 'datos/manifiesto.json': { status } });
    await assert.rejects(cargarManifiesto({ local: false, leer: s.leer }), new RegExp(`datos/manifiesto\\.json: ${status}`));
    assert.deepEqual(s.pedidas, ['datos/manifiesto.json']);
  }
});

test('recorrido en pantallas estrechas: la página se coloca con el mapa arriba (justo tras la barra de la vista)', async () => {
  const { destinoHistoria, mostrarHistoria } = await modulo('web/js/movil.js');
  assert.equal(destinoHistoria({ bottom: 350 }, 0), 356);
  assert.equal(destinoHistoria({ bottom: -6 }, 356), 356);   // ya colocada: mismo destino
  assert.equal(destinoHistoria({ bottom: -900 }, 100), 0);
  // En escritorio no hace nada; en una pantalla estrecha, se desplaza (sin animación con «reducir movimiento»)
  const ventana = (estrecha, reducir) => {
    const v = {
      scrollY: 0, innerHeight: 812, llamadas: [],
      matchMedia: (q) => ({ matches: q.includes('max-width') ? estrecha : reducir }),
      requestAnimationFrame: (f) => f(),
      scrollTo: (o) => v.llamadas.push(o),
    };
    return v;
  };
  const barra = { getBoundingClientRect: () => ({ bottom: 350 }) };
  let v = ventana(false, false);
  mostrarHistoria(barra, v);
  assert.deepEqual(v.llamadas, []);
  v = ventana(true, false);
  mostrarHistoria(barra, v);
  assert.deepEqual(v.llamadas, [{ top: 356, behavior: 'smooth' }]);
  v = ventana(true, true);
  mostrarHistoria(barra, v);
  assert.deepEqual(v.llamadas, [{ top: 356, behavior: 'auto' }]);
});

test('compartir: dirección canónica, los dos idiomas y la tarjeta, con direcciones absolutas, en las cuatro páginas', () => {
  const paginas = { 'index.html': '', 'mapa.html': 'mapa.html', 'sobrecarga.html': 'sobrecarga.html', 'historico.html': 'historico.html' };
  for (const [fichero, pagina] of Object.entries(paginas)) {
    const html = leerTexto('web', fichero);
    const url = SITIO + pagina;
    assert.ok(html.includes(`<link rel="canonical" href="${url}">`), `${fichero}: canonical`);
    assert.ok(html.includes(`<link rel="alternate" hreflang="es" href="${url}">`), `${fichero}: hreflang es`);
    assert.ok(html.includes(`<link rel="alternate" hreflang="en" href="${url}?idioma=en">`), `${fichero}: hreflang en`);
    assert.ok(html.includes(`<meta property="og:url" content="${url}">`), `${fichero}: og:url`);
    assert.ok(html.includes(`<meta property="og:image" content="${SITIO}estilo/tarjeta.png">`), `${fichero}: og:image`);
    assert.match(html, /<meta name="twitter:card" content="summary_large_image">/, fichero);
    // El título y la descripción de la tarjeta, los de la página
    const titulo = /<title>([^<]*)<\/title>/.exec(html)[1];
    assert.ok(html.includes(`<meta property="og:title" content="${titulo}">`), `${fichero}: og:title`);
    assert.match(html, /<meta property="og:description" content="[^"]{40,}">/, fichero);
    assert.match(html, /<link rel="icon" href="estilo\/fichas\/llave\.svg" type="image\/svg\+xml">/, fichero);
  }
  // La plantilla de «Método» y «Datos»: la página propia y las dos lenguas, absolutas
  const plantilla = leerTexto('web', 'herramientas', 'plantilla_documento.html');
  assert.ok(plantilla.includes(`<link rel="canonical" href="${SITIO}$if(es)$$pagina_es$$else$$pagina_en$$endif$">`));
  assert.ok(plantilla.includes(`<link rel="alternate" hreflang="es" href="${SITIO}$pagina_es$">`));
  assert.ok(plantilla.includes(`<link rel="alternate" hreflang="en" href="${SITIO}$pagina_en$">`));
  assert.ok(plantilla.includes(`<meta property="og:image" content="${SITIO}estilo/tarjeta.png">`));
  // La tarjeta existe, es un PNG y sale de una página del repositorio
  const tarjeta = join(raiz, 'web', 'estilo', 'tarjeta.png');
  assert.ok(existsSync(tarjeta), 'falta web/estilo/tarjeta.png');
  assert.deepEqual([...readFileSync(tarjeta).subarray(0, 8)], [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  assert.ok(statSync(tarjeta).size < 300 * 1024, 'la tarjeta pesa demasiado');
  assert.ok(existsSync(join(raiz, 'web', 'herramientas', 'tarjeta.html')));
});

test('página de «no existe»: sin rutas relativas (se sirve también en subcarpetas) y con salida a la portada y al mapa', () => {
  const html = leerTexto('web', '404.html');
  assert.match(html, /<meta name="robots" content="noindex">/);
  for (const [, destino] of html.matchAll(/(?:href|src)="([^"]*)"/g)) assert.ok(destino.startsWith(SITIO), destino);
  assert.ok(html.includes(`<a href="${SITIO}">`));
  assert.ok(html.includes(`<a href="${SITIO}mapa.html">`));
  assert.doesNotMatch(html, /<link rel="stylesheet"|<script/);
});

test('menú: el enlace a la propia página también lleva el idioma, y el mapa marca la entrada que toca', () => {
  // Sin esto, en inglés «Map» recargaría la página en castellano
  assert.match(leerTexto('web', 'js', 'principal.js'), /propio\.href = t\.idioma === 'en' \? 'mapa\.html\?idioma=en' : 'mapa\.html';/);
  assert.match(leerTexto('web', 'js', 'sobrecarga.js'), /propio\.href = `sobrecarga\.html\$\{estado\.idioma === 'en' \? '\?idioma=en' : ''\}`;/);
  assert.match(leerTexto('web', 'js', 'historico.js'), /propio\.href = `historico\.html\$\{estado\.idioma === 'en' \? '\?idioma=en' : ''\}`;/);
  // La marca del menú vale para la página y para una parte de ella («Tu sueldo»)
  assert.match(leerTexto('web', 'estilo', 'sitio.css'), /\.navegacion \[aria-current\] \{/);
});

test('el mapa: una carga superada no pinta, un fallo se dice sobre el mapa y se puede elegir con el teclado', () => {
  const principal = leerTexto('web', 'js', 'principal.js');
  // Dos tiempos: se pide todo y solo se vuelca si el cálculo sigue siendo el último
  assert.match(principal, /async function cargarColumnas\(series, referencia, yo\)/);
  assert.match(principal, /if \(yo !== turno\) return false;\n  for \(const pedido of pedidos\)/);
  assert.match(principal, /avisar\(\{ tipo: 'vista', clave: 'interfaz\.error_vista', boton: 'interfaz\.reintentar', accion: actualizar \}\)/);
  assert.match(principal, /avisar\(\{ tipo: 'historia', clave: 'interfaz\.historia\.no_disponible'/);
  assert.match(leerTexto('web', 'mapa.html'), /<p id="aviso-error" class="aviso-escala aviso-error" role="alert" hidden>/);
  // Intro elige el territorio del centro; la ficha ya no es región viva entera
  assert.match(leerTexto('web', 'js', 'mapa.js'), /if \(e\.key !== 'Enter' \|\| e\.altKey \|\| e\.ctrlKey \|\| e\.metaKey\) return;/);
  assert.match(leerTexto('web', 'mapa.html'), /<aside id="ficha" class="tarjeta ficha"><\/aside>\s*<p id="ficha-anuncio" class="oculto" role="status"><\/p>/);
  // Los textos nuevos, en los dos idiomas
  for (const idioma of ['es', 'en']) {
    const dic = JSON.parse(leerTexto('web', 'i18n', `${idioma}.json`));
    for (const clave of ['error_vista', 'reintentar']) assert.equal(typeof dic.interfaz[clave], 'string', `${idioma}: ${clave}`);
    assert.equal(typeof dic.interfaz.historia.no_disponible, 'string');
    assert.equal(typeof dic.interfaz.historia.nota, 'string');
    assert.equal(typeof dic.interfaz.sueldo.error, 'string');
    assert.equal(typeof dic.interfaz.mapa.lienzo, 'string');
    assert.equal(typeof dic.interfaz.buscador.sin_resultados, 'string');
  }
});
