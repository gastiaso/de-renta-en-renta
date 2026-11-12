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
//
// Cada escala pinta un nivel con sus cifras publicadas (RELLENOS): comunidades, provincias,
// municipios y secciones. Pulsar uno abre su ficha (alPulsar con las secciones; alPulsarTerritorio
// con los demás: tarea 26). Con ratón, una etiqueta dice el nombre del territorio bajo el cursor
// (etiquetaDe, del módulo principal: lo mismo que la ficha; tarea 25).

import * as maplibregl from 'maplibre-gl';
import { paletaDe, paletaContorno, rampaDeCss } from './colores.js';
import { atributosSinSeccion, elegirSinSeccion } from './datos.js';
import { esPantallaEstrecha } from './movil.js';

// Gestos cooperativos en pantallas estrechas (decisión del autor, 12-nov-2026; web/LEEME.md): por
// debajo de ANCHO_MOVIL (js/movil.js), un dedo desplaza la página y el mapa se mueve con dos, con
// el aviso de MapLibre en el idioma de la página. En escritorio no cambia nada. Para quitarlo, false.
export const GESTOS_COOPERATIVOS_MOVIL = true;

// Opciones de MapLibre de los gestos cooperativos: vacías en escritorio (o con la constante en false).
export function opcionesGestos(t, estrecha = esPantallaEstrecha()) {
  if (!GESTOS_COOPERATIVOS_MOVIL || !estrecha) return { opciones: {}, textos: {} };
  return {
    opciones: { cooperativeGestures: true },
    textos: {
      'CooperativeGesturesHandler.WindowsHelpText': t('interfaz.mapa.gesto_windows'),
      'CooperativeGesturesHandler.MacHelpText': t('interfaz.mapa.gesto_mac'),
      'CooperativeGesturesHandler.MobileHelpText': t('interfaz.mapa.gesto_movil'),
    },
  };
}

const css =(nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
const absoluta = (ruta) => new URL(ruta, document.baseURI).href;
let pmtilesRegistrado = false;

// Colores del mapa, de tokens.css: la rampa entera (siete pasos) para los tramos del mapa y tres
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
export function crearMapa({ contenedor, manifiesto, vista, t, alPulsar, alPulsarSinSeccion, alPulsarTerritorio, alMover, etiqueta = null, etiquetaDe = null }) {
  const base = manifiesto.mapa_base;
  const capas = base.capas;
  if (!capas?.secciones) throw new Error('El mapa base no tiene capa de secciones');
  const idSeccion = capas.secciones.id;

  const gestos = opcionesGestos(t);
  const opciones = {
    container: contenedor,
    style: { version: 8, sources: {}, layers: [{ id: 'mar', type: 'background', paint: { 'background-color': css('--color-mar') } }] },
    attributionControl: false,
    dragRotate: false,
    pitchWithRotate: false,
    maxPitch: 0,
    ...gestos.opciones,
    locale: {
      'NavigationControl.ZoomIn': t('interfaz.mapa.acercar'),
      'NavigationControl.ZoomOut': t('interfaz.mapa.alejar'),
      ...gestos.textos,
    },
  };
  if (vista) Object.assign(opciones, vista);
  else Object.assign(opciones, { bounds: manifiesto.vista_inicial.limites, fitBoundsOptions: { padding: 24 } });

  const mapa = new maplibregl.Map(opciones);
  mapa.touchZoomRotate.disableRotation();
  mapa.keyboard.disableRotation();
  mapa.getCanvas().setAttribute('aria-label', t('interfaz.mapa.lienzo'));
  mapa.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
  mapa.addControl(new maplibregl.ScaleControl({ unit: 'metric' }), 'bottom-right');
  mapa.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');

  // Fuente de cada capa, en la forma que piden addLayer (`source-layer`) y setFeatureState (`sourceLayer`).
  const fuente = (capa) => (base.tipo === 'pmtiles' ? { source: 'mapa-base', 'source-layer': capa } : { source: `capa-${capa}` });
  const objetivoEn = (capa, codigo) =>
    base.tipo === 'pmtiles' ? { source: 'mapa-base', sourceLayer: capa, id: codigo } : { source: `capa-${capa}`, id: codigo };
  const objetivo = (codigo) => objetivoEn('secciones', codigo);

  // Capas que se colorean con valores, con su nivel y el zoom hasta el que se ven, cada una desde
  // donde acaba la anterior: las secciones del PMTiles empiezan en el zoom 7; por debajo, los
  // municipios (5–7: la vista de toda España en una pantalla de escritorio), las provincias (4–5)
  // y, alejando más, las comunidades (menos de 4; en el móvil, toda España), con las cifras
  // publicadas en su nivel (tarea 26; franjas «por revisar»: también cabía un selector de nivel).
  const RELLENOS = [
    { capa: 'comunidades', nivel: 'ccaa', hasta: 4 },
    { capa: 'provincias', nivel: 'provincia', hasta: 5 },
    { capa: 'municipios', nivel: 'municipio', hasta: 7 },
    { capa: 'secciones', nivel: 'sc', hasta: 24 },
  ].filter((r) => capas[r.capa]?.id)
    .map((r, i, lista) => ({ ...r, desde: i ? lista[i - 1].hasta : 0, franja: r.hasta }));   // franja: el «hasta» propio (F5)

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
    // Cada nivel solo en su franja de zoom, para que no se tapen entre sí ni respondan dos al clic
    for (const { capa, desde, hasta } of RELLENOS.filter((r) => r.capa !== 'secciones')) {
      mapa.addLayer({ id: `${capa}-relleno`, type: 'fill', ...fuente(capa), minzoom: desde, maxzoom: hasta, paint: { 'fill-color': css('--color-placa') } });
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
    // Tarea 51: sin contorno por debajo del zoom 9 (con secciones de pocos píxeles, la línea tapa el
    // color y siete tramos dejan de distinguirse), y aparece poco a poco hasta el 11.
    mapa.addLayer({
      id: 'secciones-contorno', type: 'line', ...fuente('secciones'),
      paint: {
        'line-color': tinta,
        'line-opacity': ['interpolate', ['linear'], ['zoom'], 9, 0, 11, 0.6],
        'line-width': ['interpolate', ['linear'], ['zoom'], 9, 0.1, 12, 0.4, 16, 1],
      },
    });
    for (const [capa, ancho] of [['municipios', 1], ['provincias', 1.5], ['comunidades', 2]]) {
      if (capas[capa]) mapa.addLayer({ id: `${capa}-borde`, type: 'line', ...fuente(capa), paint: { 'line-color': tinta, 'line-width': ancho } });
    }
    // Resaltes: un halo de placa debajo de la línea de tinta, para que se vean sobre cualquier tramo.
    // `capa`: la de las secciones o la de un territorio (municipios, provincias y comunidades:
    // el que está bajo el ratón, en su franja de zoom, y el elegido, a todas las escalas).
    const resalte = (id, estado, ancho, discontinua, capa = 'secciones', zoom = {}) => {
      const visible = ['case', ['boolean', ['feature-state', estado], false], 1, 0];
      mapa.addLayer({
        id: `${id}-halo`, type: 'line', ...fuente(capa), ...zoom,
        paint: { 'line-color': css('--color-placa'), 'line-width': ancho + 3, 'line-opacity': visible },
      });
      mapa.addLayer({
        id, type: 'line', ...fuente(capa), ...zoom,
        paint: {
          'line-color': tinta, 'line-width': ancho, 'line-opacity': visible,
          ...(discontinua ? { 'line-dasharray': [1.5, 1] } : {}),
        },
      });
    };
    for (const { capa, desde, hasta } of RELLENOS.filter((r) => r.capa !== 'secciones')) {
      resalte(`${capa}-encima`, 'encima', 1.5, false, capa, { minzoom: desde, maxzoom: hasta });
      resalte(`${capa}-seleccion`, 'sel', 3.5, false, capa);
    }
    resalte('secciones-encima', 'encima', 1.5);
    resalte('secciones-comparada', 'cmp', 3, true);
    resalte('secciones-seleccion', 'sel', 3.5);
  }

  // F5 (indicador 20 y demás mapas sin sección): nivel más fino del mapa activo. Con «municipio», la
  // capa de municipios se ve y responde a toda escala y las secciones se apagan (ponerNivelMinimo).
  let nivelMinimo = 'sc';
  const CAPAS_SECCION = ['secciones-relleno', 'secciones-secreto', 'secciones-contorno', 'secciones-encima-halo', 'secciones-encima',
    'secciones-comparada-halo', 'secciones-comparada', 'secciones-seleccion-halo', 'secciones-seleccion'];

  let seleccionada = null;
  let comparada = null;
  let territorio = null;   // { capa, codigo } del territorio elegido
  let encima = null;       // { capa, codigo } bajo el ratón
  const marcarEn = (capa, codigo, estado) => codigo && mapa.setFeatureState(objetivoEn(capa, codigo), estado);
  const marcar = (codigo, estado) => marcarEn('secciones', codigo, estado);
  const capaDe = (nivel) => RELLENOS.find((r) => r.nivel === nivel)?.capa ?? null;

  // Etiqueta con ratón (no con el dedo, donde la ficha hace ese papel): sigue al cursor dentro del
  // marco del mapa y cambia de texto al cambiar de territorio. Lo que mueve el puntero lo dice el
  // propio evento (pointerType), que llega antes que el «mousemove» de MapLibre; tras un toque, el
  // navegador también emite un «mousemove», que así no saca la etiqueta.
  let tipoPuntero = null;
  const anotarPuntero = (ev) => {
    tipoPuntero = ev.pointerType;
    if (tipoPuntero !== 'mouse') quitarEtiqueta();
  };
  contenedor.addEventListener('pointermove', anotarPuntero, { capture: true, passive: true });
  contenedor.addEventListener('pointerdown', anotarPuntero, { capture: true, passive: true });
  const conRaton = () => tipoPuntero === 'mouse';
  let textoEtiqueta = null;
  // `datos`: los atributos del suelo sin sección (atributosSinSeccion), que no tiene código.
  function etiquetar(e, nivel, codigo, datos = null) {
    if (!etiqueta || !etiquetaDe || !conRaton()) return;
    const clave = `${nivel}:${codigo}`;
    if (clave !== textoEtiqueta) {
      const lineas = codigo ? etiquetaDe(nivel, codigo, datos) : [];
      etiqueta.replaceChildren(...lineas.map((texto, i) => {
        const span = document.createElement('span');
        span.className = i ? 'mapa-etiqueta-linea' : 'mapa-etiqueta-nombre';
        span.textContent = texto;
        return span;
      }));
      textoEtiqueta = clave;
      etiqueta.hidden = !lineas.length;
    }
    if (etiqueta.hidden) return;
    const marco = contenedor.getBoundingClientRect();
    const ancho = etiqueta.offsetWidth;
    const alto = etiqueta.offsetHeight;
    const x = e.point.x + 14 + ancho > marco.width ? e.point.x - 14 - ancho : e.point.x + 14;
    const y = e.point.y + 14 + alto > marco.height ? e.point.y - 14 - alto : e.point.y + 14;
    etiqueta.style.transform = `translate(${Math.max(0, x)}px, ${Math.max(0, y)}px)`;
  }
  function quitarEtiqueta() {
    if (!etiqueta) return;
    etiqueta.hidden = true;
    textoEtiqueta = null;
  }

  function ponerEncima(capa, codigo) {
    if (encima && (encima.capa !== capa || encima.codigo !== codigo)) marcarEn(encima.capa, encima.codigo, { encima: false });
    encima = codigo ? { capa, codigo } : null;
    if (encima) marcarEn(capa, codigo, { encima: true });
  }

  function interaccion() {
    for (const { capa, nivel } of RELLENOS) {
      const id = capas[capa].id;
      const capaMapa = `${capa}-relleno`;
      const codigoDe = (e) => {
        const x = e.features?.[0]?.properties?.[id];
        return x === undefined || x === null ? null : String(x);
      };
      mapa.on('mousemove', capaMapa, (e) => {
        const codigo = codigoDe(e);
        ponerEncima(capa, codigo);
        mapa.getCanvas().style.cursor = 'pointer';
        etiquetar(e, nivel, codigo);
      });
      mapa.on('mouseleave', capaMapa, () => {
        ponerEncima(null, null);
        mapa.getCanvas().style.cursor = '';
        quitarEtiqueta();
      });
      mapa.on('click', capaMapa, (e) => {
        const codigo = codigoDe(e);
        if (!codigo) return;
        if (nivel === 'sc') alPulsar(codigo);
        else alPulsarTerritorio?.(nivel, codigo);
      });
    }
    if (capas.sin_seccion && alPulsarSinSeccion) {
      const deSinSeccion = (e) => elegirSinSeccion((e.features ?? []).map((f) => f.properties));   // el trozo con nombre, si lo hay
      const debajo = (e) => mapa.queryRenderedFeatures(e.point, { layers: RELLENOS.map((r) => `${r.capa}-relleno`) }).length > 0;
      mapa.on('mousemove', 'sin-seccion-relleno', (e) => {
        mapa.getCanvas().style.cursor = 'pointer';
        if (debajo(e)) return;   // la sección (o el territorio) manda
        const p = deSinSeccion(e);
        etiquetar(e, 'sin_seccion', p ? `${p.nombre ?? ''}|${p.provincias ?? ''}|${p.km2 ?? ''}` : null, p ? atributosSinSeccion(p) : null);
      });
      mapa.on('mouseleave', 'sin-seccion-relleno', () => { mapa.getCanvas().style.cursor = ''; quitarEtiqueta(); });
      mapa.on('click', 'sin-seccion-relleno', (e) => {
        if (debajo(e)) return;   // la sección manda; con poco zoom, la provincia o la comunidad que lo incluye
        const p = deSinSeccion(e);
        if (p) alPulsarSinSeccion(atributosSinSeccion(p));
      });
    }
    // Teclado: el clic no puede ser la única forma de elegir. Con el foco en el mapa (las flechas lo
    // mueven; + y −, lo acercan y lo alejan), Intro elige el territorio que hay en el centro de la
    // vista, que una cruz marca mientras el mapa tiene el foco (sitio.css). Vale también para elegir
    // la sección con que comparar.
    mapa.getCanvas().addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' || e.altKey || e.ctrlKey || e.metaKey) return;
      const centro = mapa.project(mapa.getCenter());
      for (const { capa, nivel } of RELLENOS) {
        const x = mapa.queryRenderedFeatures(centro, { layers: [`${capa}-relleno`] })[0]?.properties?.[capas[capa].id];
        if (x === undefined || x === null) continue;
        e.preventDefault();
        if (nivel === 'sc') alPulsar(String(x));
        else alPulsarTerritorio?.(nivel, String(x));
        return;
      }
    });
    mapa.on('moveend', () => alMover(mapa));
    mapa.on('movestart', quitarEtiqueta);
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
    // Territorio elegido (municipio, provincia o comunidad: { nivel, codigo }), o null.
    seleccionarTerritorio(elegido) {
      if (territorio) marcarEn(territorio.capa, territorio.codigo, { sel: false });
      const capa = elegido ? capaDe(elegido.nivel) : null;
      territorio = capa ? { capa, codigo: elegido.codigo } : null;
      if (territorio) marcarEn(capa, elegido.codigo, { sel: true });
    },
    // Niveles que el mapa pinta y pulsa (comunidad, provincia, municipio y sección).
    niveles: RELLENOS.map((r) => r.nivel),
    // Capas coloreadas por valores: [{ capa, nivel, id }].
    rellenos: RELLENOS.map((r) => ({ ...r, id: capas[r.capa].id })),
    // F5: nivel más fino del mapa activo: «municipio» (mapas sin sección, como el 20: los municipios
    // llegan hasta el zoom máximo y las secciones no se pintan ni responden), «provincia» (tarea 46:
    // mapas sin municipio, como el 11; las provincias llegan hasta el zoom máximo y los municipios y
    // las secciones se apagan) o «sc» (lo de siempre).
    ponerNivelMinimo(nivel) {
      const corte = RELLENOS.findIndex((r) => r.nivel === nivel && r.capa !== 'secciones');
      const nuevo = corte >= 0 && ['municipio', 'provincia'].includes(nivel) ? nivel : 'sc';
      if (nuevo === nivelMinimo) return;
      nivelMinimo = nuevo;
      RELLENOS.forEach((r, i) => {
        if (r.capa === 'secciones') return;
        r.hasta = nuevo !== 'sc' && i === corte ? 24 : r.franja;
        const visible = nuevo === 'sc' || i <= corte ? 'visible' : 'none';
        for (const id of [`${r.capa}-relleno`, `${r.capa}-encima-halo`, `${r.capa}-encima`]) {
          if (!mapa.getLayer(id)) continue;
          mapa.setLayerZoomRange(id, r.desde, r.hasta);
          mapa.setLayoutProperty(id, 'visibility', visible);
        }
      });
      for (const id of CAPAS_SECCION) {
        if (mapa.getLayer(id)) mapa.setLayoutProperty(id, 'visibility', nuevo === 'sc' ? 'visible' : 'none');
      }
      // Con la provincia como nivel más fino, ni los bordes de los municipios ni el suelo sin sección
      // (que es de alguna provincia): el mapa no debe parecer municipal
      for (const id of ['municipios-borde', 'sin-seccion-relleno']) {
        if (mapa.getLayer(id)) mapa.setLayoutProperty(id, 'visibility', nuevo === 'provincia' ? 'none' : 'visible');
      }
    },
    nivelMinimo: () => nivelMinimo,
    // Nivel que se ve a la escala actual (provincia, municipio o sección).
    nivelVisible() {
      const zoom = mapa.getZoom();
      return (RELLENOS.find((r) => zoom < r.hasta) ?? RELLENOS.at(-1)).nivel;
    },
    // Municipio en el centro de la vista (escala relativa al municipio y superficie típica, sin ficha):
    // el de la sección pintada en el centro o, con menos zoom, el del municipio; si no hay, null.
    municipioEnCentro() {
      const punto = mapa.project(mapa.getCenter());
      for (const capa of ['secciones', 'municipios']) {
        if (!capas[capa]?.id || !mapa.getLayer(`${capa}-relleno`)) continue;
        const f = mapa.queryRenderedFeatures(punto, { layers: [`${capa}-relleno`] })[0];
        const x = f?.properties?.[capas[capa].id];
        if (x !== undefined && x !== null) return String(x).slice(0, 5);
      }
      return null;
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
      mapa.getCanvas().setAttribute('aria-label', t('interfaz.mapa.lienzo'));   // MapLibre lo deja en «Map»
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
