// Ficha de sección (panel lateral). Sin sección elegida, una invitación a elegirla; con sección,
// su código, sus territorios y el valor del mapa activo:
//   - sueldo necesario: la cifra en euros, con la superficie y el umbral;
//   - «¿te llega?»: el alquiler sobre el ingreso de la ficha, con las dos cantidades.
// Bajo la cifra, la fiabilidad de la mediana del alquiler (fiabilidad.js): sus contratos y su
// margen aproximado, «pocos contratos», el intervalo de la cifra y, en «¿te llega?», si queda en el
// límite entre dos tramos; sin mediana y con 0 contratos, «sin contratos de alquiler registrados»
// en lugar de «sin dato» (plan §11, preguntas 12 y 15 ampliadas).
// Debajo, tres huecos que se rellenan cuando llegan sus datos: el contexto (sin mediana), la
// evolución por años y el comparador.

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

// Nombres de las provincias que rodean un trozo de suelo sin sección, en orden alfabético.
export function provinciasSinSeccion(codigos, territorios) {
  return codigos.map((p) => ordenNatural(territorios.provincia?.[p] ?? p)).sort((a, b) => a.localeCompare(b, 'es'));
}

// Ficha del suelo sin sección (capa sin_seccion del mapa base): terreno comunal que no es de
// ningún término municipal. Sin datos: qué es, las provincias que lo rodean y su superficie.
export function fichaSinSeccion(contenedor, { t, km2, provincias, territorios, alCerrar }) {
  const nombres = provinciasSinSeccion(provincias, territorios);
  const datos = crear('dl', 'ficha-territorios');
  if (nombres.length) {
    const etiqueta = nombres.length === 1 ? 'vocabulario.nivel.provincia' : 'interfaz.ficha.provincias';
    datos.append(crear('dt', null, t(etiqueta)), crear('dd', null, nombres.join(', ')));
  }
  if (km2 !== null) {
    datos.append(crear('dt', null, t('interfaz.ficha.superficie')),
      crear('dd', null, t('interfaz.ficha.km2', { superficie: t.numero(km2, km2 < 10 ? 2 : 1) })));
  }
  contenedor.replaceChildren(
    cabecera(t, alCerrar),
    crear('p', 'ficha-codigo', t('interfaz.ficha.sin_seccion')),
    datos,
    crear('p', 'ficha-estado', t('interfaz.ficha.sin_seccion_texto')),
  );
}

export function fichaError(contenedor, { t, error }) {
  console.error(error);
  const aviso = crear('p', 'ficha-error', t('interfaz.error_carga'));
  aviso.setAttribute('role', 'alert');
  contenedor.replaceChildren(cabecera(t), aviso);
}

const TEXTOS_LLEGA = ['interfaz.leyenda.llega_1', 'interfaz.leyenda.llega_2', 'interfaz.leyenda.llega_3'];

// Línea de fiabilidad bajo la cifra: «Mediana de N contratos · margen aproximado ±X %», con la
// marca «pocos contratos»; en secreto, cuántos contratos hay. `f`: fiabilidadFicha() o null.
function lineaFiabilidad(t, f) {
  if (!f || (f.tipo !== 'mediana' && f.tipo !== 'secreto')) return null;
  const p = crear('p', 'ficha-fiabilidad');
  if (f.tipo === 'secreto') {
    p.textContent = t('interfaz.ficha.contratos_secreto', { contratos: t.numero(f.contratos) });
    return p;
  }
  p.textContent = f.margen === null
    ? t('interfaz.ficha.contratos_sin_margen', { contratos: t.numero(f.contratos) })
    : t('interfaz.ficha.contratos', { contratos: t.numero(f.contratos), margen: t.numero(f.margen, 1) });
  if (f.pocos) p.append(' ', crear('span', 'marca-pocos', t('interfaz.ficha.pocos_contratos')));
  return p;
}

// `valor`: en el modo «necesario», el sueldo necesario (o null); en «llega», { alquiler,
// ingreso, ratio, tramo } (o null). `estado`: índice en codificacion.estados.
// `fiabilidad`: fiabilidadFicha() o null; `intervalo`: { desde, hasta } de la cifra (modo
// «necesario») o null; `enLimite`: en «llega», si el margen la deja en el límite entre dos tramos.
// Devuelve los huecos del contexto, de la evolución y del comparador.
// `tipologia`: 'VC' | 'VU' si la serie del mapa la distingue; null si no.
export function fichaSeccion(contenedor, { t, codigo, territorios, modo, mapaId, mapaDef, ficha, supuestos, anio, valor, estado, estados, ejemplo, aviso, alCerrar, tipologia = null, fiabilidad = null, intervalo = null, enLimite = false }) {
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
    if (intervalo) {
      const d = mapaDef.decimales ?? 0;
      bloque.append(crear('p', 'ficha-intervalo', t('interfaz.ficha.intervalo', {
        desde: t.numero(intervalo.desde, d), hasta: t.numero(intervalo.hasta, d), unidad: t(`indicadores.${mapaId}.unidad`),
      })));
    }
    const lineaF = lineaFiabilidad(t, fiabilidad);
    if (lineaF) bloque.append(lineaF);
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
      if (enLimite) bloque.append(crear('p', 'ficha-limite', t('interfaz.ficha.en_limite')));
    }
    const lineaF = lineaFiabilidad(t, fiabilidad);
    if (lineaF) bloque.append(lineaF);
  }
  const partes = [t('interfaz.ficha.anio', { anio: t.periodo(anio) })];
  if (tipologia) partes.push(t(`vocabulario.tipologia.${tipologia}`));
  // Con 0 contratos, no es «sin dato»: no hay contratos de alquiler registrados (pregunta 12 ampliada)
  partes.push(fiabilidad?.tipo === 'sin_contratos'
    ? t(`interfaz.ficha.sin_contratos.${tipologia ?? 'VC'}`)
    : t(`vocabulario.estado.${estados[estado]}`));
  bloque.append(crear('p', 'ficha-estado', partes.join(' · ')));
  if (aviso) bloque.append(crear('p', 'nota', aviso));
  if (ejemplo) bloque.append(crear('p', 'etiqueta-ejemplo', t('avisos.ejemplo')));

  const huecoContexto = crear('div', 'ficha-hueco');
  const huecoSerie = crear('div', 'ficha-hueco');
  const huecoComparador = crear('div', 'ficha-hueco');
  contenedor.replaceChildren(
    cabecera(t, alCerrar),
    crear('p', 'ficha-codigo', t('interfaz.ficha.seccion', { codigo })),
    datos,
    bloque,
    huecoContexto,
    huecoSerie,
    huecoComparador,
  );
  return { huecoContexto, huecoSerie, huecoComparador };
}

// Contexto de una sección sin mediana del alquiler de la tipología del mapa: la mediana de la
// otra tipología en la sección y la de la misma en su municipio, ya en la unidad del mapa
// (sueldo necesario, % del ingreso…). Rotulado como contexto: nunca se pinta en el mapa (regla 1).
// `filas`: [{ texto, cifra }]; sin filas, el hueco queda vacío.
export function fichaContexto(contenedor, { t, filas }) {
  if (!filas?.length) return contenedor.replaceChildren();
  const bloque = crear('section', 'ficha-contexto');
  bloque.append(crear('h3', 'ficha-indicador', t('interfaz.ficha.contexto')));
  const lista = crear('dl', 'ficha-territorios');
  for (const { texto, cifra } of filas) lista.append(crear('dt', null, texto), crear('dd', null, cifra));
  bloque.append(lista, crear('p', 'nota', t('interfaz.ficha.contexto_nota')));
  contenedor.replaceChildren(bloque);
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
