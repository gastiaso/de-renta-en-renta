// Ficha de sección (panel lateral). Esqueleto: sin sección elegida, una invitación a elegirla;
// con sección, su código, sus territorios y el valor del mapa activo con su estado. El
// contenido completo de la ficha (series, fichas de perfil, comparador) llega en F2.

const crear = (etiqueta, clase, texto) => {
  const el = document.createElement(etiqueta);
  if (clase) el.className = clase;
  if (texto !== undefined) el.textContent = texto;
  return el;
};

function cabecera(t, alCerrar) {
  const caja = crear('header', 'ficha-cabecera');
  caja.append(crear('h2', 'ficha-titulo', t('interfaz.ficha.titulo')));
  if (alCerrar) {
    const cerrar = crear('button', 'ficha-cerrar', '×');
    cerrar.type = 'button';
    cerrar.setAttribute('aria-label', t('interfaz.ficha.cerrar'));
    cerrar.title = t('interfaz.ficha.cerrar');
    cerrar.addEventListener('click', alCerrar);
    caja.append(cerrar);
  }
  return caja;
}

export function fichaVacia(contenedor, { t }) {
  contenedor.replaceChildren(cabecera(t), crear('p', 'ficha-vacia', t('interfaz.ficha.vacia')));
}

export function fichaError(contenedor, { t, error }) {
  console.error(error);
  const aviso = crear('p', 'ficha-error', t('interfaz.error_carga'));
  aviso.setAttribute('role', 'alert');
  contenedor.replaceChildren(cabecera(t), aviso);
}

// `valor`: ya calculado con la fórmula del mapa (o null); `estado`: índice en binario.estados.
export function fichaSeccion(contenedor, { t, codigo, territorios, mapaId, mapaDef, anio, valor, estado, estados, ejemplo, alCerrar }) {
  const municipio = codigo.slice(0, 5);
  const provincia = codigo.slice(0, 2);
  const lineas = [
    ['vocabulario.nivel.municipio', territorios.municipio?.[municipio] ?? municipio],
    ['vocabulario.nivel.distrito', codigo.slice(5, 7)],
    ['vocabulario.nivel.provincia', territorios.provincia?.[provincia] ?? provincia],
  ];
  const datos = crear('dl', 'ficha-territorios');
  for (const [clave, texto] of lineas) datos.append(crear('dt', null, t(clave)), crear('dd', null, texto));

  const bloque = crear('section', 'ficha-valor');
  bloque.append(crear('h3', 'ficha-indicador', t(`indicadores.${mapaId}.nombre`)));
  const cifra = crear('p', 'ficha-cifra');
  cifra.append(crear('span', 'ficha-numero', valor === null ? '—' : t.numero(valor, mapaDef.decimales ?? 0)));
  cifra.append(crear('span', 'ficha-unidad', t(`indicadores.${mapaId}.unidad`)));
  bloque.append(cifra);
  const nombreEstado = estados[estado];
  bloque.append(crear('p', 'ficha-estado', `${t('interfaz.ficha.anio', { anio })} · ${t(`vocabulario.estado.${nombreEstado}`)}`));
  if (ejemplo) bloque.append(crear('p', 'etiqueta-ejemplo', t('avisos.ejemplo')));

  contenedor.replaceChildren(
    cabecera(t, alCerrar),
    crear('p', 'ficha-codigo', t('interfaz.ficha.seccion', { codigo })),
    datos,
    bloque,
  );
}
