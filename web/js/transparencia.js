// Transparencia (backlog, tarea 53): enlaces que acompañan al mapa, a la ficha y a la portada.
//   - «Avisar de un error»: las incidencias del repositorio público, sin correo personal;
//   - «Método en dos páginas» (metodo_corto.html y short_method.html, que el flujo de Pages genera
//     desde docs/metodo_corto.md y docs/short_method.md) y su fe de erratas, que se rellena desde
//     inventario/erratas.csv (web/herramientas/pagina_metodo_corto.mjs);
//   - la fecha de los datos, la de la exportación del pipeline (`generado` del manifiesto), nunca
//     escrita a mano.
// Las funciones sin DOM las usan también las pruebas (pruebas/web/transparencia.test.mjs).

export const REPOSITORIO = 'https://github.com/gastiaso/de-renta-en-renta';
export const ENLACE_ERRORES = `${REPOSITORIO}/issues`;
export const PAGINAS_METODO_CORTO = { es: 'metodo_corto.html', en: 'short_method.html' };
// Ancla del título de la fe de erratas en cada página (pandoc, identificadores de GitHub)
export const ANCLAS_ERRATAS = { es: 'fe-de-erratas', en: 'errata' };

const idiomaDe = (idioma) => (idioma === 'en' ? 'en' : 'es');
export const enlaceMetodoCorto = (idioma) => PAGINAS_METODO_CORTO[idiomaDe(idioma)];
export const enlaceErratas = (idioma) => `${enlaceMetodoCorto(idioma)}#${ANCLAS_ERRATAS[idiomaDe(idioma)]}`;

// Fecha de los datos («2026-11-11» o «2026-11-11T13:14:33+0100») en largo, en el idioma: «11 de
// noviembre de 2026», «11 November 2026». null si no es una fecha.
export function fechaLarga(texto, idioma) {
  const r = /^(\d{4})-(\d{2})-(\d{2})/.exec(texto ?? '');
  if (!r) return null;
  const d = new Date(Date.UTC(Number(r[1]), Number(r[2]) - 1, Number(r[3])));
  if (Number.isNaN(d.getTime()) || d.getUTCDate() !== Number(r[3]) || d.getUTCMonth() !== Number(r[2]) - 1) return null;
  return new Intl.DateTimeFormat(idiomaDe(idioma) === 'en' ? 'en-GB' : 'es-ES',
    { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(d);
}

// Enlaces de transparencia, en orden: [{ clave, href, externo }]. `erratas`: con la fe de erratas.
export function enlacesTransparencia(idioma, { erratas = false } = {}) {
  return [
    { clave: 'metodo_corto', href: enlaceMetodoCorto(idioma), externo: false },
    ...(erratas ? [{ clave: 'erratas', href: enlaceErratas(idioma), externo: false }] : []),
    { clave: 'error', href: ENLACE_ERRORES, externo: true },
  ];
}

// Línea con la fecha de los datos (si la hay) y los enlaces, separados por « · ». `t`: traductor
// de i18n.js (textos en interfaz.transparencia). Devuelve el elemento.
export function lineaTransparencia(t, { fecha = null, erratas = false, clase = 'nota' } = {}) {
  const p = document.createElement('p');
  p.className = clase;
  const partes = [];
  const larga = fechaLarga(fecha, t.idioma);
  if (larga) {
    const s = document.createElement('span');
    s.className = 'transparencia-fecha';
    s.textContent = t('interfaz.transparencia.fecha', { fecha: larga });
    partes.push(s);
  }
  for (const { clave, href, externo } of enlacesTransparencia(t.idioma, { erratas })) {
    const a = document.createElement('a');
    a.href = href;
    a.textContent = t(`interfaz.transparencia.${clave}`);
    a.setAttribute('data-transparencia', clave);
    if (externo) a.setAttribute('rel', 'noopener');
    partes.push(a);
  }
  partes.forEach((x, i) => { if (i) p.append(' · '); p.append(x); });
  return p;
}
