// Buscador de municipio (por nombre o por código postal) o de sección (por su código de diez
// cifras). Lista desplegable con teclado: flechas para moverse, Intro para elegir, Escape para cerrar.
//
// Decisión del autor (12-nov-2026): nadie busca por código INE. Un texto de cifras es un código
// postal (cinco cifras: sus municipios; menos de cinco: los códigos postales que empiezan así) y,
// desde seis cifras, el principio de un código de sección (lo usan los enlaces y la ficha). Ya no se
// busca un municipio por su código INE. La tabla código postal → municipios (ordenados por su peso
// en tramos de vía del callejero de 2021) es datos/cp.json (`codigos_postales` del manifiesto), que
// la página pide solo cuando se escriben cifras (`hayCifras`).

import { ordenNatural } from './nombres.js';

const normalizar = (s) => s.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase().trim();

// ¿Pide el texto la tabla de códigos postales? (solo cifras)
export const hayCifras = (texto) => /^\d+$/.test(normalizar(String(texto ?? '')));
const CIFRAS_CP = 5;

// Etiqueta de un municipio en la lista: «28013 · Madrid» si sale de un código postal; si no, su
// nombre en orden natural con la provincia entre paréntesis, que distingue los homónimos («Mieres
// (Asturias)», «Mieres (Girona)»). Sin el código INE: nadie busca por él y, con cinco cifras, se
// confunde con un código postal. `provincias`: nombres por código de provincia (territorios.json);
// si la provincia se llama igual que el municipio, o no se conoce, solo el nombre.
export function etiquetaMunicipio(o, provincias = null) {
  const nombre = ordenNatural(o.nombre);
  if (o.cp) return `${o.cp} · ${nombre}`;
  const provincia = provincias?.[String(o.codigo).slice(0, 2)];
  const natural = provincia ? ordenNatural(provincia) : null;
  return natural && natural !== nombre ? `${nombre} (${natural})` : nombre;
}

// Nombres de los municipios por código, una vez por lista de municipios.
const nombresPorLista = new WeakMap();
function nombreDe(municipios, codigo) {
  if (!nombresPorLista.has(municipios)) nombresPorLista.set(municipios, new Map(municipios.map(([c, n]) => [c, n])));
  return nombresPorLista.get(municipios).get(codigo);
}

// Opciones de un código postal (o del principio de uno): una por municipio de cada código postal
// que empieza por las cifras, en orden de código postal y, dentro de él, de peso. Un municipio que
// no está en la lista de nombres se salta.
function buscarCodigoPostal(q, { municipios, codigosPostales }, limite) {
  const resultado = [];
  if (!codigosPostales || q.length > CIFRAS_CP) return resultado;
  const claves = q.length === CIFRAS_CP ? (q in codigosPostales ? [q] : [])
    : Object.keys(codigosPostales).filter((cp) => cp.startsWith(q)).sort();
  for (const cp of claves) {
    for (const codigo of codigosPostales[cp] ?? []) {
      const nombre = nombreDe(municipios, codigo);
      if (nombre !== undefined) resultado.push({ tipo: 'municipio', codigo, nombre, cp });
      if (resultado.length >= limite) return resultado;
    }
  }
  return resultado;
}

// Los nombres del INE llevan el artículo detrás («Palmas de Gran Canaria, Las»): se busca
// también en orden natural («Las Palmas de Gran Canaria»).
export function formasDeNombre(nombre) {
  const natural = ordenNatural(nombre);
  return natural === nombre ? [normalizar(nombre)] : [normalizar(nombre), normalizar(natural)];
}

// Opciones para un texto: municipios cuyo nombre contiene el texto (primero los que empiezan
// por él); con cifras, los municipios de los códigos postales que empiezan por ellas (hasta cinco
// cifras; `codigosPostales`: { cp: [municipio, …] }, o nada) y, desde seis, las secciones cuyo
// código empieza por ellas.
export function buscar(texto, { municipios, secciones, codigosPostales = null, limite = 8 }) {
  const q = normalizar(texto);
  if (q.length < 2) return [];
  if (/^\d+$/.test(q)) {
    if (q.length <= CIFRAS_CP) return buscarCodigoPostal(q, { municipios, codigosPostales }, limite);
    const resultado = [];
    for (const codigo of secciones ?? []) {
      if (codigo.startsWith(q)) resultado.push({ tipo: 'seccion', codigo });
      if (resultado.length >= limite) break;
    }
    return resultado;
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
// puede buscar: municipio o código postal, no calle ni barrio); sin ella, no hay aviso.
// `obtenerFuentes(texto)`: las fuentes de buscar() para ese texto (con cifras, también los códigos
// postales; hayCifras()).
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
    const texto = entrada.value;
    const fuentes = await obtenerFuentes(texto);
    if (texto !== entrada.value) return;   // ya se ha escrito otra cosa: manda la búsqueda nueva
    opciones = buscar(texto, fuentes);
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
