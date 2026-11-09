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
# `larga`: la tabla larga (tar_read(tabla_larga)); `perfiles`: tar_read(perfiles), para el
# ingreso de la tartera que usa la web.

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
  return JSON.stringify({
    seccion: (f?.querySelector('.ficha-codigo')?.textContent ?? '').replace(/\D/g, ''),
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

  # Opens the page with a chosen tract and waits until its tract profile is drawn
  abrir <- function(consulta, seccion) {
    b$Page$navigate(paste0(url, consulta))
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

  ingreso_tartera <- perfiles_web(perfiles)$tartera$neto_mensual[["00"]]
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
