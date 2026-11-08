// Arranque de la web y coordinación: estado de la vista (URL), idioma, datos, mapa, leyenda,
// «Tu sueldo», ficha de sección, comparador, buscador y «Compartir».

import { leerEstado, guardarEstado, vistaATexto, textoAVista, leerSueldoCompartido, enlaceVista } from './estado.js';
import { cargarIdioma, traducirPagina } from './i18n.js';
import {
  cargarManifiesto, cargarSecciones, cargarTerritorios, cargarPerfiles, cargarCajas,
  cargarIndice, cargarValores, cargarSeries, periodoPara, periodosDe,
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

const estado = { idioma: 'es', ...leerEstado() };
let sueldo = leerSueldoCompartido();   // solo en memoria; en el enlace, solo con «Compartir»
if (sueldo && !estado.ficha) estado.ficha = 'peon';

const el = {
  mapa: document.getElementById('mapa'),
  leyenda: document.getElementById('leyenda'),
  ficha: document.getElementById('ficha'),
  ejemplo: document.getElementById('aviso-ejemplo'),
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
let compartir;     // diálogo «Compartir»
const columnas = {};            // serie → { valores, estados, periodo, clave } del año activo
let eligiendoComparada = false; // el siguiente clic en el mapa elige la sección con que comparar
let turno = 0;                  // descarta cálculos superados por otro más reciente
let turnoFicha = 0;

const mapaDef = () => m.mapas[estado.mapa];
const indiceEstado = (nombre) => m.codificacion.estados.indexOf(nombre);
const esSeccion = (x) => /^\d{10}$/.test(x ?? '');

// Lo que se pinta, a partir del estado: modo, superficie, umbral, cálculo y series necesarias.
function vista() {
  const modo = modoDe(estado, sueldo, perfiles);
  const superficie = superficieDe(estado, sueldo, perfiles);
  const umbral = umbralDe(estado);
  const supuestos = { superficie_m2: superficie ?? m.supuestos.superficie_m2, umbral };
  const calculo = modo === 'llega' ? calculoLlega({ ficha: estado.ficha, perfiles, sueldo, superficie }) : null;
  const seriesColor = calculo ? calculo.series : [mapaDef().base];
  const series = [...seriesColor];
  const renta = perfiles.llave?.ingreso.serie;
  if (!calculo && renta && m.indicadores[renta]) series.push(renta);   // banda de la llave en la regla
  return { modo, superficie, umbral, supuestos, calculo, seriesColor, series: [...new Set(series)] };
}

// Carga las series del año activo que falten, en cada nivel que pinta el mapa (secciones y, con
// poco zoom, municipios y provincias), y las guarda en sus elementos.
const otrosNiveles = {};   // nivel → serie → clave cargada
async function cargarColumnas(series) {
  await Promise.all(mapa.rellenos.map(async ({ capa, nivel }) => {
    const codigos = nivel === 'sc' ? secciones : await cargarIndice(m, nivel);
    if (!codigos) return;
    const nuevas = {};
    await Promise.all(series.map(async (serie) => {
      const def = m.indicadores[serie];
      if (!def) return;
      const periodo = periodoPara(def, estado.anio);
      const clave = `${serie}@${periodo}`;
      const cargada = nivel === 'sc' ? columnas[serie]?.clave : otrosNiveles[nivel]?.[serie];
      if (cargada === clave) return;
      const datos = await cargarValores(m, serie, nivel, periodo);
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

// Textos de «¿te llega?»: qué vivienda y qué ingreso.
function textosLlega(v) {
  const ficha = estado.ficha;
  const vivienda = ficha === 'llave'
    ? t('interfaz.sueldo.vivienda_llave')
    : t('interfaz.sueldo.vivienda_m2', { superficie: t.numero(v.superficie) });
  let ingreso;
  if (ficha === 'llave') ingreso = t('interfaz.sueldo.ingreso_llave');
  else if (ficha === 'peon') ingreso = t('interfaz.sueldo.ingreso_euros', { euros: t.numero(ingresoPeon(sueldo)) });
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

async function actualizar() {
  const yo = ++turno;
  const v = vista();
  await cargarColumnas(v.series);
  if (yo !== turno) return;

  for (const { capa, id } of mapa.rellenos) {
    const pintura = (paleta) => (v.modo === 'necesario'
      ? colorNecesario(mapaDef(), v.supuestos, paleta)
      : colorLlega(v.calculo, id, paleta));
    mapa.colorear(capa, pintura(colores), pintura(contornos), capa === 'secciones' ? secretos(v.seriesColor) : null);
  }

  const leyenda = { modo: v.modo, mapaId: estado.mapa, mapaDef: mapaDef(), superficie: v.supuestos.superficie_m2, umbral: v.umbral };
  let resumen = null;
  let detalle = null;
  if (v.modo === 'necesario') {
    Object.assign(leyenda, marcasRegla({ perfiles, seccion: estado.seccion, rentaHogar: columnas[perfiles.llave?.ingreso.serie]?.valores }));
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
  panel.pintar({ t, estado, sueldo, perfiles, modo: v.modo, superficie: v.superficie, umbral: v.umbral, resumen, detalle });
  pintarFicha(v);
  guardarEstado(estado);
}

// --- Ficha, evolución y comparador ---------------------------------------------------------

function pintarFicha(v = vista()) {
  const yo = ++turnoFicha;
  if (!estado.seccion) return fichaVacia(el.ficha, { t });
  const codigo = estado.seccion;
  const i = indice.get(codigo);
  const x = (serie) => valorEn(serie, i);
  let valor = null;
  if (v.modo === 'necesario') {
    const base = x(mapaDef().base);
    valor = base === null ? null : formulaDe(mapaDef()).calcular(base, v.supuestos);
  } else {
    const r = v.calculo.calcular(codigo, x);
    valor = r && { ...r, tramo: tramoLlega(r.ratio) };
  }
  const { huecoSerie, huecoComparador } = fichaSeccion(el.ficha, {
    t, codigo, territorios, modo: v.modo, mapaId: estado.mapa, mapaDef: mapaDef(), ficha: estado.ficha,
    supuestos: v.supuestos, anio: columnas[v.seriesColor[0]]?.periodo ?? estado.anio,
    valor, estado: peorEstado(v.seriesColor, i), estados: m.codificacion.estados, ejemplo: m.ejemplo,
    aviso: avisoAnios(v), alCerrar: () => elegirSeccion(null),
  });
  const series = cargarSeries(m, codigo).catch((error) => { console.error(error); return null; });
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
      if (b !== null) texto = t.numero(formulaDe(mapaDef()).calcular(b, v.supuestos), mapaDef().decimales ?? 0);
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
    ? await filasComparador({ m, seccion: codigo, comparado, anio: estado.anio, supuestos: v.supuestos, seriesA })
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
  compartir = crearCompartir();

  try {
    m = await cargarManifiesto();
    el.ejemplo.hidden = !m.ejemplo;
    if (!m.mapas[estado.mapa]) estado.mapa = Object.keys(m.mapas)[0];
    const anios = periodosDe(m.indicadores[mapaDef().base]);
    if (!anios.includes(estado.anio)) estado.anio = anios.at(-1);
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
