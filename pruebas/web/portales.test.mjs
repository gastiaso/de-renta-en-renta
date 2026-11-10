// Pruebas sin navegador de la capa de portales (indicador 13, tarea 35): solo web y aparte de la
// exportación general (R/web_portales.R).
//   - unirCapas() suma las series y los mapas de una capa encendida al manifiesto general, sin pisar
//     nada, y no cambia nada con la capa apagada o sin ella;
//   - el CSV no se ofrece para los datos privados de oferta (decisión 3); la imagen, sí;
//   - con la exportación del pipeline: datos/portales/manifiesto.json existe siempre; apagada, no dice
//     nada más; encendida, sus series van en datos/portales/, con los niveles de España a municipio,
//     enlace al informe de cada cifra y zonas por municipio, y ninguna está en el manifiesto general.
// Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/portales.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const modulo = (ruta) => import(pathToFileURL(join(raiz, ruta)).href);
const leerJson = (...ruta) => JSON.parse(readFileSync(join(raiz, ...ruta), 'utf8'));
const datos = await modulo('web/js/datos.js');
const exportar = await modulo('web/js/exportar.js');
const i18n = { es: leerJson('web', 'i18n', 'es.json'), en: leerJson('web', 'i18n', 'en.json') };
const en = (dic, clave) => clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);

const general = {
  version: '2026-11-10', ejemplo: false, codificacion: { escala: 10, estados: ['dato', 'estimado', 'secreto', 'ausente'] },
  indicadores: { renta_persona: { niveles: ['sc', 'municipio'], anios: [2024], ruta: 'datos/{nivel}/renta_persona/{anio}.json' } },
  mapas: { renta_persona: { base: 'renta_persona', formula: 'directo', cortes: [10, 20] } },
};
const capa = {
  capa: 'portales', activa: true, version: '2026-11-10', generado: '2026-11-10',
  indicadores: {
    precio_oferta_alquiler_idealista: {
      id: 13, indicador: 'precio_oferta', corte: 'oferta_privada', grupo: 'alquiler_idealista',
      niveles: ['municipio', 'provincia', 'ccaa', 'nacional'], anios: [2015, 2016], escala: 100, decimales: 2,
      ruta: 'datos/portales/{nivel}/precio_oferta_alquiler_idealista/{anio}.json', fuente: 'portales',
    },
    renta_persona: { niveles: ['sc'], ruta: 'otra' },   // una clave que ya está: no se pisa
  },
  mapas: { precio_oferta_alquiler_idealista: { base: 'precio_oferta_alquiler_idealista', nivel_minimo: 'municipio' } },
};

test('unirCapas: una capa encendida suma sus series y mapas detrás, sin pisar los generales', () => {
  const m = datos.unirCapas(general, [capa]);
  assert.deepEqual(Object.keys(m.indicadores), ['renta_persona', 'precio_oferta_alquiler_idealista']);
  assert.deepEqual(Object.keys(m.mapas), ['renta_persona', 'precio_oferta_alquiler_idealista']);
  assert.equal(m.indicadores.renta_persona.ruta, 'datos/{nivel}/renta_persona/{anio}.json');
  assert.deepEqual(m.capas, { portales: { version: '2026-11-10', generado: '2026-11-10' } });
  assert.equal(datos.codificacionDe(m, 'precio_oferta_alquiler_idealista').escala, 100);
  assert.equal(datos.rutaValores(m.indicadores.precio_oferta_alquiler_idealista, 'municipio', 2016),
    'datos/portales/municipio/precio_oferta_alquiler_idealista/2016.json');
  assert.equal(general.capas, undefined, 'el manifiesto general no cambia');
});

test('unirCapas: apagada, ilegible o sin capas, el manifiesto tal cual', () => {
  assert.equal(datos.unirCapas(general, [{ capa: 'portales', activa: false }]), general);
  assert.equal(datos.unirCapas(general, [null]), general);
  assert.equal(datos.unirCapas(general, []), general);
});

test('decisión 3: los datos privados de oferta no se descargan en CSV; la imagen, sí', () => {
  assert.equal(exportar.descargaPermitida('csv', 'Dato privado de oferta'), false);
  assert.equal(exportar.descargaPermitida('png', 'Dato privado de oferta'), true);
  assert.equal(exportar.descargaPermitida('csv', null), true);
  for (const idioma of ['es', 'en']) {
    assert.equal(typeof en(i18n[idioma], 'interfaz.exportar.privado'), 'string', idioma);
  }
});

const manifiesto = join(raiz, 'web', 'datos', 'manifiesto.json');
const manifiestoCapa = join(raiz, 'web', 'datos', 'portales', 'manifiesto.json');
test('exportación del pipeline: la capa de portales, aparte y completa', { skip: !existsSync(manifiesto) && 'sin la exportación de la web' }, () => {
  assert.ok(existsSync(manifiestoCapa), 'datos/portales/manifiesto.json existe siempre (apagada, activa = false)');
  const c = leerJson('web', 'datos', 'portales', 'manifiesto.json');
  assert.equal(c.capa, 'portales');
  if (!c.activa) {
    assert.deepEqual(Object.keys(c).sort(), ['activa', 'capa']);
    return;
  }
  const m = leerJson('web', 'datos', 'manifiesto.json');
  const series = Object.entries(c.indicadores);
  assert.ok(series.length > 0);
  for (const [clave, def] of series) {
    assert.ok(!(clave in m.indicadores), `${clave}: fuera del manifiesto general`);
    assert.equal(def.fuente, 'portales');
    assert.equal(def.corte, 'oferta_privada');
    assert.ok(def.ruta.startsWith('datos/portales/'), def.ruta);
    for (const nivel of ['nacional', 'ccaa', 'provincia', 'municipio']) assert.ok(def.niveles.includes(nivel), `${clave}: ${nivel}`);
    assert.ok(!def.niveles.includes('sc'));
    assert.equal(def.anios[0], 2015);
    assert.match(def.ultimo_mes, /^\d{4}-\d{2}$/);
    // Un fichero de valores por nivel y año, con la longitud del índice general del nivel
    for (const nivel of def.niveles) {
      const indice = leerJson('web', ...m.indices[nivel].split('/'));
      for (const anio of def.anios) {
        const x = leerJson('web', ...datos.rutaValores(def, nivel, anio).split('/'));
        assert.equal(x.v.length, indice.length, `${clave} ${nivel} ${anio}`);
        assert.equal(x.e.length, indice.length);
      }
    }
    // El enlace al informe de cada cifra
    const enlaces = leerJson('web', ...def.enlaces.split('/'));
    assert.match(enlaces.nacional['00'], /^https:\/\//);
    // Zonas: por municipio, una serie con los años de la capa
    const zonas = leerJson('web', ...def.zonas.split('/'));
    assert.deepEqual(zonas.anios, def.anios);
    const municipios = Object.keys(zonas.municipios);
    assert.ok(municipios.length > 0 && municipios.every((cod) => /^\d{5}$/.test(cod)));
    for (const z of Object.values(zonas.municipios).flat()) {
      assert.ok(['zona', 'localidad'].includes(z.tipo));
      assert.equal(z.v.length, def.anios.length);
      assert.equal(z.e.length, def.anios.length);
      assert.match(z.url, /^https:\/\//);
    }
    assert.ok(c.mapas[clave], `${clave}: con su mapa`);
    assert.equal(c.mapas[clave].nivel_minimo, 'municipio');
  }
  // Sumada al general, la web la pinta con la etiqueta de su fuente
  const unido = datos.unirCapas(m, [c]);
  for (const [clave] of series) assert.equal(unido.indicadores[clave].fuente, 'portales');
  assert.equal(typeof en(i18n.es, 'vocabulario.etiqueta.portales'), 'string');
});
