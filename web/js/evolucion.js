// Evolución de la ficha (backlog, tareas 43 y 45): gráfico de la serie del mapa con la banda del
// margen aproximado de la mediana del alquiler, variación de cada año con la regla de los contratos
// y aviso de euros corrientes con la subida del IPC del periodo.
//   - Banda: la cifra ± su margen aproximado (fiabilidad.js; el mismo intervalo de la ficha).
//   - Variación de un año: solo con 30 contratos o más en los dos años (UMBRAL_POCOS_CONTRATOS);
//     si no, la variación media anual de los tres últimos años, marcada; si tampoco hay cifra tres
//     años antes, ninguna. Sin contratos (series que no son del alquiler), la de un año.
//   - Euros corrientes: las series del atlas no se deflactan; la ficha lo dice y da la variación del
//     IPC (datos/ipc.json, medias anuales del índice general del INE) entre el primer y el último año.
// Las cuentas van sin DOM, para que las pruebas usen las mismas; el dibujo, en graficoEvolucion().

import { UMBRAL_POCOS_CONTRATOS } from './fiabilidad.js';

export const ANIOS_MEDIA = 3;
const SVG = 'http://www.w3.org/2000/svg';

const esAnio = (p) => /^\d{4}$/.test(String(p));
const numero = (x) => (x !== null && x !== undefined && Number.isFinite(x) ? x : null);

// Variación de cada periodo, en %, con la regla de los contratos (tarea 43). Una entrada por periodo:
//   { tipo: 'anual', valor }: frente al año anterior, con cifra en los dos y, si hay contratos, 30 o
//     más en los dos;
//   { tipo: 'media', valor, desde }: con menos de 30 contratos en alguno de los dos años, la variación
//     media anual desde `desde` (tres años antes): ((x / x_desde)^(1/3) − 1) × 100;
//   { tipo: 'pocos' }: pocos contratos y sin cifra tres años antes: no se da variación;
//   null: primer periodo, sin cifra, sin el año anterior o periodos que no son años.
// `contratos`: los de cada periodo (null si no se conocen), o null si la serie no los tiene.
export function variaciones({ periodos, valores, contratos = null, umbral = UMBRAL_POCOS_CONTRATOS }) {
  const indice = new Map(periodos.map((p, i) => [String(p), i]));
  const valorDe = (anio) => {
    const i = indice.get(String(anio));
    return i === undefined ? null : numero(valores[i]);
  };
  const contratosDe = (anio) => {
    const i = indice.get(String(anio));
    return i === undefined ? null : numero(contratos?.[i]);
  };
  return periodos.map((p, i) => {
    if (!esAnio(p)) return null;
    const x = numero(valores[i]);
    const anio = Number(p);
    const antes = valorDe(anio - 1);
    if (x === null || antes === null || antes <= 0) return null;
    const suficientes = contratos === null || [anio, anio - 1].every((a) => (contratosDe(a) ?? -1) >= umbral);
    if (suficientes) return { tipo: 'anual', valor: 100 * (x / antes - 1) };
    const lejos = valorDe(anio - ANIOS_MEDIA);
    if (lejos === null || lejos <= 0) return { tipo: 'pocos' };
    return { tipo: 'media', valor: 100 * ((x / lejos) ** (1 / ANIOS_MEDIA) - 1), desde: anio - ANIOS_MEDIA };
  });
}

// Banda de cada periodo: { desde, hasta } = cifra × (1 ∓ margen / 100), o null sin cifra o sin margen.
export function bandaMargen(valores, margenes) {
  return valores.map((v, i) => {
    const x = numero(v);
    const m = numero(margenes?.[i]);
    return x === null || m === null || m < 0 ? null : { desde: x * (1 - m / 100), hasta: x * (1 + m / 100) };
  });
}

// Periodos con pocos contratos (menos del umbral), donde hay cifra: el gráfico los pinta huecos.
export function pocosContratos(valores, contratos, umbral = UMBRAL_POCOS_CONTRATOS) {
  return valores.map((v, i) => numero(v) !== null && numero(contratos?.[i]) !== null && contratos[i] < umbral);
}

// Variación del IPC (datos/ipc.json: { anios, indice }) entre dos años, en %; null si falta alguno.
export function variacionIpc(ipc, desde, hasta) {
  if (!ipc?.anios || !ipc?.indice || !esAnio(desde) || !esAnio(hasta) || Number(desde) >= Number(hasta)) return null;
  const de = (a) => numero(ipc.indice[ipc.anios.findIndex((x) => Number(x) === Number(a))]);
  const a = de(desde);
  const b = de(hasta);
  return a === null || b === null || a <= 0 ? null : { desde: Number(desde), hasta: Number(hasta), valor: 100 * (b / a - 1) };
}

// --- Euros constantes (decisión del autor, 12-nov-2026) ------------------------------------------
// Las series en euros se ofrecen de dos maneras: «Euros de {año base}» (constantes) y «Euros de cada
// año» (corrientes). Año base: el último con media anual del IPC (datos/ipc.json: anio_base, o el
// último año con índice). Cada periodo va con la media anual de su año (un trimestre, con la de su
// año); los años sin media anual (antes del primero del índice, 2002, y el año en curso) se quedan
// fuera de la versión constante (null). La misma cuenta en R: ipc_deflactar() (R/fuente_ine_ipc.R).
export const EUROS = ['constantes', 'corrientes'];

export function anioBaseIpc(ipc) {
  if (!ipc?.anios || !ipc?.indice) return null;
  const con = ipc.anios.filter((a, i) => numero(ipc.indice[i]) !== null).map(Number);
  if (!con.length) return null;
  const ultimo = Math.max(...con);
  return Number.isInteger(ipc.anio_base) && con.includes(ipc.anio_base) ? ipc.anio_base : ultimo;
}

// Índice (media anual) de un año, o null.
export function indiceIpc(ipc, anio) {
  if (!ipc?.anios || !ipc?.indice) return null;
  const i = ipc.anios.findIndex((x) => Number(x) === Number(anio));
  return i < 0 ? null : numero(ipc.indice[i]);
}

// Año de un periodo: «2024», «2024-T2», «2024-02» → 2024; null si no empieza por un año.
export const anioDePeriodo = (p) => (/^\d{4}/.test(String(p)) ? Number(String(p).slice(0, 4)) : null);

// Valor en euros del año base: x × índice del año base / índice de su año; null sin índice.
export function deflactar(x, anio, ipc, base = anioBaseIpc(ipc)) {
  const v = numero(x);
  const ia = indiceIpc(ipc, anio);
  const ib = indiceIpc(ipc, base);
  return v === null || ia === null || ib === null || ia <= 0 ? null : (v * ib) / ia;
}

// Valores de una serie por periodos en euros del año base (null donde no hay índice).
export const deflactarSerie = (periodos, valores, ipc, base = anioBaseIpc(ipc)) =>
  valores.map((x, i) => deflactar(x, anioDePeriodo(periodos[i]), ipc, base));

// ¿Es una cifra en euros? Por su unidad («€ por mes», «€ netos por mes»…), en los dos idiomas.
export const enEuros = (unidad) => typeof unidad === 'string' && unidad.includes('€');

// Variación con su signo: «+4,2 %», «−0,8 %» (t.porcentaje redondea a una décima).
export function textoVariacion(t, valor) {
  if (numero(valor) === null) return '';
  const signo = valor > 0.05 ? '+' : valor < -0.05 ? '−' : '';
  return `${signo}${t.porcentaje(Math.abs(valor) / 100)}`;
}

// Texto de la columna de variación y la marca de cada tipo: la media de tres años lleva «†».
export function textosVariacion(t, lista) {
  return lista.map((v) => {
    if (!v) return '';
    if (v.tipo === 'pocos') return '—';
    return v.tipo === 'media' ? `${textoVariacion(t, v.valor)} †` : textoVariacion(t, v.valor);
  });
}

// Notas al pie de la evolución: la banda, los puntos huecos, la regla de las variaciones (solo las
// que salen) y los euros, corrientes o del año base, con el IPC del periodo. `euros`: 'cifra' (la
// serie está en euros), 'resto' (en «¿te llega?», los euros que quedan) o null. `unidad`:
// 'corrientes' o 'constantes' (solo con euros 'cifra'); `base`, el año base; `fuera`, los periodos
// sin media anual del IPC, que la versión constante deja fuera.
export function notasEvolucion(t, { banda = false, pocos = false, umbral = UMBRAL_POCOS_CONTRATOS, lista = [], euros = null, ipc = null,
  unidad = 'corrientes', base = null, fuera = [] }) {
  const notas = [];
  if (banda) notas.push(t('interfaz.ficha.evolucion_banda'));
  if (pocos) notas.push(t('interfaz.ficha.evolucion_pocos', { umbral: t.numero(umbral) }));
  if (lista.some((v) => v?.tipo === 'media')) notas.push(t('interfaz.ficha.variacion_media', { umbral: t.numero(umbral), anios: t.numero(ANIOS_MEDIA) }));
  if (lista.some((v) => v?.tipo === 'pocos')) notas.push(t('interfaz.ficha.variacion_pocos', { umbral: t.numero(umbral) }));
  if (euros === 'cifra' && unidad === 'constantes' && base) {
    const partes = [t('interfaz.ficha.euros_constantes', { anio: base })];
    if (fuera.length) partes.push(t('interfaz.ficha.euros_sin_ipc', { periodos: fuera.map((p) => t.periodo(p)).join(', '), anio: base }));
    if (ipc) partes.push(t('interfaz.ficha.ipc_periodo', { desde: ipc.desde, hasta: ipc.hasta, variacion: textoVariacion(t, ipc.valor) }));
    notas.push(partes.join(' '));
  } else if (euros) {
    const partes = [t(euros === 'resto' ? 'interfaz.ficha.euros_corrientes_resto' : 'interfaz.ficha.euros_corrientes')];
    if (ipc) partes.push(t('interfaz.ficha.ipc_periodo', { desde: ipc.desde, hasta: ipc.hasta, variacion: textoVariacion(t, ipc.valor) }));
    notas.push(partes.join(' '));
  }
  return notas;
}

// Geometría del gráfico, sin DOM: posición de cada periodo, tramos de la línea y de la banda (se
// cortan donde falta la cifra) y marcas del eje vertical. Periodos repartidos a la misma distancia.
export function geometriaEvolucion({ valores, banda = [], ancho = 300, alto = 132, margen = { izq: 46, der: 10, arr: 10, aba: 22 } }) {
  const n = valores.length;
  const todos = [...valores.map(numero), ...banda.flatMap((b) => (b ? [b.desde, b.hasta] : []))].filter((x) => x !== null);
  if (n < 2 || valores.filter((x) => numero(x) !== null).length < 2) return null;
  let min = Math.min(...todos);
  let max = Math.max(...todos);
  if (max - min < 1e-9) { min -= 1; max += 1; }
  const marcas = marcasEje(min, max);
  min = Math.min(min, marcas[0]);
  max = Math.max(max, marcas.at(-1));
  const x = (i) => margen.izq + (n === 1 ? 0 : (i * (ancho - margen.izq - margen.der)) / (n - 1));
  const y = (v) => alto - margen.aba - ((v - min) * (alto - margen.arr - margen.aba)) / (max - min);
  const r = (z) => Math.round(z * 10) / 10;
  // Tramos contiguos con cifra (o con banda)
  const tramos = (tiene) => {
    const lista = [];
    let actual = [];
    for (let i = 0; i < n; i++) {
      if (tiene(i)) actual.push(i);
      else if (actual.length) { lista.push(actual); actual = []; }
    }
    if (actual.length) lista.push(actual);
    return lista;
  };
  const lineas = tramos((i) => numero(valores[i]) !== null)
    .map((t) => t.map((i, k) => `${k ? 'L' : 'M'}${r(x(i))},${r(y(valores[i]))}`).join(''));
  const bandas = tramos((i) => Boolean(banda[i]))
    .map((t) => {
      const arriba = t.map((i, k) => `${k ? 'L' : 'M'}${r(x(i))},${r(y(banda[i].hasta))}`).join('');
      const abajo = [...t].reverse().map((i) => `L${r(x(i))},${r(y(banda[i].desde))}`).join('');
      // Un solo periodo con banda: un trazo vertical con algo de ancho
      return t.length === 1 ? `M${r(x(t[0]) - 3)},${r(y(banda[t[0]].hasta))}h6V${r(y(banda[t[0]].desde))}h-6Z` : `${arriba}${abajo}Z`;
    });
  return {
    ancho, alto, margen,
    xs: valores.map((_, i) => r(x(i))),
    ys: valores.map((v) => (numero(v) === null ? null : r(y(v)))),
    lineas, bandas,
    marcas: marcas.map((v) => ({ valor: v, y: r(y(v)) })),
  };
}

// Tres o cuatro marcas «redondas» que cubren [min, max].
export function marcasEje(min, max, n = 3) {
  const paso0 = (max - min) / (n - 1 || 1);
  const potencia = 10 ** Math.floor(Math.log10(paso0 || 1));
  const paso = [1, 2, 2.5, 5, 10].map((f) => f * potencia).find((p) => p >= paso0) ?? 10 * potencia;
  const desde = Math.floor(min / paso) * paso;
  const marcas = [];
  for (let v = desde; v <= max + paso * 1e-9; v += paso) marcas.push(Math.round(v * 1e6) / 1e6);
  if (marcas.at(-1) < max) marcas.push(Math.round((marcas.at(-1) + paso) * 1e6) / 1e6);
  return marcas;
}

const nodo = (etiqueta, atributos = {}, texto = null) => {
  const e = document.createElementNS(SVG, etiqueta);
  for (const [k, v] of Object.entries(atributos)) if (v !== null && v !== undefined) e.setAttribute(k, String(v));
  if (texto !== null) e.textContent = texto;
  return e;
};

// Gráfico SVG de la evolución: banda, línea, puntos (huecos con pocos contratos; el periodo del mapa,
// más grande), marcas del eje vertical y el primer y el último periodo. `formato(v)`: el texto de una
// cifra del eje. null con menos de dos cifras.
export function graficoEvolucion({ t, periodos, valores, banda = [], pocos = [], activo = null, formato, etiqueta }) {
  const g = geometriaEvolucion({ valores, banda });
  if (!g) return null;
  const svg = nodo('svg', { class: 'evo-grafico', viewBox: `0 0 ${g.ancho} ${g.alto}`, role: 'img', 'aria-label': etiqueta });
  svg.append(nodo('title', {}, etiqueta));
  for (const m of g.marcas) {
    svg.append(nodo('line', { class: 'evo-rejilla', x1: g.margen.izq, x2: g.ancho - g.margen.der, y1: m.y, y2: m.y }));
    svg.append(nodo('text', { class: 'evo-texto-eje', x: g.margen.izq - 4, y: m.y + 3.5, 'text-anchor': 'end' }, formato(m.valor)));
  }
  for (const d of g.bandas) svg.append(nodo('path', { class: 'evo-banda', d }));
  for (const d of g.lineas) svg.append(nodo('path', { class: 'evo-linea', d }));
  valores.forEach((v, i) => {
    if (g.ys[i] === null) return;
    const clases = ['evo-punto', pocos[i] ? 'evo-punto-pocos' : '', String(periodos[i]) === String(activo) ? 'evo-punto-activo' : ''];
    const punto = nodo('circle', { class: clases.filter(Boolean).join(' '), cx: g.xs[i], cy: g.ys[i], r: String(periodos[i]) === String(activo) ? 3.6 : 2.6 });
    punto.append(nodo('title', {}, `${t.periodo(periodos[i])}: ${formato(v)}`));
    svg.append(punto);
  });
  const ultimo = periodos.length - 1;
  for (const [i, ancla] of [[0, 'start'], [ultimo, 'end']]) {
    svg.append(nodo('text', { class: 'evo-texto-eje', x: g.xs[i], y: g.alto - 6, 'text-anchor': ancla }, String(periodos[i])));
  }
  return svg;
}

// datos/ipc.json, una vez por página; null si no está (la ficha dice igual que son euros corrientes).
let ipcPedido = null;
export function cargarIpc(ruta = 'datos/ipc.json') {
  if (!ipcPedido) {
    ipcPedido = fetch(ruta).then((r) => (r.ok ? r.json() : null)).catch(() => null);
  }
  return ipcPedido;
}
