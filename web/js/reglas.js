// «Reglas del juego» (reglas.html, tarea 64; docs/especificacion_reglas_del_juego.md): resúmenes de las
// normas estatales del alquiler y la compra de vivienda, cada uno con su norma y artículo enlazados al
// BOE consolidado, su estado, la fecha del texto consultado y su relación con el atlas. Registro
// impersonal, sin valoraciones ni recomendaciones; el texto oficial es el del BOE.
// Datos: datos/reglas.json (R/reglas.R); lógica sin DOM en reglas_datos.js. En local, los resúmenes en
// borrador se ven con su marca; en el sitio publicado, solo su título y «en revisión».

import { cargarIdioma, traducirPagina } from './i18n.js';
import { fechaLarga } from './transparencia.js';
import * as R from './reglas_datos.js';

const $ = (id) => document.getElementById(id);

let t;          // traductor del idioma activo
let datos;      // reglas.json
let estado;     // { idioma }

function el(etiqueta, atributos = {}, ...hijos) {
  const e = document.createElement(etiqueta);
  for (const [k, v] of Object.entries(atributos)) {
    if (v === null || v === undefined || v === false) continue;
    if (k === 'class') e.className = v;
    else e.setAttribute(k, v === true ? '' : String(v));
  }
  for (const h of hijos.flat()) {
    if (h === null || h === undefined || h === false) continue;
    e.append(h instanceof Node ? h : document.createTextNode(String(h)));
  }
  return e;
}

const fecha = (x) => fechaLarga(x, estado.idioma) ?? x ?? '';

// Párrafo con sus enlaces (solo al BOE o a páginas del atlas; reglas_datos.js)
function parrafo(etiqueta, texto, clase = null) {
  const p = el(etiqueta, { class: clase });
  for (const trozo of R.trozosTexto(texto, estado.idioma)) {
    if (trozo.href) {
      const externo = trozo.href.startsWith('https://');
      p.append(el('a', { href: trozo.href, rel: externo ? 'noopener' : null, hreflang: externo ? 'es' : null }, trozo.texto));
    } else {
      p.append(trozo.texto);
    }
  }
  return p;
}

// --- Arranque -------------------------------------------------------------------------------------

async function iniciar() {
  estado = R.leerEstado(location.search);
  t = await cargarIdioma(estado.idioma);
  traducir();
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.addEventListener('click', () => cambiarIdioma(boton.dataset.idioma));
  }
  try {
    const respuesta = await fetch(R.RUTA_DATOS);
    if (!respuesta.ok) throw new Error(`${R.RUTA_DATOS}: ${respuesta.status}`);
    datos = await respuesta.json();
  } catch (error) {
    console.error(error);
    const aviso = $('rg-estado');
    aviso.removeAttribute('data-i18n');
    aviso.textContent = t('reglas.error_carga');
    aviso.classList.add('rg-estado-error');
    return;
  }
  $('rg-estado').hidden = true;
  $('rg-contenido').hidden = false;
  pintar();
  // Un ancla del enlace (las casillas de la portada, la ficha del indicador 20) apunta a contenido que
  // no existía mientras cargaban los datos: se baja hasta ella ahora.
  const marca = location.hash.length > 1 ? document.getElementById(decodeURIComponent(location.hash.slice(1))) : null;
  if (marca) marca.scrollIntoView();
}

function traducir() {
  traducirPagina(t);
  document.title = t('reglas.titulo_pagina');
  document.querySelector('meta[name="description"]')?.setAttribute('content', t('reglas.descripcion'));
  for (const boton of document.querySelectorAll('[data-idioma]')) {
    boton.setAttribute('aria-pressed', String(boton.dataset.idioma === estado.idioma));
  }
  // Enlaces a las otras páginas con el idioma activo
  for (const enlace of document.querySelectorAll('[data-enlace]')) {
    enlace.href = `${enlace.dataset.pagina ?? './'}${R.consulta(estado)}${enlace.dataset.enlace}`;
  }
  const propio = document.querySelector('.navegacion a[aria-current="page"]');
  if (propio) propio.href = `reglas.html${R.consulta(estado)}`;
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  traducir();
  history.replaceState(null, '', `${location.pathname}${R.consulta(estado)}${location.hash}`);
  if (datos) pintar();
}

// --- Contenido ------------------------------------------------------------------------------------

function pintar() {
  const lista = R.resumenes(datos);
  // Aviso de la vista local con borradores (en el sitio publicado no hay ninguno con texto)
  const n = R.borradores(datos);
  const avisoBorrador = $('rg-aviso-borrador');
  avisoBorrador.hidden = n === 0;
  avisoBorrador.textContent = n ? t('reglas.aviso_borradores', { n }) : '';
  // Entradilla: con todo en revisión, sin prometer los enlaces al BOE que aún no salen
  const entradilla = document.querySelector('.rg-entradilla');
  if (entradilla) entradilla.textContent = t(R.todosEnRevision(datos) ? 'reglas.entradilla_revision' : 'reglas.entradilla');
  // Índice
  $('rg-indice').replaceChildren(...lista.map((r) => el('a', { href: `#${r.ancla ?? R.ancla(r.id)}` }, R.enIdioma(r.titulo, estado.idioma))));
  // Resúmenes
  $('rg-resumenes').replaceChildren(...lista.map(seccion));
  // Pie: fecha de consulta del BOE
  const consultado = R.fechaConsulta(datos);
  $('rg-pie-boe').textContent = t('reglas.pie.boe', { fecha: consultado ? fecha(consultado) : '—' });
}

function seccion(r) {
  const id = r.ancla ?? R.ancla(r.id);
  const idioma = estado.idioma;
  const borrador = R.esBorrador(r) && !R.enRevision(r);
  const s = el('section', { id, class: `tarjeta rg-regla${borrador ? ' rg-borrador' : ''}`, 'aria-labelledby': `${id}-titulo` });
  s.append(el('h2', { id: `${id}-titulo`, class: 'rg-h2' }, R.enIdioma(r.titulo, idioma)));
  if (borrador) s.append(el('p', { class: 'rg-marca-borrador' }, t('reglas.borrador')));
  s.append(el('p', { class: 'rg-linea-estado' }, R.lineasEstado(r, datos, idioma, fecha).map((l) => t(l.clave, l.valores)).join(' ')));
  if (R.enRevision(r)) return s;

  for (const clave of R.SECCIONES) {
    const parrafos = R.enIdioma(r[clave], idioma) ?? [];
    if (!parrafos.length) continue;
    const bloque = el('div', { class: `rg-bloque rg-${clave.replaceAll('_', '-')}` }, el('h3', { class: 'rg-h3' }, t(`reglas.secciones.${clave}`)));
    if (clave === 'que_dice' || clave === 'cambios') {
      bloque.append(el('ul', { class: 'rg-lista' }, parrafos.map((p) => parrafo('li', p))));
    } else {
      for (const p of parrafos) bloque.append(parrafo('p', p));
    }
    if (clave === 'en_el_atlas' && r.id === 'zonas_tensionadas') bloque.append(declaraciones());
    s.append(bloque);
  }

  // Normas citadas, con su enlace al BOE consolidado (o al diario, si el BOE no la consolida)
  const normas = R.normasDe(r, datos);
  const bloqueNormas = el('div', { class: 'rg-bloque rg-normas' }, el('h3', { class: 'rg-h3' }, t('reglas.secciones.normas')));
  bloqueNormas.append(el('ul', { class: 'rg-lista rg-lista-normas' }, normas.map((n) => el('li', {},
    el('a', { href: n.url, rel: 'noopener', hreflang: 'es' }, R.etiquetaNorma(n, idioma)),
    n.ficha ? el('span', { class: 'rg-norma-nombre' }, ` · ${R.enIdioma(n.ficha.nombre, idioma)}`) : null))));
  s.append(bloqueNormas);

  // Fecha del texto consultado y de la revisión
  const pie = [t('reglas.consultado', { fecha: fecha(r.texto_consultado) })];
  pie.push(borrador ? t('reglas.sin_revisar') : t('reglas.revisado', { fecha: fecha(r.revisado) }));
  s.append(el('p', { class: 'nota rg-consulta' }, pie.join(' ')));
  return s;
}

// Declaraciones de zona tensionada de las comunidades autónomas (inventario/zonas_tensionadas.csv)
function declaraciones() {
  const grupos = datos.declaraciones ?? [];
  if (!grupos.length) return null;
  const d = el('details', { class: 'rg-plegable' }, el('summary', {}, t('reglas.declaraciones')));
  for (const g of grupos) {
    d.append(el('h4', { class: 'rg-h4' }, g.nombre),
      el('ul', { class: 'rg-lista' }, g.declaraciones.map((x) => el('li', {},
        x.url ? el('a', { href: x.url, rel: 'noopener', hreflang: 'es' }, x.texto) : x.texto))));
  }
  return d;
}

iniciar();
