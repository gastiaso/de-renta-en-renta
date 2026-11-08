# Sección «Sobrecarga» de la web (v0.0; plan §6.6 y F1b): web/datos/sobrecarga/, fuera de git como
# el resto de web/datos/.
#
# Sale de los objetivos de la sobrecarga ya validados (sobrecarga_ecv, sobrecarga_agrupada,
# eurostat_europa, escalera y el módulo de acceso) y de las geometrías NUTS de GISCO que el
# pipeline ya guarda (fichero_nuts_2021, fichero_nuts_2024). Escribe:
#   - sobrecarga.json: vistas del mapa con su «escalera», serie de España, desgloses anuales de
#     España, nombres de las regiones y de las comunidades, y el módulo de acceso (indicador 23);
#   - nuts_<versión>.geojson: países (NUTS 0), regiones (NUTS 2), las NUTS 1 que pinta alguna vista
#     y los marcos de los recuadros.
#
# Vistas del mapa (un solo mapa de Europa que cambia de escala según el corte):
#   - toda la población, cada año de ilc_lvho07_r: la lista de armar_escalera(), es decir, cada país
#     en su nivel más fino publicado (NUTS 2; algunos, solo el país o NUTS 1), sin los códigos
#     agrupados (FI19_20), y las referencias UE-27 y España. Las comunidades y España llevan la cifra
#     de los microdatos del INE (sobrecarga_ecv) los años que la hay, con su muestra; el resto, la de
#     Eurostat. El puesto es el de armar_escalera();
#   - con tenencia o edad, el último año: países de Eurostat (ilc_lvho07c, ilc_lvho07a) y España por
#     comunidades con las olas agrupadas de la ECV (sobrecarga_agrupada); la referencia España, la ola
#     del último año.
# Mapa y escalera salen de la misma lista: la escalera ordena lo que pinta el mapa.
#
# Cifras: valor × 10 en enteros con el redondeo de la guía (valor_web(), R/web_exportar.R). Las del
# INE llevan las personas y los hogares de la muestra y la marca de fiabilidad de EU-SILC
# (fiabilidad_eusilc(); pregunta abierta 9: sin intervalos); con menos de 20 observaciones, sin
# valor. Las de Eurostat llevan su tabla y su bandera (vacía si la descarga no la trae).
#
# Geometrías: GISCO, uso no comercial y aviso «© EuroGeographics para los límites administrativos»
# (LICENCIA_DATOS.md); no entran en la licencia de los datos. Van en la proyección de Europa de
# Eurostat (LAEA, EPSG:3035), recortadas al marco europeo, con Canarias, Madeira y Azores en
# recuadros. MapLibre dibuja en Web Mercator: para que no deforme el norte, las x e y de la LAEA,
# centradas, se leen como metros de Web Mercator y se pasan a grados. No son longitudes ni latitudes
# reales: solo sirven para este mapa, que no lleva teselas de fondo.

DIR_SOBRECARGA_WEB <- "sobrecarga"                   # bajo <dir_web>/datos/
# Cortes de los tramos del mapa: columna cortes_web del indicador 22 en inventario/indicadores.csv
# (regla 7; pregunta abierta 28), fijos todos los años. Formato: los cortes generales y, tras «|»,
# los de un grupo con los suyos, como «GRUPO=c1;c2;…»: «4;6;8;10;15|RENT_MKT=15;20;25;30;40». El
# alquiler a precio de mercado lleva los suyos porque con los generales casi toda Europa caería en el
# último tramo. Cada lista, como cortes_web() (R/web_exportar.R): de 1 a 5 valores crecientes.
cortes_sobrecarga_web <- function(texto) {
  partes <- trimws(strsplit(as.character(texto), "|", fixed = TRUE)[[1]])
  if (!length(partes) || is.na(partes[1]) || !nzchar(partes[1])) {
    stop("cortes_web de la sobrecarga vac\u00edo", call. = FALSE)
  }
  grupos <- partes[-1]
  if (length(grupos) && !all(grepl("^[A-Z0-9_-]+=", grupos))) {
    stop("cortes_web de la sobrecarga: cada grupo va como GRUPO=c1;c2: ", texto, call. = FALSE)
  }
  c(list(general = cortes_web(partes[1])),
    stats::setNames(lapply(sub("^[^=]+=", "", grupos), cortes_web), sub("=.*$", "", grupos)))
}

cortes_de_indicadores <- function(indicadores, codigo = "sobrecarga") {
  cortes_sobrecarga_web(indicadores$cortes_web[match(codigo, indicadores$codigo)])
}
# Grupos que puede pintar el mapa: los que Eurostat publica por país y la ECV por comunidad
# (el de 15 a 29 años no está agrupado por comunidad; propiedad y alquiler juntos, no en Eurostat).
GRUPOS_MAPA_SOBRECARGA <- list(tenencia = c("RENT_MKT", "RENT_FR", "OWN_L", "OWN_NL"),
                               edad = c("Y_LT18", "Y18-64", "Y_GE65"))
AGREGADOS_EUROSTAT <- c("EU", "EA")                  # además de los códigos de más de dos letras
MARCO_SOBRECARGA_3035 <- c(xmin = 2000000, ymin = 1100000, xmax = 7450000, ymax = 5630000)
CENTRO_SOBRECARGA_3035 <- c(4321000, 3210000)        # origen de la LAEA de Europa
RECUADROS_SOBRECARGA <- c("ES70", "PT30", "PT20")    # Canarias, Madeira y Azores, de abajo arriba
TABLA_EUROSTAT_FUENTE <- c(ilc_lvho07a = "eurostat_ilc_lvho07", ilc_lvho07c = "eurostat_ilc_lvho07",
                           ilc_lvho07_r = "eurostat_ilc_lvho07_r")

es_pais_eurostat <- function(geo) grepl("^[A-Z]{2}$", geo) & !geo %in% AGREGADOS_EUROSTAT

# Bandera de Eurostat de cada cifra (NA si la descarga no la trae).
bandera_eurostat <- function(europa, tabla, geo, anio, tenencia = "TOTAL", edad = "TOTAL") {
  clave <- paste(europa$conjunto, europa$geo, europa$anio, europa$tenencia, europa$edad)
  europa$bandera[match(paste(tabla, geo, anio, tenencia, edad), clave)]
}

# Filas de una vista con las columnas de la web: puesto, geo, nivel, bloque, valor, fuente, tabla,
# bandera, n (personas), hogares y fiabilidad.
COLUMNAS_VISTA_SOBRECARGA <- c("puesto", "geo", "nivel", "bloque", "valor", "fuente", "tabla", "bandera", "n",
                               "hogares", "fiabilidad")

# Toda la población, un año: la escalera de ese año con las cifras del INE donde las hay.
vista_total_sobrecarga <- function(europa, anual, anio) {
  esc <- armar_escalera(europa, anio)
  ine <- anual |>
    filter(.data$anio == .env$anio, corte %in% c("total", "region")) |>
    transmute(geo = if_else(corte == "total", "ES", grupo), valor_ine = valor, n = n_personas, hogares = n_hogares)
  esc |>
    mutate(tabla = if_else(bloque == "referencia", "ilc_lvho07a", "ilc_lvho07_r")) |>
    left_join(ine, by = "geo") |>
    mutate(
      del_ine = !is.na(valor_ine) & (bloque == "comunidad" | geo == "ES"),
      valor = if_else(del_ine, valor_ine, valor),
      fuente = if_else(del_ine, "ine_ecv", unname(TABLA_EUROSTAT_FUENTE[tabla])),
      bandera = if_else(del_ine, NA_character_, bandera_eurostat(europa, tabla, geo, .env$anio)),
      tabla = if_else(del_ine, NA_character_, tabla),
      n = if_else(del_ine, n, NA_integer_), hogares = if_else(del_ine, hogares, NA_integer_),
      fiabilidad = if_else(del_ine, fiabilidad_eusilc(n), NA_character_),
      valor = if_else(!is.na(fiabilidad) & fiabilidad == "no publicable", NA_real_, valor)
    ) |>
    select(all_of(COLUMNAS_VISTA_SOBRECARGA))
}

# Tenencia o edad, un año: países de Eurostat, comunidades con las olas agrupadas de la ECV y las
# referencias (UE-27 de Eurostat; España, la ola del año). Ordenadas de más a menos; sin valor, al final.
vista_desglose_sobrecarga <- function(europa, agrupada, anual, corte, grupo, anio) {
  tabla <- if (corte == "tenencia") "ilc_lvho07c" else "ilc_lvho07a"
  eu <- europa |>
    filter(conjunto == tabla, .data$anio == .env$anio,
           tenencia == if (corte == "tenencia") grupo else "TOTAL",
           edad == if (corte == "edad") grupo else "TOTAL")
  ten <- if (corte == "tenencia") grupo else "TOTAL"
  ed <- if (corte == "edad") grupo else "TOTAL"
  desde_eurostat <- function(d, bloque, nivel) {
    d |> transmute(geo, nivel = nivel, bloque = bloque, valor, fuente = unname(TABLA_EUROSTAT_FUENTE[tabla]),
                   tabla = tabla, bandera = bandera_eurostat(europa, tabla, geo, .env$anio, ten, ed),
                   n = NA_integer_, hogares = NA_integer_, fiabilidad = NA_character_)
  }
  paises <- desde_eurostat(filter(eu, es_pais_eurostat(geo), geo != "ES"), "europa", 0L)
  ue <- desde_eurostat(filter(eu, geo == "EU27_2020"), "referencia", NA_integer_)
  espana <- anual |>
    filter(.data$anio == .env$anio, .data$corte == .env$corte, .data$grupo == .env$grupo) |>
    transmute(geo = "ES", nivel = NA_integer_, bloque = "referencia", valor, fuente = "ine_ecv", tabla = NA_character_,
              bandera = NA_character_, n = n_personas, hogares = n_hogares, fiabilidad = fiabilidad_eusilc(n_personas))
  comunidades <- agrupada |>
    filter(.data$corte == .env$corte, .data$grupo == .env$grupo) |>
    transmute(geo = region, nivel = 2L, bloque = "comunidad", valor, fuente = "ine_ecv", tabla = NA_character_,
              bandera = NA_character_, n = n_personas, hogares = n_hogares, fiabilidad = fiabilidad_eusilc(n_personas))
  bind_rows(paises, ue, espana, comunidades) |>
    mutate(valor = if_else(!is.na(fiabilidad) & fiabilidad == "no publicable", NA_real_, valor)) |>
    arrange(is.na(valor), desc(valor)) |>
    mutate(puesto = if_else(is.na(valor), NA_integer_, row_number())) |>
    select(all_of(COLUMNAS_VISTA_SOBRECARGA))
}

# Todas las vistas: el total de cada año con regiones y cada grupo de GRUPOS_MAPA_SOBRECARGA el
# último año. Una lista con corte, grupo, año, versión NUTS y filas.
vistas_sobrecarga <- function(europa, anual, agrupada) {
  anios <- sort(unique(europa$anio[europa$conjunto == "ilc_lvho07_r"]))
  ultimo <- max(anios)
  totales <- lapply(anios, function(a) {
    list(clave = paste0("total-", a), corte = "total", grupo = "total", anio = a,
         filas = vista_total_sobrecarga(europa, anual, a))
  })
  desgloses <- unlist(lapply(names(GRUPOS_MAPA_SOBRECARGA), function(corte) {
    lapply(GRUPOS_MAPA_SOBRECARGA[[corte]], function(g) {
      list(clave = paste(corte, g, ultimo, sep = "-"), corte = corte, grupo = g, anio = ultimo,
           filas = vista_desglose_sobrecarga(europa, agrupada, anual, corte, g, ultimo))
    })
  }), recursive = FALSE)
  vistas <- Filter(function(v) nrow(v$filas) > 0, c(totales, desgloses))     # un grupo sin datos no se ofrece
  lapply(vistas, function(v) c(v, list(nuts = unname(version_nuts(v$anio)))))
}

# Serie de España y de la UE-27 (Eurostat) desde el primer año publicado de cualquiera de las
# cuatro (pregunta abierta 30: España, el total desde 2004 y el alquiler a precio de mercado desde
# 2007; la UE-27, desde 2010): toda la población (ilc_lvho07a) e inquilinos a precio de mercado
# (ilc_lvho07c), con la marca de Eurostat de cada año (b: ruptura de serie; e: estimado…).
SERIES_ESPANA_SOBRECARGA <- list(
  ES_TOTAL = c(tabla = "ilc_lvho07a", geo = "ES", tenencia = "TOTAL"),
  ES_RENT_MKT = c(tabla = "ilc_lvho07c", geo = "ES", tenencia = "RENT_MKT"),
  EU27_TOTAL = c(tabla = "ilc_lvho07a", geo = "EU27_2020", tenencia = "TOTAL"),
  EU27_RENT_MKT = c(tabla = "ilc_lvho07c", geo = "EU27_2020", tenencia = "RENT_MKT")
)

# Rupturas de cada serie dentro de sus años (sin `rupturas`, ninguna), como enteros.
rupturas_en_serie <- function(rupturas, anios) {
  if (is.null(rupturas)) rupturas <- lapply(SERIES_ESPANA_SOBRECARGA, function(s) integer())
  lapply(rupturas, function(a) as.integer(a[a %in% anios]))
}

serie_espana_sobrecarga <- function(europa) {
  filas <- lapply(SERIES_ESPANA_SOBRECARGA, function(s) {
    europa[europa$conjunto == s[["tabla"]] & europa$geo == s[["geo"]] & europa$tenencia == s[["tenencia"]] &
             europa$edad == "TOTAL", ]
  })
  anios <- seq(min(unlist(lapply(filas, `[[`, "anio"))), max(europa$anio))
  list(anios = anios,
       valores = lapply(filas, function(d) d$valor[match(anios, d$anio)]),
       marcas = lapply(filas, function(d) d$bandera[match(anios, d$anio)]))
}

# Rupturas del atlas en la serie de España (pregunta abierta 34): las del indicador 22 de la ECV
# en inventario/rupturas.csv con estado «aplicado», que Eurostat no marca (ecv_ingresos_2013: desde
# 2013, los ingresos salen de la entrevista y de registros administrativos). La web corta ahí la
# línea, como en las rupturas «b» de Eurostat, con su propia nota. Años de cada serie de
# SERIES_ESPANA_SOBRECARGA: las de España, todas; las de la UE-27, ninguna.
rupturas_serie_sobrecarga <- function(rupturas) {
  del_22 <- vapply(strsplit(as.character(rupturas$indicador), ";", fixed = TRUE), function(i) "22" %in% i, TRUE)
  r <- rupturas[rupturas$fuente == "ine_ecv" & rupturas$estado == "aplicado" & del_22, ]
  anios <- sort(unique(as.integer(unlist(strsplit(as.character(r$anio), ";", fixed = TRUE)))))
  lapply(SERIES_ESPANA_SOBRECARGA, function(s) if (s[["geo"]] == "ES") anios else integer())
}

# Módulo de acceso (indicador 23): búsqueda sin éxito por comunidad (con su código NUTS 2), edad,
# sexo y tenencia, y razones de quien buscó sin éxito (España).
modulo_sobrecarga_web <- function(modulo_ccaa, modulo_edad, modulo_tenencia, ccaa) {
  pct <- paste(MEDIDA_BUSQUEDA, "(%)")
  com <- modulo_ccaa |> rename(nombre = 1) |> filter(medida == pct)
  total <- com$valor[com$nombre == "Total"]
  com <- com |> filter(nombre != "Total") |> left_join(select(ccaa, nombre = nombre_ine, nuts2), by = "nombre")
  if (anyNA(com$nuts2)) stop("Comunidades del m\u00f3dulo sin c\u00f3digo: ", paste(com$nombre[is.na(com$nuts2)], collapse = ", "),
                             call. = FALSE)
  e <- modulo_edad |> rename(sexo = 1, edad = 2) |> filter(medida == pct)
  t <- modulo_tenencia |> rename(tenencia = 1) |> filter(medida == pct, tenencia != "Total")
  razones <- modulo_ccaa |> rename(nombre = 1) |> filter(nombre == "Total", medida %in% names(RAZONES_MODULO))
  list(
    total = total,
    ccaa = tibble::tibble(geo = com$nuts2, valor = com$valor),
    edad = e |> filter(sexo == "Ambos sexos", edad != "Total") |>
      transmute(grupo = unname(GRUPOS_MODULO$edad[edad]), valor),
    sexo = e |> filter(sexo != "Ambos sexos", edad == "Total") |>
      transmute(grupo = unname(GRUPOS_MODULO$sexo[sexo]), valor),
    tenencia = t |> transmute(grupo = unname(GRUPOS_MODULO$tenencia[tenencia]), valor),
    razones = razones |> transmute(grupo = unname(RAZONES_MODULO[medida]), valor)
  )
}

# Razones de quien buscó vivienda sin éxito (porcentaje de esas personas), en las tablas del módulo.
RAZONES_MODULO <- c("Precio excesivo" = "precio", "La vivienda no reun\u00eda los requisitos que busco" = "vivienda",
                    "Yo no reun\u00eda las condiciones necesarias para el alquiler/compra" = "condiciones",
                    "Otras razones" = "otras")

# --- Geometrías ---------------------------------------------------------------------------------

marco_sobrecarga <- function(m = MARCO_SOBRECARGA_3035) {
  sf::st_as_sfc(sf::st_bbox(m, crs = sf::st_crs(3035)))
}

# Desplazamiento de cada recuadro: las islas de cada código de RECUADROS_SOBRECARGA (la región y las
# mismas partes de su país) se llevan, por orden, a una columna en el Atlántico, en el borde
# izquierdo del marco, de abajo arriba.
recuadros_sobrecarga <- function(regiones, codigos = RECUADROS_SOBRECARGA, marco = MARCO_SOBRECARGA_3035,
                                 margen = 30000, hueco = 90000) {
  x <- marco[["xmin"]] + 60000
  y <- marco[["ymin"]] + 60000
  filas <- list()
  for (codigo in codigos) {
    g <- regiones[regiones$id == codigo, ]
    if (!nrow(g)) next
    caja <- sf::st_bbox(g)
    dx <- x - caja[["xmin"]]
    dy <- y - caja[["ymin"]]
    filas[[codigo]] <- tibble::tibble(
      codigo = codigo, dx = dx, dy = dy,
      # caja de origen (con margen, para coger también las partes del país) y caja de destino
      oxmin = caja[["xmin"]] - 50000, oymin = caja[["ymin"]] - 50000, oxmax = caja[["xmax"]] + 50000,
      oymax = caja[["ymax"]] + 50000,
      dxmin = x - margen, dymin = y - margen, dxmax = caja[["xmax"]] + dx + margen, dymax = caja[["ymax"]] + dy + margen
    )
    y <- caja[["ymax"]] + dy + hueco
  }
  bind_rows(filas)
}

# Pasa de la LAEA de Europa a las coordenadas del mapa (ver la cabecera del fichero).
a_coordenadas_mapa <- function(geometria) {
  g <- sf::st_set_crs(sf::st_geometry(geometria), NA)
  g <- (g - CENTRO_SOBRECARGA_3035) |> sf::st_set_crs(3857)
  sf::st_transform(g, 4326)
}

# Países (NUTS 0), regiones (NUTS 2) y las NUTS 1 de `codigos_nuts1`, recortados al marco, con las
# islas de los recuadros desplazadas y en coordenadas del mapa. `respaldo`: códigos que esta versión
# no trae y se toman de otra (vector con nombre: código = ruta del fichero NUTS de donde sale; pregunta
# abierta 29). Columnas: id, nivel, pais y tipo («region» o «recuadro», el marco de cada recuadro
# como línea).
geometrias_sobrecarga_web <- function(ruta, codigos_nuts1 = character(), respaldo = character()) {
  leer <- function(r, quedarse) {
    n <- sf::st_read(r, quiet = TRUE)
    n <- n[quedarse(n), ]
    sf::st_sf(id = n$NUTS_ID, nivel = as.integer(n$LEVL_CODE), pais = n$CNTR_CODE,
              geometry = sf::st_transform(sf::st_make_valid(sf::st_geometry(n)), 3035))
  }
  x <- leer(ruta, function(n) n$LEVL_CODE %in% c(0, 2) | n$NUTS_ID %in% codigos_nuts1)
  for (r in unique(respaldo)) {
    x <- rbind(x, leer(r, function(n) n$NUTS_ID %in% setdiff(names(respaldo)[respaldo == r], x$id)))
  }
  x <- suppressWarnings(sf::st_collection_extract(x, "POLYGON"))
  rec <- recuadros_sobrecarga(x[x$nivel == 2, ])
  partes <- suppressWarnings(sf::st_cast(sf::st_cast(x, "MULTIPOLYGON"), "POLYGON"))
  centro <- sf::st_coordinates(suppressWarnings(sf::st_point_on_surface(sf::st_geometry(partes))))
  geom <- sf::st_set_crs(sf::st_geometry(partes), NA)
  for (k in seq_len(nrow(rec))) {
    r <- rec[k, ]
    dentro <- centro[, 1] >= r$oxmin & centro[, 1] <= r$oxmax & centro[, 2] >= r$oymin & centro[, 2] <= r$oymax &
      partes$pais == substr(r$codigo, 1, 2)
    if (any(dentro)) geom[dentro] <- geom[dentro] + c(r$dx, r$dy)
  }
  partes <- sf::st_set_geometry(partes, sf::st_sfc(lapply(geom, identity), crs = 3035))
  partes <- suppressWarnings(sf::st_intersection(partes, marco_sobrecarga()))
  partes <- suppressWarnings(sf::st_collection_extract(partes, "POLYGON"))
  regiones <- partes |>
    group_by(id, nivel, pais) |>
    summarise(do_union = FALSE, .groups = "drop") |>
    sf::st_cast("MULTIPOLYGON") |>
    mutate(tipo = "region")
  marcos <- if (nrow(rec)) {
    cajas <- lapply(seq_len(nrow(rec)), function(k) {
      r <- rec[k, ]
      sf::st_linestring(matrix(c(r$dxmin, r$dymin, r$dxmax, r$dymin, r$dxmax, r$dymax, r$dxmin, r$dymax, r$dxmin, r$dymin),
                               ncol = 2, byrow = TRUE))
    })
    sf::st_sf(id = paste0("recuadro_", rec$codigo), nivel = NA_integer_, pais = substr(rec$codigo, 1, 2), tipo = "recuadro",
              geometry = sf::st_sfc(cajas, crs = 3035))
  }
  todo <- rbind(sf::st_cast(regiones, "GEOMETRY"), if (!is.null(marcos)) sf::st_cast(marcos, "GEOMETRY"))
  sf::st_set_geometry(todo, a_coordenadas_mapa(todo))
}

# Límites del marco en coordenadas del mapa (oeste, sur, este, norte), para encuadrar.
limites_sobrecarga <- function() {
  round(unname(as.numeric(sf::st_bbox(a_coordenadas_mapa(marco_sobrecarga())))), 4)
}

# Nombres de las regiones (NUTS 1 y 2, en alfabeto latino) de un fichero NUTS de GISCO.
nombres_nuts <- function(ruta) {
  n <- sf::st_drop_geometry(sf::st_read(ruta, quiet = TRUE))
  n <- n[n$LEVL_CODE %in% c(1, 2), ]
  stats::setNames(n$NAME_LATN, n$NUTS_ID)
}

# --- Exportación ----------------------------------------------------------------------------------

# Una cifra en el JSON: valor × 10 en entero (null sin valor) y, si los hay, su muestra o su bandera.
filas_json_sobrecarga <- function(filas) {
  lapply(seq_len(nrow(filas)), function(i) {
    f <- filas[i, ]
    x <- list(puesto = f$puesto, geo = f$geo, nivel = f$nivel, bloque = f$bloque, v = valor_web(f$valor),
              fuente = f$fuente, tabla = f$tabla, bandera = f$bandera, n = f$n, hogares = f$hogares,
              fiabilidad = f$fiabilidad)
    x[!vapply(x, function(y) length(y) == 1 && is.na(y), TRUE) | names(x) %in% c("v", "puesto")]
  })
}

# Códigos que pinta cada versión NUTS y, de los que no trae, de qué versión posterior salen
# (version_geometria(), R/fuente_gisco_nuts.R). También los países de una versión posterior que
# faltan en esta, para que el fondo no tenga huecos. Devuelve, por versión, el vector de respaldo.
respaldos_geometria <- function(vistas, rutas_nuts) {
  atributos <- lapply(rutas_nuts, function(r) sf::st_drop_geometry(sf::st_read(r, quiet = TRUE))[c("NUTS_ID", "LEVL_CODE")])
  codigos <- lapply(atributos, `[[`, "NUTS_ID")
  versiones <- sort(unique(vapply(vistas, `[[`, "", "nuts")))
  stats::setNames(lapply(versiones, function(v) {
    pintados <- unique(unlist(lapply(vistas, function(x) if (x$nuts == v) x$filas$geo[x$filas$bloque != "referencia"])))
    faltan <- setdiff(pintados, codigos[[v]])
    posteriores <- names(codigos)[names(codigos) > v]
    paises <- setdiff(unlist(lapply(posteriores, function(p) atributos[[p]]$NUTS_ID[atributos[[p]]$LEVL_CODE == 0])),
                      codigos[[v]])
    todos <- unique(c(faltan, paises))
    origen <- version_geometria(todos, rep(v, length(todos)), codigos)
    stats::setNames(unname(rutas_nuts[origen[!is.na(origen)]]), todos[!is.na(origen)])
  }), versiones)
}

# Exportación completa a <dir_web>/datos/sobrecarga/. `modulos`: list(ccaa, edad, tenencia) del
# módulo de acceso; `rutas_nuts`: c("2021" = fichero_nuts_2021, "2024" = fichero_nuts_2024);
# `indicadores`: inventario/indicadores.csv (cortes del mapa); `quintil`: sobrecarga de España por
# quintil de renta (calcular_sobrecarga_quintil()). Borra antes lo exportado la vez anterior.
exportar_web_sobrecarga <- function(anual, agrupada, europa, ccaa, modulos, rutas_nuts, indicadores, quintil = NULL,
                                    rupturas = NULL, dir_web = "web", fecha = format(Sys.Date())) {
  dir <- file.path(dir_web, "datos", DIR_SOBRECARGA_WEB)
  cortes <- cortes_de_indicadores(indicadores)
  unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  vistas <- vistas_sobrecarga(europa, anual, agrupada)

  # Geometrías por versión NUTS, solo las versiones que usa alguna vista
  respaldos <- respaldos_geometria(vistas, rutas_nuts)
  rutas_geo <- character()
  for (v in names(respaldos)) {
    nuts1 <- unique(unlist(lapply(vistas, function(x) if (x$nuts == v) x$filas$geo[x$filas$nivel %in% 1L])))
    ruta <- file.path(dir, sprintf("nuts_%s.geojson", v))
    sf::st_write(geometrias_sobrecarga_web(rutas_nuts[[v]], nuts1, respaldos[[v]]), ruta, driver = "GeoJSON",
                 delete_dsn = TRUE, quiet = TRUE, layer_options = c("COORDINATE_PRECISION=3", "WRITE_BBOX=NO"))
    rutas_geo[v] <- ruta
  }
  versiones <- names(rutas_geo)
  nombres <- unlist(lapply(rev(versiones), function(v) nombres_nuts(rutas_nuts[[v]])))
  nombres <- nombres[!duplicated(names(nombres))]
  usados <- unique(unlist(lapply(vistas, function(x) x$filas$geo)))
  nombres <- nombres[names(nombres) %in% usados]

  serie <- serie_espana_sobrecarga(europa)
  modulo <- modulo_sobrecarga_web(modulos$ccaa, modulos$edad, modulos$tenencia, ccaa)
  con_v <- function(d, clave = "grupo") lapply(seq_len(nrow(d)), function(i) stats::setNames(list(d[[clave]][i], valor_web(d$valor[i])), c(clave, "v")))
  espana <- bind_rows(anual |> filter(corte != "region"),
                      if (!is.null(quintil)) select(quintil, anio, corte, grupo, valor, n_personas, n_hogares))
  datos <- list(
    version = fecha,
    escala = 10L,
    indicadores = list(sobrecarga = 22L, busqueda_sin_exito = 23L),
    anios = I(sort(unique(vapply(vistas[vapply(vistas, function(x) x$corte == "total", TRUE)], `[[`, 0L, "anio")))),
    anio_desgloses = max(vapply(vistas, `[[`, 0L, "anio")),
    olas = list(anuales = I(sort(unique(anual$anio))), agrupadas = I(c(unique(agrupada$anio_inicio), unique(agrupada$anio_fin)))),
    cortes = lapply(cortes, I),
    grupos_mapa = lapply(GRUPOS_MAPA_SOBRECARGA, I),
    geometrias = stats::setNames(as.list(file.path("datos", DIR_SOBRECARGA_WEB, basename(rutas_geo))), names(rutas_geo)),
    limites = I(limites_sobrecarga()),
    recuadros = I(RECUADROS_SOBRECARGA),
    vistas = lapply(vistas, function(x) list(clave = x$clave, corte = x$corte, grupo = x$grupo, anio = x$anio, nuts = x$nuts,
                                             filas = filas_json_sobrecarga(x$filas))),
    espana = list(
      serie = list(anios = I(serie$anios), fuente = "eurostat_ilc_lvho07",
                   valores = lapply(serie$valores, function(v) I(valor_web(v))),
                   marcas = lapply(serie$marcas, I),
                   rupturas_atlas = lapply(rupturas_en_serie(rupturas, serie$anios), I)),
      anual = lapply(seq_len(nrow(espana)), function(i) {
        f <- espana[i, ]
        fiabilidad <- fiabilidad_eusilc(f$n_personas)
        list(anio = f$anio, corte = f$corte, grupo = if (f$corte == "total") "total" else f$grupo,
             v = valor_web(if (fiabilidad == "no publicable") NA_real_ else f$valor),
             n = f$n_personas, hogares = f$n_hogares, fiabilidad = fiabilidad)
      })
    ),
    comunidades = stats::setNames(lapply(seq_len(nrow(ccaa)), function(i) list(codigo = ccaa$codigo[i], nombre = ccaa$nombre_ine[i])),
                                  ccaa$nuts2),
    nombres = as.list(nombres),
    modulo = list(anio = 2025L, fuente = "ine_ecv_modulo", total = valor_web(modulo$total),
                  ccaa = con_v(modulo$ccaa, "geo"), edad = con_v(modulo$edad), sexo = con_v(modulo$sexo),
                  tenencia = con_v(modulo$tenencia), razones = con_v(modulo$razones))
  )
  ruta <- file.path(dir, "sobrecarga.json")
  jsonlite::write_json(datos, ruta, auto_unbox = TRUE, digits = NA, na = "null", null = "null")
  unname(c(ruta, rutas_geo))
}

# --- Compuerta (ida y vuelta) ---------------------------------------------------------------------

# Lee lo exportado y lo compara con los objetivos del pipeline, cifra a cifra:
#   web_sobrecarga_valores (bloqueo): por vista y por bloque, cifras cuyo valor (÷ 10), puesto o
#     fuente no reproducen los objetivos (con el redondeo de la guía), y territorios de más o de menos;
#   web_sobrecarga_muestra (bloqueo): cifras del INE sin número de observaciones, con una marca de
#     fiabilidad que no es la de EU-SILC para su muestra o publicadas con menos de 20 observaciones;
#     cifras de Eurostat sin su tabla o con una marca distinta de la de la fuente;
#   web_sobrecarga_geometria (alerta): territorios de una vista que el mapa no puede pintar (sin
#     geometría en su versión NUTS ni de respaldo) y vistas cuya geometría no se lee.
# `indicadores` (cortes del mapa) y `quintil` (España por quintil de renta), como en la exportación.
comprobar_web_sobrecarga <- function(anual, agrupada, europa, escalera, ccaa, modulos, indicadores, quintil = NULL,
                                     rupturas = NULL, dir_web = "web") {
  dir <- file.path(dir_web, "datos", DIR_SOBRECARGA_WEB)
  x <- jsonlite::fromJSON(file.path(dir, "sobrecarga.json"), simplifyVector = FALSE)
  escala <- x$escala
  num <- function(v) if (is.null(v)) NA_real_ else as.numeric(v) / escala
  campo <- function(l, n, tipo = NA) vapply(l, function(f) if (is.null(f[[n]])) tipo else as(f[[n]], class(tipo)), tipo)
  distinto <- function(a, b) xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) > 1e-9)
  marca_distinta <- function(a, b) xor(is.na(a), is.na(b)) | (!is.na(a) & !is.na(b) & a != b)
  filas <- list()
  # Un fallo por cada TRUE; lo que no se puede comparar (NA) cuenta también como fallo
  anota <- function(id, detalle, mal) {
    filas[[length(filas) + 1L]] <<- tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(sum(mal | is.na(mal))))
  }
  # Sin valor publicable con menos de 20 observaciones (EU-SILC)
  publicable <- function(valor, n) ifelse(!is.na(n) & fiabilidad_eusilc(n) == "no publicable", NA_real_, valor)
  geometrias <- list()
  ue <- function(tabla, geo, anio, tenencia = "TOTAL", edad = "TOTAL", campo = "valor") {
    clave <- paste(europa$conjunto, europa$geo, europa$anio, europa$tenencia, europa$edad)
    europa[[campo]][match(paste(tabla, geo, anio, tenencia, edad), clave)]
  }

  # Cortes del mapa: los de inventario/indicadores.csv
  esperados <- cortes_de_indicadores(indicadores)
  anota("web_sobrecarga_valores", "cortes del mapa",
        !setequal(names(x$cortes), names(esperados)) ||
          any(vapply(names(esperados), function(k) !identical(as.numeric(unlist(x$cortes[[k]])), esperados[[k]]), TRUE)))
  del_ine <- function(geo, anio, corte, grupo, agrupado) {
    if (agrupado) {
      d <- agrupada[agrupada$corte == corte & agrupada$grupo == grupo, ]
      i <- match(geo, d$region)
    } else {
      d <- anual[anual$anio == anio, ]
      i <- match(paste(ifelse(geo == "ES", corte, "region"), ifelse(geo == "ES", grupo, geo)), paste(d$corte, d$grupo))
    }
    list(valor = d$valor[i], n = d$n_personas[i], hogares = d$n_hogares[i])
  }

  # Vistas del mapa
  ine_leidas <- list()
  for (vista in x$vistas) {
    f <- vista$filas
    geo <- campo(f, "geo", ""); bloque <- campo(f, "bloque", ""); fuente <- campo(f, "fuente", "")
    v <- vapply(f, function(r) num(r$v), 0); puesto <- campo(f, "puesto", NA_integer_)
    tabla <- campo(f, "tabla", NA_character_)
    if (vista$corte == "total") {
      esperado <- armar_escalera(europa, vista$anio)
      if (vista$anio == unique(escalera$anio)) {
        esperado_obj <- escalera[c("puesto", "geo", "bloque", "valor")]
        anota("web_sobrecarga_valores", paste(vista$clave, "frente al objetivo escalera"),
              !isTRUE(all.equal(as.data.frame(esperado[c("puesto", "geo", "bloque", "valor")]), as.data.frame(esperado_obj),
                                check.attributes = FALSE)))
      }
      m <- match(geo, esperado$geo)
      ine <- del_ine(geo, vista$anio, "total", "TOTAL", FALSE)
      es_ine <- !is.na(ine$valor) & (bloque == "comunidad" | geo == "ES")
      ref <- ifelse(es_ine, publicable(ine$valor, ine$n), esperado$valor[m])
      mal <- is.na(m) | distinto(v, redondeo_guia(ref)) | puesto != esperado$puesto[m] | bloque != esperado$bloque[m] |
        fuente != ifelse(es_ine, "ine_ecv", unname(TABLA_EUROSTAT_FUENTE[ifelse(bloque == "referencia", "ilc_lvho07a", "ilc_lvho07_r")]))
      faltan <- length(setdiff(esperado$geo, geo)) + sum(duplicated(geo))
    } else {
      t_eu <- if (vista$corte == "tenencia") "ilc_lvho07c" else "ilc_lvho07a"
      ten <- if (vista$corte == "tenencia") vista$grupo else "TOTAL"
      ed <- if (vista$corte == "edad") vista$grupo else "TOTAL"
      d_eu <- europa[europa$conjunto == t_eu & europa$anio == vista$anio & europa$tenencia == ten & europa$edad == ed, ]
      con_es <- any(anual$anio == vista$anio & anual$corte == vista$corte & anual$grupo == vista$grupo)
      esperados <- c(d_eu$geo[(es_pais_eurostat(d_eu$geo) & d_eu$geo != "ES") | d_eu$geo == "EU27_2020"],
                     if (con_es) "ES", unique(agrupada$region[agrupada$corte == vista$corte & agrupada$grupo == vista$grupo]))
      es_com <- bloque == "comunidad"
      ine <- del_ine(geo, vista$anio, vista$corte, vista$grupo, FALSE)
      ine_agr <- del_ine(geo, vista$anio, vista$corte, vista$grupo, TRUE)
      ref <- ifelse(es_com, publicable(ine_agr$valor, ine_agr$n),
                    ifelse(geo == "ES", publicable(ine$valor, ine$n), ue(t_eu, geo, vista$anio, ten, ed)))
      fuente_esp <- ifelse(es_com | geo == "ES", "ine_ecv", unname(TABLA_EUROSTAT_FUENTE[t_eu]))
      bloque_esp <- ifelse(geo %in% c("EU27_2020", "ES"), "referencia", ifelse(grepl("^ES", geo), "comunidad", "europa"))
      mal <- !geo %in% esperados | distinto(v, redondeo_guia(ref)) | fuente != fuente_esp | bloque != bloque_esp
      # Puestos: 1, 2, 3… de más a menos valor; sin valor, sin puesto
      con_v <- which(!is.na(v))
      orden <- con_v[order(puesto[con_v])]
      mal_puesto <- !identical(as.integer(puesto[orden]), seq_along(con_v)) || is.unsorted(rev(v[orden])) ||
        any(!is.na(puesto[is.na(v)]))
      mal <- c(mal, mal_puesto)
      faltan <- length(setdiff(esperados, geo)) + sum(duplicated(geo))
    }
    anota("web_sobrecarga_valores", vista$clave, c(mal, rep(TRUE, faltan)))

    # Muestra de las cifras del INE
    agrupado <- vista$corte != "total" & bloque == "comunidad"
    n_leido <- campo(f, "n", NA_integer_); h_leido <- campo(f, "hogares", NA_integer_)
    fia <- campo(f, "fiabilidad", NA_character_)
    ine_f <- fuente == "ine_ecv"
    esp_n <- ifelse(agrupado, del_ine(geo, vista$anio, vista$corte, vista$grupo, TRUE)$n,
                    del_ine(geo, vista$anio, if (vista$corte == "total") "total" else vista$corte,
                            if (vista$corte == "total") "TOTAL" else vista$grupo, FALSE)$n)
    esp_h <- ifelse(agrupado, del_ine(geo, vista$anio, vista$corte, vista$grupo, TRUE)$hogares,
                    del_ine(geo, vista$anio, if (vista$corte == "total") "total" else vista$corte,
                            if (vista$corte == "total") "TOTAL" else vista$grupo, FALSE)$hogares)
    mal_muestra <- ine_f & (is.na(n_leido) | is.na(h_leido) | n_leido != esp_n | h_leido != esp_h | is.na(fia) |
                              fia != fiabilidad_eusilc(n_leido) | (fia == "no publicable" & !is.na(v)))
    # Cifras de Eurostat: con su tabla, sin muestra y con la marca de la fuente
    ten_v <- if (vista$corte == "tenencia") vista$grupo else "TOTAL"
    ed_v <- if (vista$corte == "edad") vista$grupo else "TOTAL"
    bandera <- campo(f, "bandera", NA_character_)
    marca_fuente <- ifelse(is.na(tabla), NA_character_, ue(tabla, geo, vista$anio, ten_v, ed_v, "bandera"))
    mal_muestra <- (ine_f & mal_muestra) |
      (!ine_f & (!is.na(n_leido) | !is.na(fia) | is.na(tabla) | marca_distinta(bandera, marca_fuente)))
    anota("web_sobrecarga_muestra", vista$clave, mal_muestra)

    # Geometría de la vista: territorios que el mapa no puede pintar
    if (is.null(geometrias[[vista$nuts]])) {
      ruta_geo <- file.path(dir_web, x$geometrias[[vista$nuts]])
      geometrias[[vista$nuts]] <- tryCatch(sf::st_read(ruta_geo, quiet = TRUE)$id, error = function(e) character())
    }
    anota("web_sobrecarga_geometria", vista$clave, !geo[bloque != "referencia"] %in% geometrias[[vista$nuts]])
  }

  # Serie de España y de la UE-27 (Eurostat)
  s <- x$espana$serie
  anios <- as.integer(unlist(s$anios))
  series <- SERIES_ESPANA_SOBRECARGA
  primero <- min(unlist(lapply(series, function(k) {
    europa$anio[europa$conjunto == k[["tabla"]] & europa$geo == k[["geo"]] & europa$tenencia == k[["tenencia"]] &
                  europa$edad == "TOTAL"]
  })))
  mal <- c(!identical(anios, seq(primero, max(europa$anio))), !setequal(names(s$valores), names(series)),
           !setequal(names(s$marcas), names(series)))
  for (k in names(series)) {
    leido <- vapply(s$valores[[k]], num, 0)
    marcas <- vapply(s$marcas[[k]], function(b) if (is.null(b)) NA_character_ else as.character(b), "")
    esperado <- ue(series[[k]][["tabla"]], series[[k]][["geo"]], anios, series[[k]][["tenencia"]])
    marca_esperada <- ue(series[[k]][["tabla"]], series[[k]][["geo"]], anios, series[[k]][["tenencia"]], campo = "bandera")
    mal <- c(mal, if (length(leido) != length(anios) || length(marcas) != length(anios)) TRUE else
      distinto(leido, redondeo_guia(esperado)) | marca_distinta(marcas, marca_esperada))
  }
  anota("web_sobrecarga_valores", "serie de Espa\u00f1a", mal)
  # Rupturas del atlas (rupturas_serie_sobrecarga): las mismas que en inventario/rupturas.csv
  esperadas <- rupturas_en_serie(rupturas, anios)
  leidas <- lapply(s$rupturas_atlas, function(v) as.integer(unlist(v)))
  anota("web_sobrecarga_valores", "rupturas del atlas en la serie de Espa\u00f1a",
        c(!setequal(names(leidas), names(esperadas)),
          vapply(names(esperadas), function(k) !identical(leidas[[k]], esperadas[[k]]), TRUE)))

  # Desgloses anuales de España (INE), con su muestra
  a <- x$espana$anual
  esp <- bind_rows(anual[anual$corte != "region", ],
                   if (!is.null(quintil)) select(quintil, anio, corte, grupo, valor, n_personas, n_hogares))
  clave_l <- paste(campo(a, "anio", 0L), campo(a, "corte", ""), campo(a, "grupo", ""))
  clave_e <- paste(esp$anio, esp$corte, ifelse(esp$corte == "total", "total", esp$grupo))
  m <- match(clave_e, clave_l)
  v_l <- vapply(a, function(r) num(r$v), 0)[m]
  mal <- is.na(m) | distinto(v_l, redondeo_guia(publicable(esp$valor, esp$n_personas)))
  anota("web_sobrecarga_valores", "desgloses anuales de Espa\u00f1a", c(mal, rep(TRUE, abs(length(a) - nrow(esp)))))
  n_l <- campo(a, "n", NA_integer_)[m]; h_l <- campo(a, "hogares", NA_integer_)[m]
  f_l <- campo(a, "fiabilidad", NA_character_)[m]
  anota("web_sobrecarga_muestra", "desgloses anuales de Espa\u00f1a",
        n_l != esp$n_personas | h_l != esp$n_hogares | f_l != fiabilidad_eusilc(esp$n_personas))

  # Módulo de acceso (indicador 23), frente a las tablas
  mod <- modulo_sobrecarga_web(modulos$ccaa, modulos$edad, modulos$tenencia, ccaa)
  leido <- x$modulo
  compara <- function(lista, d, clave = "grupo") {
    k <- campo(lista, clave, "")
    vl <- vapply(lista, function(r) num(r$v), 0)
    i <- match(d[[clave]], k)
    c(is.na(i) | distinto(vl[i], redondeo_guia(d$valor)), rep(TRUE, abs(length(lista) - nrow(d))))
  }
  anota("web_sobrecarga_valores", "m\u00f3dulo de acceso",
        c(distinto(num(leido$total), redondeo_guia(mod$total)), compara(leido$ccaa, mod$ccaa, "geo"),
          compara(leido$edad, mod$edad), compara(leido$sexo, mod$sexo), compara(leido$tenencia, mod$tenencia),
          compara(leido$razones, mod$razones)))

  bind_rows(filas) |>
    mutate(anio = NA_integer_, referencia = 0, .after = id)
}
