// «Tu sueldo» (plan, §6.6 y §3.1): la lógica, sin DOM ni mapa, para que el mapa, la leyenda,
// la ficha y las pruebas usen las mismas cuentas.
//
// Dos modos:
//   - «necesario» (por defecto): sueldo neto necesario para que el alquiler mensual mediano real
//     no pase del umbral (indicador 21; decisión 4, tarea 40), en siete tramos con el juego de
//     cortes de cada escala del manifiesto (tarea 51); la ficha da al lado el mínimo teórico con la superficie elegida (formulas.js);
//   - «llega» («¿te llega?», al escribir un sueldo o elegir una ficha): alquiler / ingreso, en
//     tres tramos (hasta el 30 %, del 30 al 40 % y más del 40 %), con la proporción de secciones
//     donde el alquiler cabe por debajo del umbral; en la ficha, también los euros que quedan al
//     mes (ingreso − alquiler; tarea 34). Las fichas de una persona pagan la superficie de la
//     ficha (regla 8) y llevan al lado la cifra con el alquiler mensual mediano real (tarea 40).
// Con «Añadir otros gastos de vivienda» (decisión del autor, 12-nov-2026), los dos modos suman al
// alquiler los otros gastos de vivienda de los inquilinos de la comunidad (abajo, gastosDelAnio()).
// Cada cálculo tiene dos caras que deben coincidir: la expresión de estilo de MapLibre (color
// del mapa, sin volver a descargar teselas) y la función en JS (ficha, resumen, leyenda).

import { formulaDe } from './formulas.js';
import { pasosDeRampa, juegoDe } from './colores.js';
import { SUPUESTOS } from './supuestos.js';

export const FICHAS_PERFIL = ['mochila', 'tartera', 'transistor', 'llave'];
// Supuestos (tarea 48): salen de inventario/supuestos.csv por js/supuestos.js, que genera R
// (generar_supuestos_js()); aquí no se escriben cifras. Superficies de «Tu ficha» (50, 70 y 90 m²)
// y la de una persona (50 m²).
export const SUPERFICIES = SUPUESTOS.superficies;
export const SUPERFICIE_UNA_PERSONA = SUPUESTOS.superficie_una_persona;
// Piso de dos sueldos: 70 m² por defecto, a la vista y cambiable (plan §3.1 y §11, pregunta 43 h):
// «Tu ficha» con segundo sueldo, la línea de dos sueldos de la ficha y «entrar».
export const SUPERFICIE_DOS_SUELDOS = SUPUESTOS.superficie_dos_sueldos;
export const UMBRALES = SUPUESTOS.umbrales;
export const LIMITES_LLEGA = SUPUESTOS.limites_llega;

const SUELDO_MAXIMO = SUPUESTOS.sueldo_maximo;

// Sueldo escrito («1500», «1.500», «1500,50», «1 500 €») → número, o null si no vale. Un punto
// seguido de tres cifras es de millar («1.500» son mil quinientos, no uno y medio). Lo usan la
// portada y «Tu sueldo» del mapa.
export function leerSueldo(texto) {
  let s = String(texto ?? '').replace(/[\s €]/g, '');
  if (/^\d{1,3}(\.\d{3})+(,\d+)?$/.test(s)) s = s.replace(/\./g, '').replace(',', '.');
  else s = s.replace(',', '.');
  if (!/^\d+(\.\d+)?$/.test(s)) return null;
  const x = Number(s);
  return Number.isFinite(x) && x > 0 && x <= SUELDO_MAXIMO ? x : null;
}

// Ingreso de «Tu ficha»: neto mensual repartido en 12 (regla 8). Con 14 pagas, la paga × 14 / 12;
// el segundo sueldo, si lo hay, se suma con las mismas pagas.
export function ingresoPeon(sueldo) {
  const valido = (x) => Number.isFinite(x) && x > 0 && x <= SUELDO_MAXIMO;
  if (!sueldo || !valido(sueldo.neto)) return null;
  const pagas = SUPUESTOS.pagas.includes(sueldo.pagas) ? sueldo.pagas : SUPUESTOS.pagas_defecto;
  const segundo = valido(sueldo.segundo) ? sueldo.segundo : 0;
  return ((sueldo.neto + segundo) * pagas) / 12;
}

// Superficie típica de los pisos alquilados de un territorio (tarea 48; backlog, decisión 5):
// alquiler mensual mediano / alquiler por m² mediano del SERPAVI, como superficie_tipica_serpavi()
// de R. Es el cociente de dos medianas, no la mediana de las superficies. La usan «Tu ficha» (opción
// «típica») y la ficha de municipio (decisión del autor, 11-nov-2026). null sin los dos términos.
export function superficieTipica(alquilerMes, alquilerM2) {
  if (!Number.isFinite(alquilerMes) || !Number.isFinite(alquilerM2) || !(alquilerM2 > 0) || !(alquilerMes > 0)) return null;
  return alquilerMes / alquilerM2;
}

export function modoDe(estado, sueldo, perfiles) {
  if (estado.ficha === 'peon') return ingresoPeon(sueldo) ? 'llega' : 'necesario';
  if (estado.ficha && perfiles?.[estado.ficha]) return 'llega';
  return 'necesario';
}

// Superficie del cálculo (§3.1): las fichas de una persona, la suya (50 m²), para que sus mapas
// solo difieran por el ingreso; la llave, ninguna (paga el alquiler mediano de su sección); el
// peón y el mapa del sueldo necesario, la elegida o, si no, 50 m² con un sueldo y 70 con dos.
// Decisión del autor (11-nov-2026; plan §11, pregunta 59): la superficie típica (`superficie` =
// SUPERFICIE_TIPICA) es una opción más; `tipica`, la del territorio que manda (principal.js). Sin
// ella (sin territorio o sin los dos términos), la de por defecto.
export const SUPERFICIE_TIPICA = 'tipica';
export function superficieDe(estado, sueldo, perfiles, tipica = null) {
  const ficha = estado.ficha;
  if (ficha === 'llave' && perfiles?.llave) return null;
  if (ficha && ficha !== 'peon' && perfiles?.[ficha]) return perfiles[ficha].superficie_m2 ?? SUPERFICIE_UNA_PERSONA;
  if (estado.superficie === SUPERFICIE_TIPICA && Number.isFinite(tipica) && tipica > 0) return tipica;
  if (SUPERFICIES.includes(estado.superficie)) return estado.superficie;
  return ficha === 'peon' && ingresoPeon(sueldo) && sueldo.segundo > 0 ? SUPERFICIE_DOS_SUELDOS : SUPERFICIE_UNA_PERSONA;
}

export const umbralDe = (estado) => (UMBRALES.includes(estado.umbral) ? estado.umbral : SUPUESTOS.umbral_sueldo) / 100;

// Ingreso de una ficha de perfil en una sección: el de su provincia o el nacional (código «00»).
export function ingresoPerfil(perfil, seccion) {
  if (!perfil?.neto_mensual) return null;
  const clave = perfil.nivel === 'provincia' ? seccion.slice(0, 2) : '00';
  const x = perfil.neto_mensual[clave];
  return Number.isFinite(x) && x > 0 ? x : null;
}

// Perfil de una ficha con el ingreso del año del alquiler (regla 4; decisión del autor, 9-nov-2026):
// si la ficha tiene ese año (`anios`, por ejemplo la tartera de 2015 a 2026), su ingreso y su
// año; si no, el último que tiene (`anio`, `neto_mensual`), y la web avisa de que no son del
// mismo año. La llave no cambia: su ingreso es la renta de la sección del mismo periodo.
export function perfilDelAnio(perfil, anio) {
  const delAnio = anio === null || anio === undefined ? null : perfil?.anios?.[String(anio)];
  return delAnio ? { ...perfil, anio: Number(anio), neto_mensual: delAnio } : perfil;
}

export function perfilesDelAnio(perfiles, anio) {
  if (!perfiles) return perfiles;
  return Object.fromEntries(Object.entries(perfiles).map(([f, p]) => [f, f === 'llave' ? p : perfilDelAnio(p, anio)]));
}

function expresionIngresoPerfil(perfil, idSeccion) {
  const pares = Object.entries(perfil.neto_mensual ?? {}).filter(([, x]) => x > 0);
  if (perfil.nivel === 'provincia') {
    if (!pares.length) return 0;
    return ['match', ['slice', ['to-string', ['get', idSeccion]], 0, 2], ...pares.flat(), 0];
  }
  return perfil.neto_mensual?.['00'] ?? 0;
}

// --- Otros gastos de vivienda (decisión del autor, 12-nov-2026) ---------------------------------
// Selector «Añadir otros gastos de vivienda» (clave `gastos` de la dirección, apagado por defecto):
// al alquiler de cada territorio se le suma lo que pagan de más al mes los hogares que alquilan a
// precio de mercado (HH070 − HH060 de la ECV: la mediana de España de la ola por el factor de la
// comunidad, que sale de todas las olas juntas, o, sin muestra, la de España; datos/otros_gastos.json,
// R/fuente_ine_ecv_gastos.R). Vale para «¿te llega?» y el sueldo necesario.

// Ola de la ECV para un año del alquiler (2024 o «2025-05»): la misma o la más cercana (en un empate,
// la más reciente), como anio_ecv_para() de R. null sin olas o sin año.
export function anioEcv(anios, anio) {
  const a = Number(String(anio ?? '').slice(0, 4));
  if (!anios?.length || !Number.isFinite(a) || a <= 0) return null;
  let mejor = null;
  for (const x of anios.map(Number)) {
    if (mejor === null || Math.abs(x - a) < Math.abs(mejor - a) || (Math.abs(x - a) === Math.abs(mejor - a) && x > mejor)) mejor = x;
  }
  return mejor;
}

// Cifras de la ola que toca al alquiler de `anio`: { anio (el del alquiler), anio_ecv, minimo,
// olas: { desde, hasta } (las del factor de las comunidades), espana: { v, n },
// ccaa: { código: { v, espana } }, provincia: { código: v }, nombres }.
// `ccaaDeProvincia`: la de territorios.json; `nombres`: los de las comunidades (para los textos).
// null sin tabla o sin ola.
export function gastosDelAnio(tabla, anio, ccaaDeProvincia = {}, nombres = {}) {
  const ola = anioEcv(tabla?.anios, anio);
  const cifras = ola === null ? null : tabla.cifras?.[String(ola)];
  if (!cifras?.['00'] || !Number.isFinite(cifras['00'].v)) return null;
  const ccaa = Object.fromEntries(Object.entries(cifras).filter(([c, x]) => c !== '00' && Number.isFinite(x?.v)));
  const provincia = {};
  for (const [p, c] of Object.entries(ccaaDeProvincia ?? {})) if (ccaa[c]) provincia[p] = ccaa[c].v;
  const olas = tabla.anios.map(Number);
  return {
    anio: Number(String(anio).slice(0, 4)), anio_ecv: ola, minimo: tabla.minimo_hogares ?? null,
    olas: { desde: Math.min(...olas), hasta: Math.max(...olas) },
    espana: cifras['00'], ccaa, provincia, ccaaDeProvincia: ccaaDeProvincia ?? {}, nombres: nombres ?? {},
  };
}

// Cifra de un territorio: { valor, ccaa (código, o '00' en España), espana (la de España por falta de
// muestra) }. Las secciones, los municipios y las provincias, la de su comunidad (de sus dos primeras
// cifras); con nivel 'ccaa', la suya; con 'nacional' o un código sin comunidad, la de España. Sin
// `gastos`, null.
export function otrosGastosEn(gastos, codigo, nivel = null) {
  if (!gastos) return null;
  const deEspana = { valor: gastos.espana.v, ccaa: '00', espana: false };
  if (nivel === 'nacional' || codigo === undefined || codigo === null || codigo === '00') return deEspana;
  const c = nivel === 'ccaa' ? String(codigo) : gastos.ccaaDeProvincia[String(codigo).slice(0, 2)];
  const x = c ? gastos.ccaa[c] : null;
  return x ? { valor: x.v, ccaa: c, espana: Boolean(x.espana) } : deEspana;
}

// Supuestos de un territorio: con los otros gastos encendidos, `otros` es su cifra (las fórmulas la
// suman al alquiler) y `otros_de`, de dónde sale; si no, los mismos supuestos.
export function supuestosEn(supuestos, codigo, nivel = null) {
  const x = otrosGastosEn(supuestos?.gastos, codigo, nivel);
  return x ? { ...supuestos, otros: x.valor, otros_de: x } : supuestos;
}

// Expresión de MapLibre con la cifra de cada elemento: en las comunidades, por su código; en los
// demás niveles, por la provincia (las dos primeras cifras). Lo que no casa, la de España.
export function expresionOtrosGastos(gastos, idSeccion, nivel = null) {
  const codigo = ['to-string', ['get', idSeccion]];
  const pares = nivel === 'ccaa'
    ? Object.entries(gastos.ccaa).map(([c, x]) => [c, x.v])
    : Object.entries(gastos.provincia);
  if (!pares.length) return gastos.espana.v;
  return ['match', nivel === 'ccaa' ? codigo : ['slice', codigo, 0, 2], ...pares.flat(), gastos.espana.v];
}

// Mínimo y máximo de las cifras de las comunidades (la leyenda y la imagen, sin territorio).
export function rangoOtrosGastos(gastos) {
  const v = Object.values(gastos?.ccaa ?? {}).map((x) => x.v).filter(Number.isFinite);
  return v.length ? { desde: Math.min(...v), hasta: Math.max(...v) } : null;
}

const estadoMapa = (serie) => ['feature-state', serie];
const numero = (serie) => ['to-number', estadoMapa(serie)];
const falta = (serie) => ['==', estadoMapa(serie), null];

// Cálculo de «¿te llega?» para una ficha. `x(serie)` da el valor de una serie en la sección.
// `serie(nombre)` da la serie que se usa en lugar de cada una: la del alquiler de la tipología
// elegida (vivienda colectiva o unifamiliar; datos.js, serieDeTipologia); por defecto, la misma.
//   series: las que hay que cargar en el mapa (la primera, la del alquiler);
//   calcular(seccion, x) → { alquiler, ingreso, ratio } o null;
//   ingreso(seccion, x) → el ingreso de la ficha en la sección, o null si falta (estadoLlega);
//   expresion(idSeccion, nivel) → { valido, ratio }, expresiones de MapLibre.
// La «sección» puede ser también un municipio o una provincia (el ingreso provincial sale de sus
// dos primeras cifras). `nivel`: con 'ccaa', una ficha con ingreso por provincia no tiene uno solo
// para toda la comunidad, y queda sin dato (tarea 26).
// `gastos` (gastosDelAnio(), con el selector de otros gastos encendido): la cifra de cada territorio
// se suma al alquiler de la ficha y al real; `calcular()` la devuelve en `otros` (el alquiler sigue
// siendo solo el alquiler) y la proporción es (alquiler + otros) / ingreso.
export function calculoLlega({ ficha, perfiles, sueldo, superficie, serie = (s) => s, nivel = null, gastos = null }) {
  const otrosDe = (seccion) => (gastos ? otrosGastosEn(gastos, seccion, nivel).valor : 0);
  const conOtros = (expresion, idSeccion, nivelCapa) => (gastos ? ['+', expresion, expresionOtrosGastos(gastos, idSeccion, nivelCapa)] : expresion);
  const conGastos = (r, otros) => (gastos ? { ...r, otros } : r);
  if (ficha === 'llave') {
    const { ingreso } = perfiles.llave;
    const vivienda = { serie: serie(perfiles.llave.vivienda.serie) };
    const divisor = ingreso.divisor ?? 12;
    return {
      ficha,
      series: [vivienda.serie, ingreso.serie],
      ingreso(seccion, x) {
        const renta = x(ingreso.serie);
        return renta === null || !(renta > 0) ? null : renta / divisor;
      },
      calcular(seccion, x) {
        const alquiler = x(vivienda.serie);
        const renta = x(ingreso.serie);
        if (alquiler === null || renta === null || !(renta > 0)) return null;
        const otros = otrosDe(seccion);
        return conGastos({ alquiler, ingreso: renta / divisor, ratio: (alquiler + otros) / (renta / divisor) }, otros);
      },
      expresion(idSeccion, nivelCapa = nivel) {
        const ing = ['/', numero(ingreso.serie), divisor];
        return {
          valido: ['all', ['!', falta(vivienda.serie)], ['!', falta(ingreso.serie)], ['>', numero(ingreso.serie), 0]],
          ratio: ['/', conOtros(numero(vivienda.serie), idSeccion, nivelCapa), ing],
        };
      },
    };
  }
  const perfil = ficha === 'peon' ? null : perfiles[ficha];
  const fijo = ficha === 'peon' ? ingresoPeon(sueldo) : null;
  const sinIngresoEn = (n) => n === 'ccaa' && perfil?.nivel === 'provincia';
  const ingresoDe = (seccion) => (sinIngresoEn(nivel) ? null : perfil ? ingresoPerfil(perfil, seccion) : fijo);
  const m2Serie = serie('alquiler_m2');
  // Tarea 40 (decisión 4): al lado, el mismo ingreso frente al alquiler mensual mediano real de la
  // sección. El mapa sigue con la superficie de la ficha (regla 8). Sin esa serie, nada.
  const realSerie = serie('alquiler_mes');
  return {
    ficha,
    series: [m2Serie],
    serieReal: realSerie,
    ingreso: (seccion) => ingresoDe(seccion) || null,
    calcular(seccion, x) {
      const m2 = x(m2Serie);
      const ingreso = ingresoDe(seccion);
      if (m2 === null || !ingreso) return null;
      const alquiler = m2 * superficie;
      const otros = otrosDe(seccion);
      const mes = x(realSerie);
      const real = mes === null || mes === undefined ? null : { alquiler: mes, ratio: (mes + otros) / ingreso };
      return conGastos({ alquiler, ingreso, ratio: (alquiler + otros) / ingreso, ...(real ? { real } : {}) }, otros);
    },
    expresion(idSeccion, nivelCapa = nivel) {
      const ingreso = sinIngresoEn(nivelCapa) ? 0 : perfil ? expresionIngresoPerfil(perfil, idSeccion) : fijo;
      return {
        valido: ['all', ['!', falta(m2Serie)], ['>', ingreso, 0]],
        ratio: ['/', conOtros(['*', numero(m2Serie), superficie], idSeccion, nivelCapa), ingreso],
      };
    },
  };
}

// Euros que quedan al mes (tarea 34): el ingreso mensual de la ficha menos el alquiler mensual, con
// los mismos términos que el porcentaje (`calcular()`: la misma vivienda y el mismo año). Es una
// resta, no un umbral de suficiencia. Cada término se redondea al euro, como los escribe la web
// (t.numero sin decimales), y se restan ya redondeados: la resta cuadra con las dos cifras que
// enseña la ficha. Negativa si el alquiler pasa del ingreso; null si falta algún término. No
// depende de la familia: vale también para «entrar», con el alquiler de la oferta. Con los otros
// gastos de vivienda (`otros`, de calcular()), también se restan, redondeados igual.
export function eurosQueQuedan(terminos) {
  const { alquiler, ingreso, otros } = terminos ?? {};
  if (!Number.isFinite(alquiler) || !Number.isFinite(ingreso) || alquiler < 0 || !(ingreso > 0)) return null;
  return Math.round(ingreso) - Math.round(alquiler) - (Number.isFinite(otros) ? Math.round(otros) : 0);
}

// Tramo de «¿te llega?»: 0 hasta el 30 %, 1 del 30 al 40 %, 2 más del 40 %.
export const tramoLlega = (ratio) => (ratio <= LIMITES_LLEGA[0] ? 0 : ratio <= LIMITES_LLEGA[1] ? 1 : 2);

// Intervalo de una cifra con el margen aproximado de la mediana del alquiler (en %, el que
// exporta R; plan §11, pregunta 15 ampliada): cifra × (1 ± margen). Vale para el alquiler, el
// sueldo necesario y la proporción de «¿te llega?», que son el alquiler en otra unidad. Sin
// cifra o sin margen, null.
export function intervaloMargen(valor, margenPct) {
  if (valor === null || valor === undefined || !Number.isFinite(valor)) return null;
  if (margenPct === null || margenPct === undefined || !Number.isFinite(margenPct) || margenPct < 0) return null;
  return { desde: valor * (1 - margenPct / 100), hasta: valor * (1 + margenPct / 100) };
}

// «En el límite entre dos tramos» de «¿te llega?»: el intervalo de la proporción cruza el corte
// del 30 o del 40 %. Los tramos son fijos: no cambian con el umbral elegido.
export function enLimiteLlega(ratio, margenPct) {
  const i = intervaloMargen(ratio, margenPct);
  return i !== null && tramoLlega(i.desde) !== tramoLlega(i.hasta);
}

// Estado de «¿te llega?» (indicador 15): el del alquiler; si falta el ingreso de la ficha, el de
// «ausente» (pregunta 15 ampliada: la calidad del ingreso no rebaja cada cifra).
export const estadoLlega = (estadoAlquiler, ingreso, ausente) => (ingreso === null || ingreso === undefined ? ausente : estadoAlquiler);

// `nivel`: el de la capa que se pinta (en las comunidades, sin ingreso provincial).
export function colorLlega(calculo, idSeccion, colores, nivel = null) {
  const { valido, ratio } = calculo.expresion(idSeccion, nivel);
  return ['case', ['!', valido], colores.fuera,
    ['<=', ratio, LIMITES_LLEGA[0]], colores.llega[0],
    ['<=', ratio, LIMITES_LLEGA[1]], colores.llega[1],
    colores.llega[2]];
}

// Sueldo necesario y demás mapas por tramos: un tramo más que cortes (siete con los juegos de la
// tarea 51), cada uno con su paso de la rampa (colores.js). `nivel`: el de la capa que se pinta,
// que elige su juego de cortes (sin nivel, los `cortes` del mapa). `propios`: otros cortes (la escala
// relativa al municipio, escala_municipio.js). `idSeccion`: la propiedad con el código de cada elemento,
// para sumar los otros gastos de vivienda de su comunidad si están encendidos (supuestos.gastos).
export function colorNecesario(mapaDef, supuestos, colores, nivel = null, propios = null, idSeccion = null) {
  const s = supuestos?.gastos && idSeccion ? { ...supuestos, otros: expresionOtrosGastos(supuestos.gastos, idSeccion, nivel) } : supuestos;
  const valor = formulaDe(mapaDef).expresion(numero(mapaDef.base), s);
  const cortes = propios ?? juegoDe(mapaDef, nivel).cortes;
  const color = pasosDeRampa(cortes.length + 1, colores.rampa.length).map((i) => colores.rampa[i]);
  const pasos = ['step', valor, color[0]];
  cortes.forEach((corte, i) => pasos.push(corte, color[i + 1]));
  return ['case', falta(mapaDef.base), colores.fuera, pasos];
}

// Proporción de secciones con dato donde el alquiler cabe por debajo del umbral.
export function resumenLlega(calculo, secciones, x, umbral) {
  let con = 0;
  let caben = 0;
  for (let i = 0; i < secciones.length; i++) {
    const r = calculo.calcular(secciones[i], (serie) => x(serie, i));
    if (!r) continue;
    con++;
    if (r.ratio <= umbral) caben++;
  }
  return { con, caben, proporcion: con ? caben / con : null };
}

// Tarea 40: la misma proporción con el alquiler mensual mediano real de cada sección (`real` de
// calcular(); las fichas de una persona). Sin esa cifra en ninguna sección (la llave, que ya paga
// el alquiler real), null.
export function resumenLlegaReal(calculo, secciones, x, umbral) {
  if (!calculo.serieReal) return null;
  let con = 0;
  let caben = 0;
  for (let i = 0; i < secciones.length; i++) {
    const r = calculo.calcular(secciones[i], (serie) => x(serie, i));
    if (!r?.real) continue;
    con++;
    if (r.real.ratio <= umbral) caben++;
  }
  return con ? { con, caben, proporcion: caben / con } : null;
}

// Posición (0–1) de un valor en la regla de la leyenda: tramos de igual anchura entre los
// cortes; el primero y el último, tan anchos como su vecino. Fuera de la regla, en su borde.
export function posicionEnRegla(valor, cortes) {
  const tramos = cortes.length + 1;
  const bordes = [2 * cortes[0] - cortes[1], ...cortes, 2 * cortes.at(-1) - cortes.at(-2)];
  if (valor <= bordes[0]) return 0;
  if (valor >= bordes.at(-1)) return 1;
  let k = 0;
  while (valor > bordes[k + 1]) k++;
  return (k + (valor - bordes[k]) / (bordes[k + 1] - bordes[k])) / tramos;
}

// Cuantil p (0–1) de los valores no nulos, con interpolación lineal.
export function cuantil(valores, p) {
  const v = valores.filter((x) => x !== null && Number.isFinite(x)).sort((a, b) => a - b);
  if (!v.length) return null;
  const h = (v.length - 1) * p;
  const i = Math.floor(h);
  return i + 1 < v.length ? v[i] + (h - i) * (v[i + 1] - v[i]) : v[i];
}

// Marcas de la regla del sueldo necesario: las fichas de una persona en su ingreso (con la
// provincia de la sección elegida o, si no hay, la mediana de las provincias) y la llave como
// tramo (del cuartil 1 al 3 de la renta del hogar ÷ 12 en las secciones con dato).
// `cuartiles` (tarea 62): los cuartiles 1 y 3 de la renta del hogar en las secciones, del manifiesto;
// con ellos no hacen falta los valores de las secciones (`rentaHogar`), que mandan si no los hay.
export function marcasRegla({ perfiles, seccion, rentaHogar, cuartiles = null }) {
  const marcas = [];
  for (const ficha of FICHAS_PERFIL) {
    const perfil = perfiles?.[ficha];
    if (!perfil || ficha === 'llave') continue;
    let valor = null;
    let mediana = false;
    if (perfil.nivel === 'provincia') {
      valor = seccion ? ingresoPerfil(perfil, seccion) : null;
      if (valor === null) {
        valor = cuantil(Object.values(perfil.neto_mensual ?? {}), 0.5);
        mediana = valor !== null;
      }
    } else {
      valor = ingresoPerfil(perfil, '00');
    }
    if (valor !== null) marcas.push({ ficha, valor, mediana });
  }
  let llave = null;
  if (perfiles?.llave && cuartiles) {
    const divisor = perfiles.llave.ingreso.divisor ?? 12;
    llave = { desde: cuartiles[0] / divisor, hasta: cuartiles[1] / divisor };
  } else if (perfiles?.llave && rentaHogar) {
    const divisor = perfiles.llave.ingreso.divisor ?? 12;
    const mensual = rentaHogar.map((x) => (x === null ? null : x / divisor));
    const desde = cuantil(mensual, 0.25);
    const hasta = cuantil(mensual, 0.75);
    if (desde !== null) llave = { desde, hasta };
  }
  return { marcas, llave };
}
