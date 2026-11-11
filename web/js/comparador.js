// Comparador: la sección elegida frente a otra sección, su municipio, su provincia, su comunidad
// o España, con los indicadores de la v0.1 que tenga el manifiesto. Cada fila usa el periodo de
// la serie que corresponde al año del mapa (el mismo o el último anterior), igual en las dos
// columnas (regla 4). Si el año es anterior a toda la serie, la fila va sin dato y dice desde
// cuándo hay serie (pregunta abierta 32).

import { periodoPara, inicioSerie, valorDe, cargarSeries, tipologiaDe } from './datos.js';
import { formulaDe, textoSupuestos } from './formulas.js';
import { ordenNatural } from './nombres.js';

// Indicadores de la v0.1 (plan, §7, F2) y los de distribución de la renta de F3 (4–6), en el
// orden de la tabla. El 21 se calcula con el 9.
export const INDICADORES_V01 = [
  'renta_persona', 'renta_hogar', 'renta_uc_mediana', 'peso_salarios', 'bajo_60_mediana', 'gini',
  'alquiler_mes', 'alquiler_m2',
  'sueldo_necesario', 'esfuerzo_residentes', 'hogares_alquiler', 'viviendas_turisticas',
];
export const NIVELES_COMPARAR = ['distrito', 'municipio', 'provincia', 'ccaa', 'nacional'];

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

// Niveles de menos a más amplio: un territorio se compara con los que lo contienen.
const ORDEN_NIVELES = ['sc', 'distrito', 'municipio', 'provincia', 'ccaa', 'nacional'];

// Niveles con que se puede comparar un territorio de `nivel` (los que lo contienen).
export const nivelesSuperiores = (nivel) => NIVELES_COMPARAR.filter((n) => ORDEN_NIVELES.indexOf(n) > ORDEN_NIVELES.indexOf(nivel));

// Código del territorio con el que se compara una sección (o, con `nivel`, un municipio, una
// provincia o una comunidad: tarea 26). null si `comparar` no contiene al territorio.
export function codigoComparado(seccion, comparar, territorios, nivel = 'sc') {
  if (/^\d{10}$/.test(comparar)) return nivel === 'sc' ? { nivel: 'sc', codigo: comparar } : null;
  if (!nivelesSuperiores(nivel).includes(comparar)) return null;
  const provincia = nivel === 'ccaa' ? null : seccion.slice(0, 2);
  const codigo = {
    distrito: seccion.slice(0, 7),
    municipio: seccion.slice(0, 5),
    provincia,
    ccaa: territorios?.ccaa_de_provincia?.[provincia],
    nacional: '00',
  }[comparar];
  return codigo ? { nivel: comparar, codigo } : null;
}

export function nombreTerritorio(t, nivel, codigo, territorios) {
  if (nivel === 'sc') return t('interfaz.ficha.seccion', { codigo });
  if (nivel === 'nacional') return t('vocabulario.nivel.nacional');
  if (nivel === 'distrito') return `${t('vocabulario.nivel.distrito')} ${codigo.slice(5, 7)}`;
  return ordenNatural(territorios?.[nivel]?.[codigo] ?? codigo);
}

// Valor de una serie en una sección: de sus series (fichero del municipio) o, si no, del fichero
// del año.
async function valorSeccion(m, series, serie, codigo, periodo) {
  const s = series?.[serie];
  if (s) {
    const k = s.anios.findIndex((p) => String(p) === String(periodo));
    return k < 0 ? null : { valor: s.valores[k], estado: s.estados[k] };
  }
  return valorDe(m, serie, 'sc', codigo, periodo);
}

// Filas de la tabla: [{ indicador, periodo, desde, decimales, tipologia, derivado, a: {valor, estado} |
// null, b: ... }]; `periodo` null y `desde` (primer periodo de la serie) si el año es anterior a la
// serie; `derivado`, el mapa del manifiesto con que se calcula la fila (el 21) o null.
// `serieDe(serie)`: la serie de la tipología elegida (los alquileres y el 21 de la vivienda
// colectiva o de la unifamiliar, sin mezclarlas); por defecto, la misma.
// `nivelA`: el de la columna A ('sc' por defecto; un municipio, una provincia o una comunidad en la
// ficha de territorio, con `seccion` como su código).
export async function filasComparador({ m, seccion, comparado, anio, supuestos, seriesA, serieDe = (s) => s, nivelA = 'sc' }) {
  const seriesB = comparado.nivel === 'sc' ? await cargarSeries(m, comparado.codigo).catch(() => null) : null;
  const valor = (serie, periodo, lado) => lado === 'a'
    ? (nivelA === 'sc' ? valorSeccion(m, seriesA, serie, seccion, periodo) : valorDe(m, serie, nivelA, seccion, periodo))
    : comparado.nivel === 'sc'
      ? valorSeccion(m, seriesB, serie, comparado.codigo, periodo)
      : valorDe(m, serie, comparado.nivel, comparado.codigo, periodo);

  const filas = [];
  for (const indicador of INDICADORES_V01) {
    const derivado = indicador === 'sueldo_necesario' ? m.mapas?.sueldo_necesario : null;
    const serie = serieDe(derivado ? derivado.base : indicador);
    const def = m.indicadores?.[serie];
    if (!def || (indicador === 'sueldo_necesario' && !derivado)) continue;
    const periodo = periodoPara(def, anio);
    const ausente = { valor: null, estado: m.codificacion.estados.indexOf('ausente') };
    const [a, b] = periodo === null
      ? [ausente, ausente]
      : await Promise.all([valor(serie, periodo, 'a'), valor(serie, periodo, 'b')]);
    const transformar = (x) => {
      if (!x || !derivado || x.valor === null) return x;
      return { ...x, valor: formulaDe(derivado).calcular(x.valor, supuestos) };
    };
    filas.push({
      indicador, periodo, desde: periodo === null ? inicioSerie(def) : null, derivado: derivado ?? null, tipologia: tipologiaDe(m, serie),
      decimales: derivado ? derivado.decimales ?? 0 : def.decimales ?? 1,
      a: transformar(a), b: transformar(b),
    });
  }
  return filas;
}

// Bloque del comparador dentro de la ficha. `eleccion`: '' | nivel | 'seccion'.
export function pintarComparador(contenedor, { t, eleccion, opciones, filas, nombreA, nombreB, eligiendo, supuestos, estados, alElegir, alCancelar }) {
  const bloque = crear('section', 'ficha-comparador');
  bloque.append(crear('h3', 'ficha-indicador', t('interfaz.comparador.titulo')));

  const etiqueta = crear('label', 'comparador-eleccion');
  etiqueta.append(crear('span', null, t('interfaz.comparador.con')));
  const select = crear('select');
  for (const { valor, texto } of [{ valor: '', texto: t('interfaz.comparador.nada') }, ...opciones]) {
    const opcion = crear('option', null, texto);
    opcion.value = valor;
    opcion.selected = valor === eleccion;
    select.append(opcion);
  }
  select.addEventListener('change', () => alElegir(select.value));
  etiqueta.append(select);
  bloque.append(etiqueta);

  if (eligiendo) {
    const aviso = crear('p', 'comparador-aviso', t('interfaz.comparador.elige_en_mapa'));
    const cancelar = crear('button', 'boton-texto', t('interfaz.comparador.cancelar'));
    cancelar.type = 'button';
    cancelar.addEventListener('click', alCancelar);
    aviso.append(' ', cancelar);
    bloque.append(aviso);
  }

  if (filas?.length) {
    const celda = (x, decimales) => {
      const td = crear('td', 'comparador-cifra');
      if (!x || x.valor === null) {
        td.textContent = '—';
        if (x) td.title = t(`vocabulario.estado.${estados[x.estado]}`);
        return td;
      }
      td.textContent = t.numero(x.valor, decimales);
      if (estados[x.estado] === 'estimado') {
        const marca = crear('sup', 'comparador-marca', 'e');
        marca.title = t('vocabulario.estado.estimado');
        td.append(marca);
      }
      return td;
    };
    const tabla = crear('table', 'comparador-tabla');
    const cabecera = crear('tr');
    cabecera.append(crear('th', null, t('interfaz.comparador.indicador')), crear('th', 'comparador-cifra', nombreA), crear('th', 'comparador-cifra', nombreB));
    tabla.append(crear('thead'), crear('tbody'));
    tabla.tHead.append(cabecera);
    for (const fila of filas) {
      const tr = crear('tr');
      const th = crear('th');
      th.scope = 'row';
      th.append(crear('span', 'comparador-nombre', t(`indicadores.${fila.indicador}.nombre`)));
      // Tarea 40: el sueldo necesario del comparador es la cifra principal (alquiler mensual real)
      const textoS = fila.derivado ? textoSupuestos(t, fila.derivado, supuestos) : null;
      const unidad = textoS
        ? `${t(`indicadores.${fila.indicador}.unidad`)} · ${textoS}`
        : t(`indicadores.${fila.indicador}.unidad`);
      const tipologia = fila.tipologia ? ` · ${t(`vocabulario.tipologia.${fila.tipologia}`)}` : '';
      const cuando = fila.periodo === null ? t('interfaz.vista.desde',{ desde: t.periodo(fila.desde) }) : t.periodo(fila.periodo);
      th.append(crear('span', 'comparador-unidad', `${unidad}${tipologia} · ${cuando}`));
      tr.append(th, celda(fila.a, fila.decimales), celda(fila.b, fila.decimales));
      tabla.tBodies[0].append(tr);
    }
    bloque.append(tabla, crear('p', 'comparador-nota', t('interfaz.comparador.nota')));
  }
  contenedor.replaceChildren(bloque);
}
