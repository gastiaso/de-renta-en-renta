// Arranque de la web: idioma, manifiesto de datos, mapa, leyenda y ficha, con el estado de la
// vista en la URL (estado.js).

import { leerEstado, guardarEstado, vistaATexto, textoAVista } from './estado.js';
import { cargarIdioma, traducirPagina } from './i18n.js';
import { cargarManifiesto, cargarSecciones, cargarTerritorios, cargarIndicador, cargarSeries } from './datos.js';
import { crearMapa } from './mapa.js';
import { pintarLeyenda } from './leyenda.js';
import { fichaVacia, fichaSeccion, fichaSeries, fichaError } from './ficha.js';
import { formulaDe } from './formulas.js';

const estado = { idioma: 'es', ...leerEstado() };
const el = {
  mapa: document.getElementById('mapa'),
  leyenda: document.getElementById('leyenda'),
  ficha: document.getElementById('ficha'),
  ejemplo: document.getElementById('aviso-ejemplo'),
  idiomas: [...document.querySelectorAll('[data-idioma]')],
};

let t;            // traductor del idioma activo
let manifiesto;   // qué datos hay y dónde
let secciones;    // códigos en el orden de los valores
let indice;       // código → posición
let territorios;  // nombres por nivel
let datos;        // valores y estados del indicador base del mapa activo
let mapa;         // funciones del mapa (mapa.js)

let turnoFicha = 0; // descarta series que llegan cuando la ficha ya es otra

const mapaDef = () => manifiesto.mapas[estado.mapa];

function marcarIdioma() {
  for (const boton of el.idiomas) boton.setAttribute('aria-pressed', String(boton.dataset.idioma === estado.idioma));
}

function pintarFicha() {
  const turno = ++turnoFicha;
  if (!estado.seccion) return fichaVacia(el.ficha, { t });
  const def = mapaDef();
  const calcular = (x) => formulaDe(def).calcular(x, manifiesto.supuestos);
  const { estados } = manifiesto.codificacion;
  const seccion = estado.seccion;
  const i = indice.get(seccion);
  const base = i === undefined ? null : datos.valores[i];
  fichaSeccion(el.ficha, {
    t,
    codigo: seccion,
    territorios,
    mapaId: estado.mapa,
    mapaDef: def,
    anio: estado.anio,
    valor: base === null ? null : calcular(base),
    estado: i === undefined ? estados.indexOf('ausente') : datos.estados[i],
    estados,
    ejemplo: manifiesto.ejemplo,
    alCerrar: () => elegirSeccion(null),
  });
  // Evolución en la sección: fichas/<municipio>.json, que se pide solo al abrir la ficha.
  cargarSeries(manifiesto, seccion)
    .then((series) => {
      const serie = series?.[def.base];
      if (serie && turno === turnoFicha) fichaSeries(el.ficha, { t, serie, mapaDef: def, calcular, estados, anio: estado.anio });
    })
    .catch((error) => console.error(error));
}

function pintarLeyendaActiva() {
  pintarLeyenda(el.leyenda, { t, mapaId: estado.mapa, mapaDef: mapaDef(), supuestos: manifiesto.supuestos });
}

function elegirSeccion(codigo) {
  estado.seccion = codigo ?? undefined;
  mapa.seleccionar(codigo);
  pintarFicha();
  guardarEstado(estado);
}

async function cambiarIdioma(idioma) {
  if (idioma === estado.idioma) return;
  estado.idioma = idioma;
  t = await cargarIdioma(idioma);
  traducirPagina(t);
  marcarIdioma();
  if (mapa) {
    mapa.traducir(t);
    pintarLeyendaActiva();
    pintarFicha();
  }
  guardarEstado(estado);
}

async function iniciar() {
  t = await cargarIdioma(estado.idioma);
  traducirPagina(t);
  marcarIdioma();
  for (const boton of el.idiomas) boton.addEventListener('click', () => cambiarIdioma(boton.dataset.idioma));

  try {
    manifiesto = await cargarManifiesto();
    el.ejemplo.hidden = !manifiesto.ejemplo;

    if (!manifiesto.mapas[estado.mapa]) estado.mapa = Object.keys(manifiesto.mapas)[0];
    const anios = manifiesto.indicadores[mapaDef().base].anios;
    if (!anios.includes(estado.anio)) estado.anio = anios.at(-1);

    [secciones, territorios, datos, mapa] = await Promise.all([
      cargarSecciones(manifiesto),
      cargarTerritorios(manifiesto),
      cargarIndicador(manifiesto, mapaDef().base, estado.anio),
      crearMapa({
        contenedor: el.mapa,
        manifiesto,
        vista: estado.vista ? textoAVista(estado.vista) : null,
        t,
        alSeleccionar: elegirSeccion,
        alMover: (m) => {
          estado.vista = vistaATexto(m);
          guardarEstado(estado);
        },
      }),
    ]);
    indice = new Map(secciones.map((codigo, i) => [codigo, i]));

    mapa.pintar({ secciones, datos, mapaDef: mapaDef(), supuestos: manifiesto.supuestos });
    pintarLeyendaActiva();
    if (estado.seccion && !indice.has(estado.seccion)) estado.seccion = undefined;
    if (estado.seccion) mapa.seleccionar(estado.seccion);
    pintarFicha();
    guardarEstado(estado);
  } catch (error) {
    fichaError(el.ficha, { t, error });
  }
}

iniciar();
