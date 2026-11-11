// Escala relativa al municipio (decisión del autor, 11-nov-2026; backlog, tarea 51): con los cortes
// nacionales, el centro de Madrid y el de Barcelona caen casi enteros en el tramo más alto. La
// leyenda ofrece, a escala de sección, pintar las secciones con los septiles de las de un municipio
// en el año y la serie que se ven, calculados en la página. Sin DOM, para que las pruebas usen las
// mismas cuentas (pruebas/web/escala_municipio.test.mjs).
//
//   - Por defecto, la escala nacional (los juegos de cortes del manifiesto: comparabilidad).
//   - Solo a escala de sección, en el modo «necesario» y en los mapas con juego de cortes de la
//     sección: no en las viviendas turísticas, la zona tensionada ni la sobrecarga (sin juegos), ni
//     en los mapas sin sección, ni en la capa de portales (dato privado de oferta).
//   - Manda el municipio de la ficha abierta (el de la sección, o el municipio elegido); sin ficha de
//     sección ni de municipio, el del centro de la vista, que cambia al mover el mapa.
//   - Con menos de MINIMO_SECCIONES_RELATIVA secciones con dato (dos por tramo), no se ofrece.
//   - Fuera del municipio, las secciones quedan sin color (el de la placa).
//   - Cortes redondeados a un paso «redondo» (1, 2, 2,5 o 5 por una potencia de 10), el mayor que no
//     pase de la mitad del hueco más estrecho entre cortes ni de la cuarta parte del hueco mediano (lo
//     que sea mayor) y deje los cortes en orden estricto.

import { cuantil } from './sueldo.js';

export const TRAMOS_RELATIVA = 7;
export const MINIMO_SECCIONES_RELATIVA = 2 * TRAMOS_RELATIVA;   // 14
const FACTORES = [5, 2.5, 2, 1];

// ¿Admite el mapa la escala relativa? `modo`: 'necesario' o 'llega'; `nivelMinimo`: el del mapa
// ('sc' si tiene sección); `privado`: lleva etiqueta de dato privado (portales).
export function admiteRelativa(mapaDef, { modo = 'necesario', nivelMinimo = 'sc', privado = false } = {}) {
  return modo === 'necesario' && (nivelMinimo ?? 'sc') === 'sc' && !privado && !mapaDef?.categorias &&
    Array.isArray(mapaDef?.juegos?.seccion?.cortes);
}

// Municipio que manda: el de la sección de la ficha, el municipio elegido o, si no, el del centro.
export function municipioQueManda({ seccion = null, territorio = null, centro = null } = {}) {
  if (/^\d{10}$/.test(seccion ?? '')) return seccion.slice(0, 5);
  if (territorio?.nivel === 'municipio' && /^\d{5}$/.test(territorio.codigo ?? '')) return territorio.codigo;
  return /^\d{5}$/.test(centro ?? '') ? centro : null;
}

// Cortes de `tramos` cuantiles iguales (septiles con siete), sin redondear.
export function cuantilesCortes(valores, tramos = TRAMOS_RELATIVA) {
  return Array.from({ length: tramos - 1 }, (_, k) => cuantil(valores, (k + 1) / tramos));
}

// Decimales de un paso redondo (2,5 → 1; 0,25 → 2; 50 → 0).
const decimalesDe = (paso) => {
  for (let d = 0; d < 12; d++) if (Math.abs(Math.round(paso * 10 ** d) - paso * 10 ** d) < 1e-9) return d;
  return 12;
};

// Cortes redondeados a un paso redondo, sin pasar de los `decimales` del mapa: el mayor paso que no
// pase de la mitad del hueco más estrecho entre cortes ni de la cuarta parte del hueco mediano (lo que
// sea mayor: un solo hueco estrecho no obliga a cifras sin redondear) y deje los cortes en orden
// estricto. Los cortes repetidos (muchas secciones con la misma cifra) se quitan antes: menos tramos.
export function redondearCortes(cortes, decimales = 0) {
  const limpios = [...new Set(cortes.filter(Number.isFinite))].sort((a, b) => a - b);
  if (!limpios.length) return [];
  const dec = Math.max(0, decimales);
  const minimo = 10 ** -dec;
  const huecos = limpios.slice(1).map((c, i) => c - limpios[i]).sort((a, b) => a - b);
  const referencia = huecos.length ? Math.max(huecos[0] / 2, huecos[Math.floor((huecos.length - 1) / 2)] / 4) : Infinity;
  const enOrden = (x) => x.every((c, i) => i === 0 || c > x[i - 1]);
  const redondear = (paso) => {
    const d = decimalesDe(paso);
    return limpios.map((c) => Number((Math.round(c / paso) * paso).toFixed(d)));
  };
  const tope = Number.isFinite(referencia) ? referencia : Math.max(...limpios.map(Math.abs), minimo);
  for (let e = Math.floor(Math.log10(Math.max(tope, minimo))); e >= -dec; e--) {
    for (const f of FACTORES) {
      const paso = Number((f * 10 ** e).toPrecision(6));
      if (paso > tope || paso < minimo || decimalesDe(paso) > dec) continue;
      const x = redondear(paso);
      if (enOrden(x)) return x;
    }
  }
  return [...new Set(redondear(minimo))];
}

// Cortes relativos de un municipio: { n, cortes } con los septiles redondeados de sus `valores` (en
// la unidad del mapa); con menos de `minimo` valores, cortes null.
export function cortesRelativos(valores, { decimales = 0, minimo = MINIMO_SECCIONES_RELATIVA, tramos = TRAMOS_RELATIVA } = {}) {
  const v = valores.filter((x) => x !== null && x !== undefined && Number.isFinite(x));
  if (v.length < minimo) return { n: v.length, cortes: null };
  return { n: v.length, cortes: redondearCortes(cuantilesCortes(v, tramos), decimales) };
}

// Secciones por tramo con unos cortes (como el `step` del mapa: un valor igual a un corte va al tramo de arriba).
export function reparto(valores, cortes) {
  const cuenta = new Array(cortes.length + 1).fill(0);
  for (const x of valores) {
    if (x === null || x === undefined || !Number.isFinite(x)) continue;
    cuenta[cortes.filter((c) => x >= c).length]++;
  }
  return cuenta;
}

// Expresión de MapLibre: dentro del municipio, la de siempre (`dentro`); fuera, `fueraColor`.
// `idSeccion`: la propiedad con el código de la sección en las teselas.
export function soloEnMunicipio(dentro, { municipio, idSeccion, fueraColor }) {
  return ['case', ['==', ['slice', ['to-string', ['get', idSeccion]], 0, 5], municipio], dentro, fueraColor];
}
