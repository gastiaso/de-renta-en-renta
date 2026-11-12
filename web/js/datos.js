// Datos de la web. Un manifiesto dice qué hay y dónde: mapa base, índices de cada nivel,
// series (indicadores) con sus niveles y periodos, series de la ficha, nombres, cajas de los
// municipios, ingresos de las fichas y mapas derivados. Esquema: web/LEEME.md.
//
// Punto de enganche: cuando el pipeline exporte web/datos/manifiesto.json (y el mapa base en
// web/teselas/), la web lo usa; mientras no exista, y solo en local, carga la muestra de
// web/datos/ejemplo/ (geometría real, valores inventados; web/herramientas/generar_ejemplo.R).

const MANIFIESTOS = ['datos/manifiesto.json', 'datos/ejemplo/manifiesto.json'];
// Capas desmontables (guía, regla 6), aparte de la exportación general: cada una con su manifiesto,
// que el pipeline escribe siempre (apagada, {"capa": …, "activa": false}) y el flujo de Pages también
// (R/web_portales.R; docs/publicacion.md). Sus series y mapas se suman a los del manifiesto general
// (unirCapas). La muestra de datos/ejemplo/ no tiene capas.
const CAPAS = ['datos/portales/manifiesto.json'];
const memoria = new Map();

async function pedir(ruta) {
  const respuesta = await fetch(ruta);
  if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
  return respuesta.json();
}

function recordar(clave, promesa) {
  if (!memoria.has(clave)) memoria.set(clave, promesa().catch((error) => { memoria.delete(clave); throw error; }));
  return memoria.get(clave);
}

const opcional = (ruta, vacio) => (ruta ? recordar(ruta, () => pedir(ruta)) : Promise.resolve(vacio));

// La muestra (valores inventados) solo es reserva al trabajar en local y solo si el manifiesto del
// pipeline no existe (404). En el sitio publicado, o si el manifiesto falla por otra causa (un 503,
// la red), se lanza el error y la página lo dice: nunca se enseñan cifras inventadas por un fallo.
const EN_LOCAL = /^(localhost|127\.0\.0\.1|\[::1\])$|\.localhost$/.test(globalThis.location?.hostname ?? 'localhost');

export async function cargarManifiesto({ local = EN_LOCAL, leer = globalThis.fetch } = {}) {
  for (const ruta of local ? MANIFIESTOS : MANIFIESTOS.slice(0, 1)) {
    const respuesta = await leer(ruta, { cache: 'no-cache' });
    if (respuesta.status === 404 && local) continue;
    if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
    const m = { ...(await respuesta.json()), ruta };
    return m.ejemplo ? m : unirCapas(m, await Promise.all(CAPAS.map(pedirCapa)));
  }
  throw new Error('No hay manifiesto de datos');
}

// Manifiesto de una capa, o null si no se puede leer (la web sigue sin ella).
async function pedirCapa(ruta) {
  try {
    const respuesta = await fetch(ruta, { cache: 'no-cache' });
    return respuesta.ok ? await respuesta.json() : null;
  } catch {
    return null;
  }
}

// Manifiesto general con las series y los mapas de las capas encendidas (`activa`), detrás de los
// suyos; en `capas`, la cabecera de cada una (versión, fecha). Una clave que ya está en el general
// no se pisa. Sin capas encendidas, el manifiesto tal cual. Tarea 37: la entrada `entrar` de una
// capa (tramos de la brecha entre la oferta y el parque; js/entrar.js) pasa tal cual a `m.entrar`.
export function unirCapas(m, capas) {
  const activas = (capas ?? []).filter((c) => c?.activa);
  if (!activas.length) return m;
  const sumar = (general, campo) => {
    const out = { ...(general ?? {}) };
    for (const capa of activas) {
      for (const [clave, def] of Object.entries(capa[campo] ?? {})) if (!(clave in out)) out[clave] = def;
    }
    return out;
  };
  const cabeceras = Object.fromEntries(activas.map((c) => [c.capa, { version: c.version, generado: c.generado }]));
  const entrar = activas.find((c) => c.entrar)?.entrar;
  return {
    ...m, indicadores: sumar(m.indicadores, 'indicadores'), mapas: sumar(m.mapas, 'mapas'), capas: cabeceras,
    ...(entrar ? { entrar } : {}),
  };
}

// Índice de un nivel: códigos en el orden de los valores (sección: texto de 10 dígitos;
// España: «00»). Admite la clave antigua `secciones` para el nivel de sección.
const rutaIndice = (m, nivel) => m.indices?.[nivel] ?? (nivel === 'sc' ? m.secciones : undefined);

export function cargarIndice(m, nivel) {
  const ruta = rutaIndice(m, nivel);
  return ruta ? recordar(ruta, () => pedir(ruta)) : Promise.resolve(null);
}
export const cargarSecciones = (m) => cargarIndice(m, 'sc');

export async function posiciones(m, nivel) {
  const codigos = await cargarIndice(m, nivel);
  if (!codigos) return null;
  return recordar(`posiciones:${nivel}`, async () => new Map(codigos.map((c, i) => [c, i])));
}

// Nombres: { ccaa: {...}, provincia: {...}, municipio: {...}, ccaa_de_provincia: {'28': '13'} }.
export const cargarTerritorios = (m) => opcional(m.territorios, {});
// Cajas de los municipios para el buscador: { municipio: { '28079': [oeste, sur, este, norte] } }.
export const cargarCajas = (m) => opcional(m.cajas, {});
// Códigos postales para el buscador (12-nov-2026): { '28013': ['28079'], … }, municipios por peso;
// {} si el manifiesto no lo trae (la muestra). Se pide solo cuando se escriben cifras.
export const cargarCodigosPostales = (m) => opcional(m?.codigos_postales, {});
// Ingresos de las fichas (neto mensual en euros): { llave: {...}, mochila: {...}, ... }.
export const cargarPerfiles = (m) => opcional(m.perfiles, {});
// Percentil salarial (F3): { percentiles: [1, …, 99], anios: { '2024': { '00': [...], '09': [...] } } }.
export const cargarSalarios = (m) => opcional(m.salarios, null);
// F5: fichero de detalle de un mapa (`detalle` en el manifiesto; las declaraciones del indicador 20,
// { municipio: [...] }), o null.
export const cargarDetalle = (ruta) => opcional(ruta, null);

// Periodos de una serie: años (enteros) o, si no son años, etiquetas («2024-08»).
export const periodosDe = (def) => def?.periodos ?? def?.anios ?? [];
const anioDe = (periodo) => Number(String(periodo).slice(0, 4));
const esAnio = (periodo) => /^\d{4}$/.test(String(periodo));
// Para comparar un año con meses: el año 2024 va detrás de todos sus meses («2024-99»).
const claveDe = (periodo) => (esAnio(periodo) ? `${periodo}-99` : String(periodo));

// Periodo de una serie que corresponde a un año o a un periodo de otra serie («2024-08»): el
// mismo o el último anterior. Sin año, el último. Con un año anterior a toda la serie (2020 en
// las viviendas turísticas, que empiezan en 2024), null: la web pinta «sin dato» y dice desde
// cuándo hay serie (inicioSerie), en vez de enseñar otro año (pregunta abierta 32).
export function periodoPara(def, anio) {
  const periodos = periodosDe(def);
  if (!periodos.length) return null;
  if (anio === undefined || anio === null || anio === '') return periodos.at(-1);
  const mismo = periodos.find((p) => String(p) === String(anio));
  if (mismo !== undefined) return mismo;
  const previos = periodos.every(esAnio)
    ? periodos.filter((p) => anioDe(p) <= anioDe(anio))
    : periodos.filter((p) => claveDe(p) <= claveDe(anio));
  return previos.length ? previos.at(-1) : null;
}

// Primer periodo de una serie (desde cuándo hay datos), o null.
export const inicioSerie = (def) => periodosDe(def)[0] ?? null;

// Año pedido anterior a toda la serie: { anio, desde }; si no, null.
export function fueraDeSerie(def, anio) {
  if (anio === undefined || anio === null || anio === '' || !periodosDe(def).length) return null;
  return periodoPara(def, anio) === null ? { anio, desde: inicioSerie(def) } : null;
}

// Tipología de la vivienda (plan, decisión 12): la serie de la vivienda colectiva (VC) es la de
// por defecto; la de la unifamiliar (VU), su variante en el manifiesto («variantes»: {"VU":
// "alquiler_m2_vu"}, y en la variante, «por_defecto»). Nunca se mezclan: cada mapa usa una.
export const TIPOLOGIAS = ['VC', 'VU'];
const serieDeDefecto = (m, serie) => m.indicadores?.[serie]?.por_defecto ?? serie;

// Serie que corresponde a una tipología; si la serie no tiene esa variante, la de por defecto.
export function serieDeTipologia(m, serie, tipologia) {
  const base = serieDeDefecto(m, serie);
  return (tipologia === 'VU' && m.indicadores?.[base]?.variantes?.VU) || base;
}

// ¿Tiene la serie (o su serie de por defecto) variante por tipología?
export const tieneTipologia = (m, serie) => Boolean(m.indicadores?.[serieDeDefecto(m, serie)]?.variantes?.VU);

// Tipología de una serie: «VU» en la variante unifamiliar; «VC» en el resto de series con
// variante; null en las series sin tipología.
export function tipologiaDe(m, serie) {
  if (!tieneTipologia(m, serie)) return null;
  return m.indicadores[serie]?.por_defecto ? 'VU' : 'VC';
}

export function rutaValores(def, nivel, periodo) {
  return def.ruta.replaceAll('{nivel}', nivel).replaceAll('{anio}', periodo).replaceAll('{periodo}', periodo);
}

// Valores de una serie en un nivel y periodo: { valores: [número | null], estados: Uint8Array },
// en el orden del índice del nivel; null si la serie no existe en ese nivel.
export async function cargarValores(m, serie, nivel, periodo) {
  const def = m.indicadores?.[serie];
  if (!def) return null;
  if (def.niveles ? !def.niveles.includes(nivel) : nivel !== 'sc') return null;
  if (nivel !== 'sc' && !def.ruta.includes('{nivel}')) return null;
  const codigos = await cargarIndice(m, nivel);
  if (!codigos) return null;
  const ruta = rutaValores(def, nivel, periodo);
  return recordar(ruta, async () => decodificar(await pedir(ruta), codigos.length, codificacionDe(m, serie)));
}

// Codificación de una serie: la general, con la escala propia de la serie si la tiene
// (por ejemplo, 100 para publicar dos decimales).
export const codificacionDe = (m, serie) => {
  const escala = m.indicadores?.[serie]?.escala;
  return escala ? { ...m.codificacion, escala } : m.codificacion;
};
export const cargarIndicador = (m, serie, periodo) => cargarValores(m, serie, 'sc', periodo);

// Valor de un territorio: { valor, estado } o null.
export async function valorDe(m, serie, nivel, codigo, periodo) {
  const [datos, pos] = await Promise.all([cargarValores(m, serie, nivel, periodo), posiciones(m, nivel)]);
  const i = pos?.get(codigo);
  if (!datos || i === undefined) return null;
  return { valor: datos.valores[i], estado: datos.estados[i] };
}

// Series de una sección para la ficha, desde el fichero de su municipio (los cinco primeros
// dígitos del código): { serie: { anios, valores, estados } }, o null si no hay.
export async function cargarSeries(m, seccion) {
  if (!m.fichas) return null;
  const ruta = m.fichas.replace('{municipio}', seccion.slice(0, 5));
  const fichero = await recordar(ruta, () => pedir(ruta));
  const propias = fichero.series?.[seccion];
  if (!propias) return null;
  return Object.fromEntries(Object.entries(propias).map(([serie, datos]) => {
    const anios = fichero.anios[serie];
    return [serie, { anios, ...decodificar(datos, anios.length, codificacionDe(m, serie)) }];
  }));
}

// Formato (plan, §6.6): {"v": [valor × escala en enteros, o null], "e": "0012…"}, un elemento
// y un carácter por territorio o por periodo. Cada carácter de "e" es la posición del estado en
// `codificacion.estados` (0 dato, 1 estimado, 2 secreto, 3 ausente).
export function decodificar(datos, n, codificacion) {
  const { v, e } = datos ?? {};
  if (!Array.isArray(v) || typeof e !== 'string' || v.length !== n || e.length !== n) {
    throw new Error(`Datos con ${v?.length} valores y ${e?.length} estados; se esperaban ${n}`);
  }
  const estados = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    estados[i] = e.charCodeAt(i) - 48;
    if (estados[i] >= codificacion.estados.length) throw new Error(`Estado desconocido «${e[i]}» en la posición ${i}`);
  }
  return { valores: v.map((x) => (x === null ? null : x / codificacion.escala)), estados };
}

// Atributos de un elemento de la capa sin_seccion del mapa base (suelo que no es de ninguna
// sección): superficie en km² (o null), códigos de las provincias que lo rodean y, si el trozo es
// de una unidad del IGN, su nombre y su tipo (o null).
export function atributosSinSeccion(p) {
  const km2 = p?.km2 === undefined || p?.km2 === null || p?.km2 === '' ? NaN : Number(p.km2);
  const texto = (x) => (typeof x === 'string' && x.trim() ? x.trim() : null);
  return {
    km2: Number.isFinite(km2) ? km2 : null,
    provincias: String(p?.provincias ?? '').split(/\s+/).filter((c) => /^\d{2}$/.test(c)),
    nombre: texto(p?.nombre),
    tipo: texto(p?.tipo),
  };
}

// Elementos de la capa sin_seccion bajo un punto (propiedades): el hueco entero y, encima, el trozo
// de una unidad del IGN si lo hay. Manda el trozo con nombre; si no, el primero.
export function elegirSinSeccion(lista) {
  const validas = (lista ?? []).filter(Boolean);
  return validas.find((p) => typeof p.nombre === 'string' && p.nombre.trim()) ?? validas[0] ?? null;
}
