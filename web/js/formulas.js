// Transformaciones que la web aplica en el navegador a un indicador base (manifiesto, «mapas»).
// Cada una tiene dos caras que deben dar lo mismo: la expresión de estilo de MapLibre, para
// colorear el mapa sin volver a descargar teselas, y el cálculo en JS, para la ficha y la leyenda.
// El manifiesto solo nombra la fórmula; aquí no se evalúa texto que venga de los datos. Las que dan
// un sueldo llevan `sueldo`; las que usan la superficie elegida, `superficie`.

// Otros gastos de vivienda (decisión del autor, 12-nov-2026): las dos fórmulas del sueldo necesario
// suman al alquiler `s.otros` si lo hay (la cifra del territorio, supuestosEn() de sueldo.js; en el
// mapa, una expresión de MapLibre, colorNecesario()). Sin `otros`, como antes.
const otrosDe = (s) => (Number.isFinite(s?.otros) ? s.otros : 0);
const masOtros = (valor, s) => (s?.otros === undefined || s?.otros === null || s?.otros === 0 ? valor : ['+', valor, s.otros]);

export const FORMULAS = {
  // El indicador tal cual.
  directo: {
    expresion: (valor) => valor,
    calcular: (x) => x,
  },
  // Indicador 21, cifra principal (decisión 4; tarea 40): sueldo neto mensual necesario para que el
  // alquiler mensual mediano real de la sección no pase del `umbral` del sueldo. Base: alquiler
  // mensual mediano (indicador 8). No usa la superficie.
  alquiler_mes_a_sueldo: {
    sueldo: true,
    expresion: (valor, s) => ['/', masOtros(valor, s), s.umbral],
    calcular: (x, s) => (x + otrosDe(s)) / s.umbral,
  },
  // Indicador 21, mínimo teórico (al lado de la cifra principal; tarea 40): sueldo neto mensual
  // necesario para que el alquiler de `superficie_m2` no pase del `umbral` del sueldo. Base:
  // alquiler mediano por m² (indicador 9).
  alquiler_m2_a_sueldo: {
    sueldo: true,
    superficie: true,
    expresion: (valor, s) => ['/', masOtros(['*', valor, s.superficie_m2], s), s.umbral],
    calcular: (x, s) => (x * s.superficie_m2 + otrosDe(s)) / s.umbral,
  },
};

export function formulaDe(mapaDef) {
  const f = FORMULAS[mapaDef.formula ?? 'directo'];
  if (!f) throw new Error(`Fórmula desconocida en el manifiesto: ${mapaDef.formula}`);
  return f;
}

// ¿Da el mapa un sueldo (el indicador 21, con cualquiera de sus dos cifras)?
export const daSueldo = (mapaDef) => Boolean(mapaDef && formulaDe(mapaDef).sueldo);

// Tarea 40: el mínimo teórico de un mapa (`minimo` del manifiesto: { base, formula }), calculado con
// la superficie y el umbral elegidos. `x(serie)` da el valor de una serie; `serie(nombre)`, la de la
// tipología elegida. null sin `minimo` o sin dato.
export function minimoDe(mapaDef, x, supuestos, serie = (s) => s) {
  const def = mapaDef?.minimo;
  if (!def) return null;
  const base = x(serie(def.base));
  return base === null || base === undefined || !Number.isFinite(base) ? null : formulaDe(def).calcular(base, supuestos);
}

// Texto de los supuestos de un mapa que los usa (leyenda, ficha, comparador e imagen): con el mínimo
// al lado (el sueldo necesario; tarea 40), «Alquiler mediano de la sección · umbral del 30 %» y la
// superficie del mínimo; si no, la superficie y el umbral. Sin supuestos (los «directo»), null.
// Con los otros gastos de vivienda encendidos (supuestos.gastos), lo dice con su cifra: la del
// territorio (`otros`, supuestosEn() de sueldo.js) o, sin territorio, la horquilla de las comunidades.
// `otros`: otro texto para esa cifra (el comparador da la de sus dos columnas).
export function textoSupuestos(t, mapaDef, supuestos, otros = textoOtrosGastos(t, supuestos)) {
  if ((mapaDef?.formula ?? 'directo') === 'directo') return null;
  const umbral = t.porcentaje(supuestos.umbral);
  const sufijo = otros ? '_gastos' : '';
  if (mapaDef.minimo) return t(`interfaz.leyenda.supuestos_real${sufijo}`, { umbral, superficie: t.numero(supuestos.superficie_m2), otros });
  return t(`interfaz.leyenda.supuestos${sufijo}`, { superficie: t.numero(supuestos.superficie_m2), umbral, otros });
}

// Texto de los otros gastos de vivienda de unos supuestos (null si están apagados): con territorio,
// «149 € al mes en Aragón, ECV 2024», o la cifra de España si su muestra no llega; sin él, «de 114
// a 161 € al mes según la comunidad, ECV 2024». Lo usan la leyenda, la ficha, la imagen y «Tu sueldo».
export function textoOtrosGastos(t, supuestos) {
  const g = supuestos?.gastos;
  if (!g) return null;
  const anio = g.anio_ecv;
  const euros = (x) => t.numero(Math.round(x));
  const nombre = (c) => (c === '00' ? t('vocabulario.nivel.nacional') : g.nombres?.[c] ?? c);
  const de = supuestos.otros_de;
  if (de && Number.isFinite(supuestos.otros)) {
    if (de.espana) {
      return t('interfaz.leyenda.otros_gastos_espana', { euros: euros(supuestos.otros), territorio: nombre(de.ccaa), minimo: t.numero(g.minimo ?? 0), anio });
    }
    return t('interfaz.leyenda.otros_gastos', { euros: euros(supuestos.otros), territorio: nombre(de.ccaa), anio });
  }
  const v = Object.values(g.ccaa ?? {}).map((x) => x.v).filter(Number.isFinite);
  if (!v.length) return t('interfaz.leyenda.otros_gastos', { euros: euros(g.espana.v), territorio: nombre('00'), anio });
  return t('interfaz.leyenda.otros_gastos_rango', { desde: euros(Math.min(...v)), hasta: euros(Math.max(...v)), anio });
}
