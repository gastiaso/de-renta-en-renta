// Leyenda del mapa, plegable (abierta al entrar):
//   - mapas del manifiesto: regla con un tramo más que cortes (siete con los juegos); en el
//     sueldo necesario, además, las fichas de una persona como marcas en su ingreso y la llave
//     como un tramo (su renta cambia por sección);
//   - «¿te llega?»: tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %).
// Debajo, las claves de los huecos (sin dato, secreto estadístico) y los supuestos.
// F5: los mapas de categorías (indicador 20) llevan una lista con el texto de cada categoría en vez de
// la regla; los de un dato privado (portales, indicador 13), su etiqueta bajo el título.
// Los colores de cada tramo salen de los mismos pasos de la rampa que el mapa (colores.js).
// Tarea 34: bajo el título, la familia del mapa de alquiler con su lectura literal («Quedarse ·
// quien ya vive de alquiler»); en «¿te llega?», siempre «quedarse» (familias.js). Sin familia,
// nada.
// Tarea 51: la regla usa el juego de cortes de la escala que se ve (`nivel`; colores.js, juegoDe):
// con varios juegos, una línea dice de qué escala son los tramos y, al cambiar de juego por acercar
// o alejar el mapa, avisa (`cambioJuego`); en los juegos anclados, la nota «tramos fijados con el
// último año». Abierta al entrar, también en el móvil (allí va bajo el mapa, sin taparlo).
// Escala relativa al municipio (decisión del autor, 11-nov-2026; escala_municipio.js): a escala de
// sección y en los mapas con juego de cortes de la sección, un selector «Tramos: de España · de
// <municipio>»; con el municipio, la regla lleva sus septiles, una línea dice que no son comparables
// con otros municipios y una clave más, las secciones de fuera, sin color. `relativa`: { ofrecida,
// elegida, activa, municipio, nombre, n, cortes, anio, motivo }; `alCambiarEscala('municipio' | null)`.

import { posicionEnRegla } from './sueldo.js';
import { textoSupuestos } from './formulas.js';
import { clasesTramos, rampaDeCss, TRAMOS_LLEGA, decimalesDeCortes, juegoDe, cambiaConLaEscala, anclado } from './colores.js';
import { familiaDe, textoFamilia } from './familias.js';

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

// Abierta al entrar (tarea 51); luego, como la deje el usuario.
let abierta = true;

function claves(t, relativa = null) {
  const lista = crear('ul', 'leyenda-claves');
  const filas = [['leyenda-sin-dato', t('interfaz.leyenda.sin_dato')], ['secreto', t('interfaz.leyenda.secreto')]];
  if (relativa?.activa) filas.push(['leyenda-fuera-municipio', t('interfaz.leyenda.relativa.fuera', { municipio: relativa.nombre })]);
  for (const [clase, texto] of filas) {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clase}`), crear('span', null, texto));
    lista.append(item);
  }
  return lista;
}

// Con la escala relativa elegida y posible a la escala que se ve: sus cortes; si no, null.
const relativaVisible = (datos) => (datos.relativa?.activa && datos.nivel === 'sc' ? datos.relativa : null);

// Selector de la escala relativa (solo a escala de sección, en los mapas que la admiten) y, con ella,
// la línea que dice de qué municipio son los tramos o por qué no se pueden usar.
export function controlRelativa(t, { relativa, nivel, alCambiarEscala = null }) {
  if (!relativa?.ofrecida || nivel !== 'sc') return [];
  const grupo = crear('div', 'selector leyenda-escala');
  grupo.setAttribute('role', 'group');
  const titulo = crear('span', 'selector-titulo', t('interfaz.leyenda.relativa.titulo'));
  titulo.id = 'leyenda-escala-titulo';
  grupo.setAttribute('aria-labelledby', titulo.id);
  grupo.append(titulo);
  const boton = (texto, valor, pulsado, desactivado = false) => {
    const b = crear('button', null, texto);
    b.type = 'button';
    b.dataset.escala = valor ?? 'nacional';
    b.setAttribute('aria-pressed', String(pulsado));
    b.disabled = desactivado;
    b.addEventListener('click', () => { if (!pulsado) alCambiarEscala?.(valor); });
    return b;
  };
  const activa = Boolean(relativa.activa);
  grupo.append(
    boton(t('interfaz.leyenda.relativa.nacional'), null, !activa),
    boton(relativa.nombre ? t('interfaz.leyenda.relativa.municipio', { municipio: relativa.nombre }) : t('interfaz.leyenda.relativa.municipio_sin'),
      'municipio', activa, !relativa.cortes),
  );
  const lineas = [grupo];
  if (activa) {
    const linea = crear('p', 'leyenda-relativa', t('interfaz.leyenda.relativa.linea', {
      municipio: relativa.nombre, n: t.numero(relativa.n), anio: t.periodo(relativa.anio),
    }));
    linea.setAttribute('role', 'status');
    lineas.push(linea);
  } else if (relativa.elegida || !relativa.cortes) {
    // Elegida pero sin poder usarse, o sin municipio que la admita: por qué
    const motivo = relativa.motivo === 'pocas'
      ? t('interfaz.leyenda.relativa.pocas', { municipio: relativa.nombre, minimo: t.numero(relativa.minimo) })
      : relativa.motivo === 'sin_municipio' ? t('interfaz.leyenda.relativa.sin_municipio') : null;
    if (motivo) lineas.push(crear('p', 'leyenda-juego', motivo));
  }
  return lineas;
}

function reglaNecesario(t, { mapaDef, nivel = null, marcas = [], llave = null, relativa = null }) {
  const propia = relativaVisible({ relativa, nivel });
  const cortes = propia ? propia.cortes : juegoDe(mapaDef, nivel).cortes;
  const dec = decimalesDeCortes(cortes, mapaDef.decimales ?? 0);
  const pos = (v) => `${(100 * posicionEnRegla(v, cortes)).toFixed(2)}%`;

  const regla = crear('div', 'leyenda-regla');
  for (const clase of clasesTramos(cortes.length + 1, rampaDeCss().length)) regla.append(crear('span', `leyenda-tramo ${clase}`));
  if (llave) {
    const banda = crear('span', 'leyenda-banda-llave');
    banda.style.left = pos(llave.desde);
    banda.style.width = `calc(${pos(llave.hasta)} - ${pos(llave.desde)})`;
    regla.append(banda);
  }
  for (const m of marcas) {
    const marca = crear('span', `leyenda-marca leyenda-marca-${m.ficha}`);
    marca.style.left = pos(m.valor);
    regla.append(marca);
  }

  const etiquetas = crear('div', 'leyenda-cortes');
  cortes.forEach((corte, i) => {
    const marca = crear('span', 'leyenda-corte', t.numero(corte, dec));
    marca.style.left = `${(100 * (i + 1)) / (cortes.length + 1)}%`;
    etiquetas.append(marca);
  });

  const lista = crear('ul', 'leyenda-fichas');
  for (const m of marcas) {
    const item = crear('li');
    const nombre = m.mediana ? t('interfaz.leyenda.ficha_mediana', { ficha: t(`fichas.${m.ficha}`) }) : t(`fichas.${m.ficha}`);
    item.append(crear('span', `leyenda-icono leyenda-marca-${m.ficha}`),
      crear('span', null, `${nombre}: ${t('interfaz.sueldo.ingreso_euros', { euros: t.numero(m.valor) })}`));
    lista.append(item);
  }
  if (llave) {
    const item = crear('li');
    item.append(crear('span', 'leyenda-icono leyenda-banda-llave'),
      crear('span', null, t('interfaz.leyenda.llave', { ficha: t('fichas.llave'), desde: t.numero(llave.desde), hasta: t.numero(llave.hasta) })));
    lista.append(item);
  }
  return [regla, etiquetas, ...(lista.children.length ? [lista] : [])];
}

// F5: una muestra por categoría (`categorias`: { vocabulario, valores }), con los pasos de la rampa
// que les tocan entre los cortes del mapa (como en el mapa: un tramo por categoría).
export function listaCategorias(t, mapaDef) {
  const lista = crear('ul', 'leyenda-llega leyenda-categorias');
  const { vocabulario, valores } = mapaDef.categorias;
  const clases = clasesTramos(mapaDef.cortes.length + 1, rampaDeCss().length);
  [...valores].reverse().forEach((valor) => {
    const tramo = mapaDef.cortes.filter((c) => valor >= c).length;
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clases[tramo]}`), crear('span', null, t(`vocabulario.${vocabulario}.${valor}`)));
    lista.append(item);
  });
  return [lista];
}

function tramosLlega(t) {
  const lista = crear('ul', 'leyenda-llega');
  const clases = clasesTramos(TRAMOS_LLEGA, rampaDeCss().length);
  ['interfaz.leyenda.llega_1', 'interfaz.leyenda.llega_2', 'interfaz.leyenda.llega_3'].forEach((clave, i) => {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clases[i]}`), crear('span', null, t(clave)));
    lista.append(item);
  });
  return [lista];
}

// Tarea 51: de qué escala son los tramos (con varios juegos), con aviso al cambiar de juego, y el año
// de anclaje de los juegos anclados.
export function lineasJuego(t, { mapaDef, nivel = null, cambioJuego = false, relativa = null }) {
  if (relativaVisible({ relativa, nivel })) return [];   // la escala relativa lleva su propia línea
  const juego = juegoDe(mapaDef, nivel);
  const lineas = [];
  if (juego.nombre && cambiaConLaEscala(mapaDef)) {
    const escala = t(`interfaz.leyenda.juegos.${juego.nombre}`);
    const linea = crear('p', `leyenda-juego${cambioJuego ? ' leyenda-juego-cambio' : ''}`,
      t(cambioJuego ? 'interfaz.leyenda.juego_cambio' : 'interfaz.leyenda.juego', { escala }));
    if (cambioJuego) linea.setAttribute('role', 'status');
    lineas.push(linea);
  }
  if (anclado(juego) && juego.anio) lineas.push(crear('p', 'leyenda-anclaje', t('interfaz.leyenda.anclaje', { anio: juego.anio })));
  return lineas;
}

// `datos`: { modo, mapaId, mapaDef, nivel, cambioJuego, superficie, umbral, marcas, llave, ficha, vivienda, periodo,
// tipologia, conSupuestos, fuera, relativa, alCambiarEscala, tipica }. `conSupuestos`: el mapa usa la superficie y el umbral (el
// sueldo necesario); `tipologia`: 'VC' | 'VU' si la serie la distingue; `fuera`: con un año
// anterior a toda la serie, el texto que dice desde cuándo hay datos. La familia del mapa de
// alquiler sale de `mapaDef.familia` (manifiesto) o, en «¿te llega?», del modo.
export function pintarLeyenda(contenedor, t, datos) {
  const pliegue = crear('details', 'leyenda-pliegue');
  pliegue.open = abierta;
  pliegue.addEventListener('toggle', () => { abierta = pliegue.open; });
  const necesario = datos.modo === 'necesario';
  const titulo = necesario ? t(`indicadores.${datos.mapaId}.nombre`) : t('interfaz.leyenda.llega_titulo');
  pliegue.append(crear('summary', 'leyenda-titulo', titulo));

  // Bajo el título: unidad (o vivienda e ingreso de «¿te llega?»), periodo y tipología.
  const detalle = [necesario ? t(`indicadores.${datos.mapaId}.unidad`) : datos.vivienda];
  if (datos.periodo !== undefined && datos.periodo !== null) detalle.push(t.periodo(datos.periodo));
  if (datos.tipologia) detalle.push(t(`vocabulario.tipologia.${datos.tipologia}`));
  if (datos.grupo) detalle.push(datos.grupo);   // F5: operación y portal (indicador 13)
  const cuerpo = [];
  const familia = textoFamilia(t, familiaDe(datos));   // tarea 34: «Quedarse · quien ya vive de alquiler»
  if (familia) cuerpo.push(crear('p', 'leyenda-familia', familia));
  if (datos.etiqueta) cuerpo.push(crear('p', 'etiqueta-privado leyenda-etiqueta', datos.etiqueta));   // F5: dato privado
  cuerpo.push(crear('p', 'leyenda-unidad', detalle.join(' · ')));
  if (datos.fuera) cuerpo.push(crear('p', 'leyenda-fuera', datos.fuera));
  const categorias = necesario && datos.mapaDef?.categorias;   // F5: mapa de categorías (indicador 20)
  if (necesario && !categorias) cuerpo.push(...controlRelativa(t, datos), ...lineasJuego(t, datos));   // tarea 51
  cuerpo.push(...(categorias ? listaCategorias(t, datos.mapaDef) : necesario ? reglaNecesario(t, datos) : tramosLlega(t)));
  let supuestos = t('interfaz.leyenda.llega_nota');
  if (necesario) {
    // Tarea 40: en el sueldo necesario, el alquiler real y el umbral, y la superficie del mínimo de la ficha
    supuestos = datos.conSupuestos
      ? textoSupuestos(t, datos.mapaDef, datos.supuestos ?? { superficie_m2: datos.superficie, umbral: datos.umbral })
      : null;
  }
  pliegue.append(...cuerpo, claves(t, relativaVisible(datos)));
  if (supuestos) pliegue.append(crear('p', 'leyenda-supuestos', supuestos));
  if (necesario && datos.conSupuestos && datos.mapaDef?.minimo) {   // tarea 40: el mínimo, en la ficha
    pliegue.append(crear('p', 'leyenda-supuestos', t('interfaz.leyenda.minimo_ficha', { superficie: t.numero(datos.superficie) })));
  }
  if (datos.tipica) pliegue.append(crear('p', 'leyenda-supuestos', datos.tipica));   // superficie típica elegida

  contenedor.replaceChildren(pliegue);
  contenedor.hidden = false;
}
