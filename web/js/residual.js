// Línea de ingreso residual (backlog, tarea 65; docs/especificacion_ingreso_residual.md, parte A): lo
// que queda al mes tras pagar la vivienda (ingreso − alquiler − otros gastos de vivienda, si están
// encendidos) frente a una línea mensual del tipo de hogar y del año del alquiler (regla 4). La lógica,
// sin DOM ni mapa, para que el mapa, la leyenda, la ficha y las pruebas usen las mismas cuentas.
//
// Dos líneas, con selector (decisión del autor, 13-nov-2026), la del IMV por defecto:
//   - imv: renta garantizada del ingreso mínimo vital (100 % de la pensión no contributiva anual / 12;
//     +30 % por el segundo adulto). De 2015 a 2019, antes del IMV, la pensión no contributiva anual / 12,
//     rotulada como tal (`tipo` 'pnc');
//   - ecv: umbral de riesgo de pobreza de la ECV del INE (60 % de la mediana de la renta por unidad de
//     consumo), de la ola que trae los ingresos del año del alquiler (alquiler de 2024 → ECV 2025); dos
//     adultos, × 1,5 (escala de la OCDE modificada).
// Tipos de hogar: una persona (las tres fichas de una persona y «Tu ficha» con un sueldo) y dos adultos
// («Tu ficha» con segundo sueldo); sin menores. La llave queda fuera: su ingreso es la renta de todos
// los hogares de la sección, de tamaño desconocido («no aplica»).
// Regla de «¿te llega?» (`regla`, apagada por defecto): con «Lo que queda», tres tramos: por encima de
// 1,25 × la línea (0), de la línea a 1,25 × la línea (1) y por debajo de la línea (2). Los límites y las
// opciones salen de inventario/supuestos.csv (js/supuestos.js). Los datos, de datos/lineas_residual.json
// (R/linea_residual.R).

import { SUPUESTOS } from './supuestos.js';

export const REGLAS = SUPUESTOS.reglas_llega;              // ['porcentaje', 'residual']
export const REGLA_POR_DEFECTO = SUPUESTOS.regla_llega;    // 'porcentaje'
export const LINEAS = SUPUESTOS.lineas_residual;           // ['imv', 'ecv']
export const LINEA_POR_DEFECTO = SUPUESTOS.linea_residual; // 'imv'
export const LIMITES_RESIDUAL = SUPUESTOS.limites_residual; // [1, 1.25], múltiplos de la línea

export const reglaDe = (estado) => (REGLAS.includes(estado?.regla) ? estado.regla : REGLA_POR_DEFECTO);
export const lineaDe = (estado) => (LINEAS.includes(estado?.linea) ? estado.linea : LINEA_POR_DEFECTO);
export const conResidual = (estado) => reglaDe(estado) === 'residual';

// Tipo de hogar de la línea: null en la llave (no aplica) o sin ficha.
export function hogarDe(ficha, sueldo) {
  if (!ficha || ficha === 'llave') return null;
  if (ficha !== 'peon') return 'una_persona';
  const s = sueldo?.segundo;
  return Number.isFinite(s) && s > 0 && s <= SUPUESTOS.sueldo_maximo ? 'dos_adultos' : 'una_persona';
}

// Línea de un año del alquiler (2024 o «2025-05»): { linea, hogar, valor (€ al mes), anio, tipo ('imv',
// 'pnc' o 'ecv'), ola (la de la ECV) }; sin la línea de ese año, { linea, hogar, sin: true, anio, ultimo }
// (el último año que la tiene); sin tabla, sin hogar o sin año, null.
export function lineaDelAnio(tabla, linea, anio, hogar) {
  const a = Number(String(anio ?? '').slice(0, 4));
  const datos = tabla?.[linea]?.anios;
  if (!datos || !hogar || !Number.isFinite(a) || a <= 0) return null;
  const x = datos[String(a)];
  const valor = x?.[hogar];
  if (!Number.isFinite(valor)) {
    const anios = Object.keys(datos).map(Number).filter((y) => Number.isFinite(datos[String(y)]?.[hogar]));
    return { linea, hogar, sin: true, anio: a, ultimo: anios.length ? Math.max(...anios) : null };
  }
  return { linea, hogar, valor, anio: a, tipo: x.tipo ?? linea, ...(x.ola ? { ola: x.ola } : {}) };
}

// Ingreso residual con los términos de calcular() de calculoLlega() (sueldo.js): ingreso − alquiler −
// otros gastos de vivienda (si están). Sin redondear, como la proporción; null si falta algún término.
export function ingresoResidual(r) {
  if (!r || !Number.isFinite(r.alquiler) || r.alquiler < 0 || !(r.ingreso > 0)) return null;
  return r.ingreso - r.alquiler - (Number.isFinite(r.otros) ? r.otros : 0);
}

// Tramo de la regla residual: 0 por encima de 1,25 × la línea, 1 de la línea a 1,25 × la línea, 2 por
// debajo de la línea (como tramoLlega(): 0 es el más holgado).
export function tramoResidual(residual, valorLinea, limites = LIMITES_RESIDUAL) {
  if (!Number.isFinite(residual) || !Number.isFinite(valorLinea)) return null;
  if (residual < valorLinea * limites[0]) return 2;
  return residual <= valorLinea * limites[1] ? 1 : 0;
}

// Lo de la ficha: { residual, linea (lineaDelAnio()), distancia (residual − línea), tramo } o, en la
// llave, { noAplica: true }; null sin línea ni hogar o sin términos.
export function residualFicha(r, ficha, linea) {
  if (ficha === 'llave') return { noAplica: true };
  if (!linea) return null;
  if (linea.sin) return { linea };
  const residual = ingresoResidual(r);
  if (residual === null) return null;
  return { residual, linea, distancia: residual - linea.valor, tramo: tramoResidual(residual, linea.valor) };
}

// «En el límite»: el intervalo del alquiler con el margen aproximado de su mediana (en %) cruza un corte
// de la regla residual.
export function enLimiteResidual(r, margenPct, valorLinea) {
  if (!r || !Number.isFinite(margenPct) || margenPct < 0 || !Number.isFinite(valorLinea)) return false;
  const con = (f) => tramoResidual(ingresoResidual({ ...r, alquiler: r.alquiler * f }), valorLinea);
  return con(1 - margenPct / 100) !== con(1 + margenPct / 100);
}

// Color de MapLibre con la regla residual: `calculo` de calculoLlega() (su expresion() da el ingreso y
// el gasto de vivienda de cada elemento). Sin línea, o con la llave, todo sin color.
export function colorResidual(calculo, idSeccion, colores, nivel = null, valorLinea = null, limites = LIMITES_RESIDUAL) {
  if (!calculo || calculo.ficha === 'llave' || !Number.isFinite(valorLinea)) return colores.fuera;
  const { valido, ingreso, gasto } = calculo.expresion(idSeccion, nivel);
  const resto = ['-', ingreso, gasto];
  return ['case', ['!', valido], colores.fuera,
    ['<', resto, valorLinea * limites[0]], colores.llega[2],
    ['<=', resto, valorLinea * limites[1]], colores.llega[1],
    colores.llega[0]];
}

// Proporción de secciones con dato donde lo que queda no baja de la línea (tramos 0 y 1). Con `real`,
// con el alquiler mensual mediano real de cada sección (tarea 40; las fichas de una persona): null si
// ninguna lo tiene.
export function resumenResidual(calculo, secciones, x, valorLinea, { real = false } = {}) {
  if (!calculo || !Number.isFinite(valorLinea)) return { con: 0, encima: 0, proporcion: null };
  let con = 0;
  let encima = 0;
  for (let i = 0; i < secciones.length; i++) {
    const r = calculo.calcular(secciones[i], (serie) => x(serie, i));
    const terminos = real ? (r?.real ? { ...r, alquiler: r.real.alquiler } : null) : r;
    const residual = ingresoResidual(terminos);
    if (residual === null) continue;
    con++;
    if (residual >= valorLinea) encima++;
  }
  if (real && !con) return null;
  return { con, encima, proporcion: con ? encima / con : null };
}

// Clave de i18n del nombre de la línea: la del IMV, la de la pensión no contributiva (antes del IMV) o
// la del umbral de la ECV.
export const claveLinea = (linea) => `interfaz.residual.nombre.${linea?.tipo ?? linea?.linea ?? 'imv'}`;
