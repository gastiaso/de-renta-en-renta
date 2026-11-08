// Datos de la web. Un manifiesto dice qué hay y dónde: mapa base, índice de secciones,
// indicadores con sus años, series de la ficha y mapas derivados.
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

export async function cargarManifiesto() {
  for (const ruta of MANIFIESTOS) {
    const respuesta = await fetch(ruta, { cache: 'no-cache' });
    if (respuesta.ok) return { ...(await respuesta.json()), ruta };
  }
  throw new Error('No hay manifiesto de datos');
}

// Códigos de sección (texto de 10 dígitos) en el orden de los valores.
export const cargarSecciones = (manifiesto) => recordar(manifiesto.secciones, () => pedir(manifiesto.secciones));

// Nombres por nivel: { municipio: { '28079': 'Madrid' }, provincia: {...}, ccaa: {...} }.
export const cargarTerritorios = (manifiesto) =>
  manifiesto.territorios ? recordar(manifiesto.territorios, () => pedir(manifiesto.territorios)) : Promise.resolve({});

// Un indicador en un año: { valores: [número | null], estados: Uint8Array }.
export async function cargarIndicador(manifiesto, codigo, anio) {
  const def = manifiesto.indicadores?.[codigo];
  if (!def) throw new Error(`Indicador fuera del manifiesto: ${codigo}`);
  const ruta = def.ruta.replace('{anio}', anio);
  const secciones = await cargarSecciones(manifiesto);
  return recordar(ruta, async () => decodificar(await pedir(ruta), secciones.length, manifiesto.codificacion));
}

// Series de una sección para la ficha, desde el fichero de su municipio (los cinco primeros
// dígitos del código): { indicador: { anios, valores, estados } }, o null si no hay.
export async function cargarSeries(manifiesto, seccion) {
  if (!manifiesto.fichas) return null;
  const ruta = manifiesto.fichas.replace('{municipio}', seccion.slice(0, 5));
  const fichero = await recordar(ruta, () => pedir(ruta));
  const propias = fichero.series?.[seccion];
  if (!propias) return null;
  return Object.fromEntries(Object.entries(propias).map(([indicador, datos]) => {
    const anios = fichero.anios[indicador];
    return [indicador, { anios, ...decodificar(datos, anios.length, manifiesto.codificacion) }];
  }));
}

// Formato (plan, §6.6): {"v": [valor × escala en enteros, o null], "e": "0012…"}, un elemento
// y un carácter por territorio o por año. Cada carácter de "e" es la posición del estado en
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
