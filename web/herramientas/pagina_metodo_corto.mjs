// Monta el Markdown de «Método en dos páginas» (metodo_corto.html y short_method.html; backlog,
// tarea 53), que el flujo de Pages convierte después con pandoc y plantilla_documento.html, como
// «Método» y «Datos» (docs/publicacion.md).
//
// Parte del texto a mano (docs/metodo_corto.md o docs/short_method.md) y rellena su marca
// <!-- erratas --> con la fe de erratas de inventario/erratas.csv: una tabla con la fecha, la
// versión afectada, dónde estaba el error, cuál era y cómo se corrigió, de la más reciente a la
// más antigua; sin filas, una línea que lo dice y remite al registro de cambios.
//
// Uso, desde la raíz del proyecto (Node 18 o posterior, sin paquetes):
//   node web/herramientas/pagina_metodo_corto.mjs --idioma es --nota docs/metodo_corto.md \
//     --erratas inventario/erratas.csv [--repositorio cuenta/nombre] --salida metodo_corto_es.md
// La salida se escribe en UTF-8 con --salida: en PowerShell, «>» la pasaría a UTF-16.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const MARCA_ERRATAS = '<!-- erratas -->';
export const COLUMNAS_ERRATAS = ['fecha', 'version', 'donde_es', 'donde_en', 'error_es', 'error_en', 'correccion_es', 'correccion_en'];
const REPOSITORIO = 'gastiaso/de-renta-en-renta';

export const TEXTOS = {
  es: {
    cabecera: ['Fecha', 'Versión', 'Dónde', 'Error', 'Corrección'],
    vacia: (cambios) => `No hay erratas anotadas. Los cambios de método de cada versión, que no son erratas, están en el [registro de cambios](${cambios}).`,
    intro: (n, cambios) => `${n === 1 ? 'Una corrección' : `${n} correcciones`} de cifras o textos ya publicados, de la más reciente a la más antigua (\`inventario/erratas.csv\`). Los cambios de método de cada versión están en el [registro de cambios](${cambios}).`,
    fecha: (d, m, a) => `${d} de ${['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][m - 1]} de ${a}`,
  },
  en: {
    cabecera: ['Date', 'Version', 'Where', 'Error', 'Correction'],
    vacia: (cambios) => `No errata recorded. Method changes in each version, which are not errata, are in the [changelog](${cambios}).`,
    intro: (n, cambios) => `${n === 1 ? 'One correction' : `${n} corrections`} of figures or texts already published, most recent first (\`inventario/erratas.csv\`). Method changes in each version are in the [changelog](${cambios}).`,
    fecha: (d, m, a) => `${d} ${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m - 1]} ${a}`,
  },
};

// CSV (RFC 4180: comas, comillas dobles y saltos de línea dentro de las comillas) → filas de texto.
export function leerCsv(texto) {
  const filas = [];
  let fila = [];
  let campo = '';
  let comillas = false;
  const s = String(texto ?? '').replace(/^﻿/, '');
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (comillas) {
      if (c === '"' && s[i + 1] === '"') { campo += '"'; i++; } else if (c === '"') comillas = false;
      else campo += c;
    } else if (c === '"') comillas = true;
    else if (c === ',') { fila.push(campo); campo = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && s[i + 1] === '\n') i++;
      fila.push(campo); filas.push(fila); fila = []; campo = '';
    } else campo += c;
  }
  if (comillas) throw new Error('CSV: comillas sin cerrar');
  if (campo !== '' || fila.length) { fila.push(campo); filas.push(fila); }
  return filas.filter((f) => !(f.length === 1 && f[0] === ''));
}

// Filas de la fe de erratas como objetos, comprobadas: las columnas de COLUMNAS_ERRATAS en su
// orden, fecha AAAA-MM-DD válida, versión «0.4.0» y todos los textos rellenos. Lanza un error
// con la línea del primer fallo.
export function leerErratas(texto) {
  const [cabecera, ...filas] = leerCsv(texto);
  if (!cabecera || cabecera.join(',') !== COLUMNAS_ERRATAS.join(',')) {
    throw new Error(`erratas.csv: la cabecera debe ser ${COLUMNAS_ERRATAS.join(',')}`);
  }
  return filas.map((f, i) => {
    const linea = i + 2;
    if (f.length !== COLUMNAS_ERRATAS.length) throw new Error(`erratas.csv, línea ${linea}: ${f.length} columnas`);
    const o = Object.fromEntries(COLUMNAS_ERRATAS.map((c, k) => [c, f[k].trim()]));
    const r = /^(\d{4})-(\d{2})-(\d{2})$/.exec(o.fecha);
    const d = r ? new Date(Date.UTC(+r[1], +r[2] - 1, +r[3])) : null;
    if (!d || d.getUTCDate() !== +r[3] || d.getUTCMonth() !== +r[2] - 1) throw new Error(`erratas.csv, línea ${linea}: fecha «${o.fecha}» (AAAA-MM-DD)`);
    if (!/^\d+\.\d+\.\d+$/.test(o.version)) throw new Error(`erratas.csv, línea ${linea}: versión «${o.version}» (como 0.4.0)`);
    const vacia = COLUMNAS_ERRATAS.find((c) => !o[c]);
    if (vacia) throw new Error(`erratas.csv, línea ${linea}: falta ${vacia}`);
    return o;
  });
}

// Celda de una tabla de Markdown: sin saltos de línea ni barras sin escapar.
const celda = (x) => String(x).replace(/\s*\n\s*/g, ' ').replace(/\|/g, '\\|');

// Markdown de la fe de erratas en un idioma.
export function textoErratas(erratas, idioma, repositorio = REPOSITORIO) {
  const tx = TEXTOS[idioma === 'en' ? 'en' : 'es'];
  const cambios = `https://github.com/${repositorio}/blob/main/CHANGELOG.md`;
  if (!erratas.length) return tx.vacia(cambios);
  const sufijo = idioma === 'en' ? 'en' : 'es';
  const orden = [...erratas].sort((a, b) => b.fecha.localeCompare(a.fecha));
  const lineas = [tx.intro(erratas.length, cambios), '', `| ${tx.cabecera.join(' | ')} |`, `|${tx.cabecera.map(() => '---').join('|')}|`];
  for (const e of orden) {
    const [a, m, d] = e.fecha.split('-').map(Number);
    lineas.push(`| ${[tx.fecha(d, m, a), `v${e.version}`, e[`donde_${sufijo}`], e[`error_${sufijo}`], e[`correccion_${sufijo}`]].map(celda).join(' | ')} |`);
  }
  return lineas.join('\n');
}

// Texto de la página con la marca rellena. La nota debe llevar la marca una vez.
export function montarMetodoCorto(nota, erratas, idioma, repositorio = REPOSITORIO) {
  const partes = nota.split(MARCA_ERRATAS);
  if (partes.length !== 2) throw new Error(`La nota debe llevar la marca ${MARCA_ERRATAS} una vez`);
  return partes.join(textoErratas(erratas, idioma, repositorio));
}

function argumentos(argv) {
  const a = {};
  for (let i = 0; i < argv.length; i += 2) {
    if (!argv[i].startsWith('--')) throw new Error(`Argumento inesperado: ${argv[i]}`);
    a[argv[i].slice(2)] = argv[i + 1];
  }
  for (const clave of ['idioma', 'nota', 'erratas', 'salida']) if (!a[clave]) throw new Error(`Falta --${clave}`);
  return a;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = argumentos(process.argv.slice(2));
  const erratas = leerErratas(readFileSync(a.erratas, 'utf8'));
  const texto = montarMetodoCorto(readFileSync(a.nota, 'utf8'), erratas, a.idioma, a.repositorio ?? REPOSITORIO);
  writeFileSync(a.salida, texto, 'utf8');
  console.log(`${a.salida}: ${erratas.length} erratas`);
}
