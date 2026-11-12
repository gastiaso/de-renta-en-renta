// Panel del recorrido guiado en mapa.html (backlog, tarea 49): título de la historia, «Paso n de N»,
// título, texto, fuente y enlace del paso, el desplegable «Cómo se mide» (la nota del paso, si la
// trae), selector de historia y botones Anterior, Siguiente y Salir. La lógica (qué paso, qué cambia en el mapa) está en historias.js y principal.js; aquí solo
// el DOM. Accesible: el paso es una región aria-live; las flechas izquierda y derecha, con el foco en
// el panel (no en el selector), van al paso anterior y al siguiente; si el botón pulsado deja de
// valer (primer o último paso), el foco pasa al texto del paso.

import { textoEn, enlaceEnIdioma } from './historias.js';

const $ = (id) => document.getElementById(id);

export function crearPanelHistoria({ alAnterior, alSiguiente, alSalir, alElegir }) {
  const el = {
    panel: $('historia'),
    titulo: $('historia-titulo'),
    elegir: $('historia-elegir'),
    paso: $('historia-paso'),
    entradilla: $('historia-entradilla'),
    contador: $('historia-contador'),
    pasoTitulo: $('historia-paso-titulo'),
    texto: $('historia-texto'),
    fuente: $('historia-fuente'),
    enlace: $('historia-enlace'),
    nota: $('historia-nota'),
    notaTexto: $('historia-nota-texto'),
    anterior: $('historia-anterior'),
    siguiente: $('historia-siguiente'),
    salir: $('historia-salir'),
  };
  if (!el.panel) return { pintar() {}, ocultar() {} };

  // Tras pulsar un botón que queda desactivado, el foco va al texto del paso (no se pierde).
  const conFoco = (boton, accion) => () => {
    accion();
    if (boton.disabled) el.paso.focus();
  };
  el.anterior.addEventListener('click', conFoco(el.anterior, alAnterior));
  el.siguiente.addEventListener('click', conFoco(el.siguiente, alSiguiente));
  el.salir.addEventListener('click', alSalir);
  el.elegir.addEventListener('change', () => alElegir(el.elegir.value));
  el.panel.addEventListener('keydown', (e) => {
    if (e.target === el.elegir || e.altKey || e.ctrlKey || e.metaKey) return;
    if (e.key === 'ArrowLeft' && !el.anterior.disabled) { e.preventDefault(); alAnterior(); }
    else if (e.key === 'ArrowRight' && !el.siguiente.disabled) { e.preventDefault(); alSiguiente(); }
    else return;
    // Como con el clic: si el botón que tenía el foco deja de valer (primer o último paso), no se pierde
    if (document.activeElement?.disabled) el.paso.focus();
  });

  return {
    // `historias`: la lista del fichero; `historia` y `n`: la activa y su paso (de 1 a N).
    pintar({ t, historias, historia, n }) {
      const idioma = t.idioma;
      const total = historia.pasos.length;
      const paso = historia.pasos[n - 1];
      el.titulo.textContent = textoEn(historia.titulo, idioma);
      el.elegir.replaceChildren(...historias.map((h) => {
        const opcion = new Option(textoEn(h.titulo, idioma), h.id);
        opcion.selected = h.id === historia.id;
        return opcion;
      }));
      el.elegir.closest('.historia-elegir').hidden = historias.length < 2;
      const entradilla = n === 1 ? textoEn(historia.entradilla, idioma) : '';
      el.entradilla.textContent = entradilla;
      el.entradilla.hidden = !entradilla;
      el.contador.textContent = t('interfaz.historia.contador', { n: t.numero(n), total: t.numero(total) });
      el.pasoTitulo.textContent = textoEn(paso.titulo, idioma);
      el.texto.textContent = textoEn(paso.texto, idioma);
      el.fuente.textContent = t('interfaz.historia.fuente', { fuente: textoEn(paso.fuente, idioma) });
      const enlace = paso.enlace;
      el.enlace.hidden = !enlace;
      if (enlace) {
        const a = el.enlace.querySelector('a');
        a.href = enlaceEnIdioma(enlace.href, idioma);
        a.textContent = textoEn(enlace.texto, idioma);
      }
      // La nota, plegada en cada paso: quien la quiera la abre; sin nota, no hay desplegable
      const nota = textoEn(paso.nota, idioma);
      if (el.nota) {
        el.nota.hidden = !nota;
        el.nota.open = false;
        el.notaTexto.textContent = nota;
      }
      el.anterior.disabled = n <= 1;
      el.siguiente.disabled = n >= total;
      el.panel.hidden = false;
    },
    ocultar() {
      el.panel.hidden = true;
    },
  };
}
