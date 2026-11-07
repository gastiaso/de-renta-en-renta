# Ficha «mochila» (joven de 26 a 35 años): opciones de método con la AEAT (plan §3.1, pregunta
# abierta 7). Todo en bruto anual; el paso a neto mensual viene después, con el método elegido.
#
# - A: mediana del salario medio estimado (SME, «año completo») de 26 a 35 años de la comunidad,
#      llevada a cada provincia con la posición de su salario medio real frente al de su comunidad.
# - B: salario medio real de la provincia × relación mediana/media del SME de su comunidad.
# - C: mediana del SME de la comunidad, sin escala provincial.
#
# La AEAT no publica la mediana del SME por comunidad y edad: solo cuántos asalariados de cada
# comunidad y edad caen en cada decil nacional, y los límites de los centiles nacionales. La
# mediana se interpola suponiendo que, dentro de cada decil nacional, la comunidad se reparte
# como el país (uniforme en sus diez centiles). comprobar_interpolacion_deciles() lo contrasta
# con los recuentos por centil que la AEAT sí da por comunidad (todas las edades).

EDAD_MOCHILA <- "De 26 a 35 años"

# Tablas de la AEAT que usa la ficha: título en el mapa de la estadística y filtros fijos.
TABLAS_AEAT_MOCHILA <- list(
  provincia = list("Asalariados, percepciones salariales y salarios por provincia, edad y sexo",
                   list(Sexo = "Total", `Tramos de Edad` = EDAD_MOCHILA)),
  deciles   = list("Distribución de asalariados por decilas, tramos de edad, CCAA y género", list(`Género` = "Total")),
  sme_edad  = list("Distribución de asalariados y Salario Medio Estimado Anual por tramos de edad, género y CCAA", list()),
  recorrido = list("Recorrido del Salario Medio Estimado en cada decila de población", list()),
  centiles  = list("Distribución de asalariados y Salario Medio Estimado Anual por centilas, género y CCAA", list())
)

descargar_aeat_mochila <- function(tabla, anio) {
  t <- TABLAS_AEAT_MOCHILA[[tabla]]
  descargar_aeat_mercado(anio, t[[1]], t[[2]])
}

clave_nombre <- function(x) gsub("_", "", nombre_columna(x))

# Curva de los centiles nacionales del SME: posición (0–100) → euros.
curva_centiles_sme <- function(recorrido) {
  c <- recorrido |>
    filter(grepl("^[0-9]+$", fila), columna %in% c("SME inferior", "SME superior")) |>
    mutate(k = as.integer(fila)) |>
    select(k, columna, valor) |>
    tidyr::pivot_wider(names_from = columna, values_from = valor) |>
    arrange(k)
  if (!identical(c$k, 1:100)) stop("La tabla del recorrido del SME no trae los 100 centiles", call. = FALSE)
  list(x = c(0, c$k), y = c(c$`SME inferior`[1], c$`SME superior`))
}

# Cuantil p de una distribución dada por recuentos en tramos consecutivos de la curva nacional:
# deciles (`ancho` = 10 centiles) o centiles (`ancho` = 1), uniforme dentro de cada tramo.
cuantil_tramos <- function(n, curva, p = 0.5, ancho = 10) {
  acum <- cumsum(n)
  objetivo <- p * sum(n)
  t <- which(acum >= objetivo)[1]
  previo <- if (t == 1) 0 else acum[t - 1]
  stats::approx(curva$x, curva$y, xout = ancho * (t - 1 + (objetivo - previo) / n[t]))$y
}

# Recuentos por decil nacional («Decil 5 Mediana» incluido) de cada comunidad y edad.
deciles_aeat <- function(deciles) {
  deciles |>
    filter(grepl("^Decil [0-9]+", fila)) |>
    transmute(geo = distribucion_geografica, edad = columna,
              decil = as.integer(sub("^Decil ([0-9]+).*$", "\\1", fila)), n = valor) |>
    arrange(geo, edad, decil)
}

# Opciones A, B y C por provincia (régimen común; sin Ceuta ni Melilla, que no están en el
# módulo de año completo). La tabla provincial trae España (nivel 0), comunidades (1) y
# provincias (2); las comunidades de una sola provincia no tienen fila de nivel 2.
calcular_mochila_opciones <- function(provincia, deciles, sme_edad, recorrido, edad = EDAD_MOCHILA) {
  curva <- curva_centiles_sme(recorrido)
  medianas <- deciles_aeat(deciles) |>
    filter(edad == !!edad) |>
    group_by(geo) |>
    summarise(n_sme = sum(n), mediana_sme = cuantil_tramos(n, curva), .groups = "drop")
  medias <- sme_edad |>
    filter(fila == edad, columna == "Total · SME") |>
    select(geo = distribucion_geografica, media_sme = valor)
  comunidades <- inner_join(medianas, medias, by = "geo") |>
    filter(geo != "Total") |>
    mutate(forma = mediana_sme / media_sme, k = clave_nombre(geo))

  p <- provincia |>
    filter(tramos_de_edad == edad, sexo == "Total", columna %in% c("Asalariados", "Salario Medio Anual")) |>
    select(fila, nivel_fila, columna, valor) |>
    tidyr::pivot_wider(names_from = columna, values_from = valor) |>
    mutate(grupo = cumsum(nivel_fila == 1))
  ccaa <- filter(p, nivel_fila == 1) |> select(grupo, comunidad = fila, real_ccaa = `Salario Medio Anual`)
  provincias <- p |>
    filter(nivel_fila >= 1) |>
    left_join(ccaa, by = "grupo") |>
    group_by(grupo) |>
    filter(nivel_fila == 2 | n() == 1) |>   # comunidades de una provincia: su propia fila
    ungroup() |>
    transmute(provincia = fila, comunidad, k = clave_nombre(comunidad), asalariados = Asalariados,
              real_prov = `Salario Medio Anual`, real_ccaa)

  provincias |>
    inner_join(select(comunidades, k, n_sme, mediana_sme, media_sme, forma), by = "k") |>
    mutate(A = mediana_sme * real_prov / real_ccaa,
           B = real_prov * forma,
           C = mediana_sme,
           A_sobre_B = A / B) |>
    select(-k)
}

# Comprobación del supuesto de la interpolación (todas las edades, cada comunidad): mediana
# desde los deciles frente a la mediana desde los recuentos por centil. Desviación en %.
comprobar_interpolacion_deciles <- function(deciles, centiles, recorrido) {
  curva <- curva_centiles_sme(recorrido)
  desde_deciles <- deciles_aeat(deciles) |>
    filter(edad == "Total") |>
    group_by(geo) |>
    summarise(con_deciles = cuantil_tramos(n, curva), .groups = "drop")
  desde_centiles <- centiles |>
    filter(grepl("^[0-9]+$", fila), columna == "Total · Número") |>
    mutate(k = as.integer(fila)) |>
    arrange(k) |>
    group_by(geo = distribucion_geografica) |>
    summarise(con_centiles = cuantil_tramos(valor, curva, ancho = 1), .groups = "drop")
  inner_join(desde_deciles, desde_centiles, by = "geo") |>
    transmute(id = "aeat_mediana_deciles", anio = NA_integer_, detalle = geo,
              calculado = 100 * (con_deciles / con_centiles - 1), referencia = 0)
}
