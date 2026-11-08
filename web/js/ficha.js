// Ficha de sección (panel lateral). Sin sección elegida, una invitación a elegirla; con sección,
// su código, sus territorios y el valor del mapa activo:
//   - sueldo necesario: la cifra en euros, con la superficie y el umbral;
//   - «¿te llega?»: el alquiler sobre el ingreso de la ficha, con las dos cantidades.
// Debajo, dos huecos que se rellenan cuando llegan sus datos: la evolución por años y el
// comparador.

import { ordenNatural } from './nombres.js';
import { clasesTramos, rampaDeCss, TRAMOS_LLEGA } from './colores.js';

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

function cabecera(t, alCerrar) {
  const caja = crear('header', 'ficha-cabecera');
  caja.append(crear('h2', 'ficha-titulo', t('interfaz.ficha.titulo')));
  if (alCerrar) {
    const cerrar = crear('button', 'ficha-cerrar', '×');
    cerrar.type = 'button';
    cerrar.setAttribute('aria-label', t('interfaz.ficha.cerrar'));
    cerrar.title = t('interfaz.ficha.cerrar');
    cerrar.addEventListener('click', alCerrar);
    caja.append(cerrar);
  }
  return caja;
}

export function fichaVacia(contenedor, { t }) {
  contenedor.replaceChildren(cabecera(t), crear('p', 'ficha-vacia', t('interfaz.ficha.vacia')));
}

export function fichaError(contenedor, { t, error }) {
  console.error(error);
  const aviso = crear('p', 'ficha-error', t('interfaz.error_carga'));
  aviso.setAttribute('role', 'alert');
  contenedor.replaceChildren(cabecera(t), aviso);
}

const TEXTOS_LLEGA = ['interfaz.leyenda.llega_1', 'interfaz.leyenda.llega_2', 'interfaz.leyenda.llega_3'];

// `valor`: en el modo «necesario», el sueldo necesario (o null); en «llega», { alquiler,
// ingreso, ratio, tramo } (o null). `estado`: índice en codificacion.estados.
// Devuelve los huecos de la evolución y del comparador.
// `tipologia`: 'VC' | 'VU' si la serie del mapa la distingue; null si no.
export function fichaSeccion(contenedor, { t, codigo, territorios, modo, mapaId, mapaDef, ficha, supuestos, anio, valor, estado, estados, ejemplo, aviso, alCerrar, tipologia = null }) {
  const municipio = codigo.slice(0, 5);
  const provincia = codigo.slice(0, 2);
  const lineas = [
    ['vocabulario.nivel.municipio', ordenNatural(territorios.municipio?.[municipio] ?? municipio)],
    ['vocabulario.nivel.distrito', codigo.slice(5, 7)],
    ['vocabulario.nivel.provincia', ordenNatural(territorios.provincia?.[provincia] ?? provincia)],
  ];
  const datos = crear('dl', 'ficha-territorios');
  for (const [clave, texto] of lineas) datos.append(crear('dt', null, t(clave)), crear('dd', null, texto));

  const bloque = crear('section', 'ficha-valor');
  const cifra = crear('p', 'ficha-cifra');
  if (modo === 'necesario') {
    bloque.append(crear('h3', 'ficha-indicador', t(`indicadores.${mapaId}.nombre`)));
    cifra.append(crear('span', 'ficha-numero', valor === null ? '—' : t.numero(valor, mapaDef.decimales ?? 0)));
    cifra.append(crear('span', 'ficha-unidad', t(`indicadores.${mapaId}.unidad`)));
    bloque.append(cifra);
    // La superficie y el umbral, solo en los mapas que los usan (el sueldo necesario).
    if ((mapaDef.formula ?? 'directo') !== 'directo') {
      bloque.append(crear('p', 'ficha-estado',
        t('interfaz.leyenda.supuestos', { superficie: t.numero(supuestos.superficie_m2), umbral: t.porcentaje(supuestos.umbral) })));
    }
  } else {
    bloque.append(crear('h3', 'ficha-indicador', `${t('interfaz.leyenda.llega_titulo')} · ${t(`fichas.${ficha}`)}`));
    cifra.append(crear('span', 'ficha-numero', valor === null ? '—' : t.porcentaje(valor.ratio)));
    cifra.append(crear('span', 'ficha-unidad', t('interfaz.ficha.del_ingreso')));
    bloque.append(cifra);
    if (valor !== null) {
      const tramo = crear('p', 'ficha-tramo');
      const clase = clasesTramos(TRAMOS_LLEGA, rampaDeCss().length)[valor.tramo];
      tramo.append(crear('span', `leyenda-muestra ${clase}`), crear('span', null, t(TEXTOS_LLEGA[valor.tramo])));
      bloque.append(
        crear('p', 'ficha-estado', t('interfaz.ficha.alquiler_ingreso', { alquiler: t.numero(valor.alquiler), ingreso: t.numero(valor.ingreso) })),
        tramo,
      );
    }
  }
  const partes = [t('interfaz.ficha.anio', { anio: t.periodo(anio) })];
  if (tipologia) partes.push(t(`vocabulario.tipologia.${tipologia}`));
  partes.push(t(`vocabulario.estado.${estados[estado]}`));
  bloque.append(crear('p', 'ficha-estado', partes.join(' · ')));
  if (aviso) bloque.append(crear('p', 'nota', aviso));
  if (ejemplo) bloque.append(crear('p', 'etiqueta-ejemplo', t('avisos.ejemplo')));

  const huecoSerie = crear('div', 'ficha-hueco');
  const huecoComparador = crear('div', 'ficha-hueco');
  contenedor.replaceChildren(
    cabecera(t, alCerrar),
    crear('p', 'ficha-codigo', t('interfaz.ficha.seccion', { codigo })),
    datos,
    bloque,
    huecoSerie,
    huecoComparador,
  );
  return { huecoSerie, huecoComparador };
}

// Evolución del mapa activo en la sección: una fila por periodo, con el texto ya formateado y,
// si no es «dato», su estado. `filas`: [{ periodo, texto, estado }].
export function fichaSeries(contenedor, { t, titulo, nota, filas, estados, periodo }) {
  const cuerpo = crear('tbody');
  for (const fila of filas) {
    const tr = crear('tr', String(fila.periodo) === String(periodo) ? 'ficha-tabla-activa' : undefined);
    const th = crear('th', null, t.periodo(fila.periodo));
    th.scope = 'row';
    const nombre = estados[fila.estado];
    tr.append(
      th,
      crear('td', 'ficha-tabla-cifra', fila.texto),
      crear('td', 'ficha-tabla-estado', nombre === 'dato' ? '' : t(`interfaz.estado_corto.${nombre}`)),
    );
    cuerpo.append(tr);
  }
  const tabla = crear('table', 'ficha-tabla');
  tabla.append(cuerpo);
  const bloque = crear('section', 'ficha-serie');
  bloque.append(crear('h3', 'ficha-indicador', titulo), tabla);
  if (nota) bloque.append(crear('p', 'nota', nota));
  contenedor.replaceChildren(bloque);
}
