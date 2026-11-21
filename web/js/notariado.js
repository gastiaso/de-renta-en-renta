// Capa del Notariado (19-nov-2026; R/web_notariado.R; docs/especificacion_notariado.md): cifras con
// licencia propia no comercial («© Consejo General del Notariado, solo uso no comercial»), solo en la
// web. La etiqueta de cada serie sale de su fuente (vocabulario.etiqueta.<fuente>), como la de los
// portales, y bloquea la descarga en CSV (descargaPermitida(), js/exportar.js). Aquí, sin DOM: el
// aviso de la descarga bloqueada y la nota de la ficha con la fecha de la foto de 12 meses.

export const FUENTES_NOTARIADO = ['notariado', 'notariado_cien'];

export const esNotariado = (def) => FUENTES_NOTARIADO.includes(def?.fuente);

// Fecha «AAAA-MM-DD» en el idioma de la página («21 de octubre de 2026», «21 October 2026»).
export function fechaLarga(fecha, idioma = 'es') {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha ?? '')) return null;
  const formato = new Intl.DateTimeFormat(idioma === 'en' ? 'en-GB' : 'es-ES', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' });
  return formato.format(new Date(`${fecha}T00:00:00Z`));
}

// Nota de la ficha de una serie de penotariado (`foto` y `minimo_informadas` en su entrada del
// manifiesto): de cuándo es la foto de 12 meses y el umbral del precio. Sin `foto`, null.
export function notaFoto(t, def) {
  const fecha = fechaLarga(def?.foto, t.idioma);
  if (!fecha) return null;
  return t('interfaz.ficha.foto_notariado', { fecha, minimo: t.numero(def.minimo_informadas ?? 20) });
}

// Aviso al pedir el CSV de una serie que no se descarga: el del Notariado (licencia) o el de los
// datos privados de oferta.
export const avisoSinDescarga = (t, def) => t(esNotariado(def) ? 'interfaz.exportar.notariado' : 'interfaz.exportar.privado');
