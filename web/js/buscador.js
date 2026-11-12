// Buscador de municipio (por nombre o código) o de sección (por código). Lista desplegable con
// teclado: flechas para moverse, Intro para elegir, Escape para cerrar.

import { ordenNatural } from './nombres.js';

const normalizar = (s) => s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().trim();

// Los nombres del INE llevan el artículo detrás («Palmas de Gran Canaria, Las»): se busca
// también en orden natural («Las Palmas de Gran Canaria»).
export function formasDeNombre(nombre) {
  const natural = ordenNatural(nombre);
  return natural === nombre ? [normalizar(nombre)] : [normalizar(nombre), normalizar(natural)];
}

// Opciones para un texto: municipios cuyo nombre contiene el texto (primero los que empiezan
// por él) o cuyo código empieza por él; secciones cuyo código empieza por él (desde 5 cifras).
export function buscar(texto, { municipios, secciones, limite = 8 }) {
  const q = normalizar(texto);
  if (q.length < 2) return [];
  const resultado = [];
  if (/^\d+$/.test(q)) {
    for (const [codigo, nombre] of municipios) if (codigo.startsWith(q)) resultado.push({ tipo: 'municipio', codigo, nombre });
    if (q.length >= 5) for (const codigo of secciones) if (codigo.startsWith(q)) resultado.push({ tipo: 'seccion', codigo });
    return resultado.slice(0, limite);
  }
  const empiezan = [];
  const contienen = [];
  for (const [codigo, nombre, formas] of municipios) {
    if (formas.some((f) => f.startsWith(q))) empiezan.push({ tipo: 'municipio', codigo, nombre });
    else if (formas.some((f) => f.includes(q))) contienen.push({ tipo: 'municipio', codigo, nombre });
  }
  return [...empiezan, ...contienen].slice(0, limite);
}

// `sinResultados`: función que da el texto de «sin resultados» en el idioma activo (dice por qué se
// puede buscar: municipio o código de sección, no calle ni barrio); sin ella, no hay aviso.
export function crearBuscador({ entrada, lista, obtenerFuentes, etiqueta, alElegir, sinResultados = null }) {
  let opciones = [];
  let activa = -1;

  // La lista toma el nombre de la etiqueta del campo (un listbox sin nombre no dice qué es)
  const rotulo = entrada.id ? document.querySelector(`label[for="${entrada.id}"]`) : null;
  if (rotulo && !lista.hasAttribute('aria-labelledby')) {
    rotulo.id ||= `${entrada.id}-rotulo`;
    lista.setAttribute('aria-labelledby', rotulo.id);
  }
  // Aviso de «sin resultados»: una región viva bajo el campo, en el sitio de la lista
  const vacio = document.createElement('p');
  vacio.className = 'buscador-vacio';
  vacio.setAttribute('role', 'status');
  vacio.hidden = true;
  lista.after(vacio);

  const cerrar = () => {
    lista.hidden = true;
    vacio.hidden = true;
    entrada.setAttribute('aria-expanded', 'false');
    entrada.removeAttribute('aria-activedescendant');
    activa = -1;
  };
  const marcar = (i) => {
    activa = i;
    [...lista.children].forEach((li, k) => li.setAttribute('aria-selected', String(k === i)));
    if (i >= 0) entrada.setAttribute('aria-activedescendant', lista.children[i].id);
  };
  const elegir = (i) => {
    const opcion = opciones[i];
    if (!opcion) return;
    entrada.value = etiqueta(opcion);
    cerrar();
    alElegir(opcion);
  };

  entrada.addEventListener('input', async () => {
    const fuentes = await obtenerFuentes();
    opciones = buscar(entrada.value, fuentes);
    lista.replaceChildren(...opciones.map((opcion, i) => {
      const li = document.createElement('li');
      li.id = `buscador-opcion-${i}`;
      li.setAttribute('role', 'option');
      li.textContent = etiqueta(opcion);
      li.addEventListener('mousedown', (e) => { e.preventDefault(); elegir(i); });
      return li;
    }));
    lista.hidden = !opciones.length;
    entrada.setAttribute('aria-expanded', String(opciones.length > 0));
    marcar(opciones.length ? 0 : -1);
    const sinNada = Boolean(sinResultados) && !opciones.length && entrada.value.trim().length >= 2;
    vacio.textContent = sinNada ? sinResultados() : '';
    vacio.hidden = !sinNada;
  });
  entrada.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown' && opciones.length) { e.preventDefault(); marcar((activa + 1) % opciones.length); }
    else if (e.key === 'ArrowUp' && opciones.length) { e.preventDefault(); marcar((activa - 1 + opciones.length) % opciones.length); }
    else if (e.key === 'Enter' && activa >= 0) { e.preventDefault(); elegir(activa); }
    else if (e.key === 'Escape') cerrar();
  });
  entrada.addEventListener('blur', () => setTimeout(cerrar, 150));
}
