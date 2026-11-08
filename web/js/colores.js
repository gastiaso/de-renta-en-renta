// Colores de los mapas a partir de la rampa de tokens.css (diseno/tokens.json): qué paso de la
// rampa lleva cada tramo y de qué color va el contorno de las secciones. Sin DOM, salvo
// `rampaDeCss()`, para que las pruebas usen las mismas cuentas.
//
// La rampa tiene un paso por tramo del mapa más detallado (seis: pregunta abierta 20 del plan).
// Un mapa con menos tramos toma pasos repartidos de punta a punta, y «¿te llega?», con tres
// tramos, el primero, el del medio y el último.

export const TRAMOS_LLEGA = 3;

// Índices (desde 0) de los pasos de una rampa de `pasos` colores para un mapa de `tramos` tramos.
export function pasosDeRampa(tramos, pasos) {
  if (!(tramos >= 1) || tramos > pasos) throw new Error(`La rampa tiene ${pasos} pasos y el mapa pide ${tramos} tramos`);
  if (tramos === 1) return [0];
  return Array.from({ length: tramos }, (_, i) => Math.round((i * (pasos - 1)) / (tramos - 1)));
}

// Clases .tramo-N de tokens.css de cada tramo de un mapa (N desde 1, como los pasos de la rampa).
export const clasesTramos = (tramos, pasos) => pasosDeRampa(tramos, pasos).map((i) => `tramo-${i + 1}`);

// Decimales de las etiquetas de los cortes (leyenda e imagen): los que necesiten los cortes, sin
// pasar de los del mapa y, si el mapa lleva decimales, al menos uno. Con dos decimales (las
// viviendas turísticas, pregunta abierta 24), «0,5 · 1,0 · 2,5 · 5,0», no «0,50 · 1,00…».
export function decimalesDeCortes(cortes, decimales = 0) {
  const necesarios = Math.max(0, ...cortes.map((c) => (String(c).split('.')[1] ?? '').length));
  return Math.min(decimales, Math.max(Math.min(decimales, 1), necesarios));
}

// Contraste WCAG 2 entre dos colores «#rrggbb» (como contraste_wcag() en R/web_estilo.R).
function luminancia(hex) {
  const n = parseInt(hex.trim().slice(1), 16);
  return [n >> 16, (n >> 8) & 255, n & 255]
    .map((c) => c / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4))
    .reduce((suma, c, i) => suma + c * [0.2126, 0.7152, 0.0722][i], 0);
}

export function contraste(a, b) {
  const [claro, oscuro] = [luminancia(a), luminancia(b)].sort((x, y) => y - x);
  return (claro + 0.05) / (oscuro + 0.05);
}

// Contorno de sección sobre un paso: tinta mientras contraste con ella al menos 3:1 (mínimo WCAG de
// los elementos gráficos); en los pasos más oscuros, placa.
export const contornoDe = (color, tinta, placa) => (contraste(color, tinta) >= 3 ? tinta : placa);

// Colores del mapa: la rampa entera, los tres pasos de «¿te llega?» y el color de fuera del ámbito.
export function paletaDe(rampa, fuera) {
  return { rampa, llega: pasosDeRampa(TRAMOS_LLEGA, rampa.length).map((i) => rampa[i]), fuera };
}

// La misma paleta con el color del contorno de cada paso; fuera del ámbito, tinta.
export function paletaContorno(paleta, tinta, placa) {
  const de = (color) => contornoDe(color, tinta, placa);
  return { rampa: paleta.rampa.map(de), llega: paleta.llega.map(de), fuera: tinta };
}

// Pasos de la rampa en tokens.css (--rampa-1, --rampa-2…), en el navegador.
export function rampaDeCss() {
  const estilo = getComputedStyle(document.documentElement);
  const rampa = [];
  for (let i = 1; ; i++) {
    const color = estilo.getPropertyValue(`--rampa-${i}`).trim();
    if (!color) return rampa;
    rampa.push(color);
  }
}
