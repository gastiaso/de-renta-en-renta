// Máquina del tiempo (historico.html, F6): series de España desde 1987 (años de renta y esfuerzo
// teórico del Banco de España, tipos oficiales de referencia del mercado hipotecario, valor tasado
// del MIVAU, también por comunidad, y sueldo bruto medio por asalariado del INE), cada una en su
// gráfico, con el mismo eje de años, sus fechas clave y una lectura sin valoraciones. Sin mapa.
// Al final, la vivienda como problema en los barómetros del CIS (mensual, desde 2014), en el mismo
// eje. Datos: datos/historico/historico.json (R/web_historico.R) y datos/cis_vivienda.json
// (R/fuente_cis_barometros.R), que puede faltar; lógica sin DOM en historico_datos.js.

import { cargarIdioma, traducirPagina } from './i18n.js';
import { ordenNatural } from './nombres.js';
import * as H from './historico_datos.js';

const $ = (id) => document.getElementById(id);
const SVG = 'http://www.w3.org/2000/svg';
const CLASES = ['serie-a', 'serie-b'];

let t;          // traductor del idioma activo
let datos;      // historico.json
let cis = null; // cis_vivienda.json (null si no está)
let estado;     // { idioma, ccaa }
let rango;      // años del eje común
const anchos = new Map();   // ancho de la caja con que se dibujó cada gráfico

function el(etiqueta, atributos = {}, ...hijos) {
  const e = document.createElement(etiqueta);
  for (const [k, v] of Object.entries(atributos)) {
    if (v === null || v === undefined || v === false) continue;
    if (k === 'class') e.className = v;
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

// --- Arranque -----------------------------------------------------------------------------------

async function iniciar() {
  estado = H.leerEstado(location.search);
  t = await cargarIdioma(estado.idioma);
  traducir();
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.addEventListener('click', () => cambiarIdioma(boton.dataset.idioma));
  }
  // En el móvil el menú se desplaza en horizontal y esta página va la última: se deja a la vista
  const nav = document.querySelector('.navegacion');
  if (nav && nav.scrollWidth > nav.clientWidth) nav.scrollLeft = nav.scrollWidth;
  const pedidoCis = leerOpcional(H.RUTA_CIS);
  try {
    const respuesta = await fetch(H.RUTA_DATOS);
    if (!respuesta.ok) throw new Error(`${H.RUTA_DATOS}: ${respuesta.status}`);
    datos = await respuesta.json();
  } catch (error) {
    console.error(error);
    const aviso = $('hi-estado');
    aviso.removeAttribute('data-i18n');
    aviso.textContent = t('historico.error_carga');
    aviso.classList.add('hi-estado-error');
    return;
  }
  cis = await pedidoCis;
  estado = H.leerEstado(location.search, datos);
  rango = H.rangoAnios(datos, H.CIS_SERIES.map((p) => H.puntosCis(cis, p)));
  $('hi-estado').hidden = true;
  $('hi-contenido').hidden = false;
  $('hi-ccaa').addEventListener('change', (e) => {
    estado.ccaa = e.target.value || null;
    guardarEstado();
    pintarBloque(H.BLOQUES.find((b) => b.territorial));
  });
  pintarTodo();
  const cambio = (id) => Math.abs(document.querySelector(`[data-bloque="${id}"] .hi-grafico`).clientWidth - (anchos.get(id) ?? 0)) > 24;
  new ResizeObserver(() => {
    for (const b of H.BLOQUES) if (cambio(b.id)) pintarGrafico(b);
    if (cambio(H.CIS_ID)) pintarGraficoCis();
  }).observe($('hi-contenido'));
  // Un ancla del enlace (la casilla «Sube el euríbor» de la portada, #hist-tipos) apunta a contenido
  // que estaba oculto mientras cargaban los datos: se baja hasta ella ahora.
  const ancla = location.hash.length > 1 ? document.getElementById(decodeURIComponent(location.hash.slice(1))) : null;
  if (ancla) ancla.scrollIntoView();
}

function traducir() {
  traducirPagina(t);
  document.title = t('historico.titulo_pagina');
  document.querySelector('meta[name="description"]')?.setAttribute('content', t('historico.descripcion'));
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.setAttribute('aria-pressed', String(boton.dataset.idioma === estado.idioma));
  }
  // Enlaces a las otras páginas (portada, mapa y sobrecarga) con el idioma activo
  for (const enlace of document.querySelectorAll('[data-enlace]')) {
    enlace.href = `${enlace.dataset.pagina ?? './'}${estado.idioma === 'en' ? '?idioma=en' : ''}${enlace.dataset.enlace}`;
  }
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  traducir();
  guardarEstado();
  if (datos) pintarTodo();
}

function guardarEstado() {
  history.replaceState(null, '', `${location.pathname}${H.consulta(estado)}${location.hash}`);
}

// JSON que puede faltar (el del CIS, en la muestra sin pipeline): null, sin error en la consola.
async function leerOpcional(ruta) {
  try {
    const respuesta = await fetch(ruta);
    return respuesta.ok ? await respuesta.json() : null;
  } catch {
    return null;
  }
}

// --- Pintado ------------------------------------------------------------------------------------

function pintarTodo() {
  pintarSelector();
  for (const b of H.BLOQUES) pintarBloque(b);
  pintarCis();
}

function pintarSelector() {
  const sel = $('hi-ccaa');
  sel.replaceChildren(el('option', { value: '' }, t('historico.ccaa_ninguna')),
    ...H.comunidades(datos, ordenNatural).map((c) => el('option', { value: c.codigo, selected: c.codigo === estado.ccaa }, c.nombre)));
}

// Series que dibuja un bloque: las suyas de España y, en el valor tasado, la comunidad elegida.
function seriesDe(bloque) {
  const lista = bloque.series.map((serie, i) => ({ serie, geo: H.ESPANA, clase: CLASES[i], nombre: t(`historico.series.${serie}`) }));
  if (bloque.territorial && estado.ccaa) {
    lista.push({ serie: bloque.series[0], geo: estado.ccaa, clase: CLASES[1],
      nombre: ordenNatural(datos.territorios?.[estado.ccaa] ?? estado.ccaa) });
    lista[0].nombre = t('historico.espana');
  }
  return lista.map((s) => ({ ...s, puntos: H.puntosDe(datos, s.serie, s.geo) ?? [] }));
}

function pintarBloque(bloque) {
  const seccion = document.querySelector(`[data-bloque="${bloque.id}"]`);
  pintarGrafico(bloque);
  // Lectura: primer dato, extremos y último de cada serie
  seccion.querySelector('.hi-lectura').replaceChildren(...seriesDe(bloque).map((s) => el('span', { class: 'hi-lectura-serie' },
    seriesDe(bloque).length > 1 ? el('b', {}, `${s.nombre}. `) : null, H.lectura(datos, s.serie, s.geo, t))));
  // Fechas clave y rupturas, numeradas como en el gráfico
  const fechas = fechasBloque(bloque);
  seccion.querySelector('.hi-fechas').replaceChildren(...fechas.map((f) => {
    const s = datos.series[f.serie];
    const valor = f.punto ? ` · ${H.textoValor(f.punto.v, f.serie, datos, t)}` : '';
    const periodo = H.textoPeriodo(f.punto ?? { anio: f.periodo[0], sub: f.periodo[1] }, s.frecuencia, t);
    return el('li', { class: f.tipo === 'ruptura' ? 'hi-fecha-ruptura' : null, value: f.numero },
      el('b', {}, `${periodo}${valor}`), `: ${f.tipo === 'ruptura' ? `${t('historico.fechas.ruptura')}. ` : ''}${t.idioma === 'en' ? f.texto_en : f.texto_es}`);
  }));
  // Fuente con la fecha de los datos
  const fuentes = [...new Set(bloque.series.map((serie) => datos.series[serie].fuente))];
  seccion.querySelector('.hi-fuente').textContent = t(`historico.bloques.${bloque.id}.fuente`, {
    version: fuentes.map((f) => datos.series[bloque.series.find((s) => datos.series[s].fuente === f)].version).join(', '),
  });
  pintarTabla(bloque, seccion.querySelector('.hi-tabla-marco'));
}

// Fechas de las series de España del bloque, numeradas en orden de tiempo
function fechasBloque(bloque) {
  const todas = bloque.series.flatMap((serie, i) => H.fechasDe(datos, serie, H.ESPANA).map((f) => ({ ...f, clase: CLASES[i] })));
  return todas.sort((a, b) => a.t - b.t).map((f, k) => ({ ...f, numero: k + 1 }));
}

// Lienzo de un gráfico en su caja: SVG con la rejilla, el eje vertical de `valores` (con `unidad`
// encima) y el eje de años común a toda la página. Se puede enfocar para leerlo con el teclado.
function lienzo(id, caja, valores, unidad, nombre) {
  const ancho = Math.round(Math.max(300, Math.min(900, caja.clientWidth || 600)));
  anchos.set(id, caja.clientWidth);
  const estrecho = ancho < 480;
  const alto = estrecho ? 230 : 280;
  const m = { izq: 48, der: 12, arr: 22, aba: 28 };
  const ejeY = H.escalaEje(valores);
  const x = H.escalaLineal(rango.desde, rango.hasta, m.izq, ancho - m.der);
  const y = H.escalaLineal(ejeY.min, ejeY.max, alto - m.aba, m.arr);
  const grafico = svg('svg', { viewBox: `0 0 ${ancho} ${alto}`, role: 'img', tabindex: 0,
    'aria-label': t('historico.grafico', { serie: nombre, desde: rango.desde, hasta: rango.hasta - 1 }) });
  const decimales = ejeY.paso < 1 ? 1 : 0;
  for (let v = ejeY.min; v <= ejeY.max + 1e-9; v += ejeY.paso) {
    grafico.append(svg('line', { class: Math.abs(v) < 1e-9 ? 'eje' : 'rejilla', x1: m.izq, x2: ancho - m.der, y1: y(v), y2: y(v) }));
    grafico.append(svg('text', { class: 'texto-eje', x: m.izq - 6, y: y(v) + 4, 'text-anchor': 'end' }, t.numero(v, decimales)));
  }
  grafico.append(svg('text', { class: 'texto-eje texto-unidad', x: m.izq - 6, y: m.arr - 10, 'text-anchor': 'end' }, unidad));
  for (const a of H.marcasAnios(rango.desde, rango.hasta - 1, estrecho ? 10 : 5)) {
    grafico.append(svg('line', { class: 'marca-eje', x1: x(a), x2: x(a), y1: alto - m.aba, y2: alto - m.aba + 4 }));
    grafico.append(svg('text', { class: 'texto-eje', x: x(a), y: alto - m.aba + 17, 'text-anchor': 'middle' }, String(a)));
  }
  return { grafico, ancho, alto, m, x, y };
}

// Líneas de las series, cortadas donde falta un periodo, y un punto en las cifras aisladas (entre
// dos periodos sin cifra), que una línea no dibuja.
function pintarLineas(g, series, clase = 'linea') {
  for (const s of series) {
    g.grafico.append(svg('path', { class: `${clase} ${s.clase}`, d: H.trazado(s.puntos, g.x, g.y) }));
    for (const p of H.aislados(s.puntos)) {
      g.grafico.append(svg('circle', { class: `punto-aislado ${s.clase}`, cx: g.x(p.t), cy: g.y(p.v), r: 2.5 }));
    }
  }
}

// Capa de lectura de un gráfico, con el ratón, el dedo o el teclado: guía vertical y globo con las
// cifras del periodo más cercano. `leer(t)` da { t, nodos } o null; `pasos`, los tiempos que
// recorren las flechas (Inicio y Fin, el primero y el último; Escape cierra el globo).
function capaLectura(g, leer, pasos) {
  const { grafico, ancho, alto, m, x } = g;
  const guia = svg('line', { class: 'guia', y1: m.arr, y2: alto - m.aba, visibility: 'hidden' });
  const zona = svg('rect', { class: 'zona', x: m.izq, y: m.arr, width: ancho - m.der - m.izq, height: alto - m.aba - m.arr });
  grafico.append(guia, zona);
  const globo = el('div', { class: 'hi-globo', hidden: true, 'aria-live': 'polite' });
  let paso = null;
  const ocultar = () => {
    guia.setAttribute('visibility', 'hidden');
    globo.hidden = true;
  };
  const mostrar = (tx) => {
    const r = leer(tx);
    if (!r) return ocultar();
    guia.setAttribute('x1', x(r.t));
    guia.setAttribute('x2', x(r.t));
    guia.setAttribute('visibility', 'visible');
    globo.replaceChildren(...r.nodos);
    globo.hidden = false;
    const caja = grafico.getBoundingClientRect();
    const izquierda = ((x(r.t) / ancho) * caja.width) + 12;
    globo.style.left = `${Math.max(4, Math.min(izquierda, caja.width - globo.offsetWidth - 4))}px`;
    globo.style.top = '4px';
  };
  const desdePuntero = (e) => {
    const r = grafico.getBoundingClientRect();
    mostrar(rango.desde + (((e.clientX - r.left) / r.width) * ancho - m.izq) / (ancho - m.der - m.izq) * (rango.hasta - rango.desde));
  };
  zona.addEventListener('pointermove', desdePuntero);
  zona.addEventListener('pointerdown', desdePuntero);
  zona.addEventListener('pointerleave', ocultar);
  grafico.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      paso = null;
      ocultar();
      return;
    }
    const ultimo = pasos.length - 1;
    const destino = { ArrowRight: paso === null ? ultimo : Math.min(ultimo, paso + 1),
      ArrowLeft: paso === null ? ultimo : Math.max(0, paso - 1), Home: 0, End: ultimo }[e.key];
    if (destino === undefined || ultimo < 0) return;
    e.preventDefault();
    paso = destino;
    mostrar(pasos[paso]);
  });
  // Con el teclado (no al pulsar con el ratón, que ya muestra su periodo), el último periodo
  grafico.addEventListener('focus', () => {
    if (!pasos.length || !grafico.matches(':focus-visible')) return;
    paso ??= pasos.length - 1;
    mostrar(pasos[paso]);
  });
  grafico.addEventListener('blur', ocultar);
  return globo;
}

function leyendaDe(series) {
  return series.length > 1 ? el('ul', { class: 'hi-leyenda' }, series.map((s) => el('li', {},
    el('span', { class: `hi-trazo ${s.clase}`, 'aria-hidden': 'true' }), s.nombre))) : null;
}

function pintarGrafico(bloque) {
  const seccion = document.querySelector(`[data-bloque="${bloque.id}"]`);
  const caja = seccion.querySelector('.hi-grafico');
  const series = seriesDe(bloque);
  const unidad = datos.series[bloque.series[0]].unidad;
  const g = lienzo(bloque.id, caja, series.flatMap((s) => s.puntos.map((p) => p.v)), t(`historico.ejes.${unidad}`),
    series.map((s) => s.nombre).join(', '));
  const { grafico, m, alto, x, y } = g;
  // Rupturas: línea vertical punteada
  const fechas = fechasBloque(bloque);
  for (const f of fechas.filter((x0) => x0.tipo === 'ruptura')) {
    grafico.append(svg('line', { class: 'ruptura-linea', x1: x(f.t), x2: x(f.t), y1: m.arr, y2: alto - m.aba }));
  }
  pintarLineas(g, series);
  // Fechas clave: punto en la línea y su número encima
  for (const f of fechas) {
    if (!f.punto) continue;
    const cx = x(f.punto.t);
    const cy = y(f.punto.v);
    grafico.append(svg('circle', { class: `hito ${f.clase}${f.tipo === 'ruptura' ? ' hito-ruptura' : ''}`, cx, cy, r: 5 }));
    const arriba = cy - 9 < m.arr ? cy + 18 : cy - 9;
    grafico.append(svg('text', { class: 'hito-numero', x: cx, y: arriba, 'text-anchor': 'middle' }, String(f.numero)));
  }
  // Lectura: las cifras del periodo con cifra más cercano de cada serie
  const leer = (tx) => {
    const filas = series.map((s) => ({ s, p: H.cercano(s.puntos, tx, 0.75) })).filter((f) => f.p);
    if (!filas.length) return null;
    return { t: filas[0].p.t, nodos: filas.map(({ s, p }) => el('p', {},
      el('span', { class: `hi-trazo ${s.clase}`, 'aria-hidden': 'true' }),
      el('b', {}, H.textoValor(p.v, s.serie, datos, t)), ` ${H.textoPeriodo(p, datos.series[s.serie].frecuencia, t)}`,
      series.length > 1 ? el('span', { class: 'hi-globo-nombre' }, s.nombre) : null)) };
  };
  const globo = capaLectura(g, leer, H.pasosTeclado(series.map((s) => s.puntos)));
  const leyenda = leyendaDe(series);
  caja.replaceChildren(grafico, globo, ...(leyenda ? [leyenda] : []));
}

// Tabla con todas las cifras: una fila por periodo y una columna por serie
function pintarTabla(bloque, marco) {
  const series = seriesDe(bloque);
  const porClave = new Map();
  series.forEach((s, i) => {
    for (const p of s.puntos) {
      if (!porClave.has(p.clave)) porClave.set(p.clave, { p, frecuencia: datos.series[s.serie].frecuencia, valores: [] });
      porClave.get(p.clave).valores[i] = p.v;
    }
  });
  const filas = [...porClave.values()].sort((a, b) => a.p.t - b.p.t);
  marco.replaceChildren(el('table', { class: 'hi-tabla' },
    el('thead', {}, el('tr', {}, el('th', { scope: 'col' }, t('historico.periodo_col')),
      series.map((s) => el('th', { scope: 'col' }, s.nombre)))),
    el('tbody', {}, filas.map((f) => el('tr', {}, el('th', { scope: 'row' }, H.textoPeriodo(f.p, f.frecuencia, t)),
      series.map((s, i) => el('td', {}, f.valores[i] === undefined ? '' : H.textoValor(f.valores[i], s.serie, datos, t))))))));
}

// --- La vivienda como problema (CIS) ------------------------------------------------------------

function seriesCis() {
  return H.CIS_SERIES.map((pregunta, i) => ({ pregunta, clase: CLASES[i], nombre: t(`historico.cis_${pregunta}`),
    puntos: H.puntosCis(cis, pregunta) ?? [] }));
}

const hayCis = (series) => series.some((s) => s.puntos.length);

// Bloque del CIS: gráfico, lectura, fuente y tabla; sin el JSON, solo el aviso de que no hay datos.
function pintarCis() {
  const seccion = document.querySelector(`[data-bloque="${H.CIS_ID}"]`);
  const series = seriesCis();
  const hay = hayCis(series);
  pintarGraficoCis();
  seccion.querySelector('.hi-lectura').replaceChildren(...(hay ? series.map((s) => el('span', { class: 'hi-lectura-serie' },
    el('b', {}, `${s.nombre}. `), H.lecturaCis(cis, s.pregunta, t))) : []));
  const fuente = seccion.querySelector('.hi-fuente');
  fuente.textContent = hay
    ? [t('historico.cis_fuente'), cis.actualizado ? t('historico.cis_fecha', { fecha: cis.actualizado }) : null].filter(Boolean).join(' ')
    : '';
  fuente.hidden = !hay;
  seccion.querySelector('.hi-plegable').hidden = !hay;
  if (hay) pintarTablaCis(series, seccion.querySelector('.hi-tabla-marco'));
}

function pintarGraficoCis() {
  const caja = document.querySelector(`[data-bloque="${H.CIS_ID}"] .hi-grafico`);
  const series = seriesCis();
  if (!hayCis(series)) {
    anchos.set(H.CIS_ID, caja.clientWidth);
    caja.replaceChildren(el('p', { class: 'hi-estado hi-sin-datos' }, t('historico.cis_sin_datos')));
    return;
  }
  const g = lienzo(H.CIS_ID, caja, series.flatMap((s) => s.puntos.map((p) => p.v)), t('historico.ejes.porcentaje'),
    series.map((s) => s.nombre).join(', '));
  pintarLineas(g, series, 'linea linea-meses');
  // Lectura: el mes más cercano, también si no tiene cifra («sin dato»), con su estudio y entrevistas
  const leer = (tx) => {
    const filas = series.map((s) => ({ s, p: H.mesCercano(s.puntos, tx) })).filter((f) => f.p);
    if (!filas.length) return null;
    const estudio = H.textoEstudio(filas.map((f) => f.p), t);
    return { t: filas[0].p.t, nodos: [
      el('p', { class: 'hi-globo-periodo' }, H.textoPeriodo(filas[0].p, 'mensual', t)),
      ...filas.map(({ s, p }) => el('p', {}, el('span', { class: `hi-trazo ${s.clase}`, 'aria-hidden': 'true' }),
        el('b', {}, H.textoCis(p.v, t)), el('span', { class: 'hi-globo-serie' }, s.nombre))),
      estudio ? el('p', { class: 'hi-globo-serie' }, estudio) : null,
    ].filter(Boolean) };
  };
  const globo = capaLectura(g, leer, H.pasosTeclado(series.map((s) => s.puntos), true));
  caja.replaceChildren(g.grafico, globo, ...[leyendaDe(series)].filter(Boolean));
}

// Tabla del CIS: un mes por fila (también los que no tienen cifra), las dos preguntas y, si el JSON
// los trae, el estudio y las entrevistas.
function pintarTablaCis(series, marco) {
  const porClave = new Map();
  series.forEach((s, i) => {
    for (const p of s.puntos) {
      if (!porClave.has(p.clave)) porClave.set(p.clave, { p, valores: [], estudio: null, n: null });
      const f = porClave.get(p.clave);
      f.valores[i] = p.v;
      f.estudio ??= p.estudio;
      f.n ??= p.n;
    }
  });
  const filas = [...porClave.values()].sort((a, b) => a.p.t - b.p.t);
  const conEstudio = filas.some((f) => f.estudio);
  const conN = filas.some((f) => Number.isFinite(f.n));
  marco.replaceChildren(el('table', { class: 'hi-tabla' },
    el('thead', {}, el('tr', {}, el('th', { scope: 'col' }, t('historico.periodo_col')),
      series.map((s) => el('th', { scope: 'col' }, s.nombre)),
      conEstudio ? el('th', { scope: 'col' }, t('historico.cis_estudio_col')) : null,
      conN ? el('th', { scope: 'col' }, t('historico.cis_entrevistas_col')) : null)),
    el('tbody', {}, filas.map((f) => el('tr', {}, el('th', { scope: 'row' }, H.textoPeriodo(f.p, 'mensual', t)),
      series.map((s, i) => el('td', {}, f.valores[i] === undefined ? '' : H.textoCis(f.valores[i], t))),
      conEstudio ? el('td', {}, f.estudio ?? '') : null,
      conN ? el('td', {}, Number.isFinite(f.n) ? t.numero(f.n) : '') : null)))));
}

iniciar();
