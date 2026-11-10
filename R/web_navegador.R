# Prueba de la web en un navegador de verdad (Chrome sin ventana, con chromote; plan §6.5;
# backlog, «Siguiente»): la página, servida en local o ya publicada, recalcula una muestra en el
# navegador y coincide con R. No forma parte de tar_make(): necesita Chrome y, en local, node.
#
#   comprobar_web_navegador()                                          # la web local (web/)
#   comprobar_web_navegador("https://gastiaso.github.io/de-renta-en-renta/")   # la publicada
#
# Comprobaciones (id, detalle, calculado, referencia; todas deben dar 0):
#   navegador_arranque: la página arranca con los datos del pipeline (no la muestra de ejemplo)
#     y abre la ficha de una sección;
#   navegador_errores: errores de JavaScript o de carga durante toda la prueba;
#   navegador_sueldo: en una muestra de secciones y en todos los años, el sueldo necesario que
#     calcula la página con sus propios módulos (datos.js, formulas.js) frente al de la tabla
#     larga, redondeados a una décima, con su estado;
#   navegador_fiabilidad: contratos y margen de la mediana (vivienda colectiva, último año) que
#     lee la página frente a los de la tabla larga;
#   navegador_fichas: la ficha que pinta la página en unos casos escogidos (con mediana y muchos
#     contratos, con pocos, en secreto, con 0 contratos, y «¿te llega?» con el salario mínimo en
#     el límite entre dos tramos y lejos de él): su cifra, sus contratos y su margen, «pocos
#     contratos», «sin contratos de pisos» y «en el límite», frente a lo que sale de R.
#   navegador_redireccion: un enlace viejo a la raíz (con una sección, o con un sueldo tras «#»)
#     acaba en mapa.html con la misma vista, y el sueldo no queda en la dirección (portada, tarea 24);
#   navegador_portada: la portada carga, en castellano y en inglés, con sus 24 casillas, sin irse
#     al mapa, y sus cartas dan las cifras de la tabla larga (cifras_portada());
#   navegador_casillas: el destino de cada casilla activa, en los dos idiomas, existe (página y ancla);
#   navegador_tu_sueldo: «¿Te llega?» de la portada abre el mapa en «¿te llega?» con el sueldo, que
#     no aparece en la consulta;
#   navegador_movil: a 375 px de ancho, ni la portada ni el mapa desbordan;
#   navegador_territorio: la ficha de una comunidad, una provincia y un municipio (?territorio=…)
#     da la cifra y el estado de la tabla larga en su nivel (tarea 26);
#   navegador_clic: con el ratón sobre el mapa en cada escala (comunidad, provincia, municipio y
#     sección), la etiqueta dice el nombre que luego pone la ficha al pulsar (tareas 25 y 26).
# `larga`: la tabla larga (tar_read(tabla_larga)); `perfiles`: tar_read(perfiles), para el
# ingreso de la tartera que usa la web. El mapa está en mapa.html; la raíz es la portada.

# Programa de la página: recalcula la muestra con los módulos de la web y devuelve JSON.
JS_MUESTRA_NAVEGADOR <- r"(
(async (codigos) => {
  const base = document.baseURI;
  const D = await import(new URL('js/datos.js', base));
  const F = await import(new URL('js/formulas.js', base));
  const E = await import(new URL('js/exportar.js', base));
  const m = await D.cargarManifiesto();
  const idx = await D.cargarIndice(m, 'sc');
  const pos = codigos.map((c) => idx.indexOf(c));
  const def = m.mapas.sueldo_necesario;
  const anios = D.periodosDe(m.indicadores[def.base]);
  const sueldo = [];
  for (const a of anios) {
    const d = await D.cargarValores(m, def.base, 'sc', a);
    pos.forEach((i, k) => {
      const x = i < 0 ? null : d.valores[i];
      sueldo.push([codigos[k], a, x === null ? null : E.redondear(F.formulaDe(def).calcular(x, m.supuestos), 1),
        i < 0 ? null : m.codificacion.estados[d.estados[i]]]);
    });
  }
  const fia = m.indicadores[def.base].fiabilidad;
  const ultimo = anios.at(-1);
  const c = await D.cargarValores(m, fia.contratos, 'sc', ultimo);
  const g = await D.cargarValores(m, fia.margen, 'sc', ultimo);
  const fiabilidad = pos.map((i, k) => [codigos[k], i < 0 ? null : c.valores[i], i < 0 ? null : g.valores[i]]);
  return JSON.stringify({ sueldo, fiabilidad, ultimo, ejemplo: m.ejemplo });
})
)"

# Lectura de la ficha abierta: la cifra, los contratos, el margen y las marcas, como números.
JS_FICHA_NAVEGADOR <- r"(
(async () => {
  const f = document.getElementById('ficha');
  const { cargarIdioma } = await import(new URL('js/i18n.js', document.baseURI));
  const t = await cargarIdioma('es');
  const num = (s) => {
    if (!s) return null;
    const x = Number(s.replace(/[\s  %]/g, '').replace(/\./g, '').replace(',', '.'));
    return Number.isFinite(x) ? x : null;
  };
  const texto = f?.textContent ?? '';
  const fia = f?.querySelector('.ficha-fiabilidad')?.textContent ?? '';
  const contratos = fia.match(/(\d[\d.]*)/);
  const margen = fia.match(/±\s*([\d.,]+)/);
  const estados = t.existe('vocabulario.estado.secreto')
    ? ['secreto', 'estimado', 'dato', 'ausente'].find((e) => texto.includes(t(`vocabulario.estado.${e}`))) ?? null : null;
  const codigo = f?.querySelector('.ficha-codigo');
  return JSON.stringify({
    ruta: location.pathname,
    busqueda: location.search,
    hash: location.hash,
    seccion: (codigo?.textContent ?? '').replace(/\D/g, ''),
    nivel: codigo?.dataset.nivel ?? null,
    codigo: codigo?.dataset.codigo ?? null,
    nombre: codigo?.textContent ?? '',
    sin_nivel: Boolean(f?.querySelector('.ficha-sin-nivel')),
    estado: estados,
    cifra: num(f?.querySelector('.ficha-numero')?.textContent),
    contratos: contratos ? num(contratos[1]) : null,
    margen: margen ? num(margen[1]) : null,
    pocos: Boolean(f?.querySelector('.marca-pocos')),
    limite: Boolean(f?.querySelector('.ficha-limite')),
    sin_contratos: texto.includes(t('interfaz.ficha.sin_contratos.VC')),
    ejemplo: !document.getElementById('aviso-ejemplo')?.hidden,
  });
})()
)"

# Lectura de la portada: idioma, título, casillas, destinos de las activas y cartas.
JS_PORTADA_NAVEGADOR <- r"(
(() => JSON.stringify({
  ruta: location.pathname,
  lang: document.documentElement.lang,
  titulo: document.getElementById('portada-titulo')?.textContent ?? '',
  casillas: document.querySelectorAll('.casillas > li').length,
  primera: document.querySelector('.casillas .casilla-texto')?.textContent ?? '',
  destinos: [...document.querySelectorAll('.casillas > li > a')].map((a) => a.getAttribute('href')),
  cartas: [...document.querySelectorAll('#portada-cartas-lista .carta')].map((c) => ({ id: c.dataset.carta, texto: c.textContent })),
  listo: Boolean(document.getElementById('portada-dado-nota')?.textContent),
}))()
)"

# Comprueba en la página que cada destino existe: la página responde y, si lleva ancla, el id está.
JS_DESTINOS_NAVEGADOR <- r"(
(async (destinos) => {
  const r = [];
  for (const d of destinos) {
    const u = new URL(d, location.href);
    const res = await fetch(u, { cache: 'no-cache' });
    const html = res.ok ? await res.text() : '';
    const ancla = decodeURIComponent(u.hash.slice(1));
    r.push([d, res.status, !ancla || html.includes(`id="${ancla}"`)]);
  }
  return JSON.stringify(r);
})
)"

# Servidor local de la web (node web/servir.mjs) en un puerto libre; devuelve el proceso y la URL.
servir_web_local <- function(raiz = ".", espera = 15) {
  for (intento in 1:5) {
    puerto <- sample(20000:40000, 1)
    proceso <- processx::process$new("node", c(file.path(raiz, "web", "servir.mjs"), puerto),
                                     stdout = "|", stderr = "|", cleanup = TRUE)
    url_base <- sprintf("http://127.0.0.1:%d/", puerto)
    t0 <- Sys.time()
    while (proceso$is_alive() && difftime(Sys.time(), t0, units = "secs") < espera) {
      listo <- tryCatch({ readLines(url(paste0(url_base, "datos/manifiesto.json")), n = 1, warn = FALSE); TRUE },
                        error = function(e) FALSE)
      if (listo) return(list(proceso = proceso, url = url_base))
      Sys.sleep(0.3)
    }
    proceso$kill()
  }
  stop("No se ha podido servir la web en local (node web/servir.mjs)", call. = FALSE)
}

# Casos de la ficha: con mediana y muchos contratos, con pocos, en secreto, con 0 contratos, y
# «¿te llega?» con la tartera en el límite y lejos de él. Una fila por caso con lo esperado.
casos_ficha_navegador <- function(larga, ingreso_tartera, superficie = SUPERFICIE_FICHA, semilla = 20261109L) {
  ultimo <- max(larga$anio[larga$indicador == "sueldo_necesario" & larga$nivel == "sc"])
  ancho <- larga |>
    filter(nivel == "sc", anio == ultimo, corte %in% c("tipologia", "total"), grupo %in% c("VC", "total"),
           indicador %in% c("alquiler_m2", "contratos_alquiler", "margen_alquiler_m2", "sueldo_necesario")) |>
    select(geo_id, indicador, valor, estado) |>
    tidyr::pivot_wider(names_from = indicador, values_from = c(valor, estado))
  x <- ancho |>
    transmute(seccion = geo_id, estado = estado_alquiler_m2, contratos = valor_contratos_alquiler,
              margen = redondeo_guia(valor_margen_alquiler_m2), sueldo = valor_sueldo_necesario,
              ratio = termino_publicado(valor_alquiler_m2) * superficie / ingreso_tartera,
              limite = !is.na(ratio) & !is.na(margen) &
                tramo_llega(ratio * (1 - margen / 100)) != tramo_llega(ratio * (1 + margen / 100)))
  set.seed(semilla)
  uno <- function(d) d[sample.int(nrow(d), 1), ]
  bind_rows(
    uno(filter(x, estado == "dato", contratos >= 100)) |> mutate(caso = "mediana", ficha = NA_character_),
    uno(filter(x, estado == "dato", contratos < UMBRAL_POCOS_CONTRATOS)) |> mutate(caso = "pocos", ficha = NA_character_),
    uno(filter(x, estado == "secreto")) |> mutate(caso = "secreto", ficha = NA_character_),
    uno(filter(x, estado == "ausente", contratos %in% 0)) |> mutate(caso = "sin_contratos", ficha = NA_character_),
    uno(filter(x, estado == "dato", limite)) |> mutate(caso = "llega_limite", ficha = "tartera"),
    uno(filter(x, estado == "dato", !limite, ratio < 0.2)) |> mutate(caso = "llega_lejos", ficha = "tartera")
  )
}

# Tramo de «¿te llega?», como en web/js/sueldo.js: 0 hasta el 30 %, 1 hasta el 40 %, 2 por encima.
tramo_llega <- function(r) ifelse(r <= 0.3, 0L, ifelse(r <= 0.4, 1L, 2L))

comprobar_web_navegador <- function(url = NULL, larga, perfiles, muestra = 300L, raiz = ".", semilla = 20261109L,
                                    espera = 60) {
  servidor <- NULL
  if (is.null(url)) {
    servidor <- servir_web_local(raiz)
    on.exit(servidor$proceso$kill(), add = TRUE)
    url <- servidor$url
  }
  if (!endsWith(url, "/")) url <- paste0(url, "/")
  b <- chromote::ChromoteSession$new(width = 1280, height = 900)
  on.exit(b$close(), add = TRUE)
  errores <- character()
  b$Runtime$enable()
  b$Log$enable()
  b$Runtime$exceptionThrown(callback_ = function(e) {
    errores <<- c(errores, paste("excepcion:", e$exceptionDetails$exception$description %||% e$exceptionDetails$text))
  })
  b$Runtime$consoleAPICalled(callback_ = function(e) {
    if (identical(e$type, "error")) errores <<- c(errores, paste("consola:", e$args[[1]]$value %||% e$args[[1]]$description))
  })
  b$Log$entryAdded(callback_ = function(e) {
    if (identical(e$entry$level, "error")) errores <<- c(errores, paste("carga:", e$entry$text, e$entry$url %||% ""))
  })
  evaluar <- function(js) b$Runtime$evaluate(js, awaitPromise = TRUE, returnByValue = TRUE)$result$value

  # Opens the map page (mapa.html; with pagina = "", the old root link) with a chosen tract and
  # waits until its tract profile is drawn
  abrir <- function(consulta, seccion, pagina = "mapa.html") {
    b$Page$navigate(paste0(url, pagina, consulta))
    t0 <- Sys.time()
    repeat {
      Sys.sleep(0.5)
      listo <- tryCatch(evaluar(sprintf(
        "!!document.querySelector('#ficha .ficha-codigo') && document.querySelector('#ficha .ficha-codigo').textContent.includes('%s') && document.querySelectorAll('#ficha .ficha-estado').length > 0", seccion)),
        error = function(e) FALSE)
      if (isTRUE(listo)) return(jsonlite::fromJSON(evaluar(JS_FICHA_NAVEGADOR)))
      if (difftime(Sys.time(), t0, units = "secs") > espera) return(NULL)
    }
  }

  # La tartera del año que pinta la página (el último alquiler): la web usa el SMI de ese año
  ultimo <- max(larga$anio[larga$indicador == "sueldo_necesario" & larga$nivel == "sc"])
  tartera <- perfiles_web(perfiles)$tartera
  ingreso_tartera <- (tartera$anios[[as.character(ultimo)]] %||% tartera$neto_mensual)[["00"]]
  casos <- casos_ficha_navegador(larga, ingreso_tartera, semilla = semilla)
  filas <- list()

  # Fichas
  for (k in seq_len(nrow(casos))) {
    cs <- casos[k, ]
    consulta <- if (is.na(cs$ficha)) sprintf("?seccion=%s", cs$seccion) else sprintf("?ficha=%s&seccion=%s", cs$ficha, cs$seccion)
    f <- abrir(consulta, cs$seccion)
    if (k == 1L) {
      filas[[length(filas) + 1L]] <- tibble::tibble(
        id = "navegador_arranque", detalle = "datos del pipeline y ficha de una secci\u00f3n",
        calculado = as.numeric(is.null(f) || isTRUE(f$ejemplo)), referencia = 0)
    }
    esperada <- if (is.na(cs$ficha)) round(cs$sueldo) else 100 * cs$ratio
    tolerancia <- if (is.na(cs$ficha)) 0.5 else 0.05
    mal <- if (is.null(f)) 1 else {
      cifra_ok <- if (is.na(esperada) || cs$estado != "dato") is.null(f$cifra) else !is.null(f$cifra) && abs(f$cifra - esperada) <= tolerancia + 1e-9
      contratos_ok <- switch(cs$estado,
                             dato = identical(as.numeric(f$contratos), as.numeric(cs$contratos)) && !is.null(f$margen) &&
                               abs(f$margen - cs$margen) < 1e-9 && identical(f$pocos, cs$contratos < UMBRAL_POCOS_CONTRATOS),
                             secreto = identical(as.numeric(f$contratos), as.numeric(cs$contratos)) && is.null(f$margen),
                             ausente = isTRUE(f$sin_contratos) == isTRUE(cs$contratos == 0))
      limite_ok <- is.na(cs$ficha) || identical(f$limite, cs$limite)
      as.numeric(!(cifra_ok && contratos_ok && limite_ok))
    }
    filas[[length(filas) + 1L]] <- tibble::tibble(id = "navegador_fichas", detalle = paste(cs$caso, cs$seccion),
                                                  calculado = mal, referencia = 0)
  }

  # Old links to the root (the map was there until the front page): same view on mapa.html
  cs1 <- casos[1, ]
  f <- abrir(sprintf("?seccion=%s", cs1$seccion), cs1$seccion, pagina = "")
  filas[[length(filas) + 1L]] <- tibble::tibble(
    id = "navegador_redireccion", detalle = paste("?seccion=", cs1$seccion),
    calculado = as.numeric(is.null(f) || !endsWith(f$ruta, "/mapa.html") || !grepl(cs1$seccion, f$busqueda, fixed = TRUE)),
    referencia = 0)
  b$Page$navigate(paste0(url, "#sueldo=1500&pagas=14"))
  ok <- esperar_navegador(evaluar, "location.pathname.endsWith('/mapa.html') && document.getElementById('sueldo-neto')?.value === '1500' && !document.getElementById('sueldo-resumen')?.hidden", espera)
  dir <- if (ok) jsonlite::fromJSON(evaluar("JSON.stringify([location.search, location.hash])")) else c("?", "?")
  filas[[length(filas) + 1L]] <- tibble::tibble(
    id = "navegador_redireccion", detalle = "#sueldo=1500&pagas=14 (sueldo fuera de la direcci\u00f3n)",
    calculado = as.numeric(!ok || grepl("1500", paste(dir, collapse = "")) || nzchar(dir[2])), referencia = 0)

  # Front page, map by levels (tasks 24-26) and phone width
  filas <- c(filas, comprobar_portada_navegador(b, evaluar, url, larga, perfiles, espera),
             comprobar_territorios_navegador(b, evaluar, url, larga, espera))

  # Sample recomputed with the page modules
  sc <- unique(larga$geo_id[larga$nivel == "sc" & larga$indicador == "sueldo_necesario"])
  set.seed(semilla)
  codigos <- sample(sc, min(muestra, length(sc)))
  r <- jsonlite::fromJSON(evaluar(paste0(JS_MUESTRA_NAVEGADOR, "(", jsonlite::toJSON(codigos), ")")))
  pagina <- tibble::tibble(geo_id = r$sueldo[, 1], anio = as.integer(r$sueldo[, 2]),
                           pagina = suppressWarnings(as.numeric(r$sueldo[, 3])), estado_pagina = r$sueldo[, 4])
  esperado <- larga |>
    filter(indicador == "sueldo_necesario", nivel == "sc", geo_id %in% codigos) |>
    transmute(geo_id, anio, r = redondeo_guia(valor), estado)
  cruce <- full_join(pagina, esperado, by = c("geo_id", "anio")) |>
    mutate(mal = is.na(estado) | is.na(estado_pagina) | estado != estado_pagina | xor(is.na(r), is.na(pagina)) |
             coalesce(abs(r - pagina) > 1e-9, FALSE))
  filas[[length(filas) + 1L]] <- tibble::tibble(
    id = "navegador_sueldo", detalle = sprintf("%d secciones y %d a\u00f1os", length(codigos), dplyr::n_distinct(pagina$anio)),
    calculado = sum(cruce$mal), referencia = 0)
  fia <- tibble::tibble(geo_id = r$fiabilidad[, 1], contratos_pagina = suppressWarnings(as.numeric(r$fiabilidad[, 2])),
                        margen_pagina = suppressWarnings(as.numeric(r$fiabilidad[, 3])))
  fia_r <- larga |>
    filter(nivel == "sc", anio == as.integer(r$ultimo), grupo == "VC", geo_id %in% codigos,
           indicador %in% c("contratos_alquiler", "margen_alquiler_m2")) |>
    select(geo_id, indicador, valor) |>
    tidyr::pivot_wider(names_from = indicador, values_from = valor)
  if (!"margen_alquiler_m2" %in% names(fia_r)) fia_r$margen_alquiler_m2 <- NA_real_
  cruce_f <- left_join(fia, fia_r, by = "geo_id") |>
    mutate(mal = xor(is.na(contratos_pagina), is.na(contratos_alquiler)) | coalesce(contratos_pagina != contratos_alquiler, FALSE) |
             xor(is.na(margen_pagina), is.na(margen_alquiler_m2)) |
             coalesce(abs(margen_pagina - redondeo_guia(margen_alquiler_m2)) > 1e-9, FALSE))
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "navegador_fiabilidad", detalle = sprintf("%d secciones de %s", nrow(fia), r$ultimo),
                                                calculado = sum(cruce_f$mal), referencia = 0)
  if (isTRUE(r$ejemplo)) filas[[1]]$calculado <- 1

  # Errors of the whole check (collected while the browser messages are processed)
  b$Runtime$evaluate("1")
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "navegador_errores", detalle = paste(utils::head(errores, 5), collapse = " | "),
                                                calculado = length(errores), referencia = 0)
  bind_rows(filas) |> mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Espera (hasta `espera` segundos) a que una condicion de JavaScript sea cierta en la pagina.
esperar_navegador <- function(evaluar, condicion, espera = 60) {
  t0 <- Sys.time()
  repeat {
    Sys.sleep(0.5)
    if (isTRUE(tryCatch(evaluar(paste0("Boolean(", condicion, ")")), error = function(e) FALSE))) return(TRUE)
    if (difftime(Sys.time(), t0, units = "secs") > espera) return(FALSE)
  }
}

# Cifras de las cartas como las escribe la pagina en castellano (es-ES: punto de miles y coma
# decimal; enteros en los euros, un decimal en los porcentajes).
textos_cartas_navegador <- function(cifras) {
  euros <- function(x) formatC(round(x), format = "d", big.mark = ".", decimal.mark = ",")
  pct <- function(x) sub(".", ",", formatC(x, format = "f", digits = 1), fixed = TRUE)
  list(sueldo = euros(c(cifras$sueldo$mediana, cifras$sueldo$p10, cifras$sueldo$p90)),
       smi = pct(c(cifras$smi$pct_30, cifras$smi$pct_40)),
       sobrecarga = if (!is.null(cifras$sobrecarga)) pct(c(cifras$sobrecarga$total, cifras$sobrecarga$alquiler_mercado)))
}

# Portada (tarea 24): carga en los dos idiomas, sus cartas con las cifras de la tabla larga, los
# destinos de las casillas, «Tu sueldo» hasta el mapa sin el sueldo en la consulta y el ancho de
# un movil. Devuelve una lista de filas (tibbles) de comprobaciones.
comprobar_portada_navegador <- function(b, evaluar, url, larga, perfiles, espera = 60) {
  filas <- list()
  fila <- function(id, detalle, mal) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  b$Page$navigate(url)
  esperar_navegador(evaluar, "document.readyState === 'complete'", espera)
  hay_cartas <- isTRUE(evaluar("fetch('datos/portada.json', { cache: 'no-cache' }).then((r) => r.ok)"))
  esperados <- textos_cartas_navegador(cifras_portada(larga))
  for (idioma in c("es", "en")) {
    b$Page$navigate(paste0(url, if (idioma == "en") "?idioma=en" else ""))
    listo <- esperar_navegador(evaluar, sprintf(
      "document.documentElement.lang === '%s' && document.getElementById('portada-dado-nota')?.textContent && (!%s || document.querySelectorAll('#portada-cartas-lista .carta').length > 0)",
      idioma, tolower(hay_cartas)), espera)
    p <- if (listo) jsonlite::fromJSON(evaluar(JS_PORTADA_NAVEGADOR), simplifyVector = FALSE) else NULL
    mal <- is.null(p) || grepl("mapa\\.html$", p$ruta) || p$casillas != 24L || p$titulo != "De renta en renta" ||
      (idioma == "en" && p$primera != "Sign the lease") || (idioma == "es" && p$primera != "Firma el contrato")
    filas[[length(filas) + 1L]] <- fila("navegador_portada", paste("portada", idioma), mal)
    if (!is.null(p) && hay_cartas) {
      cartas <- stats::setNames(vapply(p$cartas, function(x) x$texto, ""), vapply(p$cartas, function(x) x$id, ""))
      for (id in names(esperados)) {
        if (is.null(esperados[[id]])) next
        texto <- cartas[id]
        mal <- is.na(texto) || (idioma == "es" && !all(vapply(esperados[[id]], function(e) grepl(e, texto, fixed = TRUE), TRUE)))
        filas[[length(filas) + 1L]] <- fila("navegador_portada", paste("carta", id, idioma), mal)
      }
    }
    if (!is.null(p)) {
      d <- jsonlite::fromJSON(evaluar(paste0(JS_DESTINOS_NAVEGADOR, "(", jsonlite::toJSON(unlist(p$destinos)), ")")))
      mal <- if (is.null(dim(d))) 1 else sum(d[, 2] != "200" | d[, 3] != "TRUE")
      filas[[length(filas) + 1L]] <- fila("navegador_casillas", sprintf("%d destinos (%s)", length(p$destinos), idioma), mal)
    }
  }

  # Te llega?: the typed pay reaches the map after the hash, never in the query
  b$Page$navigate(url)
  esperar_navegador(evaluar, "document.getElementById('portada-dado-nota')?.textContent", espera)
  evaluar("document.getElementById('portada-neto').value = '1.500'; document.getElementById('portada-sueldo').requestSubmit(); true")
  ok <- esperar_navegador(evaluar, "location.pathname.endsWith('/mapa.html') && document.getElementById('sueldo-neto')?.value === '1500' && !document.getElementById('sueldo-resumen')?.hidden", espera)
  dir <- if (ok) jsonlite::fromJSON(evaluar("JSON.stringify([location.search, location.hash])")) else c("?", "?")
  filas[[length(filas) + 1L]] <- fila("navegador_tu_sueldo", "1.500 \u20ac desde la portada",
                                      !ok || grepl("1500|[?&]sueldo=", dir[1]) || nzchar(dir[2]) || !grepl("ficha=peon", dir[1], fixed = TRUE))

  # Phone width: no horizontal overflow on the front page nor on the map. Afterwards, back to the
  # size of the session (clearing the override would also drop the size chromote set at the start)
  restaurar <- function() b$Emulation$setDeviceMetricsOverride(width = 1280, height = 900, deviceScaleFactor = 1, mobile = FALSE)
  b$Emulation$setDeviceMetricsOverride(width = 375, height = 812, deviceScaleFactor = 1, mobile = TRUE)
  on.exit(restaurar(), add = TRUE)
  for (pagina in c("", "mapa.html")) {
    b$Page$navigate(paste0(url, pagina))
    cond <- if (pagina == "") "document.getElementById('portada-dado-nota')?.textContent" else "document.querySelector('#ficha .ficha-vacia')"
    ok <- esperar_navegador(evaluar, cond, espera)
    Sys.sleep(1)
    anchos <- if (ok) jsonlite::fromJSON(evaluar("JSON.stringify([document.documentElement.scrollWidth, window.innerWidth])")) else c(1, 0)
    filas[[length(filas) + 1L]] <- fila("navegador_movil", paste("375 px:", if (pagina == "") "portada" else pagina), anchos[1] > anchos[2])
  }
  restaurar()
  filas
}

# Territorios (tarea 26) y etiqueta (tarea 25). Una ficha por nivel desde la direccion
# (?territorio=...) con la cifra y el estado de la tabla larga, un nivel sin la serie («sin dato
# en este nivel») y, en cada escala, el raton sobre el centro del mapa (Madrid): la etiqueta
# y la ficha que abre el clic dicen el mismo territorio.
comprobar_territorios_navegador <- function(b, evaluar, url, larga, espera = 60) {
  filas <- list()
  fila <- function(id, detalle, mal) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  esperada <- larga |>
    filter(indicador == "sueldo_necesario", corte == "total", nivel %in% c("ccaa", "provincia", "municipio")) |>
    group_by(nivel) |> filter(anio == max(anio)) |> ungroup()
  abrir_ficha <- function(consulta) {
    b$Page$navigate(paste0(url, "mapa.html", consulta))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]') && (document.querySelector('#ficha .ficha-estado') || document.querySelector('#ficha .ficha-sin-nivel'))", espera)
    if (ok) jsonlite::fromJSON(evaluar(JS_FICHA_NAVEGADOR)) else NULL
  }
  for (caso in list(c("ccaa", "13"), c("provincia", "28"), c("municipio", "28079"))) {
    f <- abrir_ficha(sprintf("?mapa=sueldo_necesario&territorio=%s:%s", caso[1], caso[2]))
    e <- esperada |> filter(nivel == caso[1], geo_id == caso[2])
    mal <- is.null(f) || nrow(e) != 1 || !identical(f$nivel, caso[1]) || !identical(f$codigo, caso[2]) ||
      !identical(f$estado, e$estado) || xor(is.na(e$valor), is.null(f$cifra)) ||
      (!is.na(e$valor) && !is.null(f$cifra) && abs(f$cifra - round(e$valor)) > 1e-9)
    filas[[length(filas) + 1L]] <- fila("navegador_territorio", paste(caso, collapse = ":"), mal)
  }
  # A map whose series is not published at that level: "no data at this level" (rule 1)
  f <- abrir_ficha("?mapa=renta_hogar&territorio=provincia:28")
  filas[[length(filas) + 1L]] <- fila("navegador_territorio", "renta_hogar en provincia:28 (sin dato en este nivel)",
                                      is.null(f) || !isTRUE(f$sin_nivel))

  # Mouse over the centre of the map at each scale: label first, then the profile of the click
  centro <- "(() => { const r = document.getElementById('mapa').getBoundingClientRect(); return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]); })()"
  etiqueta <- "JSON.stringify([...document.querySelectorAll('#mapa-etiqueta span')].map((s) => s.textContent))"
  for (escala in list(c("3.50", "ccaa"), c("4.50", "provincia"), c("6.00", "municipio"), c("13.00", "sc"))) {
    b$Page$navigate(sprintf("%smapa.html?mapa=sueldo_necesario&vista=%s/40.41680/-3.70380", url, escala[1]))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-vacia') && document.querySelector('.maplibregl-canvas')", espera)
    Sys.sleep(3)
    xy <- if (ok) jsonlite::fromJSON(evaluar(centro)) else c(0, 0)
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = xy[1] - 3, y = xy[2] - 3)
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = xy[1], y = xy[2])
    Sys.sleep(0.8)
    lineas <- jsonlite::fromJSON(evaluar(etiqueta))
    b$Input$dispatchMouseEvent(type = "mousePressed", x = xy[1], y = xy[2], button = "left", clickCount = 1)
    b$Input$dispatchMouseEvent(type = "mouseReleased", x = xy[1], y = xy[2], button = "left", clickCount = 1)
    ok <- ok && esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo')", 20)
    f <- if (ok) jsonlite::fromJSON(evaluar(JS_FICHA_NAVEGADOR)) else NULL
    mal <- if (is.null(f) || !length(lineas)) TRUE else if (escala[2] == "sc") {
      !is.null(f$nivel) || !grepl(f$seccion, lineas[3], fixed = TRUE) || !startsWith(f$seccion, "28079")
    } else {
      !identical(f$nivel, escala[2]) || !identical(f$nombre, lineas[1])
    }
    filas[[length(filas) + 1L]] <- fila("navegador_clic", sprintf("zoom %s: %s (%s)", escala[1], escala[2], paste(lineas, collapse = " / ")), mal)
  }
  filas
}
