// Transformaciones que la web aplica en el navegador a un indicador base (manifiesto, «mapas»).
// Cada una tiene dos caras que deben dar lo mismo: la expresión de estilo de MapLibre, para
// colorear el mapa sin volver a descargar teselas, y el cálculo en JS, para la ficha y la leyenda.
// El manifiesto solo nombra la fórmula; aquí no se evalúa texto que venga de los datos. Las que dan
// un sueldo llevan `sueldo`; las que usan la superficie elegida, `superficie`.

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
    expresion: (valor, s) => ['/', valor, s.umbral],
    calcular: (x, s) => x / s.umbral,
  },
  // Indicador 21, mínimo teórico (al lado de la cifra principal; tarea 40): sueldo neto mensual
  // necesario para que el alquiler de `superficie_m2` no pase del `umbral` del sueldo. Base:
  // alquiler mediano por m² (indicador 9).
  alquiler_m2_a_sueldo: {
    sueldo: true,
    superficie: true,
    expresion: (valor, s) => ['/', ['*', valor, s.superficie_m2], s.umbral],
    calcular: (x, s) => (x * s.superficie_m2) / s.umbral,
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
export function textoSupuestos(t, mapaDef, supuestos) {
  if ((mapaDef?.formula ?? 'directo') === 'directo') return null;
  const umbral = t.porcentaje(supuestos.umbral);
  if (mapaDef.minimo) return t('interfaz.leyenda.supuestos_real', { umbral, superficie: t.numero(supuestos.superficie_m2) });
  return t('interfaz.leyenda.supuestos', { superficie: t.numero(supuestos.superficie_m2), umbral });
}
