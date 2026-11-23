// Pruebas sin navegador de la tarea 50 (backlog, «Móvil»): a 375 px, tocar un territorio deja su
// ficha a la vista sin desplazarse a mano; controles plegables; menú sin desplazamiento horizontal.
//   - movil.js: cuándo baja la página hasta la ficha y hasta dónde, solo en pantallas estrechas y
//     respetando «reducir movimiento»; el botón que pliega la barra (aria-expanded y su texto);
//   - mapa.html: qué se pliega (la tipología y las descargas; nunca el mapa ni el año) y que el
//     botón señala lo que pliega;
//   - sitio.css: por debajo del corte de movil.js, el menú se parte en líneas (sin overflow-x), la
//     ficha va antes que «Tu sueldo» y el botón solo se ve ahí;
//   - principal.js: los tres clics del mapa (sección, territorio, suelo sin sección) bajan a la ficha.
// La prueba en un navegador de verdad (375 × 812, tocar el mapa y ver la ficha) está en
// comprobar_web_navegador() (R/web_navegador.R, navegador_movil).
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/movil.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const movil = await modulo('web/js/movil.js');

// Ventana de pega: ancho, alto, desplazamiento y «reducir movimiento»
function ventana({ ancho = 375, alto = 812, scrollY = 0, reducir = false } = {}) {
  const v = {
    innerHeight: alto, scrollY, desplazado: null,
    matchMedia: (q) => ({
      matches: q.includes('prefers-reduced-motion') ? reducir : ancho <= Number(/max-width: (\d+)px/.exec(q)?.[1] ?? 0),
    }),
    requestAnimationFrame: (f) => f(),
    scrollTo: (o) => { v.desplazado = o; },
  };
  return v;
}
const ficha = (top) => ({ getBoundingClientRect: () => ({ top, bottom: top + 400 }) });

test('ficha: baja si queda debajo de media pantalla o por encima; si ya se ve, no', () => {
  assert.equal(movil.hayQueDesplazar({ top: 921 }, 812), true);    // bajo el mapa, fuera de la pantalla
  assert.equal(movil.hayQueDesplazar({ top: 700 }, 812), true);    // asoma una tira
  assert.equal(movil.hayQueDesplazar({ top: -300 }, 812), true);   // ya pasada
  assert.equal(movil.hayQueDesplazar({ top: 8 }, 812), false);
  assert.equal(movil.hayQueDesplazar({ top: 400 }, 812), false);
  assert.equal(movil.hayQueDesplazar(null, 812), false);
  assert.equal(movil.hayQueDesplazar({ top: 900 }, 0), false);
  assert.equal(movil.destinoDesplazamiento({ top: 921 }, 0), 913);
  assert.equal(movil.destinoDesplazamiento({ top: -20 }, 10), 0);
});

test('ficha: a 375 px baja hasta ella (suave, o sin animación con «reducir movimiento»); a 1280 px, nada', () => {
  const v = ventana();
  movil.mostrarFicha(ficha(921), v);
  assert.deepEqual(v.desplazado, { top: 913, behavior: 'smooth' });
  const r = ventana({ reducir: true, scrollY: 100 });
  movil.mostrarFicha(ficha(921), r);
  assert.deepEqual(r.desplazado, { top: 1013, behavior: 'auto' });
  const visible = ventana();
  movil.mostrarFicha(ficha(10), visible);
  assert.equal(visible.desplazado, null);
  const escritorio = ventana({ ancho: 1280, alto: 720 });
  movil.mostrarFicha(ficha(921), escritorio);
  assert.equal(escritorio.desplazado, null);
  assert.doesNotThrow(() => movil.mostrarFicha(null, v));
});

test('ficha en escritorio: la columna lateral baja hasta ella si no se ve; la página, no (23-nov-2026)', () => {
  // Zamora a 1366 × 768: la columna empieza a 150 px y se ven 581; la ficha, a 1.422 px
  const columna = (scrollTop = 0) => ({
    scrollTop, desplazado: null,
    getBoundingClientRect: () => ({ top: 150, height: 581 }),
    scrollTo(o) { this.desplazado = o; },
  });
  const enColumna = (top, lateral) => ({ ...ficha(top), closest: (s) => (s === '.lateral' ? lateral : null) });
  assert.equal(movil.destinoLateral({ top: 1422 }, { top: 150 }, 0), 1264);
  assert.equal(movil.destinoLateral({ top: 100 }, { top: 150 }, 30), 0);
  const v = ventana({ ancho: 1366, alto: 768 });
  const c = columna();
  movil.mostrarFicha(enColumna(1422, c), v);
  assert.deepEqual(c.desplazado, { top: 1264, behavior: 'smooth' });
  assert.equal(v.desplazado, null);                       // la página no se mueve
  const r = columna(200);
  movil.mostrarFicha(enColumna(1422, r), ventana({ ancho: 1366, alto: 768, reducir: true }));
  assert.deepEqual(r.desplazado, { top: 1464, behavior: 'auto' });
  const visible = columna();
  movil.mostrarFicha(enColumna(300, visible), v);          // ya a la vista, arriba de la columna
  assert.equal(visible.desplazado, null);
  // El buscador también la enseña al elegir (principal.js)
  const principal = readFileSync(join(process.cwd(), 'web', 'js', 'principal.js'), 'utf8');
  const buscador = principal.slice(principal.indexOf('function prepararBuscador'), principal.indexOf('function pintarPie'));
  assert.equal((buscador.match(/mostrarFicha\(el\.ficha\)/g) ?? []).length, 3);
});

test('historias: los botones del paso, fijos al pie también en escritorio (23-nov-2026)', () => {
  const css = readFileSync(join(process.cwd(), 'web', 'estilo', 'sitio.css'), 'utf8');
  const movil = css.indexOf('@media (max-width: 760px)');
  const regla = css.search(/\n\.historia-acciones \{[^}]*position: sticky; bottom: 0;[^}]*background: var\(--color-placa\)/);
  assert.ok(regla > 0 && regla < movil, 'la regla sticky va fuera de la media de pantallas estrechas');
});

test('barra: el botón pliega y despliega, con aria-expanded y su texto', () => {
  const oyentes = [];
  const boton = { atributos: {}, textContent: '', setAttribute(k, x) { this.atributos[k] = x; }, addEventListener: (_, f) => oyentes.push(f) };
  const barra = { dataset: { plegada: 'true' } };
  const t = (k) => k;
  const p = movil.prepararPlegado(barra, boton, t);
  assert.equal(boton.atributos['aria-expanded'], 'false');
  assert.equal(boton.textContent, 'interfaz.vista.mas_opciones');
  oyentes[0]();
  assert.equal(barra.dataset.plegada, 'false');
  assert.equal(boton.atributos['aria-expanded'], 'true');
  assert.equal(boton.textContent, 'interfaz.vista.menos_opciones');
  p.traducir((k) => `[${k}]`);
  assert.equal(boton.textContent, '[interfaz.vista.menos_opciones]');
  assert.doesNotThrow(() => movil.prepararPlegado(null, null, t).traducir(t));
});

test('mapa.html: se pliegan la tipología y las descargas, nunca el mapa ni el año; el botón lo señala', () => {
  const html = leerTexto('web', 'mapa.html');
  const barra = html.split('id="barra-vista"')[1].split('</section>')[0];
  assert.match(html, /id="barra-vista" class="barra-vista"[^>]*data-plegada="true"/);
  const plegables = [...barra.matchAll(/<div id="([^"]+)" class="[^"]*\bbarra-plegable\b/g)].map((x) => x[1]);
  assert.deepEqual(plegables.sort(), ['vista-descargas', 'vista-tipologia']);
  const boton = /<button id="vista-plegar"[^>]*>/.exec(barra)?.[0] ?? '';
  assert.match(boton, /aria-expanded="false"/);
  assert.deepEqual(/aria-controls="([^"]+)"/.exec(boton)[1].split(' ').sort(), plegables.sort());
  assert.match(boton, /data-i18n="interfaz\.vista\.mas_opciones"/);
  for (const id of ['vista-mapa', 'vista-anio']) {
    const campo = barra.split(`id="${id}"`)[0].split('<label').at(-1);
    assert.doesNotMatch(campo, /barra-plegable/, id);
  }
  for (const idioma of ['es', 'en']) {
    const dic = JSON.parse(leerTexto('web', 'i18n', `${idioma}.json`));
    assert.ok(dic.interfaz.vista.mas_opciones && dic.interfaz.vista.menos_opciones, idioma);
  }
});

test('sitio.css: en pantallas estrechas, menú en líneas, ficha antes que «Tu sueldo» y botón a la vista', () => {
  const css = leerTexto('web', 'estilo', 'sitio.css');
  const corte = `@media (max-width: ${movil.ANCHO_MOVIL}px)`;
  assert.ok(css.includes(corte), 'el corte de movil.js es el de la hoja');
  const bloque = css.split(corte)[1];
  const regla = (sel) => new RegExp(`(^|\\n)\\s*${sel.replace(/[.#[\]()]/g, '\\$&')} \\{([^}]*)\\}`).exec(bloque)?.[2] ?? '';
  assert.match(regla('.navegacion'), /flex-wrap: wrap/);
  assert.doesNotMatch(regla('.navegacion'), /overflow-x|nowrap/);
  assert.match(regla('#ficha'), /order: -1/);
  assert.match(regla('.barra-plegar'), /display: inline-flex/);
  assert.match(regla('.barra-vista[data-plegada="true"] .barra-plegable'), /display: none/);
  // Fuera del bloque, el botón no se ve: en escritorio la barra no cambia
  assert.match(css.split(corte)[0], /\.barra-plegar \{ display: none; \}/);
});

test('principal.js: los tres clics del mapa bajan hasta la ficha', () => {
  const js = leerTexto('web', 'js', 'principal.js');
  const cuerpo = (nombre) => js.split(nombre)[1].split('\n}\n')[0];
  assert.match(cuerpo('const alPulsarTerritorio = '), /mostrarFicha\(el\.ficha\)/);
  assert.equal((cuerpo('function alPulsar(codigo)').match(/mostrarFicha\(el\.ficha\)/g) ?? []).length, 2);
  assert.match(cuerpo('function alPulsarSinSeccion('), /mostrarFicha\(el\.ficha\)/);
});

// Decisión del autor (12-nov-2026): en pantallas estrechas el mapa pide dos dedos para moverse
// (cooperativeGestures de MapLibre) y un dedo desplaza la página; en escritorio, nada. mapa.js
// importa maplibre-gl por su nombre (import map), así que aquí se lee como texto.
test('mapa.js: gestos cooperativos solo en pantallas estrechas, con sus textos', () => {
  const js = leerTexto('web', 'js', 'mapa.js');
  assert.match(js, /import \{ esPantallaEstrecha \} from '\.\/movil\.js';/);
  assert.match(js, /export const GESTOS_COOPERATIVOS_MOVIL = (true|false);/);
  const cuerpo = js.split('export function opcionesGestos(')[1].split('\n}\n')[0];
  assert.match(cuerpo, /if \(!GESTOS_COOPERATIVOS_MOVIL \|\| !estrecha\) return \{ opciones: \{\}, textos: \{\} \};/);
  assert.match(cuerpo, /cooperativeGestures: true/);
  for (const clave of ['WindowsHelpText', 'MacHelpText', 'MobileHelpText']) {
    assert.match(cuerpo, new RegExp(`'CooperativeGesturesHandler\.${clave}'`));
  }
  // Las opciones entran en el mapa (y en ningún otro sitio se enciende el gesto)
  assert.match(js, /\.\.\.gestos\.opciones,/);
  assert.match(js, /\.\.\.gestos\.textos,/);
  assert.equal((js.match(/cooperativeGestures/g) ?? []).length, 1);
  // Los textos de la ayuda, en los dos idiomas
  for (const idioma of ['es', 'en']) {
    const dic = JSON.parse(leerTexto('web', 'i18n', `${idioma}.json`));
    for (const clave of ['gesto_windows', 'gesto_mac', 'gesto_movil']) {
      assert.equal(typeof dic.interfaz.mapa[clave], 'string', `${idioma}: interfaz.mapa.${clave}`);
    }
  }
  // La misma versión de MapLibre trae esas claves en su locale
  const maplibre = leerTexto('web', 'vendor', 'maplibre-gl', 'maplibre-gl.mjs');
  for (const clave of ['WindowsHelpText', 'MacHelpText', 'MobileHelpText']) {
    assert.ok(maplibre.includes(`"CooperativeGesturesHandler.${clave}"`), clave);
  }
});
