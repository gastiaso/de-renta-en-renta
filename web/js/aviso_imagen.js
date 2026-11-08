// Aviso antes de descargar la imagen de «¿te llega?» con «Tu ficha» (pregunta abierta 23 del
// plan): la imagen no lleva la cifra del sueldo, pero sus colores dejan deducirla de forma
// aproximada (dónde el alquiler pasa del 30 y del 40 % del ingreso). Como con «Compartir», se
// avisa antes y se deja elegir. Con las fichas fijas no hace falta: su ingreso es público.

const $ = (id) => document.getElementById(id);

export function crearAvisoImagen() {
  const dialogo = $('aviso-imagen');
  const texto = $('aviso-imagen-texto');
  const si = $('aviso-imagen-si');
  const no = $('aviso-imagen-no');
  let responder = null;

  // Responde una sola vez: el botón elegido, o «no» al cerrar con Escape.
  function cerrar(valor) {
    const r = responder;
    responder = null;
    if (dialogo.open) dialogo.close();
    if (r) r(valor);
  }
  si.addEventListener('click', () => cerrar(true));
  no.addEventListener('click', () => cerrar(false));
  dialogo.addEventListener('close', () => cerrar(false));

  return {
    // Promesa: true si se descarga, false si no. `sueldo`: el ingreso mensual escrito.
    pedir({ t, sueldo }) {
      if (responder) cerrar(false);
      texto.textContent = t('interfaz.exportar.aviso_tu_ficha', { sueldo: t.numero(sueldo) });
      const respuesta = new Promise((resolve) => { responder = resolve; });
      dialogo.showModal();
      no.focus();
      return respuesta;
    },
  };
}
