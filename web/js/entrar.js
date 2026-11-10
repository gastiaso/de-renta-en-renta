// «Entrar» (backlog, tarea 37; decisión 18): la web solo recibe el tramo de la brecha entre la
// oferta y el parque (oferta / alquiler por m² del SERPAVI), nunca la cifra exacta. Las demás cifras
// de «entrar» son la brecha por una cifra pública de «quedarse», así que se dan como intervalo: los
// límites del tramo × esa cifra (R/derivados_entrar.R, que hace las mismas cuentas en el mismo orden):
//   - sueldo para entrar: × alquiler mensual mediano / umbral;
//   - sueldo para entrar con 50 m²: × alquiler por m² mediano × superficie / umbral;
//   - barrera (proporción del ingreso): × alquiler por m² mediano × superficie / ingreso, leída con los
//     tramos de «¿te llega?»; si el intervalo cruza un corte, «en el límite». Vale para las fichas y
//     para el sueldo que escribe el usuario («Tu ficha»), sin la oferta exacta.
// Sin DOM: la interfaz es de las tareas 38 y 39. Pruebas: pruebas/web/entrar.test.mjs, con los mismos
// casos inventados que la prueba de R (pruebas/datos/entrar_inventado.json).

import { cargarIndice, decodificar } from './datos.js';
import { tramoLlega } from './sueldo.js';

// Tramos de la brecha de una entrada `entrar` del manifiesto de la capa: { cortes, limites, aviso }.
export const tramosDe = (entrar) => entrar?.tramos ?? null;

// Límites [desde, hasta) del tramo k (0 … número de cortes), con los de la compuerta en los extremos;
// null si k no es un tramo.
export function limitesTramo(tramos, k) {
  if (!tramos || !Number.isInteger(k) || k < 0 || k > tramos.cortes.length) return null;
  const bordes = [tramos.limites[0], ...tramos.cortes, tramos.limites[1]];
  return { tramo: k, desde: bordes[k], hasta: bordes[k + 1] };
}

// Factores públicos de cada cifra derivada (mismo orden de operaciones que entrar_factores() de R).
export const FACTORES_ENTRAR = {
  sueldo_entrar: ({ alquiler_mes, umbral }) => alquiler_mes / umbral,
  sueldo_entrar_50: ({ alquiler_m2, superficie, umbral }) => (alquiler_m2 * superficie) / umbral,
  barrera_entrar: ({ alquiler_m2, superficie, ingreso }) => (alquiler_m2 * superficie) / ingreso,
};

// Intervalo de una cifra derivada: límites del tramo × factor (positivo y finito); si no, null.
export function intervaloEntrar(limites, factor) {
  if (!limites || !Number.isFinite(factor) || !(factor > 0)) return null;
  return { desde: limites.desde * factor, hasta: limites.hasta * factor };
}

// Intervalo de una cifra de «entrar» por su nombre (FACTORES_ENTRAR) en un tramo; null si falta algo.
export function cifraEntrar(nombre, tramos, k, terminos) {
  const factor = FACTORES_ENTRAR[nombre];
  if (!factor) throw new Error(`Cifra de «entrar» desconocida: ${nombre}`);
  return intervaloEntrar(limitesTramo(tramos, k), factor(terminos));
}

// «¿Te llega?» con un intervalo de la proporción: el tramo de cada extremo y si cruza un corte.
export function llegaEntrar(intervalo) {
  if (!intervalo) return null;
  const desde = tramoLlega(intervalo.desde);
  const hasta = tramoLlega(intervalo.hasta);
  return { desde, hasta, enLimite: desde !== hasta };
}

// Fichero de tramos ({"v": [tramo o null], "e": "0123…"}): tramos (enteros o null) y estados, en el
// orden del índice del nivel. Cualquier valor que no sea un tramo de 0 al número de cortes es un error.
export function decodificarTramos(datos, n, tramos, estados) {
  const { valores, estados: e } = decodificar(datos, n, { escala: 1, estados });
  const maximo = tramos.cortes.length;
  for (const v of valores) {
    if (v !== null && !(Number.isInteger(v) && v >= 0 && v <= maximo)) throw new Error(`Valor que no es un tramo: ${v}`);
  }
  return { tramos: valores, estados: e };
}

// Tramos de la brecha de un nivel y un año (manifiesto ya unido con la capa: `m.entrar`), o null.
export async function cargarTramosEntrar(m, nivel, anio) {
  const def = m?.entrar?.series?.[m.entrar.base];
  if (!def || !def.niveles.includes(nivel) || !def.anios.includes(Number(anio))) return null;
  const codigos = await cargarIndice(m, nivel);
  if (!codigos) return null;
  const ruta = def.ruta.replaceAll('{nivel}', nivel).replaceAll('{anio}', anio);
  const respuesta = await fetch(ruta);
  if (!respuesta.ok) throw new Error(`${ruta}: ${respuesta.status}`);
  return decodificarTramos(await respuesta.json(), codigos.length, m.entrar.tramos, m.codificacion.estados);
}
