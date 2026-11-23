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

// Rótulo del periodo de una serie con foto de 12 meses (lectura del sitio, 23-nov-2026): no es el año
// del selector, son los 12 meses hasta la fecha de la foto. `clave`: la de la ficha
// ('interfaz.ficha.periodo_foto') o la de la leyenda ('interfaz.leyenda.periodo_foto'). Sin `foto`, null.
export function periodoFoto(t, def, clave = 'interfaz.ficha.periodo_foto') {
  const fecha = fechaLarga(def?.foto, t.idioma);
  return fecha ? t(clave, { fecha }) : null;
}

// Estado «secreto» de una serie del Notariado: no es el secreto de la fuente, es el umbral de compraventas
// informadas del atlas (lectura del sitio, 23-nov-2026). Para las demás series, null.
export function textoSecretoNotariado(t, def) {
  return esNotariado(def) ? t('interfaz.ficha.secreto_notariado', { minimo: t.numero(def.minimo_informadas ?? 20) }) : null;
}

// Aviso al pedir el CSV de una serie que no se descarga: el del Notariado (licencia) o el de los
// datos privados de oferta.
export const avisoSinDescarga = (t, def) => t(esNotariado(def) ? 'interfaz.exportar.notariado' : 'interfaz.exportar.privado');
