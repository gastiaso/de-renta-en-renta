// Pruebas de la página «Datos» sin navegador (web/herramientas/pagina_datos.mjs), con un
// version.json y una nota inventados; con los textos de docs/ y CITATION.cff de verdad, y con el
// version.json de publicacion/ si existe. Se ejecutan desde la raíz del proyecto, sin paquetes:
//   node --test pruebas/web/pagina_datos.test.mjs

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const raiz = process.cwd();
const HERRAMIENTA = join(raiz, 'web/herramientas/pagina_datos.mjs');
const P = await import(pathToFileURL(HERRAMIENTA).href);
const leer = (...ruta) => readFileSync(join(raiz, ...ruta), 'utf8');

const SUMA = 'ab'.repeat(32);
const COMMIT = '0123456789abcdef0123456789abcdef01234567';
const VERSION = {
  fecha: '2026-11-09T13:14:33+0100',
  commit: { id: COMMIT, cambios_sin_commit: false },
  ficheros: [
    { nombre: 'datos_web.tar.gz', bytes: 100, sha256: 'cd'.repeat(32) },
    { nombre: 'tabla_larga.parquet', bytes: 36854368, sha256: SUMA },
  ],
  indicadores: [
    { indicador: 'renta_a', filas: 437101, anio_desde: 2015, anio_hasta: 2024, niveles: ['sc', 'municipio'], cortes: ['total'] },
    { indicador: 'otro', filas: 32, anio_desde: 2025, anio_hasta: 2025, niveles: ['ccaa'], cortes: ['total', 'edad'] },
  ],
};
const NOTA = '# Datos\n\n## Descarga\n\n<!-- descarga -->\n\n## Cita\n\n<!-- cita -->\n\n## Cobertura\n\n<!-- cobertura -->\n';
const DICCIONARIO = '<!-- generado -->\n\n## Diccionario\n\n### `renta_a`\n\nTexto.\n';
const CITA = [
  'cff-version: 1.2.0',
  'title: "Atlas: de prueba"',
  'authors:',
  '  - family-names: "Pérez Gómez"',
  '    given-names: "Ana María"',
  '  - family-names: "Ruiz"',
  '    given-names: "Luis"',
  'version: "0.2.0"',
  'date-released: "2027-01-15"',
  'url: "https://ejemplo.org/atlas/"',
  'repository-code: "https://ejemplo.org/codigo"',
  'license: MIT',
].join('\n');

const montar = (extra = {}) => P.montarPagina({
  idioma: 'es', nota: NOTA, diccionario: DICCIONARIO, version: VERSION, cita: P.leerCita(CITA),
  etiqueta: 'v0.2.0', repositorio: 'cuenta/atlas', ...extra,
});

test('cifras con el formato de cada idioma', () => {
  assert.equal(P.entero(36854368, 'es'), '36.854.368');
  assert.equal(P.entero(36854368, 'en'), '36,854,368');
  assert.equal(P.entero(1332, 'es'), '1.332');
  assert.equal(P.entero(261, 'es'), '261');
  assert.equal(P.megas(36854368, 'es'), '36,9 MB');
  assert.equal(P.megas(36854368, 'en'), '36.9 MB');
  assert.equal(P.fechaLarga('2026-11-09T13:14:33+0100', 'es'), '9 de noviembre de 2026');
  assert.equal(P.fechaLarga('2026-11-09T23:59:00-0500', 'en'), '9 November 2026');
  assert.equal(P.fechaLarga('sin fecha', 'es'), null);
});

test('descarga: fichero, tamaño, suma, fecha, commit y release con sus enlaces', () => {
  const md = montar();
  assert.match(md, /- \*\*Fichero:\*\* \[`tabla_larga\.parquet`\]\(descargas\/tabla_larga\.parquet\), 36,9 MB \(36\.854\.368 bytes\)\./);
  assert.ok(md.includes(`- **Suma SHA-256:** \`${SUMA}\``));
  assert.ok(md.includes(`generados el 9 de noviembre de 2026, desde el commit [\`0123456\`](https://github.com/cuenta/atlas/commit/${COMMIT}).`));
  assert.ok(md.includes('[`v0.2.0`](https://github.com/cuenta/atlas/releases/tag/v0.2.0)'));
  assert.ok(md.includes('[`version.json`](descargas/version.json)'));
  assert.ok(!md.includes('cambios sin commit'));

  const en = montar({ idioma: 'en' });
  assert.ok(en.includes('36.9 MB (36,854,368 bytes).'));
  assert.ok(en.includes('generated on 9 November 2026, from commit'));
});

test('descarga: sin repositorio no hay enlaces a GitHub; sin etiqueta, el último release', () => {
  const local = montar({ repositorio: undefined, etiqueta: undefined });
  assert.ok(!local.includes('github.com'));
  assert.ok(local.includes('desde el commit `0123456`'));
  const ultimo = montar({ etiqueta: '' });
  assert.ok(ultimo.includes('[último release](https://github.com/cuenta/atlas/releases/latest)'));
  const raro = montar({ repositorio: 'no es un repositorio', etiqueta: 'v1 "x"' });
  assert.ok(!raro.includes('github.com'));
  const sucio = montar({ version: { ...VERSION, commit: { id: COMMIT, cambios_sin_commit: true } } });
  assert.ok(sucio.includes('con cambios sin commit'));
});

test('descarga y cobertura sin version.json, o con uno sin cobertura', () => {
  const sin = montar({ version: null });
  assert.ok(sin.includes('- **Fichero:** [`tabla_larga.parquet`](descargas/tabla_larga.parquet).'));
  assert.ok(sin.includes('- **Tamaño, suma, fecha y commit:** [`version.json`](descargas/version.json).'));
  assert.ok(sin.includes('que no se ha encontrado'));
  const { indicadores, ...antigua } = VERSION;
  const v010 = montar({ version: antigua });
  assert.ok(v010.includes('no trae la cobertura por indicador'));
  assert.ok(v010.includes('36,9 MB'));
});

test('cobertura: una fila por indicador, enlazada al diccionario si está en él, y el total', () => {
  const md = montar();
  assert.ok(md.includes('| Indicador | Filas | Años | Niveles | Cortes |'));
  assert.ok(md.includes('| [`renta_a`](#renta_a) | 437.101 | 2015–2024 | `sc`, `municipio` | `total` |'));
  assert.ok(md.includes('| `otro` | 32 | 2025 | `ccaa` | `total`, `edad` |'));
  assert.ok(md.includes('437.133 filas en total.'));
  const en = montar({ idioma: 'en' });
  assert.ok(en.includes('| Indicator | Rows | Years | Levels | Breakdowns |'));
  assert.ok(en.includes('437,133 rows in total.'));
});

test('cita: autores con iniciales, año, título, versión y enlaces de CITATION.cff', () => {
  const cita = P.leerCita(CITA);
  assert.equal(cita.title, 'Atlas: de prueba');
  assert.deepEqual(cita.autores, [{ apellidos: 'Pérez Gómez', nombre: 'Ana María' }, { apellidos: 'Ruiz', nombre: 'Luis' }]);
  const md = montar();
  assert.ok(md.includes('> Pérez Gómez, A. M. y Ruiz, L. (2027). *Atlas: de prueba* (versión 0.2.0). <https://ejemplo.org/atlas/>'));
  assert.ok(md.includes('[repositorio](https://ejemplo.org/codigo)'));
  assert.ok(montar({ idioma: 'en' }).includes('> Pérez Gómez, A. M. & Ruiz, L. (2027). *Atlas: de prueba* (version 0.2.0).'));
  assert.throws(() => montar({ cita: P.leerCita('authors:\n') }), /CITATION/);
});

test('la página: marcas rellenas una vez y el diccionario al final', () => {
  const md = montar();
  for (const marca of P.MARCAS) assert.ok(!md.includes(marca), marca);
  assert.ok(md.trimEnd().endsWith('Texto.'));
  assert.ok(md.indexOf('## Cobertura') < md.indexOf('## Diccionario'));
  assert.throws(() => montar({ nota: NOTA.replace('<!-- cita -->', '') }), /<!-- cita -->/);
  assert.throws(() => montar({ nota: `${NOTA}\n<!-- descarga -->\n` }), /<!-- descarga -->/);
  assert.throws(() => montar({ idioma: 'fr' }), /fr/);
  assert.equal(P.escaparMd('a*b_c|d'), 'a\\*b\\_c\\|d');
});

// Con los textos de verdad: docs/datos.md y docs/data.md, el diccionario generado y CITATION.cff
const versionReal = join(raiz, 'publicacion', 'version.json');
for (const [idioma, nota, diccionario] of [['es', 'datos.md', 'datos_diccionario.md'], ['en', 'data.md', 'data_dictionary.md']]) {
  test(`docs/${nota}: la página se monta entera con el diccionario y la cita de CITATION.cff`, () => {
    const version = existsSync(versionReal) ? JSON.parse(leer('publicacion', 'version.json')) : null;
    const md = P.montarPagina({
      idioma, nota: leer('docs', nota), diccionario: leer('docs', diccionario), version,
      cita: P.leerCita(leer('CITATION.cff')), etiqueta: 'v0.1.0', repositorio: 'cuenta/atlas',
    });
    for (const marca of P.MARCAS) assert.ok(!md.includes(marca), marca);
    assert.ok(md.includes('](descargas/tabla_larga.parquet)'));
    assert.match(md, /^> Astiaso Llamazares, G\. \(\d{4}\)\. \*De renta en renta/m);
    assert.ok(md.includes('### `sueldo_necesario`'));
    if (version) assert.match(md, /Suma SHA-256|SHA-256 sum/);
  });
}

test('se usa desde la línea de órdenes y escribe en UTF-8', () => {
  const dir = mkdtempSync(join(tmpdir(), 'pagina-datos-'));
  try {
    const salida = join(dir, 'datos_en.md');
    const r = spawnSync(process.execPath, [HERRAMIENTA, '--idioma', 'en', '--nota', 'docs/data.md',
      '--diccionario', 'docs/data_dictionary.md', '--version', join(dir, 'no_existe.json'), '--cita', 'CITATION.cff',
      '--salida', salida], { cwd: raiz, encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stderr, /no_existe\.json/);
    const md = readFileSync(salida, 'utf8');
    assert.ok(md.includes('which was not found'));
    assert.ok(md.includes('«© EuroGeographics for the administrative boundaries»'));
    const mal = spawnSync(process.execPath, [HERRAMIENTA, '--idioma', 'en'], { cwd: raiz, encoding: 'utf8' });
    assert.equal(mal.status, 1);
    assert.match(mal.stderr, /Falta --nota/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
