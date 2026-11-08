// Arranque de la web y coordinación: estado de la vista (URL), idioma, datos, barra de la vista
// (mapa, año, tipología y descargas), mapa, leyenda, «Tu sueldo», ficha de sección, comparador,
// buscador y «Compartir».

import { leerEstado, guardarEstado, vistaATexto, textoAVista, leerSueldoCompartido, enlaceVista } from './estado.js';
import { cargarIdioma, traducirPagina } from './i18n.js';
import {
  cargarManifiesto, cargarSecciones, cargarTerritorios, cargarPerfiles, cargarCajas,
  cargarIndice, cargarValores, cargarSeries, valorDe, periodoPara, periodosDe, fueraDeSerie,
  serieDeTipologia, tipologiaDe,
} from './datos.js';
import { crearMapa, coloresMapa, coloresContorno } from './mapa.js';
import { pintarLeyenda } from './leyenda.js';
import { fichaVacia, fichaSeccion, fichaSeries, fichaError } from './ficha.js';
import { formulaDe } from './formulas.js';
import {
  modoDe, superficieDe, umbralDe, calculoLlega, colorLlega, colorNecesario, resumenLlega,
  marcasRegla, tramoLlega, ingresoPeon,
} from './sueldo.js';
import { crearPanelSueldo } from './panel_sueldo.js';
import { crearCompartir } from './compartir.js';
import { codigoComparado, nombreTerritorio, filasComparador, pintarComparador } from './comparador.js';
import { crearBuscador, formasDeNombre } from './buscador.js';
import { ordenNatural } from './nombres.js';
import { crearBarraVista } from './barra_vista.js';
import { tablaCsv, textoCsv, nombreFichero, descargar, nivelParaExportar, decimalesDeEscala } from './exportar.js';
import { imagenMapa } from './imagen.js';
import { pasosDeRampa, decimalesDeCortes } from './colores.js';
import { crearAvisoImagen } from './aviso_imagen.js';

const estado = { idioma: 'es', ...leerEstado() };
let sueldo = leerSueldoCompartido();   // solo en memoria; en el enlace, solo con «Compartir»
if (sueldo && !estado.ficha) estado.ficha = 'peon';

const el = {
  mapa: document.getElementById('mapa'),
  leyenda: document.getElementById('leyenda'),
  ficha: document.getElementById('ficha'),
  ejemplo: document.getElementById('aviso-ejemplo'),
  escala: document.getElementById('aviso-escala'),
  periodo: document.getElementById('aviso-periodo'),
  idiomas: [...document.querySelectorAll('[data-idioma]')],
};

let t;             // traductor del idioma activo
let m;             // manifiesto
let secciones;     // códigos de sección en el orden de los valores
let indice;        // código → posición
let territorios;   // nombres por nivel
let perfiles;      // ingresos de las fichas
let mapa;          // funciones del mapa (mapa.js)
let colores;       // colores del mapa (tokens.css)
let contornos;     // colores del contorno de cada tramo
let panel;         // tarjeta «Tu sueldo»
let barra;         // barra de la vista
let compartir;     // diálogo «Compartir»
let avisoImagen;   // aviso antes de la imagen de «¿te llega?» con «Tu ficha»
const columnas = {};            // serie → { valores, estados, periodo, clave } del periodo activo
let eligiendoComparada = false; // el siguiente clic en el mapa elige la sección con que comparar
let turno = 0;                  // descarta cálculos superados por otro más reciente
let turnoFicha = 0;

const MAPA_POR_DEFECTO = 'sueldo_necesario';
const mapaDef = () => m.mapas[estado.mapa];
const indiceEstado = (nombre) => m.codificacion.estados.indexOf(nombre);
const esSeccion = (x) => /^\d{10}$/.test(x ?? '');
// ¿Usa el mapa la superficie y el umbral? (el sueldo necesario; los «directo», no).
const usaSupuestos = (def) => (def.formula ?? 'directo') !== 'directo';
// Serie de la tipología elegida (vivienda colectiva por defecto; decisión 12).
const serieTipo = (serie) => serieDeTipologia(m, serie, estado.tipologia);
const nivelesDe = (serie) => m.indicadores[serie]?.niveles ?? ['sc'];

// Lo que se pinta, a partir del estado: modo, superficie, umbral, cálculo, mapa con la serie de
// la tipología, series necesarias, periodo activo y tipología. Si el año elegido es anterior a
// toda la serie que da color, `periodo` es null y `fuera` dice desde cuándo hay serie (pregunta
// abierta 32); `referencia` es el periodo con que se buscan las demás series (comparador, llave).
function vista() {
  const modo = modoDe(estado, sueldo, perfiles);
  const superficie = superficieDe(estado, sueldo, perfiles);
  const umbral = umbralDe(estado);
  const supuestos = { superficie_m2: superficie ?? m.supuestos.superficie_m2, umbral };
  const calculo = modo === 'llega' ? calculoLlega({ ficha: estado.ficha, perfiles, sueldo, superficie, serie: serieTipo }) : null;
  const def = mapaDef();
  const mapaTipo = { ...def, base: serieTipo(def.base) };
  const seriesColor = calculo ? calculo.series : [mapaTipo.base];
  // El periodo lo marca la serie que da color (la primera; en «¿te llega?», el alquiler).
  const periodo = periodoPara(m.indicadores[seriesColor[0]], estado.anio);
  const fuera = fueraDeSerie(m.indicadores[seriesColor[0]], estado.anio);
  // En el sueldo necesario, las fichas de una persona y la llave van en la regla de la leyenda.
  const enSueldo = !calculo && def.formula === 'alquiler_m2_a_sueldo';
  const series = [...seriesColor];
  const renta = perfiles.llave?.ingreso.serie;
  if (enSueldo && renta && m.indicadores[renta]) series.push(renta);   // banda de la llave en la regla
  return {
    modo, superficie, umbral, supuestos, calculo, mapa: mapaTipo, seriesColor, periodo, fuera,
    referencia: periodo ?? estado.anio, enSueldo, tipologia: tipologiaDe(m, seriesColor[0]), series: [...new Set(series)],
  };
}

// «Sin datos de 2020: la serie empieza en febrero de 2024.»
const textoFuera = (fuera) => t('interfaz.vista.fuera', { anio: t.periodo(fuera.anio), desde: t.periodo(fuera.desde) });

// Columna vacía (todo sin dato) de una serie en un nivel que tiene, para un año anterior a la serie.
const vacia = (serie, nivel, n) => (nivelesDe(serie).includes(nivel)
  ? { valores: new Array(n).fill(null), estados: new Uint8Array(n).fill(indiceEstado('ausente')) }
  : null);

// Carga las series del periodo activo que falten, en cada nivel que pinta el mapa (secciones y,
// con poco zoom, municipios y provincias), y las guarda en sus elementos. Una serie que no llega
// al año pedido (empieza después) se pinta sin dato.
const otrosNiveles = {};   // nivel → serie → clave cargada
async function cargarColumnas(series, referencia) {
  await Promise.all(mapa.rellenos.map(async ({ capa, nivel }) => {
    const codigos = nivel === 'sc' ? secciones : await cargarIndice(m, nivel);
    if (!codigos) return;
    const nuevas = {};
    await Promise.all(series.map(async (serie) => {
      const def = m.indicadores[serie];
      if (!def) return;
      const periodo = periodoPara(def, referencia);
      const clave = `${serie}@${periodo}`;
      const cargada = nivel === 'sc' ? columnas[serie]?.clave : otrosNiveles[nivel]?.[serie];
      if (cargada === clave) return;
      const datos = periodo === null ? vacia(serie, nivel, codigos.length) : await cargarValores(m, serie, nivel, periodo);
      if (!datos) return;
      if (nivel === 'sc') columnas[serie] = { ...datos, periodo, clave };
      else (otrosNiveles[nivel] ??= {})[serie] = clave;
      nuevas[serie] = datos.valores;
    }));
    mapa.ponerSeries(capa, codigos, nuevas);
  }));
}

const valorEn = (serie, i) => (i === undefined ? null : columnas[serie]?.valores[i] ?? null);

function peorEstado(series, i) {
  if (i === undefined) return indiceEstado('ausente');
  return Math.max(...series.map((s) => columnas[s]?.estados[i] ?? indiceEstado('ausente')));
}

function secretos(series) {
  const secreto = indiceEstado('secreto');
  return secciones.filter((_, i) => series.some((s) => columnas[s]?.estados[i] === secreto));
}

// Textos de «¿te llega?»: qué vivienda y qué ingreso. `sinCifra`: el sueldo escrito por el
// usuario, sin la cantidad (para las descargas).
function textosLlega(v, { sinCifra = false } = {}) {
  const ficha = estado.ficha;
  const vivienda = ficha === 'llave'
    ? t('interfaz.sueldo.vivienda_llave')
    : t('interfaz.sueldo.vivienda_m2', { superficie: t.numero(v.superficie) });
  let ingreso;
  if (ficha === 'llave') ingreso = t('interfaz.sueldo.ingreso_llave');
  else if (ficha === 'peon') ingreso = sinCifra ? t('interfaz.exportar.ingreso_peon') : t('interfaz.sueldo.ingreso_euros', { euros: t.numero(ingresoPeon(sueldo)) });
  else if (perfiles[ficha]?.nivel === 'provincia') ingreso = t('interfaz.sueldo.ingreso_provincia', { ficha: t(`fichas.${ficha}`) });
  else ingreso = t('interfaz.sueldo.ingreso_euros', { euros: t.numero(perfiles[ficha]?.neto_mensual?.['00'] ?? 0) });
  return { vivienda, ingreso };
}

// Regla 4: si el ingreso de la ficha y el alquiler no son del mismo año, se dice.
function avisoAnios(v) {
  if (v.modo !== 'llega') return null;
  const alquiler = columnas[v.calculo.series[0]]?.periodo;
  let ingreso = null;
  if (estado.ficha === 'llave') ingreso = columnas[perfiles.llave.ingreso.serie]?.periodo;
  else if (estado.ficha !== 'peon') ingreso = perfiles[estado.ficha]?.anio;
  if (!ingreso || !alquiler || String(ingreso) === String(alquiler)) return null;
  return t('interfaz.sueldo.anios_distintos', { ingreso, alquiler });
}

// Barra de la vista: mapas del manifiesto (y, en «¿te llega?», esa opción delante), periodos de
// la serie que da color (y, delante, el año elegido si es anterior a la serie) y tipología.
function pintarBarra(v) {
  const llega = v.modo === 'llega';
  const mapas = Object.keys(m.mapas).map((id) => ({ valor: id, texto: t(`indicadores.${id}.nombre`) }));
  if (llega) mapas.unshift({ valor: '', texto: t('interfaz.vista.llega_opcion', { ficha: t(`fichas.${estado.ficha}`) }) });
  const periodos = periodosDe(m.indicadores[v.seriesColor[0]]).map((p) => ({ valor: String(p), texto: t.periodo(p) }));
  if (v.fuera) periodos.unshift({ valor: String(v.fuera.anio), texto: t('interfaz.vista.anio_fuera', { anio: t.periodo(v.fuera.anio) }) });
  barra.pintar({
    mapas,
    mapa: llega ? '' : estado.mapa,
    periodos,
    periodo: String(v.periodo ?? v.fuera?.anio ?? ''),
    tipologia: v.tipologia,
  });
}

// Avisos sobre el mapa: el año es anterior a la serie (desde cuándo hay datos) o la serie no
// llega al nivel que se ve (por ejemplo, una serie solo por sección con el mapa de toda España).
function avisarMapa(v = vista()) {
  const nivel = mapa.nivelVisible();
  el.periodo.hidden = !v.fuera;
  el.periodo.textContent = v.fuera ? textoFuera(v.fuera) : '';
  el.escala.hidden = Boolean(v.fuera) || v.seriesColor.every((s) => nivelesDe(s).includes(nivel));
}

async function actualizar() {
  const yo = ++turno;
  const v = vista();
  pintarBarra(v);
  await cargarColumnas(v.series, v.referencia);
  if (yo !== turno) return;

  for (const { capa, id } of mapa.rellenos) {
    const pintura = (paleta) => (v.modo === 'necesario'
      ? colorNecesario(v.mapa, v.supuestos, paleta)
      : colorLlega(v.calculo, id, paleta));
    mapa.colorear(capa, pintura(colores), pintura(contornos), capa === 'secciones' ? secretos(v.seriesColor) : null);
  }
  avisarMapa(v);

  const leyenda = {
    modo: v.modo, mapaId: estado.mapa, mapaDef: v.mapa, superficie: v.supuestos.superficie_m2, umbral: v.umbral,
    periodo: v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo, tipologia: v.tipologia,
    conSupuestos: usaSupuestos(v.mapa), fuera: v.fuera ? textoFuera(v.fuera) : null,
  };
  let resumen = null;
  let detalle = null;
  if (v.modo === 'necesario') {
    if (v.enSueldo) Object.assign(leyenda, marcasRegla({ perfiles, seccion: estado.seccion, rentaHogar: columnas[perfiles.llave?.ingreso.serie]?.valores }));
  } else {
    const { vivienda, ingreso } = textosLlega(v);
    leyenda.vivienda = t('interfaz.leyenda.llega_sub', { vivienda, ingreso });
    const r = resumenLlega(v.calculo, secciones, valorEn, v.umbral);
    resumen = !r.con ? t('interfaz.sueldo.sin_datos') : t(estado.ficha === 'peon' ? 'interfaz.sueldo.resumen_peon' : 'interfaz.sueldo.resumen_ficha', {
      pct: t.porcentaje(r.proporcion), caben: t.numero(r.caben), total: t.numero(r.con), ficha: t(`fichas.${estado.ficha}`),
    });
    detalle = [t('interfaz.sueldo.detalle', { vivienda, ingreso, umbral: t.porcentaje(v.umbral) }), avisoAnios(v)]
      .filter(Boolean).join(' ');
  }
  pintarLeyenda(el.leyenda, t, leyenda);
  panel.pintar({
    t, estado, sueldo, perfiles, modo: v.modo, superficie: v.superficie, umbral: v.umbral, resumen, detalle,
    sinEfecto: v.modo === 'necesario' && !usaSupuestos(v.mapa),
  });
  pintarFicha(v);
  guardarEstado(estado);
}

// --- Ficha, evolución y comparador ---------------------------------------------------------

// Series de una sección para la ficha: las de su municipio (fichas/<municipio>.json) y, si falta
// alguna de las que dan color (la vivienda unifamiliar no va en esos ficheros), la misma serie
// sacada de los ficheros de cada periodo.
async function seriesDeSeccion(codigo, v) {
  const series = { ...(await cargarSeries(m, codigo)) };
  await Promise.all(v.seriesColor.filter((s) => !series[s] && m.indicadores[s]).map(async (serie) => {
    const periodos = periodosDe(m.indicadores[serie]);
    const valores = await Promise.all(periodos.map((p) => valorDe(m, serie, 'sc', codigo, p)));
    series[serie] = {
      anios: periodos,
      valores: valores.map((x) => x?.valor ?? null),
      estados: Uint8Array.from(valores, (x) => x?.estado ?? indiceEstado('ausente')),
    };
  }));
  return series;
}

function pintarFicha(v = vista()) {
  const yo = ++turnoFicha;
  if (!estado.seccion) return fichaVacia(el.ficha, { t });
  const codigo = estado.seccion;
  const i = indice.get(codigo);
  const x = (serie) => valorEn(serie, i);
  let valor = null;
  if (v.modo === 'necesario') {
    const base = x(v.mapa.base);
    valor = base === null ? null : formulaDe(v.mapa).calcular(base, v.supuestos);
  } else {
    const r = v.calculo.calcular(codigo, x);
    valor = r && { ...r, tramo: tramoLlega(r.ratio) };
  }
  const { huecoSerie, huecoComparador } = fichaSeccion(el.ficha, {
    t, codigo, territorios, modo: v.modo, mapaId: estado.mapa, mapaDef: v.mapa, ficha: estado.ficha,
    supuestos: v.supuestos, anio: v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo,
    tipologia: v.tipologia, valor, estado: peorEstado(v.seriesColor, i), estados: m.codificacion.estados, ejemplo: m.ejemplo,
    aviso: [v.fuera && textoFuera(v.fuera), avisoAnios(v)].filter(Boolean).join(' ') || null, alCerrar: () => elegirSeccion(null),
  });
  const series = seriesDeSeccion(codigo, v).catch((error) => { console.error(error); return null; });
  series.then((s) => { if (yo === turnoFicha && s) pintarEvolucion(huecoSerie, s, v, codigo); });
  series.then((s) => pintarComparadorFicha(huecoComparador, s, v, codigo, yo)).catch((error) => console.error(error));
}

function pintarEvolucion(hueco, series, v, codigo) {
  const base = v.seriesColor[0];
  const periodos = series[base]?.anios;
  if (!periodos) return;
  // Valor de cada serie en un periodo (si la serie no lo tiene, sin dato).
  const en = (serie, p) => {
    const s = series[serie];
    const k = s ? s.anios.findIndex((q) => String(q) === String(p)) : -1;
    return k < 0 ? { valor: null, estado: indiceEstado('ausente') } : { valor: s.valores[k], estado: s.estados[k] };
  };
  const filas = periodos.map((p) => {
    const estadoPeor = Math.max(...v.seriesColor.map((s) => en(s, p).estado));
    let texto = '—';
    if (v.modo === 'necesario') {
      const b = en(base, p).valor;
      if (b !== null) texto = t.numero(formulaDe(v.mapa).calcular(b, v.supuestos), v.mapa.decimales ?? 0);
    } else {
      const r = v.calculo.calcular(codigo, (serie) => en(serie, p).valor);
      if (r) texto = t.porcentaje(r.ratio);
    }
    return { periodo: p, texto, estado: estadoPeor };
  });
  fichaSeries(hueco, {
    t, filas, estados: m.codificacion.estados, periodo: columnas[base]?.periodo,
    titulo: v.modo === 'necesario' ? t('interfaz.ficha.evolucion') : t('interfaz.ficha.evolucion_llega'),
    // Salvo la llave, el ingreso de la ficha es el de hoy: en la evolución solo cambia el alquiler.
    nota: v.modo === 'llega' && estado.ficha !== 'llave' ? t('interfaz.ficha.ingreso_fijo') : null,
  });
}

async function pintarComparadorFicha(hueco, seriesA, v, codigo, yo) {
  const municipio = codigo.slice(0, 5);
  const provincia = codigo.slice(0, 2);
  const ccaa = territorios.ccaa_de_provincia?.[provincia];
  // Solo los niveles que tiene alguna serie del manifiesto.
  const hay = (nivel) => Object.values(m.indicadores).some((d) => d.niveles?.includes(nivel));
  const opciones = [
    hay('distrito') && { valor: 'distrito', texto: t('interfaz.comparador.su_distrito', { nombre: codigo.slice(5, 7) }) },
    hay('municipio') && { valor: 'municipio', texto: t('interfaz.comparador.su_municipio', { nombre: nombreTerritorio(t, 'municipio', municipio, territorios) }) },
    hay('provincia') && { valor: 'provincia', texto: t('interfaz.comparador.su_provincia', { nombre: nombreTerritorio(t, 'provincia', provincia, territorios) }) },
    hay('ccaa') && ccaa && { valor: 'ccaa', texto: t('interfaz.comparador.su_ccaa', { nombre: nombreTerritorio(t, 'ccaa', ccaa, territorios) }) },
    hay('nacional') && { valor: 'nacional', texto: t('vocabulario.nivel.nacional') },
    { valor: 'seccion', texto: esSeccion(estado.comparar) ? t('interfaz.ficha.seccion', { codigo: estado.comparar }) : t('interfaz.comparador.otra_seccion') },
  ].filter(Boolean);
  const eleccion = eligiendoComparada || esSeccion(estado.comparar) ? 'seccion' : estado.comparar ?? '';
  const comparado = estado.comparar && !eligiendoComparada ? codigoComparado(codigo, estado.comparar, territorios) : null;
  const filas = comparado
    ? await filasComparador({ m, seccion: codigo, comparado, anio: v.referencia, supuestos: v.supuestos, seriesA, serieDe: serieTipo })
    : null;
  if (yo !== turnoFicha) return;
  pintarComparador(hueco, {
    t, eleccion, opciones, filas, eligiendo: eligiendoComparada, supuestos: v.supuestos, estados: m.codificacion.estados,
    nombreA: t('interfaz.comparador.esta_seccion'),
    nombreB: comparado ? nombreTerritorio(t, comparado.nivel, comparado.codigo, territorios) : '',
    alElegir: (valor) => {
      eligiendoComparada = valor === 'seccion';
      estado.comparar = valor && valor !== 'seccion' ? valor : undefined;
      mapa.comparar(null);
      pintarFicha();
      guardarEstado(estado);
    },
    alCancelar: () => {
      eligiendoComparada = false;
      pintarFicha();
    },
  });
}

// --- Descargas ------------------------------------------------------------------------------

// Nombre de un territorio en el CSV (las secciones y los distritos, con su municipio).
function nombreParaExportar(nivel, codigo) {
  if (nivel === 'sc' || nivel === 'distrito') {
    const municipio = ordenNatural(territorios.municipio?.[codigo.slice(0, 5)] ?? codigo.slice(0, 5));
    return nivel === 'sc'
      ? t('interfaz.exportar.nombre_seccion', { municipio, distrito: codigo.slice(5, 7), seccion: codigo.slice(7) })
      : t('interfaz.exportar.nombre_distrito', { municipio, distrito: codigo.slice(5, 7) });
  }
  return nombreTerritorio(t, nivel, codigo, territorios);
}

// Fecha de los datos («2026-11-08» → «8 de noviembre de 2026», «8 November 2026»).
function fechaLarga(fecha) {
  const d = /^\d{4}-\d{2}-\d{2}$/.test(fecha ?? '') ? new Date(`${fecha}T00:00:00Z`) : null;
  if (!d) return fecha ?? '';
  return new Intl.DateTimeFormat(t.idioma === 'en' ? 'en-GB' : 'es-ES', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(d);
}

// Fuentes de las series (y «cálculo propio» si el mapa transforma la serie).
function fuentesDe(series, calculado) {
  const ids = [...new Set(series.map((s) => m.indicadores[s]?.fuente).filter(Boolean))];
  if (calculado && !ids.includes('calculo_propio')) ids.push('calculo_propio');
  return ids.map((id) => (t.existe(`fuentes.${id}`) ? t(`fuentes.${id}`) : id)).join('; ');
}

// CSV de la serie del mapa en el nivel que se ve. En «¿te llega?», el alquiler que usa el mapa
// (sin el ingreso: con «Tu ficha», es el sueldo escrito por el usuario). Con un año anterior a la
// serie, las filas van sin valor y el estado dice desde cuándo hay serie.
async function exportarCsv(v) {
  const serie = v.seriesColor[0];
  const def = m.indicadores[serie];
  const derivado = v.modo === 'necesario' && usaSupuestos(v.mapa);
  const id = v.modo === 'necesario' ? estado.mapa : def.indicador ?? def.por_defecto ?? serie;
  const nivel = nivelParaExportar(mapa.nivelVisible(), nivelesDe(serie));
  const periodo = v.fuera ? v.fuera.anio : v.periodo;
  const codigos = await cargarIndice(m, nivel);
  const datos = v.fuera ? vacia(serie, nivel, codigos?.length ?? 0) : await cargarValores(m, serie, nivel, periodo);
  if (!codigos || !datos) throw new Error(`Sin datos de ${serie} en ${nivel} (${periodo})`);
  const formula = derivado ? formulaDe(v.mapa) : null;
  const { cabecera, filas } = tablaCsv({
    t, codigos, valores: datos.valores, estados: datos.estados, nombresEstado: m.codificacion.estados,
    nivel, nombreDe: (codigo) => nombreParaExportar(nivel, codigo),
    indicador: t(`indicadores.${id}.nombre`), unidad: t(`indicadores.${id}.unidad`),
    tipologia: v.tipologia ? t(`vocabulario.tipologia.${v.tipologia}`) : '', periodo,
    fuente: fuentesDe([serie], derivado),
    transformar: formula ? (x) => formula.calcular(x, v.supuestos) : null,
    decimales: decimalesDeEscala(m.indicadores[serie]?.escala ?? m.codificacion.escala),
    supuestos: derivado ? v.supuestos : null,
    desde: v.fuera ? v.fuera.desde : null,
  });
  const nombre = nombreFichero({ mapa: id, periodo, tipologia: v.tipologia, nivel, extension: 'csv' });
  descargar(new Blob([textoCsv(cabecera, filas)], { type: 'text/csv;charset=utf-8' }), nombre);
  return nombre;
}

// PNG del mapa tal como se ve, con su leyenda y la fuente. Con «Tu ficha», el ingreso se nombra
// sin la cifra. Con un año anterior a la serie, el mapa sale sin dato y el subtítulo dice desde
// cuándo hay serie.
async function exportarPng(v) {
  const llega = v.modo === 'llega';
  const periodo = v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo;
  const titulo = llega ? `${t('interfaz.leyenda.llega_titulo')} · ${t(`fichas.${estado.ficha}`)}` : t(`indicadores.${estado.mapa}.nombre`);
  const partes = [];
  if (llega) {
    const { vivienda, ingreso } = textosLlega(v, { sinCifra: true });
    partes.push(t('interfaz.leyenda.llega_sub', { vivienda, ingreso }));
  } else partes.push(t(`indicadores.${estado.mapa}.unidad`));
  partes.push(t.periodo(periodo));
  if (v.fuera) partes.push(t('interfaz.exportar.estados.fuera', { desde: t.periodo(v.fuera.desde) }));
  if (v.tipologia) partes.push(t(`vocabulario.tipologia.${v.tipologia}`));
  if (!llega && usaSupuestos(v.mapa)) partes.push(t('interfaz.leyenda.supuestos', { superficie: t.numero(v.supuestos.superficie_m2), umbral: t.porcentaje(v.umbral) }));
  if (llega) partes.push(t('interfaz.exportar.umbral', { umbral: t.porcentaje(v.umbral) }));

  const leyenda = llega
    ? { tipo: 'lista', elementos: colores.llega.map((color, i) => ({ color, texto: t(`interfaz.leyenda.llega_${i + 1}`) })) }
    : {
      tipo: 'tramos',
      colores: pasosDeRampa(v.mapa.cortes.length + 1, colores.rampa.length).map((i) => colores.rampa[i]),
      etiquetas: v.mapa.cortes.map((corte) => t.numero(corte, decimalesDeCortes(v.mapa.cortes, v.mapa.decimales ?? 0))),
    };
  const calculado = llega || usaSupuestos(v.mapa);
  const blob = await imagenMapa({
    mapa: mapa.mapa,
    titulo,
    subtitulo: partes.join(' · '),
    leyenda,
    claves: { sinDato: t('interfaz.leyenda.sin_dato'), secreto: t('interfaz.leyenda.secreto') },
    pie: [
      t('interfaz.exportar.fuente', { fuente: fuentesDe(v.seriesColor, calculado) }),
      t('interfaz.exportar.pie', { atribucion: m.mapa_base?.atribucion ?? '', fecha: fechaLarga(m.generado) }),
    ],
    ejemplo: m.ejemplo ? t('avisos.ejemplo') : null,
  });
  const nombre = nombreFichero({ mapa: llega ? `te_llega_${estado.ficha}` : estado.mapa, periodo, tipologia: v.tipologia, extension: 'png' });
  descargar(blob, nombre);
  return nombre;
}

async function exportar(formato) {
  if (!mapa) return;
  // Pregunta abierta 23: con «Tu ficha», los colores de la imagen dejan deducir el sueldo de forma
  // aproximada; antes de descargarla, el mismo aviso que con «Compartir». El CSV no lo necesita.
  if (formato === 'png' && vista().modo === 'llega' && estado.ficha === 'peon') {
    if (!(await avisoImagen.pedir({ t, sueldo: ingresoPeon(sueldo) }))) {
      barra.avisar(t('interfaz.exportar.cancelado'));
      return;
    }
  }
  const v = vista();
  barra.ocupado(formato, true);
  barra.avisar(t('interfaz.exportar.preparando'));
  try {
    const nombre = formato === 'csv' ? await exportarCsv(v) : await exportarPng(v);
    barra.avisar(t('interfaz.exportar.hecho', { fichero: nombre }));
  } catch (error) {
    console.error(error);
    barra.avisar(t('interfaz.exportar.error'), true);
  } finally {
    barra.ocupado(formato, false);
  }
}

// --- Acciones -------------------------------------------------------------------------------

function elegirSeccion(codigo) {
  estado.seccion = codigo ?? undefined;
  if (!codigo || estado.comparar === codigo) {
    estado.comparar = undefined;
    eligiendoComparada = false;
  }
  mapa.seleccionar(codigo);
  mapa.comparar(esSeccion(estado.comparar) ? estado.comparar : null);
  actualizar();
}

function alPulsar(codigo) {
  if (eligiendoComparada && estado.seccion && codigo !== estado.seccion) {
    eligiendoComparada = false;
    estado.comparar = codigo;
    mapa.comparar(codigo);
    pintarFicha();
    guardarEstado(estado);
    return;
  }
  elegirSeccion(codigo);
}

function alCambiarSueldo(cambio) {
  if ('sueldo' in cambio) {
    sueldo = cambio.sueldo;
    if (cambio.escrito) estado.ficha = sueldo ? 'peon' : estado.ficha === 'peon' ? undefined : estado.ficha;
  }
  if ('ficha' in cambio) estado.ficha = cambio.ficha ?? undefined;
  if ('superficie' in cambio) estado.superficie = cambio.superficie;
  if ('umbral' in cambio) estado.umbral = cambio.umbral;
  // «Ver el sueldo necesario»: vuelve a ese mapa.
  if (cambio.volver && m?.mapas[MAPA_POR_DEFECTO]) estado.mapa = MAPA_POR_DEFECTO;
  actualizar();
}

// Cambios de la barra: mapa (sale de «¿te llega?»), año o periodo, y tipología.
function alCambiarVista(cambio) {
  if ('mapa' in cambio && m.mapas[cambio.mapa]) {
    estado.mapa = cambio.mapa;
    if (modoDe(estado, sueldo, perfiles) === 'llega') estado.ficha = undefined;
  }
  if ('anio' in cambio) estado.anio = /^\d{4}$/.test(cambio.anio) ? Number(cambio.anio) : cambio.anio;
  if ('tipologia' in cambio) estado.tipologia = cambio.tipologia === 'VU' ? 'VU' : undefined;
  actualizar();
}

function abrirCompartir() {
  const sinPeon = { ...estado, ficha: estado.ficha === 'peon' ? undefined : estado.ficha };
  const conSueldo = ingresoPeon(sueldo) ? enlaceVista({ ...estado, ficha: 'peon' }, sueldo) : null;
  compartir.abrir({ t, conSueldo, sinSueldo: enlaceVista(sinPeon), sueldo: ingresoPeon(sueldo) });
}

function prepararBuscador() {
  let fuentes = null;
  crearBuscador({
    entrada: document.getElementById('buscador-entrada'),
    lista: document.getElementById('buscador-lista'),
    obtenerFuentes: async () => {
      fuentes ??= {
        municipios: Object.entries(territorios.municipio ?? {}).map(([codigo, nombre]) => [codigo, nombre, formasDeNombre(nombre)]),
        secciones,
      };
      return fuentes;
    },
    etiqueta: (o) => (o.tipo === 'municipio' ? `${ordenNatural(o.nombre)} (${o.codigo})` : t('interfaz.ficha.seccion', { codigo: o.codigo })),
    alElegir: async (o) => {
      const cajas = await cargarCajas(m).catch(() => ({}));
      const caja = cajas.municipio?.[o.codigo.slice(0, 5)];
      if (o.tipo === 'municipio') return mapa.irA(caja);
      elegirSeccion(o.codigo);
      if (caja) {
        mapa.irA(caja);
        mapa.mapa.once('moveend', () => mapa.encuadrarSeccion(o.codigo));
      } else mapa.encuadrarSeccion(o.codigo);
    },
  });
}

function marcarIdioma() {
  for (const boton of el.idiomas) boton.setAttribute('aria-pressed', String(boton.dataset.idioma === estado.idioma));
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  traducirPagina(t);
  marcarIdioma();
  if (mapa) {
    mapa.traducir(t);
    actualizar();
  } else guardarEstado(estado);
}

async function iniciar() {
  t = await cargarIdioma(estado.idioma);
  traducirPagina(t);
  marcarIdioma();
  for (const boton of el.idiomas) boton.addEventListener('click', () => cambiarIdioma(boton.dataset.idioma));
  panel = crearPanelSueldo({ alCambiar: alCambiarSueldo, alCompartir: abrirCompartir });
  panel.ponerSueldo(sueldo);
  barra = crearBarraVista({ alCambiar: alCambiarVista, alExportar: exportar });
  compartir = crearCompartir();
  avisoImagen = crearAvisoImagen();

  try {
    m = await cargarManifiesto();
    el.ejemplo.hidden = !m.ejemplo;
    if (!m.mapas[estado.mapa]) estado.mapa = m.mapas[MAPA_POR_DEFECTO] ? MAPA_POR_DEFECTO : Object.keys(m.mapas)[0];
    colores = coloresMapa();
    contornos = coloresContorno();

    [secciones, territorios, perfiles, mapa] = await Promise.all([
      cargarSecciones(m),
      cargarTerritorios(m),
      cargarPerfiles(m),
      crearMapa({
        contenedor: el.mapa,
        manifiesto: m,
        vista: estado.vista ? textoAVista(estado.vista) : null,
        t,
        alPulsar,
        alMover: (mp) => {
          estado.vista = vistaATexto(mp);
          guardarEstado(estado);
          if (mapa) avisarMapa();
        },
      }),
    ]);
    indice = new Map(secciones.map((codigo, i) => [codigo, i]));

    if (estado.ficha === 'peon' ? !ingresoPeon(sueldo) : estado.ficha && !perfiles[estado.ficha]) estado.ficha = undefined;
    if (estado.seccion && !indice.has(estado.seccion)) estado.seccion = undefined;
    if (!estado.seccion || (esSeccion(estado.comparar) && !indice.has(estado.comparar))) estado.comparar = undefined;
    if (estado.seccion) mapa.seleccionar(estado.seccion);
    if (esSeccion(estado.comparar)) mapa.comparar(estado.comparar);
    prepararBuscador();
    await actualizar();
  } catch (error) {
    fichaError(el.ficha, { t, error });
  }
}

iniciar();
