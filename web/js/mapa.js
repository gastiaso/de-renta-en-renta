// Mapa de secciones con MapLibre.
//
// El mapa base viene del manifiesto (`mapa_base`) y puede ser de dos tipos con las mismas capas
// y propiedades, para que el resto del código no cambie al pasar de uno a otro:
//   - pmtiles: un fichero con las capas comunidades, provincias, municipios y secciones
//     (teselas vectoriales; el del seccionado de 2021 lo genera el pipeline);
//   - geojson: un fichero por capa (la muestra de web/datos/ejemplo/).
// Sin teselas de terceros: el fondo es el color del mar y la tierra sale de las propias capas.
//
// Los valores no van en las teselas: se cargan aparte (un JSON por serie y año) y se guardan
// como estado de cada sección (feature-state, una clave por serie). El color sale de una
// expresión de estilo (sueldo.js), así que cambiar de sueldo, ficha, umbral o superficie no
// descarga nada.
//
// Capa opcional sin_seccion: el suelo que el seccionado no cubre (terrenos comunales que no son
// de ningún municipio). Sin código ni valores: se pinta con el color de «sin dato», en todos los
// zooms, y al pulsarla avisa con sus atributos (km2 y provincias, códigos separados por espacios).

import * as maplibregl from 'maplibre-gl';
import { paletaDe, paletaContorno, rampaDeCss } from './colores.js';
import { atributosSinSeccion, elegirSinSeccion } from './datos.js';

const css = (nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
const absoluta = (ruta) => new URL(ruta, document.baseURI).href;
let pmtilesRegistrado = false;

// Colores del mapa, de tokens.css: la rampa entera (seis pasos) para los tramos del mapa y tres
// pasos repartidos para «¿te llega?» (de claro a oscuro: se distinguen también sin color).
export function coloresMapa() {
  return paletaDe(rampaDeCss(), css('--color-fuera'));
}

// Colores del contorno de cada tramo: tinta sobre los tramos claros (los dos primeros no llegan
// a 3:1 sobre la crema) y placa sobre los oscuros, donde la tinta no se ve (colores.js).
export function coloresContorno() {
  return paletaContorno(coloresMapa(), css('--color-tinta'), css('--color-placa'));
}

// Trama del secreto estadístico (como la clase .secreto de tokens.css).
function trama(color) {
  const lado = 8;
  const lienzo = document.createElement('canvas');
  lienzo.width = lienzo.height = lado;
  const ctx = lienzo.getContext('2d');
  ctx.strokeStyle = color;
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  for (const d of [-lado, 0, lado]) {
    ctx.moveTo(d, lado);
    ctx.lineTo(d + lado, 0);
  }
  ctx.stroke();
  return ctx.getImageData(0, 0, lado, lado);
}

// Caja [oeste, sur, este, norte] de una lista de geometrías GeoJSON.
function cajaDe(geometrias) {
  const caja = [Infinity, Infinity, -Infinity, -Infinity];
  const recorrer = (c) => {
    if (typeof c[0] === 'number') {
      caja[0] = Math.min(caja[0], c[0]); caja[1] = Math.min(caja[1], c[1]);
      caja[2] = Math.max(caja[2], c[0]); caja[3] = Math.max(caja[3], c[1]);
    } else c.forEach(recorrer);
  };
  geometrias.forEach((g) => recorrer(g.coordinates));
  return Number.isFinite(caja[0]) ? caja : null;
}

// Crea el mapa y resuelve, cuando ha cargado, con las funciones para pintarlo y manejarlo.
export function crearMapa({ contenedor, manifiesto, vista, t, alPulsar, alPulsarSinSeccion, alMover }) {
  const base = manifiesto.mapa_base;
  const capas = base.capas;
  if (!capas?.secciones) throw new Error('El mapa base no tiene capa de secciones');
  const idSeccion = capas.secciones.id;

  const opciones = {
    container: contenedor,
    style: { version: 8, sources: {}, layers: [{ id: 'mar', type: 'background', paint: { 'background-color': css('--color-mar') } }] },
    attributionControl: false,
    dragRotate: false,
    pitchWithRotate: false,
    maxPitch: 0,
    locale: {
      'NavigationControl.ZoomIn': t('interfaz.mapa.acercar'),
      'NavigationControl.ZoomOut': t('interfaz.mapa.alejar'),
    },
  };
  if (vista) Object.assign(opciones, vista);
  else Object.assign(opciones, { bounds: manifiesto.vista_inicial.limites, fitBoundsOptions: { padding: 24 } });

  const mapa = new maplibregl.Map(opciones);
  mapa.touchZoomRotate.disableRotation();
  mapa.keyboard.disableRotation();
  mapa.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
  mapa.addControl(new maplibregl.ScaleControl({ unit: 'metric' }), 'bottom-right');
  mapa.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');

  // Fuente de cada capa, en la forma que piden addLayer (`source-layer`) y setFeatureState (`sourceLayer`).
  const fuente = (capa) => (base.tipo === 'pmtiles' ? { source: 'mapa-base', 'source-layer': capa } : { source: `capa-${capa}` });
  const objetivoEn = (capa, codigo) =>
    base.tipo === 'pmtiles' ? { source: 'mapa-base', sourceLayer: capa, id: codigo } : { source: `capa-${capa}`, id: codigo };
  const objetivo = (codigo) => objetivoEn('secciones', codigo);

  // Capas que se colorean con valores, con su nivel y el zoom hasta el que se ven (las secciones
  // del PMTiles empiezan en el zoom 7; por debajo, municipios y, más abajo, provincias, con las
  // cifras publicadas en su nivel).
  const RELLENOS = [
    { capa: 'provincias', nivel: 'provincia', hasta: 5 },
    { capa: 'municipios', nivel: 'municipio', hasta: 7 },
    { capa: 'secciones', nivel: 'sc', hasta: 24 },
  ].filter((r) => capas[r.capa]);

  function anadirFuentes() {
    if (base.tipo === 'pmtiles') {
      if (!globalThis.pmtiles) throw new Error('Falta vendor/pmtiles/pmtiles.js');
      if (!pmtilesRegistrado) {
        maplibregl.addProtocol('pmtiles', new globalThis.pmtiles.Protocol().tile);
        pmtilesRegistrado = true;
      }
      mapa.addSource('mapa-base', {
        type: 'vector',
        url: `pmtiles://${absoluta(base.url)}`,
        promoteId: Object.fromEntries(Object.entries(capas).filter(([, def]) => def.id).map(([capa, def]) => [capa, def.id])),
        attribution: base.atribucion,
      });
    } else if (base.tipo === 'geojson') {
      for (const [capa, def] of Object.entries(capas)) {
        mapa.addSource(`capa-${capa}`, { type: 'geojson', data: absoluta(def.url), promoteId: def.id, attribution: base.atribucion });
      }
    } else {
      throw new Error(`Tipo de mapa base desconocido: ${base.tipo}`);
    }
  }

  function anadirCapas() {
    const tinta = css('--color-tinta');
    const tierra = capas.comunidades ? 'comunidades' : capas.provincias ? 'provincias' : null;
    if (tierra) mapa.addLayer({ id: 'tierra', type: 'fill', ...fuente(tierra), paint: { 'fill-color': css('--color-placa') } });
    for (const { capa, hasta } of RELLENOS.filter((r) => r.capa !== 'secciones')) {
      mapa.addLayer({ id: `${capa}-relleno`, type: 'fill', ...fuente(capa), maxzoom: hasta, paint: { 'fill-color': css('--color-placa') } });
    }
    // El suelo sin sección, encima de la tierra y de las provincias (que pueden incluirlo) y debajo de
    // las secciones, que mandan en sus bordes.
    if (capas.sin_seccion) {
      mapa.addLayer({ id: 'sin-seccion-relleno', type: 'fill', ...fuente('sin_seccion'), paint: { 'fill-color': css('--color-fuera') } });
    }
    mapa.addLayer({ id: 'secciones-relleno', type: 'fill', ...fuente('secciones'), paint: { 'fill-color': css('--color-fuera') } });
    mapa.addLayer({
      id: 'secciones-secreto', type: 'fill', ...fuente('secciones'),
      filter: ['in', ['get', idSeccion], ['literal', []]],
      paint: { 'fill-pattern': 'trama-secreto' },
    });
    // Contorno de todas las secciones: los tramos claros de la rampa no llegan a 3:1 sobre la crema.
    mapa.addLayer({
      id: 'secciones-contorno', type: 'line', ...fuente('secciones'),
      paint: { 'line-color': tinta, 'line-opacity': 0.6, 'line-width': ['interpolate', ['linear'], ['zoom'], 8, 0.1, 12, 0.4, 16, 1] },
    });
    for (const [capa, ancho] of [['municipios', 1], ['provincias', 1.5], ['comunidades', 2]]) {
      if (capas[capa]) mapa.addLayer({ id: `${capa}-borde`, type: 'line', ...fuente(capa), paint: { 'line-color': tinta, 'line-width': ancho } });
    }
    // Resaltes: un halo de placa debajo de la línea de tinta, para que se vean sobre cualquier tramo.
    const resalte = (id, estado, ancho, discontinua) => {
      const visible = ['case', ['boolean', ['feature-state', estado], false], 1, 0];
      mapa.addLayer({
        id: `${id}-halo`, type: 'line', ...fuente('secciones'),
        paint: { 'line-color': css('--color-placa'), 'line-width': ancho + 3, 'line-opacity': visible },
      });
      mapa.addLayer({
        id, type: 'line', ...fuente('secciones'),
        paint: {
          'line-color': tinta, 'line-width': ancho, 'line-opacity': visible,
          ...(discontinua ? { 'line-dasharray': [1.5, 1] } : {}),
        },
      });
    };
    resalte('secciones-encima', 'encima', 1.5);
    resalte('secciones-comparada', 'cmp', 3, true);
    resalte('secciones-seleccion', 'sel', 3.5);
  }

  let seleccionada = null;
  let comparada = null;
  let encima = null;
  const marcar = (codigo, estado) => codigo && mapa.setFeatureState(objetivo(codigo), estado);

  function interaccion() {
    const codigoDe = (e) => e.features?.[0]?.properties?.[idSeccion] ?? null;
    mapa.on('mousemove', 'secciones-relleno', (e) => {
      const codigo = codigoDe(e);
      if (codigo !== encima) {
        marcar(encima, { encima: false });
        encima = codigo;
        marcar(encima, { encima: true });
      }
      mapa.getCanvas().style.cursor = 'pointer';
    });
    mapa.on('mouseleave', 'secciones-relleno', () => {
      marcar(encima, { encima: false });
      encima = null;
      mapa.getCanvas().style.cursor = '';
    });
    mapa.on('click', 'secciones-relleno', (e) => {
      const codigo = codigoDe(e);
      if (codigo) alPulsar(codigo);
    });
    if (capas.sin_seccion && alPulsarSinSeccion) {
      mapa.on('mousemove', 'sin-seccion-relleno', () => { mapa.getCanvas().style.cursor = 'pointer'; });
      mapa.on('mouseleave', 'sin-seccion-relleno', () => { mapa.getCanvas().style.cursor = ''; });
      mapa.on('click', 'sin-seccion-relleno', (e) => {
        if (mapa.queryRenderedFeatures(e.point, { layers: ['secciones-relleno'] }).length) return;   // la sección manda
        const p = elegirSinSeccion((e.features ?? []).map((f) => f.properties));   // el trozo con nombre, si lo hay
        if (p) alPulsarSinSeccion(atributosSinSeccion(p));
      });
    }
    mapa.on('moveend', () => alMover(mapa));
  }

  // Geometrías de una sección ya cargadas en el mapa (en PMTiles, solo las de las teselas vistas).
  const geometriasDe = (codigo) =>
    mapa.querySourceFeatures(fuente('secciones').source, {
      sourceLayer: base.tipo === 'pmtiles' ? 'secciones' : undefined,
      filter: ['==', ['get', idSeccion], codigo],
    }).map((f) => f.geometry);

  const api = {
    mapa,
    seleccionar(codigo) {
      marcar(seleccionada, { sel: false });
      seleccionada = codigo ?? null;
      marcar(seleccionada, { sel: true });
    },
    comparar(codigo) {
      marcar(comparada, { cmp: false });
      comparada = codigo ?? null;
      marcar(comparada, { cmp: true });
    },
    // Capas coloreadas por valores: [{ capa, nivel, id }].
    rellenos: RELLENOS.map((r) => ({ ...r, id: capas[r.capa].id })),
    // Nivel que se ve a la escala actual (provincia, municipio o sección).
    nivelVisible() {
      const zoom = mapa.getZoom();
      return (RELLENOS.find((r) => zoom < r.hasta) ?? RELLENOS.at(-1)).nivel;
    },
    // Guarda en cada elemento de una capa los valores de varias series a la vez: { serie: [valor | null] },
    // en el orden de `codigos`.
    ponerSeries(capa, codigos, columnas) {
      const series = Object.entries(columnas);
      if (!series.length) return;
      for (let i = 0; i < codigos.length; i++) {
        const estado = {};
        for (const [serie, valores] of series) estado[serie] = valores[i];
        mapa.setFeatureState(objetivoEn(capa, codigos[i]), estado);
      }
    },
    // Color de una capa (expresión de sueldo.js); en las secciones, también el del contorno y la
    // trama del secreto; en los municipios, su borde mientras no se ven las secciones.
    colorear(capa, relleno, contorno, secretos) {
      mapa.setPaintProperty(`${capa}-relleno`, 'fill-color', relleno);
      if (capa === 'secciones') {
        mapa.setPaintProperty('secciones-contorno', 'line-color', contorno);
        mapa.setFilter('secciones-secreto', ['in', ['get', idSeccion], ['literal', secretos ?? []]]);
      } else if (capa === 'municipios' && mapa.getLayer('municipios-borde')) {
        mapa.setPaintProperty('municipios-borde', 'line-color', ['step', ['zoom'], contorno, 7, css('--color-tinta')]);
      }
    },
    irA(caja) {
      if (caja) mapa.fitBounds(caja, { padding: 24, maxZoom: 15 });
    },
    // Encuadra una sección; si aún no está cargada, lo intenta otra vez cuando el mapa se quede quieto.
    encuadrarSeccion(codigo, reintento = true) {
      const caja = cajaDe(geometriasDe(codigo));
      if (caja) mapa.fitBounds(caja, { padding: 48, maxZoom: 16 });
      else if (reintento) mapa.once('idle', () => api.encuadrarSeccion(codigo, false));
    },
    // Textos de los controles al cambiar de idioma.
    traducir(t) {
      const poner = (selector, texto) => {
        const boton = contenedor.querySelector(selector);
        if (boton) { boton.title = texto; boton.setAttribute('aria-label', texto); }
      };
      poner('.maplibregl-ctrl-zoom-in', t('interfaz.mapa.acercar'));
      poner('.maplibregl-ctrl-zoom-out', t('interfaz.mapa.alejar'));
    },
  };

  return new Promise((resolver, rechazar) => {
    // Antes de cargar, un error impide abrir el mapa; después (una tesela, una capa), se anota.
    mapa.on('error', (e) => {
      console.error(e.error ?? e);
      if (!mapa.loaded()) rechazar(e.error ?? e);
    });
    mapa.on('load', () => {
      try {
        mapa.addImage('trama-secreto', trama(css('--color-tenue')), { pixelRatio: 1 });
        anadirFuentes();
        anadirCapas();
        interaccion();
        resolver(api);
      } catch (error) {
        rechazar(error);
      }
    });
  });
}
