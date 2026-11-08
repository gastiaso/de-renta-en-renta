// Sección «Sobrecarga» (sobrecarga.html, v0.0): un solo mapa de Europa con MapLibre que cambia de
// escala según el corte, «la escalera», la serie y los desgloses de España, el módulo de acceso y
// la caja de método. Datos: datos/sobrecarga/ (R/web_sobrecarga.R); lógica sin DOM en
// sobrecarga_datos.js.
//
// El mapa no lleva teselas de fondo: el mar es el color de fondo y la tierra, las geometrías NUTS
// de GISCO (© EuroGeographics para los límites administrativos), en la proyección de Europa de
// Eurostat (ver R/web_sobrecarga.R). Los valores van como estado de cada territorio
// (feature-state) y el color sale de una expresión de estilo, como en el explorador.

import * as maplibregl from 'maplibre-gl';
import { cargarIdioma, traducirPagina } from './i18n.js';
import { rampaDeCss, contornoDe, pasosDeRampa } from './colores.js';
import { ordenNatural } from './nombres.js';
import * as S from './sobrecarga_datos.js';

const css = (nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();
const $ = (id) => document.getElementById(id);
const SVG = 'http://www.w3.org/2000/svg';

let t;                      // traductor del idioma activo
let datos;                  // sobrecarga.json
let estado;                 // { idioma, corte, grupo, anio, geo }
let anioTotal;              // último año elegido con toda la población (para volver a él)
let anioDesgloses;          // ola de los desgloses de España
let escaleraCompleta = false;
let mapa;
let mapaListo;
let atribucion;
let popup;
let versionPintada = null;
let turno = 0;
let anchoSerie = 0;         // ancho con que se dibujó la serie (se redibuja si cambia)
const geometrias = new Map(); // versión NUTS → promesa del GeoJSON

// Crea un elemento con atributos e hijos (texto siempre con textContent: los nombres son datos).
function el(etiqueta, atributos = {}, ...hijos) {
  const e = document.createElement(etiqueta);
  for (const [k, v] of Object.entries(atributos)) {
    if (v === null || v === undefined || v === false) continue;
    if (k === 'class') e.className = v;
    else if (k === 'style') e.setAttribute('style', v);
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
    else e.setAttribute(k, v === true ? '' : String(v));
  }
  for (const h of hijos.flat()) {
    if (h === null || h === undefined || h === false) continue;
    e.append(h instanceof Node ? h : document.createTextNode(String(h)));
  }
  return e;
}

function svg(etiqueta, atributos = {}, texto = null) {
  const e = document.createElementNS(SVG, etiqueta);
  for (const [k, v] of Object.entries(atributos)) if (v !== null && v !== undefined) e.setAttribute(k, String(v));
  if (texto !== null) e.textContent = texto;
  return e;
}

const vista = () => S.vistaDe(datos, estado);
const esc = (fila) => S.valorDe(fila, datos.escala);
const pct = (v) => S.porcentaje(v, t);
const nombre = (geo, opciones) => S.nombreDe(geo, datos, t, ordenNatural, opciones);
const olas = () => ({ desde: datos.olas.agrupadas[0], hasta: datos.olas.agrupadas[1] });

// --- Arranque -----------------------------------------------------------------------------------

async function iniciar() {
  estado = S.leerEstado(location.search);
  t = await cargarIdioma(estado.idioma);
  traducir();
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.addEventListener('click', () => cambiarIdioma(boton.dataset.idioma));
  }
  try {
    const respuesta = await fetch(S.RUTA_DATOS);
    if (!respuesta.ok) throw new Error(`${S.RUTA_DATOS}: ${respuesta.status}`);
    datos = await respuesta.json();
  } catch (error) {
    console.error(error);
    const aviso = $('sc-estado');
    aviso.removeAttribute('data-i18n');
    aviso.textContent = t('sobrecarga.error_carga');
    aviso.classList.add('sc-estado-error');
    return;
  }
  estado = S.leerEstado(location.search, datos);
  anioTotal = estado.corte === 'total' ? estado.anio : S.ultimoAnio(datos);
  anioDesgloses = Math.max(...datos.olas.anuales);
  $('sc-estado').hidden = true;
  $('sc-contenido').hidden = false;
  $('sc-escalera-modo').addEventListener('click', () => {
    escaleraCompleta = !escaleraCompleta;
    pintarEscalera();
  });
  crearMapa();
  pintarTodo();
  new ResizeObserver(() => {
    if (Math.abs($('sc-serie').clientWidth - anchoSerie) > 24) pintarSerie();
  }).observe($('sc-serie'));
}

function traducir() {
  traducirPagina(t);
  document.title = t('sobrecarga.titulo_pagina');
  document.querySelector('meta[name="description"]')?.setAttribute('content', t('sobrecarga.descripcion'));
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.setAttribute('aria-pressed', String(boton.dataset.idioma === estado.idioma));
  }
  // Enlaces a las otras páginas con el idioma activo
  for (const enlace of document.querySelectorAll('[data-enlace]')) {
    enlace.href = `./${estado.idioma === 'en' ? '?idioma=en' : ''}${enlace.dataset.enlace}`;
  }
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  traducir();
  if (!datos) return;
  if (mapa && atribucion) {
    mapa.removeControl(atribucion);
    atribucion = new maplibregl.AttributionControl({ compact: true, customAttribution: t('sobrecarga.mapa.licencia') });
    mapa.addControl(atribucion, 'bottom-right');
  }
  pintarTodo();
}

function guardarEstado() {
  const nueva = S.consulta(estado, datos);
  if (nueva !== location.search) history.replaceState(null, '', `${location.pathname}${nueva}`);
}

function pintarTodo() {
  pintarControles();
  pintarCifras();
  pintarCabeceraMapa();
  pintarLeyenda();
  pintarMapa();
  pintarDetalle();
  pintarComunidades();
  pintarEscalera();
  pintarSerie();
  pintarDesgloses();
  pintarAcceso();
  guardarEstado();
}

// --- Controles ----------------------------------------------------------------------------------

function botones(contenedor, opciones, alElegir) {
  contenedor.replaceChildren(...opciones.map((o) => el('button', {
    type: 'button', 'aria-pressed': String(Boolean(o.activo)), disabled: o.desactivado || null, title: o.titulo ?? null,
    onclick: () => alElegir(o.valor),
  }, o.texto)));
}

function elegir(corte, grupo) {
  if (grupo === 'total') {
    if (estado.corte !== corte) return;
    Object.assign(estado, { corte: 'total', grupo: 'total', anio: anioTotal });
  } else {
    Object.assign(estado, { corte, grupo, anio: datos.anio_desgloses });
  }
  pintarTodo();
}

function pintarControles() {
  const opcionesDe = (corte, textoTodos) => [
    { valor: 'total', texto: t(textoTodos), activo: estado.corte !== corte },
    ...S.gruposCon(datos, corte).map((g) => ({
      valor: g, texto: t(`sobrecarga.controles.grupos.${g}`), titulo: t(`vocabulario.${corte}.${g}`),
      activo: estado.corte === corte && estado.grupo === g,
    })),
  ];
  botones($('sc-tenencia'), opcionesDe('tenencia', 'sobrecarga.controles.toda_poblacion'), (g) => elegir('tenencia', g));
  botones($('sc-edad'), opcionesDe('edad', 'sobrecarga.controles.todas_edades'), (g) => elegir('edad', g));
  const total = estado.corte === 'total';
  botones($('sc-anio'), datos.anios.map((a) => ({
    valor: a, texto: String(a), activo: a === estado.anio, desactivado: !total && a !== estado.anio,
  })), (a) => {
    if (!total) return;
    estado.anio = anioTotal = a;
    pintarTodo();
  });
  const notas = [t('sobrecarga.controles.nota_rentas', { anio: estado.anio, anterior: estado.anio - 1 })];
  if (!total) notas.push(t('sobrecarga.controles.nota_desglose', { anio: datos.anio_desgloses }));
  $('sc-nota-controles').textContent = notas.join(' ');
}

function pintarCifras() {
  const v = vista();
  const cifra = (clase, etiqueta, fila, nota) => [
    el('div', { class: `sc-cifra ${clase}` },
      el('dt', {}, etiqueta),
      el('dd', {}, pct(esc(fila))),
      nota ? el('dd', { class: 'sc-cifra-nota' }, nota) : null),
  ];
  const es = S.referencia(v, 'ES');
  const ue = S.referencia(v, 'EU27_2020');
  $('sc-cifras').replaceChildren(
    ...(es ? cifra('sc-cifra-espana', t('sobrecarga.cifras.espana'), es,
                   es.n ? t('sobrecarga.cifras.muestra', { n: t.numero(es.n) }) : t('sobrecarga.cifras.eurostat')) : []),
    ...(ue ? cifra('sc-cifra-ue', t('sobrecarga.cifras.ue27'), ue, t('sobrecarga.cifras.eurostat')) : []),
  );
}

// --- Mapa ---------------------------------------------------------------------------------------

function crearMapa() {
  const [o, s, e, n] = datos.limites;
  const margen = Math.max(e - o, n - s) * 0.15;
  mapa = new maplibregl.Map({
    container: 'sc-mapa',
    style: { version: 8, sources: {}, layers: [{ id: 'mar', type: 'background', paint: { 'background-color': css('--color-mar') } }] },
    bounds: datos.limites,
    fitBoundsOptions: { padding: 8 },
    maxBounds: [o - margen, s - margen, e + margen, n + margen],
    renderWorldCopies: false,
    attributionControl: false,
    cooperativeGestures: true,       // en una página que se desplaza, la rueda sola no amplía el mapa
    dragRotate: false,
    pitchWithRotate: false,
    maxPitch: 0,
    locale: {
      'NavigationControl.ZoomIn': t('sobrecarga.mapa.acercar'),
      'NavigationControl.ZoomOut': t('sobrecarga.mapa.alejar'),
      'CooperativeGesturesHandler.WindowsHelpText': t('sobrecarga.mapa.gesto_windows'),
      'CooperativeGesturesHandler.MacHelpText': t('sobrecarga.mapa.gesto_mac'),
      'CooperativeGesturesHandler.MobileHelpText': t('sobrecarga.mapa.gesto_movil'),
    },
  });
  mapa.touchZoomRotate.disableRotation();
  mapa.keyboard.disableRotation();
  mapa.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
  atribucion = new maplibregl.AttributionControl({ compact: true, customAttribution: t('sobrecarga.mapa.licencia') });
  mapa.addControl(atribucion, 'bottom-right');
  popup = new maplibregl.Popup({ closeButton: false, closeOnClick: false, className: 'sc-popup', offset: 12, maxWidth: '280px' });
  // Las capas se añaden en cuanto el estilo (solo el fondo) está listo, sin esperar a «load», que
  // espera también a los trabajadores de MapLibre; la geometría ya se está descargando.
  cargarGeometria(vista().nuts);
  mapaListo = new Promise((resolver) => {
    if (mapa.isStyleLoaded()) resolver();
    else mapa.once('style.load', resolver);
  }).then(anadirCapas);
}

// Trama de líneas finas de placa sobre el color del tramo: horizontales para el dato de un nivel
// más grueso (país o NUTS 1) y diagonales para la muestra pequeña (como .muestra-pequena).
function trama(diagonal) {
  const lado = 12;
  const lienzo = document.createElement('canvas');
  lienzo.width = lienzo.height = lado;
  const ctx = lienzo.getContext('2d');
  ctx.strokeStyle = css('--color-placa');
  ctx.lineWidth = 2;
  ctx.beginPath();
  if (diagonal) {
    for (const d of [-lado, 0, lado]) { ctx.moveTo(d, lado); ctx.lineTo(d + lado, 0); }
  } else {
    for (const y of [1, 1 + lado / 2]) { ctx.moveTo(0, y); ctx.lineTo(lado, y); }
  }
  ctx.stroke();
  return ctx.getImageData(0, 0, lado, lado);
}

function coloresTramos(tramos) {
  const rampa = rampaDeCss();
  return pasosDeRampa(tramos, rampa.length).map((i) => rampa[i]);
}

function anadirCapas() {
  const tinta = css('--color-tinta');
  const placa = css('--color-placa');
  const fuera = css('--color-fuera');
  mapa.addSource('nuts', { type: 'geojson', data: { type: 'FeatureCollection', features: [] }, promoteId: 'id' });
  mapa.addImage('trama-grueso', trama(false), { pixelRatio: 2 });
  mapa.addImage('trama-muestra', trama(true), { pixelRatio: 2 });
  const region = ['==', ['get', 'tipo'], 'region'];
  const paises = ['all', region, ['==', ['get', 'nivel'], 0]];
  const ninguno = ['in', ['get', 'id'], ['literal', []]];
  // Seis tramos como mucho (cinco cortes): el color y el contorno de cada uno, por su número
  const colores = coloresTramos(6);
  const porTramo = (valores, otro) => ['match', ['coalesce', ['feature-state', 'tramo'], -1],
    ...valores.flatMap((c, i) => [i, c]), otro];
  mapa.addLayer({ id: 'tierra', type: 'fill', source: 'nuts', filter: paises, paint: { 'fill-color': fuera } });
  mapa.addLayer({ id: 'relleno', type: 'fill', source: 'nuts', filter: ninguno, paint: { 'fill-color': porTramo(colores, fuera) } });
  mapa.addLayer({ id: 'trama-grueso', type: 'fill', source: 'nuts', filter: ninguno, paint: { 'fill-pattern': 'trama-grueso' } });
  mapa.addLayer({ id: 'trama-muestra', type: 'fill', source: 'nuts', filter: ninguno, paint: { 'fill-pattern': 'trama-muestra' } });
  mapa.addLayer({
    id: 'contorno', type: 'line', source: 'nuts', filter: ninguno,
    paint: { 'line-color': porTramo(colores.map((c) => contornoDe(c, tinta, placa)), tinta), 'line-width': 0.5 },
  });
  mapa.addLayer({ id: 'fronteras', type: 'line', source: 'nuts', filter: paises, paint: { 'line-color': tinta, 'line-width': 0.9 } });
  mapa.addLayer({
    id: 'recuadros', type: 'line', source: 'nuts', filter: ['==', ['get', 'tipo'], 'recuadro'],
    paint: { 'line-color': tinta, 'line-width': 1.2 },
  });
  mapa.addLayer({ id: 'seleccion-halo', type: 'line', source: 'nuts', filter: ['==', ['get', 'id'], ''], paint: { 'line-color': placa, 'line-width': 5 } });
  mapa.addLayer({ id: 'seleccion', type: 'line', source: 'nuts', filter: ['==', ['get', 'id'], ''], paint: { 'line-color': tinta, 'line-width': 2 } });

  mapa.on('mousemove', 'relleno', (e) => {
    const geo = e.features?.[0]?.properties?.id;
    const fila = geo && vista().filas.find((f) => f.geo === geo);
    if (!fila) return;
    mapa.getCanvas().style.cursor = 'pointer';
    popup.setLngLat(e.lngLat).setDOMContent(el('div', {},
      el('b', {}, nombre(geo)), el('br'),
      `${pct(esc(fila))}${fila.puesto ? ` · ${t('sobrecarga.detalle.puesto', { p: fila.puesto, n: S.puestos(vista()) })}` : ''}`,
    )).addTo(mapa);
  });
  mapa.on('mouseleave', 'relleno', () => {
    mapa.getCanvas().style.cursor = '';
    popup.remove();
  });
  mapa.on('click', 'relleno', (e) => {
    const geo = e.features?.[0]?.properties?.id;
    if (geo) seleccionar(geo);
  });
}

function cargarGeometria(version) {
  if (!geometrias.has(version)) {
    geometrias.set(version, fetch(datos.geometrias[version]).then((r) => {
      if (!r.ok) throw new Error(`${datos.geometrias[version]}: ${r.status}`);
      return r.json();
    }));
  }
  return geometrias.get(version);
}

async function pintarMapa() {
  const mio = ++turno;
  const v = vista();
  await mapaListo;
  const geojson = await cargarGeometria(v.nuts);
  if (mio !== turno) return;   // otra vista más reciente
  if (versionPintada !== v.nuts) {
    mapa.getSource('nuts').setData(geojson);
    versionPintada = v.nuts;
  }
  mapa.removeFeatureState({ source: 'nuts' });
  const cortes = S.cortesDe(datos, v.grupo);
  const ids = [];
  for (const fila of S.pintables(v)) {
    ids.push(fila.geo);
    const tramo = S.tramoDe(esc(fila), cortes);
    if (tramo !== null) mapa.setFeatureState({ source: 'nuts', id: fila.geo }, { tramo });
  }
  const filtro = ['in', ['get', 'id'], ['literal', ids]];
  mapa.setFilter('relleno', filtro);
  mapa.setFilter('contorno', filtro);
  mapa.setFilter('trama-grueso', ['in', ['get', 'id'], ['literal', S.conTramaGruesa(v)]]);
  mapa.setFilter('trama-muestra', ['in', ['get', 'id'], ['literal', S.conMuestraPequena(v)]]);
  marcarSeleccion();
  pintarNotaMapa(geojson);
}

function marcarSeleccion() {
  if (!mapa?.getLayer('seleccion')) return;
  const filtro = ['==', ['get', 'id'], estado.geo ?? ''];
  mapa.setFilter('seleccion', filtro);
  mapa.setFilter('seleccion-halo', filtro);
}

function seleccionar(geo) {
  estado.geo = estado.geo === geo ? null : geo;
  marcarSeleccion();
  pintarDetalle();
  pintarEscalera();
  guardarEstado();
}

function pintarCabeceraMapa() {
  const v = vista();
  const total = v.corte === 'total';
  $('sc-mapa-titulo').textContent = t(total ? 'sobrecarga.mapa.titulo_regiones' : 'sobrecarga.mapa.titulo_paises');
  const conIne = v.filas.some((f) => f.fuente === 'ine_ecv');
  const tabla = v.filas.find((f) => f.tabla && f.bloque === 'europa')?.tabla ?? '';
  $('sc-mapa-fuente').textContent = total
    ? t(conIne ? 'sobrecarga.mapa.fuente_regiones' : 'sobrecarga.mapa.fuente_regiones_eurostat', { anio: v.anio })
    : t('sobrecarga.mapa.fuente_paises', { tabla, anio: v.anio, ...olas() });
}

// Nota bajo el mapa: qué publica Eurostat en cada caso y qué territorios de la escalera no tienen
// geometría en el mapa.
function pintarNotaMapa(geojson) {
  const v = vista();
  const ids = new Set(geojson.features.map((f) => f.properties.id));
  const sinMapa = S.pintables(v).filter((f) => !ids.has(f.geo)).map((f) => nombre(f.geo));
  const partes = [t(v.corte === 'total' ? 'sobrecarga.mapa.nota_regiones' : 'sobrecarga.mapa.nota_paises', olas())];
  if (sinMapa.length) partes.push(t('sobrecarga.mapa.sin_mapa', { lista: sinMapa.join(', ') }));
  $('sc-nota-mapa').textContent = partes.join(' ');
}

function pintarLeyenda() {
  const v = vista();
  const cortes = S.cortesDe(datos, v.grupo);
  const colores = coloresTramos(cortes.length + 1);
  const etiquetas = S.etiquetasTramos(cortes, t, t.numero);
  const muestra = (clase, estilo = null) => el('span', { class: `sc-muestra ${clase}`, style: estilo, 'aria-hidden': 'true' });
  const items = etiquetas.map((texto, i) => el('li', {}, muestra('', `background:${colores[i]}`), texto));
  items.push(el('li', {}, muestra('sc-muestra-sin-dato'), t('sobrecarga.leyenda.sin_dato')));
  if (S.conTramaGruesa(v).length) items.push(el('li', {}, muestra('sc-muestra-grueso'), t('sobrecarga.leyenda.grueso')));
  if (S.conMuestraPequena(v).length) items.push(el('li', {}, muestra('sc-muestra-pequena'), t('sobrecarga.leyenda.muestra')));
  $('sc-leyenda').replaceChildren(
    el('p', { class: 'sc-leyenda-titulo' }, t('sobrecarga.leyenda.titulo')),
    el('ul', { class: 'sc-leyenda-lista' }, items),
  );
}

// --- Territorio elegido -------------------------------------------------------------------------

function pintarDetalle() {
  const v = vista();
  const fila = estado.geo ? v.filas.find((f) => f.geo === estado.geo) : null;
  const caja = $('sc-detalle');
  if (!fila) {
    caja.replaceChildren(el('p', { class: 'sc-detalle-vacio' }, t('sobrecarga.detalle.vacio')));
    return;
  }
  const valor = esc(fila);
  const lineas = [];
  if (fila.fuente === 'ine_ecv') {
    lineas.push(t('sobrecarga.detalle.fuente_ine'));
    lineas.push(fila.bloque === 'comunidad' && v.corte !== 'total'
      ? t('sobrecarga.detalle.olas', olas()) : t('sobrecarga.detalle.anio', { anio: v.anio }));
    if (fila.n) lineas.push(`${t('sobrecarga.detalle.muestra', { n: t.numero(fila.n), h: t.numero(fila.hogares) })} · ${t(`vocabulario.fiabilidad.${fila.fiabilidad}`)}`);
  } else {
    lineas.push(`${t('sobrecarga.detalle.fuente_eurostat', { tabla: fila.tabla })} · ${t('sobrecarga.detalle.anio', { anio: v.anio })}`);
    if (fila.bandera) lineas.push(t('sobrecarga.detalle.bandera', { b: fila.bandera }));
  }
  if (v.corte === 'total' && fila.nivel === 0) lineas.push(t('sobrecarga.detalle.nivel_pais'));
  if (v.corte === 'total' && fila.nivel === 1) lineas.push(t('sobrecarga.detalle.nivel_nuts1'));
  if (valor === null) lineas.unshift(t('sobrecarga.detalle.sin_valor'));
  caja.replaceChildren(
    el('div', { class: 'sc-detalle-cabecera' },
      el('p', { class: 'sc-detalle-nombre' }, nombre(fila.geo)),
      el('button', { type: 'button', class: 'sc-cerrar', 'aria-label': t('sobrecarga.detalle.cerrar'), onclick: () => seleccionar(fila.geo) }, '×')),
    el('p', { class: 'sc-detalle-cifra' },
      el('span', { class: 'sc-detalle-numero' }, pct(valor)),
      fila.puesto ? el('span', {}, t('sobrecarga.detalle.puesto', { p: fila.puesto, n: S.puestos(v) })) : null),
    el('ul', { class: 'sc-detalle-lista' }, lineas.map((l) => el('li', {}, l))),
  );
}

function pintarComunidades() {
  const v = vista();
  const filas = v.filas.filter((f) => f.bloque === 'comunidad').sort((a, b) => (a.puesto ?? 1e9) - (b.puesto ?? 1e9));
  const c = (k) => t(`sobrecarga.comunidades.${k}`);
  $('sc-comunidades').querySelector('.sc-tabla-marco').replaceChildren(el('table', { class: 'sc-tabla' },
    el('thead', {}, el('tr', {}, ['comunidad', 'valor', 'puesto', 'personas', 'hogares', 'fiabilidad'].map((k) => el('th', { scope: 'col' }, c(k))))),
    el('tbody', {}, filas.map((f) => el('tr', {},
      el('th', { scope: 'row' }, nombre(f.geo)),
      el('td', {}, esc(f) === null ? '—' : t.numero(esc(f), 1)),
      el('td', {}, f.puesto ?? '—'),
      el('td', {}, f.n ? t.numero(f.n) : '—'),
      el('td', {}, f.hogares ? t.numero(f.hogares) : '—'),
      el('td', {}, f.fiabilidad ? t(`vocabulario.fiabilidad.${f.fiabilidad}`) : t('sobrecarga.cifras.eurostat')))))));
}

// --- La escalera --------------------------------------------------------------------------------

function pintarEscalera() {
  const v = vista();
  const cortes = S.cortesDe(datos, v.grupo);
  const colores = coloresTramos(cortes.length + 1);
  const valores = v.filas.map(esc).filter((x) => x !== null);
  const maximo = Math.max(...valores, 1);
  const periodo = v.corte === 'total' ? String(v.anio) : t('sobrecarga.escalera.periodo_paises', { anio: v.anio, ...olas() });
  $('sc-escalera-sub').textContent = t('sobrecarga.escalera.subtitulo', { n: t.numero(S.puestos(v)), periodo });

  const peldano = (fila) => {
    const valor = esc(fila);
    const tramo = S.tramoDe(valor, cortes);
    const tipo = S.tipoDe(fila);
    return el('li', { class: `sc-peldano${tipo === 'referencia' ? ' sc-peldano-referencia' : ''}` },
      el('button', { type: 'button', 'aria-current': fila.geo === estado.geo ? 'true' : null, onclick: () => seleccionar(fila.geo) },
        el('span', { class: 'sc-puesto' }, fila.puesto ? t('sobrecarga.formato.puesto', { p: fila.puesto }) : '—'),
        el('span', { class: 'sc-nombre' },
          el('span', { class: 'sc-nombre-texto', title: nombre(fila.geo) }, nombre(fila.geo)),
          el('span', { class: 'sc-barra', 'aria-hidden': 'true' },
            valor === null ? null : el('span', { style: `width:${((100 * valor) / maximo).toFixed(1)}%;background:${colores[tramo]}` }))),
        el('span', { class: `sc-etiqueta sc-etiqueta-${tipo}` }, t(`sobrecarga.escalera.etiquetas.${tipo}`)),
        el('span', { class: 'sc-valor' }, pct(valor))));
  };
  const cuerpo = $('sc-escalera-cuerpo');
  if (escaleraCompleta) {
    cuerpo.replaceChildren(
      el('h3', { class: 'sc-bloque-titulo' }, t('sobrecarga.escalera.completa')),
      el('ol', { class: 'sc-peldanos' }, S.escaleraCompleta(v).map(peldano)));
  } else {
    const b = S.bloquesEscalera(v);
    const bloque = (clave, filas) => (filas.length
      ? [el('h3', { class: 'sc-bloque-titulo' }, t(`sobrecarga.escalera.${clave}`)), el('ol', { class: 'sc-peldanos' }, filas.map(peldano))]
      : []);
    cuerpo.replaceChildren(
      ...bloque(v.corte === 'total' ? 'europa_regiones' : 'europa_paises', b.europa),
      ...bloque('referencias', b.referencias),
      ...bloque('comunidades', b.comunidades));
  }
  $('sc-escalera-modo').textContent = t(escaleraCompleta ? 'sobrecarga.escalera.ver_bloques' : 'sobrecarga.escalera.ver_completa');
}

// --- Serie de España ----------------------------------------------------------------------------

function pintarSerie() {
  const s = datos.espana.serie;
  const anios = s.anios;
  const series = [
    { clave: 'ES_TOTAL', clase: 'serie-total', ue: false, grupo: 'total', zona: 'espana' },
    { clave: 'ES_RENT_MKT', clase: 'serie-mercado', ue: false, grupo: 'mercado', zona: 'espana' },
    { clave: 'EU27_TOTAL', clase: 'serie-total', ue: true, grupo: 'total', zona: 'ue27' },
    { clave: 'EU27_RENT_MKT', clase: 'serie-mercado', ue: true, grupo: 'mercado', zona: 'ue27' },
  ].map((x) => ({
    ...x,
    valores: s.valores[x.clave].map((v) => (v === null ? null : v / datos.escala)),
    nombre: `${t(`sobrecarga.serie.${x.zona}`)} · ${t(`sobrecarga.serie.${x.grupo}`)}`,
  }));
  // Ancho del dibujo = ancho del contenedor, para que el texto salga a su tamaño en el móvil
  const caja = $('sc-serie');
  const ancho = Math.round(Math.max(300, Math.min(720, caja.clientWidth || 600)));
  anchoSerie = ancho;
  const alto = ancho < 480 ? 250 : 290;
  const m = { izq: 40, der: 118, arr: 14, aba: 30 };
  const techo = S.techoEje(series.map((x) => x.valores), 10);
  const x = S.escalaLineal(anios[0], anios.at(-1), m.izq, ancho - m.der);
  const y = S.escalaLineal(0, techo, alto - m.aba, m.arr);
  const grafico = svg('svg', { viewBox: `0 0 ${ancho} ${alto}`, role: 'img',
    'aria-label': t('sobrecarga.serie.grafico', { desde: anios[0], hasta: anios.at(-1) }) });
  for (let v = 0; v <= techo; v += 10) {
    grafico.append(svg('line', { class: v === 0 ? 'eje' : 'rejilla', x1: m.izq, x2: ancho - m.der, y1: y(v), y2: y(v) }));
    grafico.append(svg('text', { class: 'texto-eje', x: m.izq - 6, y: y(v) + 4, 'text-anchor': 'end' },
                       t('sobrecarga.formato.porcentaje', { x: t.numero(v, 0) })));
  }
  const cada = ancho < 480 ? 4 : 3;
  anios.forEach((a, i) => {
    if ((i % cada === 0 && anios.length - 1 - i >= cada / 2) || i === anios.length - 1) {
      grafico.append(svg('text', { class: 'texto-eje', x: x(a), y: alto - m.aba + 18, 'text-anchor': 'middle' }, String(a)));
    }
  });
  for (const serie of series) {
    grafico.append(svg('path', { class: `linea ${serie.clase}${serie.ue ? ' linea-ue' : ''}`, d: S.trazado(anios, serie.valores, x, y) }));
  }
  // Etiquetas directas al final de cada línea, separadas para que no se pisen
  const finales = series.map((serie) => {
    const i = serie.valores.findLastIndex((v) => v !== null);
    return { serie, i, y: y(serie.valores[i]) };
  });
  const ys = S.separarEtiquetas(finales.map((f) => f.y), 14, m.arr, alto - m.aba);
  finales.forEach((f, k) => {
    grafico.append(svg('circle', { class: `punto ${f.serie.clase}`, cx: x(anios[f.i]), cy: f.y, r: 4 }));
    grafico.append(svg('text', { class: 'etiqueta-linea', x: x(anios[f.i]) + 8, y: ys[k] + 4 },
      `${f.serie.nombre.split(' · ')[0]} ${pct(f.serie.valores[f.i])}`));
  });
  // Capa de lectura: una guía vertical en el año más cercano y un globo con las cuatro cifras
  const guia = svg('line', { class: 'guia', y1: m.arr, y2: alto - m.aba, visibility: 'hidden' });
  const zona = svg('rect', { class: 'zona', x: m.izq, y: m.arr, width: ancho - m.der - m.izq, height: alto - m.aba - m.arr });
  grafico.append(guia, zona);
  const globo = el('div', { class: 'sc-globo', hidden: true });
  zona.addEventListener('pointermove', (e) => {
    const r = grafico.getBoundingClientRect();
    const xv = ((e.clientX - r.left) / r.width) * ancho;
    const i = Math.max(0, Math.min(anios.length - 1, Math.round(((xv - m.izq) / (ancho - m.der - m.izq)) * (anios.length - 1))));
    guia.setAttribute('x1', x(anios[i]));
    guia.setAttribute('x2', x(anios[i]));
    guia.setAttribute('visibility', 'visible');
    globo.replaceChildren(el('p', { class: 'sc-globo-titulo' }, String(anios[i])), el('ul', {}, series.map((serie) => el('li', {},
      el('span', { class: `sc-trazo ${serie.grupo === 'mercado' ? 'sc-trazo-mercado' : ''} ${serie.ue ? 'sc-trazo-ue' : ''}`, 'aria-hidden': 'true' }),
      el('b', {}, pct(serie.valores[i])), serie.nombre))));
    globo.hidden = false;
    const izquierda = ((x(anios[i]) / ancho) * r.width) + 12;
    globo.style.left = `${Math.min(izquierda, r.width - globo.offsetWidth - 4)}px`;
    globo.style.top = '8px';
  });
  zona.addEventListener('pointerleave', () => {
    guia.setAttribute('visibility', 'hidden');
    globo.hidden = true;
  });
  const leyenda = el('ul', { class: 'sc-serie-leyenda' }, series.map((serie) => el('li', {},
    el('span', { class: `sc-trazo ${serie.grupo === 'mercado' ? 'sc-trazo-mercado' : ''} ${serie.ue ? 'sc-trazo-ue' : ''}`, 'aria-hidden': 'true' }),
    serie.nombre)));
  caja.replaceChildren(grafico, globo, leyenda);

  // Tabla con todas las cifras
  $('sc-serie-tabla').querySelector('.sc-tabla-marco').replaceChildren(el('table', { class: 'sc-tabla' },
    el('thead', {}, el('tr', {}, el('th', { scope: 'col' }, t('sobrecarga.serie.anio')), series.map((serie) => el('th', { scope: 'col' }, serie.nombre)))),
    el('tbody', {}, anios.map((a, i) => el('tr', {}, el('th', { scope: 'row' }, String(a)),
      series.map((serie) => el('td', {}, pct(serie.valores[i]))))))));
}

// --- Desgloses de España ------------------------------------------------------------------------

const ORDEN_DESGLOSES = {
  tenencia: ['OWN_NL', 'OWN_L', 'OWN', 'RENT_MKT', 'RENT_FR', 'RENT'],
  edad: ['Y_LT18', 'Y18-64', 'Y_GE65', 'Y15-29'],
};

// Lista de barras: cada elemento { texto, valor, nota, titulo, clase }; escala común `maximo`.
function barras(items, maximo) {
  return el('ul', { class: 'sc-barras' }, items.map((it) => el('li', { title: it.titulo ?? null },
    el('span', { class: 'sc-barras-nombre' }, el('span', {}, it.texto), it.nota ? el('span', { class: 'sc-barras-n' }, it.nota) : null),
    el('span', { class: `sc-barras-pista ${it.clase ?? ''}`, 'aria-hidden': 'true' },
      it.valor === null ? null : el('span', { class: it.fiabilidad === 'baja' ? 'muestra-pequena' : null, style: `width:${((100 * it.valor) / maximo).toFixed(1)}%` })),
    el('span', { class: 'sc-valor' }, pct(it.valor)))));
}

function pintarDesgloses() {
  botones($('sc-desgloses-anio'), datos.olas.anuales.map((a) => ({ valor: a, texto: String(a), activo: a === anioDesgloses })), (a) => {
    anioDesgloses = a;
    pintarDesgloses();
  });
  const filas = datos.espana.anual.filter((f) => f.anio === anioDesgloses);
  const total = filas.find((f) => f.corte === 'total');
  const item = (f, texto, clase) => ({
    texto, valor: esc(f), clase, fiabilidad: f.fiabilidad,
    nota: t('sobrecarga.desgloses.muestra_corta', { n: t.numero(f.n) }),
    titulo: `${t('sobrecarga.detalle.muestra', { n: t.numero(f.n), h: t.numero(f.hogares) })} · ${t(`vocabulario.fiabilidad.${f.fiabilidad}`)}`,
  });
  const maximo = Math.max(...filas.map(esc).filter((v) => v !== null), 1);
  const bloque = (corte) => {
    const grupos = ORDEN_DESGLOSES[corte]
      .map((g) => filas.find((f) => f.corte === corte && f.grupo === g))
      .filter(Boolean)
      .map((f) => item(f, t(`vocabulario.${corte}.${f.grupo}`), f.grupo === 'RENT_MKT' ? 'sc-barras-mercado' : null));
    return el('div', { class: 'sc-desglose' },
      el('h3', {}, t(`sobrecarga.desgloses.${corte}`)),
      barras([...(total ? [item(total, t('sobrecarga.desgloses.total'), 'sc-barras-total')] : []), ...grupos], maximo));
  };
  $('sc-desgloses').replaceChildren(bloque('tenencia'), bloque('edad'));
}

// --- Módulo de acceso (indicador 23) ------------------------------------------------------------

function pintarAcceso() {
  const m = datos.modulo;
  $('sc-acceso-sub').textContent = t('sobrecarga.acceso.subtitulo', { anio: m.anio });
  const v = (x) => (x.v === null ? null : x.v / datos.escala);
  const todos = [...m.ccaa, ...m.edad, ...m.tenencia, ...m.sexo];
  const maximo = Math.max(...todos.map(v).filter((x) => x !== null), 1);
  const comunidades = [...m.ccaa].sort((a, b) => b.v - a.v).map((x) => ({ texto: nombre(x.geo), valor: v(x) }));
  const precio = m.razones.find((r) => r.grupo === 'precio');
  $('sc-acceso').replaceChildren(
    el('p', {}, t('sobrecarga.acceso.definicion')),
    el('p', { class: 'sc-acceso-cifra' }, el('span', {}, t('sobrecarga.acceso.espana')), el('b', {}, pct(m.total / datos.escala))),
    precio ? el('p', {}, t('sobrecarga.acceso.razon', { x: t.numero(v(precio), 1) })) : null,
    el('h3', {}, t('sobrecarga.acceso.comunidades')),
    barras(comunidades.slice(0, 5), maximo),
    el('details', { class: 'sc-plegable' },
      el('summary', {}, t('sobrecarga.acceso.mas', { n: comunidades.length })),
      barras(comunidades.slice(5), maximo)),
    el('h3', {}, t('sobrecarga.acceso.edad')),
    barras(m.edad.map((x) => ({ texto: t(`vocabulario.edad.${x.grupo}`), valor: v(x) })), maximo),
    el('h3', {}, t('sobrecarga.acceso.tenencia')),
    barras(m.tenencia.map((x) => ({ texto: t(`vocabulario.tenencia.${x.grupo}`), valor: v(x) })), maximo),
    el('h3', {}, t('sobrecarga.acceso.sexo')),
    barras(m.sexo.map((x) => ({ texto: t(`vocabulario.sexo.${x.grupo}`), valor: v(x) })), maximo),
    el('p', { class: 'nota' }, t('sobrecarga.acceso.fuente', { anio: m.anio })),
  );
}

iniciar();
