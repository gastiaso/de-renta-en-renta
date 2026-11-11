# Exportación de los datos de la web (web/datos/; plan §6.6, preguntas abiertas 12, 14 y 17).
#
# Contrato con la web (web/js/datos.js y la muestra de web/datos/ejemplo/):
#   - manifiesto.json: qué hay y dónde (mapa base, índices, territorios, cajas, perfiles,
#     indicadores, mapas y fichas);
#   - indices/<nivel>.json: códigos del nivel en el orden de los valores (sc, distrito, municipio,
#     provincia, ccaa y nacional, «00»), de la jerarquía de geo/;
#   - <nivel>/<serie>/<periodo>.json: {"v": [valor × escala en enteros o null],
#     "e": "0123…"}, un elemento y un carácter de estado por territorio del índice (0 dato,
#     1 estimado, 2 secreto, 3 ausente); un territorio sin fila en la tabla larga va como null y
#     ausente. Todos los niveles de una serie tienen todos sus periodos (si un nivel no tiene un
#     periodo, el fichero va entero en ausente), porque la web pide cualquier combinación;
#   - fichas/<municipio>.json: series de todos los periodos de las secciones del municipio y, en
#     `series_municipio`, las del propio municipio, con el mismo par v/e;
#   - territorios.json (nombres y comunidad de cada provincia), cajas.json (rectángulo de cada
#     municipio, para el buscador) y perfiles.json (ingresos de las fichas).
#
# Qué se exporta: los indicadores del núcleo de la v0.1 (inventario/indicadores.csv, nucleo_v01)
# y los que tienen mapa (cortes_web y cifras de sección, como los 4–6 de F3, desde el 9-nov-2026)
# que estén en la tabla larga, en los niveles de NIVELES_WEB, y sus auxiliares (columna
# auxiliar_de: contratos y margen de la mediana del alquiler; preguntas 12 y 15 ampliadas). Cada
# serie con auxiliares lleva en el manifiesto `fiabilidad` ({"contratos": clave, "margen": clave},
# de su misma tipología), y el manifiesto, `umbral_pocos_contratos`. Cada combinación de indicador,
# corte y grupo que ve la web es una «serie» con su clave:
#   - sin desglose (corte total), la clave es el indicador y el periodo, el año;
#   - con tipología (SERPAVI), el grupo por defecto (GRUPO_POR_DEFECTO_WEB, vivienda colectiva:
#     pregunta 12) lleva el código del indicador y los demás, «indicador_grupo» en minúsculas
#     (alquiler_m2_vu), con `indicador`, `corte` y `grupo` en el manifiesto;
#   - por mes de referencia (viviendas turísticas, corte mes), el periodo es «AAAA-MM»;
#   - los demás cortes (cuartiles del SERPAVI, ficha del indicador 15) no se exportan: el 15 lo
#     calcula la web con la ficha elegida.
# Valores con el redondeo de la guía: as.numeric(sprintf("%.1f", x)), y después × 10 en enteros.
# La escala es 10 (una décima) salvo en los indicadores con escala_web en inventario/indicadores.csv
# (100, dos decimales: las viviendas turísticas, pregunta 24), que la llevan en su entrada del
# manifiesto (`escala`), con el redondeo de la guía a esos decimales (sprintf("%.2f", x)).

ESTADOS_WEB <- c("dato", "estimado", "secreto", "ausente")      # cifra del estado = posición - 1
ESCALA_WEB <- 10L                                                # una décima; la de codificacion
ESCALAS_WEB <- c(10L, 100L, 1000L)                               # de una a tres cifras decimales
NIVELES_WEB <- c("sc", "distrito", "municipio", "provincia", "ccaa", "nacional")
GRUPO_POR_DEFECTO_WEB <- c(tipologia = "VC")                     # pregunta abierta 12
# F5: cortes cuyos grupos son mapas propios, sin serie por defecto (precios de oferta de los portales,
# indicador 13: operación y portal, como `alquiler_idealista`; capa desmontable). Clave de cada
# serie: «indicador_grupo».
CORTES_POR_GRUPO_WEB <- c("oferta_privada")
CORTES_WEB <- c("total", "mes", names(GRUPO_POR_DEFECTO_WEB), CORTES_POR_GRUPO_WEB)
# F5: niveles más finos con que un indicador con cortes_web tiene mapa: la sección y, si no la tiene,
# el municipio (indicador 20); entonces el mapa lleva `nivel_minimo` y la web pinta los municipios a
# toda escala, con las secciones apagadas.
NIVELES_MAPA_WEB <- c("sc", "municipio")
# Mapas que la web calcula en el navegador a partir de otra serie (web/js/formulas.js), para que
# cambiar la superficie o el umbral no obligue a bajar nada. Tarea 40 (decisión 4): el sueldo
# necesario pinta la cifra principal, con el alquiler mensual mediano real, y lleva `minimo`, la
# serie y la fórmula del mínimo teórico con la superficie elegida (50 m² por defecto), que la ficha,
# el CSV y la leyenda dan al lado.
FORMULAS_WEB <- list(sueldo_necesario = list(base = "alquiler_mes", formula = "alquiler_mes_a_sueldo",
                                             minimo = list(base = "alquiler_m2", formula = "alquiler_m2_a_sueldo")))
MAPA_POR_DEFECTO_WEB <- "sueldo_necesario"                        # plan §6.6, «Tu sueldo»
SUPUESTOS_WEB <- list(superficie_m2 = 50, umbral = 0.3)           # plan §3.1 y §6.6
LIMITES_INICIALES_WEB <- c(-9.4, 35.9, 4.4, 43.9)                # península y Baleares (oeste, sur, este, norte)

# Valor × escala en enteros, con el redondeo de la guía a los decimales de la escala (no
# sprintf("%.0f", x * 10): con 0,15 da 2, y la guía, 0,1). `escala`: una o una por valor.
valor_web <- function(x, escala = ESCALA_WEB) {
  escala <- rep_len(escala, length(x))
  v <- rep(NA_integer_, length(x))
  ok <- !is.na(x)
  v[ok] <- as.integer(round(redondeo_guia(x[ok], decimales_escala(escala[ok])) * escala[ok]))
  v
}

# Redondeo de la guía (sprintf, no round()) a `decimales` (uno, o uno por valor).
redondeo_guia <- function(x, decimales = 1L) {
  decimales <- rep_len(decimales, length(x))
  r <- rep(NA_real_, length(x))
  ok <- !is.na(x)
  r[ok] <- as.numeric(sprintf(paste0("%.", decimales[ok], "f"), x[ok]))
  r
}

decimales_escala <- function(escala) as.integer(round(log10(escala)))

# Escala de cada indicador (columna escala_web de inventario/indicadores.csv; regla 7): vacía,
# ESCALA_WEB; si no, una de ESCALAS_WEB.
escala_web <- function(indicadores, codigo) {
  valor <- if ("escala_web" %in% names(indicadores)) indicadores$escala_web[match(codigo, indicadores$codigo)] else
    rep(NA, length(codigo))
  vacia <- is.na(valor) | !nzchar(trimws(as.character(valor)))
  x <- ifelse(vacia, ESCALA_WEB, suppressWarnings(as.numeric(valor)))
  if (!all(x %in% ESCALAS_WEB)) {
    stop("escala_web debe quedar vac\u00eda o valer ", paste(ESCALAS_WEB, collapse = ", "), ": ",
         paste(unique(valor[!vacia & !x %in% ESCALAS_WEB]), collapse = ", "), call. = FALSE)
  }
  as.integer(x)
}

# Cifra de cada estado ("0" dato … "3" ausente).
estado_web <- function(estado) {
  cifra <- match(estado, ESTADOS_WEB) - 1L
  if (anyNA(cifra)) stop("Estado sin cifra en la web: ", paste(unique(estado[is.na(cifra)]), collapse = ", "), call. = FALSE)
  as.character(cifra)
}

# JSON {"v": [...], "e": "..."}: con vectores, una cadena; con matrices (territorio × periodo),
# una por fila.
json_valores <- function(v, e) {
  if (is.null(dim(v))) {
    return(paste0('{"v":[', paste(ifelse(is.na(v), "null", as.character(v)), collapse = ","),
                  '],"e":"', paste(e, collapse = ""), '"}'))
  }
  texto <- ifelse(is.na(v), "null", as.character(v))
  dim(texto) <- dim(v)
  partes_v <- do.call(paste, c(lapply(seq_len(ncol(texto)), function(j) texto[, j]), sep = ","))
  partes_e <- do.call(paste0, lapply(seq_len(ncol(e)), function(j) e[, j]))
  paste0('{"v":[', partes_v, '],"e":"', partes_e, '"}')
}

# Lista JSON de periodos: años como números, meses («AAAA-MM») como texto.
json_periodos <- function(p) {
  if (all(grepl("^[0-9]{4}$", p))) paste0("[", paste(p, collapse = ","), "]")
  else paste0('["', paste(p, collapse = '","'), '"]')
}

# Lectura de un fichero de valores (para la compuerta): valores (÷ 10) y estados.
leer_valores_web <- function(ruta, escala = 10) {
  x <- jsonlite::fromJSON(ruta, simplifyVector = TRUE)
  list(valores = as.numeric(x$v) / escala, estados = ESTADOS_WEB[match(strsplit(x$e, "")[[1]], as.character(0:3))])
}

# Índices por nivel: códigos ordenados de la jerarquía del seccionado de 2021; España, «00».
indices_web <- function(jerarquia, territorios) {
  de <- function(nivel) sort(territorios$codigo[territorios$nivel == nivel])
  list(sc = sort(jerarquia$seccion), distrito = de("distrito"), municipio = de("municipio"),
       provincia = de("provincia"), ccaa = de("ccaa"), nacional = "00")
}

# Decimales con que la web muestra una serie: uno en los porcentajes, en los índices (Gini), en
# los euros por m² y mes (alquiler) y en los años (F5: años de salario para comprar); en el resto de
# euros, ninguno (F5: también en los euros por m² de la compraventa, como el valor tasado). Con una escala propia, los suyos (100: dos).
decimales_web <- function(unidad, escala = ESCALA_WEB) {
  escala <- rep_len(escala, length(unidad))
  una <- grepl("^%", unidad) | (grepl("m\u00b2", unidad) & grepl("mes", unidad)) | grepl("^\u00edndice", unidad) |
    grepl("^a\u00f1os", unidad)   # F5: anios de salario (16), con una decimal
  ifelse(escala > ESCALA_WEB, decimales_escala(escala), ifelse(una, 1L, 0L))
}

# Indicadores auxiliares (columna auxiliar_de de inventario/indicadores.csv: los indicadores a los
# que acompañan, separados por «;»), con su papel en la web: «contratos» o «margen», por el
# principio de su código. Sin la columna, ninguno.
PAPELES_AUXILIARES_WEB <- c("contratos", "margen")
auxiliares_web <- function(indicadores) {
  vacio <- tibble::tibble(codigo = character(), papel = character(), de = list())
  if (!"auxiliar_de" %in% names(indicadores)) return(vacio)
  a <- indicadores[!is.na(indicadores$auxiliar_de) & nzchar(trimws(indicadores$auxiliar_de)), ]
  if (!nrow(a)) return(vacio)
  papel <- sub("_.*$", "", a$codigo)
  if (!all(papel %in% PAPELES_AUXILIARES_WEB)) {
    stop("Auxiliar sin papel conocido en la web: ", paste(a$codigo[!papel %in% PAPELES_AUXILIARES_WEB], collapse = ", "),
         call. = FALSE)
  }
  tibble::tibble(codigo = a$codigo, papel = papel, de = strsplit(a$auxiliar_de, ";", fixed = TRUE))
}

# Filas de la tabla larga que van a la web, con su clave, su grupo en la web y su periodo: las
# del núcleo y las de sus auxiliares.
series_web <- function(larga, indicadores) {
  con_mapa <- indicadores$codigo[!is.na(indicadores$cortes_web) & nzchar(indicadores$cortes_web)]
  con_mapa <- intersect(con_mapa, unique(larga$indicador[larga$nivel %in% NIVELES_MAPA_WEB]))   # F5: tambien municipio
  nucleo <- union(indicadores$codigo[indicadores$nucleo_v01 %in% c(TRUE, "TRUE")], con_mapa)
  aux <- auxiliares_web(indicadores)
  aux <- aux$codigo[vapply(aux$de, function(d) any(d %in% nucleo), TRUE)]
  x <- larga |>
    filter(indicador %in% c(nucleo, aux), nivel %in% NIVELES_WEB, corte %in% CORTES_WEB) |>
    select(geo_id, nivel, anio, indicador, corte, grupo, valor, estado, fuente, version)
  por_defecto <- unname(GRUPO_POR_DEFECTO_WEB[x$corte])
  sin_grupo <- x$corte %in% c("total", "mes")
  x |>
    mutate(
      periodo = ifelse(corte == "mes", sprintf("%d-%s", anio, substr(grupo, 2, 3)), as.character(anio)),
      grupo_web = ifelse(sin_grupo, "total", grupo),
      clave = ifelse(sin_grupo | (!is.na(por_defecto) & grupo == por_defecto), indicador, paste0(indicador, "_", tolower(grupo))),
      escala = escala_web(indicadores, indicador),
      auxiliar = indicador %in% aux
    )
}

# Ruta de los valores de una serie, con {nivel} y {anio} o {periodo} por sustituir (relativa a web/):
# datos/{nivel}/<serie>/{anio}.json.
ruta_web <- function(clave, corte, prefijo = "datos") {
  file.path(prefijo, "{nivel}", clave, ifelse(corte == "mes", "{periodo}.json", "{anio}.json"))
}

ruta_valores <- function(ruta, nivel, periodo) {
  gsub("{periodo}", periodo, gsub("{anio}", periodo, gsub("{nivel}", nivel, ruta, fixed = TRUE), fixed = TRUE),
       fixed = TRUE)
}

# Una fila por serie: indicador, corte, grupo, escala, niveles, periodos, ruta, fuente y versión.
catalogo_web <- function(series) {
  if (!"auxiliar" %in% names(series)) series$auxiliar <- FALSE
  series |>
    group_by(clave, indicador, corte, grupo_web, escala, auxiliar) |>
    summarise(niveles = list(NIVELES_WEB[NIVELES_WEB %in% nivel]), periodos = list(sort(unique(periodo))),
              fuente = paste(sort(unique(fuente)), collapse = ";"), version = max(version), .groups = "drop") |>
    mutate(ruta = ruta_web(clave, corte)) |>
    arrange(clave)
}

# Valores por serie, nivel y periodo: un fichero por combinación, en el orden del índice del nivel.
escribir_valores_web <- function(series, catalogo, indices, dir_web = "web") {
  rutas <- character()
  for (k in seq_len(nrow(catalogo))) {
    fila <- catalogo[k, ]
    datos <- series[series$clave == fila$clave, ]
    for (nivel in fila$niveles[[1]]) {
      d_n <- datos[datos$nivel == nivel, ]
      indice <- indices[[nivel]]
      for (p in fila$periodos[[1]]) {
        d <- d_n[d_n$periodo == p, ]
        m <- match(indice, d$geo_id)
        ruta <- file.path(dir_web, ruta_valores(fila$ruta, nivel, p))
        dir.create(dirname(ruta), recursive = TRUE, showWarnings = FALSE)
        writeLines(json_valores(valor_web(d$valor[m], fila$escala), estado_web(ifelse(is.na(m), "ausente", d$estado[m]))),
                   ruta, useBytes = TRUE)
        rutas <- c(rutas, ruta)
      }
    }
  }
  rutas
}

# Matriz territorio × periodo (enteros y cifras de estado) de una serie en un nivel.
matriz_web <- function(datos, codigos, periodos, escala = ESCALA_WEB) {
  fila <- match(datos$geo_id, codigos)
  col <- match(datos$periodo, periodos)
  ok <- !is.na(fila) & !is.na(col)
  v <- matrix(NA_integer_, length(codigos), length(periodos))
  e <- matrix("3", length(codigos), length(periodos))
  v[cbind(fila[ok], col[ok])] <- valor_web(datos$valor[ok], escala)
  e[cbind(fila[ok], col[ok])] <- estado_web(datos$estado[ok])
  list(v = v, e = e)
}

# Fichas: un JSON por municipio con las series de sus secciones (las series con nivel sc) y, en
# `series_municipio`, las del propio municipio (las series con nivel municipio). Solo las series
# por defecto (la ficha usa la vivienda colectiva; las variantes, como alquiler_m2_vu, se leen de
# los ficheros por periodo) y sin las auxiliares (contratos y margen: la ficha las lee de los
# ficheros del periodo que pinta el mapa; en las fichas pesarían una cuarta parte más).
series_ficha <- function(catalogo) {
  auxiliar <- if ("auxiliar" %in% names(catalogo)) catalogo$auxiliar else FALSE
  catalogo[catalogo$clave == catalogo$indicador & !auxiliar, ]
}

escribir_fichas_web <- function(series, catalogo, jerarquia, dir_web = "web", prefijo = "datos") {
  catalogo <- series_ficha(catalogo)
  dir <- file.path(dir_web, prefijo, "fichas")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  secciones <- sort(jerarquia$seccion)
  municipio_de <- jerarquia$municipio[match(secciones, jerarquia$seccion)]
  municipios <- sort(unique(municipio_de))
  trozos <- function(nivel, codigos) {
    cat_n <- catalogo[vapply(catalogo$niveles, function(n) nivel %in% n, TRUE), ]
    if (!nrow(cat_n)) return(list(periodos = character(), series = matrix(character(), length(codigos), 0)))
    s <- vapply(seq_len(nrow(cat_n)), function(k) {
      d <- series[series$clave == cat_n$clave[k] & series$nivel == nivel, ]
      m <- matriz_web(d, codigos, cat_n$periodos[[k]], cat_n$escala[k])
      paste0('"', cat_n$clave[k], '":', json_valores(m$v, m$e))
    }, character(length(codigos)))
    dim(s) <- c(length(codigos), nrow(cat_n))
    list(periodos = paste0('"', cat_n$clave, '":', vapply(cat_n$periodos, json_periodos, "")), series = s)
  }
  sc <- trozos("sc", secciones)
  mun <- trozos("municipio", municipios)
  juntar <- function(m) if (ncol(m)) do.call(paste, c(lapply(seq_len(ncol(m)), function(j) m[, j]), sep = ",")) else ""
  por_seccion <- paste0('"', secciones, '":{', juntar(sc$series), "}")
  por_municipio <- split(por_seccion, municipio_de)
  propio <- rep_len(juntar(mun$series), length(municipios))
  rutas <- file.path(dir, paste0(municipios, ".json"))
  for (i in seq_along(municipios)) {
    texto <- paste0('{"municipio":"', municipios[i], '","anios":{', paste(sc$periodos, collapse = ","),
                    '},"series":{', paste(por_municipio[[municipios[i]]], collapse = ","),
                    '},"series_municipio":{"anios":{', paste(mun$periodos, collapse = ","),
                    '},"series":{', propio[i], "}}}")
    writeLines(texto, rutas[i], useBytes = TRUE)
  }
  rutas
}

# Nombres por nivel y comunidad de cada provincia.
territorios_web <- function(territorios) {
  de <- function(nivel, campo = "nombre") {
    t <- territorios[territorios$nivel == nivel, ]
    stats::setNames(as.list(t[[campo]]), t$codigo)
  }
  list(ccaa = de("ccaa"), provincia = de("provincia"), municipio = de("municipio"),
       ccaa_de_provincia = de("provincia", "superior"))
}

# Rectángulo de cada municipio (oeste, sur, este, norte; grados, cinco decimales), para el buscador.
cajas_web <- function(secciones, jerarquia) {
  g <- sf::st_transform(sf::st_geometry(secciones), 4326)
  municipio <- jerarquia$municipio[match(secciones$seccion, jerarquia$seccion)]
  cajas <- lapply(split(seq_along(g), municipio), function(i) round(unname(as.numeric(sf::st_bbox(g[i]))), 5))
  list(municipio = cajas)
}

# Ingresos de las fichas en el formato de la web, desde la tabla `perfiles` (perfiles_fichas()):
#   llave: se calcula en la web con la renta por hogar de la sección (÷ 12) y paga su alquiler;
#   mochila, tartera y transistor: neto mensual por territorio de cada año (`anios`), para que la
#   web use el del año del alquiler (regla 4; decisión del autor, 9-nov-2026), y el del último año
#   (`anio`, `neto_mensual`: la tartera, el salario mínimo vigente), con el redondeo de la guía;
#   sin las cifras ausentes.
perfiles_web <- function(perfiles) {
  if (is.null(perfiles)) return(NULL)
  ficha <- function(nombre) {
    p <- perfiles[perfiles$ficha == nombre & !is.na(perfiles$ingreso) & perfiles$estado %in% c("dato", "estimado"), ]
    if (!nrow(p)) return(NULL)
    neto <- function(x) stats::setNames(as.list(redondeo_guia(x$ingreso)), x$geo_id)
    ultimo <- p[p$anio == max(p$anio), ]
    list(anio = max(p$anio), nivel = p$nivel[1], neto_mensual = neto(ultimo),
         anios = lapply(split(p, p$anio), neto),
         superficie_m2 = unique(p$superficie_m2)[1])
  }
  web <- list(llave = list(ingreso = list(serie = "renta_hogar", divisor = 12L), vivienda = list(serie = "alquiler_mes")),
              mochila = ficha("mochila"), tartera = ficha("tartera"), transistor = ficha("transistor"))
  web[!vapply(web, is.null, TRUE)]
}

# Cortes de los tramos del mapa (columna cortes_web de inventario/indicadores.csv): de uno a
# MAX_CORTES_WEB valores crecientes separados por «;», con punto decimal. La rampa de
# diseno/tokens.json tiene un paso por tramo del mapa más detallado (seis: pregunta abierta 20);
# con menos tramos, la web toma pasos repartidos (web/js/colores.js).
MAX_CORTES_WEB <- 5L

cortes_web <- function(texto) {
  x <- as.numeric(strsplit(as.character(texto), ";", fixed = TRUE)[[1]])
  if (!length(x) || length(x) > MAX_CORTES_WEB || anyNA(x) || is.unsorted(x, strictly = TRUE)) {
    stop("cortes_web debe tener de 1 a ", MAX_CORTES_WEB, " valores crecientes: ", texto, call. = FALSE)
  }
  x
}

# Mapas: uno por indicador con cortes_web y valores de sección; el por defecto, el primero. Los
# de FORMULAS_WEB se calculan en el navegador desde su base (y, con `minimo`, la segunda cifra desde
# la suya; tarea 40). Tarea 41: un indicador sin cortes_web (el 14) no tiene mapa ni sale en el
# selector, aunque su serie se exporte (núcleo de la v0.1) y la ficha la muestre.
# F5 (indicadores 20 y 13):
#   - sin sección, el municipio como nivel más fino: el mapa lleva `nivel_minimo` («municipio»);
#   - con `vocabulario` y un grupo del vocabulario con el código del indicador (zona_tensionada), el
#     mapa es de categorías: `categorias` = {vocabulario, valores}; los cortes separan los valores;
#   - los cortes de CORTES_POR_GRUPO_WEB dan un mapa por grupo (clave «indicador_grupo», con
#     `indicador`, `corte` y `grupo`), con los cortes de su grupo en cortes_web («general|grupo=…»).
# Tarea 34: los mapas de alquiler llevan `familia` («quedarse» o «entrar»; columna familia_alquiler
# de inventario/indicadores.csv), que la leyenda escribe con su lectura literal.
familia_web <- function(indicadores, codigo) {
  if (!"familia_alquiler" %in% names(indicadores)) return(NULL)
  f <- indicadores$familia_alquiler[match(codigo, indicadores$codigo)]
  if (is.na(f) || !nzchar(f)) NULL else f
}

mapas_web <- function(catalogo, indicadores, vocabulario = NULL) {
  con_seccion <- catalogo$clave[vapply(catalogo$niveles, function(n) any(NIVELES_MAPA_WEB %in% n), TRUE)]
  nivel_minimo <- function(clave) {
    n <- catalogo$niveles[[match(clave, catalogo$clave)]]
    NIVELES_MAPA_WEB[NIVELES_MAPA_WEB %in% n][1]
  }
  filas <- indicadores[!is.na(indicadores$cortes_web) & nzchar(indicadores$cortes_web), ]
  filas <- filas[order(filas$codigo != MAPA_POR_DEFECTO_WEB, filas$id), ]
  mapas <- list()
  for (k in seq_len(nrow(filas))) {
    codigo <- filas$codigo[k]
    por_grupo <- catalogo[catalogo$indicador == codigo & catalogo$corte %in% CORTES_POR_GRUPO_WEB & catalogo$clave %in% con_seccion, ]
    if (nrow(por_grupo)) {
      cortes <- cortes_grupos_web(filas$cortes_web[k])
      for (j in seq_len(nrow(por_grupo))) {
        g <- por_grupo[j, ]
        def <- list(base = g$clave, formula = "directo", indicador = codigo, corte = g$corte, grupo = g$grupo_web,
                    cortes = I(cortes[[g$grupo_web]] %||% cortes$general),
                    decimales = decimales_web(filas$unidad_es[k], escala_web(indicadores, codigo)))
        if (!identical(nivel_minimo(g$clave), "sc")) def$nivel_minimo <- nivel_minimo(g$clave)
        def$familia <- familia_web(indicadores, codigo)
        mapas[[g$clave]] <- def
      }
      next
    }
    f <- FORMULAS_WEB[[codigo]]
    def <- if (!is.null(f) && f$base %in% con_seccion) {
      c(list(base = f$base, formula = f$formula),
        if (!is.null(f$minimo) && f$minimo$base %in% catalogo$clave) list(minimo = f$minimo))   # tarea 40
    } else if (codigo %in% con_seccion) {
      list(base = codigo, formula = "directo")
    } else NULL
    if (is.null(def)) next
    mapas[[codigo]] <- c(def, list(cortes = I(cortes_web(filas$cortes_web[k])),
                                   decimales = decimales_web(filas$unidad_es[k], escala_web(indicadores, codigo))))
    # F5: mapa sin seccion (nivel_minimo) y de categorias
    if (!identical(nivel_minimo(def$base), "sc")) mapas[[codigo]]$nivel_minimo <- nivel_minimo(def$base)
    categorias <- categorias_web(vocabulario, codigo)
    if (!is.null(categorias)) mapas[[codigo]]$categorias <- categorias
    mapas[[codigo]]$familia <- familia_web(indicadores, codigo)
  }
  mapas
}

# F5: declaraciones de zona tensionada por municipio (indicador 20), para la ficha de la web:
# {"municipio": [{boe, publicacion, inicio, fin, ambito, ambito_texto, nombre_boe, declaracion, url,
# url_declaracion}]}, por fecha de efecto. Fechas «AAAA-MM-DD»; textos vacíos como "".
CODIGO_ZONAS_WEB <- "zona_tensionada"
zonas_web <- function(zonas) {
  z <- zonas[order(zonas$municipio, zonas$fecha_inicio, zonas$ambito_texto), ]
  texto <- function(x) ifelse(is.na(x), "", x)
  filas <- lapply(seq_len(nrow(z)), function(k) list(
    boe = z$boe[k], publicacion = format(z$fecha_publicacion[k]), inicio = format(z$fecha_inicio[k]),
    fin = format(z$fecha_fin[k]), ambito = z$ambito[k], ambito_texto = texto(z$ambito_texto[k]),
    nombre_boe = z$nombre_boe[k], declaracion = texto(z$declaracion[k]), url = z$url[k],
    url_declaracion = texto(z$url_declaracion[k])))
  split(filas, z$municipio)
}

# F5: compuerta web_zonas_tensionadas (bloqueo): las declaraciones de datos/zonas_tensionadas.json
# reproducen las del inventario (municipio, resolución, ámbito y fechas), y el mapa del indicador 20
# apunta al fichero.
comprobar_zonas_web <- function(zonas, dir_web = "web") {
  ruta <- file.path(dir_web, "datos", "zonas_tensionadas.json")
  leido <- if (file.exists(ruta)) jsonlite::fromJSON(ruta, simplifyVector = FALSE) else list()
  plano <- function(x) sort(unlist(lapply(names(x), function(m) vapply(x[[m]], function(d)
    paste(m, d$boe, d$ambito, d$ambito_texto, d$inicio, d$fin), ""))))
  esperado <- plano(zonas_web(zonas))
  manifiesto <- jsonlite::fromJSON(file.path(dir_web, "datos", "manifiesto.json"), simplifyVector = FALSE)
  tibble::tibble(
    id = "web_zonas_tensionadas",
    detalle = c("declaraciones distintas del inventario", "mapa sin la ruta de las declaraciones"),
    calculado = c(length(union(setdiff(esperado, plano(leido)), setdiff(plano(leido), esperado))),
                  as.numeric(!identical(manifiesto$mapas[[CODIGO_ZONAS_WEB]]$detalle, "datos/zonas_tensionadas.json"))),
    referencia = 0
  )
}

# F5: cortes de un indicador con un mapa por grupo: los generales y, tras «|», los de un grupo, como
# «8;10;12;15;20|venta_idealista=1000;1500;2000;3000;4000» (el formato de los de la sobrecarga).
cortes_grupos_web <- function(texto) {
  partes <- trimws(strsplit(as.character(texto), "|", fixed = TRUE)[[1]])
  grupos <- partes[-1]
  if (length(grupos) && !all(grepl("^[A-Za-z0-9_-]+=", grupos))) {
    stop("cortes_web: cada grupo va como grupo=c1;c2: ", texto, call. = FALSE)
  }
  c(list(general = cortes_web(partes[1])),
    stats::setNames(lapply(sub("^[^=]+=", "", grupos), cortes_web), sub("=.*$", "", grupos)))
}

# F5: categorías de un mapa (indicador 20): las claves numéricas del grupo de inventario/vocabulario.csv
# que se llama como el indicador (sus textos van a web/i18n con exportar_i18n()). Sin ese grupo, NULL.
categorias_web <- function(vocabulario, codigo) {
  if (is.null(vocabulario)) return(NULL)
  claves <- vocabulario$clave[vocabulario$grupo == codigo]
  if (!length(claves)) return(NULL)
  valores <- suppressWarnings(as.numeric(claves))
  if (anyNA(valores)) stop("Las categor\u00edas de ", codigo, " deben ser n\u00fameros: ", paste(claves, collapse = ", "), call. = FALSE)
  list(vocabulario = codigo, valores = I(sort(valores)))
}

# Series de fiabilidad de cada serie del catálogo con auxiliares: {"contratos": clave, "margen":
# clave}, de la misma tipología (las series sin desglose, como el esfuerzo de residentes, toman
# la de por defecto, la vivienda colectiva). Una lista con nombre por clave; sin auxiliares, vacía.
fiabilidad_web <- function(catalogo, indicadores) {
  aux <- auxiliares_web(indicadores)
  out <- list()
  if (!nrow(aux)) return(out)
  for (k in seq_len(nrow(catalogo))) {
    c_k <- catalogo[k, ]
    g <- if (c_k$grupo_web %in% c("VC", "VU")) c_k$grupo_web else GRUPO_POR_DEFECTO_WEB[["tipologia"]]
    f <- list()
    for (j in which(vapply(aux$de, function(d) c_k$indicador %in% d, TRUE))) {
      clave <- catalogo$clave[catalogo$indicador == aux$codigo[j] & catalogo$grupo_web == g]
      if (length(clave) == 1) f[[aux$papel[j]]] <- clave
    }
    if (length(f)) out[[c_k$clave]] <- f
  }
  out
}

# Entradas del manifiesto por serie: niveles, años (o periodos «AAAA-MM»), escala (si no es la de
# codificacion), decimales y ruta, que es lo que lee web/js/datos.js; con desglose, además, el
# indicador, el corte y el grupo. Por
# conveniencia, el número del indicador (los auxiliares no tienen), la fuente, la versión y las
# variantes de la serie por defecto (`variantes`: {"VU": "alquiler_m2_vu"}) o la serie por defecto
# de una variante; con auxiliares, `fiabilidad` (fiabilidad_web()).
indicadores_manifiesto_web <- function(catalogo, indicadores) {
  fiabilidad <- fiabilidad_web(catalogo, indicadores)
  entradas <- lapply(seq_len(nrow(catalogo)), function(k) {
    c_k <- catalogo[k, ]
    ind <- c_k$indicador
    fila <- match(ind, indicadores$codigo)
    p <- c_k$periodos[[1]]
    e <- if (is.na(indicadores$id[fila])) list() else list(id = indicadores$id[fila])
    if (!c_k$corte %in% c("total", "mes")) e <- c(e, list(indicador = ind, corte = c_k$corte, grupo = c_k$grupo_web))
    e$niveles <- I(c_k$niveles[[1]])
    if (c_k$corte == "mes") e$periodos <- I(p) else e$anios <- I(as.integer(p))
    if (c_k$escala != ESCALA_WEB) e$escala <- c_k$escala
    e <- c(e, list(decimales = decimales_web(indicadores$unidad_es[fila], c_k$escala), ruta = c_k$ruta,
                   fuente = c_k$fuente, version = c_k$version))
    if (c_k$clave == ind) {
      otras <- catalogo[catalogo$indicador == ind & catalogo$clave != ind, ]
      if (nrow(otras)) e$variantes <- stats::setNames(as.list(otras$clave), otras$grupo_web)
    } else if (!c_k$corte %in% CORTES_POR_GRUPO_WEB) {   # F5: los mapas por grupo no tienen serie por defecto
      e$por_defecto <- ind
    }
    if (!is.null(fiabilidad[[c_k$clave]])) e$fiabilidad <- fiabilidad[[c_k$clave]]
    e
  })
  stats::setNames(entradas, catalogo$clave)
}

# Exportación completa. `pmtiles`: el mapa base (fichero_mapa_base), que se copia a
# web/teselas/seccionado_2021.pmtiles (fuera de git). `perfiles`: tabla perfiles (perfiles_fichas()).
# `cajas`: cajas_web(). Borra antes lo exportado la vez anterior, salvo la muestra (ejemplo/).
# F5: `vocabulario` (inventario/vocabulario.csv) da las categorías de los mapas que las tienen
# (categorias_web(), indicador 20); `zonas` (inventario/zonas_tensionadas.csv), las declaraciones de
# cada municipio para la ficha del indicador 20, en datos/zonas_tensionadas.json (zonas_web()), con
# su ruta en el mapa (`detalle`).
exportar_web <- function(larga, indicadores, jerarquia, territorios, pmtiles = NULL, perfiles = NULL, cajas = NULL,
                         salarios = NULL, dir_web = "web", fecha = format(Sys.Date()), vocabulario = NULL, zonas = NULL) {
  datos <- file.path(dir_web, "datos")
  dir.create(datos, recursive = TRUE, showWarnings = FALSE)
  unlink(file.path(datos, c("manifiesto.json", "territorios.json", "cajas.json", "perfiles.json", "salarios.json", "indices", "fichas",
                            "zonas_tensionadas.json", NIVELES_WEB)), recursive = TRUE)

  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  catalogo <- catalogo_web(series)

  rutas_indices <- file.path("datos", "indices", paste0(names(indices), ".json"))
  dir.create(file.path(datos, "indices"), showWarnings = FALSE)
  for (k in seq_along(indices)) {
    writeLines(paste0('["', paste(indices[[k]], collapse = '","'), '"]'), file.path(dir_web, rutas_indices[k]),
               useBytes = TRUE)
  }
  escribir_json <- function(x, nombre) {
    ruta <- file.path(datos, nombre)
    jsonlite::write_json(x, ruta, auto_unbox = TRUE, digits = NA, na = "null")
    ruta
  }
  otros <- c(escribir_json(territorios_web(territorios), "territorios.json"),
             if (!is.null(cajas)) escribir_json(cajas, "cajas.json"),
             if (!is.null(perfiles)) escribir_json(perfiles_web(perfiles), "perfiles.json"),
             if (!is.null(salarios)) escribir_json(salarios, "salarios.json"),   # percentil salarial (salarios_web())
             if (!is.null(zonas)) escribir_json(zonas_web(zonas), "zonas_tensionadas.json"))   # F5, indicador 20
  valores <- escribir_valores_web(series, catalogo, indices, dir_web)
  fichas <- escribir_fichas_web(series, catalogo, jerarquia, dir_web)

  url_teselas <- "teselas/seccionado_2021.pmtiles"
  if (!is.null(pmtiles)) {
    dir.create(file.path(dir_web, "teselas"), showWarnings = FALSE)
    if (!file.copy(pmtiles, file.path(dir_web, url_teselas), overwrite = TRUE)) {
      stop("No se ha podido copiar ", pmtiles, call. = FALSE)
    }
  }

  manifiesto <- list(
    version = fecha, ejemplo = FALSE, generado = fecha, seccionado = 2021L,
    # sin_seccion: suelo que no es de ninguna sección (geo_capas_mapa_base), sin código propio:
    # la web lo pinta como «sin dato» y su ficha lee estos atributos (nombre y tipo, del IGN).
    mapa_base = list(tipo = "pmtiles", url = url_teselas, atribucion = "INE, IGN",
                     capas = list(comunidades = list(id = "ccaa"), provincias = list(id = "provincia"),
                                  municipios = list(id = "municipio"), secciones = list(id = "seccion"),
                                  sin_seccion = list(atributos = I(c("km2", "provincias", "nombre", "tipo"))))),
    secciones = rutas_indices[1],
    indices = stats::setNames(as.list(rutas_indices), names(indices)),
    territorios = "datos/territorios.json",
    cajas = if (!is.null(cajas)) "datos/cajas.json",
    fichas = "datos/fichas/{municipio}.json",
    perfiles = if (!is.null(perfiles)) "datos/perfiles.json",
    salarios = if (!is.null(salarios)) "datos/salarios.json",
    codificacion = list(escala = ESCALA_WEB, estados = I(ESTADOS_WEB)),
    supuestos = SUPUESTOS_WEB,
    umbral_pocos_contratos = UMBRAL_POCOS_CONTRATOS,
    indicadores = indicadores_manifiesto_web(catalogo, indicadores),
    mapas = mapas_web(catalogo, indicadores, vocabulario),
    vista_inicial = list(limites = I(LIMITES_INICIALES_WEB))
  )
  # F5: declaraciones del indicador 20 para la ficha (ruta en su mapa)
  if (!is.null(zonas) && !is.null(manifiesto$mapas[[CODIGO_ZONAS_WEB]])) {
    manifiesto$mapas[[CODIGO_ZONAS_WEB]]$detalle <- "datos/zonas_tensionadas.json"
  }
  manifiesto <- manifiesto[!vapply(manifiesto, is.null, TRUE)]
  ruta_manifiesto <- file.path(datos, "manifiesto.json")
  jsonlite::write_json(manifiesto, ruta_manifiesto, auto_unbox = TRUE, pretty = TRUE, digits = NA)

  c(ruta_manifiesto, file.path(dir_web, rutas_indices), otros, valores, fichas,
    if (!is.null(pmtiles)) file.path(dir_web, url_teselas))
}

# Compuerta de la web: lo escrito reproduce la tabla larga (ida y vuelta), leyendo los ficheros.
#   web_valores: por fichero de valores, territorios cuyo valor (÷ la escala de la serie en el
#     manifiesto) o estado no es el de la tabla larga con el redondeo de la guía a los decimales
#     de la escala del inventario (longitud distinta de la del índice: todos); además,
#     series de la tabla larga sin fichero y diferencias de perfiles.json con la tabla perfiles;
#   web_fichas: por municipio, celdas de sus series (secciones y municipio) que no cuadran, y
#     secciones o series de más o de menos;
#   web_fuera_indice: filas de la tabla larga que no tienen hueco en el índice de su nivel.
comprobar_web <- function(larga, indicadores, jerarquia, territorios, dir_web = "web", perfiles = NULL) {
  manifiesto <- jsonlite::fromJSON(file.path(dir_web, "datos", "manifiesto.json"), simplifyVector = FALSE)
  indices <- indices_web(jerarquia, territorios)
  series <- series_web(larga, indicadores)
  series$redondeado <- redondeo_guia(series$valor, decimales_escala(series$escala))
  # Escala con que la web lee cada serie: la suya en el manifiesto o la general
  escalas <- vapply(manifiesto$indicadores, function(d) as.numeric(d$escala %||% manifiesto$codificacion$escala), 1)
  filas <- list()

  # Ficheros de valores: todos los del manifiesto
  for (clave in names(manifiesto$indicadores)) {
    def <- manifiesto$indicadores[[clave]]
    d_c <- series[series$clave == clave, ]
    for (nivel in unlist(def$niveles)) {
      d_n <- d_c[d_c$nivel == nivel, ]
      n_ind <- length(indices[[nivel]])
      for (p in as.character(unlist(c(def$anios, def$periodos)))) {
        ruta <- ruta_valores(def$ruta, nivel, p)
        leido <- leer_valores_web(file.path(dir_web, ruta), escalas[[clave]])
        d <- d_n[d_n$periodo == p, ]
        m <- match(indices[[nivel]], d$geo_id)
        esp_v <- d$redondeado[m]
        esp_e <- ifelse(is.na(m), "ausente", d$estado[m])
        mal <- if (length(leido$valores) != n_ind || length(leido$estados) != n_ind) n_ind else
          sum(is.na(leido$estados) | leido$estados != esp_e | xor(is.na(leido$valores), is.na(esp_v)) |
                (!is.na(esp_v) & !is.na(leido$valores) & abs(esp_v - leido$valores) > 1e-9))
        filas[[length(filas) + 1L]] <- tibble::tibble(id = "web_valores", detalle = ruta, calculado = mal)
      }
    }
  }
  en_manifiesto <- unlist(lapply(names(manifiesto$indicadores), function(cl) {
    def <- manifiesto$indicadores[[cl]]
    as.vector(outer(paste(cl, unlist(def$niveles)), as.character(unlist(c(def$anios, def$periodos))), paste))
  }))
  faltan <- setdiff(unique(paste(series$clave, series$nivel, series$periodo)), en_manifiesto)
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "web_valores", detalle = "series de la tabla larga sin fichero",
                                                calculado = length(faltan))
  if (!is.null(perfiles)) {
    leido <- jsonlite::fromJSON(file.path(dir_web, "datos", "perfiles.json"), simplifyVector = FALSE)
    esperado <- perfiles_web(perfiles)
    filas[[length(filas) + 1L]] <- tibble::tibble(id = "web_valores", detalle = "perfiles.json",
                                                  calculado = as.numeric(!isTRUE(all.equal(leido, esperado))))
  }

  # Fichas: se leen todas, se aplanan a una fila por territorio, serie y periodo, y se cruzan con
  # lo esperado: cada sección (y cada municipio) del índice con todos los periodos de cada serie.
  catalogo <- series_ficha(catalogo_web(series))
  leidas <- bind_rows(lapply(indices$municipio, function(mun) {
    f <- jsonlite::fromJSON(file.path(dir_web, sub("{municipio}", mun, manifiesto$fichas, fixed = TRUE)),
                            simplifyVector = TRUE)
    propio <- if (length(f$series_municipio$series)) stats::setNames(list(f$series_municipio$series), mun)
    bind_rows(mutate(aplanar_ficha(f$series, f$anios, escalas), nivel = "sc"),
              mutate(aplanar_ficha(propio, f$series_municipio$anios, escalas), nivel = "municipio"))
  }))
  esperadas <- bind_rows(lapply(c("sc", "municipio"), function(n) {
    cat_n <- catalogo[vapply(catalogo$niveles, function(x) n %in% x, TRUE), ]
    bind_rows(lapply(seq_len(nrow(cat_n)), function(k) {
      p <- cat_n$periodos[[k]]
      tibble::tibble(geo_id = rep(indices[[n]], each = length(p)), nivel = n, clave = cat_n$clave[k],
                     periodo = rep(p, length(indices[[n]])))
    }))
  })) |>
    left_join(select(series, geo_id, nivel, clave, periodo, redondeado, estado), by = c("geo_id", "nivel", "clave", "periodo")) |>
    mutate(estado = ifelse(is.na(estado), "ausente", estado))
  cruce <- full_join(esperadas, leidas, by = c("geo_id", "nivel", "clave", "periodo"))
  mal <- with(cruce, is.na(estado) | is.na(estado_leido) | estado != estado_leido | xor(is.na(redondeado), is.na(valor)) |
                (!is.na(redondeado) & !is.na(valor) & abs(redondeado - valor) > 1e-9))
  por_municipio <- tapply(mal, substr(cruce$geo_id, 1, 5), sum)
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "web_fichas", detalle = names(por_municipio),
                                                calculado = as.numeric(por_municipio))

  # Filas sin hueco en el índice de su nivel
  fuera <- vapply(NIVELES_WEB, function(n) sum(!series$geo_id[series$nivel == n] %in% indices[[n]]), numeric(1))
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "web_fuera_indice", detalle = NIVELES_WEB, calculado = unname(fuera))
  bind_rows(filas) |>
    mutate(calculado = as.numeric(calculado), referencia = 0)
}

# Series de una ficha (territorio → serie → {v, e}) en filas: territorio, serie, periodo, valor y
# estado. Una serie que falta o con otra longitud sale como NA (y la compuerta la cuenta).
# `escalas`: escala de cada serie, con su nombre (sin ella, ESCALA_WEB).
aplanar_ficha <- function(series, periodos, escalas = NULL) {
  vacio <- tibble::tibble(geo_id = character(), clave = character(), periodo = character(), valor = numeric(),
                          estado_leido = character())
  if (!length(series) || !length(periodos)) return(vacio)
  claves <- names(periodos)
  n <- lengths(periodos)
  trozo <- function(x, campo, relleno) {
    unlist(lapply(claves, function(cl) {
      y <- x[[cl]][[campo]]
      if (campo == "e" && !is.null(y)) y <- strsplit(y, "")[[1]]
      if (is.null(y) || length(y) != n[[cl]]) rep(relleno, n[[cl]]) else y
    }), use.names = FALSE)
  }
  v <- as.numeric(unlist(lapply(series, trozo, "v", NA_real_), use.names = FALSE))
  e <- unlist(lapply(series, trozo, "e", "?"), use.names = FALSE)
  clave <- rep(rep(claves, n), length(series))
  escala <- if (is.null(escalas)) rep(ESCALA_WEB, length(clave)) else unname(escalas[clave])
  escala[is.na(escala)] <- ESCALA_WEB
  tibble::tibble(geo_id = rep(names(series), each = sum(n)), clave = clave,
                 periodo = rep(as.character(unlist(periodos, use.names = FALSE)), length(series)), valor = v / escala,
                 estado_leido = ESTADOS_WEB[match(e, as.character(seq_along(ESTADOS_WEB) - 1L))])
}
