// Textos en castellano e inglés desde i18n/<idioma>.json. Las secciones `indicadores`,
// `fuentes` y `vocabulario` las genera el pipeline; `sitio`, `nav`, `fichas`, `avisos` e
// `interfaz` se escriben a mano y el pipeline las conserva (web/LEEME.md).

export const IDIOMAS = ['es', 'en'];
const LOCALES = { es: 'es-ES', en: 'en-GB' };
const diccionarios = new Map();

async function leerJson(ruta) {
  const respuesta = await fetch(ruta);
  if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
  return respuesta.json();
}

export async function cargarIdioma(idioma) {
  if (!diccionarios.has(idioma)) diccionarios.set(idioma, await leerJson(`i18n/${idioma}.json`));
  return crearTraductor(idioma, diccionarios.get(idioma));
}

// t('nav.mapa'), t('interfaz.ficha.seccion', { codigo: '2807901001' }); t.numero(4216.7, 0) → «4.217».
function crearTraductor(idioma, dic) {
  const formatos = new Map();
  const formato = (opciones) => {
    const clave = JSON.stringify(opciones);
    if (!formatos.has(clave)) formatos.set(clave, new Intl.NumberFormat(LOCALES[idioma], opciones));
    return formatos.get(clave);
  };

  const t = (clave, valores = {}) => {
    const texto = clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic);
    if (typeof texto !== 'string') {
      console.warn(`Falta el texto «${clave}» (${idioma})`);
      return clave;
    }
    return texto.replace(/\{(\w+)\}/g, (marca, nombre) => (nombre in valores ? valores[nombre] : marca));
  };
  t.idioma = idioma;
  t.existe = (clave) => typeof clave.split('.').reduce((nodo, parte) => nodo?.[parte], dic) === 'string';
  // Separador de miles también en las cifras de cuatro dígitos (1.332), como en el resto del atlas.
  t.numero = (x, decimales = 0) =>
    formato({ minimumFractionDigits: decimales, maximumFractionDigits: decimales, useGrouping: 'always' }).format(x);
  t.porcentaje = (x) => formato({ style: 'percent', maximumFractionDigits: 1 }).format(x);
  // Periodos: un año tal cual; un mes («2024-11»), escrito («noviembre de 2024», «November 2024»).
  const meses = new Intl.DateTimeFormat(LOCALES[idioma], { month: 'long', year: 'numeric', timeZone: 'UTC' });
  t.periodo = (p) => {
    const m = /^(\d{4})-(\d{2})$/.exec(String(p ?? ''));
    return m ? meses.format(new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, 1))) : String(p ?? '');
  };
  return t;
}

// Rellena los elementos marcados en el HTML: data-i18n (texto), data-i18n-aria (aria-label),
// data-i18n-title (title) y data-i18n-placeholder (placeholder). Los enlaces del menú a otras
// páginas llevan data-href-es y data-href-en (la página «Método» tiene un fichero por idioma).
export function traducirPagina(t, raiz = document) {
  document.documentElement.lang = t.idioma;
  for (const el of raiz.querySelectorAll('[data-href-es]')) el.href = t.idioma === 'en' ? el.dataset.hrefEn : el.dataset.hrefEs;
  for (const el of raiz.querySelectorAll('[data-i18n]')) el.textContent = t(el.dataset.i18n);
  for (const el of raiz.querySelectorAll('[data-i18n-aria]')) el.setAttribute('aria-label', t(el.dataset.i18nAria));
  for (const el of raiz.querySelectorAll('[data-i18n-title]')) el.title = t(el.dataset.i18nTitle);
  for (const el of raiz.querySelectorAll('[data-i18n-placeholder]')) el.placeholder = t(el.dataset.i18nPlaceholder);
}
