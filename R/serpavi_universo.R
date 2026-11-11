# Universo del SERPAVI (backlog, tarea 42; nota §7.1 y §8). Según su metodología oficial (MIVAU,
# «Sistema Estatal de Referencia del Precio del Alquiler de Vivienda. Explotación estadística de
# fuentes tributarias. Metodología», 18-mar-2026, a la que remite la Resolución de 16 de abril de
# 2026, BOE-A-2026-8691), el SERPAVI solo cuenta los inmuebles con ingresos por arrendamiento de
# titulares que son personas físicas, declarados en el modelo 100 del IRPF (109 en Gipuzkoa) como
# vivienda habitual del inquilino, no afectos a una actividad económica y sin parentesco entre las
# partes (pp. 6, 8 y 17). Quedan fuera las sociedades y demás personas jurídicas (también la vivienda
# pública), el alquiler no declarado, el alquiler a parientes, el que el arrendador declara como
# actividad económica y, en territorio común, los inmuebles cuyos titulares residen todos en
# territorio foral o en el extranjero (p. 6).
#
# No hay tabla abierta del parque alquilado por tipo de arrendador por municipio: el Censo 2021 no
# distingue al arrendador y las estadísticas de titularidad del Catastro cuentan todo el parque
# residencial, no el alquilado. Este contraste compara, en las mismas secciones y el mismo año
# (2021), las viviendas alquiladas que cuenta el SERPAVI (testigos de vivienda colectiva y
# unifamiliar) con los hogares en alquiler del Censo 2021. La diferencia no aísla a las personas
# jurídicas: mezcla lo que el SERPAVI deja fuera con diferencias de la otra fuente en los dos
# sentidos (el Censo cuenta hogares a 1 de enero, con la tenencia imputada en una cuarta parte de
# ellos; el SERPAVI cuenta inmuebles alquilados algún momento del año, también los de estudiantes
# empadronados en otro sitio).

# Contraste del SERPAVI con el Censo 2021. `larga_serpavi`: la tabla larga del SERPAVI (usa
# contratos_alquiler de las secciones); `censo`: el objetivo censo2021 (columnas seccion y alquiler).
# Solo entran las secciones con las dos cifras: sin País Vasco (fuera del SERPAVI en 2021), sin las
# secciones del Censo en secreto y sin las que el SERPAVI trae vacías en alguna tipología.
# Devuelve una lista: `espana` (secciones, contratos, hogares y cobertura, en %), `provincias` (lo
# mismo por provincia, de menor a mayor cobertura), `municipios` (municipios con todas sus secciones
# con las dos cifras y al menos `minimo` hogares en alquiler) y `resumen_municipios` (cuantiles de su
# cobertura, sin ponderar y ponderados por hogares en alquiler, y cuántos quedan por debajo del 50 %
# y por encima del 100 %).
serpavi_contraste_censo <- function(larga_serpavi, censo, anio_ref = 2021L, minimo = 100) {
  contratos <- larga_serpavi |>
    dplyr::filter(.data$nivel == "sc", .data$indicador == "contratos_alquiler", .data$anio == anio_ref) |>
    dplyr::group_by(seccion = .data$geo_id) |>
    dplyr::summarise(contratos = if (all(.data$estado == "dato")) sum(.data$valor) else NA_real_, .groups = "drop")
  todas <- censo |>
    dplyr::select("seccion", hogares = "alquiler") |>
    dplyr::left_join(contratos, by = "seccion") |>
    dplyr::mutate(provincia = substr(.data$seccion, 1, 2), municipio = substr(.data$seccion, 1, 5),
                  completa = !is.na(.data$hogares) & !is.na(.data$contratos))
  d <- dplyr::filter(todas, .data$completa)
  sumar <- function(x, por = character()) {
    x |>
      dplyr::group_by(dplyr::across(dplyr::all_of(por))) |>
      dplyr::summarise(secciones = dplyr::n(), contratos = sum(.data$contratos), hogares = sum(.data$hogares),
                       .groups = "drop") |>
      dplyr::mutate(cobertura = 100 * .data$contratos / .data$hogares)
  }
  espana <- sumar(d)
  provincias <- sumar(d, "provincia") |> dplyr::arrange(.data$cobertura)
  municipios <- todas |>
    dplyr::group_by(.data$municipio) |>
    dplyr::filter(all(.data$completa)) |>
    dplyr::ungroup() |>
    sumar("municipio") |>
    dplyr::filter(.data$hogares >= minimo) |>
    dplyr::arrange(.data$cobertura)
  ponderado <- function(p) {
    o <- order(municipios$cobertura)
    acumulado <- cumsum(municipios$hogares[o]) / sum(municipios$hogares)
    municipios$cobertura[o][which(acumulado >= p)[1]]
  }
  probs <- c(0.1, 0.25, 0.5, 0.75, 0.9)
  resumen <- tibble::tibble(
    cuantil = probs,
    municipios = unname(stats::quantile(municipios$cobertura, probs, type = 7)),
    ponderado = vapply(probs, ponderado, numeric(1))
  )
  list(espana = espana, provincias = provincias, municipios = municipios,
       resumen_municipios = list(n = nrow(municipios), cuantiles = resumen,
                                 bajo_50 = sum(municipios$cobertura < 50),
                                 sobre_100 = sum(municipios$cobertura > 100)))
}
