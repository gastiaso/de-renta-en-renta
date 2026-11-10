// Familias de los indicadores de alquiler (backlog, decisión 1 y tarea 34), que nunca se mezclan
// en una cifra:
//   - «quedarse»: quien ya vive de alquiler (el parque alquilado, con los contratos vigentes que
//     declara el SERPAVI);
//   - «entrar»: quien busca piso hoy (la oferta y los contratos nuevos).
// El manifiesto marca cada mapa de alquiler con la suya (`familia`); los demás mapas no la llevan.
// Su nombre está en `vocabulario.familia_alquiler` (lo genera el pipeline) y su lectura literal, en
// `interfaz.leyenda.lectura_familia`. Sin DOM, para que la leyenda, la portada y las pruebas usen lo
// mismo.

export const FAMILIAS_ALQUILER = ['quedarse', 'entrar'];

// Familias que aún no tienen mapa en el sitio: «entrar» sale «próximamente» mientras Idealista no
// autorice publicar su oferta (decisión del autor, 10-nov-2026; plan §11, pregunta 52). Se quita
// cuando la familia tenga su mapa (backlog, tareas 37 y 38).
export const FAMILIAS_PROXIMAMENTE = ['entrar'];

// Indicador de la oferta de los portales (13): sin su capa encendida, el selector del mapa lo
// ofrece desactivado y rotulado «próximamente».
export const INDICADOR_OFERTA = 'precio_oferta';
export function opcionProximamente(t, mapas, indicador = INDICADOR_OFERTA) {
  const tiene = Object.entries(mapas ?? {}).some(([id, def]) => (def?.indicador ?? id) === indicador);
  if (tiene || !t.existe(`indicadores.${indicador}.nombre`)) return null;
  return { valor: `proximamente:${indicador}`, texto: `${t(`indicadores.${indicador}.nombre`)} · ${t('portada.proximamente')}`,
    desactivada: true };
}

// Familia de lo que pinta el mapa. «¿Te llega?» calcula en el navegador el peso del alquiler en el
// ingreso (indicador 15) con el alquiler del SERPAVI: siempre «quedarse». Un mapa del manifiesto,
// la suya; sin ella (o con una que no es de las dos), ninguna.
export function familiaDe({ modo, mapaDef } = {}) {
  if (modo === 'llega') return 'quedarse';
  const familia = mapaDef?.familia;
  return FAMILIAS_ALQUILER.includes(familia) ? familia : null;
}

// «Quedarse · quien ya vive de alquiler». null sin familia o si falta alguno de sus dos textos.
export function textoFamilia(t, familia) {
  if (!FAMILIAS_ALQUILER.includes(familia)) return null;
  const nombre = `vocabulario.familia_alquiler.${familia}`;
  const lectura = `interfaz.leyenda.lectura_familia.${familia}`;
  if (!t.existe(nombre) || !t.existe(lectura)) return null;
  return `${t(nombre)} · ${t(lectura)}`;
}
