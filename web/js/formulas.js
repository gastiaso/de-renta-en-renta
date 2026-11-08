// Transformaciones que la web aplica en el navegador a un indicador base (manifiesto, «mapas»).
// Cada una tiene dos caras que deben dar lo mismo: la expresión de estilo de MapLibre, para
// colorear el mapa sin volver a descargar teselas, y el cálculo en JS, para la ficha y la leyenda.
// El manifiesto solo nombra la fórmula; aquí no se evalúa texto que venga de los datos.

export const FORMULAS = {
  // El indicador tal cual.
  directo: {
    expresion: (valor) => valor,
    calcular: (x) => x,
  },
  // Indicador 21: sueldo neto mensual necesario para que el alquiler de `superficie_m2` no pase
  // del `umbral` del sueldo. Base: alquiler mediano por m² (indicador 9).
  alquiler_m2_a_sueldo: {
    expresion: (valor, s) => ['/', ['*', valor, s.superficie_m2], s.umbral],
    calcular: (x, s) => (x * s.superficie_m2) / s.umbral,
  },
};

export function formulaDe(mapaDef) {
  const f = FORMULAS[mapaDef.formula ?? 'directo'];
  if (!f) throw new Error(`Fórmula desconocida en el manifiesto: ${mapaDef.formula}`);
  return f;
}
