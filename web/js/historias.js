// Recorridos guiados por el mapa (backlog, tarea 49): lógica sin DOM. Las historias las escribe R
// (R/web_historias.R) en datos/historias.json, fuera de git como portada.json:
//   { generado, historias: [{ id, titulo, entradilla, pasos: [{ titulo, texto, nota, estado, enlace, fuente }] }] }
// con los textos en { es, en }, sin HTML y con las cifras ya escritas. `nota` (opcional, o null) es el
// desplegable «Cómo se mide» del paso: los matices de método, fuera del cuerpo del texto. `estado` lleva claves de
// estado.js (mapa, anio, vista, territorio, escala; `vista` siempre): aplicar un paso pone esas y
// quita las que falten, y también la sección, la comparación, la ficha de perfil, la tipología, la
// superficie y el umbral, para que el mapa quede en el modo «necesario», con los supuestos por
// defecto y con lo que cuenta el texto. El panel lo pinta
// panel_historia.js y lo coordina principal.js.

import { esValida } from './estado.js';

export const RUTA_HISTORIAS = 'datos/historias.json';
// Claves del estado que puede traer un paso y las que aplicar un paso quita siempre.
export const CLAVES_PASO = ['mapa', 'anio', 'vista', 'territorio', 'escala'];
export const CLAVES_QUITADAS = ['seccion', 'comparar', 'ficha', 'tipologia', 'superficie', 'umbral'];
export const MAXIMO_PASOS = 20;   // el de la clave `paso` (estado.js)
const IDIOMAS = ['es', 'en'];
const ID = /^[a-z0-9_]{1,30}$/;
const ETIQUETA = /<\/?[a-z!][^>]*>/i;
// Enlace de un paso: una página del sitio (relativa, sin esquema), con consulta y ancla opcionales.
const HREF = /^(?!\/\/)[a-z0-9_\-./]*\.html(\?[a-z0-9_=&.:/%-]*)?(#[a-z0-9_-]*)?$/i;

const esObjeto = (x) => x !== null && typeof x === 'object' && !Array.isArray(x);

// Texto en el idioma pedido; si no está, en castellano.
export function textoEn(texto, idioma) {
  if (!esObjeto(texto)) return '';
  return texto[idioma] || texto.es || '';
}

// Errores de un texto { es, en }: los dos idiomas, sin vacíos y sin etiquetas HTML.
function erroresTexto(texto, donde, { opcional = false } = {}) {
  if ((texto === undefined || texto === null) && opcional) return [];
  if (!esObjeto(texto)) return [`${donde}: falta el texto`];
  const errores = [];
  for (const idioma of IDIOMAS) {
    const x = texto[idioma];
    if (typeof x !== 'string' || !x.trim()) errores.push(`${donde}: falta el texto en «${idioma}»`);
    else if (ETIQUETA.test(x)) errores.push(`${donde}: el texto en «${idioma}» lleva etiquetas HTML`);
  }
  return errores;
}

function erroresEstado(estado, donde, mapas) {
  if (!esObjeto(estado)) return [`${donde}: falta el estado`];
  const errores = [];
  for (const [clave, valor] of Object.entries(estado)) {
    if (!CLAVES_PASO.includes(clave)) errores.push(`${donde}: clave de estado no admitida «${clave}»`);
    else if (valor !== null && !esValida(clave, valor)) errores.push(`${donde}: valor no válido de «${clave}» (${valor})`);
  }
  if (estado.vista === undefined || estado.vista === null) errores.push(`${donde}: falta la vista`);
  if (mapas && estado.mapa != null && !mapas.includes(estado.mapa)) errores.push(`${donde}: el mapa «${estado.mapa}» no está en el manifiesto`);
  return errores;
}

function erroresEnlace(enlace, donde) {
  if (enlace === null || enlace === undefined) return [];
  if (!esObjeto(enlace)) return [`${donde}: el enlace no es un objeto ni null`];
  const errores = erroresTexto(enlace.texto, `${donde}, texto del enlace`);
  if (typeof enlace.href !== 'string' || !HREF.test(enlace.href)) errores.push(`${donde}: dirección del enlace no admitida (${enlace.href})`);
  return errores;
}

// Errores del fichero frente al contrato (lista vacía si cumple). `mapas`: ids de mapa del manifiesto,
// para comprobar también que existen.
export function validarHistorias(datos, { mapas = null } = {}) {
  if (!esObjeto(datos) || !Array.isArray(datos.historias)) return ['falta la lista «historias»'];
  const errores = [];
  const vistos = new Set();
  datos.historias.forEach((h, i) => {
    const donde = `historia ${i + 1}`;
    if (!esObjeto(h)) { errores.push(`${donde}: no es un objeto`); return; }
    if (typeof h.id !== 'string' || !ID.test(h.id)) errores.push(`${donde}: id no válido (${h.id})`);
    else if (vistos.has(h.id)) errores.push(`${donde}: id repetido (${h.id})`);
    vistos.add(h.id);
    errores.push(...erroresTexto(h.titulo, `${h.id ?? donde}, título`));
    errores.push(...erroresTexto(h.entradilla, `${h.id ?? donde}, entradilla`, { opcional: true }));
    if (!Array.isArray(h.pasos) || !h.pasos.length) { errores.push(`${h.id ?? donde}: sin pasos`); return; }
    if (h.pasos.length > MAXIMO_PASOS) errores.push(`${h.id ?? donde}: más de ${MAXIMO_PASOS} pasos`);
    h.pasos.forEach((p, k) => {
      const dondePaso = `${h.id ?? donde}, paso ${k + 1}`;
      if (!esObjeto(p)) { errores.push(`${dondePaso}: no es un objeto`); return; }
      errores.push(...erroresTexto(p.titulo, `${dondePaso}, título`));
      errores.push(...erroresTexto(p.texto, `${dondePaso}, texto`));
      errores.push(...erroresTexto(p.nota, `${dondePaso}, nota`, { opcional: true }));
      errores.push(...erroresTexto(p.fuente, `${dondePaso}, fuente`));
      errores.push(...erroresEstado(p.estado, dondePaso, mapas));
      errores.push(...erroresEnlace(p.enlace, dondePaso));
    });
  });
  return errores;
}

// Historias del fichero, o null si falta, no se lee o no cumple el contrato (la página sigue sin panel).
export async function cargarHistorias({ ruta = RUTA_HISTORIAS, leer = globalThis.fetch, mapas = null } = {}) {
  try {
    const respuesta = await leer(ruta, { cache: 'no-cache' });
    if (!respuesta.ok) return null;
    const datos = await respuesta.json();
    const errores = validarHistorias(datos, { mapas });
    if (errores.length) {
      console.warn(`${ruta}: ${errores.slice(0, 5).join('; ')}`);
      return null;
    }
    return datos;
  } catch {
    return null;
  }
}

// Enlace de un paso en el idioma de la página: en inglés, las páginas con un fichero por idioma
// cambian de fichero (el ancla se conserva tal cual) y las demás llevan ?idioma=en antes del ancla.
const PAGINAS_EN = { 'metodo.html': 'method.html', 'datos.html': 'data.html', 'metodo_corto.html': 'short_method.html' };
export function enlaceEnIdioma(href, idioma) {
  if (idioma !== 'en') return href;
  const [ruta, ancla] = href.split('#');
  const [pagina, consulta] = ruta.split('?');
  const cola = ancla !== undefined ? `#${ancla}` : '';
  if (PAGINAS_EN[pagina]) return `${PAGINAS_EN[pagina]}${consulta ? `?${consulta}` : ''}${cola}`;
  return `${pagina}?${consulta ? `${consulta}&` : ''}idioma=en${cola}`;
}

export const buscarHistoria = (datos, id) => datos?.historias?.find((h) => h.id === id) ?? null;

// Paso `n` (de 1 a N; fuera de ese rango, el más cercano; sin número, el 1): { paso, n, total }, o null.
export function pasoDe(historia, n) {
  const total = historia?.pasos?.length ?? 0;
  if (!total) return null;
  const k = Math.min(total, Math.max(1, Math.trunc(Number(n)) || 1));
  return { paso: historia.pasos[k - 1], n: k, total };
}

// Cambios de estado de un paso: las claves que trae y, como undefined, las que no trae y las que se
// quitan siempre. Un año «2024» queda como número, como lo deja estado.js.
export function cambiosDePaso(paso) {
  const cambios = {};
  for (const clave of [...CLAVES_PASO, ...CLAVES_QUITADAS]) cambios[clave] = undefined;
  for (const clave of CLAVES_PASO) {
    const valor = paso?.estado?.[clave];
    if (valor === undefined || valor === null || !esValida(clave, valor)) continue;
    cambios[clave] = clave === 'anio' && /^\d{4}$/.test(String(valor)) ? Number(valor) : String(valor);
  }
  return cambios;
}
