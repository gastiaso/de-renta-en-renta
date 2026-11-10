// Leyenda del mapa, plegable (cerrada de entrada en el móvil):
//   - mapas del manifiesto: regla con un tramo más que cortes (seis en el indicador 21); en el
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

import { posicionEnRegla } from './sueldo.js';
import { clasesTramos, rampaDeCss, TRAMOS_LLEGA, decimalesDeCortes } from './colores.js';
import { familiaDe, textoFamilia } from './familias.js';

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

// Sin `matchMedia` (las pruebas, en node), abierta.
let abierta = typeof matchMedia === 'function' ? !matchMedia('(max-width: 760px)').matches : true;

function claves(t) {
  const lista = crear('ul', 'leyenda-claves');
  for (const [clase, clave] of [['leyenda-sin-dato', 'interfaz.leyenda.sin_dato'], ['secreto', 'interfaz.leyenda.secreto']]) {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clase}`), crear('span', null, t(clave)));
    lista.append(item);
  }
  return lista;
}

function reglaNecesario(t, { mapaDef, marcas = [], llave = null }) {
  const cortes = mapaDef.cortes;
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

// `datos`: { modo, mapaId, mapaDef, superficie, umbral, marcas, llave, ficha, vivienda, periodo,
// tipologia, conSupuestos, fuera }. `conSupuestos`: el mapa usa la superficie y el umbral (el
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
  cuerpo.push(...(categorias ? listaCategorias(t, datos.mapaDef) : necesario ? reglaNecesario(t, datos) : tramosLlega(t)));
  let supuestos = t('interfaz.leyenda.llega_nota');
  if (necesario) {
    supuestos = datos.conSupuestos
      ? t('interfaz.leyenda.supuestos', { superficie: t.numero(datos.superficie), umbral: t.porcentaje(datos.umbral) })
      : null;
  }
  pliegue.append(...cuerpo, claves(t));
  if (supuestos) pliegue.append(crear('p', 'leyenda-supuestos', supuestos));

  contenedor.replaceChildren(pliegue);
  contenedor.hidden = false;
}
