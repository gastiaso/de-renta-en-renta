# Diseño · tablero «De renta en renta»

| Fichero | Contenido |
|---|---|
| `tokens.json` | Colores con contrastes WCAG calculados, rampa secuencial, colores de las fichas (objeto y texto), tipografías, formas y límites |
| `fichas/*.svg` | Las cinco fichas (64 × 64): llave, mochila, tartera, transistor y peón |

Reglas:

- Texto normal con 4,5:1 como mínimo. Los dos primeros pasos de la rampa no llegan a 3:1 sobre la crema: en los mapas, siempre con contorno o sobre el mar.
- El color propio de cada ficha es decorativo; para texto, la variante «texto» de `tokens.json`.
- Sobre fondo oscuro, la ficha va sobre una placa crema.
- Tipografías libres: Jost, Marcellus SC y Archivo Narrow (OFL) y Yellowtail (Apache 2.0, no OFL), autoalojadas en `web/estilo/fuentes/` con su licencia. Yellowtail solo en titulares de 22 px o más.
- Nada de elementos propios de Monopoly (sus fichas, sus esquinas, la banda diagonal del título ni los nombres de sus mazos). Referente de dominio público: *The Landlord's Game* (Lizzie Magie, 1904).

Las maquetas (`docs/maquetas.md`) son referencia visual; las cifras que llevan son de ejemplo.

`web/estilo/tokens.css` se genera desde `tokens.json` (`generar_tokens_css()`); las compuertas `contraste_texto`, `contraste_declarado` y `rampa_contorno` recalculan los contrastes WCAG en cada ejecución.
