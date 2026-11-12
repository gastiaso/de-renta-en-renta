// Pantallas estrechas (backlog, tarea 50). Por debajo de ANCHO_MOVIL (el mismo corte que
// estilo/sitio.css) el mapa va arriba y la columna lateral debajo, con la ficha antes que «Tu
// sueldo». Aquí:
//   - los controles de la barra de la vista que no son el mapa ni el año, plegables con un botón
//     (aria-expanded), plegados al entrar;
//   - al tocar un territorio en el mapa, la página baja hasta su ficha si no está a la vista, para
//     que se lea sin desplazarse a mano.
// En escritorio no hace nada: el botón no se ve y la ficha ya está al lado del mapa.

export const ANCHO_MOVIL = 760;

export const esPantallaEstrecha = (ventana = globalThis) =>
  Boolean(ventana.matchMedia?.(`(max-width: ${ANCHO_MOVIL}px)`).matches);

// ¿Hay que bajar hasta la ficha? Sí si su borde de arriba queda por encima de la ventana o por debajo
// de `fraccion` de su alto (no se vería más que una tira). `rect`: getBoundingClientRect() de la ficha.
export function hayQueDesplazar(rect, alto, fraccion = 0.5) {
  if (!rect || !(alto > 0)) return false;
  return rect.top < 0 || rect.top > alto * fraccion;
}

// Posición de desplazamiento que deja la ficha arriba, con un respiro de `respiro` px.
export const destinoDesplazamiento = (rect, scrollY, respiro = 8) => Math.max(0, Math.round(scrollY + rect.top - respiro));

// Baja hasta la ficha en pantallas estrechas, después de pintarla. Respeta «reducir movimiento».
export function mostrarFicha(ficha, ventana = globalThis) {
  if (!ficha || !esPantallaEstrecha(ventana)) return;
  ventana.requestAnimationFrame(() => {
    const rect = ficha.getBoundingClientRect();
    if (!hayQueDesplazar(rect, ventana.innerHeight)) return;
    const suave = !ventana.matchMedia('(prefers-reduced-motion: reduce)').matches;
    ventana.scrollTo({ top: destinoDesplazamiento(rect, ventana.scrollY), behavior: suave ? 'smooth' : 'auto' });
  });
}

// Recorrido guiado en pantallas estrechas: el mapa queda fijo arriba y el texto del paso justo debajo
// (sitio.css, body.con-historia), a la vista los dos. Al abrir un paso, la página se coloca con el
// mapa arriba del todo; la barra de la vista, que va antes, queda fuera por arriba. `barra`: el
// elemento que precede al mapa. Posición de destino, aparte, para las pruebas.
export const destinoHistoria = (rectBarra, scrollY, respiro = 6) => Math.max(0, Math.round(scrollY + rectBarra.bottom + respiro));

export function mostrarHistoria(barra, ventana = globalThis) {
  if (!barra || !esPantallaEstrecha(ventana)) return;
  ventana.requestAnimationFrame(() => {
    const destino = destinoHistoria(barra.getBoundingClientRect(), ventana.scrollY);
    if (Math.abs(destino - ventana.scrollY) < 4) return;
    const suave = !ventana.matchMedia('(prefers-reduced-motion: reduce)').matches;
    ventana.scrollTo({ top: destino, behavior: suave ? 'smooth' : 'auto' });
  });
}

// Botón que pliega y despliega los controles secundarios de la barra (data-plegada en la barra).
export function prepararPlegado(barra, boton, t) {
  if (!barra || !boton) return { traducir() {} };
  const rotular = () => {
    const plegada = barra.dataset.plegada === 'true';
    boton.setAttribute('aria-expanded', String(!plegada));
    if (t) boton.textContent = t(plegada ? 'interfaz.vista.mas_opciones' : 'interfaz.vista.menos_opciones');
  };
  boton.addEventListener('click', () => {
    barra.dataset.plegada = barra.dataset.plegada === 'true' ? 'false' : 'true';
    rotular();
  });
  rotular();
  return {
    traducir(nuevo) {
      t = nuevo;
      rotular();
    },
  };
}
