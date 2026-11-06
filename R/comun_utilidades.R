# Utilidades comunes
# Convenciones del proyecto (docs/guia_de_trabajo.md), 6-nov-2026.

# Redondeo a un decimal. round() redondea al par en los empates y descuadra ±0,1
# respecto a las cifras publicadas; sprintf() no.
redondear_1 <- function(x) as.numeric(sprintf("%.1f", x))

# Ceros a la izquierda en un código territorial leído como número.
con_ceros <- function(x, ancho) {
  ifelse(is.na(x), NA_character_, formatC(as.integer(x), width = ancho, flag = "0"))
}

# Código de sección censal de 10 dígitos: provincia (2), municipio (3), distrito (2), sección (3).
codigo_seccion <- function(provincia, municipio, distrito, seccion) {
  paste0(con_ceros(provincia, 2), con_ceros(municipio, 3), con_ceros(distrito, 2), con_ceros(seccion, 3))
}

# Ingreso neto mensual repartido en 12 a partir del bruto anual (plan, §3.1).
# `cotizaciones` y `retencion` son tipos (0,065 = 6,5 %).
neto_mensual <- function(bruto_anual, cotizaciones, retencion = 0) {
  bruto_anual * (1 - cotizaciones - retencion) / 12
}
