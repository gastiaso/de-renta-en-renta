// Exportación de la vista, sin dependencias: CSV de la serie del mapa en el nivel que se ve y
// nombre de los ficheros (la imagen PNG, en imagen.js). Sin DOM, salvo `descargar()`, para que
// las pruebas usen las mismas cuentas.
//
// El sueldo escrito por el usuario no sale en ninguno de los dos ficheros, como con «Compartir»
// (plan, §6.6): en «¿te llega?», el CSV lleva el alquiler que usa el mapa y no la proporción
// (de la que se despejaría el sueldo), y la imagen nombra el ingreso sin la cifra.

// Redondeo a `decimales`, como el de la guía: toFixed da el decimal más cercano al número binario,
// igual que sprintf("%.1f") en R salvo en los empates exactos.
export const redondear = (x, decimales) => Number(x.toFixed(decimales));

// Decimales con que se guardan los valores (escala 10: una décima).
export const decimalesDeEscala = (escala) => Math.max(0, Math.round(Math.log10(escala ?? 10)));

// Niveles que pinta el mapa, de menos a más zoom (mapa.js, RELLENOS).
const NIVELES_MAPA = ['ccaa', 'provincia', 'municipio', 'sc'];

// Nivel del CSV: el que pinta el mapa a su escala o, si la serie no llega a él, el más fino que
// tenga (una serie solo por sección, con el mapa de toda España, sale por sección).
export function nivelParaExportar(visible, niveles) {
  const tiene = (n) => niveles.includes(n);
  const desde = Math.max(0, NIVELES_MAPA.indexOf(visible));
  return NIVELES_MAPA.slice(desde).find(tiene) ?? [...NIVELES_MAPA].reverse().find(tiene) ?? 'sc';
}

// Campo de CSV (RFC 4180): entre comillas si lleva coma, comillas o salto de línea.
function campo(x) {
  const texto = x === null || x === undefined ? '' : String(x);
  return /[",\r\n]/.test(texto) ? `"${texto.replaceAll('"', '""')}"` : texto;
}

// Texto del CSV: UTF-8 con BOM (para que las hojas de cálculo lean bien las tildes), coma entre
// campos, punto decimal y CRLF entre filas.
export function textoCsv(cabecera, filas) {
  return `﻿${[cabecera, ...filas].map((fila) => fila.map(campo).join(',')).join('\r\n')}\r\n`;
}

const COLUMNAS = ['codigo', 'nombre', 'nivel', 'indicador', 'tipologia', 'periodo', 'valor', 'unidad', 'estado', 'fuente'];

// Tabla de una serie en un nivel: una fila por territorio, en el orden del índice.
//   codigos, valores, estados: los del nivel (datos.js, cargarValores);
//   nombresEstado: codificacion.estados del manifiesto;
//   transformar(x): la fórmula del mapa (sueldo necesario) o nada;
//   supuestos: { superficie_m2, umbral } si la fórmula los usa (dos columnas más);
//   desde: con un año anterior a toda la serie (`periodo`), su primer periodo; las filas van sin
//   valor y el estado dice desde cuándo hay serie (pregunta abierta 32);
//   fiabilidad: { contratos, margen }, los valores de las series auxiliares del alquiler en el
//   mismo nivel y periodo (o null), si la serie los tiene: dos columnas más, contratos y
//   margen_pct (preguntas 12 y 15 ampliadas). Un territorio sin recuento o sin margen, vacío;
//   etiqueta: F5, el texto de dato privado de la serie (portales, indicador 13), en una columna más
//   en todas las filas; categoria(x): F5, el texto de cada valor en los mapas de categorías
//   (indicador 20), en una columna más.
// Los textos (cabecera, nivel, indicador…) llegan ya traducidos, salvo los que pide `t`.
export function tablaCsv({ t, codigos, valores, estados, nombresEstado, nivel, nombreDe, indicador, unidad, tipologia, periodo, fuente, transformar, decimales, supuestos, desde = null, fiabilidad = null, etiqueta = null, categoria = null }) {
  const columnas = [...COLUMNAS, ...(fiabilidad ? ['contratos', 'margen_pct'] : []), ...(supuestos ? ['superficie_m2', 'umbral'] : []),
    ...(categoria ? ['categoria'] : []), ...(etiqueta ? ['etiqueta'] : [])];   // F5
  const cabecera = columnas.map((c) => t(`interfaz.exportar.columnas.${c}`));
  const textoNivel = t(`vocabulario.nivel.${nivel}`);
  const fuera = desde === null ? null : t('interfaz.exportar.estados.fuera', { desde });
  const de = (lista, i) => (fuera || !lista ? null : lista[i] ?? null);
  const filas = codigos.map((codigo, i) => {
    const x = fuera ? null : valores[i];
    const valor = x === null || x === undefined ? null : redondear(transformar ? transformar(x) : x, decimales);
    const fila = [codigo, nombreDe(codigo), textoNivel, indicador, tipologia ?? '', periodo, valor, unidad,
      fuera ?? t(`interfaz.exportar.estados.${nombresEstado[estados[i]]}`), fuente];
    if (fiabilidad) {
      const n = de(fiabilidad.contratos, i);
      const margen = de(fiabilidad.margen, i);
      fila.push(n === null ? null : Math.round(n), margen === null ? null : redondear(margen, 1));
    }
    if (supuestos) fila.push(supuestos.superficie_m2, supuestos.umbral);
    if (categoria) fila.push(valor === null ? null : categoria(valor));   // F5
    if (etiqueta) fila.push(etiqueta);                                    // F5
    return fila;
  });
  return { cabecera, filas };
}

// Nombre del fichero: el mapa, «vu» si es la vivienda unifamiliar, el periodo y, en el CSV, el
// nivel («de-renta-en-renta_sueldo_necesario_2024_municipio.csv»).
export function nombreFichero({ mapa, periodo, tipologia, nivel, extension }) {
  const partes = ['de-renta-en-renta', mapa, tipologia === 'VU' ? 'vu' : null, periodo, nivel];
  return `${partes.filter((p) => p !== null && p !== undefined && p !== '').join('_').replace(/[^\w-]/g, '-')}.${extension}`;
}

// Descarga un Blob con un nombre de fichero (enlace temporal con «download»).
export function descargar(blob, nombre) {
  const url = URL.createObjectURL(blob);
  const enlace = document.createElement('a');
  enlace.href = url;
  enlace.download = nombre;
  document.body.append(enlace);
  enlace.click();
  enlace.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
}
