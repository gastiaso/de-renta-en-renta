// Pruebas sin navegador de la capa del Notariado (19-nov-2026; R/web_notariado.R y web/js/notariado.js):
// licencia propia no comercial («© Consejo General del Notariado, solo uso no comercial») y solo web.
//   - la web pide su manifiesto como capa, aparte del general, y unirCapas() suma sus series y mapas
//     junto a los de los portales, con la licencia y la fecha de la foto en la cabecera de la capa;
//   - cada serie lleva la etiqueta de su fuente en los dos idiomas, y el CSV no se ofrece (la imagen,
//     sí), con su propio aviso;
//   - la ficha cita la fecha de la foto de 12 meses y el umbral de 20 compraventas;
//   - con la exportación del pipeline (web/datos/notariado/, que va en git): el manifiesto existe y,
//     encendido, lleva la licencia, sus series son de las dos fuentes del Notariado y ninguna está en
//     el manifiesto general.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/notariado.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerJson = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
// cargarIdioma() pide i18n/<idioma>.json: aquí, el fichero de web/i18n.
globalThis.fetch = async (ruta) => ({ ok: true, json: async () => leerJson('web', ruta) });

const datos = await modulo('web/js/datos.js');
const exportar = await modulo('web/js/exportar.js');
const notariado = await modulo('web/js/notariado.js');
const { cargarIdioma } = await modulo('web/js/i18n.js');
const t = { es: await cargarIdioma('es'), en: await cargarIdioma('en') };
const LICENCIA = '© Consejo General del Notariado, solo uso no comercial';

const general = {
  version: '2026-11-19', ejemplo: false,
  indicadores: { renta_persona: { niveles: ['sc', 'municipio'], anios: [2024], ruta: 'datos/{nivel}/renta_persona/{anio}.json' } },
  mapas: { renta_persona: { base: 'renta_persona', formula: 'directo', cortes: [10, 20] } },
};
const capaNotariado = {
  capa: 'notariado', activa: true, version: '2026-11-19', generado: '2026-11-19', licencia: LICENCIA, foto: '2026-10-21',
  indicadores: {
    precio_escriturado_m2: {
      id: 25, niveles: ['municipio', 'provincia', 'ccaa', 'nacional'], anios: [2026], decimales: 0,
      ruta: 'datos/notariado/{nivel}/precio_escriturado_m2/{anio}.json', fuente: 'notariado', foto: '2026-10-21', minimo_informadas: 20,
    },
    hipotecas_compra_vivienda: {
      id: 28, niveles: ['provincia', 'ccaa', 'nacional'], anios: [2024, 2025], decimales: 0,
      ruta: 'datos/notariado/{nivel}/hipotecas_compra_vivienda/{anio}.json', fuente: 'notariado_cien',
    },
  },
  mapas: {
    precio_escriturado_m2: { base: 'precio_escriturado_m2', formula: 'directo', cortes: [600, 900], nivel_minimo: 'municipio' },
    hipotecas_compra_vivienda: { base: 'hipotecas_compra_vivienda', formula: 'directo', cortes: [1000], nivel_minimo: 'provincia' },
  },
};
const capaPortales = { capa: 'portales', activa: false };

test('la web pide el manifiesto del Notariado como capa, junto al de los portales', () => {
  assert.ok(datos.CAPAS.includes('datos/notariado/manifiesto.json'));
  assert.ok(datos.CAPAS.includes('datos/portales/manifiesto.json'));
});

test('unirCapas suma las series y los mapas del Notariado, con su licencia y la fecha de la foto', () => {
  const m = datos.unirCapas(general, [capaPortales, capaNotariado]);
  assert.deepEqual(Object.keys(m.indicadores), ['renta_persona', 'precio_escriturado_m2', 'hipotecas_compra_vivienda']);
  assert.deepEqual(Object.keys(m.mapas), ['renta_persona', 'precio_escriturado_m2', 'hipotecas_compra_vivienda']);
  assert.deepEqual(m.capas, { notariado: { version: '2026-11-19', generado: '2026-11-19', licencia: LICENCIA, foto: '2026-10-21' } });
  // Apagada (NOTARIADO=FALSE, o una referencia anterior a la capa): el manifiesto general, tal cual
  assert.equal(datos.unirCapas(general, [capaPortales, { capa: 'notariado', activa: false }]), general);
});

test('cada serie lleva la etiqueta de su fuente y no se descarga en CSV, con su aviso', () => {
  for (const idioma of ['es', 'en']) {
    for (const fuente of notariado.FUENTES_NOTARIADO) {
      assert.ok(t[idioma].existe(`vocabulario.etiqueta.${fuente}`), `${idioma}: falta la etiqueta de ${fuente}`);
      assert.match(t[idioma](`vocabulario.etiqueta.${fuente}`), /© Consejo General del Notariado/);
    }
    assert.ok(t[idioma].existe('interfaz.exportar.notariado'));
    assert.ok(t[idioma].existe('interfaz.ficha.foto_notariado'));
  }
  const etiqueta = t.es('vocabulario.etiqueta.notariado');
  assert.equal(etiqueta, LICENCIA);
  assert.equal(exportar.descargaPermitida('csv', etiqueta), false);
  assert.equal(exportar.descargaPermitida('png', etiqueta), true);
  const def = capaNotariado.indicadores.hipotecas_compra_vivienda;
  assert.equal(notariado.avisoSinDescarga(t.es, def), t.es('interfaz.exportar.notariado'));
  assert.equal(notariado.avisoSinDescarga(t.es, { fuente: 'portales' }), t.es('interfaz.exportar.privado'));
  assert.match(notariado.avisoSinDescarga(t.en, def), /non-commercial/);
});

test('la ficha cita la fecha de la foto y el umbral; las series del CIEN, no', () => {
  assert.equal(notariado.fechaLarga('2026-10-21', 'es'), '21 de octubre de 2026');
  assert.equal(notariado.fechaLarga('2026-10-21', 'en'), '21 October 2026');
  assert.equal(notariado.fechaLarga('octubre'), null);
  const nota = notariado.notaFoto(t.es, capaNotariado.indicadores.precio_escriturado_m2);
  assert.match(nota, /21 de octubre de 2026/);
  assert.match(nota, /20 compraventas/);
  assert.doesNotMatch(nota, /\{/);
  assert.match(notariado.notaFoto(t.en, capaNotariado.indicadores.precio_escriturado_m2), /21 October 2026/);
  assert.equal(notariado.notaFoto(t.es, capaNotariado.indicadores.hipotecas_compra_vivienda), null);
  assert.equal(notariado.notaFoto(t.es, undefined), null);
});

test('los nombres, unidades y lecturas de los indicadores 25 a 29 están en los dos idiomas y dicen la licencia', () => {
  const codigos = ['precio_escriturado_m2', 'precio_escriturado_vivienda', 'compraventas_notariado', 'hipotecas_compra_vivienda',
    'cuantia_hipoteca_vivienda'];
  for (const idioma of ['es', 'en']) {
    for (const c of codigos) {
      for (const campo of ['nombre', 'unidad', 'definicion', 'calculo', 'lectura']) {
        assert.ok(t[idioma].existe(`indicadores.${c}.${campo}`), `${idioma}: falta indicadores.${c}.${campo}`);
      }
      assert.match(t[idioma](`indicadores.${c}.lectura`), /© Consejo General del Notariado/);
    }
  }
});

// Con la exportación del pipeline (va en git: web/datos/notariado/)
const rutaCapa = join(raiz, 'web', 'datos', 'notariado', 'manifiesto.json');
test('exportación del pipeline: manifiesto con licencia, series del Notariado y nada en el manifiesto general', { skip: !existsSync(rutaCapa) && 'sin web/datos/notariado/' }, () => {
  const capa = leerJson('web', 'datos', 'notariado', 'manifiesto.json');
  assert.equal(capa.capa, 'notariado');
  if (!capa.activa) {
    assert.deepEqual(capa, { capa: 'notariado', activa: false });
    return;
  }
  assert.equal(capa.licencia, LICENCIA);
  assert.match(capa.foto, /^\d{4}-\d{2}-\d{2}$/);
  for (const [clave, def] of Object.entries(capa.indicadores)) {
    assert.ok(notariado.esNotariado(def), `${clave}: fuente ${def.fuente}`);
    assert.ok(def.ruta.startsWith('datos/notariado/'), clave);
    for (const nivel of def.niveles) {
      for (const anio of def.anios) {
        const ruta = join(raiz, 'web', def.ruta.replace('{nivel}', nivel).replace('{anio}', anio));
        assert.ok(existsSync(ruta), `falta ${ruta}`);
      }
    }
  }
  for (const def of Object.values(capa.mapas)) assert.ok(def.nivel_minimo === 'municipio' || def.nivel_minimo === 'provincia');
  const rutaGeneral = join(raiz, 'web', 'datos', 'manifiesto.json');
  if (existsSync(rutaGeneral)) {
    const m = leerJson('web', 'datos', 'manifiesto.json');
    assert.equal(Object.values(m.indicadores).filter((d) => notariado.esNotariado(d)).length, 0);
  }
});
