// Portada (index.html; docs/especificacion_portada.md): el tablero completo. Las casillas y los
// enlaces están en el HTML (se ven sin JavaScript); aquí, el idioma, las fichas que tienen datos,
// las historias (datos/historias.json), las cartas (datos/portada.json, cifras reales del
// pipeline), la cifra del salario mínimo bajo la pregunta (la de su carta; sin ella, el lema),
// «Tu sueldo» (al escribir, la cuenta en la propia portada; el botón abre el mapa en «¿te llega?»
// con lo escrito tras «#», como «Compartir»), el buscador, «Tira el dado» y el pie.

import { cargarIdioma, traducirPagina } from './i18n.js';
import { leerEstado, fragmentoSueldo } from './estado.js';
import { cargarManifiesto, cargarSecciones, cargarTerritorios, cargarPerfiles, cargarValores, periodosDe, periodoPara, serieDeTipologia } from './datos.js';
import { crearBuscador, formasDeNombre, etiquetaMunicipio } from './buscador.js';
import { FICHAS_PERFIL, leerSueldo, calculoLlega, resumenLlegaReal, superficieDe, umbralDe } from './sueldo.js';
import { FAMILIAS_PROXIMAMENTE, textoFamilia } from './familias.js';
import { fechaLarga, lineaTransparencia } from './transparencia.js';
import { cargarHistorias, textoEn } from './historias.js';

const $ = (id) => document.getElementById(id);
const estado = { idioma: leerEstado(globalThis.location?.search ?? '').idioma ?? 'es' };
const MAPA_POR_DEFECTO = 'sueldo_necesario';

let t;
let m = null;          // manifiesto (o null si no carga)
let portada = null;    // datos/portada.json (o null)
let perfiles = null;
let version = null;    // descargas/version.json (o null)
let historias = null;  // datos/historias.json (o null)

// --- Utilidades ----------------------------------------------------------------------------

// Enlace interno con el idioma: mapa.html y sobrecarga.html llevan «idioma=en» en la consulta.
export function conIdioma(ruta, idioma) {
  if (idioma !== 'en') return ruta;
  const [sinAncla, ...ancla] = ruta.split('#');
  const unir = sinAncla.includes('?') ? '&' : '?';
  return `${sinAncla}${unir}idioma=en${ancla.length ? `#${ancla.join('#')}` : ''}`;
}

// Sueldo escrito → número, o null si no vale: el mismo lector que «Tu sueldo» del mapa (sueldo.js).
export { leerSueldo };

// Enlace del botón «¿Te llega?»: el mapa con «Tu ficha» y el sueldo en el fragmento (nunca en la
// consulta), en 12 pagas, igual que «Compartir».
export function enlaceTeLlega(neto, idioma) {
  return `${conIdioma('mapa.html?ficha=peon', idioma)}${fragmentoSueldo({ neto, pagas: 12 })}`;
}

// Texto con marcas «{nombre}» en un elemento: el texto tal cual y cada cifra en su <span>. Con
// `resaltar`, solo esas marcas van en <span>; las demás, como texto.
function rellenar(el, plantilla, valores, resaltar = null) {
  el.replaceChildren(...plantilla.split(/\{(\w+)\}/).map((parte, i) => {
    if (i % 2 === 0) return document.createTextNode(parte);
    if (resaltar && !resaltar.includes(parte)) return document.createTextNode(valores[parte] ?? `{${parte}}`);
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
  // Tarea 40 (decisión 4): el sueldo con el alquiler real y, al lado, el mínimo de 50 m²; el salario
  // mínimo con 50 m² y, al lado, con el alquiler real. Sin la cifra de al lado, la carta no sale.
  const s = c.sueldo;
  if (s && hay(s.anio, s.mediana, s.p10, s.p90, s.minimo, s.superficie_m2, s.umbral)) {
    cartas.push({
      id: 'sueldo', anio: s.anio, fuentes: s.fuentes ?? [],
      valores: {
        anio: s.anio, mediana: ['numero', s.mediana], p10: ['numero', s.p10], p90: ['numero', s.p90], minimo: ['numero', s.minimo],
        superficie: ['numero', s.superficie_m2], umbral: ['pct', s.umbral],
      },
      enlace: `mapa.html?mapa=${s.mapa ?? MAPA_POR_DEFECTO}&anio=${s.anio}`,
    });
  }
  const b = c.smi;
  if (b && hay(b.anio, b.neto_mensual, b.pct_30, b.pct_40, b.pct_30_real, b.pct_40_real, b.superficie_m2)) {
    cartas.push({
      id: 'smi', anio: b.anio, fuentes: b.fuentes ?? [],
      valores: {
        anio: b.anio, neto: ['numero', b.neto_mensual], pct30: ['pct', b.pct_30], pct40: ['pct', b.pct_40],
        pct30real: ['pct', b.pct_30_real], pct40real: ['pct', b.pct_40_real], superficie: ['numero', b.superficie_m2],
      },
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

// Tarea 52: cartas de la familia «entrar» (el sueldo para entrar y la brecha entre entrar y quedarse)
// mientras la familia sale «próximamente» (familias.js): qué medirán, su familia y «próximamente»,
// sin cifras ni enlace (la oferta de Idealista no se publica sin su autorización; decisiones 17–19).
// Si falta alguno de sus textos, esa carta no sale.
export const CARTAS_ENTRAR = ['sueldo_entrar', 'brecha'];
export function cartasProximamente(t) {
  if (!FAMILIAS_PROXIMAMENTE.includes('entrar')) return [];
  const familia = textoFamilia(t, 'entrar');
  if (!familia) return [];
  return CARTAS_ENTRAR.filter((id) => t.existe(`portada.cartas.${id}.titulo`) && t.existe(`portada.cartas.${id}.texto`))
    .map((id) => ({ id, familia, titulo: t(`portada.cartas.${id}.titulo`), texto: t(`portada.cartas.${id}.texto`) }));
}

function cartaProximamente({ id, familia, titulo, texto }) {
  const art = crear('article', `carta carta-${id} carta-proximamente`);
  art.setAttribute('data-carta', id);
  art.setAttribute('data-proximamente', 'true');
  art.append(crear('h3', 'carta-titulo cabecera-carta', titulo), crear('p', 'carta-texto', texto),
    crear('p', 'carta-fuente', familia), crear('p', 'carta-pronto', t('portada.proximamente')));
  return art;
}

function pintarCartas() {
  const seccion = $('portada-cartas');
  const cartas = cartasDe(portada);
  const pronto = cartasProximamente(t);
  seccion.hidden = !cartas.length && !pronto.length;
  // La del sueldo necesario, primero; detrás, las de «entrar» (su contrapunto) y las demás
  const reales = cartas.map((carta) => {
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
  });
  const n = cartas.findIndex((c) => c.id === 'sueldo') + 1;
  $('portada-cartas-lista').replaceChildren(...reales.slice(0, n), ...pronto.map(cartaProximamente), ...reales.slice(n));
}

// --- La cifra del centro ----------------------------------------------------------------------

// Decisión del autor (12-nov-2026): bajo la pregunta, en lugar del lema, la cifra de la carta del
// salario mínimo con el alquiler mensual mediano real de cada sección (`pct_30_real`): «9 de cada
// 10» si el porcentaje queda a menos de 2,5 puntos de una decena (de 10 a 90) y, si no, el
// porcentaje. Sin el dato, null (se queda el lema).
export function cifraCentro(datos) {
  const b = datos?.cartas?.smi;
  if (!b || !hay(b.anio, b.pct_30_real)) return null;
  const n = Math.round(b.pct_30_real / 10);
  if (n >= 1 && n <= 9 && Math.abs(b.pct_30_real - n * 10) < 2.5) return { clave: 'decimos', anio: b.anio, n };
  return { clave: 'porcentaje', anio: b.anio, pct: b.pct_30_real };
}

function pintarCifra() {
  const el = $('portada-cifra');
  const c = cifraCentro(portada);
  el.classList.toggle('portada-lema-cifra', Boolean(c));
  if (!c) return;   // el lema, que ya ha puesto traducirPagina()
  const valores = { anio: String(c.anio), n: c.n === undefined ? '' : t.numero(c.n), pct: c.pct === undefined ? '' : pct(c.pct) };
  rellenar(el, t(`portada.cifra.${c.clave}`), valores, ['n', 'pct']);
}

// --- La cuenta con lo que se escribe ----------------------------------------------------------

// Decisión del autor (12-nov-2026): al escribir unos ingresos, la portada calcula en cuántas
// secciones el alquiler mensual mediano real (vivienda colectiva, último año) no pasa del umbral,
// con lo escrito en 12 pagas: la misma cuenta que la segunda frase del resumen del mapa con «Tu
// ficha» (resumenLlegaReal() de sueldo.js, con la vista por defecto del mapa). Los valores de las
// secciones se piden solo al escribir.
const RETARDO_CUENTA = 300;   // ms tras la última tecla

// Series y periodos de la cuenta: el alquiler por m² en su último periodo (el que marca el mapa sin
// año) y el alquiler mensual del mismo periodo, de la vivienda colectiva. null si falta alguno.
export function seriesCuenta(m) {
  if (!m?.indicadores) return null;
  const serie = (s) => serieDeTipologia(m, s, 'VC');
  const m2 = serie('alquiler_m2');
  const mes = serie('alquiler_mes');
  if (!m.indicadores[m2] || !m.indicadores[mes]) return null;
  const periodo = periodoPara(m.indicadores[m2]);
  const periodoMes = periodo === null ? null : periodoPara(m.indicadores[mes], periodo);
  if (periodo === null || periodoMes === null) return null;
  return { serie, periodo, pedidos: [[m2, periodo], [mes, periodoMes]] };
}

// La cuenta: { con, caben, proporcion } o null sin secciones con dato. `columnas`: { serie: { valores } }.
export function cuentaIngresos(neto, secciones, columnas, serie = (s) => s) {
  const sueldo = { neto, pagas: 12 };
  const estado = { ficha: 'peon' };
  const calculo = calculoLlega({ ficha: 'peon', perfiles: {}, sueldo, superficie: superficieDe(estado, sueldo, {}), serie });
  return resumenLlegaReal(calculo, secciones, (s, i) => columnas[s]?.valores[i] ?? null, umbralDe(estado));
}

let datosCuenta = null;   // promesa de { secciones, columnas, serie } (o null si no hay)
let cuenta = null;        // lo último pintado: { neto, r } | { error: true } | null
let turnoCuenta = 0;
let esperaCuenta = null;

function pedirDatosCuenta() {
  datosCuenta ??= (async () => {
    const s = seriesCuenta(m);
    if (!s) return null;
    const [secciones, ...cols] = await Promise.all([cargarSecciones(m), ...s.pedidos.map(([serie, p]) => cargarValores(m, serie, 'sc', p))]);
    if (!secciones || cols.some((c) => !c)) return null;
    return { secciones, columnas: Object.fromEntries(s.pedidos.map(([serie], i) => [serie, cols[i]])), serie: s.serie };
  })().catch((error) => {
    console.error(error);
    datosCuenta = null;   // se reintenta con la siguiente tecla
    return undefined;
  });
  return datosCuenta;
}

function pintarCuenta() {
  const caja = $('portada-cuenta');
  const nota = $('portada-cuenta-nota');
  nota.hidden = !cuenta?.r;
  if (!cuenta) return caja.replaceChildren();
  if (cuenta.error) return caja.replaceChildren(t('portada.cuenta.error'));
  if (!cuenta.r) return caja.replaceChildren(t('portada.cuenta.sin_datos'));
  const { neto, r } = cuenta;
  rellenar(caja, t('portada.cuenta.resultado'), {
    neto: t.numero(neto, Number.isInteger(neto) ? 0 : 2), umbral: t.porcentaje(umbralDe({})),
    pct: t.porcentaje(r.proporcion), caben: t.numero(r.caben), total: t.numero(r.con),
  }, ['pct']);
}

// Cuenta con lo escrito (sin datos reales, la muestra de ejemplo, o con algo que no se entiende, nada).
async function actualizarCuenta() {
  const yo = ++turnoCuenta;
  const neto = leerSueldo($('portada-neto').value);
  if (!neto || !m || m.ejemplo) {
    cuenta = null;
    return pintarCuenta();
  }
  const d = await pedirDatosCuenta();
  if (yo !== turnoCuenta) return;   // ya se ha escrito otra cosa
  cuenta = d ? { neto, r: cuentaIngresos(neto, d.secciones, d.columnas, d.serie) } : d === null ? null : { error: true };
  pintarCuenta();
}

// --- Historias ------------------------------------------------------------------------------

// Entradas del bloque «Historias»: título, entradilla (o '') y enlace al mapa con la historia, en
// el idioma de la página. Las historias sin título en ese idioma (ni en castellano) no salen. No
// depende de cuántas haya.
export function entradasHistorias(datos, idioma) {
  return (datos?.historias ?? []).map((h) => ({
    id: h.id,
    titulo: textoEn(h.titulo, idioma),
    entradilla: textoEn(h.entradilla, idioma),
    enlace: conIdioma(`mapa.html?historia=${encodeURIComponent(h.id)}`, idioma),
  })).filter((h) => h.titulo);
}

function pintarHistorias() {
  const seccion = $('portada-historias');
  const entradas = entradasHistorias(historias, t.idioma);
  seccion.hidden = !entradas.length;
  $('portada-historias-lista').replaceChildren(...entradas.map((h) => {
    const li = crear('li', 'portada-historia');
    li.dataset.historia = h.id;
    const a = crear('a', 'portada-historia-enlace', h.titulo);
    a.href = h.enlace;
    li.append(a);
    if (h.entradilla) li.append(crear('p', 'portada-historia-entradilla', h.entradilla));
    return li;
  }));
}

// --- Fichas, dado y pie ---------------------------------------------------------------------

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

// Pie: las fuentes y la fecha de los datos publicados (descargas/version.json, del release) o, sin
// él, las del manifiesto.
function pintarPie() {
  const ids = version?.fuentes?.map((f) => f.fuente)
    ?? Object.values(m?.indicadores ?? {}).map((d) => d.fuente);
  const fuentes = [...new Set((ids ?? []).filter((id) => id && id !== 'calculo_propio'))].map(nombreFuente);
  const pf = $('portada-pie-fuentes');
  pf.hidden = !fuentes.length;
  pf.textContent = fuentes.length ? t('portada.pie.fuentes', { fuentes: fuentes.join('; ') }) : '';
  const fecha = fechaLarga(version?.fecha ?? m?.generado, t.idioma);
  const pfe = $('portada-pie-fecha');
  pfe.hidden = !fecha;
  pfe.textContent = fecha ? t('portada.pie.fecha', { fecha }) : '';
  // Tarea 53: «Método en dos páginas», la fe de erratas y «Avisar de un error»
  $('portada-pie-transparencia').replaceChildren(...lineaTransparencia(t, { erratas: true }).childNodes);
}

// --- Idioma y arranque ----------------------------------------------------------------------

function pintar() {
  traducirPagina(t);
  document.title = t('portada.titulo_pagina');
  document.querySelector('meta[name="description"]')?.setAttribute('content', t('portada.descripcion'));
  for (const b of document.querySelectorAll('[data-idioma]')) b.setAttribute('aria-pressed', String(b.dataset.idioma === t.idioma));
  pintarCifra();
  pintarCuenta();
  pintarFichas();
  pintarHistorias();
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
    clearTimeout(esperaCuenta);
    esperaCuenta = setTimeout(actualizarCuenta, RETARDO_CUENTA);
  });
}

function prepararBuscador(territorios, secciones) {
  let fuentes = null;
  crearBuscador({
    entrada: $('buscador-entrada'),
    lista: $('buscador-lista'),
    sinResultados: () => t('interfaz.buscador.sin_resultados'),
    obtenerFuentes: async (texto) => {
      fuentes ??= {
        municipios: Object.entries(territorios.municipio ?? {}).map(([codigo, nombre]) => [codigo, nombre, formasDeNombre(nombre)]),
        secciones: await secciones(),
      };
      // Los códigos postales, solo cuando se escriben cifras (12-nov-2026; js/buscador.js)
      if (/^\d+$/.test(String(texto ?? '').trim()) && !fuentes.codigosPostales) {
        const { cargarCodigosPostales } = await import('./datos.js');
        fuentes.codigosPostales = await cargarCodigosPostales(m).catch(() => null);
      }
      return fuentes;
    },
    // Municipio: «28013 · Madrid» si sale de un código postal; si no, con su provincia (etiquetaMunicipio())
    etiqueta: (o) => (o.tipo === 'municipio' ? etiquetaMunicipio(o, territorios.provincia) : t('interfaz.ficha.seccion', { codigo: o.codigo })),
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
  // Las historias llevan cifras reales: con la muestra de ejemplo, como las cartas, no salen
  const [territorios, perf, port, ver, hist] = await Promise.all([
    cargarTerritorios(m).catch(() => ({})),
    cargarPerfiles(m).catch(() => null),
    m.ejemplo ? null : pedirJson('datos/portada.json').catch(() => null),
    m.ejemplo ? null : pedirJson('descargas/version.json').catch(() => null),
    m.ejemplo ? null : cargarHistorias(),
  ]);
  perfiles = perf;
  portada = port;
  version = ver;
  historias = hist;
  prepararBuscador(territorios, () => cargarSecciones(m));
  $('portada-dado').addEventListener('click', tirarDado);
  for (const el of document.querySelectorAll('[data-js]')) el.hidden = false;
  pintar();
  if ($('portada-neto').value.trim()) actualizarCuenta();   // escrito antes de que llegaran los datos
}

if (typeof document !== 'undefined' && document.getElementById('portada-sueldo')) iniciar();
