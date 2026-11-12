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
#     contratos», «sin contratos de pisos» y «en el límite», frente a lo que sale de R; en el sueldo
#     necesario, también el mínimo de 50 m² al lado de la cifra principal (tarea 40).
#   navegador_redireccion: un enlace viejo a la raíz (con una sección, o con un sueldo tras «#»)
#     acaba en mapa.html con la misma vista, y el sueldo no queda en la dirección (portada, tarea 24);
#   navegador_portada: la portada carga, en castellano y en inglés, con sus 24 casillas, sin irse
#     al mapa, y sus cartas dan las cifras de la tabla larga (cifras_portada());
#   navegador_casillas: el destino de cada casilla activa, en los dos idiomas, existe (página y ancla);
#   navegador_tu_sueldo: «¿Te llega?» de la portada abre el mapa en «¿te llega?» con el sueldo, que
#     no aparece en la consulta;
#   navegador_movil: a 375 px de ancho, ni la portada ni el mapa desbordan; en el mapa (tarea 50), el
#     menú no se desplaza en horizontal, la tipología y las descargas salen plegadas y, al tocar
#     el mapa, la ficha de lo tocado queda a la vista (su borde de arriba, en la mitad de arriba de
#     la pantalla) sin desplazarse a mano;
#   navegador_territorio: la ficha de una comunidad, una provincia y un municipio (?territorio=…)
#     da la cifra y el estado de la tabla larga en su nivel (tarea 26);
#   navegador_clic: con el ratón sobre el mapa en cada escala (comunidad, provincia, municipio y
#     sección), la etiqueta dice el nombre que luego pone la ficha al pulsar (tareas 25 y 26);
#   navegador_municipal (F5): los mapas sin sección (indicador 20 y los de F4): la ficha del 20 en un
#     municipio declarado entero, uno en parte y uno sin declarar da el texto de su categoría en la
#     tabla larga, sus declaraciones (inventario/zonas_tensionadas.csv) y la nota de política
#     pública; la leyenda, una muestra por categoría; a escala de sección, el clic abre la ficha del
#     municipio; con una sección en la dirección, la ficha es la de su municipio; y la del valor
#     tasado (12) de un municipio da la cifra de la tabla larga.
#   navegador_leyenda (tarea 51): en el sueldo necesario, desde la sección y alejando el mapa con el
#     botón, la leyenda (abierta) lleva en cada escala (sección, municipio y provincia) los cortes de
#     su juego en el manifiesto, con un tramo más, y avisa al cambiar de juego; en los juegos
#     anclados, la nota del año de anclaje.
#   navegador_escala_municipio (decisión del autor, 11-nov-2026): con ?escala=municipio y una sección
#     de Madrid o de Barcelona, en la renta por hogar y el alquiler mensual, la leyenda lleva seis
#     cortes en orden y siete tramos, la línea «no comparables» con el municipio y sus secciones con
#     dato (las de la tabla larga), la clave de las secciones de fuera y, con los valores de la tabla
#     larga, ningún tramo vacío ni con más de dos séptimos de las secciones; «De España» vuelve a los
#     cortes del juego de la sección y quita la escala de la dirección; en un municipio con menos de
#     14 secciones con dato, la opción no se puede elegir.
#   navegador_superficie_tipica (ídem): la ficha de municipio de Madrid da su superficie típica, la de
#     la tabla larga (alquiler mensual / alquiler por m², vivienda colectiva);
#   navegador_una_escala (ídem): en el mapa del 11 (provincial), un municipio en la dirección abre la
#     ficha de su provincia.
#   navegador_historias (tarea 49): ?historia=centro&paso=3 (con un sueldo tras «#») abre el panel con
#     el texto de ese paso en datos/historias.json y deja en la dirección las claves de su estado, sin
#     ficha de perfil (modo «necesario»); «Siguiente» pasa al paso 4 y «Salir» quita la historia de
#     la dirección sin mover la vista. Sin el fichero, se salta (una fila, con el motivo).
#   navegador_carga (tarea 62): abrir mapa.html sin vista no pide el índice de las secciones ni
#     ningún fichero de valores de sección; con la vista en Madrid, el primer clic en una sección pide
#     la ficha de su distrito y ningún fichero nacional (ni de secciones ni de España). Con un
#     manifiesto sin `secciones_desde_zoom` (exportación anterior a la tarea 62), se salta.
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
    minimo: num(f?.querySelector('.ficha-minimo-cifra')?.textContent),
    contratos: contratos ? num(contratos[1]) : null,
    margen: margen ? num(margen[1]) : null,
    pocos: Boolean(f?.querySelector('.marca-pocos')),
    limite: Boolean(f?.querySelector('.ficha-limite')),
    sin_contratos: texto.includes(t('interfaz.ficha.sin_contratos.VC')),
    ejemplo: !document.getElementById('aviso-ejemplo')?.hidden,
  });
})()
)"

# Tarea 50: en el mapa a 375 px, anchos del menú (el que ocupa y el que tiene), si la barra está
# plegada, el centro del mapa en la ventana y el borde de arriba de la ficha frente al alto.
JS_MOVIL_NAVEGADOR <- r"(
(() => {
  const nav = document.querySelector('.navegacion');
  const r = document.getElementById('mapa').getBoundingClientRect();
  return JSON.stringify({
    menu: [nav.scrollWidth, nav.clientWidth],
    plegada: document.getElementById('barra-vista')?.dataset.plegada === 'true'
      && getComputedStyle(document.getElementById('vista-descargas')).display === 'none',
    centro: [r.left + r.width / 2, r.top + Math.min(r.height, innerHeight - r.top) / 2],
    ficha: [document.getElementById('ficha').getBoundingClientRect().top],
    alto: innerHeight,
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
# «¿te llega?» con la tartera en el límite y lejos de él. Una fila por caso con lo esperado. Tarea
# 40: en el sueldo necesario, la cifra es la principal (alquiler mensual real) con el margen de la
# mediana del alquiler mensual, y la ficha da al lado el mínimo de 50 m² (`minimo`); en «¿te
# llega?», la tartera paga 50 m² (regla 8), con el margen de la mediana por m².
casos_ficha_navegador <- function(larga, ingreso_tartera, superficie = SUPERFICIE_FICHA, semilla = 20261109L) {
  ultimo <- max(larga$anio[larga$indicador == "sueldo_necesario" & larga$nivel == "sc"])
  ancho <- larga |>
    filter(nivel == "sc", anio == ultimo, corte %in% c("tipologia", "total"), grupo %in% c("VC", "total"),
           indicador %in% c("alquiler_m2", "contratos_alquiler", "margen_alquiler_m2", "margen_alquiler_mes",
                            "sueldo_necesario")) |>
    select(geo_id, indicador, valor, estado) |>
    tidyr::pivot_wider(names_from = indicador, values_from = c(valor, estado))
  x <- ancho |>
    transmute(seccion = geo_id, estado = estado_alquiler_m2, contratos = valor_contratos_alquiler,
              margen = redondeo_guia(valor_margen_alquiler_mes), margen_m2 = redondeo_guia(valor_margen_alquiler_m2),
              sueldo = valor_sueldo_necesario,
              minimo = termino_publicado(valor_alquiler_m2) * superficie / UMBRAL_SUELDO,
              ratio = termino_publicado(valor_alquiler_m2) * superficie / ingreso_tartera,
              limite = !is.na(ratio) & !is.na(margen_m2) &
                tramo_llega(ratio * (1 - margen_m2 / 100)) != tramo_llega(ratio * (1 + margen_m2 / 100)))
  set.seed(semilla)
  uno <- function(d) d[sample.int(nrow(d), 1), ]
  llega <- function(d) mutate(d, margen = margen_m2, ficha = "tartera")
  bind_rows(
    uno(filter(x, estado == "dato", contratos >= 100)) |> mutate(caso = "mediana", ficha = NA_character_),
    uno(filter(x, estado == "dato", contratos < UMBRAL_POCOS_CONTRATOS)) |> mutate(caso = "pocos", ficha = NA_character_),
    uno(filter(x, estado == "secreto")) |> mutate(caso = "secreto", ficha = NA_character_),
    uno(filter(x, estado == "ausente", contratos %in% 0)) |> mutate(caso = "sin_contratos", ficha = NA_character_),
    uno(filter(x, estado == "dato", limite)) |> mutate(caso = "llega_limite") |> llega(),
    uno(filter(x, estado == "dato", !limite, ratio < 0.2)) |> mutate(caso = "llega_lejos") |> llega()
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
      # Tarea 40: en el sueldo necesario, el minimo de 50 m2 al lado de la cifra principal
      minimo_ok <- !is.na(cs$ficha) || cs$estado != "dato" || (!is.null(f$minimo) && abs(f$minimo - round(cs$minimo)) <= 0.5 + 1e-9)
      as.numeric(!(cifra_ok && contratos_ok && limite_ok && minimo_ok))
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
             comprobar_territorios_navegador(b, evaluar, url, larga, espera),
             comprobar_leyenda_navegador(b, evaluar, url, espera),   # tarea 51
             comprobar_escala_municipio_navegador(b, evaluar, url, larga, espera),   # decisiones del 11-nov-2026
             comprobar_municipales_navegador(b, evaluar, url, larga, raiz, espera),   # F5
             comprobar_historias_navegador(b, evaluar, url, espera,   # tarea 49
                                           hay_fichero = if (is.null(servidor)) NA else file.exists(file.path(raiz, "web", "datos", "historias.json"))),
             comprobar_carga_navegador(b, evaluar, url, espera))   # tarea 62

  # Sample recomputed with the page modules
  sc <- unique(larga$geo_id[larga$nivel == "sc" & larga$indicador == "sueldo_necesario"])
  set.seed(semilla)
  codigos <- sample(sc, min(muestra, length(sc)))
  r <- jsonlite::fromJSON(evaluar(paste0(JS_MUESTRA_NAVEGADOR, "(", jsonlite::toJSON(codigos), ")")))
  pagina <- tibble::tibble(geo_id = r$sueldo[, 1], anio = as.integer(r$sueldo[, 2]),
                           pagina = suppressWarnings(as.numeric(r$sueldo[, 3])), estado_pagina = r$sueldo[, 4])
  esperado <- larga |>
    filter(indicador == "sueldo_necesario", corte == "total", nivel == "sc", geo_id %in% codigos) |>
    transmute(geo_id, anio, r = redondeo_guia(valor), estado)
  cruce <- full_join(pagina, esperado, by = c("geo_id", "anio")) |>
    mutate(mal = is.na(estado) | is.na(estado_pagina) | estado != estado_pagina | xor(is.na(r), is.na(pagina)) |
             coalesce(abs(r - pagina) > 1e-9, FALSE))
  filas[[length(filas) + 1L]] <- tibble::tibble(
    id = "navegador_sueldo", detalle = sprintf("%d secciones y %d a\u00f1os", length(codigos), dplyr::n_distinct(pagina$anio)),
    calculado = sum(cruce$mal), referencia = 0)
  fia <- tibble::tibble(geo_id = r$fiabilidad[, 1], contratos_pagina = suppressWarnings(as.numeric(r$fiabilidad[, 2])),
                        margen_pagina = suppressWarnings(as.numeric(r$fiabilidad[, 3])))
  # Tarea 40: el sueldo necesario sale del alquiler mensual, con el margen de su mediana
  fia_r <- larga |>
    filter(nivel == "sc", anio == as.integer(r$ultimo), corte == "tipologia", grupo == "VC", geo_id %in% codigos,
           indicador %in% c("contratos_alquiler", "margen_alquiler_mes")) |>
    select(geo_id, indicador, valor) |>
    tidyr::pivot_wider(names_from = indicador, values_from = valor)
  if (!"margen_alquiler_mes" %in% names(fia_r)) fia_r$margen_alquiler_mes <- NA_real_
  cruce_f <- left_join(fia, fia_r, by = "geo_id") |>
    mutate(mal = xor(is.na(contratos_pagina), is.na(contratos_alquiler)) | coalesce(contratos_pagina != contratos_alquiler, FALSE) |
             xor(is.na(margen_pagina), is.na(margen_alquiler_mes)) |
             coalesce(abs(margen_pagina - redondeo_guia(margen_alquiler_mes)) > 1e-9, FALSE))
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "navegador_fiabilidad", detalle = sprintf("%d secciones de %s", nrow(fia), r$ultimo),
                                                calculado = sum(cruce_f$mal), referencia = 0)
  if (isTRUE(r$ejemplo)) filas[[1]]$calculado <- 1

  # Errors of the whole check (collected while the browser messages are processed)
  b$Runtime$evaluate("1")
  filas[[length(filas) + 1L]] <- tibble::tibble(id = "navegador_errores", detalle = paste(utils::head(errores, 5), collapse = " | "),
                                                calculado = length(errores), referencia = 0)
  bind_rows(filas) |> mutate(calculado = as.numeric(calculado), referencia = as.numeric(referencia))
}

# Tarea 62: lo que pide el mapa al abrirse sin vista y en el primer clic en una sección de Madrid
# (navegador_carga), con las rutas de la Resource Timing API del navegador.
comprobar_carga_navegador <- function(b, evaluar, url, espera = 60) {
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_carga", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  pedidas <- function() {
    unlist(jsonlite::fromJSON(evaluar("JSON.stringify(performance.getEntriesByType('resource').map((e) => new URL(e.name).pathname))")))
  }
  de_secciones <- function(rutas) grepl("/datos/indices/sc[.]json$|/datos/sc/", rutas)
  b$Page$navigate(paste0(url, "mapa.html"))
  ok <- esperar_navegador(evaluar, "document.getElementById('mapa-cargando')?.hidden && document.querySelector('#ficha .ficha-vacia')", espera)
  diferida <- ok && isTRUE(evaluar(
    "fetch('datos/manifiesto.json').then((r) => r.json()).then((m) => Number.isFinite(m.secciones_desde_zoom))"))
  if (ok && !diferida) return(list(fila("sin secciones_desde_zoom en el manifiesto: se salta", 0)))
  Sys.sleep(2)
  rutas <- if (ok) pedidas() else character()
  filas <- list(fila(sprintf("mapa.html sin vista: %d peticiones, %d de secciones", length(rutas), sum(de_secciones(rutas))),
                     !ok || any(de_secciones(rutas))))

  b$Page$navigate(paste0(url, "mapa.html?vista=14.00/40.41680/-3.70380"))
  ok <- esperar_navegador(evaluar, "document.getElementById('mapa-cargando')?.hidden && document.querySelector('#ficha .ficha-vacia')", espera)
  Sys.sleep(3)
  evaluar("performance.clearResourceTimings(); true")
  xy <- if (ok) jsonlite::fromJSON(evaluar(
    "(() => { const r = document.getElementById('mapa').getBoundingClientRect(); return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]); })()")) else c(0, 0)
  b$Input$dispatchMouseEvent(type = "mousePressed", x = xy[1], y = xy[2], button = "left", clickCount = 1)
  b$Input$dispatchMouseEvent(type = "mouseReleased", x = xy[1], y = xy[2], button = "left", clickCount = 1)
  ok <- ok && esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo')?.textContent.includes('28079')", 20)
  Sys.sleep(3)
  rutas <- if (ok) pedidas() else character()
  fichas <- rutas[grepl("/datos/fichas/", rutas)]
  nacionales <- rutas[de_secciones(rutas) | grepl("/datos/nacional/", rutas)]
  filas[[2]] <- fila(sprintf("primer clic en Madrid: %s; %d ficheros nacionales", paste(sub(".*/datos/", "", fichas), collapse = ", "),
                             length(nacionales)),
                     !ok || length(nacionales) > 0 || length(fichas) != 1 || !any(grepl("/datos/fichas/28079/[0-9]{2}[.]json$", fichas)))
  filas
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
# decimal; enteros en los euros, con los empates hacia arriba, y un decimal en los porcentajes). Tarea 40: con el minimo de 50 m2
# al lado del sueldo y, en el salario minimo, los porcentajes con el alquiler real.
textos_cartas_navegador <- function(cifras) {
  # los empates hacia arriba, como Intl.NumberFormat (2.976,5 da 2.977; round() daria 2.976)
  euros <- function(x) formatC(floor(x + 0.5), format = "d", big.mark = ".", decimal.mark = ",")
  pct <- function(x) sub(".", ",", formatC(x, format = "f", digits = 1), fixed = TRUE)
  list(sueldo = euros(c(cifras$sueldo$mediana, cifras$sueldo$p10, cifras$sueldo$p90, cifras$sueldo$minimo)),
       smi = pct(c(cifras$smi$pct_30, cifras$smi$pct_40, cifras$smi$pct_30_real, cifras$smi$pct_40_real)),
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
  esperados <- textos_cartas_navegador(cifras_portada(larga, perfiles = perfiles))
  for (idioma in c("es", "en")) {
    b$Page$navigate(paste0(url, if (idioma == "en") "?idioma=en" else ""))
    listo <- esperar_navegador(evaluar, sprintf(
      "document.documentElement.lang === '%s' && document.getElementById('portada-dado-nota')?.textContent && (!%s || document.querySelectorAll('#portada-cartas-lista .carta').length > 0)",
      idioma, tolower(hay_cartas)), espera)
    p <- if (listo) jsonlite::fromJSON(evaluar(JS_PORTADA_NAVEGADOR), simplifyVector = FALSE) else NULL
    mal <- is.null(p) || grepl("mapa\\.html$", p$ruta) || p$casillas != 24L || p$titulo != "De renta en renta" ||
      (idioma == "en" && p$primera != "Collect your wages") || (idioma == "es" && p$primera != "Cobra la nómina")
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
  # Task 50: at 375 px the menu wraps (no horizontal scroll), the secondary controls start folded
  # and tapping the map leaves the profile of what was tapped in view, without scrolling by hand
  b$Page$navigate(paste0(url, "mapa.html?mapa=sueldo_necesario&vista=6.00/40.41680/-3.70380"))
  ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-vacia') && document.querySelector('.maplibregl-canvas')", espera)
  Sys.sleep(3)
  m <- if (ok) jsonlite::fromJSON(evaluar(JS_MOVIL_NAVEGADOR)) else NULL
  filas[[length(filas) + 1L]] <- fila("navegador_movil", "375 px: menú sin desplazamiento horizontal",
                                      is.null(m) || m$menu[1] > m$menu[2])
  filas[[length(filas) + 1L]] <- fila("navegador_movil", "375 px: tipología y descargas plegadas al entrar",
                                      is.null(m) || !isTRUE(m$plegada))
  if (!is.null(m)) {
    evaluar("window.scrollTo(0, 0); true")
    b$Input$dispatchMouseEvent(type = "mousePressed", x = m$centro[1], y = m$centro[2], button = "left", clickCount = 1)
    b$Input$dispatchMouseEvent(type = "mouseReleased", x = m$centro[1], y = m$centro[2], button = "left", clickCount = 1)
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo')", 20)
    Sys.sleep(1.5)   # the smooth scroll
  }
  f <- if (!is.null(m) && ok) jsonlite::fromJSON(evaluar(JS_MOVIL_NAVEGADOR)) else NULL
  filas[[length(filas) + 1L]] <- fila("navegador_movil", sprintf("375 px: la ficha a la vista al tocar el mapa (borde de arriba en %s px de %s)",
                                                                 f$ficha[1] %||% NA, f$alto %||% NA),
                                      is.null(f) || f$ficha[1] < 0 || f$ficha[1] > f$alto / 2)
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

# Tarea 51: la leyenda cambia de juego de cortes al cruzar de escala (navegador_leyenda). El mapa del
# sueldo necesario se abre a escala de sección (zoom 7,5, en Madrid) y se aleja con el botón «Alejar»:
# una vez hasta los municipios y dos más hasta las provincias. Cifras de la leyenda como las escribe la
# página en castellano (punto de miles y coma decimal).
comprobar_leyenda_navegador <- function(b, evaluar, url, espera = 60) {
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_leyenda", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  leer <- "JSON.stringify({ cortes: [...document.querySelectorAll('#leyenda .leyenda-corte')].map((s) => s.textContent),
    tramos: document.querySelectorAll('#leyenda .leyenda-tramo').length,
    juego: document.querySelector('#leyenda .leyenda-juego')?.textContent ?? null,
    cambio: Boolean(document.querySelector('#leyenda .leyenda-juego-cambio')),
    anclaje: document.querySelector('#leyenda .leyenda-anclaje')?.textContent ?? null,
    abierta: Boolean(document.querySelector('#leyenda details[open]')) })"
  numero <- function(x) as.numeric(sub(",", ".", gsub(".", "", unlist(x), fixed = TRUE), fixed = TRUE))
  b$Page$navigate(sprintf("%smapa.html?mapa=sueldo_necesario&vista=7.50/40.41680/-3.70380", url))
  ok <- esperar_navegador(evaluar, "document.querySelector('#leyenda .leyenda-corte') && document.getElementById('mapa-cargando')?.hidden !== false", espera)
  if (!ok) return(list(fila("sueldo_necesario: la leyenda no aparece", TRUE)))
  m <- jsonlite::fromJSON(evaluar("fetch('datos/manifiesto.json').then((r) => r.text())"), simplifyVector = FALSE)
  juegos <- m$mapas$sueldo_necesario$juegos
  if (is.null(juegos)) return(list(fila("sueldo_necesario: el manifiesto no trae juegos de cortes", TRUE)))
  filas <- list()
  for (paso in list(list(juego = "seccion", alejar = 0L, cambio = FALSE), list(juego = "municipio", alejar = 1L, cambio = TRUE),
                    list(juego = "provincia_ccaa", alejar = 2L, cambio = TRUE))) {
    for (k in seq_len(paso$alejar)) {
      evaluar("document.querySelector('.maplibregl-ctrl-zoom-out').click()")
      Sys.sleep(1.5)
    }
    Sys.sleep(1)
    l <- jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE)
    j <- juegos[[paso$juego]]
    esperados <- as.numeric(unlist(j$cortes))
    leidos <- numero(l$cortes)
    mal <- is.null(j) || !isTRUE(l$abierta) || l$tramos != length(esperados) + 1L || length(leidos) != length(esperados) ||
      any(abs(leidos - esperados) > 1e-9) || is.null(l$juego) || !identical(isTRUE(l$cambio), paso$cambio) ||
      (startsWith(j$metodo %||% "", "anclado") && is.null(l$anclaje))
    filas[[length(filas) + 1L]] <- fila(sprintf("sueldo_necesario, %s: %s (%s)", paso$juego, paste(l$cortes, collapse = " "),
                                                l$juego %||% "sin l\u00ednea de escala"), mal)
  }
  filas
}

# Decisiones del autor del 11-nov-2026: escala relativa al municipio (navegador_escala_municipio),
# superficie típica en la ficha de municipio (navegador_superficie_tipica) y ficha de la provincia en
# el mapa provincial del 11 (navegador_una_escala). Cifras de la leyenda como las escribe la página en
# castellano. El reparto por tramos se cuenta con los valores de la tabla larga del último año.
comprobar_escala_municipio_navegador <- function(b, evaluar, url, larga, espera = 60) {
  fila <- function(id, detalle, mal) tibble::tibble(id = id, detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  numero <- function(x) as.numeric(sub(",", ".", gsub(".", "", unlist(x), fixed = TRUE), fixed = TRUE))
  leer <- "JSON.stringify({ cortes: [...document.querySelectorAll('#leyenda .leyenda-corte')].map((s) => s.textContent),
    tramos: document.querySelectorAll('#leyenda .leyenda-tramo').length,
    linea: document.querySelector('#leyenda .leyenda-relativa')?.textContent ?? null,
    botones: [...document.querySelectorAll('#leyenda .leyenda-escala button')].map((x) => ({ escala: x.dataset.escala, pulsado: x.getAttribute('aria-pressed') === 'true', desactivado: x.disabled })),
    fuera: Boolean(document.querySelector('#leyenda .leyenda-fuera-municipio')),
    busqueda: location.search })"
  valores_sc <- function(indicador, municipio) {
    x <- larga[larga$indicador == indicador & larga$nivel == "sc" & startsWith(larga$geo_id, municipio) &
                 (indicador != "alquiler_mes" | (larga$corte == "tipologia" & larga$grupo == "VC")) &
                 (indicador == "alquiler_mes" | larga$corte == "total"), ]
    x <- x[x$anio == max(x$anio) & x$estado %in% c("dato", "estimado") & !is.na(x$valor), ]
    redondeo_guia(x$valor)
  }
  filas <- list()
  casos <- list(c("renta_hogar", "28079", "2807901001", "40.41680/-3.70380", "Madrid"),
                c("alquiler_mes", "28079", "2807901001", "40.41680/-3.70380", "Madrid"),
                c("renta_hogar", "08019", "0801901001", "41.38700/2.17000", "Barcelona"),
                c("alquiler_mes", "08019", "0801901001", "41.38700/2.17000", "Barcelona"))
  for (cs in casos) {
    b$Page$navigate(sprintf("%smapa.html?mapa=%s&seccion=%s&escala=municipio&vista=12.00/%s", url, cs[1], cs[3], cs[4]))
    ok <- esperar_navegador(evaluar, "document.querySelector('#leyenda .leyenda-relativa') && document.querySelectorAll('#leyenda .leyenda-corte').length > 0", espera)
    l <- if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
    v <- valores_sc(cs[1], cs[2])
    cortes <- if (is.null(l)) numeric(0) else numero(l$cortes)
    reparto <- if (length(cortes)) tabulate(findInterval(v, cortes) + 1L, nbins = length(cortes) + 1L) else integer(0)
    n_linea <- if (is.null(l$linea)) NA_real_ else numero(regmatches(l$linea, regexpr("[0-9.]+(?= secciones)", l$linea, perl = TRUE)))
    mal <- is.null(l) || length(cortes) != 6L || is.unsorted(cortes, strictly = TRUE) || l$tramos != 7L ||
      !grepl(cs[5], l$linea, fixed = TRUE) || !grepl("no comparables", l$linea, fixed = TRUE) ||
      !identical(n_linea, as.numeric(length(v))) || !isTRUE(l$fuera) || !grepl("escala=municipio", l$busqueda, fixed = TRUE) ||
      any(reparto == 0L) || any(reparto > 2 * length(v) / 7)
    filas[[length(filas) + 1L]] <- fila("navegador_escala_municipio",
                                        sprintf("%s %s: %s (reparto %s)", cs[1], cs[5], paste(l$cortes, collapse = " "), paste(reparto, collapse = "/")), mal)
  }
  # "De Espana": vuelve a los cortes del juego de la seccion y la escala sale de la direccion
  evaluar("document.querySelector('#leyenda .leyenda-escala button[data-escala=\"nacional\"]')?.click()")
  ok <- esperar_navegador(evaluar, "!document.querySelector('#leyenda .leyenda-relativa') && !location.search.includes('escala=')", 20)
  m <- jsonlite::fromJSON(evaluar("fetch('datos/manifiesto.json').then((r) => r.text())"), simplifyVector = FALSE)
  l <- if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
  esperados <- as.numeric(unlist(m$mapas$alquiler_mes$juegos$seccion$cortes))
  filas[[length(filas) + 1L]] <- fila("navegador_escala_municipio", "\u00abDe Espa\u00f1a\u00bb: cortes del juego de la secci\u00f3n",
                                      is.null(l) || !identical(numero(l$cortes), esperados) || isTRUE(l$fuera))
  # Municipio con menos de 14 secciones con dato: la opcion no se puede elegir
  pequenos <- larga[larga$indicador == "renta_hogar" & larga$nivel == "sc" & larga$corte == "total" & !is.na(larga$valor), ]
  pequenos <- pequenos[pequenos$anio == max(pequenos$anio), ]
  cuenta <- table(substr(pequenos$geo_id, 1, 5))
  pequeno <- names(cuenta)[cuenta >= 3 & cuenta < 14][1]
  if (!is.na(pequeno)) {
    b$Page$navigate(sprintf("%smapa.html?mapa=renta_hogar&territorio=municipio:%s&escala=municipio", url, pequeno))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]') && document.querySelector('#leyenda .leyenda-corte')", espera)
    # A escala de seccion, encuadrado en el municipio
    ok <- ok && esperar_navegador(evaluar, "document.querySelectorAll('#leyenda .leyenda-escala button').length === 2", 30)
    l <- if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
    municipal <- Filter(function(x) identical(x$escala, "municipio"), l$botones)
    filas[[length(filas) + 1L]] <- fila("navegador_escala_municipio", sprintf("%s (%d secciones con dato): sin escala relativa", pequeno, cuenta[[pequeno]]),
                                        is.null(l) || length(municipal) != 1L || !isTRUE(municipal[[1]]$desactivado) || !is.null(l$linea))
  }
  # Superficie tipica en la ficha de municipio (Madrid, ultimo anio del alquiler)
  a <- larga[larga$geo_id == "28079" & larga$nivel == "municipio" & larga$corte == "tipologia" & larga$grupo == "VC" &
               larga$indicador %in% c("alquiler_mes", "alquiler_m2"), ]
  a <- a[a$anio == max(a$anio), ]
  tipica <- redondeo_guia(a$valor[a$indicador == "alquiler_mes"]) / redondeo_guia(a$valor[a$indicador == "alquiler_m2"])
  b$Page$navigate(paste0(url, "mapa.html?mapa=alquiler_mes&territorio=municipio:28079"))
  ok <- esperar_navegador(evaluar, "[...document.querySelectorAll('#ficha .nota')].some((p) => p.textContent.startsWith('Superficie t\u00edpica'))", espera)
  nota <- if (ok) evaluar("[...document.querySelectorAll('#ficha .nota')].find((p) => p.textContent.startsWith('Superficie t\u00edpica')).textContent") else ""
  leida <- numero(regmatches(nota, regexpr("[0-9.,]+(?= m\u00b2)", nota, perl = TRUE)))
  filas[[length(filas) + 1L]] <- fila("navegador_superficie_tipica", sprintf("28079 (%d): %s m\u00b2", max(a$anio), format(round(tipica))),
                                      !ok || length(leida) != 1L || abs(leida - round(tipica)) > 1e-9)
  # Mapa del 11 (provincial): un municipio abre la ficha de su provincia
  b$Page$navigate(paste0(url, "mapa.html?mapa=precio_compra_m2&territorio=municipio:28065"))
  ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]')", espera)
  f <- if (ok) jsonlite::fromJSON(evaluar("JSON.stringify({ nivel: document.querySelector('#ficha .ficha-codigo').dataset.nivel, codigo: document.querySelector('#ficha .ficha-codigo').dataset.codigo })")) else NULL
  filas[[length(filas) + 1L]] <- fila("navegador_una_escala", "precio_compra_m2 con municipio:28065: ficha de la provincia 28",
                                      is.null(f) || !identical(f$nivel, "provincia") || !identical(f$codigo, "28"))
  filas
}

# F5: mapas sin seccion (indicador 20, zonas tensionadas, y los de F4) y de categor\u00edas (navegador_municipal).
# Los textos de las categorías, de web/i18n/es.json; las declaraciones, de inventario/zonas_tensionadas.csv.
comprobar_municipales_navegador <- function(b, evaluar, url, larga, raiz = ".", espera = 60) {
  filas <- list()
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_municipal", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  textos <- jsonlite::read_json(file.path(raiz, "web", "i18n", "es.json"))$vocabulario$zona_tensionada
  zonas <- leer_zonas_tensionadas(file.path(raiz, "inventario", "zonas_tensionadas.csv"))
  zt <- larga |> filter(indicador == "zona_tensionada", nivel == "municipio")
  if (!nrow(zt)) return(list(fila("sin el indicador 20 en la tabla larga", TRUE)))
  ultimo <- max(zt$anio)
  leer <- "JSON.stringify({ codigo: document.querySelector('#ficha .ficha-codigo')?.dataset.codigo ?? null,
    nivel: document.querySelector('#ficha .ficha-codigo')?.dataset.nivel ?? null,
    categoria: document.querySelector('#ficha .ficha-categoria')?.textContent ?? null,
    declaraciones: [...document.querySelectorAll('#ficha .ficha-lista-declaraciones li')].map((li) => li.textContent),
    notas: [...document.querySelectorAll('#ficha .nota')].map((p) => p.textContent),
    leyenda: [...document.querySelectorAll('#leyenda .leyenda-categorias li')].map((li) => li.textContent) })"
  abrir <- function(consulta) {
    b$Page$navigate(paste0(url, "mapa.html", consulta))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]') && document.querySelector('#ficha .ficha-declaraciones')", espera)
    if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
  }
  lectura <- jsonlite::read_json(file.path(raiz, "web", "i18n", "es.json"))$indicadores$zona_tensionada$lectura
  # Un municipio declarado entero, uno en parte y uno sin declarar, en el ultimo anio
  casos <- c(entero = "08019", parte = "33024", ninguno = "28079")
  for (k in names(casos)) {
    cod <- casos[[k]]
    f <- abrir(sprintf("?mapa=zona_tensionada&territorio=municipio:%s", cod))
    v <- zt$valor[zt$geo_id == cod & zt$anio == ultimo]
    n <- sum(zonas$municipio == cod)
    mal <- is.null(f) || length(v) != 1 || !identical(f$codigo, cod) || !identical(f$categoria, textos[[as.character(v)]]) ||
      length(f$declaraciones) != n || !any(unlist(f$notas) == lectura) ||
      (n > 0 && !all(vapply(zonas$boe[zonas$municipio == cod], function(id) any(grepl(id, unlist(f$declaraciones), fixed = TRUE)), TRUE)))
    if (k == "entero") mal <- mal || length(f$leyenda) != length(textos)
    filas[[length(filas) + 1L]] <- fila(sprintf("zona_tensionada %s (%s): %s", cod, k, f$categoria %||% "sin ficha"), mal)
  }
  # Con una seccion en la direccion, la ficha es la de su municipio
  f <- abrir("?mapa=zona_tensionada&seccion=0801901001")
  filas[[length(filas) + 1L]] <- fila("zona_tensionada con ?seccion=0801901001: ficha de 08019",
                                      is.null(f) || !identical(f$nivel, "municipio") || !identical(f$codigo, "08019"))
  # A escala de seccion (zoom 13), el clic en el centro de Madrid abre la ficha del municipio
  b$Page$navigate(sprintf("%smapa.html?mapa=zona_tensionada&vista=13.00/40.41680/-3.70380", url))
  ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-vacia') && document.querySelector('.maplibregl-canvas')", espera)
  Sys.sleep(3)
  xy <- if (ok) jsonlite::fromJSON(evaluar("(() => { const r = document.getElementById('mapa').getBoundingClientRect(); return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]); })()")) else c(0, 0)
  b$Input$dispatchMouseEvent(type = "mousePressed", x = xy[1], y = xy[2], button = "left", clickCount = 1)
  b$Input$dispatchMouseEvent(type = "mouseReleased", x = xy[1], y = xy[2], button = "left", clickCount = 1)
  ok <- ok && esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]')", 20)
  f <- if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
  filas[[length(filas) + 1L]] <- fila("zona_tensionada, zoom 13 en Madrid: ficha del municipio 28079",
                                      is.null(f) || !identical(f$nivel, "municipio") || !identical(f$codigo, "28079"))
  # Un mapa de F4 sin seccion: la cifra del municipio, la de la tabla larga (sin decimales)
  vt <- larga |> filter(indicador == "valor_tasado_m2", nivel == "municipio", geo_id == "28079")
  if (nrow(vt)) {
    vt <- vt[vt$anio == max(vt$anio), ]
    b$Page$navigate(paste0(url, "mapa.html?mapa=valor_tasado_m2&territorio=municipio:28079"))
    ok <- esperar_navegador(evaluar, "document.querySelector('#ficha .ficha-codigo[data-nivel]') && document.querySelector('#ficha .ficha-estado')", espera)
    f <- if (ok) jsonlite::fromJSON(evaluar(JS_FICHA_NAVEGADOR)) else NULL
    filas[[length(filas) + 1L]] <- fila(sprintf("valor_tasado_m2 28079 (%d)", vt$anio),
                                        is.null(f) || is.null(f$cifra) || abs(f$cifra - round(vt$valor)) > 1e-9)
  }
  filas
}

# Tarea 49: recorrido guiado en el mapa (navegador_historias). El texto y las claves esperadas salen
# del propio datos/historias.json que sirve la pagina; sin el fichero, una fila que se salta.
# `hay_fichero`: si se sabe (web local), si el fichero existe; con NA (web publicada), se pregunta a
# la pagina. En local no se pide si falta, para que su 404 no cuente en navegador_errores.
comprobar_historias_navegador <- function(b, evaluar, url, espera = 60, hay_fichero = NA, historia = "centro", paso = 3L) {
  fila <- function(detalle, mal) tibble::tibble(id = "navegador_historias", detalle = detalle, calculado = as.numeric(mal), referencia = 0)
  if (isFALSE(hay_fichero)) return(list(fila("sin web/datos/historias.json: se salta", FALSE)))
  b$Page$navigate(paste0(url, "mapa.html"))
  esperar_navegador(evaluar, "document.readyState === 'complete'", espera)
  datos <- evaluar("fetch('datos/historias.json', { cache: 'no-cache' }).then((r) => (r.ok ? r.text() : '')).catch(() => '')")
  if (!nzchar(datos %||% "")) return(list(fila("sin datos/historias.json: se salta", FALSE)))
  h <- Filter(function(x) identical(x$id, historia), jsonlite::fromJSON(datos, simplifyVector = FALSE)$historias)
  if (length(h) != 1L || length(h[[1]]$pasos) <= paso) {
    return(list(fila(sprintf("datos/historias.json sin la historia %s o sin el paso %d", historia, paso + 1L), TRUE)))
  }
  pasos <- h[[1]]$pasos
  leer <- "JSON.stringify({ visible: !document.getElementById('historia').hidden,
    texto: document.getElementById('historia-texto')?.textContent ?? '',
    contador: document.getElementById('historia-contador')?.textContent ?? '',
    busqueda: location.search })"
  # Claves del estado del paso en la direccion (las que trae, con su valor; sin vista, que cambia
  # con el encuadre) y las que no deben estar: las que no trae y la ficha de perfil
  claves_bien <- function(busqueda, estado) {
    p <- parametros_consulta_navegador(busqueda)
    trae <- setdiff(names(estado), "vista")
    todas <- c("mapa", "anio", "territorio", "escala")
    all(vapply(trae, function(k) identical(p[[k]], as.character(estado[[k]])), TRUE)) &&
      !any(setdiff(todas, trae) %in% names(p)) && !any(c("ficha", "seccion", "comparar", "tipologia") %in% names(p))
  }
  esperar_paso <- function(n) {
    ok <- esperar_navegador(evaluar, sprintf(
      "!document.getElementById('historia').hidden && location.search.includes('paso=%d') && document.getElementById('historia-texto').textContent && document.getElementById('mapa-cargando')?.hidden !== false",
      n), espera)
    Sys.sleep(1)   # la direccion se escribe un cuarto de segundo despues de pintar
    if (ok) jsonlite::fromJSON(evaluar(leer), simplifyVector = FALSE) else NULL
  }
  filas <- list()
  # Paso pedido en la direccion, con un sueldo compartido: el mapa sigue en el modo "necesario"
  b$Page$navigate(sprintf("%smapa.html?historia=%s&paso=%d#sueldo=1500", url, historia, paso))
  l <- esperar_paso(paso)
  esperado <- pasos[[paso]]
  filas[[length(filas) + 1L]] <- fila(
    sprintf("%s, paso %d: panel, texto y estado (%s)", historia, paso, l$busqueda %||% "sin panel"),
    is.null(l) || !isTRUE(l$visible) || !identical(l$texto, esperado$texto$es) ||
      !grepl(sprintf("Paso %d de %d", paso, length(pasos)), l$contador, fixed = TRUE) || !claves_bien(l$busqueda, esperado$estado))
  # Siguiente: el paso siguiente
  evaluar("document.getElementById('historia-siguiente').click(); true")
  l <- esperar_paso(paso + 1L)
  esperado <- pasos[[paso + 1L]]
  filas[[length(filas) + 1L]] <- fila(
    sprintf("%s, Siguiente: paso %d (%s)", historia, paso + 1L, l$busqueda %||% "sin panel"),
    is.null(l) || !identical(l$texto, esperado$texto$es) || !claves_bien(l$busqueda, esperado$estado))
  # Salir: fuera historia y paso de la direccion y fuera el panel; la vista no cambia
  Sys.sleep(3)   # el vuelo hasta la vista del paso
  antes <- parametros_consulta_navegador(evaluar("location.search"))$vista
  evaluar("document.getElementById('historia-salir').click(); true")
  ok <- esperar_navegador(evaluar, "document.getElementById('historia').hidden && !location.search.includes('historia=') && !location.search.includes('paso=')", 20)
  Sys.sleep(1)
  despues <- parametros_consulta_navegador(evaluar("location.search"))$vista
  filas[[length(filas) + 1L]] <- fila(sprintf("%s, Salir: sin historia en la direcci\u00f3n, vista %s", historia, despues %||% "sin vista"),
                                      !ok || is.null(antes) || !identical(antes, despues))
  filas
}

# Parametros de una consulta ("?a=1&b=2") como lista con nombre.
parametros_consulta_navegador <- function(busqueda) {
  partes <- strsplit(sub("^[?]", "", busqueda %||% ""), "&", fixed = TRUE)[[1]]
  partes <- partes[nzchar(partes)]
  stats::setNames(lapply(sub("^[^=]*=?", "", partes), utils::URLdecode), sub("=.*$", "", partes))
}
