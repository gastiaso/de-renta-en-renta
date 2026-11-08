// Datos de la web. Un manifiesto dice qué hay y dónde: mapa base, índice de secciones,
// indicadores con sus años y mapas derivados.
//
// Punto de enganche: cuando el pipeline exporte web/datos/manifiesto.json (y el mapa base en
// web/teselas/), la web lo usa; mientras no exista, carga la muestra de web/datos/ejemplo/
// (geometría real, valores inventados; web/herramientas/generar_ejemplo.R).

const MANIFIESTOS = ['datos/manifiesto.json', 'datos/ejemplo/manifiesto.json'];
const memoria = new Map();

async function pedir(ruta, como) {
  const respuesta = await fetch(ruta);
  if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
  return respuesta[como]();
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

// Códigos de sección (texto de 10 dígitos) en el orden de los binarios.
export const cargarSecciones = (manifiesto) => recordar(manifiesto.secciones, () => pedir(manifiesto.secciones, 'json'));

// Nombres por nivel: { municipio: { '28079': 'Madrid' }, provincia: {...}, ccaa: {...} }.
export const cargarTerritorios = (manifiesto) =>
  manifiesto.territorios ? recordar(manifiesto.territorios, () => pedir(manifiesto.territorios, 'json')) : Promise.resolve({});

// Un indicador en un año: { valores: [número | null], estados: Uint8Array }.
export async function cargarIndicador(manifiesto, codigo, anio) {
  const def = manifiesto.indicadores?.[codigo];
  if (!def) throw new Error(`Indicador fuera del manifiesto: ${codigo}`);
  const ruta = def.ruta.replace('{anio}', anio);
  const secciones = await cargarSecciones(manifiesto);
  return recordar(ruta, async () => decodificar(await pedir(ruta, 'arrayBuffer'), secciones.length, manifiesto.binario));
}

// Formato binario (uno por indicador y año): n enteros de 32 bits con signo, little-endian,
// con el valor × 10 (un decimal exacto; `binario.nulo` = sin valor), seguidos de n bytes de
// estado (índice en `binario.estados`: dato, estimado, secreto, ausente).
export function decodificar(buffer, n, binario) {
  if (buffer.byteLength !== 5 * n) throw new Error(`Binario de ${buffer.byteLength} bytes; se esperaban ${5 * n}`);
  const vista = new DataView(buffer);
  const valores = new Array(n);
  for (let i = 0; i < n; i++) {
    const entero = vista.getInt32(4 * i, true);
    valores[i] = entero === binario.nulo ? null : entero / 10;
  }
  return { valores, estados: new Uint8Array(buffer, 4 * n, n) };
}
