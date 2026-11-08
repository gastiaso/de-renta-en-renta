// «Compartir»: copia el enlace a la vista. Si hay un sueldo escrito, avisa antes de que el
// enlace lo lleve, y deja elegir entre copiarlo con el sueldo o sin él (plan, §6.6). El sueldo
// va tras «#»: el navegador no lo envía al servidor al abrir el enlace.

const $ = (id) => document.getElementById(id);

export function crearCompartir() {
  const dialogo = $('compartir');
  const aviso = $('compartir-aviso');
  const enlace = $('compartir-enlace');
  const con = $('compartir-con');
  const sin = $('compartir-sin');
  const hecho = $('compartir-hecho');
  let t;
  let enlaces = { con: null, sin: null };

  async function copiar(cual) {
    enlace.value = enlaces[cual];
    try {
      await navigator.clipboard.writeText(enlaces[cual]);
      hecho.textContent = t(cual === 'con' ? 'interfaz.compartir.copiado_con' : 'interfaz.compartir.copiado');
    } catch {
      enlace.select();
      hecho.textContent = t('interfaz.compartir.copia_a_mano');
    }
  }
  con.addEventListener('click', () => copiar('con'));
  sin.addEventListener('click', () => copiar('sin'));
  $('compartir-cerrar').addEventListener('click', () => dialogo.close());

  return {
    // `conSueldo` y `sinSueldo`: los dos enlaces; `sueldo`: el ingreso mensual que iría, o null.
    abrir({ t: traductor, conSueldo, sinSueldo, sueldo }) {
      t = traductor;
      enlaces = { con: conSueldo, sin: sinSueldo };
      enlace.value = sinSueldo;
      hecho.textContent = '';
      con.hidden = !sueldo;
      aviso.textContent = sueldo
        ? t('interfaz.compartir.aviso', { sueldo: t.numero(sueldo) })
        : t('interfaz.compartir.sin_sueldo');
      sin.textContent = t(sueldo ? 'interfaz.compartir.copiar_sin' : 'interfaz.compartir.copiar');
      dialogo.showModal();
      sin.focus();
    },
  };
}
