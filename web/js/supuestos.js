// Generado por generar_supuestos_js() (R/comun_supuestos.R) desde inventario/supuestos.csv: no se
// edita a mano. Supuestos de «Tu sueldo» (backlog, tarea 48): superficies en m², umbrales en %,
// tramos de «¿te llega?» como proporción del ingreso, pagas al año y sueldo máximo en euros;
// regla de «¿te llega?», líneas de ingreso residual y sus tramos en múltiplos de la línea (tarea 65).
export const SUPUESTOS = Object.freeze({
  superficies: Object.freeze([50, 70, 90]),
  superficie_una_persona: 50,
  superficie_dos_sueldos: 70,
  umbrales: Object.freeze([30, 40]),
  umbral_sueldo: 30,
  limites_llega: Object.freeze([0.3, 0.4]),
  pagas: Object.freeze([12, 14]),
  pagas_defecto: 12,
  divisor_llave: 12,
  sueldo_maximo: 100000,
  reglas_llega: Object.freeze(['porcentaje', 'residual']),
  regla_llega: 'porcentaje',
  lineas_residual: Object.freeze(['imv', 'ecv']),
  linea_residual: 'imv',
  limites_residual: Object.freeze([1.00, 1.25]),
});
