// Datos de la web. Un manifiesto dice qué hay y dónde: mapa base, índices de cada nivel,
// series (indicadores) con sus niveles y periodos, series de la ficha, nombres, cajas de los
// municipios, ingresos de las fichas y mapas derivados. Esquema: web/LEEME.md.
//
// Punto de enganche: cuando el pipeline exporte web/datos/manifiesto.json (y el mapa base en
// web/teselas/), la web lo usa; mientras no exista, carga la muestra de web/datos/ejemplo/
// (geometría real, valores inventados; web/herramientas/generar_ejemplo.R).

const MANIFIESTOS = ['datos/manifiesto.json', 'datos/ejemplo/manifiesto.json'];
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

export async function cargarManifiesto() {
  for (const ruta of MANIFIESTOS) {
    const respuesta = await fetch(ruta, { cache: 'no-cache' });
    if (respuesta.ok) return { ...(await respuesta.json()), ruta };
  }
  throw new Error('No hay manifiesto de datos');
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
// Ingresos de las fichas (neto mensual en euros): { llave: {...}, mochila: {...}, ... }.
export const cargarPerfiles = (m) => opcional(m.perfiles, {});

// Periodos de una serie: años (enteros) o, si no son años, etiquetas («2024-08»).
export const periodosDe = (def) => def?.periodos ?? def?.anios ?? [];
const anioDe = (periodo) => Number(String(periodo).slice(0, 4));

// Periodo de una serie que corresponde a un año: el mismo, o el último anterior, o el último.
export function periodoPara(def, anio) {
  const periodos = periodosDe(def);
  if (!periodos.length) return null;
  const previos = periodos.filter((p) => anioDe(p) <= anio);
  return (previos.length ? previos : periodos).at(-1);
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
