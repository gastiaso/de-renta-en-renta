// Arranque del mapa (mapa.html) y coordinación: estado de la vista (URL), idioma, datos, barra de
// la vista (mapa, año, tipología y descargas), mapa, leyenda, «Tu sueldo», ficha de sección o de
// territorio (municipio, provincia o comunidad; tarea 26), etiqueta al pasar el ratón (tarea 25),
// comparador, buscador y «Compartir».

import {
  leerEstado, guardarEstado, vistaATexto, textoAVista, leerSueldoCompartido, enlaceVista, leerTerritorio, territorioATexto,
} from './estado.js';
import { cargarIdioma, traducirPagina } from './i18n.js';
import {
  cargarManifiesto, cargarSecciones, cargarTerritorios, cargarPerfiles, cargarCajas, cargarSalarios,
  cargarIndice, cargarValores, cargarSeries, valorDe, periodoPara, periodosDe, fueraDeSerie,
  serieDeTipologia, tipologiaDe, tieneTipologia, cargarDetalle,
} from './datos.js';
import { crearMapa, coloresMapa, coloresContorno } from './mapa.js';
import { pintarLeyenda } from './leyenda.js';
import {
  fichaVacia, fichaSeccion, fichaSeries, fichaError, fichaSinSeccion, fichaContexto, fichaTerritorio, nombresTerritorio,
  fichaDeclaraciones, textoResto, fichaResidentes,
} from './ficha.js';
import { formulaDe, daSueldo, minimoDe, textoSupuestos } from './formulas.js';
import {
  modoDe, superficieDe, umbralDe, calculoLlega, colorLlega, colorNecesario, resumenLlega, resumenLlegaReal,
  marcasRegla, tramoLlega, ingresoPeon, intervaloMargen, enLimiteLlega, estadoLlega, perfilesDelAnio,
  eurosQueQuedan,
} from './sueldo.js';
import { seriesFiabilidad, fiabilidadFicha, umbralPocos } from './fiabilidad.js';
import { percentilSalarial } from './percentil.js';
import { crearPanelSueldo } from './panel_sueldo.js';
import { crearCompartir } from './compartir.js';
import { codigoComparado, nombreTerritorio, filasComparador, pintarComparador, nivelesSuperiores } from './comparador.js';
import { crearBuscador, formasDeNombre } from './buscador.js';
import { ordenNatural } from './nombres.js';
import { crearBarraVista } from './barra_vista.js';
import { tablaCsv, textoCsv, nombreFichero, descargar, nivelParaExportar, decimalesDeEscala, descargaPermitida } from './exportar.js';
import { imagenMapa } from './imagen.js';
import { pasosDeRampa, decimalesDeCortes } from './colores.js';
import { crearAvisoImagen } from './aviso_imagen.js';
import { opcionProximamente } from './familias.js';
import {
  variaciones, bandaMargen, pocosContratos, variacionIpc, enEuros, textosVariacion, notasEvolucion, graficoEvolucion, cargarIpc,
} from './evolucion.js';

const estado = { idioma: 'es', ...leerEstado() };
let sueldo = leerSueldoCompartido();   // solo en memoria; en el enlace, solo con «Compartir»
if (sueldo && !estado.ficha) estado.ficha = 'peon';

const el = {
  mapa: document.getElementById('mapa'),
  leyenda: document.getElementById('leyenda'),
  ficha: document.getElementById('ficha'),
  ejemplo: document.getElementById('aviso-ejemplo'),
  escala: document.getElementById('aviso-escala'),
  privado: document.getElementById('aviso-privado'),   // F5: etiqueta de dato privado de oferta
  periodo: document.getElementById('aviso-periodo'),
  idiomas: [...document.querySelectorAll('[data-idioma]')],
};

let t;             // traductor del idioma activo
let m;             // manifiesto
let secciones;     // códigos de sección en el orden de los valores
let indice;        // código → posición
let territorios;   // nombres por nivel
let perfiles;      // ingresos de las fichas
let salarios;      // curvas del percentil salarial (datos/salarios.json)
let mapa;          // funciones del mapa (mapa.js)
let colores;       // colores del mapa (tokens.css)
let contornos;     // colores del contorno de cada tramo
let panel;         // tarjeta «Tu sueldo»
let barra;         // barra de la vista
let compartir;     // diálogo «Compartir»
let avisoImagen;   // aviso antes de la imagen de «¿te llega?» con «Tu ficha»
const columnas = {};            // serie → { valores, estados, periodo, clave } del periodo activo
let eligiendoComparada = false; // el siguiente clic en el mapa elige la sección con que comparar
let sinSeccion = null;          // suelo sin sección pulsado: atributosSinSeccion() (sin sección elegida)
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

// --- F5: mapas sin sección (indicador 20 y los de F4), de categorías y de datos privados (portales) ---
// Nivel más fino del mapa activo: «municipio» en los mapas sin sección (nivel_minimo del manifiesto).
const nivelMinimoDe = (v) => (v.modo === 'necesario' ? v.mapa.nivel_minimo ?? 'sc' : 'sc');
// Indicador de los textos de un mapa: el suyo, o el `indicador` de los mapas por grupo (portales).
const idTextos = (id) => m.mapas[id]?.indicador ?? id;
// Operación y portal de un mapa por grupo (indicador 13), o null.
const grupoDe = (def) => (def?.corte && def?.grupo ? t(`vocabulario.${def.corte}.${def.grupo}`) : null);
// Nombre de un mapa en la barra: el del indicador y, en los mapas por grupo, su grupo.
const nombreMapa = (id) => [t(`indicadores.${idTextos(id)}.nombre`), grupoDe(m.mapas[id])].filter(Boolean).join(' · ');
// Etiqueta de dato privado de una serie: la de su fuente (vocabulario.etiqueta.<fuente>), o null.
function etiquetaPrivada(serie) {
  const fuente = m.indicadores[serie]?.fuente;
  return fuente && t.existe(`vocabulario.etiqueta.${fuente}`) ? t(`vocabulario.etiqueta.${fuente}`) : null;
}
const etiquetaVista = (v) => (v.modo === 'necesario' ? etiquetaPrivada(v.seriesColor[0]) : null);

// Lo que se pinta, a partir del estado: modo, superficie, umbral, cálculo, mapa con la serie de
// la tipología, series necesarias, periodo activo y tipología. Si el año elegido es anterior a
// toda la serie que da color, `periodo` es null y `fuera` dice desde cuándo hay serie (pregunta
// abierta 32); `referencia` es el periodo con que se buscan las demás series (comparador, llave).
function vista() {
  const modo = modoDe(estado, sueldo, perfiles);
  const superficie = superficieDe(estado, sueldo, perfiles);
  const umbral = umbralDe(estado);
  const supuestos = { superficie_m2: superficie ?? m.supuestos.superficie_m2, umbral };
  let calculo = modo === 'llega' ? calculoLlega({ ficha: estado.ficha, perfiles, sueldo, superficie, serie: serieTipo }) : null;
  const def = mapaDef();
  const mapaTipo = { ...def, base: serieTipo(def.base) };
  const seriesColor = calculo ? calculo.series : [mapaTipo.base];
  // El periodo lo marca la serie que da color (la primera; en «¿te llega?», el alquiler).
  const periodo = periodoPara(m.indicadores[seriesColor[0]], estado.anio);
  const fuera = fueraDeSerie(m.indicadores[seriesColor[0]], estado.anio);
  // Ingreso de las fichas del año del alquiler (regla 4): la tartera y el transistor tienen serie.
  const perfilesAnio = perfilesDelAnio(perfiles, periodo ?? estado.anio);
  if (calculo) calculo = calculoLlega({ ficha: estado.ficha, perfiles: perfilesAnio, sueldo, superficie, serie: serieTipo });
  // En el sueldo necesario, las fichas de una persona y la llave van en la regla de la leyenda.
  const enSueldo = !calculo && daSueldo(def);
  const series = [...seriesColor];
  const renta = perfiles.llave?.ingreso.serie;
  if (enSueldo && renta && m.indicadores[renta]) series.push(renta);   // banda de la llave en la regla
  // Tarea 40: la serie de la segunda cifra (el mínimo de 50 m² del sueldo necesario; en «¿te llega?»,
  // el alquiler mensual real), para la ficha y el resumen
  const segunda = calculo ? calculo.serieReal : !calculo && def.minimo ? serieTipo(def.minimo.base) : null;
  if (segunda && m.indicadores[segunda]) series.push(segunda);
  // Contratos y margen de la mediana de la serie que da color, para la ficha (preguntas 12 y 15 ampliadas)
  const fiabilidad = seriesFiabilidad(m, seriesColor[0]);
  if (fiabilidad) series.push(...Object.values(fiabilidad).filter((s) => m.indicadores[s]));
  return {
    modo, superficie, umbral, supuestos, calculo, mapa: mapaTipo, seriesColor, periodo, fuera, fiabilidad,
    referencia: periodo ?? estado.anio, enSueldo, tipologia: tipologiaDe(m, seriesColor[0]), series: [...new Set(series)],
    perfiles: perfilesAnio,
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
  else if (v.perfiles[ficha]?.nivel === 'provincia') ingreso = t('interfaz.sueldo.ingreso_provincia', { ficha: t(`fichas.${ficha}`) });
  else {
    // Ingreso nacional (la tartera) del año del alquiler y, si no es el último, también el vigente
    const p = v.perfiles[ficha];
    const ultimo = perfiles[ficha];
    ingreso = p && ultimo && p.anio !== ultimo.anio
      ? t('interfaz.sueldo.ingreso_euros_anio', {
        euros: t.numero(p.neto_mensual?.['00'] ?? 0), anio: p.anio,
        ultimo: ultimo.anio, euros_ultimo: t.numero(ultimo.neto_mensual?.['00'] ?? 0),
      })
      : t('interfaz.sueldo.ingreso_euros', { euros: t.numero(p?.neto_mensual?.['00'] ?? 0) });
  }
  return { vivienda, ingreso };
}

// Regla 4: si el ingreso de la ficha y el alquiler no son del mismo año, se dice.
function avisoAnios(v) {
  if (v.modo !== 'llega') return null;
  const alquiler = columnas[v.calculo.series[0]]?.periodo;
  let ingreso = null;
  if (estado.ficha === 'llave') ingreso = columnas[perfiles.llave.ingreso.serie]?.periodo;
  else if (estado.ficha !== 'peon') ingreso = v.perfiles[estado.ficha]?.anio;
  if (!ingreso || !alquiler || String(ingreso) === String(alquiler)) return null;
  return t('interfaz.sueldo.anios_distintos', { ingreso, alquiler });
}

// Barra de la vista: mapas del manifiesto (y, en «¿te llega?», esa opción delante), periodos de
// la serie que da color (y, delante, el año elegido si es anterior a la serie) y tipología.
function pintarBarra(v) {
  const llega = v.modo === 'llega';
  const mapas = Object.keys(m.mapas).map((id) => ({ valor: id, texto: nombreMapa(id) }));   // F5: con el grupo
  if (llega) mapas.unshift({ valor: '', texto: t('interfaz.vista.llega_opcion', { ficha: t(`fichas.${estado.ficha}`) }) });
  const proximamente = opcionProximamente(t, m.mapas);   // la oferta de Idealista, sin su capa
  if (proximamente) mapas.push(proximamente);
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
  mapa.ponerNivelMinimo(nivelMinimoDe(v));   // F5: sin sección, los municipios a toda escala
  const etiqueta = etiquetaVista(v);         // F5: dato privado de oferta, también sobre el mapa
  el.privado.hidden = !etiqueta;
  el.privado.textContent = etiqueta ?? '';
  await cargarColumnas(v.series, v.referencia);
  if (yo !== turno) return;

  for (const { capa, id, nivel } of mapa.rellenos) {
    const pintura = (paleta) => (v.modo === 'necesario'
      ? colorNecesario(v.mapa, v.supuestos, paleta)
      : colorLlega(v.calculo, id, paleta, nivel));
    mapa.colorear(capa, pintura(colores), pintura(contornos), capa === 'secciones' ? secretos(v.seriesColor) : null);
  }
  avisarMapa(v);

  const leyenda = {
    modo: v.modo, mapaId: idTextos(estado.mapa), mapaDef: v.mapa, superficie: v.supuestos.superficie_m2, umbral: v.umbral,
    grupo: v.modo === 'necesario' ? grupoDe(v.mapa) : null, etiqueta,   // F5
    periodo: v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo, tipologia: v.tipologia,
    conSupuestos: usaSupuestos(v.mapa), fuera: v.fuera ? textoFuera(v.fuera) : null,
    supuestos: v.supuestos,   // tarea 40: con el mínimo al lado, el texto de los supuestos lo dice
  };
  let resumen = null;
  let detalle = null;
  if (v.modo === 'necesario') {
    // La provincia de las fichas provinciales: la de la sección o la del municipio o provincia elegidos
    const terr = leerTerritorio(estado.territorio);
    const enProvincia = estado.seccion ?? (terr && terr.nivel !== 'ccaa' ? terr.codigo : undefined);
    if (v.enSueldo) Object.assign(leyenda, marcasRegla({ perfiles: v.perfiles, seccion: enProvincia, rentaHogar: columnas[perfiles.llave?.ingreso.serie]?.valores }));
  } else {
    const { vivienda, ingreso } = textosLlega(v);
    leyenda.vivienda = t('interfaz.leyenda.llega_sub', { vivienda, ingreso });
    const r = resumenLlega(v.calculo, secciones, valorEn, v.umbral);
    resumen = !r.con ? t('interfaz.sueldo.sin_datos') : t(estado.ficha === 'peon' ? 'interfaz.sueldo.resumen_peon' : 'interfaz.sueldo.resumen_ficha', {
      pct: t.porcentaje(r.proporcion), caben: t.numero(r.caben), total: t.numero(r.con), ficha: t(`fichas.${estado.ficha}`),
    });
    // Tarea 40: al lado, la misma proporción con el alquiler mensual mediano real de cada sección
    const real = r.con ? resumenLlegaReal(v.calculo, secciones, valorEn, v.umbral) : null;
    if (real) resumen += ` ${t('interfaz.sueldo.resumen_real', { pct: t.porcentaje(real.proporcion), caben: t.numero(real.caben), total: t.numero(real.con) })}`;
    // Tarea 44: qué estadístico usa la ficha y de quién, en una línea
    const metodo = t.existe(`fichas_metodo.${estado.ficha}`) ? t(`fichas_metodo.${estado.ficha}`) : null;
    detalle = [metodo, t('interfaz.sueldo.detalle', { vivienda, ingreso, umbral: t.porcentaje(v.umbral) }), avisoAnios(v),
      estado.ficha === 'transistor' ? t('interfaz.sueldo.nota_transistor') : null]
      .filter(Boolean).join(' ');
  }
  pintarLeyenda(el.leyenda, t, leyenda);
  panel.pintar({
    t, estado, sueldo, perfiles, modo: v.modo, superficie: v.superficie, umbral: v.umbral, resumen, detalle,
    sinEfecto: v.modo === 'necesario' && !usaSupuestos(v.mapa),
    soloMinimo: v.modo === 'necesario' && Boolean(v.mapa.minimo),   // tarea 40: la superficie solo cambia el mínimo
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

// Estado de la cifra de la ficha: en el modo «necesario», el peor de las series que dan color; en
// «¿te llega?», el del alquiler, o «ausente» si falta el ingreso de la ficha (pregunta 15 ampliada).
function estadoCifra(v, codigo, x, estadoDe) {
  if (v.modo !== 'llega') return Math.max(...v.seriesColor.map(estadoDe));
  return estadoLlega(estadoDe(v.seriesColor[0]), v.calculo.ingreso(codigo, x), indiceEstado('ausente'));
}

function pintarFicha(v = vista()) {
  const yo = ++turnoFicha;
  const terr = leerTerritorio(estado.territorio);
  // F5: en un mapa sin sección, la sección elegida se ve en la ficha de su municipio
  const porMunicipio = Boolean(estado.seccion) && nivelMinimoDe(v) === 'municipio';
  if ((!estado.seccion && terr) || porMunicipio) {
    pintarFichaTerritorio(v, porMunicipio ? { nivel: 'municipio', codigo: estado.seccion.slice(0, 5) } : terr, yo)
      .catch((error) => console.error(error));
    return;
  }
  if (!estado.seccion) {
    if (sinSeccion) return fichaSinSeccion(el.ficha, { t, ...sinSeccion, territorios, alCerrar: () => elegirSeccion(null) });
    return fichaVacia(el.ficha, { t, comparar: NIVELES_COMPARAR_VACIA.includes(estado.comparar) ? estado.comparar : null });
  }
  const codigo = estado.seccion;
  const i = indice.get(codigo);
  const x = (serie) => valorEn(serie, i);
  const estadoDe = (serie) => (i === undefined ? indiceEstado('ausente') : columnas[serie]?.estados[i] ?? indiceEstado('ausente'));
  // Fiabilidad de la mediana del alquiler que da color (sin serie de fiabilidad o fuera de la serie, nada)
  const fia = v.fiabilidad && !v.fuera ? v.fiabilidad : null;
  const margen = fia?.margen ? x(fia.margen) : null;
  const fiabilidad = fia?.contratos
    ? fiabilidadFicha({ contratos: x(fia.contratos), margen, estado: m.codificacion.estados[estadoDe(v.seriesColor[0])], umbral: umbralPocos(m) })
    : null;
  let valor = null;
  let intervalo = null;
  let enLimite = false;
  let minimo = null;
  if (v.modo === 'necesario') {
    const base = x(v.mapa.base);
    valor = base === null ? null : formulaDe(v.mapa).calcular(base, v.supuestos);
    // El intervalo, en los mapas que son el alquiler en alguna unidad (no en el esfuerzo, con la renta)
    if (tieneTipologia(m, v.mapa.base)) intervalo = intervaloMargen(valor, margen);
    // Tarea 40: al lado, el mínimo teórico con la superficie elegida (fuera de la serie, nada)
    if (!v.fuera) minimo = minimoDe(v.mapa, x, v.supuestos, serieTipo);
  } else {
    const r = v.calculo.calcular(codigo, x);
    valor = r && { ...r, tramo: tramoLlega(r.ratio) };
    enLimite = Boolean(r) && enLimiteLlega(r.ratio, margen);
  }
  const { huecoContexto, huecoSerie, huecoComparador, huecoResidentes } = fichaSeccion(el.ficha, {
    t, codigo, territorios, modo: v.modo, mapaId: idTextos(estado.mapa), mapaDef: v.mapa, ficha: estado.ficha,
    supuestos: v.supuestos, anio: v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo,
    tipologia: v.tipologia, valor, estado: estadoCifra(v, codigo, x, estadoDe), estados: m.codificacion.estados, ejemplo: m.ejemplo,
    aviso: [v.fuera && textoFuera(v.fuera), avisoAnios(v)].filter(Boolean).join(' ') || null, alCerrar: () => elegirSeccion(null),
    fiabilidad, intervalo, enLimite, sueldo, minimo,
    notas: notaPercentil(v, valor, columnas[v.seriesColor[0]]?.periodo ?? v.periodo, 'sc', codigo),
  });
  if (valor === null && !v.fuera) {
    contextoSinMediana(v, codigo, x)
      .then((filas) => { if (yo === turnoFicha) fichaContexto(huecoContexto, { t, filas }); })
      .catch((error) => console.error(error));
  }
  const series = seriesDeSeccion(codigo, v).catch((error) => { console.error(error); return null; });
  series.then((s) => { if (yo === turnoFicha && s) pintarEvolucion(huecoSerie, s, v, codigo); });
  series.then((s) => pintarComparadorFicha(huecoComparador, s, v, codigo, yo)).catch((error) => console.error(error));
  series.then((s) => { if (yo === turnoFicha && s) pintarResidentes(huecoResidentes, v, 'sc', codigo, s); })
    .catch((error) => console.error(error));
}

// Tarea 41 (decisión 10): el indicador 14, fuera del selector del mapa, en la ficha de la sección (de
// sus series, fichas/<municipio>.json) y del municipio (del fichero del periodo), en el periodo de
// referencia de la vista y con su aviso de lectura. No va en «¿te llega?» con la llave, que ya da
// ese mismo cociente como cifra principal (con el aviso).
const SERIE_RESIDENTES = 'esfuerzo_residentes';
async function pintarResidentes(hueco, v, nivel, codigo, series = null) {
  const def = m.indicadores[SERIE_RESIDENTES];
  if (!hueco || !def || !nivelesDe(SERIE_RESIDENTES).includes(nivel) || (v.modo === 'llega' && estado.ficha === 'llave')) return;
  const periodo = periodoPara(def, v.referencia);
  if (periodo === null) return;
  let lectura = null;
  const s = series?.[SERIE_RESIDENTES];
  if (s) {
    const k = s.anios.findIndex((p) => String(p) === String(periodo));
    lectura = k < 0 ? null : { valor: s.valores[k], estado: s.estados[k] };
  } else lectura = await valorDe(m, SERIE_RESIDENTES, nivel, codigo, periodo);
  if (!hueco.isConnected) return;
  fichaResidentes(hueco, { t, valor: lectura?.valor ?? null, estado: lectura?.estado, estados: m.codificacion.estados, anio: periodo });
}

// Contexto de una sección sin mediana del alquiler de su tipología (pregunta 12 ampliada): la
// mediana de la otra tipología en la sección y la de la misma tipología en su municipio, en la
// unidad del mapa. Rotulado como contexto, nunca se pinta en el mapa (regla 1). Solo en los mapas
// del alquiler (los que tienen tipología) y en «¿te llega?».
async function contextoSinMediana(v, codigo, x) {
  const base = v.seriesColor[0];
  if (!tieneTipologia(m, base)) return [];
  const periodo = columnas[base]?.periodo ?? v.periodo;
  if (periodo === null || periodo === undefined) return [];
  const tipologia = v.tipologia ?? 'VC';
  const otra = tipologia === 'VU' ? 'VC' : 'VU';
  const serieOtra = serieDeTipologia(m, base, otra);
  const municipio = codigo.slice(0, 5);
  const [enSeccion, enMunicipio] = await Promise.all([
    serieOtra !== base ? valorDe(m, serieOtra, 'sc', codigo, periodo) : null,
    valorDe(m, base, 'municipio', municipio, periodo),
  ]);
  // Cifra en la unidad del mapa: el sueldo necesario o el alquiler, o la proporción del ingreso
  const enUnidad = (alquiler) => {
    if (alquiler === null || alquiler === undefined) return null;
    if (v.modo === 'necesario') {
      const d = v.mapa.decimales ?? 0;
      return `${t.numero(formulaDe(v.mapa).calcular(alquiler, v.supuestos), d)} ${t(`indicadores.${estado.mapa}.unidad`)}`;
    }
    const r = v.calculo.calcular(codigo, (s) => (s === base ? alquiler : x(s)));
    return r ? `${t.porcentaje(r.ratio)} ${t('interfaz.ficha.del_ingreso')}` : null;
  };
  const filas = [];
  const cifraSeccion = enUnidad(enSeccion?.valor);
  if (cifraSeccion) filas.push({ texto: t('interfaz.ficha.contexto_tipologia', { tipologia: t(`vocabulario.tipologia.${otra}`) }), cifra: cifraSeccion });
  const cifraMunicipio = enUnidad(enMunicipio?.valor);
  if (cifraMunicipio) {
    filas.push({
      texto: t('interfaz.ficha.contexto_municipio', {
        tipologia: t(`vocabulario.tipologia.${tipologia}`),
        municipio: ordenNatural(territorios.municipio?.[municipio] ?? municipio),
      }),
      cifra: cifraMunicipio,
    });
  }
  return filas;
}

// `nivel`: el del territorio ('sc' en la ficha de sección); en una comunidad, las fichas con ingreso
// por provincia quedan sin dato (calculoLlega).
function pintarEvolucion(hueco, series, v, codigo, nivel = 'sc') {
  const base = v.seriesColor[0];
  const periodos = series[base]?.anios;
  if (!periodos) return;
  // Valor de cada serie en un periodo (si la serie no lo tiene, sin dato).
  const en = (serie, p) => {
    const s = series[serie];
    const k = s ? s.anios.findIndex((q) => String(q) === String(p)) : -1;
    return k < 0 ? { valor: null, estado: indiceEstado('ausente') } : { valor: s.valores[k], estado: s.estados[k] };
  };
  // En «¿te llega?», cada año con el ingreso de la ficha de ese año si lo tiene (la tartera, la
  // mochila y el transistor; regla 4); si no («Tu ficha»), con el de hoy.
  const ficha = estado.ficha;
  const conSerie = (p) => Boolean(perfiles[ficha]?.anios?.[String(p)]);
  const calculoNivel = nivel === 'sc' || !v.calculo
    ? v.calculo
    : calculoLlega({ ficha, perfiles: v.perfiles, sueldo, superficie: v.superficie, serie: serieTipo, nivel });
  const calculoDe = (p) => (ficha !== 'llave' && conSerie(p)
    ? calculoLlega({ ficha, perfiles: perfilesDelAnio(perfiles, p), sueldo, superficie: v.superficie, serie: serieTipo, nivel })
    : calculoNivel);
  const filas = periodos.map((p) => {
    const estadoPeor = v.modo !== 'llega'
      ? Math.max(...v.seriesColor.map((s) => en(s, p).estado))
      : estadoLlega(en(base, p).estado, calculoDe(p).ingreso(codigo, (serie) => en(serie, p).valor), indiceEstado('ausente'));
    let texto = '—';
    let resto = null;
    let cifra = null;   // la cifra sin formato, para el gráfico y las variaciones (tareas 43 y 45)
    if (v.modo === 'necesario') {
      const b = en(base, p).valor;
      const cat = v.mapa.categorias;   // F5: en los mapas de categorías, su texto
      if (b !== null && !cat) cifra = formulaDe(v.mapa).calcular(b, v.supuestos);
      if (b !== null) texto = cat ? t(`vocabulario.${cat.vocabulario}.${b}`) : t.numero(cifra, v.mapa.decimales ?? 0);
    } else {
      const r = calculoDe(p).calcular(codigo, (serie) => en(serie, p).valor);
      if (r) { texto = t.porcentaje(r.ratio); cifra = r.ratio; }
      resto = textoResto(t, eurosQueQuedan(r), { corto: true })?.texto ?? null;   // tarea 34
    }
    return { periodo: p, texto, estado: estadoPeor, resto, cifra };
  });
  let nota = null;
  if (v.modo === 'llega' && ficha !== 'llave') {
    nota = periodos.every(conSerie) ? t('interfaz.ficha.ingreso_anio') : t('interfaz.ficha.ingreso_fijo');
  }
  const datosSerie = {
    t, filas, estados: m.codificacion.estados, periodo: columnas[base]?.periodo,
    titulo: v.modo === 'necesario' ? t('interfaz.ficha.evolucion') : t('interfaz.ficha.evolucion_llega'),
    nota,
  };
  fichaSeries(hueco, datosSerie);
  // Tareas 43 y 45: cuando llegan los contratos y el margen de cada año y el IPC, el gráfico con la
  // banda, las variaciones con la regla de los contratos y el aviso de euros corrientes.
  completarEvolucion(hueco, datosSerie, v, codigo, nivel, periodos).catch((error) => console.error(error));
}

// Contratos y margen de la mediana del alquiler de cada periodo en un territorio (tarea 43): de
// los ficheros de cada periodo, como la ficha (no van en las fichas por municipio; nota §9.2).
// { contratos, margen }, con un valor (o null) por periodo; null sin series de fiabilidad.
async function fiabilidadEnPeriodos(v, nivel, codigo, periodos) {
  const fia = v.fiabilidad;
  if (!fia || v.fuera) return null;
  const leer = async (serie) => {
    const def = m.indicadores[serie];
    if (!serie || !def || !nivelesDe(serie).includes(nivel)) return null;
    const propios = new Set(periodosDe(def).map(String));
    return Promise.all(periodos.map(async (p) => {
      if (!propios.has(String(p))) return null;
      const x = await valorDe(m, serie, nivel, codigo, p);
      return x && x.estado === indiceEstado('dato') ? x.valor : null;
    }));
  };
  const [contratos, margen] = await Promise.all([leer(fia.contratos), leer(fia.margen)]);
  return contratos || margen ? { contratos, margen } : null;
}

async function completarEvolucion(hueco, datosSerie, v, codigo, nivel, periodos) {
  const [fia, ipc] = await Promise.all([fiabilidadEnPeriodos(v, nivel, codigo, periodos), cargarIpc()]);
  if (!hueco.isConnected) return;   // la ficha ya es otra
  const { filas } = datosSerie;
  const cifras = filas.map((f) => f.cifra ?? null);
  const umbral = umbralPocos(m);
  // La banda, donde la ficha da el intervalo: los mapas que son el alquiler en alguna unidad y «¿te
  // llega?» (no en el esfuerzo, con la renta)
  const conBanda = v.modo === 'llega' || tieneTipologia(m, v.seriesColor[0]);
  const banda = conBanda ? bandaMargen(cifras, fia?.margen ?? null) : [];
  const pocos = pocosContratos(cifras, fia?.contratos ?? null, umbral);
  // Variaciones de un año: solo en las series del alquiler (con contratos) y en el modo «necesario»
  const lista = v.modo === 'necesario' && fia?.contratos ? variaciones({ periodos, valores: cifras, contratos: fia.contratos, umbral }) : [];
  const textos = textosVariacion(t, lista);
  const mapaId = idTextos(estado.mapa);
  const unidad = v.modo === 'necesario' ? t(`indicadores.${mapaId}.unidad`) : '';
  const conCifra = periodos.filter((p, i) => cifras[i] !== null);
  const euros = v.modo === 'necesario' ? (enEuros(unidad) ? 'cifra' : null) : (filas.some((f) => f.resto) ? 'resto' : null);
  const formato = v.modo === 'necesario' ? (x) => t.numero(x, v.mapa.decimales ?? 0) : (x) => t.porcentaje(x);
  const grafico = graficoEvolucion({
    t, periodos, valores: cifras, banda, pocos, activo: datosSerie.periodo, formato,
    etiqueta: t('interfaz.ficha.evolucion_grafico', {
      titulo: v.modo === 'necesario' ? t(`indicadores.${mapaId}.nombre`) : datosSerie.titulo,
      desde: t.periodo(periodos[0]), hasta: t.periodo(periodos.at(-1)),
    }),
  });
  fichaSeries(hueco, {
    ...datosSerie,
    filas: filas.map((f, i) => ({ ...f, variacion: textos[i] || null })),
    grafico,
    cabeceras: { periodo: t('interfaz.ficha.cabecera_periodo'), cifra: unidad, variacion: t('interfaz.ficha.cabecera_variacion') },
    notas: notasEvolucion(t, {
      banda: Boolean(grafico) && banda.some(Boolean), pocos: Boolean(grafico) && pocos.some(Boolean), umbral, lista, euros,
      ipc: euros && conCifra.length > 1 ? variacionIpc(ipc, conCifra[0], conCifra.at(-1)) : null,
    }),
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

// --- Ficha de territorio (tarea 26) ---------------------------------------------------------

// Niveles con que comparar que se pueden dejar elegidos sin sección (la casilla «Mudanza» de la
// portada abre el mapa con ?comparar=municipio: se aplica a la sección que se pulse).
const NIVELES_COMPARAR_VACIA = ['distrito', 'municipio', 'provincia', 'ccaa', 'nacional'];

// Valores de unas series en un territorio y su periodo: { serie: { valor, estado } | null }.
async function lecturasTerritorio(series, nivel, codigo, referencia) {
  const pares = await Promise.all(series.map(async (serie) => {
    const periodo = periodoPara(m.indicadores[serie], referencia);
    return [serie, periodo === null ? null : await valorDe(m, serie, nivel, codigo, periodo)];
  }));
  return Object.fromEntries(pares);
}

// Series de un territorio en todos sus periodos, para la evolución (como las de una sección).
async function seriesDeTerritorio(nivel, codigo, v) {
  const series = {};
  await Promise.all(v.seriesColor.filter((s) => m.indicadores[s] && nivelesDe(s).includes(nivel)).map(async (serie) => {
    const periodos = periodosDe(m.indicadores[serie]);
    const valores = await Promise.all(periodos.map((p) => valorDe(m, serie, nivel, codigo, p)));
    series[serie] = {
      anios: periodos,
      valores: valores.map((x) => x?.valor ?? null),
      estados: Uint8Array.from(valores, (x) => x?.estado ?? indiceEstado('ausente')),
    };
  }));
  return series;
}

// Percentil salarial del sueldo necesario (F3; web/js/percentil.js): una nota de la ficha, solo en el
// mapa del sueldo necesario, con la curva de los salarios de la comunidad del territorio y del año
// del alquiler (País Vasco y Navarra, que la AEAT no cubre, y España, con la de España).
function notaPercentil(v, valor, anio, nivel, codigo) {
  if (v.modo !== 'necesario' || estado.mapa !== 'sueldo_necesario' || v.fuera || !Number.isFinite(valor)) return [];
  const ccaa = nivel === 'nacional' ? '00' : nivel === 'ccaa' ? codigo : territorios.ccaa_de_provincia?.[codigo.slice(0, 2)];
  const p = percentilSalarial(salarios, { valor, anio, ccaa });
  if (!p) return [];
  if (p.sinCurva) return p.desde ? [t('interfaz.ficha.percentil_desde', { anio: p.desde })] : [];
  const ambito = p.ambito === '00' ? t('vocabulario.nivel.nacional') : ordenNatural(territorios.ccaa?.[p.ambito] ?? p.ambito);
  const clave = p.percentil <= 0 ? 'percentil_bajo' : p.percentil >= 100 ? 'percentil_alto' : 'percentil';
  return [t(`interfaz.ficha.${clave}`, { percentil: t.numero(Math.round(p.percentil)), ambito, anio: p.anio })];
}

// Ficha de un municipio, una provincia o una comunidad: la cifra del mapa activo publicada en su
// nivel (regla 1: si alguna serie que da color no llega a él, «sin dato en este nivel»; nunca se
// suman secciones), su evolución y el comparador con los territorios que lo contienen.
async function pintarFichaTerritorio(v, { nivel, codigo }, yo) {
  const base = v.seriesColor[0];
  const tieneNivel = v.seriesColor.every((s) => nivelesDe(s).includes(nivel));
  const calculo = v.modo === 'llega'
    ? calculoLlega({ ficha: estado.ficha, perfiles: v.perfiles, sueldo, superficie: v.superficie, serie: serieTipo, nivel })
    : null;
  const fia = v.fiabilidad && !v.fuera ? v.fiabilidad : null;
  const auxiliares = fia ? Object.values(fia).filter((s) => m.indicadores[s] && nivelesDe(s).includes(nivel)) : [];
  // Tarea 40: la serie de la segunda cifra (mínimo de 50 m² o alquiler mensual real), si llega al nivel
  const segunda = (calculo ? calculo.serieReal : v.mapa.minimo ? serieTipo(v.mapa.minimo.base) : null);
  if (segunda && m.indicadores[segunda] && nivelesDe(segunda).includes(nivel)) auxiliares.push(segunda);
  const lecturas = tieneNivel && !v.fuera ? await lecturasTerritorio([...v.seriesColor, ...auxiliares], nivel, codigo, v.referencia) : {};
  if (yo !== turnoFicha) return;
  const x = (serie) => lecturas[serie]?.valor ?? null;
  const estadoDe = (serie) => lecturas[serie]?.estado ?? indiceEstado('ausente');
  const margen = fia?.margen ? x(fia.margen) : null;
  const fiabilidad = fia?.contratos && lecturas[fia.contratos]
    ? fiabilidadFicha({ contratos: x(fia.contratos), margen, estado: m.codificacion.estados[estadoDe(base)], umbral: umbralPocos(m) })
    : null;
  let valor = null;
  let intervalo = null;
  let enLimite = false;
  let minimo = null;
  if (tieneNivel && v.modo === 'necesario') {
    const b = x(v.mapa.base);
    valor = b === null ? null : formulaDe(v.mapa).calcular(b, v.supuestos);
    if (tieneTipologia(m, v.mapa.base)) intervalo = intervaloMargen(valor, margen);
    if (!v.fuera) minimo = minimoDe(v.mapa, x, v.supuestos, serieTipo);   // tarea 40
  } else if (tieneNivel) {
    const r = calculo.calcular(codigo, x);
    valor = r && { ...r, tramo: tramoLlega(r.ratio) };
    enLimite = Boolean(r) && enLimiteLlega(r.ratio, margen);
  }
  const notas = [];
  if (calculo && nivel === 'ccaa' && v.perfiles[estado.ficha]?.nivel === 'provincia') {
    notas.push(t('interfaz.ficha.sin_ingreso_nivel', { ficha: t(`fichas.${estado.ficha}`) }));
  }
  const estadoCifraT = calculo
    ? estadoLlega(estadoDe(base), calculo.ingreso(codigo, x), indiceEstado('ausente'))
    : Math.max(...v.seriesColor.map(estadoDe));
  const periodoBase = periodoPara(m.indicadores[base], v.referencia);
  if (tieneNivel) notas.push(...notaPercentil(v, valor, periodoBase ?? v.periodo, nivel, codigo));
  // F5: en los mapas sin sección, cómo se lee el indicador (el 20: política pública, no mercado)
  if (nivelMinimoDe(v) === 'municipio') notas.push(t(`indicadores.${idTextos(estado.mapa)}.lectura`));
  const { huecoSerie, huecoComparador, huecoDetalle, huecoResidentes } = fichaTerritorio(el.ficha, {
    t, nivel, codigo, territorios, sinNivel: !tieneNivel, modo: v.modo, mapaId: idTextos(estado.mapa), mapaDef: v.mapa, ficha: estado.ficha,
    grupo: v.modo === 'necesario' ? grupoDe(v.mapa) : null, etiqueta: etiquetaVista(v),   // F5
    supuestos: v.supuestos, anio: v.fuera ? v.fuera.anio : periodoBase ?? v.periodo, tipologia: v.tipologia, valor,
    estado: estadoCifraT, estados: m.codificacion.estados, ejemplo: m.ejemplo,
    aviso: [v.fuera && textoFuera(v.fuera), avisoAnios(v)].filter(Boolean).join(' ') || null, alCerrar: () => elegirTerritorio(null),
    fiabilidad, intervalo, enLimite, sueldo, notas, minimo,
  });
  pintarResidentes(huecoResidentes, v, nivel, codigo).catch((error) => console.error(error));   // tarea 41
  // F5: declaraciones de zona tensionada del municipio (indicador 20; datos/zonas_tensionadas.json)
  if (v.modo === 'necesario' && v.mapa.detalle && nivel === 'municipio') {
    cargarDetalle(v.mapa.detalle)
      .then((d) => { if (yo === turnoFicha) fichaDeclaraciones(huecoDetalle, { t, declaraciones: d?.[codigo] ?? [], fecha: fechaLarga }); })
      .catch((error) => console.error(error));
  }
  if (tieneNivel) {
    seriesDeTerritorio(nivel, codigo, v)
      .then((s) => { if (yo === turnoFicha) pintarEvolucion(huecoSerie, s, v, codigo, nivel); })
      .catch((error) => console.error(error));
  }
  pintarComparadorTerritorio(huecoComparador, nivel, codigo, v, yo).catch((error) => console.error(error));
}

async function pintarComparadorTerritorio(hueco, nivel, codigo, v, yo) {
  const provincia = nivel === 'ccaa' ? null : codigo.slice(0, 2);
  const ccaa = nivel === 'ccaa' ? null : territorios.ccaa_de_provincia?.[provincia];
  const hay = (n) => Object.values(m.indicadores).some((d) => d.niveles?.includes(n));
  const superiores = nivelesSuperiores(nivel);
  const opciones = [
    superiores.includes('provincia') && hay('provincia') && { valor: 'provincia', texto: t('interfaz.comparador.su_provincia', { nombre: nombreTerritorio(t, 'provincia', provincia, territorios) }) },
    superiores.includes('ccaa') && hay('ccaa') && ccaa && { valor: 'ccaa', texto: t('interfaz.comparador.su_ccaa', { nombre: nombreTerritorio(t, 'ccaa', ccaa, territorios) }) },
    superiores.includes('nacional') && hay('nacional') && { valor: 'nacional', texto: t('vocabulario.nivel.nacional') },
  ].filter(Boolean);
  const eleccion = opciones.some((o) => o.valor === estado.comparar) ? estado.comparar : '';
  const comparado = eleccion ? codigoComparado(codigo, eleccion, territorios, nivel) : null;
  const filas = comparado
    ? await filasComparador({ m, seccion: codigo, nivelA: nivel, comparado, anio: v.referencia, supuestos: v.supuestos, seriesA: null, serieDe: serieTipo })
    : null;
  if (yo !== turnoFicha) return;
  pintarComparador(hueco, {
    t, eleccion, opciones, filas, eligiendo: false, supuestos: v.supuestos, estados: m.codificacion.estados,
    nombreA: t(`interfaz.comparador.este.${nivel}`),
    nombreB: comparado ? nombreTerritorio(t, comparado.nivel, comparado.codigo, territorios) : '',
    alElegir: (valor) => {
      estado.comparar = valor || undefined;
      pintarFicha();
      guardarEstado(estado);
    },
    alCancelar: () => {},
  });
}

// Caja [oeste, sur, este, norte] de un territorio: la de su municipio o la que reúne las de los
// municipios de su provincia o comunidad (cajas.json solo trae municipios).
function cajaTerritorio(cajas, { nivel, codigo }) {
  const todos = cajas?.municipio ?? {};
  if (nivel === 'municipio') return todos[codigo] ?? null;
  const dentro = (municipio) => (nivel === 'provincia'
    ? municipio.startsWith(codigo)
    : territorios.ccaa_de_provincia?.[municipio.slice(0, 2)] === codigo);
  const caja = [Infinity, Infinity, -Infinity, -Infinity];
  for (const [municipio, c] of Object.entries(todos)) {
    if (!dentro(municipio)) continue;
    caja[0] = Math.min(caja[0], c[0]); caja[1] = Math.min(caja[1], c[1]);
    caja[2] = Math.max(caja[2], c[2]); caja[3] = Math.max(caja[3], c[3]);
  }
  return Number.isFinite(caja[0]) ? caja : null;
}

// Etiqueta del mapa al pasar el ratón (tarea 25): lo mismo que dice la ficha. En las secciones, el
// municipio, el distrito (su número; el INE no publica nombres de distrito) y el código; en los
// municipios y las provincias, su nombre y el del territorio superior; en las comunidades, su nombre.
function etiquetaDe(nivel, codigo, datos = null) {
  if (!t || !territorios) return [];
  if (nivel === 'sc') {
    return [
      ordenNatural(territorios.municipio?.[codigo.slice(0, 5)] ?? codigo.slice(0, 5)),
      t('interfaz.etiqueta.distrito', { distrito: codigo.slice(5, 7) }),
      t('interfaz.etiqueta.seccion', { codigo }),
    ];
  }
  if (nivel === 'sin_seccion') return datos?.nombre ? [datos.nombre, t('interfaz.ficha.sin_seccion')] : [t('interfaz.ficha.sin_seccion')];
  return nombresTerritorio(nivel, codigo, territorios).slice(0, 2).map((x) => x.nombre);
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
  const idMapa = v.modo === 'necesario' ? estado.mapa : def.indicador ?? def.por_defecto ?? serie;
  const id = idTextos(idMapa);   // F5: los mapas por grupo toman los textos de su indicador
  const grupo = v.modo === 'necesario' ? grupoDe(v.mapa) : null;
  const categorias = v.modo === 'necesario' ? v.mapa.categorias : null;
  const nivel = nivelParaExportar(mapa.nivelVisible(), nivelesDe(serie));
  const periodo = v.fuera ? v.fuera.anio : v.periodo;
  const codigos = await cargarIndice(m, nivel);
  const datos = v.fuera ? vacia(serie, nivel, codigos?.length ?? 0) : await cargarValores(m, serie, nivel, periodo);
  if (!codigos || !datos) throw new Error(`Sin datos de ${serie} en ${nivel} (${periodo})`);
  const formula = derivado ? formulaDe(v.mapa) : null;
  // Contratos y margen de la mediana de la serie, si los tiene (columnas contratos y margen_pct)
  const fia = seriesFiabilidad(m, serie);
  const columnaDe = async (s) => (s && !v.fuera ? (await cargarValores(m, s, nivel, periodo))?.valores ?? null : null);
  const fiabilidad = fia ? { contratos: await columnaDe(fia.contratos), margen: await columnaDe(fia.margen) } : null;
  // Tarea 40: en el sueldo necesario, el mínimo teórico con la superficie elegida, en una columna más
  const defMinimo = derivado ? v.mapa.minimo : null;
  const serieMinimo = defMinimo ? serieTipo(defMinimo.base) : null;
  const minimo = serieMinimo && nivelesDe(serieMinimo).includes(nivel)
    ? { valores: await columnaDe(serieMinimo), transformar: (x) => formulaDe(defMinimo).calcular(x, v.supuestos) }
    : defMinimo ? { valores: null, transformar: null } : null;
  const { cabecera, filas } = tablaCsv({
    t, codigos, valores: datos.valores, estados: datos.estados, nombresEstado: m.codificacion.estados,
    nivel, nombreDe: (codigo) => nombreParaExportar(nivel, codigo),
    indicador: [t(`indicadores.${id}.nombre`), grupo].filter(Boolean).join(' · '), unidad: t(`indicadores.${id}.unidad`),
    tipologia: v.tipologia ? t(`vocabulario.tipologia.${v.tipologia}`) : '', periodo,
    fuente: fuentesDe([serie], derivado),
    transformar: formula ? (x) => formula.calcular(x, v.supuestos) : null,
    decimales: decimalesDeEscala(m.indicadores[serie]?.escala ?? m.codificacion.escala),
    supuestos: derivado ? v.supuestos : null,
    desde: v.fuera ? v.fuera.desde : null,
    fiabilidad,
    minimo,
    etiqueta: etiquetaPrivada(serie),   // F5: columna «etiqueta» (dato privado de oferta)
    categoria: categorias ? (x) => t(`vocabulario.${categorias.vocabulario}.${x}`) : null,   // F5: indicador 20
  });
  const nombre = nombreFichero({ mapa: idMapa, periodo, tipologia: v.tipologia, nivel, extension: 'csv' });
  descargar(new Blob([textoCsv(cabecera, filas)], { type: 'text/csv;charset=utf-8' }), nombre);
  return nombre;
}

// PNG del mapa tal como se ve, con su leyenda y la fuente. Con «Tu ficha», el ingreso se nombra
// sin la cifra. Con un año anterior a la serie, el mapa sale sin dato y el subtítulo dice desde
// cuándo hay serie.
async function exportarPng(v) {
  const llega = v.modo === 'llega';
  const periodo = v.fuera ? v.fuera.anio : columnas[v.seriesColor[0]]?.periodo ?? v.periodo;
  const titulo = llega ? `${t('interfaz.leyenda.llega_titulo')} · ${t(`fichas.${estado.ficha}`)}` : nombreMapa(estado.mapa);
  const etiqueta = etiquetaVista(v);   // F5: dato privado de oferta, en el subtítulo y al pie
  const partes = etiqueta ? [etiqueta] : [];
  if (llega) {
    const { vivienda, ingreso } = textosLlega(v, { sinCifra: true });
    partes.push(t('interfaz.leyenda.llega_sub', { vivienda, ingreso }));
  } else partes.push(t(`indicadores.${idTextos(estado.mapa)}.unidad`));
  partes.push(t.periodo(periodo));
  if (v.fuera) partes.push(t('interfaz.exportar.estados.fuera', { desde: t.periodo(v.fuera.desde) }));
  if (v.tipologia) partes.push(t(`vocabulario.tipologia.${v.tipologia}`));
  if (!llega && usaSupuestos(v.mapa)) partes.push(textoSupuestos(t, v.mapa, v.supuestos));   // tarea 40: con el mínimo, lo dice
  if (llega) partes.push(t('interfaz.exportar.umbral', { umbral: t.porcentaje(v.umbral) }));

  const tramosColor = (n) => pasosDeRampa(n, colores.rampa.length).map((i) => colores.rampa[i]);
  const cat = !llega && v.mapa.categorias;   // F5: mapa de categorías (indicador 20)
  const leyenda = llega
    ? { tipo: 'lista', elementos: colores.llega.map((color, i) => ({ color, texto: t(`interfaz.leyenda.llega_${i + 1}`) })) }
    : cat ? {
      tipo: 'lista',
      elementos: [...cat.valores].reverse().map((valor) => ({
        color: tramosColor(v.mapa.cortes.length + 1)[v.mapa.cortes.filter((c) => valor >= c).length],
        texto: t(`vocabulario.${cat.vocabulario}.${valor}`),
      })),
    } : {
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
      ...(etiqueta ? [etiqueta] : []),
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
  // Decisión 3: los datos privados de oferta (capa de portales) no se descargan en CSV
  if (!descargaPermitida(formato, etiquetaPrivada(v.seriesColor[0]))) {
    barra.avisar(t('interfaz.exportar.privado'), true);
    return;
  }
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

// `hueco`: el suelo sin sección pulsado (atributosSinSeccion), que ocupa la ficha sin elegir sección.
function elegirSeccion(codigo, hueco = null) {
  sinSeccion = codigo ? null : hueco;
  estado.seccion = codigo ?? undefined;
  estado.territorio = undefined;
  mapa.seleccionarTerritorio(null);
  if (!codigo || estado.comparar === codigo) {
    estado.comparar = undefined;
    eligiendoComparada = false;
  }
  mapa.seleccionar(codigo);
  mapa.comparar(esSeccion(estado.comparar) ? estado.comparar : null);
  actualizar();
}

// Un municipio, una provincia o una comunidad (tarea 26): su ficha sustituye a la de la sección.
// Se queda el nivel con que comparar si lo contiene; otra sección o un nivel menor, no.
function elegirTerritorio(nivel, codigo) {
  sinSeccion = null;
  eligiendoComparada = false;
  estado.seccion = undefined;
  estado.territorio = codigo ? territorioATexto(nivel, codigo) : undefined;
  if (!codigo || !nivelesSuperiores(nivel).includes(estado.comparar)) estado.comparar = undefined;
  mapa.seleccionar(null);
  mapa.comparar(null);
  mapa.seleccionarTerritorio(codigo ? { nivel, codigo } : null);
  actualizar();
}

const alPulsarTerritorio = (nivel, codigo) => elegirTerritorio(nivel, codigo);

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

// Suelo sin sección: su ficha sustituye a la de la sección elegida y cancela la elección de la
// sección con que comparar (no tiene datos que comparar).
function alPulsarSinSeccion(hueco) {
  eligiendoComparada = false;
  elegirSeccion(null, hueco);
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
      if (o.tipo === 'municipio') {
        elegirTerritorio('municipio', o.codigo);   // su ficha (tarea 26)
        return mapa.irA(caja);
      }
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
  document.title = `${t('nav.mapa')} · ${t('sitio.titulo')}`;
  marcarIdioma();
  if (mapa) {
    mapa.traducir(t);
    actualizar();
  } else guardarEstado(estado);
}

async function iniciar() {
  const vistaDelEnlace = Boolean(estado.vista);
  t = await cargarIdioma(estado.idioma);
  traducirPagina(t);
  document.title = `${t('nav.mapa')} · ${t('sitio.titulo')}`;
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

    const pedirSalarios = cargarSalarios(m).catch((error) => { console.error(error); return null; });
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
        alPulsarSinSeccion,
        alPulsarTerritorio,
        etiqueta: document.getElementById('mapa-etiqueta'),
        etiquetaDe,
        alMover: (mp) => {
          estado.vista = vistaATexto(mp);
          guardarEstado(estado);
          if (mapa) avisarMapa();
        },
      }),
    ]);
    salarios = await pedirSalarios;
    indice = new Map(secciones.map((codigo, i) => [codigo, i]));

    if (estado.ficha === 'peon' ? !ingresoPeon(sueldo) : estado.ficha && !perfiles[estado.ficha]) estado.ficha = undefined;
    if (estado.seccion && !indice.has(estado.seccion)) estado.seccion = undefined;
    // Territorio elegido (tarea 26): solo sin sección, en un nivel que el mapa pinta y con un código de su índice
    let terr = estado.seccion ? null : leerTerritorio(estado.territorio);
    if (terr && (!mapa.niveles.includes(terr.nivel) || !(await cargarIndice(m, terr.nivel).catch(() => null))?.includes(terr.codigo))) terr = null;
    estado.territorio = terr ? territorioATexto(terr.nivel, terr.codigo) : undefined;
    // Con qué comparar: otra sección, solo con sección; un nivel, el que contiene lo elegido o, sin
    // nada elegido, el que se aplicará a la sección que se pulse (casilla «Mudanza» de la portada)
    if (esSeccion(estado.comparar) ? !estado.seccion || !indice.has(estado.comparar)
      : terr && !nivelesSuperiores(terr.nivel).includes(estado.comparar)) estado.comparar = undefined;
    if (estado.seccion) mapa.seleccionar(estado.seccion);
    if (terr) mapa.seleccionarTerritorio(terr);
    if (esSeccion(estado.comparar)) mapa.comparar(estado.comparar);
    prepararBuscador();
    await actualizar();
    // Sin vista en el enlace (desde la portada: el dado o el buscador), el mapa va a lo elegido
    if (!vistaDelEnlace && (estado.seccion || terr)) {
      const cajas = await cargarCajas(m).catch(() => ({}));
      if (estado.seccion) {
        const caja = cajas.municipio?.[estado.seccion.slice(0, 5)];
        const codigo = estado.seccion;
        if (caja) {
          mapa.irA(caja);
          mapa.mapa.once('moveend', () => mapa.encuadrarSeccion(codigo));
        } else mapa.encuadrarSeccion(codigo);
      } else mapa.irA(cajaTerritorio(cajas, terr));
    }
  } catch (error) {
    fichaError(el.ficha, { t, error });
  }
}

iniciar();
