// Estado de la vista en la URL, para que cada vista se pueda enlazar:
//   ?idioma=es&mapa=sueldo_necesario&anio=2024&seccion=2807901001&vista=14.50/40.41680/-3.70380
// (vista = zoom/latitud/longitud). Solo entran estas claves, validadas al leer y al escribir.
//
// El sueldo que se escribe en «Tu sueldo» NO entra nunca aquí: viaja en el enlace solo si la
// persona pulsa «Compartir», con aviso previo (plan, §6.6).

const VALIDAS = {
  idioma: (v) => v === 'es' || v === 'en',
  mapa: (v) => /^[a-z0-9_]{1,40}$/.test(v),
  anio: (v) => /^(19|20)\d{2}$/.test(v),
  seccion: (v) => /^\d{10}$/.test(v),
  vista: (v) => /^\d{1,2}(\.\d+)?\/-?\d{1,2}(\.\d+)?\/-?\d{1,3}(\.\d+)?$/.test(v),
};
const CLAVES = Object.keys(VALIDAS);

export function leerEstado() {
  const parametros = new URLSearchParams(location.search);
  const estado = {};
  for (const clave of CLAVES) {
    const valor = parametros.get(clave);
    if (valor !== null && VALIDAS[clave](valor)) estado[clave] = valor;
  }
  if (estado.anio) estado.anio = Number(estado.anio);
  return estado;
}

let espera = null;

// Escribe el estado en la URL sin recargar ni crear entradas en el historial. Agrupa los cambios
// seguidos (por ejemplo, al arrastrar el mapa) en una sola escritura.
export function guardarEstado(estado) {
  clearTimeout(espera);
  espera = setTimeout(() => {
    const partes = [];
    for (const clave of CLAVES) {
      const valor = estado[clave];
      if (valor === undefined || valor === null || valor === '') continue;
      if (VALIDAS[clave](String(valor))) partes.push(`${clave}=${valor}`);
    }
    const consulta = partes.length ? `?${partes.join('&')}` : '';
    if (consulta !== location.search) history.replaceState(null, '', `${location.pathname}${consulta}${location.hash}`);
  }, 250);
}

export function vistaATexto(mapa) {
  const centro = mapa.getCenter();
  return `${mapa.getZoom().toFixed(2)}/${centro.lat.toFixed(5)}/${centro.lng.toFixed(5)}`;
}

export function textoAVista(texto) {
  const [zoom, lat, lon] = texto.split('/').map(Number);
  return { zoom, center: [lon, lat] };
}
