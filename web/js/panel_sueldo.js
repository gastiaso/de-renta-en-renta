// Tarjeta «Tu sueldo»: sueldo neto (12 o 14 pagas, segundo sueldo opcional), fichas, superficie,
// umbral, resumen y botones. El marcado está en index.html (textos con data-i18n); aquí se
// conectan los controles y se actualiza lo que cambia. El sueldo solo vive en memoria.

import { FICHAS_PERFIL, ingresoPeon } from './sueldo.js';

const $ = (id) => document.getElementById(id);

export function crearPanelSueldo({ alCambiar, alCompartir }) {
  const el = {
    neto: $('sueldo-neto'),
    segundo: $('sueldo-segundo'),
    pagas: $('sueldo-pagas'),
    fichas: $('sueldo-fichas'),
    superficie: $('sueldo-superficie'),
    superficieNota: $('sueldo-superficie-nota'),
    umbral: $('sueldo-umbral'),
    intro: $('sueldo-intro'),
    resumen: $('sueldo-resumen'),
    detalle: $('sueldo-detalle'),
    volver: $('sueldo-volver'),
    compartir: $('sueldo-compartir'),
  };
  let pagas = 12;
  let espera = null;

  const numero = (input) => {
    const x = Number(String(input.value).replace(',', '.'));
    return Number.isFinite(x) && x > 0 ? x : null;
  };
  const sueldoEscrito = () => {
    const s = { neto: numero(el.neto), pagas, segundo: numero(el.segundo) };
    return ingresoPeon(s) ? s : null;
  };
  const avisarSueldo = () => {
    clearTimeout(espera);
    espera = setTimeout(() => alCambiar({ sueldo: sueldoEscrito(), escrito: true }), 300);
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
    if (boton && !boton.disabled) alCambiar({ superficie: Number(boton.dataset.superficie) });
  });
  el.umbral.addEventListener('click', (e) => {
    const boton = e.target.closest('button[data-umbral]');
    if (boton) alCambiar({ umbral: Number(boton.dataset.umbral) });
  });
  el.volver.addEventListener('click', () => {
    el.neto.value = '';
    el.segundo.value = '';
    alCambiar({ ficha: null, sueldo: null, volver: true });
  });
  el.compartir.addEventListener('click', alCompartir);

  function marcarGrupo(grupo, dato, valor) {
    for (const b of grupo.querySelectorAll(`button[data-${dato}]`)) b.setAttribute('aria-pressed', String(Number(b.dataset[dato]) === valor));
  }

  return {
    // Rellena los campos con un sueldo que llega de un enlace compartido.
    ponerSueldo(sueldo) {
      if (!sueldo) return;
      el.neto.value = String(sueldo.neto);
      el.segundo.value = sueldo.segundo ? String(sueldo.segundo) : '';
      pagas = sueldo.pagas === 14 ? 14 : 12;
      marcarGrupo(el.pagas, 'pagas', pagas);
    },
    // `vista`: { t, estado, sueldo, perfiles, modo, superficie, umbral, resumen, detalle,
    // sinEfecto } (sinEfecto: el mapa activo no usa la superficie ni el umbral).
    pintar({ t, estado, sueldo, perfiles, modo, superficie, umbral, resumen, detalle, sinEfecto = false }) {
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
      for (const b of el.superficie.querySelectorAll('button[data-superficie]')) {
        b.disabled = fija;
        b.setAttribute('aria-pressed', String(Number(b.dataset.superficie) === superficie));
      }
      let nota = '';
      if (fija) {
        nota = estado.ficha === 'llave'
          ? t('interfaz.sueldo.superficie_llave')
          : t('interfaz.sueldo.superficie_fija', { superficie: t.numero(superficie ?? 50) });
      } else if (sinEfecto) nota = t('interfaz.sueldo.supuestos_mapa');
      el.superficieNota.textContent = nota;
      el.superficieNota.hidden = !nota;
      marcarGrupo(el.umbral, 'umbral', Math.round(umbral * 100));

      el.intro.textContent = modo === 'necesario' ? t('interfaz.sueldo.intro_necesario') : t('interfaz.sueldo.intro_llega');
      el.resumen.textContent = resumen ?? '';
      el.resumen.hidden = !resumen;
      el.detalle.textContent = detalle ?? '';
      el.detalle.hidden = !detalle;
      el.volver.hidden = modo === 'necesario';
    },
  };
}
