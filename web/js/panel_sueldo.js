// Tarjeta «Tu sueldo»: ingresos netos (12 o 14 pagas, segundo ingreso opcional; «ingresos» para que
// valga una pensión, decisión del autor del 12-nov-2026), fichas, superficie, umbral, «Añadir otros
// gastos de vivienda» con su cifra a la vista, resumen con su aviso fijo y botones. El marcado está en
// mapa.html (textos con data-i18n); aquí se conectan los controles y se actualiza lo que cambia. Lo
// escrito solo vive en memoria.

import { FICHAS_PERFIL, ingresoPeon, leerSueldo, SUPERFICIE_TIPICA } from './sueldo.js';

const $ = (id) => document.getElementById(id);

export function crearPanelSueldo({ alCambiar, alCompartir }) {
  const el = {
    neto: $('sueldo-neto'),
    segundo: $('sueldo-segundo'),
    error: $('sueldo-error'),
    pagas: $('sueldo-pagas'),
    fichas: $('sueldo-fichas'),
    superficie: $('sueldo-superficie'),
    superficieNota: $('sueldo-superficie-nota'),
    umbral: $('sueldo-umbral'),
    umbralTitulo: $('sueldo-umbral-titulo'),
    gastos: $('sueldo-gastos'),
    gastosNota: $('sueldo-gastos-nota'),
    aviso: $('sueldo-aviso'),
    intro: $('sueldo-intro'),
    resumen: $('sueldo-resumen'),
    detalle: $('sueldo-detalle'),
    volver: $('sueldo-volver'),
    compartir: $('sueldo-compartir'),
  };
  let pagas = 12;
  let espera = null;

  // «1.500» son mil quinientos (leerSueldo, el lector de la portada). Lo escrito que no se entiende
  // («mil», «1500 al mes») no se calla: el campo queda marcado y sale el aviso.
  const numero = (input) => leerSueldo(input.value);
  const sueldoEscrito = () => {
    const s = { neto: numero(el.neto), pagas, segundo: numero(el.segundo) };
    return ingresoPeon(s) ? s : null;
  };
  const marcarErrores = () => {
    let alguno = false;
    for (const input of [el.neto, el.segundo]) {
      const mal = input.value.trim() !== '' && numero(input) === null;
      if (mal) input.setAttribute('aria-invalid', 'true');
      else input.removeAttribute('aria-invalid');
      alguno ||= mal;
    }
    if (el.error) el.error.hidden = !alguno;
  };
  const avisarSueldo = () => {
    clearTimeout(espera);
    espera = setTimeout(() => {
      marcarErrores();
      alCambiar({ sueldo: sueldoEscrito(), escrito: true });
    }, 300);
  };

  el.neto.addEventListener('input', avisarSueldo);
  el.segundo.addEventListener('input', avisarSueldo);
  el.pagas.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-pagas]');
    if (!boton) return;
    pagas = Number(boton.dataset.pagas);
    marcarGrupo(el.pagas, 'pagas', pagas);
    if (sueldoEscrito()) avisarSueldo();
  });
  el.fichas.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-ficha]');
    if (!boton || boton.disabled) return;
    const ficha = boton.dataset.ficha;
    alCambiar({ ficha: boton.getAttribute('aria-pressed') === 'true' ? null : ficha });
  });
  el.superficie.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-superficie]');
    // Decisión del autor (11-nov-2026): «típica», la superficie típica del territorio que manda
    if (boton && !boton.disabled) {
      alCambiar({ superficie: boton.dataset.superficie === SUPERFICIE_TIPICA ? SUPERFICIE_TIPICA : Number(boton.dataset.superficie) });
    }
  });
  el.umbral.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-umbral]');
    if (boton) alCambiar({ umbral: Number(boton.dataset.umbral) });
  });
  // Otros gastos de vivienda (decisión del autor, 12-nov-2026): apagado por defecto
  el.gastos?.addEventListener('change', () => alCambiar({ gastos: el.gastos.checked }));
  el.volver.addEventListener('click', () => {
    el.neto.value = '';
    el.segundo.value = '';
    marcarErrores();
    alCambiar({ ficha: null, sueldo: null, volver: true });
  });
  el.compartir.addEventListener('click', alCompartir);

  function marcarGrupo(grupo, dato, valor) {
    for (const b of grupo.querySelectorAll(`button[data-${dato}]`)) b.setAttribute('aria-pressed', String(Number(b.dataset[dato]) === valor));
  }

  return {
    // Solo el texto de los otros gastos de vivienda (al mover el mapa sin ficha, cambia el municipio del centro).
    notaGastos(texto) {
      if (!el.gastosNota) return;
      el.gastosNota.textContent = texto ?? '';
      el.gastosNota.hidden = !texto;
    },
    // Rellena los campos con un sueldo que llega de un enlace compartido.
    ponerSueldo(sueldo) {
      if (!sueldo) return;
      el.neto.value = String(sueldo.neto);
      el.segundo.value = sueldo.segundo ? String(sueldo.segundo) : '';
      pagas = sueldo.pagas === 14 ? 14 : 12;
      marcarGrupo(el.pagas, 'pagas', pagas);
    },
    // `vista`: { t, estado, sueldo, perfiles, modo, superficie, umbral, resumen, detalle,
    // sinEfecto, soloMinimo } (sinEfecto: el mapa activo no usa la superficie ni el umbral;
    // soloMinimo, tarea 40: el mapa del sueldo necesario usa el alquiler real y la superficie solo
    // cambia el mínimo teórico de la ficha). `tipica`: con la superficie típica elegida, el texto que
    // dice de qué territorio es (o por qué no la hay). `gastos`: { activo, disponible, nota }, el
    // selector de otros gastos de vivienda y el texto con su cifra (o por qué no la hay).
    pintar({ t, estado, sueldo, perfiles, modo, superficie, umbral, resumen, detalle, sinEfecto = false, soloMinimo = false, tipica = null, gastos = null }) {
      // Fichas: las que tienen ingreso en perfiles.json, y «Tu ficha» si hay sueldo escrito.
      const disponibles = [...FICHAS_PERFIL.filter((f) => perfiles?.[f]), 'peon'];
      el.fichas.querySelector('.fichas-botones').replaceChildren(...disponibles.map((ficha) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = `ficha-boton ficha-boton-${ficha}`;
        b.dataset.ficha = ficha;
        b.textContent = t(`fichas.${ficha}`);
        b.setAttribute('aria-pressed', String(modo === 'llega' && estado.ficha === ficha));
        if (ficha === 'peon' && !ingresoPeon(sueldo)) {
          b.disabled = true;
          b.title = t('interfaz.sueldo.peon_sin_sueldo');
        }
        return b;
      }));

      // Superficie: solo se elige para el sueldo necesario y para «Tu ficha».
      const fija = modo === 'llega' && estado.ficha !== 'peon';
      const conTipica = !fija && estado.superficie === SUPERFICIE_TIPICA;
      for (const b of el.superficie.querySelectorAll('button[data-superficie]')) {
        b.disabled = fija;
        const esTipica = b.dataset.superficie === SUPERFICIE_TIPICA;
        b.setAttribute('aria-pressed', String(esTipica ? conTipica : !conTipica && Number(b.dataset.superficie) === superficie));
      }
      let nota = '';
      if (fija) {
        nota = estado.ficha === 'llave'
          ? t('interfaz.sueldo.superficie_llave')
          : t('interfaz.sueldo.superficie_fija', { superficie: t.numero(superficie ?? 50) });
      } else if (sinEfecto) nota = t('interfaz.sueldo.supuestos_mapa');
      else if (soloMinimo) nota = t('interfaz.sueldo.superficie_minimo');
      if (conTipica && tipica) nota = [tipica, nota].filter(Boolean).join(' ');
      el.superficieNota.textContent = nota;
      el.superficieNota.hidden = !nota;
      marcarGrupo(el.umbral, 'umbral', Math.round(umbral * 100));
      // El umbral dice qué cuenta: solo el alquiler o, con el selector, también los otros gastos
      const conGastos = Boolean(gastos?.activo);
      if (el.umbralTitulo) el.umbralTitulo.textContent = t(conGastos ? 'interfaz.sueldo.umbral_gastos' : 'interfaz.sueldo.umbral');
      if (el.gastos) {
        el.gastos.checked = conGastos;
        el.gastos.disabled = !gastos?.disponible;
      }
      if (el.gastosNota) {
        el.gastosNota.textContent = gastos?.nota ?? '';
        el.gastosNota.hidden = !gastos?.nota;
      }
      // Rótulos con el formato del idioma («30 %» en castellano, «30%» en inglés)
      for (const b of el.umbral.querySelectorAll('button[data-umbral]')) b.textContent = t.porcentaje(Number(b.dataset.umbral) / 100);
      for (const b of el.superficie.querySelectorAll('button[data-superficie]')) {
        if (b.dataset.superficie !== SUPERFICIE_TIPICA) b.textContent = t('interfaz.sueldo.vivienda_m2', { superficie: t.numero(Number(b.dataset.superficie)) });
      }

      el.intro.textContent = modo === 'necesario' ? t('interfaz.sueldo.intro_necesario') : t('interfaz.sueldo.intro_llega');
      el.resumen.textContent = resumen ?? '';
      el.resumen.hidden = !resumen;
      // Aviso fijo junto al resultado de «¿te llega?» (decisión del autor, 12-nov-2026)
      const conAviso = Boolean(resumen) && modo === 'llega';
      if (el.aviso) el.aviso.hidden = !conAviso;
      el.resumen.classList.toggle('con-aviso', conAviso);
      el.detalle.textContent = detalle ?? '';
      el.detalle.hidden = !detalle;
      el.volver.hidden = modo === 'necesario';
    },
  };
}
