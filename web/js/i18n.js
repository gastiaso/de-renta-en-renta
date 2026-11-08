// Textos en castellano e inglés desde i18n/<idioma>.json.
//
// Las claves que aún no están en los diccionarios se toman de i18n/pendiente_interfaz.json
// (sección «interfaz»), que se pasará a es.json y en.json; entonces ese fichero sobra y se
// borra. Los diccionarios mandan: el pendiente solo añade lo que falta.

export const IDIOMAS = ['es', 'en'];
const LOCALES = { es: 'es-ES', en: 'en-GB' };
const diccionarios = new Map();

async function leerJson(ruta) {
  const respuesta = await fetch(ruta);
  if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
  return respuesta.json();
}

function completar(base, extra) {
  for (const [clave, valor] of Object.entries(extra ?? {})) {
    if (!(clave in base)) base[clave] = valor;
    else if (valor && typeof valor === 'object' && typeof base[clave] === 'object') completar(base[clave], valor);
  }
  return base;
}

export async function cargarIdioma(idioma) {
  if (!diccionarios.has(idioma)) {
    const [dic, pendiente] = await Promise.all([
      leerJson(`i18n/${idioma}.json`),
      leerJson('i18n/pendiente_interfaz.json').catch(() => ({})),
    ]);
    diccionarios.set(idioma, completar(dic, pendiente[idioma]));
  }
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
  return t;
}

// Rellena los elementos marcados en el HTML: data-i18n (texto), data-i18n-aria (aria-label) y
// data-i18n-title (title).
export function traducirPagina(t, raiz = document) {
  document.documentElement.lang = t.idioma;
  for (const el of raiz.querySelectorAll('[data-i18n]')) el.textContent = t(el.dataset.i18n);
  for (const el of raiz.querySelectorAll('[data-i18n-aria]')) el.setAttribute('aria-label', t(el.dataset.i18nAria));
  for (const el of raiz.querySelectorAll('[data-i18n-title]')) el.title = t(el.dataset.i18nTitle);
}
