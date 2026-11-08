// Leyenda del mapa: regla de cinco tramos con los cortes del manifiesto, claves de los huecos
// (sin dato, secreto estadístico) y supuestos del cálculo.

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

export function pintarLeyenda(contenedor, { t, mapaId, mapaDef, supuestos }) {
  const titulo = crear('h2', 'leyenda-titulo', t(`indicadores.${mapaId}.nombre`));
  const unidad = crear('p', 'leyenda-unidad', t(`indicadores.${mapaId}.unidad`));

  const regla = crear('div', 'leyenda-regla');
  for (let i = 1; i <= mapaDef.cortes.length + 1; i++) regla.append(crear('span', `leyenda-tramo tramo-${i}`));
  const cortes = crear('div', 'leyenda-cortes');
  mapaDef.cortes.forEach((corte, i) => {
    const marca = crear('span', 'leyenda-corte', t.numero(corte, mapaDef.decimales ?? 0));
    marca.style.left = `${(100 * (i + 1)) / (mapaDef.cortes.length + 1)}%`;
    cortes.append(marca);
  });

  const claves = crear('ul', 'leyenda-claves');
  for (const [clase, clave] of [['leyenda-sin-dato', 'interfaz.leyenda.sin_dato'], ['secreto', 'interfaz.leyenda.secreto']]) {
    const item = crear('li');
    item.append(crear('span', `leyenda-muestra ${clase}`), crear('span', null, t(clave)));
    claves.append(item);
  }

  const notas = [];
  if (mapaDef.formula === 'alquiler_m2_a_sueldo') {
    notas.push(crear('p', 'leyenda-supuestos', t('interfaz.leyenda.supuestos', {
      superficie: t.numero(supuestos.superficie_m2), umbral: t.porcentaje(supuestos.umbral),
    })));
  }

  contenedor.replaceChildren(titulo, unidad, regla, cortes, claves, ...notas);
  contenedor.hidden = false;
}
