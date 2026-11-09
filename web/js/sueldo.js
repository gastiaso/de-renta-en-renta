// «Tu sueldo» (plan, §6.6 y §3.1): la lógica, sin DOM ni mapa, para que el mapa, la leyenda,
// la ficha y las pruebas usen las mismas cuentas.
//
// Dos modos:
//   - «necesario» (por defecto): sueldo neto necesario para que el alquiler de la superficie
//     elegida no pase del umbral (indicador 21), en seis tramos con los cortes del manifiesto;
//   - «llega» («¿te llega?», al escribir un sueldo o elegir una ficha): alquiler / ingreso, en
//     tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %), con la proporción de secciones
//     donde el alquiler cabe por debajo del umbral.
// Cada cálculo tiene dos caras que deben coincidir: la expresión de estilo de MapLibre (color
// del mapa, sin volver a descargar teselas) y la función en JS (ficha, resumen, leyenda).

import { formulaDe } from './formulas.js';
import { pasosDeRampa } from './colores.js';

export const FICHAS_PERFIL = ['llave', 'mochila', 'tartera', 'transistor'];
export const SUPERFICIES = [50, 70, 90];
export const UMBRALES = [30, 40];
export const LIMITES_LLEGA = [0.3, 0.4];

const SUELDO_MAXIMO = 100000;

// Ingreso de «Tu ficha»: neto mensual repartido en 12 (regla 8). Con 14 pagas, la paga × 14 / 12;
// el segundo sueldo, si lo hay, se suma con las mismas pagas.
export function ingresoPeon(sueldo) {
  const valido = (x) => Number.isFinite(x) && x > 0 && x <= SUELDO_MAXIMO;
  if (!sueldo || !valido(sueldo.neto)) return null;
  const pagas = sueldo.pagas === 14 ? 14 : 12;
  const segundo = valido(sueldo.segundo) ? sueldo.segundo : 0;
  return ((sueldo.neto + segundo) * pagas) / 12;
}

export function modoDe(estado, sueldo, perfiles) {
  if (estado.ficha === 'peon') return ingresoPeon(sueldo) ? 'llega' : 'necesario';
  if (estado.ficha && perfiles?.[estado.ficha]) return 'llega';
  return 'necesario';
}

// Superficie del cálculo (§3.1): las fichas de una persona, la suya (50 m²), para que sus mapas
// solo difieran por el ingreso; la llave, ninguna (paga el alquiler mediano de su sección); el
// peón y el mapa del sueldo necesario, la elegida o, si no, 50 m² con un sueldo y 70 con dos.
export function superficieDe(estado, sueldo, perfiles) {
  const ficha = estado.ficha;
  if (ficha === 'llave' && perfiles?.llave) return null;
  if (ficha && ficha !== 'peon' && perfiles?.[ficha]) return perfiles[ficha].superficie_m2 ?? 50;
  if (SUPERFICIES.includes(estado.superficie)) return estado.superficie;
  return ficha === 'peon' && ingresoPeon(sueldo) && sueldo.segundo > 0 ? 70 : 50;
}

export const umbralDe = (estado) => (UMBRALES.includes(estado.umbral) ? estado.umbral : 30) / 100;

// Ingreso de una ficha de perfil en una sección: el de su provincia o el nacional (código «00»).
export function ingresoPerfil(perfil, seccion) {
  if (!perfil?.neto_mensual) return null;
  const clave = perfil.nivel === 'provincia' ? seccion.slice(0, 2) : '00';
  const x = perfil.neto_mensual[clave];
  return Number.isFinite(x) && x > 0 ? x : null;
}

// Perfil de una ficha con el ingreso del año del alquiler (regla 4; decisión del autor, 9-nov-2026):
// si la ficha tiene ese año (`anios`, por ejemplo la tartera de 2015 a 2026), su ingreso y su
// año; si no, el último que tiene (`anio`, `neto_mensual`), y la web avisa de que no son del
// mismo año. La llave no cambia: su ingreso es la renta de la sección del mismo periodo.
export function perfilDelAnio(perfil, anio) {
  const delAnio = anio === null || anio === undefined ? null : perfil?.anios?.[String(anio)];
  return delAnio ? { ...perfil, anio: Number(anio), neto_mensual: delAnio } : perfil;
}

export function perfilesDelAnio(perfiles, anio) {
  if (!perfiles) return perfiles;
  return Object.fromEntries(Object.entries(perfiles).map(([f, p]) => [f, f === 'llave' ? p : perfilDelAnio(p, anio)]));
}

function expresionIngresoPerfil(perfil, idSeccion) {
  const pares = Object.entries(perfil.neto_mensual ?? {}).filter(([, x]) => x > 0);
  if (perfil.nivel === 'provincia') {
    if (!pares.length) return 0;
    return ['match', ['slice', ['to-string', ['get', idSeccion]], 0, 2], ...pares.flat(), 0];
  }
  return perfil.neto_mensual?.['00'] ?? 0;
}

const estadoMapa = (serie) => ['feature-state', serie];
const numero = (serie) => ['to-number', estadoMapa(serie)];
const falta = (serie) => ['==', estadoMapa(serie), null];

// Cálculo de «¿te llega?» para una ficha. `x(serie)` da el valor de una serie en la sección.
// `serie(nombre)` da la serie que se usa en lugar de cada una: la del alquiler de la tipología
// elegida (vivienda colectiva o unifamiliar; datos.js, serieDeTipologia); por defecto, la misma.
//   series: las que hay que cargar en el mapa (la primera, la del alquiler);
//   calcular(seccion, x) → { alquiler, ingreso, ratio } o null;
//   ingreso(seccion, x) → el ingreso de la ficha en la sección, o null si falta (estadoLlega);
//   expresion(idSeccion) → { valido, ratio }, expresiones de MapLibre.
export function calculoLlega({ ficha, perfiles, sueldo, superficie, serie = (s) => s }) {
  if (ficha === 'llave') {
    const { ingreso } = perfiles.llave;
    const vivienda = { serie: serie(perfiles.llave.vivienda.serie) };
    const divisor = ingreso.divisor ?? 12;
    return {
      ficha,
      series: [vivienda.serie, ingreso.serie],
      ingreso(seccion, x) {
        const renta = x(ingreso.serie);
        return renta === null || !(renta > 0) ? null : renta / divisor;
      },
      calcular(seccion, x) {
        const alquiler = x(vivienda.serie);
        const renta = x(ingreso.serie);
        if (alquiler === null || renta === null || !(renta > 0)) return null;
        return { alquiler, ingreso: renta / divisor, ratio: alquiler / (renta / divisor) };
      },
      expresion() {
        const ing = ['/', numero(ingreso.serie), divisor];
        return {
          valido: ['all', ['!', falta(vivienda.serie)], ['!', falta(ingreso.serie)], ['>', numero(ingreso.serie), 0]],
          ratio: ['/', numero(vivienda.serie), ing],
        };
      },
    };
  }
  const perfil = ficha === 'peon' ? null : perfiles[ficha];
  const fijo = ficha === 'peon' ? ingresoPeon(sueldo) : null;
  const ingresoDe = (seccion) => (perfil ? ingresoPerfil(perfil, seccion) : fijo);
  const m2Serie = serie('alquiler_m2');
  return {
    ficha,
    series: [m2Serie],
    ingreso: (seccion) => ingresoDe(seccion) || null,
    calcular(seccion, x) {
      const m2 = x(m2Serie);
      const ingreso = ingresoDe(seccion);
      if (m2 === null || !ingreso) return null;
      const alquiler = m2 * superficie;
      return { alquiler, ingreso, ratio: alquiler / ingreso };
    },
    expresion(idSeccion) {
      const ingreso = perfil ? expresionIngresoPerfil(perfil, idSeccion) : fijo;
      return {
        valido: ['all', ['!', falta(m2Serie)], ['>', ingreso, 0]],
        ratio: ['/', ['*', numero(m2Serie), superficie], ingreso],
      };
    },
  };
}

// Tramo de «¿te llega?»: 0 hasta el 30 %, 1 del 30 al 40 %, 2 más del 40 %.
export const tramoLlega = (ratio) => (ratio <= LIMITES_LLEGA[0] ? 0 : ratio <= LIMITES_LLEGA[1] ? 1 : 2);

// Intervalo de una cifra con el margen aproximado de la mediana del alquiler (en %, el que
// exporta R; plan §11, pregunta 15 ampliada): cifra × (1 ± margen). Vale para el alquiler, el
// sueldo necesario y la proporción de «¿te llega?», que son el alquiler en otra unidad. Sin
// cifra o sin margen, null.
export function intervaloMargen(valor, margenPct) {
  if (valor === null || valor === undefined || !Number.isFinite(valor)) return null;
  if (margenPct === null || margenPct === undefined || !Number.isFinite(margenPct) || margenPct < 0) return null;
  return { desde: valor * (1 - margenPct / 100), hasta: valor * (1 + margenPct / 100) };
}

// «En el límite entre dos tramos» de «¿te llega?»: el intervalo de la proporción cruza el corte
// del 30 o del 40 %. Los tramos son fijos: no cambian con el umbral elegido.
export function enLimiteLlega(ratio, margenPct) {
  const i = intervaloMargen(ratio, margenPct);
  return i !== null && tramoLlega(i.desde) !== tramoLlega(i.hasta);
}

// Estado de «¿te llega?» (indicador 15): el del alquiler; si falta el ingreso de la ficha, el de
// «ausente» (pregunta 15 ampliada: la calidad del ingreso no rebaja cada cifra).
export const estadoLlega = (estadoAlquiler, ingreso, ausente) => (ingreso === null || ingreso === undefined ? ausente : estadoAlquiler);

export function colorLlega(calculo, idSeccion, colores) {
  const { valido, ratio } = calculo.expresion(idSeccion);
  return ['case', ['!', valido], colores.fuera,
    ['<=', ratio, LIMITES_LLEGA[0]], colores.llega[0],
    ['<=', ratio, LIMITES_LLEGA[1]], colores.llega[1],
    colores.llega[2]];
}

// Sueldo necesario por tramos: un tramo más que cortes (seis con los del indicador 21), cada uno
// con su paso de la rampa (colores.js).
export function colorNecesario(mapaDef, supuestos, colores) {
  const valor = formulaDe(mapaDef).expresion(numero(mapaDef.base), supuestos);
  const color = pasosDeRampa(mapaDef.cortes.length + 1, colores.rampa.length).map((i) => colores.rampa[i]);
  const pasos = ['step', valor, color[0]];
  mapaDef.cortes.forEach((corte, i) => pasos.push(corte, color[i + 1]));
  return ['case', falta(mapaDef.base), colores.fuera, pasos];
}

// Proporción de secciones con dato donde el alquiler cabe por debajo del umbral.
export function resumenLlega(calculo, secciones, x, umbral) {
  let con = 0;
  let caben = 0;
  for (let i = 0; i < secciones.length; i++) {
    const r = calculo.calcular(secciones[i], (serie) => x(serie, i));
    if (!r) continue;
    con++;
    if (r.ratio <= umbral) caben++;
  }
  return { con, caben, proporcion: con ? caben / con : null };
}

// Posición (0–1) de un valor en la regla de la leyenda: tramos de igual anchura entre los
// cortes; el primero y el último, tan anchos como su vecino. Fuera de la regla, en su borde.
export function posicionEnRegla(valor, cortes) {
  const tramos = cortes.length + 1;
  const bordes = [2 * cortes[0] - cortes[1], ...cortes, 2 * cortes.at(-1) - cortes.at(-2)];
  if (valor <= bordes[0]) return 0;
  if (valor >= bordes.at(-1)) return 1;
  let k = 0;
  while (valor > bordes[k + 1]) k++;
  return (k + (valor - bordes[k]) / (bordes[k + 1] - bordes[k])) / tramos;
}

// Cuantil p (0–1) de los valores no nulos, con interpolación lineal.
export function cuantil(valores, p) {
  const v = valores.filter((x) => x !== null && Number.isFinite(x)).sort((a, b) => a - b);
  if (!v.length) return null;
  const h = (v.length - 1) * p;
  const i = Math.floor(h);
  return i + 1 < v.length ? v[i] + (h - i) * (v[i + 1] - v[i]) : v[i];
}

// Marcas de la regla del sueldo necesario: las fichas de una persona en su ingreso (con la
// provincia de la sección elegida o, si no hay, la mediana de las provincias) y la llave como
// tramo (del cuartil 1 al 3 de la renta del hogar ÷ 12 en las secciones con dato).
export function marcasRegla({ perfiles, seccion, rentaHogar }) {
  const marcas = [];
  for (const ficha of FICHAS_PERFIL) {
    const perfil = perfiles?.[ficha];
    if (!perfil || ficha === 'llave') continue;
    let valor = null;
    let mediana = false;
    if (perfil.nivel === 'provincia') {
      valor = seccion ? ingresoPerfil(perfil, seccion) : null;
      if (valor === null) {
        valor = cuantil(Object.values(perfil.neto_mensual ?? {}), 0.5);
        mediana = valor !== null;
      }
    } else {
      valor = ingresoPerfil(perfil, '00');
    }
    if (valor !== null) marcas.push({ ficha, valor, mediana });
  }
  let llave = null;
  if (perfiles?.llave && rentaHogar) {
    const divisor = perfiles.llave.ingreso.divisor ?? 12;
    const mensual = rentaHogar.map((x) => (x === null ? null : x / divisor));
    const desde = cuantil(mensual, 0.25);
    const hasta = cuantil(mensual, 0.75);
    if (desde !== null) llave = { desde, hasta };
  }
  return { marcas, llave };
}
