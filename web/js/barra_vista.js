// Barra de la vista, encima del mapa: qué mapa, qué año (o periodo, «noviembre de 2024»), qué
// tipología de vivienda y las descargas. El marcado está en index.html; aquí se rellenan las
// opciones y se conectan los controles.
//
// Mapa y año son <select> nativos: se manejan con el teclado y, en el móvil, con el selector del
// sistema, sin código propio. La tipología son dos botones con aria-pressed, como los de «Tu
// sueldo», y solo se ve si la serie del mapa tiene variante (decisión 12: colectiva por defecto,
// sin mezclar las dos).

const $ = (id) => document.getElementById(id);

// Rellena un <select> solo si cambian sus opciones (rehacerlas con el foco dentro lo descoloca).
function rellenar(select, opciones, valor) {
  const clave = JSON.stringify(opciones);
  if (select.dataset.opciones !== clave) {
    select.replaceChildren(...opciones.map(({ valor: v, texto }) => {
      const opcion = document.createElement('option');
      opcion.value = v;
      opcion.textContent = texto;
      return opcion;
    }));
    select.dataset.opciones = clave;
  }
  select.value = valor;
  select.disabled = opciones.length < 2;
}

export function crearBarraVista({ alCambiar, alExportar }) {
  const el = {
    mapa: $('vista-mapa'),
    anio: $('vista-anio'),
    tipologia: $('vista-tipologia'),
    csv: $('exportar-csv'),
    png: $('exportar-png'),
    estado: $('exportar-estado'),
  };
  el.mapa.addEventListener('change', () => alCambiar({ mapa: el.mapa.value }));
  el.anio.addEventListener('change', () => alCambiar({ anio: el.anio.value }));
  el.tipologia.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-tipologia]');
    if (boton && boton.getAttribute('aria-pressed') !== 'true') alCambiar({ tipologia: boton.dataset.tipologia });
  });
  el.csv.addEventListener('click', () => alExportar('csv'));
  el.png.addEventListener('click', () => alExportar('png'));

  return {
    // mapas y periodos: [{ valor, texto }]; tipologia: 'VC' | 'VU' | null (la serie no tiene).
    pintar({ mapas, mapa, periodos, periodo, tipologia }) {
      rellenar(el.mapa, mapas, mapa);
      rellenar(el.anio, periodos, periodo);
      el.tipologia.hidden = !tipologia;
      for (const b of el.tipologia.querySelectorAll('button[data-tipologia]')) {
        b.setAttribute('aria-pressed', String(b.dataset.tipologia === tipologia));
      }
    },
    // Botón de descarga ocupado mientras se prepara el fichero.
    ocupado(formato, si) {
      const boton = formato === 'csv' ? el.csv : el.png;
      boton.disabled = si;
      boton.setAttribute('aria-busy', String(si));
    },
    // Aviso para lectores de pantalla (y, si hay error, también a la vista).
    avisar(texto, error = false) {
      el.estado.textContent = texto;
      el.estado.classList.toggle('oculto', !error);
    },
  };
}
