// Imagen PNG del mapa tal como se ve, con título, leyenda, claves de los huecos y fuente, compuesta
// en un lienzo 2D. Sin dependencias: el mapa sale del lienzo de MapLibre y el resto se dibuja aquí
// con los colores y las tipografías de tokens.css. Los textos llegan ya escritos (principal.js):
// aquí no se decide qué se dice, y el sueldo escrito por el usuario no llega nunca.

const css = (nombre) => getComputedStyle(document.documentElement).getPropertyValue(nombre).trim();

// Copia del lienzo del mapa justo después de dibujarlo. WebGL vacía el búfer tras cada fotograma
// (salvo con preserveDrawingBuffer, que hace más lento el mapa), así que se copia dentro del evento
// «render» de un fotograma pedido a propósito; si aún faltan teselas, se espera a que el mapa pare.
function copiaDelMapa(mapa) {
  return new Promise((resolver, rechazar) => {
    const copiar = () => {
      try {
        const origen = mapa.getCanvas();
        const copia = document.createElement('canvas');
        copia.width = origen.width;
        copia.height = origen.height;
        copia.getContext('2d').drawImage(origen, 0, 0);
        resolver(copia);
      } catch (error) {
        rechazar(error);
      }
    };
    const dibujar = () => {
      mapa.once('render', copiar);
      mapa.triggerRepaint();
    };
    if (mapa.loaded()) dibujar();
    else mapa.once('idle', dibujar);
  });
}

// Líneas de un texto que caben en `ancho` con la fuente activa del contexto.
function partir(ctx, texto, ancho) {
  const lineas = [];
  let linea = '';
  for (const palabra of String(texto).split(/\s+/).filter(Boolean)) {
    const prueba = linea ? `${linea} ${palabra}` : palabra;
    if (linea && ctx.measureText(prueba).width > ancho) {
      lineas.push(linea);
      linea = palabra;
    } else linea = prueba;
  }
  if (linea) lineas.push(linea);
  return lineas;
}

// Muestra rayada del secreto estadístico (como la clase .secreto de tokens.css).
function muestraSecreto(c, x, y, lado, color) {
  c.save();
  c.beginPath();
  c.rect(x, y, lado, lado);
  c.clip();
  c.strokeStyle = color;
  c.lineWidth = 1.5;
  c.beginPath();
  for (let d = -lado; d <= lado; d += 5) {
    c.moveTo(x + d, y + lado);
    c.lineTo(x + d + lado, y);
  }
  c.stroke();
  c.restore();
  c.strokeStyle = color;
  c.lineWidth = 1;
  c.strokeRect(x + 0.5, y + 0.5, lado - 1, lado - 1);
}

// Compone la imagen y la devuelve como Blob PNG.
//   titulo, subtitulo: textos de la cabecera;
//   leyenda: { tipo: 'tramos', colores, etiquetas } (regla con los cortes entre tramos) o
//            { tipo: 'lista', elementos: [{ color, texto }] };
//   claves: { sinDato, secreto } (textos de los huecos);
//   pie: líneas de la fuente, el mapa base y la web;
//   ejemplo: texto de la etiqueta «Datos de ejemplo», o null.
export async function imagenMapa({ mapa, titulo, subtitulo, leyenda, claves, pie, ejemplo }) {
  await document.fonts.ready;
  const lienzoMapa = await copiaDelMapa(mapa);
  const escala = lienzoMapa.width / (mapa.getCanvas().clientWidth || lienzoMapa.width);
  const W = lienzoMapa.width / escala;
  const H = lienzoMapa.height / escala;
  const M = 16;

  const color = {
    fondo: css('--color-crema'), tinta: css('--color-tinta'), tenue: css('--color-tenue'),
    aviso: css('--color-aviso'), fuera: css('--color-fuera'),
  };
  const letra = {
    titulo: `600 20px ${css('--fuente-tablero')}`,
    etiqueta: `600 12px ${css('--fuente-tablero')}`,
    cifra: `500 12px ${css('--fuente-tablero')}`,
    texto: `14px ${css('--fuente-carta')}`,
    pie: `12px ${css('--fuente-carta')}`,
  };

  // Primero se mide y se anota cada trazo; después, con la altura ya sabida, se dibuja.
  const medida = document.createElement('canvas').getContext('2d');
  const trazos = [];
  const anchoDe = (texto, fuente) => {
    medida.font = fuente;
    return medida.measureText(texto).width;
  };
  let y = M;
  const escribir = (texto, fuente, tinta, alto, ancho = W) => {
    medida.font = fuente;
    for (const linea of partir(medida, texto, ancho)) {
      const yy = y;
      trazos.push((c) => {
        c.font = fuente;
        c.fillStyle = tinta;
        c.fillText(linea, M, yy);
      });
      y += alto;
    }
  };

  // Cabecera, con la etiqueta de los datos de ejemplo a la derecha.
  let anchoTitulo = W;
  if (ejemplo) {
    const rotulo = ejemplo.toUpperCase();
    const ancho = anchoDe(rotulo, letra.etiqueta) + 16;
    anchoTitulo -= ancho + 8;
    trazos.push((c) => {
      c.fillStyle = color.aviso;
      c.fillRect(M + W - ancho, M, ancho, 22);
      c.strokeStyle = color.tinta;
      c.lineWidth = 1.5;
      c.strokeRect(M + W - ancho, M, ancho, 22);
      c.font = letra.etiqueta;
      c.fillStyle = color.tinta;
      c.fillText(rotulo, M + W - ancho + 8, M + 5);
    });
  }
  escribir(titulo, letra.titulo, color.tinta, 25, anchoTitulo);
  if (subtitulo) escribir(subtitulo, letra.texto, color.tenue, 18);
  y += 8;

  // El mapa, con un filete de tinta.
  const yMapa = y;
  trazos.push((c) => {
    c.drawImage(lienzoMapa, M, yMapa, W, H);
    c.strokeStyle = color.tinta;
    c.lineWidth = 1;
    c.strokeRect(M + 0.5, yMapa + 0.5, W - 1, H - 1);
  });
  y += H + 12;

  // Leyenda.
  if (leyenda.tipo === 'tramos') {
    const n = leyenda.colores.length;
    const ancho = Math.min(64, W / n);
    const yRegla = y;
    trazos.push((c) => {
      leyenda.colores.forEach((tono, i) => {
        c.fillStyle = tono;
        c.fillRect(M + i * ancho, yRegla, ancho, 14);
      });
      c.strokeStyle = color.tinta;
      c.lineWidth = 1;
      c.strokeRect(M + 0.5, yRegla + 0.5, n * ancho - 1, 13);
    });
    y += 17;
    const yCortes = y;
    trazos.push((c) => {
      c.font = letra.cifra;
      c.fillStyle = color.tinta;
      c.textAlign = 'center';
      leyenda.etiquetas.forEach((texto, i) => c.fillText(texto, M + (i + 1) * ancho, yCortes));
      c.textAlign = 'left';
    });
    y += 20;
  } else {
    let x = M;
    for (const { color: tono, texto } of leyenda.elementos) {
      const ancho = 14 + 6 + anchoDe(texto, letra.texto) + 16;
      if (x > M && x + ancho > M + W) {
        x = M;
        y += 20;
      }
      const [xx, yy] = [x, y];
      trazos.push((c) => {
        c.fillStyle = tono;
        c.fillRect(xx, yy + 1, 14, 14);
        c.strokeStyle = color.tinta;
        c.lineWidth = 1;
        c.strokeRect(xx + 0.5, yy + 1.5, 13, 13);
        c.font = letra.texto;
        c.fillStyle = color.tinta;
        c.fillText(texto, xx + 20, yy);
      });
      x += ancho;
    }
    y += 22;
  }

  // Claves de los huecos: sin dato y secreto estadístico.
  {
    const yy = y;
    const anchoSinDato = 20 + anchoDe(claves.sinDato, letra.texto) + 16;
    trazos.push((c) => {
      c.fillStyle = color.fuera;
      c.fillRect(M, yy + 1, 14, 14);
      c.strokeStyle = color.tenue;
      c.lineWidth = 1;
      c.strokeRect(M + 0.5, yy + 1.5, 13, 13);
      muestraSecreto(c, M + anchoSinDato, yy + 1, 14, color.tenue);
      c.font = letra.texto;
      c.fillStyle = color.tinta;
      c.fillText(claves.sinDato, M + 20, yy);
      c.fillText(claves.secreto, M + anchoSinDato + 20, yy);
    });
    y += 26;
  }

  // Pie: fuente, mapa base y web.
  for (const linea of pie) escribir(linea, letra.pie, color.tenue, 16);
  y += M - 4;

  const lienzo = document.createElement('canvas');
  lienzo.width = Math.round((W + 2 * M) * escala);
  lienzo.height = Math.round(y * escala);
  const c = lienzo.getContext('2d');
  c.scale(escala, escala);
  c.textBaseline = 'top';
  c.fillStyle = color.fondo;
  c.fillRect(0, 0, W + 2 * M, y);
  for (const trazo of trazos) trazo(c);

  return new Promise((resolver, rechazar) => {
    lienzo.toBlob((blob) => (blob ? resolver(blob) : rechazar(new Error('No se pudo crear la imagen'))), 'image/png');
  });
}
