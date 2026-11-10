// Portada (index.html; docs/especificacion_portada.md): el tablero completo. Las casillas y los
// enlaces están en el HTML (se ven sin JavaScript); aquí, el idioma, la lectura literal de las
// familias (tarea 34), las fichas que tienen datos, las cartas (datos/portada.json, cifras reales
// del pipeline), «Tu sueldo» (abre el mapa en «¿te llega?» con el sueldo tras «#», como
// «Compartir»), el buscador, «Tira el dado» y el pie.

import { cargarIdioma, traducirPagina } from './i18n.js';
import { leerEstado, fragmentoSueldo } from './estado.js';
import { cargarManifiesto, cargarSecciones, cargarTerritorios, cargarPerfiles, cargarValores, periodosDe } from './datos.js';
import { crearBuscador, formasDeNombre } from './buscador.js';
import { ordenNatural } from './nombres.js';
import { FICHAS_PERFIL } from './sueldo.js';
import { FAMILIAS_ALQUILER, FAMILIAS_PROXIMAMENTE, textoFamilia } from './familias.js';

const $ = (id) => document.getElementById(id);
const estado = { idioma: leerEstado(globalThis.location?.search ?? '').idioma ?? 'es' };
const MAPA_POR_DEFECTO = 'sueldo_necesario';
const SUELDO_MAXIMO = 100000;   // como ingresoPeon() (sueldo.js)

let t;
let m = null;          // manifiesto (o null si no carga)
let portada = null;    // datos/portada.json (o null)
let perfiles = null;
let version = null;    // descargas/version.json (o null)

// --- Utilidades ----------------------------------------------------------------------------

// Enlace interno con el idioma: mapa.html y sobrecarga.html llevan «idioma=en» en la consulta.
export function conIdioma(ruta, idioma) {
  if (idioma !== 'en') return ruta;
  const [sinAncla, ...ancla] = ruta.split('#');
  const unir = sinAncla.includes('?') ? '&' : '?';
  return `${sinAncla}${unir}idioma=en${ancla.length ? `#${ancla.join('#')}` : ''}`;
}

// Sueldo escrito («1500», «1.500», «1500,50», «1 500 €») → número, o null si no vale.
export function leerSueldo(texto) {
  let s = String(texto ?? '').replace(/[\s €]/g, '');
  if (/^\d{1,3}(\.\d{3})+(,\d+)?$/.test(s)) s = s.replace(/\./g, '').replace(',', '.');
  else s = s.replace(',', '.');
  if (!/^\d+(\.\d+)?$/.test(s)) return null;
  const x = Number(s);
  return Number.isFinite(x) && x > 0 && x <= SUELDO_MAXIMO ? x : null;
}

// Enlace del botón «¿Te llega?»: el mapa con «Tu ficha» y el sueldo en el fragmento (nunca en la
// consulta), en 12 pagas, igual que «Compartir».
export function enlaceTeLlega(neto, idioma) {
  return `${conIdioma('mapa.html?ficha=peon', idioma)}${fragmentoSueldo({ neto, pagas: 12 })}`;
}

// Texto con marcas «{nombre}» en un elemento: el texto tal cual y cada cifra en su <span>.
function rellenar(el, plantilla, valores) {
  el.replaceChildren(...plantilla.split(/\{(\w+)\}/).map((parte, i) => {
    if (i % 2 === 0) return document.createTextNode(parte);
    const span = document.createElement('span');
    span.className = 'carta-cifra';
    span.textContent = valores[parte] ?? `{${parte}}`;
    return span;
  }));
}

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

const pedirJson = async (ruta) => {
  const r = await fetch(ruta, { cache: 'no-cache' });
  if (!r.ok) throw new Error(`${ruta}: ${r.status}`);
  return r.json();
};

// --- Cartas --------------------------------------------------------------------------------

const hay = (...xs) => xs.every((x) => x !== null && x !== undefined && x !== '' && (typeof x !== 'number' || Number.isFinite(x)));
const nombreFuente = (id) => (t.existe(`fuentes.${id}`) ? t(`fuentes.${id}`) : id);
const pct = (x) => t.porcentaje(x / 100);

// Cartas con todos sus términos (si falta uno, la carta no se muestra: nunca «—» en una carta).
export function cartasDe(datos) {
  const c = datos?.cartas ?? {};
  const cartas = [];
  const s = c.sueldo;
  if (s && hay(s.anio, s.mediana, s.p10, s.p90, s.superficie_m2, s.umbral)) {
    cartas.push({
      id: 'sueldo', anio: s.anio, fuentes: s.fuentes ?? [],
      valores: { anio: s.anio, mediana: ['numero', s.mediana], p10: ['numero', s.p10], p90: ['numero', s.p90], superficie: ['numero', s.superficie_m2], umbral: ['pct', s.umbral] },
      enlace: `mapa.html?mapa=${s.mapa ?? MAPA_POR_DEFECTO}&anio=${s.anio}`,
    });
  }
  const b = c.smi;
  if (b && hay(b.anio, b.neto_mensual, b.pct_30, b.pct_40, b.superficie_m2)) {
    cartas.push({
      id: 'smi', anio: b.anio, fuentes: b.fuentes ?? [],
      valores: { anio: b.anio, neto: ['numero', b.neto_mensual], pct30: ['pct', b.pct_30], pct40: ['pct', b.pct_40], superficie: ['numero', b.superficie_m2] },
      enlace: `mapa.html?ficha=${b.ficha ?? 'tartera'}&anio=${b.anio}`,
    });
  }
  const o = c.sobrecarga;
  if (o && hay(o.anio, o.total, o.alquiler_mercado)) {
    cartas.push({
      id: 'sobrecarga', anio: o.anio, fuentes: o.fuentes ?? [],
      valores: { anio: o.anio, total: ['pct', o.total], mercado: ['pct', o.alquiler_mercado] },
      enlace: 'sobrecarga.html',
    });
  }
  return cartas;
}

function pintarCartas() {
  const seccion = $('portada-cartas');
  const cartas = cartasDe(portada);
  seccion.hidden = !cartas.length;
  $('portada-cartas-lista').replaceChildren(...cartas.map((carta) => {
    const valores = Object.fromEntries(Object.entries(carta.valores).map(([k, v]) => {
      if (!Array.isArray(v)) return [k, String(v)];
      return [k, v[0] === 'pct' ? pct(v[1]) : t.numero(v[1])];
    }));
    const art = crear('article', `carta carta-${carta.id}`);
    art.dataset.carta = carta.id;
    art.append(crear('h3', 'carta-titulo cabecera-carta', t(`portada.cartas.${carta.id}.titulo`)));
    const p = crear('p', 'carta-texto');
    rellenar(p, t(`portada.cartas.${carta.id}.texto`), valores);
    art.append(p);
    const fuentes = carta.fuentes.map(nombreFuente).join('; ');
    art.append(crear('p', 'carta-fuente', t('portada.cartas.fuente', { fuentes, anio: carta.anio })));
    const a = crear('a', 'carta-enlace', t(`portada.cartas.${carta.id}.enlace`));
    a.href = conIdioma(carta.enlace, t.idioma);
    art.append(a);
    return art;
  }));
}

// --- Familias, fichas, dado y pie -----------------------------------------------------------

// Bajo las familias del centro, su lectura literal con los mismos textos que la leyenda del mapa
// («Quedarse · quien ya vive de alquiler»). Si falta alguno, la lista no se ve.
// Las familias aún sin mapa llevan detrás «(próximamente)».
export const lecturasFamilias = (t) => FAMILIAS_ALQUILER.map((f) => {
  const texto = textoFamilia(t, f);
  return texto && FAMILIAS_PROXIMAMENTE.includes(f) ? `${texto} (${t('portada.proximamente')})` : texto;
});

function pintarLecturas() {
  const lista = $('portada-lecturas');
  const textos = lecturasFamilias(t);
  lista.hidden = textos.some((x) => !x);
  if (!lista.hidden) lista.replaceChildren(...textos.map((x) => crear('li', null, x)));
}

// Las fichas de perfil sin ingreso en perfiles.json quedan desactivadas y rotuladas «próximamente».
function pintarFichas() {
  for (const ficha of FICHAS_PERFIL) {
    const a = document.querySelector(`.ficha-enlace[data-ficha="${ficha}"]`);
    if (!a || !perfiles) continue;
    const desc = a.querySelector('.ficha-desc');
    if (perfiles[ficha]) {
      if (a.dataset.hrefEs) a.href = t.idioma === 'en' ? a.dataset.hrefEn : a.dataset.hrefEs;
      a.removeAttribute('aria-disabled');
      continue;
    }
    a.removeAttribute('href');
    a.setAttribute('aria-disabled', 'true');
    a.title = t('portada.proximamente');
    if (desc) desc.textContent = t('portada.proximamente');
  }
}

// Serie y periodo del dado: la base del mapa por defecto (alquiler por m² de la vivienda colectiva),
// en su último periodo.
const serieDado = () => {
  const def = m?.mapas?.[MAPA_POR_DEFECTO] ?? (m ? Object.values(m.mapas)[0] : null);
  if (!def) return null;
  const periodo = periodosDe(m.indicadores[def.base]).at(-1);
  return periodo === undefined ? null : { serie: def.base, periodo };
};

function pintarNotaDado() {
  const d = serieDado();
  $('portada-dado-nota').textContent = d ? t('portada.dado_nota', { anio: t.periodo(d.periodo) }) : '';
}

// Sección al azar con «dato» en el último periodo del mapa por defecto.
export function seccionAlAzar(secciones, estados, dato, azar = Math.random) {
  const con = [];
  for (let i = 0; i < secciones.length; i++) if (estados[i] === dato) con.push(i);
  return con.length ? secciones[con[Math.floor(azar() * con.length)]] : null;
}

async function tirarDado() {
  const boton = $('portada-dado');
  const d = serieDado();
  if (!d || boton.disabled) return;
  boton.disabled = true;
  try {
    const [secciones, valores] = await Promise.all([cargarSecciones(m), cargarValores(m, d.serie, 'sc', d.periodo)]);
    const codigo = seccionAlAzar(secciones, valores.estados, m.codificacion.estados.indexOf('dato'));
    if (!codigo) throw new Error('Sin secciones con dato');
    const ir = () => { location.href = conIdioma(`mapa.html?seccion=${codigo}`, t.idioma); };
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return ir();
    boton.classList.add('tirando');
    setTimeout(ir, 450);
  } catch (error) {
    console.error(error);
    boton.disabled = false;
  }
}

// Fecha de los datos («2026-11-09T13:14:33+0100» o «2026-11-09») en largo.
function fechaLarga(texto) {
  const r = /^(\d{4})-(\d{2})-(\d{2})/.exec(texto ?? '');
  if (!r) return null;
  const d = new Date(Date.UTC(Number(r[1]), Number(r[2]) - 1, Number(r[3])));
  return new Intl.DateTimeFormat(t.idioma === 'en' ? 'en-GB' : 'es-ES', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(d);
}

// Pie: las fuentes y la fecha de los datos publicados (descargas/version.json, del release) o, sin
// él, las del manifiesto.
function pintarPie() {
  const ids = version?.fuentes?.map((f) => f.fuente)
    ?? Object.values(m?.indicadores ?? {}).map((d) => d.fuente);
  const fuentes = [...new Set((ids ?? []).filter((id) => id && id !== 'calculo_propio'))].map(nombreFuente);
  const pf = $('portada-pie-fuentes');
  pf.hidden = !fuentes.length;
  pf.textContent = fuentes.length ? t('portada.pie.fuentes', { fuentes: fuentes.join('; ') }) : '';
  const fecha = fechaLarga(version?.fecha ?? m?.generado);
  const pfe = $('portada-pie-fecha');
  pfe.hidden = !fecha;
  pfe.textContent = fecha ? t('portada.pie.fecha', { fecha }) : '';
}

// --- Idioma y arranque ----------------------------------------------------------------------

function pintar() {
  traducirPagina(t);
  document.title = t('portada.titulo_pagina');
  document.querySelector('meta[name="description"]')?.setAttribute('content', t('portada.descripcion'));
  for (const b of document.querySelectorAll('[data-idioma]')) b.setAttribute('aria-pressed', String(b.dataset.idioma === t.idioma));
  pintarLecturas();
  pintarFichas();
  pintarCartas();
  pintarNotaDado();
  pintarPie();
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  history.replaceState(null, '', `${location.pathname}${idioma === 'en' ? '?idioma=en' : ''}`);
  pintar();
}

function prepararSueldo() {
  const form = $('portada-sueldo');
  const entrada = $('portada-neto');
  const error = $('portada-sueldo-error');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const neto = leerSueldo(entrada.value);
    if (!neto) {
      error.textContent = t('portada.sueldo_error');
      error.hidden = false;
      entrada.setAttribute('aria-invalid', 'true');
      entrada.focus();
      return;
    }
    location.href = enlaceTeLlega(neto, t.idioma);
  });
  entrada.addEventListener('input', () => {
    error.hidden = true;
    entrada.removeAttribute('aria-invalid');
  });
}

function prepararBuscador(territorios, secciones) {
  let fuentes = null;
  crearBuscador({
    entrada: $('buscador-entrada'),
    lista: $('buscador-lista'),
    obtenerFuentes: async () => {
      fuentes ??= {
        municipios: Object.entries(territorios.municipio ?? {}).map(([codigo, nombre]) => [codigo, nombre, formasDeNombre(nombre)]),
        secciones: await secciones(),
      };
      return fuentes;
    },
    etiqueta: (o) => (o.tipo === 'municipio' ? `${ordenNatural(o.nombre)} (${o.codigo})` : t('interfaz.ficha.seccion', { codigo: o.codigo })),
    alElegir: (o) => {
      const destino = o.tipo === 'municipio' ? `mapa.html?territorio=municipio:${o.codigo}` : `mapa.html?seccion=${o.codigo}`;
      location.href = conIdioma(destino, t.idioma);
    },
  });
}

async function iniciar() {
  t = await cargarIdioma(estado.idioma);
  pintar();
  for (const b of document.querySelectorAll('[data-idioma]')) b.addEventListener('click', () => cambiarIdioma(b.dataset.idioma));
  prepararSueldo();
  try {
    m = await cargarManifiesto();
  } catch (error) {
    console.error(error);
    return;
  }
  $('aviso-ejemplo').hidden = !m.ejemplo;
  const [territorios, perf, port, ver] = await Promise.all([
    cargarTerritorios(m).catch(() => ({})),
    cargarPerfiles(m).catch(() => null),
    m.ejemplo ? null : pedirJson('datos/portada.json').catch(() => null),
    m.ejemplo ? null : pedirJson('descargas/version.json').catch(() => null),
  ]);
  perfiles = perf;
  portada = port;
  version = ver;
  prepararBuscador(territorios, () => cargarSecciones(m));
  $('portada-dado').addEventListener('click', tirarDado);
  for (const el of document.querySelectorAll('[data-js]')) el.hidden = false;
  pintar();
}

if (typeof document !== 'undefined' && document.getElementById('portada-sueldo')) iniciar();
