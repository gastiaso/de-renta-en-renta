// Nombres de territorio. El INE escribe el artículo o el tipo de entidad detrás, tras una coma
// («Coruña, A», «Palmas de Gran Canaria, Las», «Madrid, Comunidad de», «Hospitalet de
// Llobregat, L'»). En pantalla van en orden natural («A Coruña», «Comunidad de Madrid»,
// «L'Hospitalet de Llobregat»); el buscador busca con las dos formas.

export function ordenNatural(nombre) {
  if (typeof nombre !== 'string') return nombre;
  const i = nombre.lastIndexOf(', ');
  if (i < 0) return nombre;
  const cabeza = nombre.slice(0, i);
  const cola = nombre.slice(i + 2);
  return cola.endsWith("'") ? `${cola}${cabeza}` : `${cola} ${cabeza}`;
}
