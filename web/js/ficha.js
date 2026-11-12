// Ficha de sección (panel lateral). Sin sección elegida, una invitación a elegirla; con sección,
// su código, sus territorios y el valor del mapa activo:
//   - sueldo necesario: la cifra en euros con el alquiler mensual real y, al lado, el mínimo teórico
//     con la superficie elegida (decisión 4; tarea 40), con el umbral;
//   - «¿te llega?»: qué estadístico usa la ficha y de quién (tarea 44), el alquiler sobre el ingreso
//     de la ficha, al lado los euros que quedan al mes (ingreso − alquiler, o lo que falta si sale
//     negativa; tarea 34), la proporción con el alquiler mensual real (tarea 40) y debajo las dos
//     cantidades.
// Bajo la cifra, en la sección y el municipio, el indicador 14 con su aviso de lectura (tarea 41).
// Bajo la cifra, la fiabilidad de la mediana del alquiler (fiabilidad.js): sus contratos y su
// margen aproximado, «pocos contratos», el intervalo de la cifra y, en «¿te llega?», si queda en el
// límite entre dos tramos; sin mediana y con 0 contratos, «sin contratos de alquiler registrados»
// en lugar de «sin dato» (plan §11, preguntas 12 y 15 ampliadas).
// Debajo, tres huecos que se rellenan cuando llegan sus datos: el contexto (sin mediana), la
// evolución por años y el comparador. En el sueldo necesario, también la paga en 14 pagas y lo de
// cada uno entre dos sueldos; con «Tu ficha», de dónde sale su ingreso (F3).
// Ficha de territorio (municipio, provincia o comunidad, al pulsarlos con poco zoom; tarea 26): la
// misma cifra con la publicada en su nivel, o «sin dato en este nivel».
// F5: en los mapas de categorías (indicador 20), el texto de la categoría en vez de la cifra y, en la
// ficha del municipio, sus declaraciones (fichaDeclaraciones); en los de un dato privado (portales,
// indicador 13), su etiqueta.

import { ordenNatural } from './nombres.js';
import { clasesTramos, rampaDeCss, TRAMOS_LLEGA } from './colores.js';
import { eurosQueQuedan, SUPERFICIE_DOS_SUELDOS, SUPERFICIES } from './sueldo.js';
import { daSueldo, textoSupuestos } from './formulas.js';
import { lineaTransparencia } from './transparencia.js';

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

// Tarea 53: al pie de la ficha, «Método en dos páginas» (qué mide cada familia y a quién deja fuera)
// y «Avisar de un error».
export const pieFicha = (t) => lineaTransparencia(t, { clase: 'nota ficha-pie' });

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

// Euros que quedan al mes (tarea 34; la resta, eurosQueQuedan() de sueldo.js): «Quedan 673 € al mes
// después del alquiler». Si la resta sale negativa, lo que falta, en positivo: «Faltan 85 € al mes
// para cubrir el alquiler». Con 1 €, en singular. `corto`: «quedan 673 €», para la tabla de la
// evolución. Solo dice la resta: ningún texto dice si con eso llega o no. `gastos`: la resta lleva
// también los otros gastos de vivienda, y la frase larga lo dice («… después del alquiler y los otros
// gastos»; 12-nov-2026); la corta no nombra el alquiler y no cambia. Devuelve la clave, la cifra ya
// escrita (para resaltarla) y el texto entero; null sin resta.
export function textoResto(t, euros, { corto = false, gastos = false } = {}) {
  if (euros === null || euros === undefined || !Number.isFinite(euros)) return null;
  const n = Math.abs(euros);
  const clave = `interfaz.ficha.resto.${euros < 0 ? 'falta' : 'queda'}${corto ? '_corto' : ''}${n === 1 ? '_uno' : ''}${gastos && !corto ? '_gastos' : ''}`;
  const cifra = t('interfaz.ficha.resto.euros', { euros: t.numero(n) });
  return { clave, cifra, texto: t(clave, { cifra }) };
}

// Línea de los euros que quedan, con la cifra resaltada.
function lineaResto(t, resto) {
  const p = crear('p', 'ficha-resto');
  t(resto.clave).split('{cifra}').forEach((parte, i) => {
    if (i > 0) p.append(crear('span', 'ficha-resto-cifra', resto.cifra));
    if (parte) p.append(parte);
  });
  return p;
}

// Tarea 40 (decisión 4): línea del mínimo teórico del sueldo necesario, al lado de la cifra
// principal: «Mínimo teórico con un piso de 50 m²: 1.217 € netos al mes», con la cifra resaltada
// (clase ficha-minimo-cifra). null sin cifra.
export function lineaMinimo(t, minimo, supuestos) {
  if (minimo === null || minimo === undefined || !Number.isFinite(minimo)) return null;
  const p = crear('p', 'ficha-minimo');
  t('interfaz.ficha.minimo', { superficie: t.numero(supuestos.superficie_m2) }).split('{cifra}').forEach((parte, i) => {
    if (i > 0) p.append(crear('span', 'ficha-minimo-cifra', t.numero(minimo)));
    if (parte) p.append(parte);
  });
  return p;
}

// Tarea 44: qué estadístico usa una ficha (media, mediana o mínimo legal) y de quién (hogar o
// persona), en una línea (fichas_metodo.<ficha> de i18n). null si la ficha no lo tiene.
export function lineaMetodo(t, ficha) {
  const clave = `fichas_metodo.${ficha}`;
  return ficha && t.existe(clave) ? crear('p', 'ficha-metodo', t(clave)) : null;
}

// Entre dos sueldos, la vivienda de dos: 70 m² por defecto, a la vista y cambiable a 50 o 90 m²
// (plan §3.1 y §11, pregunta 43 h; decisión del autor, 10-nov-2026), como «Tu ficha» con dos
// sueldos (SUPERFICIE_DOS_SUELDOS, sueldo.js). Lo que elige quien mira dura mientras no recargue la página.
let superficieDosElegida = SUPERFICIE_DOS_SUELDOS;

// El sueldo necesario en las pagas de quien lo mira (F3): en 14 pagas, la paga (× 12 / 14), y
// entre dos sueldos iguales, cada uno con la vivienda de dos: `base` (sueldo necesario de
// `superficie` m², el mínimo teórico) llevado a `superficieDos` m² y ÷ 2. Sin base, la cifra ÷ 2 y
// `superficieDos` null. Solo en los mapas que dan un sueldo.
export function equivalenciasSueldo(valor, { base = null, superficie = null, superficieDos = SUPERFICIE_DOS_SUELDOS } = {}) {
  if (valor === null || valor === undefined || !Number.isFinite(valor)) return null;
  const conBase = Number.isFinite(base) && Number.isFinite(superficie) && superficie > 0 && SUPERFICIES.includes(superficieDos);
  return {
    paga14: (valor * 12) / 14,
    cadaUno: conBase ? (base * superficieDos) / superficie / 2 : valor / 2,
    superficieDos: conBase ? superficieDos : null,
  };
}

// Línea de los dos sueldos, con la superficie a la vista y los botones para cambiarla (50, 70, 90).
function lineaDosSueldos(t, valor, opciones, decimales) {
  const li = crear('li', 'ficha-dos-sueldos');
  const texto = crear('span');
  const pintar = () => {
    const eq = equivalenciasSueldo(valor, { ...opciones, superficieDos: superficieDosElegida });
    texto.textContent = eq.superficieDos
      ? t('interfaz.ficha.dos_sueldos_m2', { euros: t.numero(eq.cadaUno, decimales), superficie: t.numero(eq.superficieDos) })
      : t('interfaz.ficha.dos_sueldos', { euros: t.numero(eq.cadaUno, decimales) });
    for (const b of li.querySelectorAll('button')) b.setAttribute('aria-pressed', String(Number(b.dataset.superficie) === superficieDosElegida));
  };
  li.append(texto);
  if (equivalenciasSueldo(valor, opciones)?.superficieDos) {
    const grupo = crear('span', 'ficha-dos-superficie');
    grupo.setAttribute('role', 'group');
    grupo.setAttribute('aria-label', t('interfaz.ficha.dos_sueldos_superficie'));
    for (const s of SUPERFICIES) {
      const b = crear('button', null, `${t.numero(s)} m²`);
      b.type = 'button';
      b.dataset.superficie = String(s);
      b.addEventListener('click', () => { superficieDosElegida = s; pintar(); });
      grupo.append(b);
    }
    li.append(' ', grupo);
  }
  pintar();
  return li;
}

// Bloque de la cifra del mapa activo (ficha de sección y ficha de territorio).
// `valor`: en el modo «necesario», el sueldo necesario (o null); en «llega», { alquiler,
// ingreso, ratio, tramo } (o null). `estado`: índice en codificacion.estados.
// `fiabilidad`: fiabilidadFicha() o null; `intervalo`: { desde, hasta } de la cifra (modo
// «necesario») o null; `enLimite`: en «llega», si el margen la deja en el límite entre dos tramos.
// `tipologia`: 'VC' | 'VU' si la serie del mapa la distingue; null si no. `sinNivel`: el nombre
// del nivel si la serie no tiene cifra en él (ficha de territorio; regla 1). `sueldo`: el de «Tu
// ficha», para desglosar su ingreso. `notas`: textos de más, al final.
// F5: `grupo` (texto de la operación y el portal), `etiqueta` (dato privado de oferta) y, en los
// mapas de categorías, el texto de la categoría (mapaDef.categorias).
// Tarea 40 (decisión 4): `minimo`, en el sueldo necesario, el mínimo teórico con la superficie
// elegida, al lado de la cifra principal (la del alquiler mensual real); en «¿te llega?», `valor.real`
// (las fichas de una persona) da la proporción con el alquiler mensual mediano real.
// Tarea 44: en «¿te llega?», bajo el título, qué estadístico usa la ficha y de quién, en una línea
// (lineaMetodo). Tarea 41: la llave lleva el aviso de lectura del indicador 14, el mismo cociente.
function bloqueValor({ t, modo, mapaId, mapaDef, ficha, supuestos, anio, valor, estado, estados, ejemplo, aviso, tipologia = null, fiabilidad = null, intervalo = null, enLimite = false, sinNivel = null, sueldo = null, notas = [], grupo = null, etiqueta = null, minimo = null }) {
  const bloque = crear('section', 'ficha-valor');
  const cifra = crear('p', 'ficha-cifra');
  const sinCifra = sinNivel ? t('interfaz.ficha.sin_dato_nivel') : '—';
  const claseNumero = sinNivel ? 'ficha-numero ficha-sin-nivel' : 'ficha-numero';
  if (modo === 'necesario') {
    const nombre = t(`indicadores.${mapaId}.nombre`);
    bloque.append(crear('h3', 'ficha-indicador', grupo ? `${nombre} · ${grupo}` : nombre));
    if (etiqueta) bloque.append(crear('p', 'etiqueta-privado', etiqueta));
    const categorias = mapaDef.categorias;
    if (categorias && valor !== null) {
      cifra.append(crear('span', 'ficha-categoria', t(`vocabulario.${categorias.vocabulario}.${valor}`)));
    } else {
      cifra.append(crear('span', claseNumero, valor === null ? sinCifra : t.numero(valor, mapaDef.decimales ?? 0)));
      if (!sinNivel && !categorias) cifra.append(crear('span', 'ficha-unidad', t(`indicadores.${mapaId}.unidad`)));
    }
    bloque.append(cifra);
    if (intervalo) {
      const d = mapaDef.decimales ?? 0;
      bloque.append(crear('p', 'ficha-intervalo', t('interfaz.ficha.intervalo', {
        desde: t.numero(intervalo.desde, d), hasta: t.numero(intervalo.hasta, d), unidad: t(`indicadores.${mapaId}.unidad`),
      })));
    }
    const lineaF = lineaFiabilidad(t, fiabilidad);
    if (lineaF) bloque.append(lineaF);
    // Tarea 40: al lado de la cifra principal, el mínimo teórico con la superficie elegida
    const lineaM = lineaMinimo(t, minimo, supuestos);
    if (lineaM) bloque.append(lineaM);
    // La superficie y el umbral, solo en los mapas que los usan (el sueldo necesario).
    const textoS = textoSupuestos(t, mapaDef, supuestos);
    if (textoS) bloque.append(crear('p', 'ficha-estado', textoS));
    // El sueldo en 14 pagas y entre dos sueldos (F3), en los mapas que dan un sueldo
    // Entre dos sueldos, con la vivienda de dos (70 m² por defecto; pregunta 43 h): desde el mínimo
    // teórico o, si no lo hay, desde la cifra cuando la calcula la superficie elegida
    const baseDos = Number.isFinite(minimo) ? minimo : mapaDef.formula === 'alquiler_m2_a_sueldo' ? valor : null;
    const opcionesDos = { base: baseDos, superficie: supuestos?.superficie_m2 ?? null };
    const eq = daSueldo(mapaDef) ? equivalenciasSueldo(valor, opcionesDos) : null;
    if (eq) {
      const d = mapaDef.decimales ?? 0;
      const pagas = crear('ul', 'ficha-pagas');
      pagas.setAttribute('aria-label', t('interfaz.ficha.tus_terminos'));
      pagas.append(crear('li', null, t('interfaz.ficha.paga_14', { euros: t.numero(eq.paga14, d) })),
        lineaDosSueldos(t, valor, opcionesDos, d));
      bloque.append(pagas);
    }
  } else {
    bloque.append(crear('h3', 'ficha-indicador', `${t('interfaz.leyenda.llega_titulo')} · ${t(`fichas.${ficha}`)}`));
    const metodo = lineaMetodo(t, ficha);   // tarea 44: estadístico y de quién
    if (metodo) bloque.append(metodo);
    cifra.append(crear('span', claseNumero, valor === null ? sinCifra : t.porcentaje(valor.ratio)));
    // Con los otros gastos de vivienda sumados (`otros`, de calcular()), las dos frases lo dicen
    const conGastos = Number.isFinite(valor?.otros);
    if (!sinNivel) cifra.append(crear('span', 'ficha-unidad', t(conGastos ? 'interfaz.ficha.del_ingreso_gastos' : 'interfaz.ficha.del_ingreso')));
    bloque.append(cifra);
    if (valor !== null) {
      // Al lado del porcentaje, los euros que quedan al mes con los mismos términos (tarea 34)
      const resto = textoResto(t, eurosQueQuedan(valor), { gastos: conGastos });
      if (resto) bloque.append(lineaResto(t, resto));
      // Tarea 40: con el alquiler mensual mediano real de la sección (las fichas de una persona)
      if (valor.real) {
        bloque.append(crear('p', 'ficha-real', t('interfaz.ficha.real_llega', {
          alquiler: t.numero(valor.real.alquiler), pct: t.porcentaje(valor.real.ratio),
        })));
      }
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
    // Tarea 41: la llave es el mismo cociente que el indicador 14 y lleva su aviso de lectura
    if (ficha === 'llave') bloque.append(crear('p', 'nota ficha-aviso-lectura', t('indicadores.esfuerzo_residentes.lectura')));
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

  const huecoResidentes = crear('div', 'ficha-hueco');   // tarea 41: el indicador 14, con su aviso
  const huecoContexto = crear('div', 'ficha-hueco');
  const huecoSerie = crear('div', 'ficha-hueco');
  const huecoComparador = crear('div', 'ficha-hueco');
  contenedor.replaceChildren(
    cabecera(t, alCerrar),
    crear('p', 'ficha-codigo', t('interfaz.ficha.seccion', { codigo })),
    datos,
    bloque,
    huecoResidentes,
    huecoContexto,
    huecoSerie,
    huecoComparador,
    pieFicha(t),
  );
  return { huecoContexto, huecoSerie, huecoComparador, huecoResidentes };
}

// Tarea 41 (decisión 10): el indicador 14, «alquiler mediano sobre renta media del barrio», fuera
// del selector del mapa, en la ficha de la sección y del municipio, con su aviso de lectura (la
// lectura del inventario): el periodo y, si no es «dato», su estado en corto. Sin cifra, el hueco
// queda vacío. `valor`: en % (17,6); `estado`: índice en `estados`.
export function fichaResidentes(contenedor, { t, valor, estado, estados, anio }) {
  if (valor === null || valor === undefined || !Number.isFinite(valor)) return contenedor.replaceChildren();
  const bloque = crear('section', 'ficha-residentes');
  bloque.append(crear('h3', 'ficha-indicador', t('indicadores.esfuerzo_residentes.nombre')));
  const cifra = crear('p', 'ficha-cifra ficha-cifra-secundaria');
  cifra.append(crear('span', 'ficha-residentes-cifra', `${t.numero(valor, 1)} %`),
    crear('span', 'ficha-unidad', t('indicadores.esfuerzo_residentes.unidad')));
  bloque.append(cifra);
  const nombre = estados[estado];
  const partes = [t('interfaz.ficha.anio', { anio: t.periodo(anio) })];
  if (nombre && nombre !== 'dato' && t.existe(`interfaz.estado_corto.${nombre}`)) partes.push(t(`interfaz.estado_corto.${nombre}`));
  bloque.append(crear('p', 'ficha-residentes-anio', partes.join(' · ')),
    crear('p', 'nota ficha-aviso-lectura', t('indicadores.esfuerzo_residentes.lectura')));
  contenedor.replaceChildren(bloque);
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
  const huecoResidentes = crear('div', 'ficha-hueco');   // tarea 41: el indicador 14 (municipios)
  const huecoDetalle = crear('div', 'ficha-hueco');   // F5: declaraciones de zona tensionada
  const huecoSerie = crear('div', 'ficha-hueco');
  const huecoComparador = crear('div', 'ficha-hueco');
  const titulo = crear('p', 'ficha-codigo', propio.nombre);
  titulo.dataset.nivel = nivel;
  titulo.dataset.codigo = codigo;
  contenedor.replaceChildren(cabecera(t, alCerrar, t('interfaz.ficha.titulo_territorio')), titulo, datos, bloque, huecoResidentes, huecoDetalle, huecoSerie, huecoComparador, pieFicha(t));
  return { huecoSerie, huecoComparador, huecoDetalle, huecoResidentes };
}

// F5: declaraciones de zona de mercado residencial tensionado de un municipio (indicador 20), de
// datos/zonas_tensionadas.json: ámbito (todo el municipio o la parte que fija la declaración), periodo
// de vigencia, resolución del BOE y declaración de la comunidad, con sus enlaces. `declaraciones`:
// [{ boe, inicio, fin, ambito, ambito_texto, declaracion, url, url_declaracion }]; `fecha(x)` escribe
// una fecha «AAAA-MM-DD». Sin declaraciones, lo dice. Al pie, que es política pública.
export function fichaDeclaraciones(contenedor, { t, declaraciones, fecha }) {
  const bloque = crear('section', 'ficha-declaraciones');
  bloque.append(crear('h3', 'ficha-indicador', t('interfaz.ficha.zonas.titulo')));
  if (!declaraciones?.length) {
    bloque.append(crear('p', 'ficha-estado', t('interfaz.ficha.zonas.ninguna')));
  } else {
    const lista = crear('ul', 'ficha-lista-declaraciones');
    for (const d of declaraciones) {
      const item = crear('li');
      item.append(crear('p', 'ficha-declaracion-ambito', d.ambito === 'parcial'
        ? t('interfaz.ficha.zonas.parcial', { ambito: d.ambito_texto })
        : t('interfaz.ficha.zonas.municipio')));
      item.append(crear('p', 'ficha-estado', t('interfaz.ficha.zonas.vigencia', { inicio: fecha(d.inicio), fin: fecha(d.fin) })));
      const enlace = (url, texto) => {
        const a = crear('a', null, texto);
        a.href = url;
        a.rel = 'noopener';
        return a;
      };
      const boe = crear('p', 'ficha-estado');
      boe.append(enlace(d.url, t('interfaz.ficha.zonas.resolucion', { boe: d.boe })));
      item.append(boe);
      if (d.declaracion) {
        const dec = crear('p', 'nota');
        if (d.url_declaracion) dec.append(enlace(d.url_declaracion, d.declaracion));
        else dec.textContent = d.declaracion;
        item.append(dec);
      }
      lista.append(item);
    }
    bloque.append(lista);
  }
  bloque.append(crear('p', 'nota', t('interfaz.ficha.zonas.nota')));
  contenedor.replaceChildren(bloque);
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
// si no es «dato», su estado. `filas`: [{ periodo, texto, estado, resto }]; `resto`, en «¿te
// llega?», los euros que quedan al mes («quedan 673 €»; tarea 34), en una columna al lado.
// Tareas 43 y 45 (evolucion.js): `grafico`, el gráfico con la banda del margen, encima de la tabla;
// `variacion` de cada fila, en una columna con cabecera (`cabeceras`: { periodo, cifra, variacion });
// `notas`, al pie (banda, pocos contratos, regla de las variaciones, euros corrientes o del año
// base e IPC). `selector`: en las series en euros, «Euros de {año base} · Euros de cada año», bajo
// el título (decisión del autor, 12-nov-2026).
export function fichaSeries(contenedor, { t, titulo, nota, filas, estados, periodo, grafico = null, cabeceras = null, notas = [], selector = null }) {
  const cuerpo = crear('tbody');
  const conResto = filas.some((f) => f.resto);
  const conVariacion = filas.some((f) => f.variacion);
  for (const fila of filas) {
    const tr = crear('tr', String(fila.periodo) === String(periodo) ? 'ficha-tabla-activa' : undefined);
    const th = crear('th', null, t.periodo(fila.periodo));
    th.scope = 'row';
    const nombre = estados[fila.estado];
    tr.append(
      th,
      crear('td', 'ficha-tabla-cifra', fila.texto),
      ...(conVariacion ? [crear('td', 'ficha-tabla-variacion', fila.variacion ?? '')] : []),
      ...(conResto ? [crear('td', 'ficha-tabla-resto', fila.resto ?? '')] : []),
      crear('td', 'ficha-tabla-estado', nombre === 'dato' ? '' : t(`interfaz.estado_corto.${nombre}`)),
    );
    cuerpo.append(tr);
  }
  const tabla = crear('table', 'ficha-tabla');
  if (conVariacion && cabeceras) {
    const fila = crear('tr');
    for (const [texto, clase] of [[cabeceras.periodo, null], [cabeceras.cifra, 'ficha-tabla-cifra'], [cabeceras.variacion, 'ficha-tabla-variacion'], ['', null]]) {
      const th = crear('th', clase, texto ?? '');
      th.scope = 'col';
      fila.append(th);
    }
    const cabeza = crear('thead');
    cabeza.append(fila);
    tabla.append(cabeza);
  }
  tabla.append(cuerpo);
  const bloque = crear('section', 'ficha-serie');
  bloque.append(crear('h3', 'ficha-indicador', titulo), ...(selector ? [selector] : []), ...(grafico ? [grafico] : []), tabla);
  if (nota) bloque.append(crear('p', 'nota', nota));
  for (const n of notas) bloque.append(crear('p', 'nota', n));
  contenedor.replaceChildren(bloque);
}
