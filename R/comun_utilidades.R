# Utilidades comunes
# Convenciones del proyecto (docs/guia_de_trabajo.md), 6-nov-2026.

# Redondeo a un decimal. round() redondea al par en los empates y descuadra ±0,1
# respecto a las cifras publicadas; sprintf() no.
redondear_1 <- function(x) as.numeric(sprintf("%.1f", x))

# Redondeo a `decimales` con los empates hacia arriba (lejos del cero) sobre la cifra decimal. Las
# medias de cifras con pocos decimales caen en empates exactos (7,575; 3,465) que el binario guarda
# por debajo, y sprintf() los baja (7,57; 3,46). Precios de los portales (anualizar_portales()) y
# tipo del Banco de España del 17 (compraventa_tipo_bde(); plan §11, pregunta 59 b).
redondear_empate_arriba <- function(x, decimales = 2L) {
  f <- 10^decimales
  sign(x) * floor(abs(x) * f + 0.5 + 1e-7) / f
}

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
