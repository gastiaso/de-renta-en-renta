// Máquina del tiempo (historico.html, F6): lógica sin DOM, para el navegador y para las pruebas de
// node (pruebas/web/historico.test.mjs). Datos: datos/historico/historico.json (R/web_historico.R):
// cada serie, con su frecuencia, su escala y, por territorio, el primer periodo y un vector de
// enteros (valor × escala) sin huecos de periodos (null sin cifra).

export const RUTA_DATOS = 'datos/historico/historico.json';
export const SUBPERIODOS = { trimestral: 4, mensual: 12, anual: 1 };
export const ESPANA = '00';

// Bloques de la página, en orden: el id es el ancla de la sección (la casilla «Sube el euríbor» de
// la portada lleva a #hist-tipos). El valor tasado se puede ver también por comunidad.
export const BLOQUES = [
  { id: 'hist-renta', series: ['anios_renta'] },
  { id: 'hist-esfuerzo', series: ['esfuerzo_teorico'] },
  { id: 'hist-tipos', series: ['tipo_hipotecas', 'mibor_euribor'] },
  { id: 'hist-tasado', series: ['valor_tasado'], territorial: true },
  { id: 'hist-sueldo', series: ['sueldo_asalariado'] },
];

// Estado de la URL: idioma y comunidad del valor tasado (solo una que tenga serie).
export function leerEstado(busqueda, datos = null) {
  const p = new URLSearchParams(busqueda);
  const idioma = p.get('idioma') === 'en' ? 'en' : 'es';
  let ccaa = p.get('ccaa');
  const validas = datos?.series?.valor_tasado?.territorios ?? null;
  if (!ccaa || !/^\d{2}$/.test(ccaa) || ccaa === ESPANA || (validas && !(ccaa in validas))) ccaa = null;
  return { idioma, ccaa };
}

export function consulta(estado) {
  const p = new URLSearchParams();
  if (estado.idioma === 'en') p.set('idioma', 'en');
  if (estado.ccaa) p.set('ccaa', estado.ccaa);
  const s = p.toString();
  return s ? `?${s}` : '';
}

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
  const e = extremos(puntosDe(datos, serie, geo));
  if (!e) return '';
  const frecuencia = datos.series[serie].frecuencia;
  const orden = [];
  const papeles = new Map();
  for (const papel of ['primero', 'maximo', 'minimo', 'ultimo']) {
    const p = e[papel];
    if (!papeles.has(p.clave)) {
      papeles.set(p.clave, []);
      orden.push(p);
    }
    papeles.get(p.clave).push(papel);
  }
  return orden.sort((a, b) => a.t - b.t).map((p) => {
    const etiqueta = papeles.get(p.clave).map((papel) => t(`historico.lectura.${papel}`)).join(t('historico.lectura.y'));
    const frase = `${etiqueta}, ${textoPeriodo(p, frecuencia, t)}: ${textoValor(p.v, serie, datos, t)}.`;
    return frase.charAt(0).toUpperCase() + frase.slice(1);
  }).join(' ');
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
export function rangoAnios(datos) {
  let hasta = datos.desde ?? 1987;
  for (const serie of Object.keys(datos.series)) {
    for (const geo of Object.keys(datos.series[serie].territorios)) {
      const e = extremos(puntosDe(datos, serie, geo));
      if (e) hasta = Math.max(hasta, Math.ceil(e.ultimo.t));
    }
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
