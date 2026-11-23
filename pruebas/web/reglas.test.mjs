// Pruebas de la página «Reglas del juego» (tarea 64) sin navegador: lógica de web/js/reglas_datos.js
// con la muestra inventada de pruebas/datos/reglas_inventado.json, textos de los dos diccionarios,
// HTML de la página y de los menús, casillas de la portada y enlace de la ficha del indicador 20. Si
// el pipeline ya ha exportado web/datos/reglas.json, se comprueba también su contrato con el inventario.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/reglas.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const R = await import(pathToFileURL(join(raiz, 'web/js/reglas_datos.js')).href);
const leerTexto = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');
const leerJson = (...ruta) => JSON.parse(leerTexto(...ruta));
const muestra = () => leerJson('pruebas', 'datos', 'reglas_inventado.json');

// CSV mínimo (comillas dobles, saltos de línea dentro de los campos): filas como objetos
function leerCsv(texto) {
  const filas = [];
  let fila = [], campo = '', comillas = false;
  for (let i = 0; i < texto.length; i++) {
    const c = texto[i];
    if (comillas) {
      if (c === '"' && texto[i + 1] === '"') { campo += '"'; i++; } else if (c === '"') comillas = false; else campo += c;
    } else if (c === '"') comillas = true;
    else if (c === ',') { fila.push(campo); campo = ''; } else if (c === '\n') { fila.push(campo.replace(/\r$/, '')); filas.push(fila); fila = []; campo = ''; } else campo += c;
  }
  if (campo || fila.length) { fila.push(campo); filas.push(fila); }
  const [cabecera, ...resto] = filas;
  return resto.filter((f) => f.length > 1).map((f) => Object.fromEntries(cabecera.map((c, k) => [c, f[k] ?? ''])));
}

function traductor(idioma) {
  const dic = leerJson('web', 'i18n', `${idioma}.json`);
  const t = (clave, valores = {}) => {
    const texto = clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);
    if (typeof texto !== 'string') throw new Error(`Falta ${clave} (${idioma})`);
    return texto.replace(/\{(\w+)\}/g, (m, n) => (n in valores ? valores[n] : m));
  };
  t.idioma = idioma;
  return t;
}

test('estado de la dirección: solo el idioma', () => {
  assert.deepEqual(R.leerEstado(''), { idioma: 'es' });
  assert.deepEqual(R.leerEstado('?idioma=en'), { idioma: 'en' });
  assert.deepEqual(R.leerEstado('?idioma=fr'), { idioma: 'es' });
  assert.equal(R.consulta({ idioma: 'en' }), '?idioma=en');
  assert.equal(R.ancla('zonas_tensionadas'), 'zonas-tensionadas');
});

test('enlaces de los textos: al BOE o a páginas del atlas, en el idioma de la página', () => {
  assert.equal(R.destinoEnlace('https://www.boe.es/buscar/act.php?id=BOE-A-1994-26003#a36', 'en'),
    'https://www.boe.es/buscar/act.php?id=BOE-A-1994-26003#a36');
  assert.equal(R.destinoEnlace('mapa.html?mapa=zona_tensionada', 'es'), 'mapa.html?mapa=zona_tensionada');
  assert.equal(R.destinoEnlace('mapa.html?mapa=zona_tensionada', 'en'), 'mapa.html?mapa=zona_tensionada&idioma=en');
  assert.equal(R.destinoEnlace('mapa.html#tu-sueldo', 'en'), 'mapa.html?idioma=en#tu-sueldo');
  assert.equal(R.destinoEnlace('metodo.html#71-alquiler', 'en'), 'method.html#71-alquiler');
  assert.equal(R.destinoEnlace('#fianza-garantias', 'es'), 'reglas.html#fianza-garantias');
  assert.equal(R.destinoEnlace('https://example.com/', 'es'), null);
  assert.equal(R.destinoEnlace('javascript:alert(1)', 'es'), null);
  assert.equal(R.destinoEnlace('otra.html', 'es'), null);
  const trozos = R.trozosTexto('Ver [el mapa](mapa.html?mapa=a) y [fuera](https://example.com/).', 'en');
  assert.deepEqual(trozos, [{ texto: 'Ver ' }, { texto: 'el mapa', href: 'mapa.html?mapa=a&idioma=en' }, { texto: ' y ' },
    { texto: 'fuera' }, { texto: '.' }]);
  assert.deepEqual(R.trozosTexto('Sin enlaces.'), [{ texto: 'Sin enlaces.' }]);
});

test('resúmenes en orden, borradores, normas y línea de estado', () => {
  const d = muestra();
  const lista = R.resumenes(d);
  assert.deepEqual(lista.map((r) => r.id), ['fianza_prueba', 'duracion_prueba']);
  assert.equal(R.borradores(d), 1);
  assert.ok(R.esBorrador(lista[1]));
  assert.ok(!R.esBorrador(lista[0]));
  const normas = R.normasDe(lista[1], d);
  assert.equal(R.etiquetaNorma(normas[0], 'es'), 'Ley 1/2099, Artículo 1');
  assert.equal(R.etiquetaNorma(normas[0], 'en'), 'Test Act, Artículo 1');   // el título del bloque, el oficial
  assert.deepEqual(R.pendientesDe(lista[1], d).map((n) => n.norma), ['BOE-A-2099-2']);
  assert.deepEqual(R.pendientesDe(lista[0], d), []);
  for (const idioma of ['es', 'en']) {
    const t = traductor(idioma);
    const pendiente = R.lineasEstado(lista[1], d, idioma).map((l) => t(l.clave, l.valores)).join(' ');
    assert.match(pendiente, /2099-02-04/);
    assert.match(pendiente, idioma === 'es' ? /Real Decreto-ley 2\/2099, pendiente de convalidación/ : /Royal Decree-law 2\/2099, pending ratification/);
    const vigente = R.lineasEstado(lista[0], d, idioma).map((l) => t(l.clave, l.valores)).join(' ');
    assert.doesNotMatch(vigente, /pendiente|pending/);
  }
  assert.equal(R.fechaConsulta(d), '2099-03-01');
});

test('versión publicada: un resumen en revisión sale sin texto, con su título y su ancla', () => {
  const d = muestra();
  // Lo que deja reglas_para_publicar() (R/reglas.R) de un borrador
  d.reglas[0] = { id: d.reglas[0].id, ancla: d.reglas[0].ancla, orden: d.reglas[0].orden, titulo: d.reglas[0].titulo, en_revision: true };
  d.borradores = 0;
  const r = R.resumenes(d).find((x) => x.id === 'duracion_prueba');
  assert.ok(R.enRevision(r));
  assert.equal(R.borradores(d), 0);   // sin aviso de vista local
  assert.equal(R.todosEnRevision(d), false);   // uno en revisión, los demás con texto: la entradilla de siempre
  assert.deepEqual(R.lineasEstado(r, d, 'es'), [{ clave: 'reglas.estado.en_revision', valores: {} }]);
  assert.equal(R.enIdioma(r.titulo, 'en'), 'Test duration');
  // Con todos en revisión (el sitio antes de la firma), la entradilla condicional (23-nov-2026)
  for (const x of d.reglas) x.en_revision = true;
  assert.equal(R.todosEnRevision(d), true);
  assert.equal(R.todosEnRevision({ reglas: [] }), false);
});

test('textos de la página en los dos idiomas', () => {
  const claves = ['nav.reglas', 'reglas.titulo_pagina', 'reglas.descripcion', 'reglas.antetitulo', 'reglas.titulo',
    'reglas.entradilla', 'reglas.entradilla_revision', 'reglas.distintivo', 'reglas.carga', 'reglas.error_carga', 'reglas.indice', 'reglas.aviso_borradores',
    'reglas.borrador', 'reglas.consultado', 'reglas.revisado', 'reglas.sin_revisar', 'reglas.declaraciones',
    'reglas.pie.informativo', 'reglas.pie.boe', 'reglas.pie.patrocinio', 'reglas.estado.vigente_desde', 'reglas.estado.pendiente',
    'reglas.estado.en_revision', 'interfaz.ficha.zonas.que_supone', 'interfaz.ficha.zonas.regla_tope',
    ...R.SECCIONES.map((s) => `reglas.secciones.${s}`), 'reglas.secciones.normas'];
  for (const idioma of ['es', 'en']) {
    const t = traductor(idioma);
    for (const clave of claves) assert.ok(t(clave).length > 0, `${clave} (${idioma})`);
  }
  // Con todo en revisión, la entradilla no promete los enlaces al BOE (23-nov-2026)
  assert.match(traductor('es')('reglas.entradilla_revision'), /solo se publican sus títulos/);
  assert.doesNotMatch(traductor('es')('reglas.entradilla_revision'), /Cada resumen enlaza/);
  assert.match(traductor('en')('reglas.entradilla_revision'), /only their titles are published/);
  // Nombre y subtítulo decididos (13-nov-2026)
  assert.equal(traductor('es')('nav.reglas'), 'Reglas del juego');
  assert.equal(traductor('es')('reglas.antetitulo'), 'Normativa vigente');
  // Aviso legal del BOE: texto consolidado meramente informativo, atribución, fecha y sin patrocinio
  const es = traductor('es');
  assert.match(es('reglas.pie.informativo'), /meramente informativo/);
  assert.match(es('reglas.pie.boe'), /Basado en datos de la Agencia Estatal Boletín Oficial del Estado/);
  assert.match(es('reglas.pie.boe'), /\{fecha\}|consultados el/);
  assert.match(es('reglas.pie.patrocinio'), /no participa en este atlas ni lo patrocina/);
});

test('reglas.html: menú, pie, carga y etiquetas para compartir', () => {
  const html = leerTexto('web', 'reglas.html');
  assert.match(html, /<a href="reglas\.html" aria-current="page" data-i18n="nav\.reglas">Reglas del juego<\/a>/);
  for (const id of ['rg-estado', 'rg-contenido', 'rg-aviso-borrador', 'rg-indice', 'rg-resumenes', 'rg-pie-boe']) {
    assert.match(html, new RegExp(`id="${id}"`), id);
  }
  for (const clave of ['reglas.pie.informativo', 'reglas.pie.patrocinio', 'reglas.antetitulo', 'reglas.titulo']) {
    assert.ok(html.includes(`data-i18n="${clave}"`), clave);
  }
  assert.match(html, /<script type="module" src="js\/reglas\.js"><\/script>/);
  assert.match(html, /<link rel="canonical" href="https:\/\/gastiaso\.github\.io\/de-renta-en-renta\/reglas\.html">/);
  assert.match(html, /hreflang="en" href="https:\/\/gastiaso\.github\.io\/de-renta-en-renta\/reglas\.html\?idioma=en"/);
  assert.ok(existsSync(join(raiz, 'web', 'estilo', 'reglas.css')));
});

test('menús: «Reglas del juego» entre «Sobrecarga» y «Datos» en todas las páginas y en la plantilla', () => {
  for (const pagina of ['index.html', 'mapa.html', 'sobrecarga.html', 'historico.html', 'reglas.html']) {
    const nav = /<nav class="navegacion"[^>]*>([\s\S]*?)<\/nav>/.exec(leerTexto('web', pagina))[1];
    const enlaces = [...nav.matchAll(/data-i18n="(nav\.\w+)"/g)].map((m) => m[1]);
    const i = enlaces.indexOf('nav.reglas');
    assert.ok(i > 0, pagina);
    assert.equal(enlaces[i - 1], 'nav.sobrecarga', pagina);
    assert.equal(enlaces[i + 1], 'nav.datos', pagina);
  }
  const plantilla = leerTexto('web', 'herramientas', 'plantilla_documento.html');
  assert.ok(plantilla.indexOf('$texto_reglas$') > plantilla.indexOf('$texto_sobrecarga$'));
  assert.ok(plantilla.indexOf('$texto_reglas$') < plantilla.indexOf('$texto_datos$'));
  assert.match(leerTexto('web', 'herramientas', 'documento_es.yaml'), /^reglas: "reglas\.html"$/m);
  assert.match(leerTexto('web', 'herramientas', 'documento_en.yaml'), /^reglas: "reglas\.html\?idioma=en"$/m);
  assert.match(leerTexto('.github', 'workflows', 'pages.yml'), /texto_reglas=/);
});

test('portada y ficha del 20: llevan a anclas que existen en el inventario', () => {
  const reglas = leerCsv(leerTexto('inventario', 'reglas.csv'));
  const anclas = new Set(reglas.map((r) => R.ancla(r.id)));
  assert.equal(reglas.length, 7);
  const casillas = leerCsv(leerTexto('inventario', 'casillas_portada.csv'));
  const aReglas = casillas.filter((c) => c.activa === 'TRUE' && c.destino.startsWith('reglas.html'));
  // Decisión del autor (13-nov-2026): la 7, la 10, la 17 y la 22, a sus anclas; la 3 y la 8, sin cambios
  assert.deepEqual(aReglas.map((c) => Number(c.orden)).sort((a, b) => a - b), [7, 10, 17, 22]);
  for (const c of aReglas) {
    const marca = c.destino.split('#')[1];
    if (marca) assert.ok(anclas.has(marca), `${c.id}: #${marca}`);
  }
  const porId = Object.fromEntries(casillas.map((c) => [c.id, c]));
  assert.ok(porId.fianza.destino.startsWith('metodo.html'));
  assert.ok(porId.tope_alquileres.destino.startsWith('mapa.html?mapa=var_alquiler'));
  // La portada ya escrita (escribir_casillas_portada()) lleva los mismos enlaces, también en inglés
  const index = leerTexto('web', 'index.html');
  assert.match(index, /data-casilla="ley_vivienda"><a href="reglas\.html" data-href-es="reglas\.html" data-href-en="reglas\.html\?idioma=en"/);
  assert.match(index, /data-href-en="reglas\.html\?idioma=en#fianza-garantias"/);
  // Ficha del indicador 20 y de la variación del alquiler (destino de la casilla 8): a la regla
  const ficha = leerTexto('web', 'js', 'ficha.js');
  assert.match(ficha, /enlaceRegla\(t, 'zonas-tensionadas', 'interfaz\.ficha\.zonas\.que_supone'\)/);
  assert.match(ficha, /REGLA_DE_MAPA = \{ var_alquiler: 'zonas-tensionadas' \}/);
  assert.ok(anclas.has('zonas-tensionadas'));
  // Y la nota metodológica, destino de la casilla 3, enlaza la regla de la fianza
  assert.match(leerTexto('docs', 'metodologia.md'), /\(https:\/\/gastiaso\.github\.io\/de-renta-en-renta\/reglas\.html#fianza-garantias\)/);
  assert.match(leerTexto('docs', 'methodology.md'), /\(https:\/\/gastiaso\.github\.io\/de-renta-en-renta\/reglas\.html\?idioma=en#fianza-garantias\)/);
});

test('datos/reglas.json real: mismos resúmenes que el inventario, con sus textos en los dos idiomas', { skip: !existsSync(join(raiz, 'web', 'datos', 'reglas.json')) }, () => {
  const d = leerJson('web', 'datos', 'reglas.json');
  const inventario = leerCsv(leerTexto('inventario', 'reglas.csv'));
  assert.deepEqual(R.resumenes(d).map((r) => r.id), [...inventario].sort((a, b) => a.orden - b.orden).map((r) => r.id));
  for (const r of R.resumenes(d)) {
    if (R.enRevision(r)) continue;
    for (const s of R.SECCIONES) {
      assert.equal(r[s].es.length, r[s].en.length, `${r.id}.${s}`);
      for (const idioma of ['es', 'en']) {
        for (const p of r[s][idioma]) {
          // Ningún enlace de los textos se pierde: todos van al BOE o a una página del atlas
          const n = [...p.matchAll(/\[[^\]]+\]\([^)\s]+\)/g)].length;
          assert.equal(R.trozosTexto(p, idioma).filter((x) => x.href).length, n, `${r.id}.${s}: ${p}`);
        }
      }
    }
    for (const n of r.normas) {
      assert.match(n.url, /^https:\/\/www\.boe\.es\//);
      assert.ok(d.normas[n.norma], n.norma);
    }
  }
});
