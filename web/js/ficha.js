// Ficha de sección (panel lateral). Sin sección elegida, una invitación a elegirla; con sección,
// su código, sus territorios y el valor del mapa activo:
//   - sueldo necesario: la cifra en euros, con la superficie y el umbral;
//   - «¿te llega?»: el alquiler sobre el ingreso de la ficha, con las dos cantidades.
// Bajo la cifra, la fiabilidad de la mediana del alquiler (fiabilidad.js): sus contratos y su
// margen aproximado, «pocos contratos», el intervalo de la cifra y, en «¿te llega?», si queda en el
// límite entre dos tramos; sin mediana y con 0 contratos, «sin contratos de alquiler registrados»
// en lugar de «sin dato» (plan §11, preguntas 12 y 15 ampliadas).
// Debajo, tres huecos que se rellenan cuando llegan sus datos: el contexto (sin mediana), la
// evolución por años y el comparador. En el sueldo necesario, también la paga en 14 pagas y lo de
// cada uno entre dos sueldos; con «Tu ficha», de dónde sale su ingreso (F3).
// Ficha de territorio (municipio, provincia o comunidad, al pulsarlos con poco zoom; tarea 26): la
// misma cifra con la publicada en su nivel, o «sin dato en este nivel».

import { ordenNatural } from './nombres.js';
import { clasesTramos, rampaDeCss, TRAMOS_LLEGA } from './colores.js';

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

function cabecera(t, alCerrar, titulo = t('interfaz.ficha.titulo')) {
  const caja = crear('header', 'ficha-cabecera');
  caja.append(crear('h2', 'ficha-titulo', titulo));
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

// Sin nada elegido. Con un nivel con que comparar ya elegido (por ejemplo, desde la casilla
// «Mudanza» de la portada, ?comparar=municipio), lo dice.
export function fichaVacia(contenedor, { t, comparar = null }) {
  const partes = [crear('p', 'ficha-vacia', t('interfaz.ficha.vacia'))];
  if (comparar) {
    partes.push(crear('p', 'ficha-vacia ficha-vacia-nota', t('interfaz.ficha.vacia_comparar', { nivel: t(`vocabulario.nivel.${comparar}`).toLowerCase() })));
  }
  contenedor.replaceChildren(cabecera(t), ...partes);
}

// Nombres de las provincias que rodean un trozo de suelo sin sección, en orden alfabético.
export function provinciasSinSeccion(codigos, territorios) {
  return codigos.map((p) => ordenNatural(territorios.provincia?.[p] ?? p)).sort((a, b) => a.localeCompare(b, 'es'));
}

// Ficha del suelo sin sección (capa sin_seccion del mapa base): terreno comunal que no es de
// ningún término municipal. Sin datos: qué es, las provincias que lo rodean y su superficie. Si el
// trozo es de una unidad del IGN, su nombre (el literal del IGN) y su tipo, con la fuente al pie.
export function fichaSinSeccion(contenedor, { t, km2, provincias, nombre = null, tipo = null, territorios, alCerrar }) {
  const nombres = provinciasSinSeccion(provincias, territorios);
  const datos = crear('dl', 'ficha-territorios');
  if (nombre) {
    datos.append(crear('dt', null, t('interfaz.ficha.nombre')), crear('dd', null, nombre));
    const claveTipo = `interfaz.ficha.tipo_ign.${tipo}`;
    if (tipo) datos.append(crear('dt', null, t('interfaz.ficha.tipo')), crear('dd', null, t.existe(claveTipo) ? t(claveTipo) : tipo));
  }
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
    ...(nombre ? [crear('p', 'ficha-estado', t('interfaz.ficha.fuente_ign'))] : []),
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

// Desglose del ingreso de «Tu ficha» (plan §3.1 y F3: 14 pagas y segundo sueldo en la ficha): la
// paga, el segundo sueldo y las 14 pagas repartidas en 12. `sueldo`: { neto, pagas, segundo }.
export function textoIngresoPeon(t, sueldo, ingreso) {
  if (!sueldo?.neto || !ingreso) return null;
  const clave = `${sueldo.pagas === 14 ? '14' : '12'}${sueldo.segundo > 0 ? '_segundo' : ''}`;
  return t(`interfaz.ficha.ingreso_peon.${clave}`, {
    neto: t.numero(sueldo.neto), segundo: t.numero(sueldo.segundo ?? 0), ingreso: t.numero(ingreso),
  });
}

// El sueldo necesario en las pagas de quien lo mira (F3): en 14 pagas, la paga (× 12 / 14), y
// entre dos sueldos iguales, cada uno (÷ 2). Solo en los mapas que dan un sueldo.
export function equivalenciasSueldo(valor) {
  if (valor === null || valor === undefined || !Number.isFinite(valor)) return null;
  return { paga14: (valor * 12) / 14, cadaUno: valor / 2 };
}

// Bloque de la cifra del mapa activo (ficha de sección y ficha de territorio).
// `valor`: en el modo «necesario», el sueldo necesario (o null); en «llega», { alquiler,
// ingreso, ratio, tramo } (o null). `estado`: índice en codificacion.estados.
// `fiabilidad`: fiabilidadFicha() o null; `intervalo`: { desde, hasta } de la cifra (modo
// «necesario») o null; `enLimite`: en «llega», si el margen la deja en el límite entre dos tramos.
// `tipologia`: 'VC' | 'VU' si la serie del mapa la distingue; null si no. `sinNivel`: el nombre
// del nivel si la serie no tiene cifra en él (ficha de territorio; regla 1). `sueldo`: el de «Tu
// ficha», para desglosar su ingreso. `notas`: textos de más, al final.
function bloqueValor({ t, modo, mapaId, mapaDef, ficha, supuestos, anio, valor, estado, estados, ejemplo, aviso, tipologia = null, fiabilidad = null, intervalo = null, enLimite = false, sinNivel = null, sueldo = null, notas = [] }) {
  const bloque = crear('section', 'ficha-valor');
  const cifra = crear('p', 'ficha-cifra');
  const sinCifra = sinNivel ? t('interfaz.ficha.sin_dato_nivel') : '—';
  const claseNumero = sinNivel ? 'ficha-numero ficha-sin-nivel' : 'ficha-numero';
  if (modo === 'necesario') {
    bloque.append(crear('h3', 'ficha-indicador', t(`indicadores.${mapaId}.nombre`)));
    cifra.append(crear('span', claseNumero, valor === null ? sinCifra : t.numero(valor, mapaDef.decimales ?? 0)));
    if (!sinNivel) cifra.append(crear('span', 'ficha-unidad', t(`indicadores.${mapaId}.unidad`)));
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
    // El sueldo en 14 pagas y entre dos sueldos (F3), en los mapas que dan un sueldo
    const eq = mapaDef.formula === 'alquiler_m2_a_sueldo' ? equivalenciasSueldo(valor) : null;
    if (eq) {
      const d = mapaDef.decimales ?? 0;
      const pagas = crear('ul', 'ficha-pagas');
      pagas.setAttribute('aria-label', t('interfaz.ficha.tus_terminos'));
      pagas.append(crear('li', null, t('interfaz.ficha.paga_14', { euros: t.numero(eq.paga14, d) })),
        crear('li', null, t('interfaz.ficha.dos_sueldos', { euros: t.numero(eq.cadaUno, d) })));
      bloque.append(pagas);
    }
  } else {
    bloque.append(crear('h3', 'ficha-indicador', `${t('interfaz.leyenda.llega_titulo')} · ${t(`fichas.${ficha}`)}`));
    cifra.append(crear('span', claseNumero, valor === null ? sinCifra : t.porcentaje(valor.ratio)));
    if (!sinNivel) cifra.append(crear('span', 'ficha-unidad', t('interfaz.ficha.del_ingreso')));
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
    // «Tu ficha»: de dónde sale el ingreso (las 14 pagas y el segundo sueldo; F3)
    const desglose = ficha === 'peon' ? textoIngresoPeon(t, sueldo, valor?.ingreso ?? null) : null;
    if (desglose) {
      bloque.append(crear('p', 'ficha-pagas', desglose));
      if (sueldo.pagas === 14) bloque.append(crear('p', 'nota', t('interfaz.ficha.pagas_nota')));
    }
    const lineaF = lineaFiabilidad(t, fiabilidad);
    if (lineaF) bloque.append(lineaF);
  }
  if (sinNivel) {
    bloque.append(crear('p', 'nota', t('interfaz.ficha.sin_dato_nivel_nota', { nivel: sinNivel })));
    for (const nota of notas) bloque.append(crear('p', 'nota', nota));
    if (ejemplo) bloque.append(crear('p', 'etiqueta-ejemplo', t('avisos.ejemplo')));
    return bloque;
  }
  const partes = [t('interfaz.ficha.anio', { anio: t.periodo(anio) })];
  if (tipologia) partes.push(t(`vocabulario.tipologia.${tipologia}`));
  // Con 0 contratos, no es «sin dato»: no hay contratos de alquiler registrados (pregunta 12 ampliada)
  partes.push(fiabilidad?.tipo === 'sin_contratos'
    ? t(`interfaz.ficha.sin_contratos.${tipologia ?? 'VC'}`)
    : t(`vocabulario.estado.${estados[estado]}`));
  bloque.append(crear('p', 'ficha-estado', partes.join(' · ')));
  if (aviso) bloque.append(crear('p', 'nota', aviso));
  for (const nota of notas) bloque.append(crear('p', 'nota', nota));
  if (ejemplo) bloque.append(crear('p', 'etiqueta-ejemplo', t('avisos.ejemplo')));
  return bloque;
}

// Ficha de sección. Devuelve los huecos del contexto, de la evolución y del comparador.
export function fichaSeccion(contenedor, { t, codigo, territorios, alCerrar, ...resto }) {
  const municipio = codigo.slice(0, 5);
  const provincia = codigo.slice(0, 2);
  const lineas = [
    ['vocabulario.nivel.municipio', ordenNatural(territorios.municipio?.[municipio] ?? municipio)],
    ['vocabulario.nivel.distrito', codigo.slice(5, 7)],
    ['vocabulario.nivel.provincia', ordenNatural(territorios.provincia?.[provincia] ?? provincia)],
  ];
  const datos = crear('dl', 'ficha-territorios');
  for (const [clave, texto] of lineas) datos.append(crear('dt', null, t(clave)), crear('dd', null, texto));
  const bloque = bloqueValor({ t, ...resto });

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

// Nombres de un territorio (municipio, provincia o comunidad) y de los que lo contienen, como los
// pone la ficha: [{ nivel, nombre }], del propio al más amplio. También para la etiqueta del mapa.
export function nombresTerritorio(nivel, codigo, territorios) {
  const nombre = (n, c) => ordenNatural(territorios?.[n]?.[c] ?? c);
  const lista = [{ nivel, nombre: nombre(nivel, codigo) }];
  if (nivel === 'ccaa') return lista;
  const provincia = codigo.slice(0, 2);
  if (nivel === 'municipio') lista.push({ nivel: 'provincia', nombre: nombre('provincia', provincia) });
  const ccaa = territorios?.ccaa_de_provincia?.[provincia];
  if (ccaa) lista.push({ nivel: 'ccaa', nombre: nombre('ccaa', ccaa) });
  return lista;
}

// Ficha de un municipio, una provincia o una comunidad (tarea 26): su nombre, los territorios que
// lo contienen y la cifra del mapa activo publicada en su nivel (regla 1: si la serie no la tiene,
// «sin dato en este nivel», con `sinNivel`). Devuelve los huecos de la evolución y del comparador.
export function fichaTerritorio(contenedor, { t, nivel, codigo, territorios, alCerrar, sinNivel = false, ...resto }) {
  const [propio, ...superiores] = nombresTerritorio(nivel, codigo, territorios);
  const datos = crear('dl', 'ficha-territorios');
  datos.append(crear('dt', null, t(`vocabulario.nivel.${nivel}`)), crear('dd', null, codigo));   // el código del INE
  for (const { nivel: n, nombre } of superiores) datos.append(crear('dt', null, t(`vocabulario.nivel.${n}`)), crear('dd', null, nombre));
  const bloque = bloqueValor({ t, ...resto, sinNivel: sinNivel ? t(`vocabulario.nivel.${nivel}`).toLowerCase() : null });
  const huecoSerie = crear('div', 'ficha-hueco');
  const huecoComparador = crear('div', 'ficha-hueco');
  const titulo = crear('p', 'ficha-codigo', propio.nombre);
  titulo.dataset.nivel = nivel;
  titulo.dataset.codigo = codigo;
  contenedor.replaceChildren(cabecera(t, alCerrar, t('interfaz.ficha.titulo_territorio')), titulo, datos, bloque, huecoSerie, huecoComparador);
  return { huecoSerie, huecoComparador };
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
