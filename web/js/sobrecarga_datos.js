// Lógica de la sección «Sobrecarga», sin DOM ni MapLibre: estado de la URL, vistas del mapa, tramos,
// bloques de «la escalera», nombres, formatos y trazado de la serie. La usan sobrecarga.js y las
// pruebas (pruebas/web/sobrecarga.test.mjs).
//
// Datos: datos/sobrecarga/sobrecarga.json, de exportar_web_sobrecarga() (R/web_sobrecarga.R). Cada
// vista del mapa (corte, grupo y año) es una lista de filas con su puesto, que el mapa pinta y la
// escalera ordena: la escalera muestra lo mismo que el mapa. Las cifras van × 10 en enteros
// (`escala`), como en el resto de la web; las del INE llevan su muestra (`n`, `hogares`) y la
// marca de fiabilidad de EU-SILC; las de Eurostat, su tabla.

export const RUTA_DATOS = 'datos/sobrecarga/sobrecarga.json';
export const CORTES = ['total', 'tenencia', 'edad'];

// Valor real de una cifra (null si no hay).
export const valorDe = (fila, escala = 10) => (fila?.v === null || fila?.v === undefined ? null : fila.v / escala);

// --- Estado de la URL: ?idioma=en&corte=tenencia&grupo=RENT_MKT&anio=2024&geo=ES30 ---------------

const GEO = /^[A-Z]{2}[A-Z0-9_]{0,7}$/;

// Lee y valida el estado contra los datos (sin datos, solo el idioma).
export function leerEstado(busqueda, datos = null) {
  const p = new URLSearchParams(busqueda);
  const estado = { idioma: p.get('idioma') === 'en' ? 'en' : 'es', corte: 'total', grupo: 'total', anio: null, geo: null };
  if (!datos) return estado;
  const corte = p.get('corte');
  const grupo = p.get('grupo');
  if (CORTES.includes(corte) && corte !== 'total' && datos.grupos_mapa?.[corte]?.includes(grupo)) {
    estado.corte = corte;
    estado.grupo = grupo;
  }
  const anio = Number(p.get('anio'));
  estado.anio = estado.corte === 'total' && datos.anios.includes(anio) ? anio : ultimoAnio(datos);
  const geo = p.get('geo');
  if (geo && GEO.test(geo)) estado.geo = geo;
  if (!vistaDe(datos, estado)) Object.assign(estado, { corte: 'total', grupo: 'total', anio: ultimoAnio(datos) });
  return estado;
}

// Consulta de la URL, sin lo que vale por defecto.
export function consulta(estado, datos) {
  const partes = [];
  if (estado.idioma === 'en') partes.push('idioma=en');
  if (estado.corte !== 'total') partes.push(`corte=${estado.corte}`, `grupo=${estado.grupo}`);
  else if (datos && estado.anio !== ultimoAnio(datos)) partes.push(`anio=${estado.anio}`);
  if (estado.geo && GEO.test(estado.geo)) partes.push(`geo=${estado.geo}`);
  return partes.length ? `?${partes.join('&')}` : '';
}

export const ultimoAnio = (datos) => Math.max(...datos.anios);

// --- Vistas -----------------------------------------------------------------------------------

// Vista del estado: toda la población, el año elegido; con tenencia o edad, el año de los desgloses.
export function vistaDe(datos, { corte = 'total', grupo = 'total', anio = null } = {}) {
  const a = corte === 'total' ? anio ?? ultimoAnio(datos) : datos.anio_desgloses;
  return datos.vistas.find((v) => v.corte === corte && v.grupo === grupo && v.anio === a) ?? null;
}

// Grupos con vista (los botones que se ofrecen).
export const gruposCon = (datos, corte) =>
  (datos.grupos_mapa?.[corte] ?? []).filter((g) => vistaDe(datos, { corte, grupo: g }));

// Filas que pinta el mapa (las referencias, UE-27 y España, no tienen geometría propia).
export const pintables = (vista) => vista.filas.filter((f) => f.bloque !== 'referencia');

// Territorios con el dato de un nivel más grueso que NUTS 2 (país o NUTS 1): van con trama.
export const conTramaGruesa = (vista) =>
  vista.corte === 'total' ? pintables(vista).filter((f) => f.nivel < 2).map((f) => f.geo) : [];

// Territorios con muestra pequeña (marca «baja» de EU-SILC): van con la trama de muestra pequeña.
export const conMuestraPequena = (vista) => pintables(vista).filter((f) => f.fiabilidad === 'baja').map((f) => f.geo);

export const referencia = (vista, geo) => vista.filas.find((f) => f.geo === geo) ?? null;

// Número de puestos de la vista (todas las filas con valor, referencias incluidas).
export const puestos = (vista) => vista.filas.filter((f) => f.puesto !== null && f.puesto !== undefined).length;

// --- Tramos -----------------------------------------------------------------------------------

export const cortesDe = (datos, grupo) => datos.cortes[grupo] ?? datos.cortes.general;

// Tramo de un valor (0 = por debajo del primer corte); null sin valor.
export function tramoDe(valor, cortes) {
  if (valor === null || valor === undefined) return null;
  let k = 0;
  while (k < cortes.length && valor >= cortes[k]) k++;
  return k;
}

// Etiquetas de la leyenda: menos de c0, c0–c1, …, cN o más. `t` da el texto y `numero` el formato.
export function etiquetasTramos(cortes, t, numero) {
  const n = (x) => numero(x, Number.isInteger(x) ? 0 : 1);
  return Array.from({ length: cortes.length + 1 }, (_, k) => {
    if (k === 0) return t('sobrecarga.leyenda.menos_de', { x: n(cortes[0]) });
    if (k === cortes.length) return t('sobrecarga.leyenda.o_mas', { x: n(cortes[k - 1]) });
    return t('sobrecarga.leyenda.entre', { a: n(cortes[k - 1]), b: n(cortes[k]) });
  });
}

// --- La escalera --------------------------------------------------------------------------------

const porPuesto = (a, b) => (a.puesto ?? Infinity) - (b.puesto ?? Infinity);

// Tres bloques, cada fila con su puesto en la lista completa: lo más alto de Europa (sin
// comunidades), las referencias (UE-27 y España) y todas las comunidades.
export function bloquesEscalera(vista, arriba = 10) {
  const de = (bloque) => vista.filas.filter((f) => f.bloque === bloque).sort(porPuesto);
  return {
    europa: de('europa').filter((f) => f.puesto !== null && f.puesto !== undefined).slice(0, arriba),
    referencias: de('referencia'),
    comunidades: de('comunidad'),
    total: puestos(vista),
  };
}

// La lista completa, por puesto (sin valor, al final).
export const escaleraCompleta = (vista) => [...vista.filas].sort(porPuesto);

// Etiqueta de cada fila: comunidad, referencia, país o región.
export function tipoDe(fila) {
  if (fila.bloque === 'comunidad') return 'comunidad';
  if (fila.bloque === 'referencia') return 'referencia';
  return fila.nivel === 0 ? 'pais' : 'region';
}

// --- Nombres y formatos -----------------------------------------------------------------------

// Nombre de un territorio: comunidades por su nombre del INE (en orden natural), países y la UE-27
// por el diccionario, regiones por el nombre de GISCO con su país entre paréntesis.
export function nombreDe(geo, datos, t, ordenNatural = (x) => x, { conPais = true } = {}) {
  const comunidad = datos.comunidades?.[geo];
  if (comunidad) return ordenNatural(comunidad.nombre);
  const clavePais = (g) => `sobrecarga.paises.${g}`;
  if (t.existe(clavePais(geo))) return t(clavePais(geo));
  const pais = geo.slice(0, 2);
  const nombrePais = t.existe(clavePais(pais)) ? t(clavePais(pais)) : pais;
  const propio = datos.nombres?.[geo];
  if (!propio) return `${nombrePais} (${geo})`;
  return conPais ? `${propio} (${nombrePais})` : propio;
}

export const porcentaje = (valor, t, decimales = 1) =>
  valor === null || valor === undefined ? '—' : t('sobrecarga.formato.porcentaje', { x: t.numero(valor, decimales) });

// --- Serie --------------------------------------------------------------------------------------

export const escalaLineal = (d0, d1, r0, r1) => (x) => r0 + ((x - d0) / (d1 - d0)) * (r1 - r0);

// Trazado SVG de una serie con huecos: cada tramo seguido de años con valor es un «M … L …».
export function trazado(anios, valores, x, y) {
  let d = '';
  let dentro = false;
  anios.forEach((a, i) => {
    const v = valores[i];
    if (v === null || v === undefined) {
      dentro = false;
      return;
    }
    d += `${dentro ? 'L' : 'M'}${x(a).toFixed(1)},${y(v).toFixed(1)}`;
    dentro = true;
  });
  return d;
}

// Posiciones verticales de las etiquetas directas de varias líneas: separadas al menos `hueco`
// píxeles, en el mismo orden y dentro de [min, max]. Devuelve una posición por etiqueta.
export function separarEtiquetas(ys, hueco, min = -Infinity, max = Infinity) {
  const orden = ys.map((y, i) => ({ y, i })).sort((a, b) => a.y - b.y);
  const pos = orden.map((o) => o.y);
  for (let k = 1; k < pos.length; k++) pos[k] = Math.max(pos[k], pos[k - 1] + hueco);
  if (pos.length && pos.at(-1) > max) pos[pos.length - 1] = max;
  for (let k = pos.length - 2; k >= 0; k--) pos[k] = Math.min(pos[k], pos[k + 1] - hueco);
  if (pos.length && pos[0] < min) {
    pos[0] = min;
    for (let k = 1; k < pos.length; k++) pos[k] = Math.max(pos[k], pos[k - 1] + hueco);
  }
  const resultado = new Array(ys.length);
  orden.forEach((o, k) => { resultado[o.i] = pos[k]; });
  return resultado;
}

// Máximo redondo para el eje: el múltiplo de `paso` que cubre todos los valores.
export function techoEje(series, paso = 10) {
  const max = Math.max(0, ...series.flat().filter((v) => v !== null && v !== undefined));
  return Math.max(paso, Math.ceil(max / paso) * paso);
}
