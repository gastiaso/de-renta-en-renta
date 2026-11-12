// Percentil salarial del sueldo necesario (F3; R/percentil_salarial.R): posición de un neto mensual
// en la distribución de los salarios de su comunidad y año (datos/salarios.json: lo cobrado en el
// año por los asalariados según la AEAT, neto y repartido en 12), por interpolación lineal entre
// los percentiles 1 a 99. País Vasco y Navarra, que la AEAT no cubre (y Ceuta y Melilla en 2020 y
// 2021), no tienen curva propia: la de España («00»). De 2015 a 2025 (la web usa los años con alquiler).

// `salarios`: { percentiles: [1, …, 99], anios: { '2024': { '00': [...], '09': [...] } } }.
// Curva de una comunidad y año, o la de España si la comunidad no tiene; null si el año no tiene.
export function curvaSalarial(salarios, anio, ccaa) {
  const delAnio = salarios?.anios?.[String(anio)];
  if (!delAnio) return null;
  if (ccaa && Array.isArray(delAnio[ccaa])) return { ambito: ccaa, curva: delAnio[ccaa] };
  return Array.isArray(delAnio['00']) ? { ambito: '00', curva: delAnio['00'] } : null;
}

// Percentil de `valor` en una curva creciente: lineal entre puntos; por debajo del primero, 0; por
// encima del último, 100 (la ficha escribe «por debajo del percentil 1» y «por encima del 99»).
export function percentilEnCurva(valor, curva, percentiles) {
  if (!Number.isFinite(valor) || !curva?.length || curva.length !== percentiles?.length) return null;
  const n = curva.length;
  if (valor < curva[0]) return 0;
  if (valor > curva[n - 1]) return 100;
  for (let i = 0; i < n - 1; i += 1) {
    if (valor <= curva[i + 1]) {
      const tramo = curva[i + 1] - curva[i];
      const f = tramo > 0 ? (valor - curva[i]) / tramo : 0;
      return percentiles[i] + f * (percentiles[i + 1] - percentiles[i]);
    }
  }
  return percentiles[n - 1];
}

// Primer año con curva (para decir desde cuándo hay percentil), o null.
export function primerAnioSalarial(salarios) {
  const anios = Object.keys(salarios?.anios ?? {}).map(Number).filter(Number.isFinite);
  return anios.length ? Math.min(...anios) : null;
}

// Percentil del sueldo necesario de un territorio: `ccaa`, el código de su comunidad ('00' o
// null: España). Devuelve { percentil, ambito, anio } (ambito: código de la comunidad cuya curva
// se usa, '00' para España); { sinCurva: true, desde } si el año no tiene curva; null si no hay
// datos de salarios o valor.
export function percentilSalarial(salarios, { valor, anio, ccaa }) {
  if (!salarios?.anios || !Number.isFinite(valor)) return null;
  const c = curvaSalarial(salarios, anio, ccaa);
  if (!c) return { sinCurva: true, desde: primerAnioSalarial(salarios) };
  const p = percentilEnCurva(valor, c.curva, salarios.percentiles);
  return p === null ? null : { percentil: p, ambito: c.ambito, anio: Number(anio) };
}
