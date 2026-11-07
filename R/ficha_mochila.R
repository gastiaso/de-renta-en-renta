# Ficha «mochila» (joven de 26 a 35 años): mediana estimada del salario con la AEAT (plan §3.1).
# Pasos 1, 2 y 4 en bruto anual; el paso 3 (calcular_mochila_neta) lo lleva a neto mensual en 12.
#
# Opciones calculadas (pregunta abierta 7):
# - A: mediana del salario medio estimado (SME, «año completo») de 26 a 35 años de la comunidad,
#      llevada a cada provincia con la posición de su salario medio real frente al de su comunidad.
# - B: salario medio real de la provincia × relación mediana/media del SME de su comunidad.
#      Adoptada el 7-nov-2026: coincide con la mediana de la ECV; A queda alta (el SME anualiza
#      por días cotizados y deja fuera lo que no llega al SMI).
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
  centiles  = list("Distribución de asalariados y Salario Medio Estimado Anual por centilas, género y CCAA", list()),
  retenciones = list("GRUPOS DE POBLACIÓN POR LA NATURALEZA DE SUS RETRIBUCIONES", list())
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

# Método adoptado (B): bruto anual de 26 a 35 años por provincia. Es lo cobrado en el año, así
# que incluye a quien trabajó pocos meses.
calcular_mochila <- function(opciones) {
  opciones |>
    transmute(provincia, comunidad, asalariados, salario_medio = real_prov, forma, bruto_anual = B)
}

# Paso 3: de bruto anual a neto mensual repartido en 12 (regla 8) ---------------------------------

# Cotización del trabajador a la Seguridad Social por año de ingresos (régimen general, contrato
# indefinido): contingencias comunes 4,70 %, desempleo 1,55 %, formación profesional 0,10 % y
# mecanismo de equidad intergeneracional 0,12 % (2024). Con contrato temporal, el desempleo es
# del 1,60 % (6,52 % en total).
COTIZACION_TRABAJADOR <- c(`2024` = 0.0647)

# Retención del IRPF sobre el salario por territorio y tramo de renta anual (AEAT, «Grupos de
# población por la naturaleza de sus retribuciones», bloque de salarios). Se toman las personas
# que solo cobran salarios (columna «Asalariados»): su tramo de renta es el de su salario anual.
# Retribuciones y retenciones vienen en miles de euros. Una fila por territorio y tramo, ordenada
# por salario medio del tramo (euros), con el tipo de retención (proporción del salario).
retenciones_aeat <- function(grupos, columna = "Asalariados") {
  grupos |>
    filter(bloque == "SALARIOS", columna == !!columna, tramos_de_renta_anual != "Total",
           fila %in% c("Personas", "Retribuciones", "Retenciones")) |>
    select(geo = distribucion_geografica, tramo = tramos_de_renta_anual, fila, valor) |>
    tidyr::pivot_wider(names_from = fila, values_from = valor) |>
    filter(Personas > 0, Retribuciones > 0) |>
    transmute(geo, tramo, personas = Personas, salario_medio = 1000 * Retribuciones / Personas,
              retencion = Retenciones / Retribuciones) |>
    arrange(geo, salario_medio)
}

# Tipo de retención de un salario anual: interpolación lineal entre los salarios medios de los
# tramos de una curva (filas de retenciones_aeat() de un territorio); fuera de ellos, el tipo del
# tramo extremo.
tipo_retencion <- function(salario, curva) {
  stats::approx(curva$salario_medio, curva$retencion, xout = salario, rule = 2, ties = "ordered")$y
}

# Tipo de retención de cada salario con la curva de su territorio (clave_nombre(); «total» para
# España).
tipos_retencion <- function(salario, territorio, retenciones) {
  curvas <- split(retenciones, clave_nombre(retenciones$geo))
  k <- clave_nombre(territorio)
  faltan <- setdiff(unique(k), names(curvas))
  if (length(faltan) > 0) stop("Sin retenciones de la AEAT para: ", paste(faltan, collapse = ", "), call. = FALSE)
  unname(mapply(function(x, kk) tipo_retencion(x, curvas[[kk]]), salario, k))
}

# Neto anual = bruto × (1 − cotización − retención), con la retención que corresponde al bruto
# en la curva de su comunidad (en `retencion_espana`, la de la curva de España, como registro).
# Es la retención practicada en nómina, no la cuota final del IRPF. Neto mensual = neto anual / 12.
calcular_mochila_neta <- function(mochila, retenciones, cotizacion) {
  mochila |>
    mutate(cotizacion = cotizacion,
           retencion = tipos_retencion(bruto_anual, comunidad, retenciones),
           retencion_espana = tipos_retencion(bruto_anual, rep("Total", n()), retenciones),
           neto_anual = bruto_anual * (1 - cotizacion - retencion),
           neto_mensual = neto_anual / 12)
}

# Mediana con pesos: primer valor en que el peso acumulado llega a la mitad.
mediana_ponderada <- function(x, w) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  x[which(cumsum(w) / sum(w) >= 0.5)[1]]
}

# Control con la ECV (paso 5 del método): asalariados de 26 a 35 años con salario en el año de
# ingresos (PY010G > 0), con su comunidad (DB040), su factor (PB040), el salario neto de
# retenciones y cotizaciones (PY010N) y los meses trabajados por cuenta ajena (PL073 a tiempo
# completo, PL074 a tiempo parcial). La edad es la del final del año de ingresos (año de
# ingresos − año de nacimiento, PB140), como los tramos de la AEAT.
leer_ecv_asalariados <- function(rutas, anio_ingresos, edades = c(26L, 35L)) {
  ruta <- function(letra) rutas[grepl(sprintf("esudb\\d{2}%s\\.csv$", letra), rutas, ignore.case = TRUE)]
  p <- readr::read_csv(ruta("p"), col_select = c("PB030", "PB040", "PB140", "PY010G", "PY010N", "PL073", "PL074"),
                       col_types = readr::cols(.default = readr::col_double()), progress = FALSE)
  d <- readr::read_csv(ruta("d"), col_select = c("DB030", "DB040"),
                       col_types = readr::cols(DB030 = readr::col_double(), DB040 = readr::col_character()),
                       progress = FALSE)
  p |>
    mutate(DB030 = PB030 %/% 100, edad = anio_ingresos - PB140) |>
    inner_join(d, by = "DB030") |>
    filter(edad >= edades[1], edad <= edades[2], !is.na(PY010G), PY010G > 0) |>
    transmute(nuts2 = DB040, peso = PB040, bruto = PY010G, neto = PY010N,
              meses = dplyr::coalesce(PL073, 0) + dplyr::coalesce(PL074, 0))
}

# Medianas del bruto y del neto por comunidad y para España, con el número de observaciones y la
# parte (con pesos) que trabajó los doce meses.
resumir_ecv_asalariados <- function(asalariados) {
  bind_rows(mutate(asalariados, nuts2 = "ES"), asalariados) |>
    group_by(nuts2) |>
    summarise(n = n(), mediana_bruto = mediana_ponderada(bruto, peso),
              pct_anio_completo = 100 * sum(peso[meses >= 12]) / sum(peso),
              mediana_neto = mediana_ponderada(neto, peso), .groups = "drop")
}

# Mochila de cada comunidad (salario medio real de la comunidad × su relación mediana/media)
# frente a la mediana de la ECV. Desviación en %; alerta mochila_ecv.
comprobar_mochila_ecv <- function(opciones, ecv, ccaa) {
  comunidades <- opciones |>
    distinct(comunidad, real_ccaa, forma) |>
    mutate(mochila = real_ccaa * forma, k = clave_nombre(comunidad))
  ccaa |>
    transmute(nuts2, k = clave_nombre(nombre_ine)) |>
    inner_join(comunidades, by = "k") |>
    inner_join(ecv, by = "nuts2") |>
    transmute(id = "mochila_ecv", anio = NA_integer_, detalle = paste0(comunidad, " (n = ", n, ")"),
              calculado = 100 * (mochila / mediana_bruto - 1), referencia = 0)
}

# Control del paso 3 con la ECV: para cada comunidad (y España, con la curva del total), el neto
# calculado sobre la mediana del bruto de la ECV frente a la mediana del neto de la ECV (PY010N:
# salario menos retenciones y cotizaciones del trabajador). Separa el paso a neto de la diferencia
# en el bruto, que ya mide mochila_ecv. Desviación en %; alerta mochila_neto_ecv.
comprobar_neto_ecv <- function(retenciones, ecv, ccaa, cotizacion) {
  territorios <- ccaa |>
    transmute(nuts2, territorio = nombre_ine) |>
    bind_rows(tibble::tibble(nuts2 = "ES", territorio = "Total")) |>
    filter(clave_nombre(territorio) %in% clave_nombre(retenciones$geo))
  ecv |>
    inner_join(territorios, by = "nuts2") |>
    mutate(neto = mediana_bruto * (1 - cotizacion - tipos_retencion(mediana_bruto, territorio, retenciones))) |>
    transmute(id = "mochila_neto_ecv", anio = NA_integer_, detalle = paste0(territorio, " (n = ", n, ")"),
              calculado = 100 * (neto / mediana_neto - 1), referencia = 0)
}
