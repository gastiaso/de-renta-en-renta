// Máquina del tiempo (historico.html, F6): lógica sin DOM, para el navegador y para las pruebas de
// node (pruebas/web/historico.test.mjs). Datos: datos/historico/historico.json (R/web_historico.R):
// cada serie, con su frecuencia, su escala y, por territorio, el primer periodo y un vector de
// enteros (valor × escala) sin huecos de periodos (null sin cifra). La vivienda como problema
// (CIS), aparte: datos/cis_vivienda.json (R/fuente_cis_barometros.R), al final de este fichero.

import { EUROS, anioBaseIpc, deflactar } from './evolucion.js';

export const RUTA_DATOS = 'datos/historico/historico.json';
export const RUTA_IPC = 'datos/ipc.json';
export const SUBPERIODOS = { trimestral: 4, mensual: 12, anual: 1 };
export const ESPANA = '00';
// Euros constantes (decisión del autor, 12-nov-2026): las series en euros se ven en euros del año
// base del IPC (por defecto) o en euros de cada año; los demás gráficos son cocientes o tipos.
export const SERIES_EUROS = ['valor_tasado', 'sueldo_asalariado'];
export const EUROS_DEFECTO = 'constantes';

// Bloques de la página, en orden: el id es el ancla de la sección (la casilla «Sube el euríbor» de
// la portada lleva a #hist-tipos). El valor tasado se puede ver también por comunidad.
export const BLOQUES = [
  { id: 'hist-renta', series: ['anios_renta'] },
  { id: 'hist-esfuerzo', series: ['esfuerzo_teorico'] },
  // Tipos (plan §11, pregunta 47 c): el de los préstamos nuevos para vivienda, línea principal, y
  // como referencia el MIBOR hasta 1998 y el euríbor desde 1999 (índices distintos, con su ruptura)
  { id: 'hist-tipos', series: ['tipo_prestamos', 'mibor_euribor'] },
  { id: 'hist-tasado', series: ['valor_tasado'], territorial: true, euros: true },
  { id: 'hist-sueldo', series: ['sueldo_asalariado'], euros: true },
];

// Estado de la URL: idioma, comunidad del valor tasado (solo una que tenga serie) y euros de las
// series en euros («constantes», por defecto, o «corrientes»: ?euros=corrientes).
export function leerEstado(busqueda, datos = null) {
  const p = new URLSearchParams(busqueda);
  const idioma = p.get('idioma') === 'en' ? 'en' : 'es';
  let ccaa = p.get('ccaa');
  const validas = datos?.series?.valor_tasado?.territorios ?? null;
  if (!ccaa || !/^\d{2}$/.test(ccaa) || ccaa === ESPANA || (validas && !(ccaa in validas))) ccaa = null;
  const euros = EUROS.includes(p.get('euros')) ? p.get('euros') : EUROS_DEFECTO;
  return { idioma, ccaa, euros };
}

export function consulta(estado) {
  const p = new URLSearchParams();
  if (estado.idioma === 'en') p.set('idioma', 'en');
  if (estado.ccaa) p.set('ccaa', estado.ccaa);
  if (estado.euros && estado.euros !== EUROS_DEFECTO) p.set('euros', estado.euros);
  const s = p.toString();
  return s ? `?${s}` : '';
}

// --- Euros constantes ---------------------------------------------------------------------------

// Copia de los datos con las series en euros en euros del año base del IPC (datos/ipc.json): cada
// periodo, con la media anual de su año (un trimestre, con la de su año); sin índice (antes del
// primer año con media anual, 2002, y el año en curso), sin cifra, y esos periodos se recortan de
// los extremos de la serie. Las demás series, tal cual. Cada serie deflactada lleva `deflactada`:
// { base, desde, hasta, fuera } (primer y último año con cifra; `fuera`, los años con cifra en
// euros de cada año que se quedan fuera). null sin IPC: la página se queda en euros de cada año.
export function deflactarDatos(datos, ipc, series = SERIES_EUROS) {
  const base = anioBaseIpc(ipc);
  if (!datos?.series || base === null) return null;
  const copia = { ...datos, series: { ...datos.series } };
  for (const serie of series) {
    const s = datos.series[serie];
    if (!s) continue;
    const fuera = new Set();
    const territorios = {};
    for (const [geo, terr] of Object.entries(s.territorios)) {
      const puntos = puntosDe(datos, serie, geo);
      let v = puntos.map((p) => {
        if (p.v === null) return null;
        const x = deflactar(p.v, p.anio, ipc, base);
        if (x === null) fuera.add(p.anio);
        return x === null ? null : x * s.escala;
      });
      let primero = v.findIndex((x) => x !== null);
      if (primero < 0) continue;
      const ultimo = v.length - 1 - [...v].reverse().findIndex((x) => x !== null);
      v = v.slice(primero, ultimo + 1);
      const p0 = puntos[primero];
      territorios[geo] = { ...terr, inicio: [p0.anio, p0.sub], v };
    }
    const anios = Object.keys(territorios).flatMap((g) => puntosDe({ series: { x: { ...s, territorios } } }, 'x', g)
      .filter((p) => p.v !== null).map((p) => p.anio));
    copia.series[serie] = { ...s, territorios,
      deflactada: { base, desde: Math.min(...anios), hasta: Math.max(...anios), fuera: [...fuera].sort((a, b) => a - b) } };
  }
  return copia;
}

// Datos que pinta la página según la elección de euros: los deflactados con «constantes» (si hay
// IPC) y los originales con «corrientes».
export const datosVista = (datos, deflactados, euros) => (euros === 'constantes' && deflactados ? deflactados : datos);

export const decimalesDe = (escala) => Math.round(Math.log10(escala));

// Puntos de una serie en un territorio: { anio, sub, clave, t, v }, con t el centro del periodo en
// años (1987,125 = primer trimestre de 1987) y v el valor (null sin cifra). null si no hay serie.
export function puntosDe(datos, serie, geo = ESPANA) {
  const s = datos?.series?.[serie];
  const terr = s?.territorios?.[geo];
  if (!terr) return null;
  const n = SUBPERIODOS[s.frecuencia];
  const [a0, s0] = terr.inicio;
  const base = a0 * n + Math.max(s0, 1) - 1;
  return terr.v.map((x, k) => {
    const i = base + k;
    const anio = Math.floor(i / n);
    const sub = n === 1 ? 0 : (i % n) + 1;
    return { anio, sub, clave: claveDe(anio, sub, s.frecuencia), t: anio + ((n === 1 ? 0 : sub - 1) + 0.5) / n,
      v: x === null || x === undefined ? null : x / s.escala };
  });
}

export function claveDe(anio, sub, frecuencia) {
  if (frecuencia === 'trimestral') return `${anio}-T${sub}`;
  if (frecuencia === 'mensual') return `${anio}-${String(sub).padStart(2, '0')}`;
  return String(anio);
}

// [anio, sub] de una fecha clave → su clave en la frecuencia de la serie.
export const claveFecha = (periodo, frecuencia) => claveDe(periodo[0], periodo[1], frecuencia);

// Primer y último punto con cifra, máximo y mínimo (el primero, si se repite).
export function extremos(puntos) {
  const con = (puntos ?? []).filter((p) => p.v !== null);
  if (!con.length) return null;
  let maximo = con[0];
  let minimo = con[0];
  for (const p of con) {
    if (p.v > maximo.v) maximo = p;
    if (p.v < minimo.v) minimo = p;
  }
  return { primero: con[0], ultimo: con.at(-1), maximo, minimo };
}

// Punto con cifra más cercano a t (null si no hay ninguno a menos de `tolerancia` años).
export function cercano(puntos, t, tolerancia = Infinity) {
  let mejor = null;
  for (const p of puntos ?? []) {
    if (p.v === null) continue;
    if (!mejor || Math.abs(p.t - t) < Math.abs(mejor.t - t)) mejor = p;
  }
  return mejor && Math.abs(mejor.t - t) <= tolerancia ? mejor : null;
}

// Escala vertical redonda: paso de 1, 2, 2,5 o 5 × 10^k para unas `marcas` divisiones, desde 0 (o
// desde el múltiplo del paso por debajo del mínimo, si hay negativos).
export function escalaEje(valores, marcas = 5) {
  const vs = valores.filter((v) => v !== null && v !== undefined);
  const max = Math.max(0, ...vs);
  const min = Math.min(0, ...vs);
  const bruto = (max - min || 1) / marcas;
  const potencia = 10 ** Math.floor(Math.log10(bruto));
  const paso = [1, 2, 2.5, 5, 10].map((m) => m * potencia).find((p) => p >= bruto);
  return { min: Math.floor(min / paso + 1e-9) * paso, max: Math.ceil(max / paso - 1e-9) * paso, paso };
}

// Años con marca en el eje horizontal: múltiplos de `cada` entre desde y hasta.
export function marcasAnios(desde, hasta, cada = 5) {
  const out = [];
  for (let a = Math.ceil(desde / cada) * cada; a <= hasta; a += cada) out.push(a);
  return out;
}

export const escalaLineal = (d0, d1, r0, r1) => (x) => r0 + ((x - d0) / (d1 - d0)) * (r1 - r0);

// Trazado SVG de los puntos, cortado en los periodos sin cifra.
export function trazado(puntos, x, y) {
  let d = '';
  let dentro = false;
  for (const p of puntos) {
    if (p.v === null) {
      dentro = false;
      continue;
    }
    d += `${dentro ? 'L' : 'M'}${x(p.t).toFixed(1)},${y(p.v).toFixed(1)}`;
    dentro = true;
  }
  return d;
}

// Periodo escrito: «primer trimestre de 1987» / «Q1 1987», «noviembre de 1990», «1995».
export function textoPeriodo(p, frecuencia, t) {
  if (frecuencia === 'trimestral') return t(`historico.periodo.t${p.sub}`, { anio: p.anio });
  if (frecuencia === 'mensual') return t.periodo(`${p.anio}-${String(p.sub).padStart(2, '0')}`);
  return String(p.anio);
}

export function textoValor(v, serie, datos, t) {
  if (v === null || v === undefined) return t('historico.sin_dato');
  const s = datos.series[serie];
  return t(`historico.unidades.${s.unidad}`, { x: t.numero(v, decimalesDe(s.escala)) });
}

// Lectura impersonal de una serie: primer dato, máximo, mínimo y último, sin repetir un punto que
// sea varias cosas a la vez («Primer dato y mínimo de la serie, primer trimestre de 1987: 2,90 años.»).
export function lectura(datos, serie, geo, t) {
  const frecuencia = datos.series[serie]?.frecuencia;
  return lecturaPuntos(puntosDe(datos, serie, geo), ['primero', 'maximo', 'minimo', 'ultimo'],
    (p) => textoPeriodo(p, frecuencia, t), (v) => textoValor(v, serie, datos, t), t);
}

// Frases de la lectura con los `papeles` pedidos (de extremos()), en orden de tiempo.
function lecturaPuntos(puntos, papeles, periodo, valor, t) {
  const e = extremos(puntos);
  if (!e) return '';
  const orden = [];
  const porClave = new Map();
  for (const papel of papeles) {
    const p = e[papel];
    if (!porClave.has(p.clave)) {
      porClave.set(p.clave, []);
      orden.push(p);
    }
    porClave.get(p.clave).push(papel);
  }
  return orden.sort((a, b) => a.t - b.t).map((p) => {
    const etiqueta = porClave.get(p.clave).map((papel) => t(`historico.lectura.${papel}`)).join(t('historico.lectura.y'));
    const frase = `${etiqueta}, ${periodo(p)}: ${valor(p.v)}.`;
    return frase.charAt(0).toUpperCase() + frase.slice(1);
  }).join(' ');
}

// Puntos con cifra entre dos periodos sin ella (o en un extremo): el trazado no los dibuja, porque
// un tramo de un solo punto no es una línea; el gráfico les pone un punto.
export function aislados(puntos) {
  const lista = puntos ?? [];
  return lista.filter((p, k) => p.v !== null && (lista[k - 1]?.v ?? null) === null && (lista[k + 1]?.v ?? null) === null);
}

// Tiempos que recorre el teclado en un gráfico: los periodos de todas sus series, ordenados y sin
// repetir; con `conHuecos`, también los periodos sin cifra (para leer «sin dato»).
export function pasosTeclado(listas, conHuecos = false) {
  const ts = new Set();
  for (const puntos of listas) for (const p of puntos ?? []) if (conHuecos || p.v !== null) ts.add(p.t);
  return [...ts].sort((a, b) => a - b);
}

// Fechas clave de una serie en un territorio, con su punto (las que no caen en un periodo con
// cifra, sin punto) y en orden de tiempo. Las rupturas también.
export function fechasDe(datos, serie, geo = ESPANA) {
  const s = datos.series[serie];
  const puntos = puntosDe(datos, serie, geo) ?? [];
  const porClave = new Map(puntos.map((p) => [p.clave, p]));
  return (datos.fechas ?? [])
    .filter((f) => f.serie === serie && (f.geo ?? ESPANA) === geo)
    .map((f) => {
      const clave = claveFecha(f.periodo, s.frecuencia);
      const p = porClave.get(clave);
      const punto = p && p.v !== null ? p : null;
      const n = SUBPERIODOS[s.frecuencia];
      const t0 = f.periodo[0] + ((n === 1 ? 0 : Math.max(f.periodo[1], 1) - 1) + 0.5) / n;
      return { ...f, clave, punto, t: punto?.t ?? t0 };
    })
    .sort((a, b) => a.t - b.t);
}

// Primer y último año que cubren todas las series de la página (eje común a todos los gráficos).
// `otras`: listas de puntos que no van en historico.json (la del CIS).
export function rangoAnios(datos, otras = []) {
  let hasta = datos.desde ?? 1987;
  const listas = [...otras];
  for (const serie of Object.keys(datos.series)) {
    for (const geo of Object.keys(datos.series[serie].territorios)) listas.push(puntosDe(datos, serie, geo));
  }
  for (const puntos of listas) {
    const e = extremos(puntos);
    if (e) hasta = Math.max(hasta, Math.ceil(e.ultimo.t));
  }
  return { desde: datos.desde ?? 1987, hasta };
}

// Comunidades con serie del valor tasado, ordenadas por su nombre en orden natural.
export function comunidades(datos, ordenNatural = (x) => x) {
  const terr = datos.series.valor_tasado?.territorios ?? {};
  return Object.keys(terr).filter((g) => g !== ESPANA)
    .map((g) => ({ codigo: g, nombre: ordenNatural(datos.territorios?.[g] ?? g) }))
    .sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));
}

// --- La vivienda como problema (CIS) ------------------------------------------------------------
// datos/cis_vivienda.json (cis_exportar_vivienda()): por pregunta («espana», el principal problema de
// España; «personal», el que más afecta a quien responde), listas paralelas de periodo («AAAA-MM»),
// valor (% con un decimal), estudio y entrevistas (n), solo los meses con dato. Va fuera de
// datos/historico/, que su exportación borra. Opinión, no registro.

export const RUTA_CIS = 'datos/cis_vivienda.json';
export const CIS_ID = 'hist-cis';
export const CIS_SERIES = ['espana', 'personal'];
export const CIS_SIN_BAROMETRO = 8;   // agosto: el CIS no hace barómetro; no es un hueco

const PERIODO_MES = /^(\d{4})-(\d{2})$/;

// Puntos mensuales de una pregunta, del primer mes con dato al último y sin agosto (salvo que lo
// traiga): { anio, sub, clave, t, v, estudio, n }, con v = null en los meses que faltan, donde la
// línea se corta. null si la pregunta no está o no trae ningún mes.
export function puntosCis(cis, pregunta) {
  const s = cis?.series?.[pregunta];
  const periodos = Array.isArray(s?.periodo) ? s.periodo : [];
  const porClave = new Map();
  periodos.forEach((p, k) => {
    if (PERIODO_MES.test(p) && typeof s.valor?.[k] === 'number') porClave.set(p, k);
  });
  if (!porClave.size) return null;
  const indice = (p) => {
    const [, a, m] = PERIODO_MES.exec(p);
    return Number(a) * 12 + Number(m) - 1;
  };
  const indices = [...porClave.keys()].map(indice);
  const out = [];
  for (let i = Math.min(...indices); i <= Math.max(...indices); i++) {
    const anio = Math.floor(i / 12);
    const sub = (i % 12) + 1;
    const clave = claveDe(anio, sub, 'mensual');
    const k = porClave.get(clave);
    if (k === undefined && sub === CIS_SIN_BAROMETRO) continue;
    out.push({ anio, sub, clave, t: anio + (sub - 0.5) / 12,
      v: k === undefined ? null : s.valor[k],
      estudio: k === undefined ? null : (s.estudio?.[k] ?? null),
      n: k === undefined ? null : (s.n?.[k] ?? null) });
  }
  return out;
}

// Meses sin dato entre el primero y el último (agosto no cuenta).
export const huecosCis = (puntos) => (puntos ?? []).filter((p) => p.v === null).length;

// Mes más cercano a t, tenga o no cifra (null si no hay ninguno a menos de `tolerancia` años): el
// globo dice «sin dato» en un hueco en lugar de saltar al mes vecino.
export function mesCercano(puntos, t, tolerancia = 0.1) {
  let mejor = null;
  for (const p of puntos ?? []) {
    if (!mejor || Math.abs(p.t - t) < Math.abs(mejor.t - t)) mejor = p;
  }
  return mejor && Math.abs(mejor.t - t) <= tolerancia ? mejor : null;
}

export function textoCis(v, t) {
  return v === null || v === undefined ? t('historico.sin_dato') : t('historico.unidades.porcentaje', { x: t.numero(v, 1) });
}

// Lectura impersonal de una pregunta: primer dato, máximo y último, y los meses sin dato.
export function lecturaCis(cis, pregunta, t) {
  const puntos = puntosCis(cis, pregunta);
  const frases = lecturaPuntos(puntos, ['primero', 'maximo', 'ultimo'], (p) => textoPeriodo(p, 'mensual', t), (v) => textoCis(v, t), t);
  const huecos = huecosCis(puntos);
  return huecos ? `${frases} ${t('historico.cis_huecos', { n: t.numero(huecos) })}` : frases;
}

// Estudio y entrevistas de un mes, del primer punto que los traiga (las dos preguntas son del mismo
// barómetro): «Estudio 3582 · 5.024 entrevistas»; '' si el JSON no los trae.
export function textoEstudio(puntos, t) {
  const p = puntos.find((x) => x && x.v !== null && (x.estudio || Number.isFinite(x.n)));
  if (!p) return '';
  return [p.estudio ? t('historico.cis_estudio', { estudio: p.estudio }) : null,
    Number.isFinite(p.n) ? t('historico.cis_entrevistas', { n: t.numero(p.n) }) : null].filter(Boolean).join(' · ');
}
