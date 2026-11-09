// Fiabilidad de la mediana del alquiler en la ficha (plan §11, preguntas 12 y 15 ampliadas;
// docs/especificacion_contratos_margen.md). Sin DOM, para que las pruebas usen las mismas cuentas.
//
// El manifiesto liga cada serie de alquiler (y las que salen de ella: sueldo necesario,
// esfuerzo) con dos series auxiliares de su misma tipología: `fiabilidad`: {"contratos":
// "contratos_alquiler", "margen": "margen_alquiler_m2"}. Los contratos son el recuento de
// testigos del SERPAVI (0 incluido); el margen, el error típico aproximado de la mediana en %
// (R/fuente_mivau_serpavi.R, margen_mediana()), redondeado a una décima como lo exporta R.

// Por debajo, «pocos contratos». El manifiesto trae el de R (umbral_pocos_contratos).
export const UMBRAL_POCOS_CONTRATOS = 30;

// Series de fiabilidad de una serie: { contratos, margen } o null.
export const seriesFiabilidad = (m, serie) => m?.indicadores?.[serie]?.fiabilidad ?? null;

export const umbralPocos = (m) => (Number.isFinite(m?.umbral_pocos_contratos) ? m.umbral_pocos_contratos : UMBRAL_POCOS_CONTRATOS);

// Qué dice la ficha de la mediana de una sección:
//   { tipo: 'mediana', contratos, margen, pocos }: hay mediana (dato o estimado); `margen`, null si no hay;
//   { tipo: 'secreto', contratos }: de 1 a 9 contratos, la fuente no publica la mediana;
//   { tipo: 'sin_contratos' }: 0 contratos de alquiler registrados (no «sin dato»);
//   null: sin recuento (sin dato) o sin series de fiabilidad.
// `estado`: el nombre del estado de la mediana (codificacion.estados).
export function fiabilidadFicha({ contratos, margen = null, estado, umbral = UMBRAL_POCOS_CONTRATOS }) {
  if (contratos === null || contratos === undefined || !Number.isFinite(contratos)) return null;
  if (estado === 'dato' || estado === 'estimado') {
    return { tipo: 'mediana', contratos, margen: Number.isFinite(margen) ? margen : null, pocos: contratos < umbral };
  }
  if (contratos === 0) return { tipo: 'sin_contratos' };
  if (estado === 'secreto') return { tipo: 'secreto', contratos };
  return null;
}
