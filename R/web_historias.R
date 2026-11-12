# Primeras historias (backlog, tarea 49; decisiones del autor del 11-nov-2026): recorridos guiados
# dentro del mapa (web/mapa.html), paso a paso. Cada paso fija la vista del mapa (mapa, año, encuadre,
# territorio y escala) y lleva un texto en castellano y en inglés con marcas {id} que se rellenan con
# cifras calculadas aquí, desde la tabla larga, la tabla del histórico y los cortes de la web.
#
#   inventario/historias.csv         una fila por paso: textos, fuente, vista del mapa y enlace opcional;
#                                    el título y la entradilla de la historia, en su paso 1. Columnas
#                                    opcionales `nota_es` y `nota_en`: la nota «Cómo se mide» del paso
#                                    (los matices de método, fuera del cuerpo), con marcas {id} como el
#                                    texto; en los dos idiomas o en ninguno. Columna opcional `ficha`:
#                                    una ficha de perfil (llave, mochila, tartera o transistor; nunca
#                                    el peón, que es el sueldo de quien visita) que deja el mapa en
#                                    «¿te llega?» con ella; vacía, el modo normal.
#   inventario/historias_cifras.csv  una fila por cifra: la consulta que la calcula y la cifra tal como
#                                    se redactó el texto (`redactado`, ya redondeada a `decimales`); el
#                                    grupo de la tabla larga, como «corte:grupo» (tipologia:VC) o vacío
#                                    para el total.
#
# Registro (decisión del autor, 11-nov-2026, tras la lectura con seis perfiles): las historias van en
# lenguaje llano, con una idea, una o dos cifras y un lugar con nombre por paso; siguen sin
# valoraciones ni recomendaciones. Lo técnico va a la nota del paso.
#
# Consultas (columna `consulta`):
#   valor                      la cifra de un territorio (geo_id), en cualquier nivel
#   maximo, minimo, *_geo,     sobre los territorios del nivel; con geo_id, solo los que empiezan por
#   cuenta_desde,              ese código (los distritos de un municipio, los municipios de una
#   cociente_p90_p10           provincia)
#   secciones_*                secciones de un territorio (las que empiezan por geo_id: una provincia,
#                              un municipio) o de España (00). secciones_cuota_mayor: % de secciones
#                              por encima del parámetro (estrictamente, como «pasa del 30 %» de la
#                              carta del salario mínimo de la portada)
#   panel_n, panel_cuenta_desde, panel_cuantil
#                              lo mismo con panel constante: solo los territorios con dato en `anio`
#                              y en otro año. Parámetro «valor;año;decimales»: el umbral o el cuantil
#                              (vacío en panel_n), el otro año y, si se dan, los decimales a que se
#                              redondea cada valor antes de contar (los que enseña el mapa)
#   corte_mayor                último corte de un juego de la web
#   hist_*                     tabla del histórico
#   ipc_variacion              subida del IPC (media anual) de `parametro` a `anio`, en %. El IPC no
#                              deflacta ninguna cifra: se da al lado de la subida en euros de cada año
#   derivada_variacion, derivada_diferencia
#                              de dos cifras de la misma tabla (parámetro «id_final;id_inicial»),
#                              desde sus valores ya redondeados, como los lee quien sigue la historia
#   derivada_por               una cifra de la tabla, ya redondeada, por un número (parámetro
#                              «id;factor»: la entrada del 20 % en meses de renta, años × 0,2 × 12)
#   perfil_ingreso             ingreso neto mensual de una ficha de perfil (indicador = ficha, geo_id,
#                              anio), el que recibe la web (perfiles_web())
#   portada_smi                una cifra de la carta del salario mínimo de la portada (cifras_portada(),
#                              R/web_portada.R) calculada para `anio`: parámetro = su campo (pct_30,
#                              pct_30_real, secciones...). La misma definición que la portada, no otra
#
# Compuerta (validacion_historias, bloqueo): cada cifra calculada, redondeada, coincide con la
# redactada. Si una actualización de los datos la mueve, el pipeline para y el texto se revisa a mano
# antes de publicarlo: las frases («la más alta desde 2011», «el primero es…») no se reescriben solas.
# Las cifras que solo sostienen una frase (el año del máximo, el municipio que encabeza) van también
# como cifras, aunque no se impriman. Además: marcas sin cifra, textos vacíos, vistas que no puede
# pintar el mapa, fichas que no son de perfil (el peón no) y ninguna cifra ni mapa de la oferta
# privada (Idealista: decisiones 17 a 19).
# La brecha entre entrar y quedarse queda aplazada hasta la autorización de Idealista.
#
# Salida: web/datos/historias.json (fuera de git), con las cifras ya escritas en cada idioma.

FICHERO_HISTORIAS_WEB <- "historias.json"

HISTORIAS_CONSULTAS <- c(
  # tabla larga, territorios de un nivel (nivel, anio; geo_id: el territorio en "valor" y, en las
  # demas, el prefijo que los limita)
  "valor", "maximo", "minimo", "maximo_geo", "minimo_geo", "cuenta_desde", "cociente_p90_p10",
  # tabla larga, panel constante entre dos anios (parametro "valor;anio;decimales")
  "panel_n", "panel_cuenta_desde", "panel_cuantil",
  # tabla larga, secciones de un municipio (geo_id de cinco cifras) o de toda Espa\u00f1a (geo_id 00)
  "secciones_n", "secciones_mediana", "secciones_cuantil", "secciones_cuota_desde", "secciones_cuota_mayor",
  # ingreso de una ficha de perfil (perfiles_web()) y la carta del salario minimo de la portada
  "perfil_ingreso", "portada_smi",
  # IPC (indicador = ipc; anio = final; parametro = inicial)
  "ipc_variacion",
  # de otras dos cifras (parametro "id_final;id_inicial")
  "derivada_variacion", "derivada_diferencia", "derivada_por",
  # inventario/cortes_web_niveles.csv (nivel = juego: seccion, municipio, provincia_ccaa)
  "corte_mayor",
  # tabla del historico (indicador = serie; parametro de hist_valor = subperiodo)
  "hist_valor", "hist_maximo", "hist_maximo_anio", "hist_maximo_subperiodo",
  "hist_minimo_desde", "hist_minimo_desde_anio", "hist_minimo_desde_subperiodo",
  "hist_ultimo", "hist_ultimo_anio", "hist_ultimo_subperiodo",
  "hist_mayor_desde_anio", "hist_mayor_desde_subperiodo"
)

HISTORIAS_COLUMNAS <- c("historia", "paso", "historia_titulo_es", "historia_titulo_en", "entradilla_es", "entradilla_en",
                        "titulo_es", "titulo_en", "texto_es", "texto_en", "fuente_es", "fuente_en",
                        "mapa", "anio", "vista", "territorio", "escala", "enlace", "enlace_es", "enlace_en")
HISTORIAS_COLUMNAS_NOTA <- c("nota_es", "nota_en")   # opcionales: sin ellas, pasos sin nota
# Fichas de perfil que puede fijar un paso (columna opcional `ficha`): las del pipeline, nunca el peon
HISTORIAS_FICHAS <- c("llave", "mochila", "tartera", "transistor")
HISTORIAS_CIFRAS_COLUMNAS <- c("id", "historia", "consulta", "indicador", "nivel", "geo_id", "anio", "grupo",
                               "parametro", "decimales", "redactado", "nota")

# Mismas expresiones que web/js/estado.js (VALIDAS)
HISTORIAS_RE_ESTADO <- c(
  mapa = "^[a-z0-9_]{1,40}$",
  anio = "^(19|20)[0-9]{2}$",
  vista = "^[0-9]{1,2}(\\.[0-9]+)?/-?[0-9]{1,2}(\\.[0-9]+)?/-?[0-9]{1,3}(\\.[0-9]+)?$",
  territorio = "^((ccaa|provincia):[0-9]{2}|municipio:[0-9]{5})$",
  escala = "^municipio$",
  historia = "^[a-z0-9_]{1,30}$"
)

leer_historias <- function(ruta) {
  x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = character())
  faltan <- setdiff(HISTORIAS_COLUMNAS, names(x))
  if (length(faltan)) stop("Faltan columnas en ", ruta, ": ", paste(faltan, collapse = ", "), call. = FALSE)
  for (opcional in c(HISTORIAS_COLUMNAS_NOTA, "ficha")) if (!opcional %in% names(x)) x[[opcional]] <- ""
  x$paso <- as.integer(x$paso)
  x
}

leer_historias_cifras <- function(ruta) {
  x <- readr::read_csv(ruta, col_types = readr::cols(.default = "c"), na = character())
  faltan <- setdiff(HISTORIAS_CIFRAS_COLUMNAS, names(x))
  if (length(faltan)) stop("Faltan columnas en ", ruta, ": ", paste(faltan, collapse = ", "), call. = FALSE)
  x$decimales <- as.integer(x$decimales)
  x$redactado <- as.numeric(x$redactado)
  x
}

# --- Cifras ----------------------------------------------------------------------------------------

# Una cifra de la tabla larga. `d`: filas del indicador, ya sin valores vacíos.
historias_cifra_larga <- function(f, d) {
  d <- d[d$nivel == f$nivel, ]
  if (nzchar(f$grupo)) {
    corte_grupo <- strsplit(f$grupo, ":", fixed = TRUE)[[1]]   # "tipologia:VC"
    d <- d[d$corte %in% corte_grupo[1] & d$grupo %in% corte_grupo[2], ]
  } else d <- d[d$grupo %in% c("total", NA), ]
  if (startsWith(f$consulta, "panel_")) return(historias_cifra_panel(f, d))
  d <- d[d$anio == as.integer(f$anio), ]
  p <- suppressWarnings(as.numeric(f$parametro))
  if (startsWith(f$consulta, "secciones_")) {
    if (f$geo_id != "00") d <- d[startsWith(d$geo_id, f$geo_id), ]   # una provincia, un municipio...
    x <- d$valor
    if (!length(x)) return(NA_real_)
    return(switch(f$consulta,
                  secciones_n = length(x),
                  secciones_mediana = stats::median(x),
                  secciones_cuantil = stats::quantile(x, p, names = FALSE),
                  secciones_cuota_desde = 100 * mean(x >= p),
                  secciones_cuota_mayor = 100 * mean(x > p),
                  NA_real_))
  }
  if (f$consulta == "valor") {
    v <- d$valor[d$geo_id == f$geo_id]
    return(if (length(v) == 1) v else NA_real_)
  }
  if (nzchar(f$geo_id)) d <- d[startsWith(d$geo_id, f$geo_id), ]   # los distritos de un municipio, etc.
  x <- d$valor
  if (!length(x)) return(NA_real_)
  switch(f$consulta,
         maximo = max(x),
         minimo = min(x),
         maximo_geo = as.numeric(d$geo_id[which.max(x)]),
         minimo_geo = as.numeric(d$geo_id[which.min(x)]),
         cuenta_desde = sum(x >= p),
         cociente_p90_p10 = stats::quantile(x, 0.9, names = FALSE) / stats::quantile(x, 0.1, names = FALSE),
         NA_real_)
}

# Consultas con panel constante. `d`: filas del indicador, del nivel y del grupo, de todos los años.
# Cuentan solo los territorios con dato en el año de la cifra y en el otro año (segundo trozo del
# parámetro); con un tercer trozo, cada valor se redondea antes a esos decimales, los que enseña el
# mapa, para que la cuenta sea la que puede hacer quien lo mira.
historias_cifra_panel <- function(f, d) {
  pp <- suppressWarnings(as.numeric(strsplit(f$parametro, ";", fixed = TRUE)[[1]]))
  otro <- if (length(pp) >= 2) as.integer(pp[2]) else NA_integer_
  if (is.na(otro)) return(NA_real_)
  if (nzchar(f$geo_id)) d <- d[startsWith(d$geo_id, f$geo_id), ]
  a <- d[d$anio == as.integer(f$anio), ]
  x <- a$valor[a$geo_id %in% d$geo_id[d$anio == otro]]
  if (!length(x)) return(if (f$consulta == "panel_cuantil") NA_real_ else 0)
  if (length(pp) >= 3 && !is.na(pp[3])) x <- redondear_empate_arriba(x, as.integer(pp[3]))
  switch(f$consulta,
         panel_n = length(x),
         panel_cuenta_desde = if (is.na(pp[1])) NA_real_ else sum(x >= pp[1]),
         panel_cuantil = if (is.na(pp[1])) NA_real_ else stats::quantile(x, pp[1], names = FALSE),
         NA_real_)
}

# Una cifra de la tabla del histórico. `h`: filas de la serie y el territorio, en orden.
historias_cifra_hist <- function(f, h) {
  if (!nrow(h)) return(NA_real_)
  fila <- function(i) if (length(i) == 1 && !is.na(i)) h[i, ] else NULL
  r <- switch(sub("_(anio|subperiodo)$", "", f$consulta),
              hist_valor = fila(which(h$anio == as.integer(f$anio) & h$subperiodo == as.integer(f$parametro))),
              hist_maximo = fila(which.max(h$valor)),
              hist_minimo_desde = {
                desde <- which(h$anio >= as.integer(f$anio))
                fila(desde[which.min(h$valor[desde])])
              },
              hist_ultimo = fila(nrow(h)),
              hist_mayor_desde = {
                previos <- which(h$valor[-nrow(h)] >= h$valor[nrow(h)])
                fila(if (length(previos)) max(previos) else NA_integer_)
              },
              NULL)
  if (is.null(r)) return(NA_real_)
  if (endsWith(f$consulta, "_anio")) return(as.numeric(r$anio))
  if (endsWith(f$consulta, "_subperiodo")) return(as.numeric(r$subperiodo))
  if (f$consulta == "hist_mayor_desde") return(NA_real_)   # solo existe con _anio o _subperiodo
  as.numeric(r$valor)
}

# Subida del IPC entre dos años, en %. `ipc`: tabla de ipc_leer() (anio, indice).
historias_cifra_ipc <- function(f, ipc) {
  if (is.null(ipc)) return(NA_real_)
  fin <- ipc$indice[ipc$anio == suppressWarnings(as.integer(f$anio))]
  ini <- ipc$indice[ipc$anio == suppressWarnings(as.integer(f$parametro))]
  if (length(fin) == 1 && length(ini) == 1) 100 * (fin / ini - 1) else NA_real_
}

# Cifras derivadas de otras dos de la tabla («id_final;id_inicial»), desde sus valores ya redondeados
# a sus decimales, como en los derivados de la web. Una derivada no puede salir de otra derivada.
historias_derivar <- function(cifras) {
  derivadas <- which(startsWith(cifras$consulta, "derivada_"))
  for (i in derivadas) {
    ids <- strsplit(cifras$parametro[i], ";", fixed = TRUE)[[1]]
    if (cifras$consulta[i] == "derivada_por") {
      # "id;factor": la cifra ya redondeada, por un numero
      j <- match(ids[1], cifras$id)
      factor <- suppressWarnings(as.numeric(ids[2]))
      if (length(ids) != 2 || is.na(j) || j %in% derivadas || is.na(factor)) next
      cifras$calculado[i] <- redondear_empate_arriba(cifras$calculado[j], cifras$decimales[j]) * factor
      next
    }
    j <- match(ids, cifras$id)
    if (length(ids) != 2 || anyNA(j) || any(j %in% derivadas)) next
    terminos <- redondear_empate_arriba(cifras$calculado[j], cifras$decimales[j])
    cifras$calculado[i] <- switch(cifras$consulta[i],
                                  derivada_variacion = 100 * (terminos[1] / terminos[2] - 1),
                                  derivada_diferencia = terminos[1] - terminos[2],
                                  NA_real_)
  }
  cifras
}

# Ingreso neto mensual de una ficha de perfil (indicador = ficha) en un año y territorio, el que
# recibe la web. `ingresos`: perfiles_web(perfiles), o NULL.
historias_cifra_perfil <- function(f, ingresos) {
  v <- ((ingresos[[f$indicador]]$anios %||% list())[[f$anio]] %||% list())[[f$geo_id]]
  if (is.null(v)) NA_real_ else as.numeric(v)
}

# Cartas del salario minimo de la portada (cifras_portada(), R/web_portada.R) de cada año pedido: la
# tabla larga hasta ese año, para que el «último año» de la carta sea el de la cifra. Solo las series
# que usa la carta del salario minimo; la de la sobrecarga queda fuera (sus avisos, callados).
historias_cartas_smi <- function(cifras, larga, perfiles) {
  anios <- unique(cifras$anio[cifras$consulta == "portada_smi"])
  if (!length(anios) || is.null(perfiles)) return(list())
  base <- larga[larga$indicador %in% c("peso_alquiler_ingreso", "alquiler_mes", "sueldo_necesario"), ]
  stats::setNames(lapply(anios, function(a) {
    smi <- tryCatch(suppressWarnings(cifras_portada(base[base$anio <= as.integer(a), ], perfiles = perfiles)$smi),
                    error = function(e) NULL)
    if (is.null(smi) || !identical(as.integer(smi$anio), as.integer(a))) NULL else smi
  }), anios)
}

# Calcula todas las cifras: columna `calculado` (sin redondear). `ipc`: tabla del IPC (ipc_leer()),
# solo para las consultas ipc_variacion; `perfiles`: el objetivo del pipeline, solo para
# perfil_ingreso y portada_smi.
historias_calcular <- function(cifras, larga, historico, cortes_niveles, ipc = NULL, perfiles = NULL) {
  usados <- unique(cifras$indicador)
  l <- larga[larga$indicador %in% usados & !is.na(larga$valor), c("geo_id", "nivel", "anio", "indicador", "valor", "corte", "grupo")]
  h <- historico[historico$serie %in% usados, ]
  ingresos <- if (is.null(perfiles) || !any(cifras$consulta == "perfil_ingreso")) NULL else perfiles_web(perfiles)
  cartas <- historias_cartas_smi(cifras, larga, perfiles)
  cifras$calculado <- vapply(seq_len(nrow(cifras)), function(i) {
    f <- cifras[i, ]
    if (!f$consulta %in% HISTORIAS_CONSULTAS || startsWith(f$consulta, "derivada_")) return(NA_real_)
    if (f$consulta == "perfil_ingreso") return(historias_cifra_perfil(f, ingresos))
    if (f$consulta == "portada_smi") {
      v <- cartas[[f$anio]][[f$parametro]]
      return(if (is.numeric(v) && length(v) == 1) as.numeric(v) else NA_real_)
    }
    if (f$consulta == "corte_mayor") {
      cc <- cortes_niveles$cortes[cortes_niveles$indicador == f$indicador & cortes_niveles$juego == f$nivel]
      return(if (length(cc) == 1) max(cortes_web(cc)) else NA_real_)
    }
    if (f$consulta == "ipc_variacion") return(historias_cifra_ipc(f, ipc))
    if (startsWith(f$consulta, "hist_")) {
      hh <- h[h$serie == f$indicador & h$geo_id == f$geo_id, ]
      return(historias_cifra_hist(f, hh[order(hh$anio, hh$subperiodo), ]))
    }
    as.numeric(historias_cifra_larga(f, l[l$indicador == f$indicador, ]))
  }, numeric(1))
  historias_derivar(cifras)
}

# Cifra escrita: redondeo con los empates hacia arriba y separadores de cada idioma (2.421,5 · 2,421.5).
historias_formatear <- function(x, decimales, idioma = c("es", "en")) {
  idioma <- match.arg(idioma)
  formatC(redondear_empate_arriba(x, decimales), format = "f", digits = decimales,
          big.mark = if (idioma == "es") "." else ",", decimal.mark = if (idioma == "es") "," else ".")
}

historias_marcas <- function(texto) {
  unique(regmatches(texto, gregexpr("(?<=\\{)[a-z0-9_]+(?=\\})", texto, perl = TRUE))[[1]])
}

# Rellena las marcas {id} con las cifras de `cifras` (calculadas). Las marcas sin cifra se quedan.
historias_rellenar <- function(texto, cifras, idioma) {
  for (id in historias_marcas(texto)) {
    i <- match(id, cifras$id)
    if (is.na(i) || is.na(cifras$calculado[i])) next
    texto <- gsub(paste0("{", id, "}"), historias_formatear(cifras$calculado[i], cifras$decimales[i], idioma),
                  texto, fixed = TRUE)
  }
  texto
}

# --- Exportación ----------------------------------------------------------------------------------

historias_web <- function(historias, cifras) {
  bilingue <- function(fila, campo) {
    list(es = historias_rellenar(fila[[paste0(campo, "_es")]], cifras, "es"),
         en = historias_rellenar(fila[[paste0(campo, "_en")]], cifras, "en"))
  }
  if (!"ficha" %in% names(historias)) historias$ficha <- ""   # columna opcional
  ids <- unique(historias$historia)
  lapply(ids, function(id) {
    h <- historias[historias$historia == id, ]
    h <- h[order(h$paso), ]
    primero <- h[1, ]
    list(
      id = id,
      titulo = list(es = primero$historia_titulo_es, en = primero$historia_titulo_en),
      entradilla = list(es = primero$entradilla_es, en = primero$entradilla_en),
      pasos = lapply(seq_len(nrow(h)), function(k) {
        p <- h[k, ]
        estado <- list(mapa = p$mapa, anio = as.integer(p$anio), vista = p$vista)
        if (nzchar(p$territorio)) estado$territorio <- p$territorio
        if (nzchar(p$escala)) estado$escala <- p$escala
        if (nzchar(p$ficha)) estado$ficha <- p$ficha   # mapa en "te llega" con esa ficha
        list(
          titulo = bilingue(p, "titulo"),
          texto = bilingue(p, "texto"),
          estado = estado,
          enlace = if (nzchar(p$enlace)) list(href = p$enlace, texto = list(es = p$enlace_es, en = p$enlace_en)) else NULL,
          fuente = bilingue(p, "fuente"),
          nota = if (nzchar(p$nota_es) && nzchar(p$nota_en)) bilingue(p, "nota") else NULL
        )
      })
    )
  })
}

exportar_historias <- function(historias, cifras, dir_web = "web") {
  dir <- file.path(dir_web, "datos")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ruta <- file.path(dir, FICHERO_HISTORIAS_WEB)
  datos <- list(generado = format(Sys.Date()), historias = historias_web(historias, cifras))
  con <- file(ruta, open = "wb")
  writeLines(jsonlite::toJSON(datos, auto_unbox = TRUE, digits = NA, pretty = TRUE, null = "null"), con, useBytes = TRUE)
  close(con)
  ruta
}

# --- Compuerta -------------------------------------------------------------------------------------

# `manifiesto`: el de la web (lista); `claves_estado`: claves_estado_web(); `anclas`: anclas por página
# (anclas_paginas_web); `larga`: para la fuente de las cifras; `indicadores`: inventario/indicadores.csv.
comprobar_historias <- function(historias, cifras, manifiesto, claves_estado, anclas, larga, indicadores) {
  cuenta <- function(id, detalle, n) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(n), referencia = 0)
  # 1. Cifras: la calculada, redondeada, es la redactada
  c1 <- tibble::tibble(id = "historias_cifras", detalle = paste0(cifras$historia, ": ", cifras$id),
                       calculado = redondear_empate_arriba(cifras$calculado, cifras$decimales),
                       referencia = cifras$redactado)

  # 2. Textos
  campos <- c("titulo", "texto", "fuente")
  for (opcional in c(HISTORIAS_COLUMNAS_NOTA, "ficha")) if (!opcional %in% names(historias)) historias[[opcional]] <- ""
  # Marcas del texto y de la nota de cada paso, por idioma (las dos se rellenan igual)
  marcas_de <- function(idioma) {
    lapply(seq_len(nrow(historias)), function(i) {
      unique(c(historias_marcas(historias[[paste0("texto_", idioma)]][i]), historias_marcas(historias[[paste0("nota_", idioma)]][i])))
    })
  }
  marcas_es <- marcas_de("es")
  marcas_en <- marcas_de("en")
  sin_cifra <- sum(vapply(seq_len(nrow(historias)), function(i) {
    sum(!c(marcas_es[[i]], marcas_en[[i]]) %in% cifras$id[cifras$historia == historias$historia[i]])
  }, numeric(1)))
  distintas <- sum(vapply(seq_len(nrow(historias)), function(i) !setequal(marcas_es[[i]], marcas_en[[i]]), TRUE))
  vacios <- sum(vapply(campos, function(cp) sum(!nzchar(historias[[paste0(cp, "_es")]]) | !nzchar(historias[[paste0(cp, "_en")]])),
                       numeric(1)))
  nota_coja <- sum(nzchar(historias$nota_es) != nzchar(historias$nota_en))
  # Marcas en la cabecera o en la fuente: no se rellenan (historias_web), asi que no puede haberlas
  sin_rellenar <- sum(vapply(c("historia_titulo_es", "historia_titulo_en", "entradilla_es", "entradilla_en",
                               "titulo_es", "titulo_en", "enlace_es", "enlace_en"),
                             function(cp) sum(grepl("{", historias[[cp]], fixed = TRUE)), numeric(1)))
  primero <- historias$paso == 1L
  cabecera <- c("historia_titulo_es", "historia_titulo_en", "entradilla_es", "entradilla_en")
  sin_cabecera <- sum(vapply(cabecera, function(cp) sum(!nzchar(historias[[cp]][primero])), numeric(1)))
  sobra_cabecera <- sum(vapply(cabecera, function(cp) sum(nzchar(historias[[cp]][!primero])), numeric(1)))
  orden <- sum(vapply(split(historias$paso, historias$historia), function(p) !identical(sort(p), seq_along(p)), TRUE))
  ids_mal <- sum(duplicated(cifras$id)) + sum(!cifras$historia %in% historias$historia) +
    sum(!grepl(HISTORIAS_RE_ESTADO[["historia"]], unique(historias$historia)))
  consultas_mal <- sum(!cifras$consulta %in% HISTORIAS_CONSULTAS) + sum(is.na(cifras$decimales) | is.na(cifras$redactado))
  c2 <- dplyr::bind_rows(
    cuenta("historias_textos", "marcas {id} sin cifra de su historia", sin_cifra),
    cuenta("historias_textos", "pasos con marcas distintas en castellano y en ingl\u00e9s", distintas),
    cuenta("historias_textos", "t\u00edtulos, textos o fuentes vac\u00edos", vacios),
    cuenta("historias_textos", "notas en un solo idioma", nota_coja),
    cuenta("historias_textos", "marcas {id} en un campo que no se rellena (t\u00edtulos, entradilla, enlace)", sin_rellenar),
    cuenta("historias_textos", "historias sin t\u00edtulo o entradilla en el paso 1", sin_cabecera),
    cuenta("historias_textos", "t\u00edtulo o entradilla fuera del paso 1", sobra_cabecera),
    cuenta("historias_textos", "historias con los pasos fuera de 1 a N", orden),
    cuenta("historias_textos", "ids de cifra repetidos, de una historia que no existe o ids de historia no v\u00e1lidos", ids_mal),
    cuenta("historias_textos", "consultas desconocidas o cifras sin decimales o sin redactar", consultas_mal)
  )

  # 3. Vista del mapa
  mapas <- manifiesto$mapas
  def <- lapply(historias$mapa, function(id) mapas[[id]])
  sin_mapa <- vapply(def, is.null, TRUE)
  anios <- lapply(seq_along(def), function(i) if (sin_mapa[i]) integer() else unlist(manifiesto$indicadores[[def[[i]]$base]]$anios))
  fuera_serie <- sum(!sin_mapa & !mapply(function(a, an) as.integer(a) %in% an, historias$anio, anios))
  formato <- function(campo, opcional = TRUE) {
    v <- historias[[campo]]
    sum(!(if (opcional) !nzchar(v) else FALSE) & !grepl(HISTORIAS_RE_ESTADO[[campo]], v))
  }
  formato_mal <- formato("mapa", FALSE) + formato("anio", FALSE) + formato("vista", FALSE) +
    formato("territorio") + formato("escala")
  escala_mal <- sum(nzchar(historias$escala) & vapply(def, function(d) is.null(d$juegos$seccion), TRUE))
  nivel_terr <- sub(":.*$", "", historias$territorio)
  terr_mal <- sum(nzchar(historias$territorio) & !sin_mapa & !mapply(function(n, d) {
    is.null(d) || n %in% unlist(manifiesto$indicadores[[d$base]]$niveles)
  }, nivel_terr, def))
  con_ficha <- nzchar(historias$ficha)
  claves_mal <- length(setdiff(c("mapa", "anio", "vista", "territorio", "escala", "historia", "paso",
                                 if (any(con_ficha)) "ficha"), claves_estado))
  # Ficha de perfil: solo las del pipeline (nunca el peon, el sueldo de quien visita)
  ficha_mal <- sum(con_ficha & !historias$ficha %in% HISTORIAS_FICHAS)
  con_enlace <- nzchar(historias$enlace)
  pagina <- sub("[?#].*$", "", historias$enlace[con_enlace])   # la pagina, sin consulta ni ancla
  ancla <- ifelse(grepl("#", historias$enlace[con_enlace]), sub("^[^#]*#", "", historias$enlace[con_enlace]), "")
  paginas <- c("mapa.html", "sobrecarga.html", "metodo.html", "method.html", "datos.html", "data.html", "historico.html",
               "metodo_corto.html", "short_method.html")
  enlace_mal <- sum(!pagina %in% paginas) +
    sum(nzchar(ancla) & !mapply(function(p, a) is.null(anclas[[p]]) || a %in% anclas[[p]], pagina, ancla)) +
    sum(nzchar(ancla) & vapply(pagina, function(p) is.null(anclas[[p]]), TRUE)) +
    sum(con_enlace & (!nzchar(historias$enlace_es) | !nzchar(historias$enlace_en)))
  c3 <- dplyr::bind_rows(
    cuenta("historias_estado", "mapas que no est\u00e1n en el manifiesto", sum(sin_mapa)),
    cuenta("historias_estado", "a\u00f1os fuera de la serie del mapa", fuera_serie),
    cuenta("historias_estado", "mapa, a\u00f1o, vista, territorio o escala con un formato que no admite estado.js", formato_mal),
    cuenta("historias_estado", "escala del municipio en un mapa sin juego de cortes de la secci\u00f3n", escala_mal),
    cuenta("historias_estado", "territorios de un nivel que el mapa no tiene", terr_mal),
    cuenta("historias_estado", "claves del recorrido que no admite web/js/estado.js", claves_mal),
    cuenta("historias_estado", "fichas que no son de perfil (llave, mochila, tartera o transistor)", ficha_mal),
    cuenta("historias_estado", "enlaces a p\u00e1ginas o anclas que no existen, o sin texto en los dos idiomas", enlace_mal)
  )

  # 4. Nada de la oferta privada (decisiones 17 a 19)
  privada <- function(x) grepl("portal|idealista", x, ignore.case = TRUE)
  mapas_priv <- sum(!sin_mapa & vapply(def, function(d) !is.null(d) && privada(manifiesto$indicadores[[d$base]]$fuente %||% ""), TRUE))
  ind_priv <- indicadores$codigo[privada(indicadores$fuentes)]
  de_larga <- unique(cifras$indicador[!grepl("^(hist|ipc|derivada)_", cifras$consulta) & cifras$consulta != "corte_mayor"])
  fuentes_cifras <- unique(larga$fuente[larga$indicador %in% de_larga])
  cifras_priv <- sum(cifras$indicador %in% ind_priv) + sum(privada(fuentes_cifras)) +
    sum(grepl("entrar", cifras$indicador)) + sum(grepl("entrar", historias$mapa))
  c4 <- dplyr::bind_rows(
    cuenta("historias_privado", "pasos con un mapa de la oferta privada", mapas_priv),
    cuenta("historias_privado", "cifras de indicadores de la oferta privada o de \u00abentrar\u00bb", cifras_priv)
  )
  dplyr::bind_rows(c1, c2, c3, c4)
}
