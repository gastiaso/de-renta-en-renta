// Mapa de secciones con MapLibre.
//
// El mapa base viene del manifiesto (`mapa_base`) y puede ser de dos tipos con las mismas capas
// y propiedades, para que el resto del código no cambie al pasar de uno a otro:
//   - pmtiles: un fichero con las capas comunidades, provincias, municipios y secciones
//     (teselas vectoriales; el del seccionado de 2021 lo genera el pipeline);
//   - geojson: un fichero por capa (la muestra de web/datos/ejemplo/).
// Sin teselas de terceros: el fondo es el color del mar y la tierra sale de las propias capas.
//
// Los valores no van en las teselas: se cargan aparte (binarios por indicador y año) y se
// guardan como estado de cada sección (feature-state `b`, el valor base). El color se calcula
// con una expresión de estilo, así que cambiar de umbral o de superficie no descarga nada.

import * as maplibregl from 'maplibre-gl';
import { formulaDe } from './formulas.js';

const css = (nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
const absoluta = (ruta) => new URL(ruta, document.baseURI).href;
let pmtilesRegistrado = false;

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

// Crea el mapa y resuelve, cuando ha cargado, con las funciones para pintarlo y manejarlo.
export function crearMapa({ contenedor, manifiesto, vista, t, alSeleccionar, alMover }) {
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
  const objetivo = (codigo) =>
    base.tipo === 'pmtiles' ? { source: 'mapa-base', sourceLayer: 'secciones', id: codigo } : { source: 'capa-secciones', id: codigo };

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
        promoteId: Object.fromEntries(Object.entries(capas).map(([capa, def]) => [capa, def.id])),
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
    mapa.addLayer({ id: 'secciones-relleno', type: 'fill', ...fuente('secciones'), paint: { 'fill-color': css('--color-fuera') } });
    mapa.addLayer({
      id: 'secciones-secreto', type: 'fill', ...fuente('secciones'),
      filter: ['in', ['get', idSeccion], ['literal', []]],
      paint: { 'fill-pattern': 'trama-secreto' },
    });
    // Contorno de todas las secciones: los tramos 1 y 2 de la rampa no llegan a 3:1 sobre la crema.
    mapa.addLayer({
      id: 'secciones-contorno', type: 'line', ...fuente('secciones'),
      paint: { 'line-color': tinta, 'line-opacity': 0.6, 'line-width': ['interpolate', ['linear'], ['zoom'], 8, 0.1, 12, 0.4, 16, 1] },
    });
    for (const [capa, ancho] of [['municipios', 1], ['provincias', 1.5], ['comunidades', 2]]) {
      if (capas[capa]) mapa.addLayer({ id: `${capa}-borde`, type: 'line', ...fuente(capa), paint: { 'line-color': tinta, 'line-width': ancho } });
    }
    const resalte = (id, estado, ancho) =>
      mapa.addLayer({
        id, type: 'line', ...fuente('secciones'),
        paint: { 'line-color': tinta, 'line-width': ancho, 'line-opacity': ['case', ['boolean', ['feature-state', estado], false], 1, 0] },
      });
    resalte('secciones-encima', 'encima', 2);
    resalte('secciones-seleccion', 'sel', 4);
  }

  // Color por tramos: valor base del estado de la sección → fórmula del mapa → rampa de cinco pasos.
  function expresionColor(mapaDef, supuestos) {
    const valor = formulaDe(mapaDef).expresion(['to-number', ['feature-state', 'b']], supuestos);
    const pasos = ['step', valor, css('--rampa-1')];
    mapaDef.cortes.forEach((corte, i) => pasos.push(corte, css(`--rampa-${i + 2}`)));
    return ['case', ['==', ['feature-state', 'b'], null], css('--color-fuera'), pasos];
  }

  let seleccionada = null;
  let encima = null;
  const marcar = (codigo, estado) => codigo && mapa.setFeatureState(objetivo(codigo), estado);

  function seleccionar(codigo) {
    marcar(seleccionada, { sel: false });
    seleccionada = codigo ?? null;
    marcar(seleccionada, { sel: true });
  }

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
      if (!codigo) return;
      seleccionar(codigo);
      alSeleccionar(codigo);
    });
    mapa.on('moveend', () => alMover(mapa));
  }

  const api = {
    mapa,
    seleccionar,
    // Guarda el valor base y el estado de cada sección y recalcula el color.
    pintar({ secciones, datos, mapaDef, supuestos }) {
      for (let i = 0; i < secciones.length; i++) {
        mapa.setFeatureState(objetivo(secciones[i]), { b: datos.valores[i], e: datos.estados[i] });
      }
      const secretos = secciones.filter((_, i) => datos.estados[i] === 2);
      mapa.setFilter('secciones-secreto', ['in', ['get', idSeccion], ['literal', secretos]]);
      mapa.setPaintProperty('secciones-relleno', 'fill-color', expresionColor(mapaDef, supuestos));
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
