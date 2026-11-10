// Estado de la vista en la URL, para que cada vista se pueda enlazar:
//   ?idioma=es&mapa=sueldo_necesario&anio=2024&tipologia=VU&ficha=mochila&superficie=70&umbral=40
//    &seccion=2807901001&comparar=municipio&vista=14.50/40.41680/-3.70380
//    &territorio=municipio:28079
// (anio = año o periodo de la serie del mapa, «2025-05»; sin él, el último; tipologia = VU para la
// vivienda unifamiliar, sin ella la colectiva; vista = zoom/latitud/longitud; comparar = nivel o
// código de otra sección; territorio = municipio, provincia o comunidad elegidos con un clic en
// esas escalas, en lugar de una sección: tarea 26). Solo entran estas claves, validadas al leer y
// al escribir. El mapa está en mapa.html; la raíz (la portada) manda a mapa.html los enlaces que
// traen alguna de estas claves salvo el idioma (js/redireccion.js).
//
// El sueldo de «Tu sueldo» NO entra en la consulta: viaja en el enlace solo si la persona pulsa
// «Compartir», con aviso previo (plan, §6.6), y entonces va tras «#», que el navegador no envía
// al servidor. Al abrir un enlace así, se lee y se quita de la barra de direcciones.

const FICHAS = ['llave', 'mochila', 'tartera', 'transistor', 'peon'];
const NIVELES_COMPARAR = ['distrito', 'municipio', 'provincia', 'ccaa', 'nacional'];

const VALIDAS = {
  idioma: (v) => v === 'es' || v === 'en',
  mapa: (v) => /^[a-z0-9_]{1,40}$/.test(v),
  anio: (v) => /^(19|20)\d{2}(-(0[1-9]|1[0-2]))?$/.test(v),
  tipologia: (v) => v === 'VC' || v === 'VU',
  ficha: (v) => FICHAS.includes(v),
  superficie: (v) => ['50', '70', '90'].includes(v),
  umbral: (v) => v === '30' || v === '40',
  seccion: (v) => /^\d{10}$/.test(v),
  comparar: (v) => /^\d{10}$/.test(v) || NIVELES_COMPARAR.includes(v),
  vista: (v) => /^\d{1,2}(\.\d+)?\/-?\d{1,2}(\.\d+)?\/-?\d{1,3}(\.\d+)?$/.test(v),
  territorio: (v) => /^(?:(?:ccaa|provincia):\d{2}|municipio:\d{5})$/.test(v),
};
export const CLAVES = Object.keys(VALIDAS);
const NUMERICAS = ['anio', 'superficie', 'umbral'];
// Número si lo es («2024» → 2024); los periodos con mes («2025-05») quedan como texto.
const leerValor = (clave, valor) => (NUMERICAS.includes(clave) && /^\d+$/.test(valor) ? Number(valor) : valor);

export function leerEstado(busqueda = location.search) {
  const parametros = new URLSearchParams(busqueda);
  const estado = {};
  for (const clave of CLAVES) {
    const valor = parametros.get(clave);
    if (valor !== null && VALIDAS[clave](valor)) estado[clave] = leerValor(clave, valor);
  }
  return estado;
}

export function consulta(estado) {
  const partes = [];
  for (const clave of CLAVES) {
    const valor = estado[clave];
    if (valor === undefined || valor === null || valor === '') continue;
    if (VALIDAS[clave](String(valor))) partes.push(`${clave}=${valor}`);
  }
  return partes.length ? `?${partes.join('&')}` : '';
}

let espera = null;

// Escribe el estado en la URL sin recargar ni crear entradas en el historial. Agrupa los cambios
// seguidos (por ejemplo, al arrastrar el mapa) en una sola escritura.
export function guardarEstado(estado) {
  clearTimeout(espera);
  espera = setTimeout(() => {
    const nueva = consulta(estado);
    if (nueva !== location.search) history.replaceState(null, '', `${location.pathname}${nueva}${location.hash}`);
  }, 250);
}

// Territorio de la clave `territorio` («municipio:28079» → { nivel: 'municipio', codigo: '28079' }), o null.
export function leerTerritorio(texto) {
  if (!texto || !VALIDAS.territorio(String(texto))) return null;
  const [nivel, codigo] = String(texto).split(':');
  return { nivel, codigo };
}
export const territorioATexto = (nivel, codigo) => `${nivel}:${codigo}`;

// Sueldo de un enlace compartido (#sueldo=1500&pagas=14&segundo=900), o null. Un fragmento sin
// sueldo es un ancla (#tu-sueldo, desde la portada y el menú) y se deja: el navegador baja hasta ella.
export function leerSueldoCompartido() {
  if (!location.hash) return null;
  const p = new URLSearchParams(location.hash.slice(1));
  if (!p.has('sueldo')) return null;
  const numero = (clave) => {
    const x = Number(p.get(clave));
    return Number.isFinite(x) && x > 0 && x <= 100000 ? x : null;
  };
  const neto = numero('sueldo');
  history.replaceState(null, '', `${location.pathname}${location.search}`);
  if (!neto) return null;
  return { neto, pagas: p.get('pagas') === '14' ? 14 : 12, segundo: numero('segundo') };
}

// Fragmento con el sueldo (#sueldo=1500&pagas=14&segundo=900), o '' sin sueldo. El de «Compartir»
// y el del botón «¿Te llega?» de la portada.
export function fragmentoSueldo(sueldo) {
  if (!sueldo?.neto) return '';
  const partes = [`sueldo=${Math.round(sueldo.neto)}`];
  if (sueldo.pagas === 14) partes.push('pagas=14');
  if (sueldo.segundo > 0) partes.push(`segundo=${Math.round(sueldo.segundo)}`);
  return `#${partes.join('&')}`;
}

// Enlace a la vista; con `sueldo`, también el sueldo (tras «#»).
export function enlaceVista(estado, sueldo = null) {
  return `${location.origin}${location.pathname}${consulta(estado)}${fragmentoSueldo(sueldo)}`;
}

export function vistaATexto(mapa) {
  const centro = mapa.getCenter();
  return `${mapa.getZoom().toFixed(2)}/${centro.lat.toFixed(5)}/${centro.lng.toFixed(5)}`;
}

export function textoAVista(texto) {
  const [zoom, lat, lon] = texto.split('/').map(Number);
  return { zoom, center: [lon, lat] };
}
