// Monta el Markdown de la página «Datos» (datos.html y data.html), que el flujo de Pages convierte
// después con pandoc y plantilla_documento.html, como la página «Método» (docs/publicacion.md).
//
// Parte del texto a mano (docs/datos.md o docs/data.md), rellena sus tres marcas y le añade al
// final el diccionario que genera R desde el inventario (docs/datos_diccionario.md o
// docs/data_dictionary.md; exportar_diccionario_datos(), objetivo ficheros_diccionario_datos):
//   <!-- descarga -->   fichero, tamaño, suma SHA-256, fecha y commit de los datos y enlace al
//                       release, de version.json (el del release que se publica);
//   <!-- cita -->       cita del atlas, de CITATION.cff;
//   <!-- cobertura -->  filas, años, niveles y cortes de cada indicador en la tabla larga
//                       (version.json, «indicadores»; empaquetar_publicacion()).
// Sin version.json (en local, si no se ha copiado), la descarga sale sin cifras y sin cobertura.
//
// Uso, desde la raíz del proyecto (Node 18 o posterior, sin paquetes):
//   node web/herramientas/pagina_datos.mjs --idioma es --nota docs/datos.md \
//     --diccionario docs/datos_diccionario.md --version publicacion/version.json \
//     --cita CITATION.cff [--etiqueta v0.1.0] [--repositorio cuenta/nombre] --salida datos_es.md
// --etiqueta y --repositorio dan los enlaces al release y al commit (en el flujo, los de la
// ejecución). La salida se escribe en UTF-8 con --salida: en PowerShell, «>» la pasaría a UTF-16.

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const MARCAS = ['<!-- descarga -->', '<!-- cita -->', '<!-- cobertura -->'];
const FICHERO = 'tabla_larga.parquet';
const RUTA_FICHERO = `descargas/${FICHERO}`;
const RUTA_VERSION = 'descargas/version.json';

export const TEXTOS = {
  es: {
    miles: '.', decimal: ',',
    meses: ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre',
      'noviembre', 'diciembre'],
    fecha: (d, m, a) => `${d} de ${m} de ${a}`,
    fichero: 'Fichero',
    suma: 'Suma SHA-256',
    datos: 'Datos',
    generados: (fecha) => `generados el ${fecha}`,
    desde_commit: (commit) => `desde el commit ${commit}`,
    sin_commit: 'con cambios sin commit',
    release: 'Release',
    release_texto: 'con los datos de la web y el mapa base',
    ultimo_release: 'último release',
    versiones: 'Versiones de las fuentes',
    sin_version: 'Tamaño, suma, fecha y commit',
    cobertura_intro: 'Filas, años, niveles y cortes de cada indicador en la tabla larga de este release (`version.json`, `indicadores`).',
    cabecera: ['Indicador', 'Filas', 'Años', 'Niveles', 'Cortes'],
    total: (n) => `${n} filas en total.`,
    sin_cobertura: 'El `version.json` de este release no trae la cobertura por indicador.',
    sin_version_cobertura: 'La cobertura por indicador sale de `version.json`, que no se ha encontrado.',
    version_cita: 'versión',
    y: 'y',
    cita_github: (url) => `GitHub la ofrece también en APA y BibTeX desde el [repositorio](${url}) («Cite this repository»).`,
  },
  en: {
    miles: ',', decimal: '.',
    meses: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October',
      'November', 'December'],
    fecha: (d, m, a) => `${d} ${m} ${a}`,
    fichero: 'File',
    suma: 'SHA-256 sum',
    datos: 'Data',
    generados: (fecha) => `generated on ${fecha}`,
    desde_commit: (commit) => `from commit ${commit}`,
    sin_commit: 'with uncommitted changes',
    release: 'Release',
    release_texto: 'with the site data and the base map',
    ultimo_release: 'latest release',
    versiones: 'Source versions',
    sin_version: 'Size, sum, date and commit',
    cobertura_intro: 'Rows, years, levels and breakdowns of each indicator in the long table of this release (`version.json`, `indicadores`).',
    cabecera: ['Indicator', 'Rows', 'Years', 'Levels', 'Breakdowns'],
    total: (n) => `${n} rows in total.`,
    sin_cobertura: 'The `version.json` of this release does not include the coverage by indicator.',
    sin_version_cobertura: 'The coverage by indicator comes from `version.json`, which was not found.',
    version_cita: 'version',
    y: '&',
    cita_github: (url) => `GitHub also offers it in APA and BibTeX from the [repository](${url}) («Cite this repository»).`,
  },
};

const textos = (idioma) => {
  const tx = TEXTOS[idioma];
  if (!tx) throw new Error(`Idioma sin textos: ${idioma}`);
  return tx;
};

// Texto sin marcas de Markdown.
export const escaparMd = (x) => String(x).replace(/([\\`*_[\]<>|#~])/g, '\\$1');
const codigo = (x) => `\`${x}\``;

// Cifras con el formato de cada idioma, sin depender de los datos de idioma de Node.
export function entero(n, idioma) {
  return String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, textos(idioma).miles);
}

export function megas(bytes, idioma) {
  return `${(bytes / 1e6).toFixed(1).replace('.', textos(idioma).decimal)} MB`;
}

// «2026-11-09T13:14:33+0100» → «9 de noviembre de 2026» o «9 November 2026» (la fecha local de version.json).
export function fechaLarga(iso, idioma) {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(iso ?? ''));
  if (!m) return null;
  const tx = textos(idioma);
  return tx.fecha(Number(m[3]), tx.meses[Number(m[2]) - 1], m[1]);
}

const REPOSITORIO = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ETIQUETA = /^[A-Za-z0-9_.-]+$/;

export function bloqueDescarga({ version, idioma, etiqueta, repositorio }) {
  const tx = textos(idioma);
  const repo = REPOSITORIO.test(repositorio ?? '') ? `https://github.com/${repositorio}` : null;
  const fichero = version?.ficheros?.find?.((f) => f.nombre === FICHERO);
  const enlace = `[${codigo(FICHERO)}](${RUTA_FICHERO})`;
  if (!fichero) {
    return [`- **${tx.fichero}:** ${enlace}.`, `- **${tx.sin_version}:** [${codigo('version.json')}](${RUTA_VERSION}).`];
  }
  const lineas = [`- **${tx.fichero}:** ${enlace}, ${megas(fichero.bytes, idioma)} (${entero(fichero.bytes, idioma)} bytes).`];
  if (/^[0-9a-f]{64}$/.test(fichero.sha256 ?? '')) lineas.push(`- **${tx.suma}:** ${codigo(fichero.sha256)}`);

  const partes = [];
  const fecha = fechaLarga(version.fecha, idioma);
  if (fecha) partes.push(tx.generados(fecha));
  const id = version.commit?.id;
  if (/^[0-9a-f]{40}$/.test(id ?? '')) {
    const corto = codigo(id.slice(0, 7));
    partes.push(tx.desde_commit(repo ? `[${corto}](${repo}/commit/${id})` : corto));
    if (version.commit.cambios_sin_commit === true) partes.push(tx.sin_commit);
  }
  if (partes.length) lineas.push(`- **${tx.datos}:** ${partes.join(', ')}.`);

  if (repo) {
    const release = ETIQUETA.test(etiqueta ?? '')
      ? `[${codigo(etiqueta)}](${repo}/releases/tag/${etiqueta})`
      : `[${tx.ultimo_release}](${repo}/releases/latest)`;
    lineas.push(`- **${tx.release}:** ${release}, ${tx.release_texto}.`);
  }
  lineas.push(`- **${tx.versiones}:** [${codigo('version.json')}](${RUTA_VERSION}).`);
  return lineas;
}

export function bloqueCobertura({ version, idioma, anclas = new Set() }) {
  const tx = textos(idioma);
  if (!version) return [tx.sin_version_cobertura];
  const filas = Array.isArray(version.indicadores) ? version.indicadores : [];
  if (!filas.length) return [tx.sin_cobertura];
  const lista = (x) => (Array.isArray(x) ? x : [x]).filter((v) => v != null).map(codigo).join(', ');
  const anios = (f) => (f.anio_desde === f.anio_hasta ? `${f.anio_desde}` : `${f.anio_desde}–${f.anio_hasta}`);
  const total = filas.reduce((s, f) => s + Number(f.filas ?? 0), 0);
  return [
    tx.cobertura_intro,
    '',
    `| ${tx.cabecera.join(' | ')} |`,
    `| ${tx.cabecera.map(() => '---').join(' | ')} |`,
    ...filas.map((f) => {
      const ind = anclas.has(f.indicador) ? `[${codigo(f.indicador)}](#${f.indicador})` : codigo(f.indicador);
      return `| ${ind} | ${entero(f.filas, idioma)} | ${anios(f)} | ${lista(f.niveles)} | ${lista(f.cortes)} |`;
    }),
    '',
    tx.total(entero(total, idioma)),
  ];
}

// Campos de CITATION.cff que usa la cita (el fichero es YAML sencillo: se lee línea a línea).
export function leerCita(texto) {
  const valor = (l) => l.replace(/^[^:]+:\s*/, '').replace(/^"(.*)"\s*$/, '$1').replace(/^'(.*)'\s*$/, '$1').trim();
  const cita = { autores: [] };
  for (const linea of texto.split(/\r?\n/)) {
    const clave = /^\s*-?\s*([a-z-]+):/.exec(linea)?.[1];
    if (!clave) continue;
    if (clave === 'family-names') cita.autores.push({ apellidos: valor(linea), nombre: '' });
    else if (clave === 'given-names' && cita.autores.length) cita.autores.at(-1).nombre = valor(linea);
    else if (['title', 'version', 'date-released', 'url', 'repository-code'].includes(clave) && /^[a-z]/.test(linea)) {
      cita[clave] = valor(linea);
    }
  }
  return cita;
}

export function bloqueCita({ cita, idioma }) {
  const tx = textos(idioma);
  if (!cita.title || !cita.autores.length) throw new Error('CITATION.cff sin título o sin autores');
  const iniciales = (n) => n.split(/\s+/).filter(Boolean).map((p) => `${p[0]}.`).join(' ');
  const autores = cita.autores.map((a) => `${a.apellidos}${a.nombre ? `, ${iniciales(a.nombre)}` : ''}`);
  const nombres = autores.length > 1 ? `${autores.slice(0, -1).join(', ')} ${tx.y} ${autores.at(-1)}` : autores[0];
  const anio = /^\d{4}/.exec(cita['date-released'] ?? '')?.[0] ?? 's. f.';
  const version = cita.version ? ` (${tx.version_cita} ${cita.version})` : '';
  const url = cita.url ? ` <${cita.url}>` : '';
  const lineas = [`> ${escaparMd(nombres)} (${anio}). *${escaparMd(cita.title)}*${version}.${url}`];
  if (cita['repository-code']) lineas.push('', tx.cita_github(cita['repository-code']));
  return lineas;
}

// Página entera: la nota con sus marcas rellenas y, al final, el diccionario.
export function montarPagina({ idioma, nota, diccionario, version = null, cita, etiqueta, repositorio }) {
  for (const marca of MARCAS) {
    const veces = nota.split(marca).length - 1;
    if (veces !== 1) throw new Error(`La nota debe llevar la marca ${marca} una vez (lleva ${veces})`);
  }
  const anclas = new Set([...diccionario.matchAll(/^### `([a-z0-9_]+)`$/gm)].map((m) => m[1]));
  const bloques = {
    '<!-- descarga -->': bloqueDescarga({ version, idioma, etiqueta, repositorio }),
    '<!-- cita -->': bloqueCita({ cita, idioma }),
    '<!-- cobertura -->': bloqueCobertura({ version, idioma, anclas }),
  };
  let texto = nota.replace(/\r\n/g, '\n');
  for (const [marca, lineas] of Object.entries(bloques)) texto = texto.replace(marca, () => lineas.join('\n'));
  return `${texto.trimEnd()}\n\n${diccionario.replace(/\r\n/g, '\n').trimEnd()}\n`;
}

function argumentos(lista) {
  const args = {};
  for (let i = 0; i < lista.length; i += 2) {
    if (!lista[i].startsWith('--') || lista[i + 1] === undefined) throw new Error(`Argumento sin valor: ${lista[i]}`);
    args[lista[i].slice(2)] = lista[i + 1];
  }
  for (const clave of ['idioma', 'nota', 'diccionario', 'salida']) {
    if (!args[clave]) throw new Error(`Falta --${clave} (ver la cabecera de web/herramientas/pagina_datos.mjs)`);
  }
  return args;
}

function principal() {
  const args = argumentos(process.argv.slice(2));
  const leer = (ruta) => readFileSync(ruta, 'utf8').replace(/^\uFEFF/, '');
  const version = args.version && existsSync(args.version) ? JSON.parse(leer(args.version)) : null;
  if (args.version && !version) console.warn(`Aviso: no existe ${args.version}; la descarga sale sin cifras.`);
  const pagina = montarPagina({
    idioma: args.idioma,
    nota: leer(args.nota),
    diccionario: leer(args.diccionario),
    version,
    cita: leerCita(leer(args.cita ?? 'CITATION.cff')),
    etiqueta: args.etiqueta,
    repositorio: args.repositorio,
  });
  writeFileSync(args.salida, pagina, 'utf8');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    principal();
  } catch (e) {
    console.error(`pagina_datos.mjs: ${e.message}`);
    process.exit(1);
  }
}
