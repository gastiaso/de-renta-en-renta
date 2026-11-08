// Leyenda del mapa, plegable (cerrada de entrada en el móvil):
//   - sueldo necesario: regla de cinco tramos con los cortes del manifiesto, las fichas de una
//     persona como marcas en su ingreso y la llave como un tramo (su renta cambia por sección);
//   - «¿te llega?»: tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %).
// Debajo, las claves de los huecos (sin dato, secreto estadístico) y los supuestos.

import { posicionEnRegla } from './sueldo.js';

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

let abierta = !matchMedia('(max-width: 760px)').matches;

function claves(t) {
  const lista = crear('ul', 'leyenda-claves');
  for (const [clase, clave] of [['leyenda-sin-dato', 'interfaz.leyenda.sin_dato'], ['secreto', 'interfaz.leyenda.secreto']]) {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clase}`), crear('span', null, t(clave)));
    lista.append(item);
  }
  return lista;
}

function reglaNecesario(t, { mapaDef, marcas, llave }) {
  const cortes = mapaDef.cortes;
  const dec = mapaDef.decimales ?? 0;
  const pos = (v) => `${(100 * posicionEnRegla(v, cortes)).toFixed(2)}%`;

  const regla = crear('div', 'leyenda-regla');
  for (let i = 1; i <= cortes.length + 1; i++) regla.append(crear('span', `leyenda-tramo tramo-${i}`));
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

function tramosLlega(t) {
  const lista = crear('ul', 'leyenda-llega');
  ['interfaz.leyenda.llega_1', 'interfaz.leyenda.llega_2', 'interfaz.leyenda.llega_3'].forEach((clave, i) => {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra tramo-${[1, 3, 5][i]}`), crear('span', null, t(clave)));
    lista.append(item);
  });
  return [lista];
}

// `datos`: { modo, mapaId, mapaDef, superficie, umbral, marcas, llave, ficha, vivienda }.
export function pintarLeyenda(contenedor, t, datos) {
  const pliegue = crear('details', 'leyenda-pliegue');
  pliegue.open = abierta;
  pliegue.addEventListener('toggle', () => { abierta = pliegue.open; });
  const necesario = datos.modo === 'necesario';
  const titulo = necesario ? t(`indicadores.${datos.mapaId}.nombre`) : t('interfaz.leyenda.llega_titulo');
  pliegue.append(crear('summary', 'leyenda-titulo', titulo));

  const cuerpo = necesario
    ? [crear('p', 'leyenda-unidad', t(`indicadores.${datos.mapaId}.unidad`)), ...reglaNecesario(t, datos)]
    : [crear('p', 'leyenda-unidad', datos.vivienda), ...tramosLlega(t)];
  const supuestos = necesario
    ? t('interfaz.leyenda.supuestos', { superficie: t.numero(datos.superficie), umbral: t.porcentaje(datos.umbral) })
    : t('interfaz.leyenda.llega_nota');
  pliegue.append(...cuerpo, claves(t), crear('p', 'leyenda-supuestos', supuestos));

  contenedor.replaceChildren(pliegue);
  contenedor.hidden = false;
}
