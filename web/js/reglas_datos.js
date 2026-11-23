// «Reglas del juego» (reglas.html, tarea 64): lógica sin DOM de la página, para probarla con node.
// Datos: datos/reglas.json (R/reglas.R, reglas_exportar_web()), con los resúmenes de
// inventario/reglas.csv, la ficha de cada norma citada (inventario/reglas_normas.csv) y las
// declaraciones de zona tensionada de las comunidades (inventario/zonas_tensionadas.csv).
//
// Borradores (decisión del autor, 13-nov-2026): la revisión jurídica la hace el autor; hasta entonces
// un resumen lleva `borrador: true`. En local, la página lo enseña con su marca; en el release,
// empaquetar_publicacion() deja de él solo el título y `en_revision: true` (R/publicar.R), y la página
// dice que está en revisión. Nada en borrador sale en el sitio.
//
// Textos: cada párrafo es una cadena; «[texto](destino)» es un enlace al BOE o a una página del atlas
// (los demás destinos se quedan en texto).

export const RUTA_DATOS = 'datos/reglas.json';
export const IDIOMAS = ['es', 'en'];
export const SECCIONES = ['que_dice', 'a_quien', 'cambios', 'en_el_atlas'];
// Páginas del atlas a las que puede llevar un enlace de los textos (las mismas que REGLAS_PAGINAS, R/reglas.R)
export const PAGINAS = ['./', 'index.html', 'mapa.html', 'sobrecarga.html', 'historico.html', 'reglas.html',
  'metodo.html', 'method.html', 'metodo_corto.html', 'short_method.html', 'datos.html', 'data.html'];
// Páginas que cambian de idioma con ?idioma=en (las demás tienen un fichero por idioma)
const CON_IDIOMA = ['./', 'index.html', 'mapa.html', 'sobrecarga.html', 'historico.html', 'reglas.html'];
const PAGINA_EN = { 'metodo.html': 'method.html', 'datos.html': 'data.html', 'metodo_corto.html': 'short_method.html' };

// Estado de la dirección: solo el idioma.
export function leerEstado(busqueda = '') {
  const p = new URLSearchParams(busqueda);
  return { idioma: IDIOMAS.includes(p.get('idioma')) ? p.get('idioma') : 'es' };
}

export function consulta(estado) {
  return estado.idioma === 'en' ? '?idioma=en' : '';
}

// Ancla de un resumen (la que enlazan la portada y la ficha del indicador 20): el id con guiones.
export function ancla(id) {
  return String(id ?? '').replaceAll('_', '-');
}

// Destino de un enlace de los textos en el idioma de la página, o null si no está permitido.
export function destinoEnlace(destino, idioma = 'es') {
  if (typeof destino !== 'string') return null;
  if (destino.startsWith('https://www.boe.es/')) return destino;
  const m = /^([^?#]*)(\?[^#]*)?(#.*)?$/.exec(destino);
  if (!m) return null;
  let [, pagina, busqueda = '', marca = ''] = m;
  if (!pagina) pagina = 'reglas.html';
  if (!PAGINAS.includes(pagina)) return null;
  if (idioma === 'en') {
    if (CON_IDIOMA.includes(pagina)) {
      const p = new URLSearchParams(busqueda);
      p.set('idioma', 'en');
      busqueda = `?${p.toString()}`;
    } else if (PAGINA_EN[pagina]) {
      pagina = PAGINA_EN[pagina];
    }
  }
  return `${pagina}${busqueda}${marca}`;
}

// Trozos de un párrafo: [{ texto }] y [{ texto, href }] para los enlaces permitidos.
export function trozosTexto(parrafo, idioma = 'es') {
  const trozos = [];
  const re = /\[([^\]]+)\]\(([^)\s]+)\)/g;
  let desde = 0;
  for (const m of String(parrafo ?? '').matchAll(re)) {
    if (m.index > desde) trozos.push({ texto: parrafo.slice(desde, m.index) });
    const href = destinoEnlace(m[2], idioma);
    trozos.push(href ? { texto: m[1], href } : { texto: m[1] });
    desde = m.index + m[0].length;
  }
  if (desde < String(parrafo ?? '').length) trozos.push({ texto: parrafo.slice(desde) });
  return trozos;
}

// Resúmenes en orden, los publicables y los que están en revisión (sin texto).
export function resumenes(datos) {
  return [...(datos?.reglas ?? [])].sort((a, b) => (a.orden ?? 0) - (b.orden ?? 0));
}

export function enRevision(regla) {
  return regla?.en_revision === true;
}

export function esBorrador(regla) {
  return regla?.borrador === true || regla?.revisado === 'borrador';
}

// Texto de un campo en un idioma: { es, en } -> el del idioma (o el castellano si falta).
export function enIdioma(campo, idioma) {
  if (campo === null || campo === undefined) return null;
  if (typeof campo === 'string') return campo;
  return campo[idioma] ?? campo.es ?? null;
}

// Normas de un resumen con su ficha: [{ norma, bloque, titulo, url, ficha }].
export function normasDe(regla, datos) {
  return (regla?.normas ?? []).map((n) => ({ ...n, ficha: datos?.normas?.[n.norma] ?? null }));
}

// Etiqueta de una norma citada: «LAU, Artículo 36» (el título del bloque, tal como lo da el índice del
// BOE, en castellano en los dos idiomas: es el nombre oficial).
export function etiquetaNorma(n, idioma) {
  const nombre = enIdioma(n.ficha?.abreviatura, idioma) ?? n.norma;
  return n.titulo ? `${nombre}, ${n.titulo}` : nombre;
}

// Decretos-leyes de los que depende un resumen y siguen pendientes de convalidación.
export function pendientesDe(regla, datos) {
  const vistos = new Set();
  return normasDe(regla, datos).filter((n) => {
    if (n.ficha?.estado !== 'vigente_pendiente_convalidacion' || vistos.has(n.norma)) return false;
    vistos.add(n.norma);
    return true;
  });
}

// Línea de estado de un resumen: [{ clave, valores }] para el traductor (la página las une).
export function lineasEstado(regla, datos, idioma, fecha = (x) => x) {
  if (enRevision(regla)) return [{ clave: 'reglas.estado.en_revision', valores: {} }];
  const lineas = [{ clave: 'reglas.estado.vigente_desde', valores: { fecha: fecha(regla.vigente_desde) } }];
  const pendientes = pendientesDe(regla, datos);
  if (regla.estado === 'vigente_pendiente_convalidacion' && pendientes.length) {
    lineas.push({ clave: 'reglas.estado.pendiente', valores: { normas: pendientes.map((n) => enIdioma(n.ficha.abreviatura, idioma)).join(', ') } });
  }
  return lineas;
}

// Fecha más reciente de consulta del BOE (la del pie).
export function fechaConsulta(datos) {
  return datos?.consultado ?? null;
}

// ¿Están todos los resúmenes en revisión (el sitio publicado antes de la firma)? La entradilla lo dice
// y no promete enlaces que aún no salen (lectura del sitio, 23-nov-2026). Sin resúmenes, false.
export function todosEnRevision(datos) {
  const lista = resumenes(datos);
  return lista.length > 0 && lista.every(enRevision);
}

// Resúmenes en borrador con texto (la página local los cuenta en el aviso de arriba).
export function borradores(datos) {
  return resumenes(datos).filter((r) => esBorrador(r) && !enRevision(r)).length;
}
