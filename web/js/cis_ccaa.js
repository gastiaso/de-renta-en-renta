// La vivienda como problema por comunidad autónoma (CIS; tarea 63): lógica sin DOM de la tabla de la
// Máquina del tiempo (historico.js) y de la línea de la ficha de comunidad del mapa (principal.js).
// Datos: datos/cis_vivienda_ccaa.json (R/fuente_cis_ccaa.R, cis_ccaa_exportar()), que puede faltar:
// listas paralelas por fila (codigo, anio, desde, hasta, anios, pregunta, valor, inferior, superior,
// margen, entrevistas, meses, en_curso, ruptura, estado), con la fuente, la licencia, la edición de
// Barómetro a barómetro, el último mes y las rupturas. Cifras en % con un decimal; «ausente» (menos de
// 50 entrevistas) va sin cifra. Opinión, no registro.

export const RUTA_CIS_CCAA = 'datos/cis_vivienda_ccaa.json';
export const ESPANA_CIS = '00';
export const PREGUNTAS_CIS = ['espana', 'personal'];

const LOCALES = { es: 'es-ES', en: 'en-GB' };

// Filas del JSON como objetos; [] si no hay JSON o no trae filas.
export function filasCis(json) {
  const f = json?.filas;
  if (!f || !Array.isArray(f.codigo)) return [];
  return f.codigo.map((codigo, i) => ({
    codigo: String(codigo), anio: Number(f.anio[i]), desde: f.desde?.[i] ?? null, hasta: f.hasta?.[i] ?? null,
    anios: Number(f.anios?.[i] ?? 1), pregunta: f.pregunta[i],
    valor: typeof f.valor?.[i] === 'number' ? f.valor[i] : null,
    inferior: typeof f.inferior?.[i] === 'number' ? f.inferior[i] : null,
    superior: typeof f.superior?.[i] === 'number' ? f.superior[i] : null,
    margen: typeof f.margen?.[i] === 'number' ? f.margen[i] : null,
    entrevistas: Number(f.entrevistas?.[i] ?? 0), meses: Number(f.meses?.[i] ?? 0),
    en_curso: Boolean(f.en_curso?.[i]), ruptura: Boolean(f.ruptura?.[i]), estado: f.estado?.[i] ?? 'ausente',
  }));
}

// Años con alguna cifra, de menor a mayor.
export function aniosCis(filas) {
  return [...new Set(filas.filter((f) => f.valor !== null).map((f) => f.anio))].sort((a, b) => a - b);
}

// Año que abre la tabla: el último completo (no en curso) con cifra; si no hay, el último.
export function anioInicial(filas) {
  const completos = [...new Set(filas.filter((f) => f.valor !== null && !f.en_curso).map((f) => f.anio))];
  if (completos.length) return Math.max(...completos);
  const todos = aniosCis(filas);
  return todos.length ? todos.at(-1) : null;
}

// Filas de un año y una pregunta, ordenadas por la cifra de mayor a menor (las que no tienen, al
// final, por su nombre); España, aparte, como referencia. `nombre(codigo)` da el nombre que se pinta.
export function tablaAnio(filas, anio, pregunta, nombre = (c) => c) {
  const del = filas.filter((f) => f.anio === anio && f.pregunta === pregunta);
  const espana = del.find((f) => f.codigo === ESPANA_CIS) ?? null;
  const comunidades = del.filter((f) => f.codigo !== ESPANA_CIS).map((f) => ({ ...f, nombre: nombre(f.codigo) }))
    .sort((a, b) => (b.valor ?? -1) - (a.valor ?? -1) || a.nombre.localeCompare(b.nombre, 'es'));
  return { espana: espana && { ...espana, nombre: nombre(ESPANA_CIS) }, comunidades };
}

// Escala común de las barras de intervalo: de 0 a la decena por encima del mayor límite superior.
export function escalaCis(filas) {
  const altos = filas.map((f) => f.superior).filter((v) => typeof v === 'number');
  const max = altos.length ? Math.max(...altos) : 10;
  return { min: 0, max: Math.max(10, Math.ceil(max / 10) * 10) };
}

// Posición en % del ancho de una cifra en la escala (para las barras de la tabla).
export const posicion = (v, escala) => Math.max(0, Math.min(100, ((v - escala.min) / (escala.max - escala.min)) * 100));

// Nombre del mes de «AAAA-MM» («octubre», «October»).
export function nombreMes(mes, idioma = 'es') {
  const m = /^(\d{4})-(\d{2})$/.exec(String(mes ?? ''));
  if (!m) return '';
  return new Intl.DateTimeFormat(LOCALES[idioma] ?? LOCALES.es, { month: 'long', timeZone: 'UTC' })
    .format(new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, 1)));
}

// Periodo de una fila: «2025», «2024–2025» (dos años juntos) y, en curso, «2026, hasta octubre».
export function textoPeriodoCis(f, t) {
  const desde = Number(String(f.desde ?? f.anio).slice(0, 4));
  const base = f.anios > 1 && desde < f.anio ? t('historico.cis_ccaa.periodo_dos', { desde, hasta: f.anio }) : String(f.anio);
  return f.en_curso ? t('historico.cis_ccaa.periodo_en_curso', { periodo: base, mes: nombreMes(f.hasta, t.idioma) }) : base;
}

export const textoCifraCis = (f, t) => (f.valor === null ? t('historico.cis_ccaa.sin_cifra', { minimo: 50 })
  : t('historico.unidades.porcentaje', { x: t.numero(f.valor, 1) }));

export const textoMargenCis = (f, t) => (f.margen === null ? '' : t('historico.cis_ccaa.margen', { m: t.numero(f.margen, 1) }));

export const textoIntervaloCis = (f, t) => (f.inferior === null ? ''
  : t('historico.cis_ccaa.intervalo', { inf: t.numero(f.inferior, 1), sup: t.numero(f.superior, 1) }));

// Notas al pie de la tabla de un año: año en curso, ruptura de la ponderación (R10) y Ceuta y Melilla
// agrupadas, solo las que tocan a las filas que se ven.
export function notasCis(tabla, t) {
  const filas = [tabla.espana, ...tabla.comunidades].filter(Boolean);
  const notas = [];
  const curso = filas.find((f) => f.en_curso);
  if (curso) notas.push(t('historico.cis_ccaa.nota_en_curso', { mes: nombreMes(curso.hasta, t.idioma) }));
  if (filas.some((f) => f.ruptura)) notas.push(t('historico.cis_ccaa.nota_ruptura'));
  if (filas.some((f) => f.anios > 1)) notas.push(t('historico.cis_ccaa.nota_agrupadas'));
  return notas;
}

// --- Ficha de comunidad del mapa ---------------------------------------------------------------
// El JSON se pide una vez, la primera vez que se abre una ficha de comunidad; si falta, null.
let pedido = null;
export function cargarCis(pedir = (ruta) => fetch(ruta)) {
  pedido ??= Promise.resolve().then(() => pedir(RUTA_CIS_CCAA))
    .then((r) => (r.ok ? r.json() : null)).catch(() => null);
  return pedido;
}

// Bloque de la ficha de comunidad (principal.js, en el hueco de detalle, que en las comunidades no
// usa nada más): título, la línea con la cifra más reciente y una nota con la fuente y el enlace a la
// Máquina del tiempo. Sin datos para la comunidad, el hueco queda vacío. `vigente()`: la ficha sigue
// siendo la misma cuando llega el JSON.
export async function pintarCisFicha(hueco, codigo, t, vigente = () => true) {
  const json = await cargarCis();
  if (!vigente()) return;
  const linea = lineaFichaCis(filasCis(json), codigo, t);
  if (!linea) {
    hueco.replaceChildren();
    return;
  }
  const crear = (etiqueta, clase, texto) => {
    const e = document.createElement(etiqueta);
    if (clase) e.className = clase;
    if (texto !== undefined) e.textContent = texto;
    return e;
  };
  const bloque = crear('section', 'ficha-cis');
  const nota = crear('p', 'nota', `${t('interfaz.ficha.cis_ccaa.nota')} `);
  const enlace = crear('a', null, t('nav.historico'));
  // A la tabla por comunidad, no a la serie nacional del mismo bloque (lectura del sitio, 23-nov-2026)
  enlace.href = `historico.html${t.idioma === 'en' ? '?idioma=en' : ''}#hi-cis-ccaa`;
  nota.append(enlace);
  bloque.append(crear('h3', 'ficha-indicador', t('interfaz.ficha.cis_ccaa.titulo')), crear('p', 'ficha-estado', linea), nota);
  hueco.replaceChildren(bloque);
}

// Línea de la ficha de comunidad del mapa:la cifra más reciente de la comunidad en la pregunta de
// los problemas de España (el año en curso, rotulado «hasta {mes}»), con su margen y sus entrevistas;
// null si la comunidad no tiene cifra.
export function lineaFichaCis(filas, codigo, t, pregunta = 'espana') {
  const suyas = filas.filter((f) => f.codigo === codigo && f.pregunta === pregunta && f.valor !== null)
    .sort((a, b) => b.anio - a.anio);
  const f = suyas[0];
  if (!f) return null;
  return t('interfaz.ficha.cis_ccaa.linea', {
    cifra: t.numero(f.valor, 1), periodo: textoPeriodoCis(f, t), margen: t.numero(f.margen, 1),
    entrevistas: t.numero(f.entrevistas),
  });
}
