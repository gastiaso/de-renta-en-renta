// Máquina del tiempo (historico.html, F6): series de España desde 1987 (años de renta y esfuerzo
// teórico del Banco de España, tipos oficiales de referencia del mercado hipotecario, valor tasado
// del MIVAU, también por comunidad, y sueldo bruto medio por asalariado del INE), cada una en su
// gráfico, con el mismo eje de años, sus fechas clave y una lectura sin valoraciones. Sin mapa.
// Datos: datos/historico/historico.json (R/web_historico.R); lógica sin DOM en historico_datos.js.

import { cargarIdioma, traducirPagina } from './i18n.js';
import { ordenNatural } from './nombres.js';
import * as H from './historico_datos.js';

const $ = (id) => document.getElementById(id);
const SVG = 'http://www.w3.org/2000/svg';
const CLASES = ['serie-a', 'serie-b'];

let t;          // traductor del idioma activo
let datos;      // historico.json
let estado;     // { idioma, ccaa }
let rango;      // años del eje común
const anchos = new Map();   // ancho con que se dibujó cada gráfico

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
  estado = H.leerEstado(location.search, datos);
  rango = H.rangoAnios(datos);
  $('hi-estado').hidden = true;
  $('hi-contenido').hidden = false;
  $('hi-ccaa').addEventListener('change', (e) => {
    estado.ccaa = e.target.value || null;
    guardarEstado();
    pintarBloque(H.BLOQUES.find((b) => b.territorial));
  });
  pintarTodo();
  new ResizeObserver(() => {
    for (const b of H.BLOQUES) {
      const caja = document.querySelector(`[data-bloque="${b.id}"] .hi-grafico`);
      if (Math.abs(caja.clientWidth - (anchos.get(b.id) ?? 0)) > 24) pintarGrafico(b);
    }
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

// --- Pintado ------------------------------------------------------------------------------------

function pintarTodo() {
  pintarSelector();
  for (const b of H.BLOQUES) pintarBloque(b);
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

function pintarGrafico(bloque) {
  const seccion = document.querySelector(`[data-bloque="${bloque.id}"]`);
  const caja = seccion.querySelector('.hi-grafico');
  const series = seriesDe(bloque);
  const ancho = Math.round(Math.max(300, Math.min(900, caja.clientWidth || 600)));
  anchos.set(bloque.id, ancho);
  const estrecho = ancho < 480;
  const alto = estrecho ? 230 : 280;
  const m = { izq: 48, der: 12, arr: 22, aba: 28 };
  const unidad = datos.series[bloque.series[0]].unidad;
  const ejeY = H.escalaEje(series.flatMap((s) => s.puntos.map((p) => p.v)));
  const x = H.escalaLineal(rango.desde, rango.hasta, m.izq, ancho - m.der);
  const y = H.escalaLineal(ejeY.min, ejeY.max, alto - m.aba, m.arr);
  const grafico = svg('svg', { viewBox: `0 0 ${ancho} ${alto}`, role: 'img',
    'aria-label': t('historico.grafico', { serie: series.map((s) => s.nombre).join(', '), desde: rango.desde, hasta: rango.hasta - 1 }) });
  // Rejilla y ejes
  const decimales = ejeY.paso < 1 ? 1 : 0;
  for (let v = ejeY.min; v <= ejeY.max + 1e-9; v += ejeY.paso) {
    grafico.append(svg('line', { class: Math.abs(v) < 1e-9 ? 'eje' : 'rejilla', x1: m.izq, x2: ancho - m.der, y1: y(v), y2: y(v) }));
    grafico.append(svg('text', { class: 'texto-eje', x: m.izq - 6, y: y(v) + 4, 'text-anchor': 'end' }, t.numero(v, decimales)));
  }
  grafico.append(svg('text', { class: 'texto-eje texto-unidad', x: m.izq - 6, y: m.arr - 10, 'text-anchor': 'end' }, t(`historico.ejes.${unidad}`)));
  for (const a of H.marcasAnios(rango.desde, rango.hasta - 1, estrecho ? 10 : 5)) {
    grafico.append(svg('line', { class: 'marca-eje', x1: x(a), x2: x(a), y1: alto - m.aba, y2: alto - m.aba + 4 }));
    grafico.append(svg('text', { class: 'texto-eje', x: x(a), y: alto - m.aba + 17, 'text-anchor': 'middle' }, String(a)));
  }
  // Rupturas: línea vertical punteada
  const fechas = fechasBloque(bloque);
  for (const f of fechas.filter((x0) => x0.tipo === 'ruptura')) {
    grafico.append(svg('line', { class: 'ruptura-linea', x1: x(f.t), x2: x(f.t), y1: m.arr, y2: alto - m.aba }));
  }
  // Líneas
  for (const s of series) {
    grafico.append(svg('path', { class: `linea ${s.clase}`, d: H.trazado(s.puntos, x, y) }));
  }
  // Fechas clave: punto en la línea y su número encima
  for (const f of fechas) {
    if (!f.punto) continue;
    const cx = x(f.punto.t);
    const cy = y(f.punto.v);
    grafico.append(svg('circle', { class: `hito ${f.clase}${f.tipo === 'ruptura' ? ' hito-ruptura' : ''}`, cx, cy, r: 5 }));
    const arriba = cy - 9 < m.arr ? cy + 18 : cy - 9;
    grafico.append(svg('text', { class: 'hito-numero', x: cx, y: arriba, 'text-anchor': 'middle' }, String(f.numero)));
  }
  // Capa de lectura: guía vertical y globo con las cifras del periodo más cercano
  const guia = svg('line', { class: 'guia', y1: m.arr, y2: alto - m.aba, visibility: 'hidden' });
  const zona = svg('rect', { class: 'zona', x: m.izq, y: m.arr, width: ancho - m.der - m.izq, height: alto - m.aba - m.arr });
  grafico.append(guia, zona);
  const globo = el('div', { class: 'hi-globo', hidden: true });
  const mover = (e) => {
    const r = grafico.getBoundingClientRect();
    const tx = rango.desde + (((e.clientX - r.left) / r.width) * ancho - m.izq) / (ancho - m.der - m.izq) * (rango.hasta - rango.desde);
    const filas = series.map((s) => ({ s, p: H.cercano(s.puntos, tx, 0.75) })).filter((f) => f.p);
    if (!filas.length) {
      guia.setAttribute('visibility', 'hidden');
      globo.hidden = true;
      return;
    }
    const ref = filas[0].p;
    guia.setAttribute('x1', x(ref.t));
    guia.setAttribute('x2', x(ref.t));
    guia.setAttribute('visibility', 'visible');
    globo.replaceChildren(...filas.map(({ s, p }) => el('p', {},
      el('span', { class: `hi-trazo ${s.clase}`, 'aria-hidden': 'true' }),
      el('b', {}, H.textoValor(p.v, s.serie, datos, t)), ` ${H.textoPeriodo(p, datos.series[s.serie].frecuencia, t)}`,
      series.length > 1 ? el('span', { class: 'hi-globo-nombre' }, s.nombre) : null)));
    globo.hidden = false;
    const izquierda = ((x(ref.t) / ancho) * r.width) + 12;
    globo.style.left = `${Math.max(4, Math.min(izquierda, r.width - globo.offsetWidth - 4))}px`;
    globo.style.top = '4px';
  };
  zona.addEventListener('pointermove', mover);
  zona.addEventListener('pointerdown', mover);
  zona.addEventListener('pointerleave', () => {
    guia.setAttribute('visibility', 'hidden');
    globo.hidden = true;
  });
  const leyenda = series.length > 1 ? el('ul', { class: 'hi-leyenda' }, series.map((s) => el('li', {},
    el('span', { class: `hi-trazo ${s.clase}`, 'aria-hidden': 'true' }), s.nombre))) : null;
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

iniciar();
