# Methodology note

*De renta en renta · v0.1, draft · 8 November 2026 · in line with plan v0.26.*

This note describes how the atlas figures are produced: sources, constant geography, territorial hierarchy and base map, validation gate, v0.1 indicators and token incomes. It is a faithful translation of the Spanish note, `docs/metodologia.md`.

## 0. How each figure is cited

- **Traceability.** Each figure gives its origin in brackets. It can be:
  - a pipeline target, read with `targets::tar_read(<target>)`;
  - a function in `R/`;
  - a file in `inventario/`;
  - a section of the plan (`docs/plan_integracion_atlas.md`, «plan §»).
- **Repeated targets.** Targets ending in `_<tracts>` are repeated once per source tract map, as set by `PASOS_2021` in `_targets.R`. For example, `paso_final_2016` carries ADRH 2015.
- **Reference store.** Unless stated otherwise, figures come from the `targets` store of 8 Nov 2026, covering all of Spain, after the full run that ended at 22:25: `tabla_larga` dates from 21:13, already with the regions and provinces of indicators 18 and 19; the base map, from 22:12; the website data, from 22:14, and the website overburden section, from 21:04.
- **Decisions.** Open questions already closed in the plan are cited as «plan §11, question *n*».
- **Pending.** Marks what the pipeline does not compute yet.
- **Format.** Figures use a comma for thousands and a point for decimals. Rounding to one decimal uses `redondear_1()`, which calls `sprintf("%.1f")`: `round()` rounds half to even.

---

## 1. Guiding question and scope

**Question.** Who has any pay left after paying for housing? Where, since when and for whom the link between housing costs and pay has changed (plan §1). For those already on the board and for those just joining the game: the first family of indicators measures those who already rent (the rented stock) and the second, those looking for a home today (asking prices and new tenancies). They are never mixed in a single figure.

**Audience.** Primary: data journalists and analysts in public bodies and organisations. Secondary: a layer for the general public.

**Scale and period.** Census tract, from 2015 to the latest data available. All series are drawn on the 2021 Census tract map (§3).

**Two families of rent indicators** (plan §1; `familia_alquiler` column of `inventario/indicadores.csv`):
- **Staying** (those already renting): the rented stock, with the tenancies in force declared to SERPAVI. It includes median rent over the area's average household income (indicator 14: income of all households in the tract against rent in that tract; profile only, with its reading note) and the rent share of income (rent in the tract against the income of a token, §6).
- **Moving in** (those looking for a home today): asking rents from property portals and the INE index for new tenancies. It is added before v1.0; until then, the atlas only measures the first family. The new-tenancy index is already in the long table (indicator 10, `contrato` breakdown; §7.7), with no map. The gap between asking rents and the stock, the pay to move in and the barrier to moving in are computed with the portals layer on and reach the website only as bands (§7.8).

SERPAVI figures measure those already renting, not the cost of moving in. The rent share of income corrects a bias in the burden: expensive areas look affordable because higher-income people live there.

**Staging** (plan §2.3):

| Version | Content | Computation status (8 Nov 2026) |
|---|---|---|
| v0.0 | Indicators 22 (housing cost overburden, Eurostat method) and 23 (unsuccessful housing search) | In the long table: 261 and 32 rows (`tabla_larga`, sources `ine_ecv` and `ine_ecv_modulo`) |
| v0.1 | Core of 10 indicators: 1–3, 8, 9, 14, 15, 18, 19 and 21 | All 10, in the long table; the rent share of income (15), only with the Young adult and Minimum wage tokens of 2024 (§7.4) |
| v1.0 | The 23 indicators of the catalogue (plan §5) | — |

**v0.1 core** (`inventario/indicadores.csv`, column `nucleo_v01`):

| # | Indicator | Source | Native level | Series | Status |
|---|---|---|---|---|---|
| 1 | Average net income per person | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 2 | Average net income per household | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 3 | Median income per consumption unit | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 8 | Monthly rent (median) | MIVAU, SERPAVI | Tract (2021 tract map) | 2015–2024 | Computed (`larga_serpavi`) |
| 9 | Rent per m² (median) | MIVAU, SERPAVI | Tract (2021 tract map) | 2015–2024 | Computed (`larga_serpavi`) |
| 14 | Median rent over the area's average household income (profile only) | SERPAVI and ADRH | Tract | 2015–2024 | Computed (`larga_derivados`) |
| 15 | Rent share of income | SERPAVI and the income of each token | Tract × income | 2015–2024 | Check in `larga_derivados` (Minimum wage, Young adult and Pensioner tokens, 2015–2024); the website computes it with each token |
| 18 | Renting households | INE, 2021 Census | Tract (2021 tract map) | 2021 (2011, in F6) | Computed (`larga_censo2021`) |
| 19 | Tourist dwellings | INE, experimental statistics | Tract (2024 tract map, carried to 2021) | February 2024 – May 2026, twice a year (2020–2023, in F6) | Computed (`larga_vut`) |
| 21 | Net pay needed (default map; with actual monthly rent and, alongside, the 50 m² minimum) | SERPAVI | Tract | 2015–2024 | Computed (`larga_derivados`) |

**Rental building type** (plan §11, question 12). SERPAVI does not publish a joint median for apartments (vivienda colectiva) and single-family houses (vivienda unifamiliar). The rent map shows apartments by default, which account for 88.9% of observations in 2024: 2,271,987 against 284,591 (`serpavi`, regions sheet). Single-family houses are an option, and the two are never combined in one map. The derived indicators (14, 15 and 21) use apartments.

**Indicator 7.** AEAT average annual wage per employee, overall and aged 26 to 35, by province, region and Spain, from 2011 to 2025, in the long table (`larga_salarios`, §5.6). It is the starting point of the Young adult token, which has a series from 2015 to 2025 (`mochila_neta`, §6.2).

**Lag.** The atlas runs one or two years behind on income and wages. ADRH has a lag of about 22 months: the 2024 edition was published on 19 Oct 2026. AEAT's *Mercado de trabajo y pensiones* (labour market and pensions) has one of about 11 months (plan §8).

---

## 2. Sources and licences

### 2.1 Sources used by v0.1

The full inventory, with address, access, frequency and notes, is in `inventario/fuentes.csv`. The `licencia` column quotes the text of each source.

| Source (`id`) | Body | Use | Licence (summary from `fuentes.csv`) |
|---|---|---|---|
| `ine_adrh` | INE | Indicators 1–6; net income per household for indicator 17 (§7.7); population and households for the geography tests; municipality names | CC BY 4.0 |
| `mivau_serpavi` | MIVAU | Indicators 8, 9, 14, 15 and 21 | Reuse authorised by the MIVAU legal notice (Law 37/2007 and RD 1495/2011), citing the source and the date, without distorting the information |
| `ine_censo2021` | INE | Indicator 18; denominator of 19 | CC BY 4.0 |
| `ine_vut` | INE | Indicator 19 | CC BY 4.0 |
| `aeat_mercado_trabajo` | AEAT | Indicator 7; «Young adult» and «Pensioner» tokens (pensioners' withholding); wage percentile (§6.6) | Free reuse, including commercial, citing the source and the date of last update |
| `boe_smi` | BOE | «Minimum wage» token (2015–2026) | Reusable |
| `inss_pensiones` | INSS (Social Security) | «Pensioner» token | Reuse citing the source and the date of last update |
| `ine_ecv` | INE | Check of the Young adult token; indicator 22 | CC BY 4.0 |
| `ine_ecv_modulo` | INE | Indicator 23 | CC BY 4.0 |
| `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r` | Eurostat | Gate of indicator 22, also by income quintile (`ilc_lvho07b`); European series and map of the website | CC BY 4.0 |
| `eurostat_nuts` | Eurostat (GISCO) | Geometries of the European map | Non-commercial use with the notice «© EuroGeographics for the administrative boundaries». Not CC BY |
| `ine_seccionado` | INE | Tract maps from 2016 to 2025; territorial hierarchy and base map | CC BY 4.0 |
| `ign_au` | IGN | Name and type of the land without a tract in the base map (§3.10) | CC BY 4.0 (Order FOM/2807/2015), with the attribution `Obra derivada de BDDAE 2026 CC-BY 4.0 ign.es` |
| `ine_callejero` | INE | Conversion tables, route (a) | CC BY 4.0 |
| `catastro_inspire` | Directorate General for the Cadastre | Conversion tables, route (b) | Contradictory: see below |
| `catastro_foral` | Provincial councils of Álava, Bizkaia and Gipuzkoa; Government of Navarre | Route (b) in the Basque Country and Navarre | Different in each territory: see below |
| `gv_emal` | Basque Government | Municipal context layer (deposits); not combined with indicator 8 | CC BY 4.0 |
| `ine_ipva` | INE | Indicator 10 | CC BY 4.0 |
| `mivau_valor_tasado` | MIVAU | Indicators 12, 16 and 17 | Reuse authorised by the MIVAU legal notice, citing the source and the date |
| `mivau_transacciones` | MIVAU (notarial deeds) | Coherence gate for appraisals (§7.7) | Reuse authorised by the MIVAU legal notice, citing the source and the date |
| `ine_hipotecas` | INE | Gate of its average rate (`validacion_hipotecas`); indicator 17 uses the Banco de España rate (§7.7) | CC BY 4.0 |
| `bde_accesibilidad`, `bde_tipos_referencia` | Banco de España | Historical module (§7.9); new housing-loan rate for indicator 17 (§7.7) | Reuse citing the source and the update date, without suggesting it takes part in the atlas |
| `ine_ipc` | INE | Euros of each year or base-year euros in the Time machine (appraised value and average wage) and in the profile's chart over time, and CPI change of the period; nothing deflated goes into the map, the legends, the stories or the long table (§9.2) | CC BY 4.0 |
| `notariado` | General Council of Notaries | Not used: its websites reserve all rights and ask for express authorisation to reuse the figures; indicator 11 comes from the Land Registrars, by province (§7.7) | All rights reserved: personal use only; reuse requires its express authorisation |
| `zonas_tensionadas` | Housing Ministry, in the BOE (declarations by the autonomous communities) | Indicator 20 (§7.8) | Reusable citing the source (BOE reuse conditions) |
| `portales` | Idealista and Fotocasa (press rooms) | Indicator 13, removable and web-only layer, off by default: Idealista rents from 2015 to 2026 (§7.8) | Idealista's general terms: personal and private use; without its written permission, no automated or manual extraction, no copying into another website and no deep links; its reports, citing the source. To be reviewed: ask for that permission (§7.8) |
| `cis_barometros` | CIS | Housing as a problem: national monthly series from the barometers, outside the long table (§7.10) | Free reuse citing the CIS, without distorting the content (Law 37/2007); the metadata of each study state CC BY 4.0 |
| `calculo_propio` | De renta en renta | Derived indicators 14, 15, 16, 17 and 21, from the sources of each term, and approximate margin of the rent median (§7.6) | CC BY-SA 4.0 |

**Manual download of SERPAVI.** The MIVAU website blocks automated downloads. If the Excel file is missing, `descargar_mivau_serpavi()` stops the pipeline and gives the page and the name under which to save it (`inventario/fuentes.csv`, column `acceso`).

**Manual download of Registradores** (indicator 11; source `registradores`). The server of its open-data portal rejects clients that are not a browser, and this is not forced: the CSV `RP_ComprvResid_2007-2t2026.csv` (577 KB) is downloaded by hand and saved under its own name in `datos/brutos/registradores/`, outside git. `registradores_descargar()` takes the most recent version and, if there is none, stops and says what to download and where to put it. The 2007-2t2026 file (577,366 bytes) has been in place since 11 Nov 2026 and the `_targets.R` block is connected (§7.7).

### 2.2 Licences: what each source requires

Single table of licences (backlog, task 57). The text of each licence, with its address and the date it was read, is in the `licencia` column of `inventario/fuentes.csv`. The four cases that need care are in bold: the three cadastres with contradictory licences, the Land Registrars' ODbL, the European geometries for non-commercial use and Idealista, on the website only.

| Source | Licence | What it requires |
|---|---|---|
| INE (ADRH, 2021 Census, tourist dwellings, IPVA, mortgages, ECV, tract maps, street index, population register, National Accounts and CPI), Eurostat (data), IGN and Basque Government | CC BY 4.0 | Cite the source. The IGN also asks for the attribution `Obra derivada de BDDAE 2026 CC-BY 4.0 ign.es` |
| MIVAU (SERPAVI, appraised value and transactions), AEAT, INSS, BOE (minimum wage and stressed areas), Banco de España and CIS | Reuse authorised by their legal notices or terms of use (Law 37/2007) | Cite the source and the date of last update, without distorting the information. The Banco de España also asks not to suggest that it takes part in or sponsors the atlas; the CIS, not to give it an official character |
| State Cadastre (Directorate General for the Cadastre) | **Contradictory:** CC BY 4.0 in the IDEE metadata; a licence from 2016 that requires transforming the data before disseminating them on the INSPIRE page; «all rights reserved» in the general ATOM feed; free use citing the Directorate General as author and owner in the buildings feeds | Treated as open data (author's decision, 8 Nov 2026). Cite the Directorate General for the Cadastre as author and owner. Only derived data are disseminated (the conversion tables), never the buildings |
| Foral cadastre of Bizkaia | **Contradictory:** CC BY 3.0 ES with the conditions of Law 37/2007; the municipal entries of its feed say «all rights reserved» | Cite the Provincial Council and the date of update, without altering the content |
| Foral cadastre of Gipuzkoa | **Contradictory:** attribution only in the WFS; CC BY-SA 4.0 in the metadata and in the feed | Cite the Provincial Council and publish derived data under the same licence: that is why the atlas publishes under CC BY-SA 4.0 (§2.3) |
| Foral cadastres of Álava and Navarre | CC BY 4.0, without contradictions | Cite; Navarre asks for «Servicio proporcionado por el Gobierno de Navarra» |
| Land Registrars (Estadística Registral Inmobiliaria): indicator 11, by province (backlog, task 46) | **ODbL** (Open Database License) | Cite the Land Registrars in every public use. Whatever is published as a database derived from theirs (the rows of indicator 11 in the long table and in the *release*) is under the ODbL, not CC BY-SA 4.0, and without technical measures that close access; on maps and charts, a notice that they use their database under the ODbL. The package states it in `version.json` (`licencia`; `LICENCIA_DATOS.md`) |
| Eurostat, GISCO: NUTS geometries of the European map | **Non-commercial use**, with the notice «© EuroGeographics for the administrative boundaries». Not CC BY | The notice, in the map legend and on the «Data» page. The geometries are outside the licence of the derived data; commercial use requires a licence from EuroGeographics |
| Idealista: indicator 13 and the «getting in» derived figures | **Website only, «coming soon»:** its general terms limit use to personal and private use and ask for its written permission to copy its content into another website, extract it or deep-link; its reports are cited with their source | Until its written authorisation, the layer is off and the website announces it as «coming soon». Nothing of it in the long table, the downloads or the *release*; in the repository, only a dozen figures cited in the documentation and in the gate, with their source (backlog, decision 19). Its derived figures, only by bands (decision 18) |
| General Council of Notaries | All rights reserved: personal use; reuse requires its express authorisation | Not used: the atlas does not download its figures (§7.7) |
| De renta en renta: derived data, texts and inventory | CC BY-SA 4.0 | Cite and publish whatever is derived under the same licence (`LICENCIA_DATOS.md`; §2.3) |
| Code of the atlas; web libraries (MapLibre GL JS 6.15.0 and PMTiles 4.5.0) | MIT; BSD-3 | Keep the licence notice (`LICENSE`, `web/vendor/`) |

(`inventario/fuentes.csv`; plan §6.3.)

### 2.3 Licence of the derived data

**Author's decision (8 Nov 2026):** sources are treated as open data. Derived data, texts and the inventory are published under CC BY-SA 4.0 (`LICENCIA_DATOS.md`; plan §6.1). Until that date, the licence was CC BY 4.0.

ShareAlike accepts sources under CC BY and those that require sharing alike, such as Gipuzkoa. In return, whoever reuses the derived data must publish their own under the same licence.

**What it covers:**
- Since that date, the conversion tables combined with the Cadastre are versioned in `geo/tablas_paso/combinada_<year>_2021.csv` (target `fichero_paso_final_<tracts>`).
- The territorial hierarchy (`geo/jerarquia_2021.csv`, `geo/territorios_2021.csv`) and the PMTiles base map derive from the INE tract map and carry the same licence. The PMTiles file is not in git: it is published from a repository *release* (§3.10).

**Exceptions:**
- The GISCO NUTS geometries are outside the licence of the derived data.
- The figures of indicator 11, from the Land Registrars, follow the ODbL (§2.2).
- The layer of portal asking prices is not redistributed and is off by default (`PORTALES=FALSE`; plan §2.2): it is not in the *release* or the downloads, only on the website (backlog, decision 3).
- The web libraries, MapLibre GL JS 6.15.0 and PMTiles 4.5.0 (`web/vendor/`), keep their BSD-3 licence (plan §6.6).
- The code is under the MIT licence (`LICENSE`).

**Suggested attribution:** «De renta en renta (Guillermo Astiaso Llamazares), from [original source]» (`LICENCIA_DATOS.md`).

### 2.4 Withdrawal plan by source

What is done if a source clarifies its licence against reuse, withdraws its permission or asks for its data to be removed. What has already been published remains in earlier *releases* and in the git history: withdrawing a source means publishing a *release* without it, deleting its files from the earlier ones (`gh release delete-asset`) and, only if the source requires it, rewriting the git history.

| Source | What depends on it | How it is withdrawn |
|---|---|---|
| State Cadastre | Route (b) of the conversion tables outside the Basque Country and Navarre, and the combined tables versioned in git | Conversion tables from the street index alone, route (a), with a change in `_targets.R`. It costs precision: with the 2025 tract map, 7,057 tracts `estimado` and 3,101 medians `ausente`, against 1,194 and 753 with the combined table (§3.5). The combined tables leave git in a new commit |
| Foral cadastres of Bizkaia or Gipuzkoa | Route (b) in their territory | Their zips, out of `ZIPS_CATASTRO_FORAL` or `FEEDS_CATASTRO_FORAL` (`R/fuente_catastro_foral.R`): their tracts move to route (a) |
| Land Registrars | Indicator 11 in the long table, the *release* and the website | Its block out of `_targets.R` (task 46), and a new package and *release*: indicator 11 is again left without a source |
| Eurostat, GISCO | European map of the overburden section | `nuts_2021.geojson` and `nuts_2024.geojson` leave the website package; the section keeps the series and the table of countries |
| Idealista | Portal layer (indicator 13) and «getting in» derived figures | The layer is already off by default (`PORTALES=FALSE`) and does not leave the pipeline: its extraction is deleted from `datos/brutos/portales/`. If it asks, the figures cited in the documentation and the `portales_*` references of the gate also go |
| Official sources cited (INE, MIVAU, AEAT, INSS, BOE, Banco de España and CIS) | Their indicators; SERPAVI is the core of the atlas (indicators 8, 9, 14, 15 and 21) | Their rows out of the long table (column `fuente`), their maps and their profiles; new package and *release* |

---

## 3. Reference tract map and constant geography

### 3.1 Reference: the 2021 Census tract map

**What it is.** The map and all series use the INE tract map at 1 January 2021: 36,333 tracts (`secciones_2021`; plan §1 and §6.3).

**Why.** SERPAVI (2011–2024) and the 2021 Census (indicator 18) publish their whole series on that tract map: neither needs a conversion table (plan §6.3). With the latest tract map, the SERPAVI medians would have to be split: 227 of the 26,137 tracts with data in 2024 have a code that disappears before 2025 (plan §11, question 4).

**What is reprojected:**
- ADRH income, published each year on its own tract map (§3.2 and §5);
- tourist dwellings (indicator 19), published on the 2024 tract map since February 2024 (§7.3; break `vut_seccionado_2024` in `inventario/rupturas.csv`). The plan placed them on the 2021 tract map from v0.9; this was corrected in v0.20.
- the 2011 Census (indicator 18 for 2011) and tourist dwellings from August 2020 to February 2023, which are on the 2011 Census tracts (§3.11; task 47).

**Cost.** Tracts that change after 2021 are shown with their 2021 boundaries.
- From 2021 to 2025, 35,995 tracts keep their code, 338 disappear and 559 appear (`secciones_2021`, `secciones_2025`).
- Of those that keep their code, 1,444 change more than 1% of their area (more than 5%, 1,304; more than 25%, 933).
- From 2016 to 2021, 3,265 of 35,917 change more than 1% of their area (more than 5%, 1,938) (`cambios_limites`, `geo_cambios_limites()`).

### 3.2 ADRH years and conversion tables

**Code phase.** ADRH for year *t* (income of *t*) is published on the tract map of 1 January *t* + 1 (`seccionado_adrh()`). Code matching confirms it (`fase_codigos`, `geo_fase_codigos()`). ADRH 2020 is native to the 2021 tract map.

**Tables.** There are nine conversion tables, one per source tract map, each towards the 2021 tracts (`PASOS_2021` in `_targets.R`):

| Source tract map | ADRH | Street register (format of the INE application) | Direction |
|---|---|---|---|
| 2016 | 2015 | January 2016 (old) | Forward: splits |
| 2017–2020 | 2016–2019 | January of the same year (old) | Forward: splits |
| 2022 | 2021 | January 2022 (new) | Backward: almost always aggregates |
| 2023–2025 | 2022–2024 | January of the same year (new) | Backward: almost always aggregates |

ADRH 2020 uses an identity table (`geo_tabla_identidad()`). The table for the 2024 tract map (`paso_final_2024`) also carries tourist dwellings to 2021 (§7.3).

**Table format.** Each row is a pair (source tract, 2021 tract) with these columns (`geo/LEEME.md`):
- `portales`: the weight of the pair;
- `metodo`: `callejero`, `catastro`, `codigo` or `identidad`;
- `fraccion`: the share of the source that goes to that destination. The fractions of each source add up to 1.

**Outside git.** With `PROVINCIA=<code>`, the pipeline is limited to one province. Those tables carry the code in their name and are not versioned.

### 3.3 Route (a): electoral census street register

- **Weight.** Each street segment in the register has a tract and a range of building entrances (portales). The weight of each pair is the number of entrances shared by the source tract and the 2021 tract (`geo_tabla_paso_callejero()`, `contar_portales()`).
- **Province by province.** The computation runs by province (`geo_tabla_paso_callejero_por_provincia()`). The join is by municipality, so the result does not change and memory is limited to the largest province (plan §6.3).
- **Same application at both ends.** Each table compares segments from the same INE application. The January 2021 street register was published with both the old and the new one (`tramos_2021_antigua`, `tramos_2021_nueva`; break `callejero_aplicacion_2021` in `inventario/rupturas.csv`).
- **Generic ranges.** The 0001–9999 ranges of the old application are trimmed to the last real entrance given by the new one (`geo_topes_portal()`, `recortar_tramos()`).
- **Limit.** The weight counts entrances, not dwellings: a block of a hundred dwellings weighs the same as a house. Besides, entrance numbers do not distinguish entrances that exist only on paper, as in half-built neighbourhoods. That is why route (b) exists.

### 3.4 Route (b): Cadastre dwellings

- **Weight.** Each building with dwellings in the INSPIRE service carries its number of dwellings (`numberOfDwellings`). One point inside each building footprint is taken (`leer_catastro_edificios()`, `leer_catastro_foral()`). The point is placed in a source tract and in a 2021 tract (`seccion_de_puntos()`), and the weight of the pair is the sum of dwellings (`geo_tabla_paso_catastro()`).
- **Year of construction.** The table for a tract map counts only buildings built up to that year; buildings of unknown year also count. The year comes from the Cadastre construction date (`beginning`). In the foral cadastres, each territory uses a different part of the date: Navarre, `beginning`; Bizkaia and Gipuzkoa, `end`; Álava, `anyPoint` (`anio_construccion_foral()`).
- **No crossing of municipalities.** Pairs from different municipalities are discarded, except within a merger or split group (§3.7). Municipal boundaries are digitised differently in each tract map; without that filter, the 2015 closure test failed in two municipalities of Madrid (±6–7%; plan §6.3).
- **Municipalities.** The Cadastre is read for 1,501 municipalities: those with tracts `estimado` by the street register in some table or belonging to a merger or split group (`municipios_catastro_sel`, `seleccionar_municipios_catastro()`).
  - 1,420 come from the State Cadastre. Each is matched to its zip file by name (`casar_municipios_catastro()`): 1,351 by normalised name and the rest by variants, bilingual names, truncated names and a manual table. Six offices have their own feed: Cartagena, Gijón, Jerez, Vigo, Ceuta and Melilla (plan §6.3).
  - 81 are in the Basque Country and Navarre, with their foral cadastres (since 8 Nov 2026).
- **Buildings.** In total, 5,849,539 buildings with 20,601,213 dwellings (`edificios_paso`):

  | Cadastre | Buildings with dwellings | Dwellings |
  |---|---|---|
  | State | 5,718,204 | 19,565,802 |
  | Foral (`edificios_forales`) | 131,335 | 1,035,411 |

  - 1,574 buildings have no year of construction.
  - 603 fall in no 2021 tract.
- **Foral check against the 2021 Census.** In the 11 municipalities with a Census figure, the difference in dwellings ranges from −5.0% to +3.0%; overall, −0.1% (plan §6.3).

### 3.5 Combination rule

The rule was adopted on 7 Nov 2026 and lives in `combinar_vias()` (plan §6.3).

**Which route decides for each source tract:**
1. **Falls whole** (fraction ≥ 0.99 towards one 2021 tract): route (a) decides. If the Cadastre gives its dwellings, the weight becomes the number of dwellings, so that the dominant source of medians compares dwellings with dwellings.
2. **Is split:** route (b) decides, if the tract has buildings with dwellings.
3. **The Cadastre also decides where the street register does not reach:**
   - sources that the Cadastre carries to another municipality of the same merger or split group;
   - sources with ADRH data that are on the map but not in the street register;
   - sources that the Cadastre carries in part to a 2021 tract that the combination would leave empty. This is repeated until none is left.
4. **«Ghost» tracts:** map codes that are neither in the street register nor in the ADRH of the same year. Their buildings go to the data source that, according to the street register, covers the same destination. If several cover it, those sources follow the street register (`reasignar_fantasmas()`).
5. **No route at all:** tracts with data that no route carries to 2021, but whose code exists in 2021, go to that tract (`completar_por_codigo()`, `metodo = "codigo"`).

**Result.** 2021 tracts with counts `estimado` and with medians `ausente`, first with the street register only and then with the combined table:

| ADRH | Source tract map | `estimado`, street register only | `estimado`, combined | Medians `ausente`, street register only | Medians `ausente`, combined | Pairs by street register / by Cadastre |
|---|---|---|---|---|---|---|
| 2015 | 2016 | 8,235 | 1,665 | 3,348 | 614 | 28,789 / 8,563 |
| 2016 | 2017 | 7,808 | 1,485 | 3,224 | 521 | 29,062 / 8,168 |
| 2017 | 2018 | 7,211 | 934 | 3,080 | 377 | 29,513 / 7,444 |
| 2018 | 2019 | 6,534 | 395 | 2,820 | 137 | 29,987 / 6,636 |
| 2019 | 2020 | 6,284 | 281 | 2,731 | 66 | 30,155 / 6,380 |
| 2021 | 2022 | 6,180 | 195 | 2,717 | 127 | 30,371 / 6,122 |
| 2022 | 2023 | 6,358 | 604 | 2,754 | 393 | 30,817 / 5,990 |
| 2023 | 2024 | 6,693 | 878 | 2,882 | 536 | 30,624 / 6,375 |
| 2024 | 2025 | 7,057 | 1,194 | 3,101 | 753 | 30,483 / 6,792 |

Origin of the columns:
- street register only: plan §6.3 (`tablas_paso_callejero`, with `geo_estado_paso()`);
- combined: `tablas_paso_finales`, with `geo_estado_paso()`;
- pairs: column `metodo` of `tablas_paso_finales`. No table currently has pairs by code (`metodo = "codigo"`).

### 3.6 Status of reprojected figures

The rule was adopted on 6 Nov 2026 (`geo_estado_paso()`; plan §6.3). The destination tract decides, not the direction. A source tract «falls whole» into the 2021 tract if its fraction towards it is ≥ 0.99.

- **Counts and weighted means:**
  - `dato` (data) if all sources received by the tract fall whole: adding, or averaging with their denominator, is exact;
  - `estimado` (estimated) if any is split.
- **Medians and indices.** They are not combined: the value of a single source is copied.
  - `dato` with a single source that falls whole: the same tract, even if its code changes.
  - `estimado` with a single split source, or with a dominant source contributing at least 95% of the weight the tract receives.
  - `ausente` (missing) if no source dominates. The higher scale is then shown instead.
- **Declared exception.** `estimado` is an exception to the native-level rule, limited to those tracts and years.
- **Statistical confidentiality.** When the table is applied to the data (`armonizar_ine_adrh()`, §5.3), whatever the source brings comes in.

**Check of the dominant source** (Madrid, one-year test with mean age and mean household size, which are not added up; plan §6.3):
- With a source contributing at least 95% (264 tracts), the error is that of 1:1 tracts. For mean age: median of 0.4 years and 90th percentile of 0.87 years, against 0.90 in 1:1 tracts.
- Between 80 and 95% (100 tracts), the 99th percentile rises to 2.7 years, against 1.4.

### 3.7 Municipal mergers and splits

Between 2016 and 2025 there are nine groups with 19 municipalities (`grupos_municipio`, `geo_grupos_municipio()`; plan §6.3):
- Cerdedo and Cotobade form Cerdedo-Cotobade (2017).
- Seven Andalusian splits on the 2019 tract map: San Martín del Tesorillo, Fuente Carreteros, La Guijarrosa, Valderrubio, Torrenueva Costa, La Zarza-Perrunal and El Palmar de Troya.
- Usansolo splits from Galdakao (2024).

**How a group is formed.** Each municipality present in only one of the two tract maps forms a group with those of the other that cover at least 1% of its area.

**What changes within a group:**
- Conversion tables and the closure test cross municipalities (`agrupar_municipio()`).
- New municipalities keep the street codes of the register very unevenly (Fuente Carreteros, 38 of 38; El Palmar de Troya, 19 of 71). That is why the Cadastre decides for sources that move to another municipality.

### 3.8 Orphan tracts and coverage exceptions

**ADRH orphan tracts** (warning `adrh_seccion_huerfana`; `huerfanas_adrh`, `seccion_huerfanas()`):
- Nine codes that are in no tract map from 2016 to 2025: seven in 2015 (5,409 people in total), one in 2016 and one in 2021.
- ADRH publishes them with codes from an earlier tract map. Almost always it is an extra tract of a municipality that later merges it.
- Without map or street register there is no conversion table: they are left out of the table and of the closure test.

| ADRH year | Tract | Population |
|---|---|---|
| 2015 | 0518602001 | 785 |
| 2015 | 2706501005 | 556 |
| 2015 | 4308601002 | 735 |
| 2015 | 4315503003 | 1,527 |
| 2015 | 4622004005 | 196 |
| 2015 | 5029703010 | 852 |
| 2015 | 5029703031 | 758 |
| 2016 | 4622004005 | 175 |
| 2021 | 1808704004 | 5 |

**Coverage exceptions** (`inventario/excepciones_cobertura.csv`; warning `cobertura_destino_excepcion`). Two 2021 tracts that the table leaves empty because of a known defect of the source:
- **3500201010** (ADRH 2015 and 2016). It has the same polygon in all tract maps and population in ADRH: 2,373 people in 2015. But the 2016 and 2017 street registers send its source to another tract, and the Cadastre does not reach it.
- **0309002003**, in Mutxamel (ADRH 2021–2024; also tourist dwellings, §7.3). On the 2021 map it is a farming area of 11 km² with no dwellings in the Cadastre, while ADRH 2020 gives it 1,110 inhabitants. From 2022 the code is elsewhere. Probably a mislabelled polygon in the 2021 tract map.

Hence the combined table reaches 36,332 of the 36,333 2021 tracts in 2015, 2016 and 2021–2024, and all of them in 2017–2019 (`tablas_paso_finales`).

### 3.9 Closure test and one-year test

**Closure test** (`cierre_poblacional`, blocking, ±0.5%; `comprobar_cierre_poblacional()`):
- **What it compares.** ADRH population by tract, carried to 2021 and added up by municipality (or by group), against the sum of its source tracts.
- **Result.** It passes in all nine years: 66,407 comparisons of municipality or group and year. The maximum deviation is 1.5 × 10⁻¹⁴%, machine rounding error (`comprobaciones_f1`).
- **Weak by construction.** Tables do not cross municipalities and each source distributes 100%, so it only detects tracts without a table and municipalities that change (plan §6.3).
- **Before 7 Nov 2026** the comparison was with the published municipal total. That discrepancy of the source is now watched by the warning `adrh_suma_secciones` (§4).

**Destination coverage** (`cobertura_destino`, blocking): no 2021 tract is left receiving nothing in the nine years, except the two exceptions (§3.8; `comprobar_cobertura_destino()`).

**One-year test.**
- **Design.** ADRH 2021 (2022 tract map) is carried to 2021 and compared with ADRH 2020, native to 2021. One year apart there is hardly any real growth, so the ratio between the two mostly measures the error of the table. With the old application of the street register, it is repeated with ADRH 2019 (2020 tract map).
- **What the next table compares.** The tracts that the street register splits, with the street-register-only table and with the combined table:

| Scope | ADRH (tract map) | Tracts split by the street register | Within ±5%: street register → combined | Central 90% of the ratio: street register → combined | Ratio outside [0.8; 1.25]: street register → combined | Tracts that fall whole: within ±5% | Source |
|---|---|---|---|---|---|---|---|
| Madrid (province) | 2021 (2022) | 465 | 66.5 → 92.5% | 0.81–1.28 → 0.96–1.04 | 50 → 7 | 94.8% | Plan §6.3 |
| Basque Country and Navarre (foral municipalities) | 2021 (2022) | 300 | 76.7 → 95.0% | 0.88–1.15 → 0.96–1.04 | 12 → 0 | 95.9% | Plan §6.3 |
| 1,501 municipalities with Cadastre (all of Spain) | 2021 (2022) | 6,180 | 61.2 → 94.1% | 0.72–1.52 → 0.96–1.04 | 1,003 → 37 | 96.0% (21,265 tracts) | `comparacion_vias` |
| 1,501 municipalities with Cadastre (all of Spain) | 2019 (2020) | 6,280 | 58.3 → 94.8% | 0.63–2.12 → 0.97–1.04 | 1,443 → 44 | 96.7% (21,151 tracts) | `comparacion_vias` |

Origin: `comparar_vias_paso()`; in `comparacion_vias`, rows with `estimada_a` true and false.

- **Result.** In the tracts that the street register splits, the combined table gives a spread of the same order as that of the tracts that fall whole.
- **Tract-by-tract diagnosis** (`diagnostico_f1`, `geo_diagnostico_paso()`; not a gate). It compares each year with ADRH 2020. Four or five years apart, it mixes the error of the table with the real growth of neighbourhoods.

### 3.10 Territorial hierarchy and base map

**Hierarchy** (`geo_jerarquia()`, `geo_territorios()`; targets `jerarquia_2021` and `territorios_2021`). Each tract of the 2021 tract map belongs to one district, one municipality, one province and one region (autonomous community). District, municipality and province come from the tract code; the region, from the CCA column of the tract map.

| Level | Units | Name |
|---|---|---|
| Tract | 36,333 | No name (code) |
| District | 10,479 | No name |
| Municipality | 8,131 | The current one, from ADRH (`nombres_municipios_adrh()`) |
| Province | 52 | 2021 tract map |
| Region | 19 | `geo/ccaa.csv` |

**Files in git** (`ficheros_jerarquia`, `exportar_jerarquia()`):
- `geo/jerarquia_2021.csv`: one row per tract, with its district, municipality, province and region;
- `geo/territorios_2021.csv`: level, code, name, parent unit and number of tracts of each unit. It is the names table of the website.

**Gate** (`comprobar_jerarquia()`, `validacion_jerarquia`; §4.1). No repeated tract; no unit with two parents; codes that fit together; each unit adds up its parts, and the total, the 36,333 tracts; no unit without a name. All 14 figures are 0.

**Base map** (`fichero_mapa_base`; `geo/referencia/mapa_base_2021.pmtiles`, outside git):
- **Layers** (`ZOOMS_MAPA_BASE`). Regions, provinces and municipalities are obtained by dissolving the tracts (`geo_capas_mapa_base()`), so their borders match those of the tracts, except where they absorb land without a tract (below). Above zoom 12, MapLibre overzooms the tiles.

  | Layer | Zooms | Attributes |
  |---|---|---|
  | comunidades | 0–12 | `ccaa`, `nombre` |
  | provincias | 3–12 | `provincia`, `nombre` |
  | municipios | 5–12 | `municipio`, `nombre` |
  | secciones | 7–12 | `seccion` |
  | sin_seccion | 0–12 | `km2`, `provincias`, `nombre`, `tipo` |

- **Land without a tract.** The 2021 INE tract map does not cover land that belongs to no municipality: shared mountains and common land, such as the Bardenas Reales or the Urbasa and Andía ranges. It is left as interior rings of the union of the tracts (`geo_huecos()`). Rings of at least 0.01 km² (`UMBRAL_SIN_SECCION_KM2`) are counted, less any tracts inside them (enclaves): 95, totalling 1,495 km²; the largest, 418.4 km². Below the threshold there are only slivers between neighbouring tracts, 1,140 under 1 m² and one of 13 m²; there is no ring between 13 m² and 1 ha. The gaps go in the `sin_seccion` layer, with their area and the codes of the provinces they touch. The 77 that touch a single province are added to it, and the 5 that touch several provinces of a single region, to the region (`geo_absorber_huecos()`). The other 13 stay out of those layers, because without the official boundary line no land is divided between provinces. The website shows them as «no data»; clicking one, the sheet says what it is. They have no population, no tract and no data. Gaps that touch the coast or the border are not interior rings and are not detected.

- **IGN names** (author's decision, 9 Nov 2026). The IGN administrative units (`ign_au`; `leer_ign_au()`, target `unidades_ign`) include the condominiums: mountains and land shared by several municipalities, such as *facerías*, *parzonerías*, *ledanías* or *comunidades*. Each gap is split by the units that overlap it by at least 0.01 km² (`geo_nombrar_huecos()`), the same threshold as the gaps: the smaller overlaps are 0.001 km² or less, edge contacts, and the next one is 0.012 km². Each piece carries the IGN's literal name, its type and the provinces it touches. The type is «condominio» (condominium), as the IGN's political map classifies them (the INSPIRE service gives them the «Municipio» level). 57 of the 95 gaps and 1,176.5 km² are named, in 73 pieces; 7 gaps have two units or more, and one in Burgos, 10. The layer carries each whole gap, unnamed, with its named pieces on top; on a click, the website gives the piece and, outside the pieces, the gap. What no unit covers thus keeps the generic text: 182.2 km² in the named gaps, 165.1 of them in the 264 km² gap between Álava and Navarre, where the IGN only draws the Parzonería de Entzia and the Monte Comunal de las Limitaciones de las Améscoas. The rest are thin strips along the edges, where the IGN and INE lines do not match; as separate pieces, tile quantization broke them. The other 38 gaps (136.3 km²) have no IGN unit and keep the generic text. Seven names in Burgos carry five-digit identifiers instead of names («Comunidad de 09076, 09290, 09578, 09606 y 09822»): they are not INE municipality codes and are given as they are. None of the 7 units with code 54 (territories outside any province) touches a gap. The sheet credits the IGN with the attribution its licence requires.

- **Tiles.** They are generated with GDAL from R, with the PMTiles and MVT drivers (`generar_pmtiles()`), without tippecanoe (plan §6.2). Each tile uses a grid of 4,096 units per 512 pixels. Simplification is measured in units of that grid, so it is the same on both sides of a shared border.
- **Simplification** (plan §11, question 16): 4 units (half a pixel) below zoom 12 and none at zoom 12. In GDAL, the maximum-zoom parameter is a tolerance, not a zoom number: it is set to 0 (`simplificacion_zoom_max`).
- **Size.** The file takes 35.4 MB (1 MB = 10⁶ bytes), with 13,235 tiles (`resumen_mapa_base`, `pmtiles_resumen()`):

  | Zoom | Tiles | MB | Largest tile (KB) |
  |---|---|---|---|
  | 0–4 | 13 | 0.04 | 9.0 |
  | 5 | 5 | 0.35 | 146.0 |
  | 6 | 10 | 0.46 | 149.4 |
  | 7 | 24 | 1.67 | 208.4 |
  | 8 | 71 | 2.27 | 142.5 |
  | 9 | 208 | 2.78 | 85.3 |
  | 10 | 702 | 4.12 | 68.4 |
  | 11 | 2,548 | 6.50 | 38.4 |
  | 12 | 9,654 | 17.13 | 58.0 |

- **Gate** (`comprobar_mapa_base()`, `validacion_mapa_base`). It reads the zoom 12 tiles with GDAL. `mapa_base_secciones`: it finds the 36,333 tracts. `mapa_base_huecos` (warning): 95 gaps in the tract map and 1,495 km², computed from the tracts. `mapa_base_sin_seccion` (blocking): with the tracts and the `sin_seccion` layer together, the layer widened by one grid unit (2.4 m at zoom 12), no gap is left open. With the IGN units, `mapa_base_huecos` also gives the named gaps (57) and their area (1,176.5 km²). `mapa_base_nombres` (blocking): the 73 named pieces carry their name and type in the zoom 12 layer, at their interior point. `mapa_base_nombres_dobles` (blocking): no land has two units at once (0 km²).
- **Publication** (plan §6.6; plan §11, question 16). The PMTiles file is not in the git history: it is regenerated with `targets` and published from a repository *release*, which the GitHub Pages workflow copies next to the website. Locally it can be viewed with `node geo/visor/servir.mjs` (`geo/visor/`).

**Postcodes** (plan §6.3; plan §11, question 16). They are not an INE unit and there are no reusable official polygons. The tract ↔ postcode correspondence will come from the INE street register (CPOS field of the segments): in January 2021, 80.7% of tracts have a single postcode (11,051 postcodes; 2,262 cross municipalities). Only indicators 11 and 16 need it. A geometry of its own built from the CartoCiudad entrances is decided in F4.

### 3.11 Conversion table from the 2011 Census

**What it carries** (plan §11, question 14; task 47). Indicator 18 for 2011 (2011 Census) and indicator 19 from August 2020 to February 2023 (`PERIODOS_VUT_2011`), which INE publishes on the 35,960 tracts of the 2011 Census, as of 1 November 2011. August 2023 is left out: it mixes codes from several tract maps (§7.3).

**Inputs** (`R/paso2011.R`; `bloque_paso2011` in `_targets.R`):
- **Map:** the 2011 Census tract boundaries (`secciones_censo2011`). They match the tourist dwellings and the Census indicators code by code (`paso2011_seccionado`). The tract map of 1 January 2011 does not: it has 4 codes that are not in the Census and lacks 3 (under review).
- **Street register:** that of January 2012, with segments as of 31 December 2011 (`tramos_2012`), in the old application, like the 2016–2020 tables. It is the closest to the Census date: January 2011 is ten months earlier and January 2012, two months later (author's decision, 10 Nov 2026). Even so it is not in phase: 63 of its codes are not in the Census and 45 Census codes are not in it, in 69 municipalities (`paso2011_descasados`, `paso2011_municipios_descasados()`).
- **Cadastre:** the F1 buildings (`edificios_paso`, §3.4), without reading any more. They are placed on the Census tracts (`edificios_censo2011`, `paso2011_origen_edificios()`): 5,848,919 buildings with 20,599,073 dwellings.

**Two tables** (`paso2011_tabla_catastro()`). As in F1, route (b) only counts buildings built up to the year of the data:
- the Census table, with those built up to 2011 (`paso_final_2011`; 19,778,309 dwellings);
- the tourist dwellings table, with those built up to 2020, the year of the first period (`paso_final_2011_vut`; 20,258,627 dwellings). With 2011 buildings, the tracts of neighbourhoods built later would receive no tourist dwellings.

**Combination** (`paso2011_combinar()`). The F1 rule (`combinar_vias()`, §3.5), with two adjustments for the phase of the street register:
- street-register sources that are not on the Census map are dropped;
- in the mismatched municipalities, route (b) decides for tracts with Cadastre buildings, because the street register only sees part of them. In 3 of those municipalities there is no Cadastre and the street register decides.

Municipal mergers and splits between 2011 and 2021 form 15 groups with 37 municipalities (`grupos_2011`, §3.7).

**Result** (2021 tracts; `resumen_paso2011`, `paso2011_resumen()`):

| Table | 2021 tracts that receive something | `estimado` | Medians `ausente` | Pairs by street register / Cadastre / code |
|---|---|---|---|---|
| Street register only | 36,286 | 11,043 | 4,242 | 81,344 / 0 / 3 |
| Combined, Census (buildings up to 2011) | 36,300 | 5,446 | 1,974 | 24,465 / 15,972 / 1 |
| Combined, tourist dwellings (up to 2020) | 36,314 | 5,497 | 1,998 | 24,464 / 16,032 / 1 |

- There are more `estimado` tracts than in any ADRH year (from 195 to 1,665; §3.5): ten years of boundary changes, with the Cadastre read only in the F1 municipalities. Of the 5,446 in the Census table, 366 are in 179 municipalities without Cadastre, where the street register splits.
- `ausente` medians do not affect these series: 18 and 19 are ratios of counts.

**Gate** (`paso2011_comprobar()`, `validacion_paso2011`; §4.1). In `anio`, 2011 for the Census table and 2020 for the tourist dwellings table.
- `cierre_poblacional`: the 2011 Census population carried to 2021 against that of its sources, by municipality or group. It passes in both tables, with 8,112 comparisons each and a maximum deviation of 1.4 × 10⁻¹⁴%. One municipality with no Census population is left out.
- `cobertura_destino`: passes in both tables with 19 exceptions (`inventario/excepciones_cobertura.csv`): 2021 tracts that neither the January 2012 street register nor the F1 Cadastre reach, in 18 municipalities. They are neighbourhoods built after 2011 or municipalities without Cadastre in F1 (under review). One of them, 3500201010, is already an ADRH exception (§3.8).
- `paso2011_cobertura_posterior` (warning): 14 2021 tracts with nothing from the Census table whose buildings all date from 2012 or later (in Madrid, Boadilla del Monte, Getafe, Leganés, Tres Cantos, Pamplona and Zaragoza). In 2011 they had no dwellings: their 2011 figure is `ausente`. The tourist dwellings table does reach them.
- `paso2011_sin_paso` (warning): 2 Census tracts with data that no route carries to 2021, 1502501002 and 3200701003: they have no segments in the street register nor Cadastre buildings read, and their code is not in 2021 (under review). They lose one tourist dwelling in two periods (§7.3).

---

## 4. Validation gate

**Rule.** Nothing is published that does not reproduce the source figures (guide, rule 3; plan §6.5). Each check has a row in `inventario/referencias_validacion.csv`, with its reference, tolerance and type. If a check has no row, the pipeline stops.

**How it is applied.** `validar_referencias()` compares each computed figure with its reference:
- `bloqueo` (blocking) checks stop the pipeline;
- `alerta` (warning) checks are listed as warnings at the end of `tar_make()`.

**Computation order.** Each target feeding the long table depends on its gate:
- `larga_adrh`, on `validacion_adrh` and on `validacion_f1` (geography, since 8 Nov 2026);
- `larga_serpavi`, `larga_censo2021` and `larga_vut`, on `validacion_serpavi`, `validacion_censo2021` and `validacion_vut`;
- `larga_derivados`, on `validacion_derivados`;
- `tabla_larga`, also on `validacion_sobrecarga` and `validacion_modulo`;
- the hierarchy and base map files, on `validacion_jerarquia`. `validacion_mapa_base` reads the PMTiles file once generated: it checks the file before publication;
- the website data (`ficheros_web`), on `validacion_jerarquia`, `validacion_mapa_base` and `validacion_derivados`. `validacion_web` checks the files once written;
- the website overburden section (`ficheros_web_sobrecarga`), on `validacion_sobrecarga`, `validacion_modulo`, `validacion_nuts` and `validacion_quintil` (the income quintile, `sobrecarga_quintil`, against Eurostat, `eurostat_quintil`): it does not depend on the long table. `validacion_web_sobrecarga` checks the files once written.

Each block of the long table also goes through `validar_tabla_larga()`: columns, levels and code lengths, states, empty values only in `secreto` and `ausente`, repeated rows, and cuts, groups, indicators and sources that exist in `inventario/`.

### 4.1 Checks in the pipeline

| `id` | What it compares | Tolerance | Type | Result | Target |
|---|---|---|---|---|---|
| `adrh_municipio` | Median, by year and indicator, of the deviation between tract means aggregated to municipality and the municipal figure | ±0.1% | Blocking | 0.0% in 2015–2024, income per person and per household | `validacion_adrh` |
| `adrh_dist_cobertura` | Provinces with municipalities in each tract table of indicators 4–6 (a truncated download stops at an intermediate province without raising an error) | Exact | Blocking | 52 in the three tables | `validacion_adrh_distribucion` |
| `adrh_dist_rango` | Figures of indicators 4–6 outside 0–100 | Exact | Blocking | 0 in the 30 figures of year and indicator | `validacion_adrh_distribucion` |
| `adrh_dist_fuentes_suma` | Maximum deviation, by year, of the sum of the five income sources from 100, in the areas with all five published | ±0.25 points | Blocking | 0.2 points at most in 2015–2024 | `validacion_adrh_distribucion` |
| `adrh_dist_umbrales_orden` | Areas where the population below 40% of the median exceeds that below 50%, or this exceeds that below 60% | Exact | Blocking | 0 in the 10 years | `validacion_adrh_distribucion` |
| `adrh_dist_seccion_unica` | Maximum difference, by year and indicator, between the tract and the municipality in single-tract municipalities | Exact | Blocking | 0 in the 30 figures | `validacion_adrh_distribucion` |
| `adrh_dist_municipio` | Median, by year and indicator, of the deviation (points) between the tracts of indicators 4 and 5 aggregated to municipality as a weighted mean (4 with gross income and 5 with population) and the municipal figure | ±0.05 points | Blocking | 0.006 points at most (indicator 5); 0 for indicator 4 | `validacion_adrh_distribucion` |
| `adrh_dist_provincia` | The same by province, with the published tracts, against the totals table: checks the name matching | ±0.3 points | Blocking | 0.16 points at most | `validacion_adrh_distribucion` |
| `cierre_poblacional` | Population reprojected to 2021 against the sum of its sources, by municipality or group | ±0.5% | Blocking | Passes in all nine years (§3.9) | `validacion_f1` |
| `cierre_poblacional` (2011 tables) | The same with the 2011 Census population, in the two tables from the 2011 Census (`anio` 2011 and 2020) | ±0.5% | Blocking | Passes: 8,112 comparisons per table, 1.4 × 10⁻¹⁴% at most (§3.11) | `validacion_paso2011` |
| `cobertura_destino` | 2021 tracts that receive nothing | Exact | Blocking | None, except the exceptions | `validacion_f1` |
| `cobertura_destino` (2011 tables) | The same in the two tables from the 2011 Census, without the tracts of `paso2011_cobertura_posterior` | Exact | Blocking | None, except 19 exceptions in each table (§3.11) | `validacion_paso2011` |
| `paso2011_seccionado` | Tourist dwelling tracts for 2020–2023 and 2011 Census tracts outside the 2011 Census map, and map tracts with no row in the tourist dwellings | Exact | Blocking | 0, 0 and 0 | `validacion_paso2011` |
| `paso2011_censo_alquiler` | Renting households (%) in 2011 for Spain, each region and each province in table 02003 against the 2011 Census tracts, with confidential tracts as an interval | ±0.1 points | Blocking | All 72 territories, within the interval | `validacion_paso2011` |
| `paso2011_censo_principales` | Households of the 2011 Census tracts summed against those of table 02003 | ±1% | Blocking | Spain, −0.03%; from −0.56% (Pontevedra) to +0.06% | `validacion_paso2011` |
| `paso2011_censo_paso` | Households and renting households in 2011 carried to 2021, summed by province, against their 2011 Census tracts | ±0.01% | Blocking | 0 in all 104 figures | `validacion_paso2011` |
| `paso2011_vut_paso` | Tourist dwellings for 2020–2023 carried to 2021, summed by province and Spain, against table 39364 | ±0.02% | Blocking | 0, except A Coruña in two periods (−0.02%; `paso2011_sin_paso`) | `validacion_paso2011` |
| `paso2011_vut_denominador` | 2011 Census tracts that fall whole and alone into the 2021 tract with the same code: median of the difference between INE's percentage and 100 × tourist dwellings / 2011 Census dwellings, by period | ±0.01 points | Blocking | 0.0001 points at most | `validacion_paso2011` |
| `paso2011_vut_territorios` | 2020–2023: percentage of Spain, each region and each province in table 39365 against 100 × tourist dwellings of its tracts / 2011 Census dwellings of its tracts | ±0.01 points | Blocking | All 432 figures; maximum difference, 0.0063 points (A Coruña, August 2022) | `validacion_paso2011` |
| `serpavi_provincia` | Observations of the tracts added up to province, by year and building type, against the provinces sheet (medians are not aggregated) | Exact | Blocking | Passes in all 1,040 figures: 52 provinces, 10 years and 2 building types | `validacion_serpavi` |
| `serpavi_espana` | Observations of the tracts, and separately those of the regions, added up to Spain, against the Spain row of the regions sheet | Exact | Blocking | Passes in all 40 figures. In 2022 and 2023, Spain is the sum of the regions without Gipuzkoa, because the Basque Country has no figure yet | `validacion_serpavi` |
| `serpavi_secreto` | Tracts, provinces and regions with a median and fewer than 10 observations, or without a median and with 10 or more | Exact | Blocking | 0 cases in the 60 figures of year, level and building type | `validacion_serpavi` |
| `serpavi_cuartiles` | Median without quartiles, monthly rent without rent per m² (or the reverse) or unordered quartiles | Exact | Blocking | 0 cases in the 60 figures | `validacion_serpavi` |
| `serpavi_escalas` | Share of municipalities and districts that do not match their tracts, by year and level | ±1% | Blocking | Maximum, 0.56% (municipalities in 2022) | `validacion_serpavi` |
| `serpavi_seccionado` | Tracts of the database outside the 2021 tract map, and districts and municipalities outside it with observations or a median | Exact | Blocking | 0 at all three levels | `validacion_serpavi` |
| `contratos_mediana` | Areas whose median and whose contracts (`contratos_alquiler`) do not match the confidentiality rule: with a median, 10 or more; confidential, 1 to 9; no data, 0 or none | Exact | Blocking | 0 cases in the 100 figures of year, level and housing type | `validacion_fiabilidad` |
| `contratos_suma` | Contracts of the tracts added up to province and, as in `serpavi_espana`, to Spain, in the long table | Exact | Blocking | Passes in the 1,080 figures: 1,040 for provinces and 40 for Spain | `validacion_fiabilidad` |
| `censo2021_alquiler` | Renting households (%) in Spain, each region and each province from the tracts, against table 59523. Tracts under confidentiality enter as an interval: their households may be between 0 and 100% renting | ±0.1 points | Blocking | Passes in all 72 territories; the published figure falls within the interval in 52; Spain, 16.10% in both; maximum difference, 0.055 points (Huelva) | `validacion_censo2021` |
| `censo2021_principales` | Households of the tracts against those published, in Spain and in the 7 regions and 19 provinces with no tract under confidentiality | ±0.5% | Blocking | Spain, −0.20% (the households of tracts under confidentiality); regions and provinces, from 0 to +0.17% (Melilla) | `validacion_censo2021` |
| `censo2021_seccionado` | Tracts of the CSV outside the 2021 tract map and tracts of the tract map without a row in the CSV | Exact | Blocking | 0 and 0 | `validacion_censo2021` |
| `censo2021_nacional` | Renting households (%) published for Spain against the weighted mean of the provinces and, separately, of the regions of table 59523 | Exact | Blocking | Passes: 16.10% in all three | `validacion_censo2021` |
| `vut_viviendas_provincia` | Tourist dwellings of the tracts added up by province and Spain, in the 13 periods, against table 39364 | Exact | Blocking | All 689 figures match: 13 periods and 53 territories | `validacion_vut` |
| `vut_seccionado` | Since February 2024: tracts of the 2024 tract map missing from table 5, plus tracts with tourist dwellings outside it | Exact | Blocking | 0 in the six periods | `validacion_vut` |
| `vut_paso_2021` | Tourist dwellings carried to 2021 with the 2024 → 2021 table, added up by province and Spain, against table 39364 | ±0.01% | Blocking | Deviation 0 in the 318 figures | `validacion_vut` |
| `vut_denominador` | 2024 tracts that fall whole and alone into the 2021 tract with the same code: median of the difference between the INE percentage and 100 × tourist dwellings / 2021 Census dwellings | ±0.01 points | Blocking | 0 in the six periods | `validacion_vut` |
| `vut_nacional_viviendas` | Tourist dwellings of the 52 provinces added up against those of Spain, in the 13 periods, in table 39364 | Exact | Blocking | All 13 periods match | `validacion_vut` |
| `vut_nacional_porcentaje` | Since February 2024: percentage for Spain in table 39365 against the mean of the provincial ones weighted by 2021 Census dwellings | ±0.02 points | Blocking | From −0.001 to +0.009 points | `validacion_vut` |
| `vut_territorios` | Since February 2024: percentage of Spain, each region and each province in table 39365 against 100 × tourist dwellings of its tracts / 2021 Census dwellings, with INE's denominator in each period (tracts with data up to August 2024; table 59521 since November 2024) | ±0.005 points | Blocking | All 432 figures pass; maximum difference, 0.005 points, the rounding (Jaén, February 2024) | `validacion_vut` |
| `jerarquia_unica` | Repeated tracts, units with more than one parent and codes that do not fit together | Exact | Blocking | 0 in the 5 figures | `validacion_jerarquia` |
| `jerarquia_sumas` | Units that do not add up their parts; tracts in excess or missing against the 2021 tract map | Exact | Blocking | 0 in the 6 figures | `validacion_jerarquia` |
| `jerarquia_nombres` | Regions, provinces and municipalities without a name | Exact | Blocking | 0 in the 3 figures | `validacion_jerarquia` |
| `mapa_base_secciones` | 2021 tracts missing from the maximum-zoom tiles of the PMTiles file | Exact | Blocking | 0 | `validacion_mapa_base` |
| `mapa_base_sin_seccion` | Gaps in the tract map still open with the tracts and the maximum-zoom `sin_seccion` layer together | Exact | Blocking | 0 | `validacion_mapa_base` |
| `mapa_base_nombres` | Pieces of land without a tract named after an IGN unit that do not carry that name and type in the maximum-zoom `sin_seccion` layer | Exact | Blocking | 0 of 73 | `validacion_mapa_base` |
| `mapa_base_nombres_dobles` | Area of the gaps with two IGN units at once | Exact | Blocking | 0 km² | `validacion_mapa_base` |
| `smi_neto` | Net monthly income of the 2026 Minimum wage token (`perfiles`) against the plan figure: €17,094 × (1 − 0.065) / 12 ≈ €1,332 | ±€1 | Blocking | €1,331.91; difference, −€0.09 | `validacion_derivados` |
| `derivados_terminos` | Maximum deviation, by year and indicator, between each derived figure and the one recomputed from its terms | ±0.001% | Blocking | 4.3 × 10⁻¹⁴% at most in the 41 figures | `validacion_derivados` |
| `derivados_estado` | Derived figures whose status is not the worst of their terms (for 15, that of the rent, or `ausente` with no token income), or with a value and status `secreto` or `ausente` (or the reverse) | Exact | Blocking | 0 in the 41 figures | `validacion_derivados` |
| `derivados_rango` | Derived figures outside the possible range: burden, from 0.1 to 100%; rent share of income, from 0.1 to 300%; pay needed, from 100 to 20,000 net € a month with actual monthly rent and from 100 to 10,000 € with the 50 m² minimum (by indicator and cut; task 40) | Exact | Blocking | 0 in the 60 figures | `validacion_derivados` |
| `perfiles_mochila` | Provinces of the Young adult token without an INE code in `inventario/provincias_aeat.csv`, provinces repeated in a year and provinces of the table without the token (over the 10 years) | Exact | Blocking | 0 in the 3 figures | `validacion_derivados` |
| `supuestos_inventario` | Assumptions in `inventario/supuestos.csv` whose default lies outside their options, without unit, use or decision, repeated or missing (§6.7) | Exact | Blocking | 0 in the 12 assumptions | `validacion_supuestos` |
| `supuestos_r` | Pipeline constants that differ from the CSV (floor areas, threshold, «Can you make rent?» bands, manifest and home-purchase assumptions) | Exact | Blocking | 0 of 9 | `validacion_supuestos` |
| `supuestos_web` | `web/js/supuestos.js` differing from what R generates from the CSV, or floor area, threshold and instalment buttons of `web/mapa.html` differing from their options | Exact | Blocking | 0 of 4 | `validacion_supuestos` |
| `supuestos_muestra_21` | Sample of 14 territories in 2024: required pay from the page's calculations with the default assumptions against indicator 21 of the long table, both figures | ±0.001% | Blocking | 0% | `validacion_supuestos` |
| `supuestos_muestra_15` | Same sample: rent share of income of the Minimum wage, Young adult and Pensioner tokens against indicator 15 of the long table | ±0.001% | Blocking | 2 × 10⁻¹⁴% at most in the 40 figures | `validacion_supuestos` |
| `supuestos_superficie_tipica` | Typical floor area of Madrid, Barcelona and València in 2024 against task 37 of the backlog (62, 66 and 83 m²) | ±0.5 | Blocking | 62.1, 65.7 and 83.0 m² | `validacion_supuestos` |
| `smi_boe` | Monthly minimum wage of each year in `SMI_FICHAS` against that of the royal decree in its BOE XML, and the cited rule; 2021, mean weighted by months in force | Exact | Blocking | 0 in the 18 figures (2015–2023) | `validacion_smi` |
| `inss_cobertura` | Provinces, multi-province regions and Spain missing or repeated in any month of the year (INSS Excel) | Exact | Blocking | 0 in the 11 years | `validacion_inss` |
| `inss_suma` | Retirement pensions of the provinces against the number published for their region and for Spain, each month | Exact | Blocking | 0 in the 11 years (132 figures a month) | `validacion_inss` |
| `inss_media` | Average retirement pension of the provinces, weighted, against the one published for their region and for Spain, each month | ±€0.01 | Blocking | €4.5 × 10⁻¹³ at most | `validacion_inss` |
| `transistor_cobertura` | Provinces without a net Pensioner income in any year | Exact | Blocking | 0 in the 11 years | `validacion_transistor` |
| `transistor_retencion` | Pensioner withholding outside [0, 30%] | Exact | Blocking | 0 in the 11 years | `validacion_transistor` |
| `aeat_provincia` | Figures of the AEAT provincial table whose published average wage is not wages / employees rounded to the euro | Exact | Blocking | 0 in the 15 years (2011–2025) | `validacion_salarios` |
| `aeat_salarios_cobertura` | Common-regime provinces (48), regions (17) and Spain without the overall average wage and that of ages 26 to 35, or repeated | Exact | Blocking | 0 in the 15 years | `validacion_salarios` |
| `aeat_salarios_suma` | Employees of the provinces added up against those published for their region and for Spain | Exact | Blocking | 0 in the 15 years (36 figures a year) | `validacion_salarios` |
| `aeat_salarios_media` | Average wage of the provinces (wages / employees added up) against that published for their region and for Spain | ±€0.5 | Blocking | €0.499 at most: the rounding of the published figure | `validacion_salarios` |
| `mochila_cobertura` | Common-regime provinces with the full-year module (46) without a net Young adult income in some year, or repeated | Exact | Blocking | 0 in the 11 years (2015–2025) | `validacion_mochila_serie` |
| `percentil_cobertura` | Common-regime regions (15) and Spain without a complete wage curve (percentiles 1 to 99) | Exact | Blocking | 0 in the 11 years (2015–2025) | `validacion_percentil` |
| `percentil_monotono` | Wage curves whose net pay does not rise with the percentile | Exact | Blocking | 0 in the 11 years | `validacion_percentil` |
| `percentil_suma` | Employees of the 13 wage bands against the total of their region or of Spain | ±10 employees | Blocking | 1 at most, in 5 of the 11 years: the source is off by one employee | `validacion_percentil` |
| `percentil_limites` | Bands whose average wage falls outside their limits with the annual minimum wage of the year (14 payments) | Exact | Blocking | 0 in the 11 years | `validacion_percentil` |
| `web_salarios` | Figures of `web/datos/salarios.json` different from the curves rounded to the euro, and curves missing or extra | Exact | Blocking | 0 | `validacion_web_salarios` |
| `web_valores` | Value files in `web/datos/` whose values or states are not those of the long table (with the rounding of the guide to the precision of each series: one decimal; two for indicator 19) or whose length is not that of the index; series without a file. Also the contracts and margin of each rent series | Exact | Blocking | 0 in the 830 figures | `validacion_web` |
| `web_fichas` | By municipality: cells of the series of its sheet that do not reproduce the long table with the precision of each series, and tracts in excess or missing | Exact | Blocking | 0 in the 8,131 municipalities | `validacion_web` |
| `portada_valores` | Figures of the front-page cards (`web/datos/portada.json`): pay needed in the median tract with actual monthly rent and its 10th and 90th percentiles, and alongside the median of the 50 m² minimum; tracts where the rent of 50 m² takes more than 30 and 40 % of the net minimum wage and, alongside, where actual monthly rent does; and overburden in Spain, recomputed from monthly rent, rent per m² and the minimum-wage income the website receives, and from the overburden rows | Exact | Blocking | 0 in the 15 figures | `validacion_portada` |
| `portada_casillas` | Front-page squares (`inventario/casillas_portada.csv`): 24, order with no gaps, unique ids, four families, active ones with a destination and inactive ones without, and destinations that exist (maps in the manifest, keys of `web/js/estado.js` and anchors of the generated pages) | Exact | Blocking | 0 in the 24 squares | `validacion_portada` |
| `web_sobrecarga_valores` | Website overburden section: by view, value, rank, block, source and flag of each figure against the pipeline targets (with the rounding of the guide), and units in excess or missing; Spain series, annual breakdowns with the quintile, access module and map cut-offs against `cortes_web` of indicator 22 | Exact | Blocking | 0 in the 17 figures | `validacion_web_sobrecarga` |
| `web_sobrecarga_muestra` | INE figures without a sample size, with a sample different from that of the computation, with a flag other than the EU-SILC one or with a value and fewer than 20 observations; Eurostat figures without their table, with a sample size or with a flag other than that of the source | Exact | Blocking | 0 in the 13 figures | `validacion_web_sobrecarga` |
| `sobrecarga_es_total`, `sobrecarga_es_mercado`, `sobrecarga_ccaa` | Overburden from ECV microdata against Eurostat | ±0.1 points | Blocking | Pass in 2023–2025 (§7.5) | `validacion_sobrecarga` |
| `sobrecarga_quintil_total` | By wave: mean of the overburden rates of the five income quintiles, weighted by their people, against the overall rate | ±0.01 points | Blocking | Difference 0 in all three waves | `validacion_quintil` |
| `sobrecarga_quintil_eurostat` | Overburden in Spain by income quintile, from ECV microdata and unrounded, against Eurostat (`ilc_lvho07b`) for the same year | ±0.1 points | Blocking | All 15 figures of 2023–2025 pass, equal to one decimal; maximum difference, 0.045 points (§7.5) | `validacion_quintil` |
| `modulo_acceso_lectura` | Sum of the regions against the national total of the ECV 2025 module | ±0.1% | Blocking | Passes | `validacion_modulo` |
| `i18n_completo`, `contraste_texto`, `rampa_contorno`, `rampa_daltonismo` | ES/EN dictionaries, website contrasts and a seven-step ramp distinguishable under simulated colour blindness (0.07 in OKLab at least; task 51) | Exact | Blocking | Pass | `validacion_i18n`, `validacion_diseno` |
| `adrh_municipio_detalle` | Deviation of each municipality between aggregated tract means and the municipal figure | ±1% | Warning | Warns in 579 of 146,306 figures of municipality, year and indicator; 135 exceed 5% | `comprobaciones_adrh` |
| `adrh_dist_municipio_detalle` | Deviation (points) of each municipality between the tracts of indicators 4 and 5 aggregated as a weighted mean and the municipal figure | ±1 point | Warning | Warns in 98 of 108,360 figures of municipality, year and indicator; 33 exceed 2 points and the largest is 5.8 | `comprobaciones_adrh_distribucion` |
| `adrh_suma_secciones` | ADRH population by tract added up by municipality against the municipal total of the same table | ±0.5% | Warning | Warns in 160 municipality-years, all in 2015–2019 (38, 34, 30, 29 and 29) | `comprobaciones_f1` |
| `adrh_seccion_huerfana` | ADRH tracts with no code in any tract map of 2016–2025 | Exact | Warning | 9 (§3.8) | `huerfanas_adrh` |
| `cobertura_destino_excepcion` | 2021 tracts left empty by a known defect of the source | Exact | Warning | 2 tracts, 6 tract-years (§3.8) | `comprobaciones_f1` |
| `cobertura_destino_excepcion` (2011 tables) | The same, in the tables from the 2011 Census | Exact | Warning | 19 tracts in each table (§3.11) | `comprobaciones_paso2011` |
| `paso2011_cobertura_posterior` | 2021 tracts with nothing from a table from the 2011 Census whose Cadastre buildings all postdate its year | Exact | Warning | 14 in the Census table; none in the tourist dwellings table | `comprobaciones_paso2011` |
| `paso2011_sin_paso` | 2011 Census tracts with data that no route carries to 2021 | Exact | Warning | 2, in both tables | `comprobaciones_paso2011` |
| `mapa_base_huecos` | Gaps of at least 0.01 km² in the 2021 tract map (land in no tract): number and area, in total and named after an IGN unit | Exact | Warning | Warns with 95 gaps and 1,495 km² (the largest, 418.4 km²); named after an IGN unit, 57 and 1,176.5 km² (§3.10) | `validacion_mapa_base` |
| `serpavi_escalas_detalle` | Each municipality or district, year and building type that does not match its tracts | Exact | Warning | Warns in 164 rows, which go as `ausente` (§7.1) | `validacion_serpavi` |
| `serpavi_forales` | First year with observations of each foral province against that of the break `serpavi_forales` | Exact | Warning | All four match | `validacion_serpavi` |
| `serpavi_sin_fila` | Tracts, districts and municipalities of the 2021 tract map that the database does not have (they go as `ausente`) | Exact | Warning | Warns with 40 tracts, 36 districts and 36 municipalities (§7.1) | `validacion_serpavi` |
| `margen_rango` | Tracts with the approximate margin of the median outside 1–40%, by year, indicator and housing type | Exact | Warning | Warns in the 40 figures: 2,414 tracts and years in 2015–2024, 2,242 of them single-family; in 2024, 16 apartment and 268 single-family (§7.6) | `validacion_fiabilidad` |
| `vut_denominador_detalle` | The tracts of `vut_denominador`, one by one (only those more than 0.001 points apart) | ±0.1 points | Warning | Passes: 839 tract-periods, all since November 2024; maximum difference, 0.091 points | `validacion_vut` |
| `derivados_rango_detalle` | Each derived figure outside the usual range: burden, below 3% or above 60%; rent share of income, 3% or 150%; pay needed, €200 or €10,000 with actual monthly rent and €200 or €4,000 with the 50 m² minimum | Exact | Warning | Warns in 43 figures: three burdens above 60% (2019 and 2022); with the 50 m² minimum, 18 pay-needed figures below €200 in 2015–2018 and two above €4,000 (two tracts in Madrid, 2024); with actual monthly rent, 19 above €10,000 and one below €200 (task 40) | `validacion_derivados` |
| `supuestos_muestra_fichero` | `pruebas/datos/supuestos_muestra.json` (14 territories × 40 combinations of «Your token» and the three one-person tokens) differing from the pipeline sample | Exact | Warning | Up to date | `validacion_supuestos` |
| `supuestos_superficie_tipica_mediana` | Median typical floor area of municipalities in 2024 against the calculation of 11 Nov 2026 (82.1 m²) | ±0.5 | Warning | 82.1 m² in 2,555 municipalities | `validacion_supuestos` |
| `supuestos_superficie_tipica_rango` | Municipal typical floor areas outside 40 to 160 m², 2015 to 2024 | Exact | Warning | None | `validacion_supuestos` |
| `otros_gastos_cobertura` | Renters' other housing costs (§6.7): regions and waves without a figure (Spain's for the wave times the region's factor) | Exact | Warning | None | `validacion_otros_gastos` |
| `otros_gastos_negativos` | Market-rate renters whose total housing cost (HH070) is below their rent (HH060) | Exact | Warning | None | `validacion_otros_gastos` |
| `otros_gastos_rango` | Figures for Spain and the regions outside 50 to 300 € a month | Exact | Warning | None | `validacion_otros_gastos` |
| `otros_gastos_hogares` | Households of the regions minus those of Spain, by wave | Exact | Warning | 0 | `validacion_otros_gastos` |
| `otros_gastos_mediana` | Medians that fail the definition checked another way (weight below and up to it) or do not match the table | Exact | Warning | None | `validacion_otros_gastos` |
| `otros_gastos_minimo` | Regions wrongly flagged with Spain's figure (those under 50 observations with the waves pooled, with factor 1, and only those) | Exact | Warning | None | `validacion_otros_gastos` |
| `otros_gastos_factor` | Regional factors that fail the definition checked another way, do not match the table, fall outside 0.5 to 1.5 or do not give the figure (Spain's for the wave times the factor) | Exact | Warning | None | `validacion_otros_gastos` |
| `web_otros_gastos` | `datos/otros_gastos.json` against the `otros_gastos` table: figures, factors, observations and flags | Exact | Block | No difference | `validacion_web_otros_gastos` |
| `web_fuera_indice` | Long-table rows going to the website with no slot in the index of their level | Exact | Warning | Warns in 16 municipality rows; at the other levels, 0 | `validacion_web` |
| `web_tramos` | By map and set of cut-offs (tract, municipality, and province and region together), in the latest year: classes that are empty or hold more than 35% of the units with data; maps without sets that are not a declared exception | Exact | Warning | Passes: no class empty or above 35% in the 35 sets of 15 maps; the fullest, 31% (Gini, province and region, 2024) | `validacion_web_tramos` |
| `web_sobrecarga_geometria` | Units of a view of the overburden map with no geometry in their NUTS version or in the fallback one | Exact | Warning | Passes: 0 in the 12 views (§7.5) | `validacion_web_sobrecarga` |
| `aeat_mediana_deciles` | SME median by region interpolated from deciles against centiles | ±0.5% | Warning | Between −0.19 and +0.45% (2019–2025) | `validacion_mochila` |
| `mochila_ecv` | Young adult token of each region and of Spain against the 95% interval of the ECV median gross pay, which comes from its sample size (how far outside, in %) | Exact | Warning | Warns on 20 of 160 figures (with ±15%, on 32); the interval goes from ±2.7% (Spain) to ±57% (regions with about 50 observations) | `validacion_mochila_ecv` |
| `mochila_neto_ecv` | Gross-to-net step applied to the ECV median gross pay against the median net pay, each year | ±5% | Warning | Warns on 8 of 180 figures, all regional (from −5.0 to +19.0%); in 2024, between −2.0 and +3.4%; Spain, between −1.2 and +2.5% (+0.5% in 2024) | `validacion_mochila_neto_ecv` |
| `mochila_forma` | Median-to-mean ratio of the SME at ages 26 to 35 of each region, from 2020 to 2025, against that of 2019, used for 2015–2018 | ±3% | Warning | Passes: between −2.7 and +1.8% | `validacion_mochila_serie` |
| `mochila_relacion_ecv` | Median-to-mean ratio of the gross pay of those who worked the twelve months, aged 26 to 35, in the ECV for Spain, 2015 to 2018 against 2019 (points) | ±2 points | Warning | Warns in 2015 (+2.1) and 2017 (−3.1) | `validacion_mochila_relacion` |
| `mochila_relacion_correccion` | If the previous one warns, the correction (the 2019 ratio scaled with the ECV) is only applied if it validates in 2020–2024 | Exact | Warning | Warns and is not corrected: mean error of 4.0 points scaled against 0.6 unscaled | `validacion_mochila_relacion` |
| `percentil_media` | Mean of the modelled distribution by bands against the published average wage of each region and of Spain | ±0.5% | Warning | Passes: 0.12% at most (2017) | `validacion_percentil` |
| `sobrecarga_es_edad` | Overburden in Spain by age group | ±0.1 points | Warning | Passes in 2023–2025; maximum difference, 0.05 points (plan §7, F1b) | `validacion_sobrecarga` |
| `sobrecarga_quintil_reparto` | Population with income (weight RB050) in each quintile, by wave | ±1 point around 20% | Warning | Passes: from 19.95 to 20.05% | `validacion_quintil` |
| `nuts_geometria` | Regions with data and no geometry in their NUTS version or, as a fallback, in a later one | Exact | Warning | Warns: the grouped code FI19_20 in 2021–2025 | `validacion_nuts` |
| `contraste_declarado` | Contrast declared in `tokens.json` against the recomputed one | ±0.05 | Warning | Passes; maximum difference, 0.003 | `validacion_diseno` |
| `ipva_variacion` | Published annual change of the IPVA against the one recomputed from the indices | ±0.06 points | Blocking | Maximum difference, 0.051 points | `validacion_ipva` |
| `ipva_nota` | Spain, Madrid, Barcelona and the Valencian Community in 2024 against the press release | Exact | Blocking | 3.5; 3.6; 3.3 and 5.0% | `validacion_ipva` |
| `ipva_contrato_enlace` | 2021 change of new and existing tenancies against the one recomputed from their index and the general 2020 index | ±0.06 points | Blocking | Maximum difference, 0.049 points | `validacion_ipva` |
| `ipva_contrato` | Spain by contract age (table 59004): 2021 and 2024 index of new tenancies, existing ones and the total; change of new and existing tenancies in 2021, 2022 and 2024 | Exact | Blocking | Index: 114.871 and 137.041; 112.229 and 120.637; 112.694 and 122.920. Change: 3.5 and 1.2%; 5.3 and 2.1%; 8.8 and 2.8% | `validacion_ipva` |
| `hipotecas_tipo_anual` | Annual average rate of home mortgages against the mean of its twelve months | ±0.05 points | Blocking | Maximum difference, 0.024 points (2020) | `validacion_hipotecas` |
| `valor_tasado_nombres` | Ministry names with no INE code | Exact | Blocking | None: 306 municipalities matched | `validacion_valor_tasado` |
| `valor_tasado_ccaa` | Regions and Spain outside the range of their provinces | Exact | Blocking | No quarter since 2015 | `validacion_valor_tasado` |
| `valor_tasado_tasaciones` | Appraisals of the regions and of Spain against the sum of those of their provinces | Exact | Blocking | Equal since 2015 | `validacion_valor_tasado` |
| `valor_tasado_nota` | Spain in the first quarter of 2026 | Exact | Blocking | 2,315.7 €/m² | `validacion_valor_tasado` |
| `compraventa_coherencia_espana` | Implied floor area for Spain (deeds over appraisal) outside 70–110 m² | Exact | Blocking | Passes: from 91.8 to 106.1 m² (2015–2025) | `validacion_coherencia_compraventa` |
| `compraventa_coherencia_provincias` | Provinces and quarters with an implied floor area outside 50–150 m² | ±5% | Blocking | 1.9% at most (2021) | `validacion_coherencia_compraventa` |
| `compraventa_terminos` | Years of wages and mortgage payment over household income against their terms | ±0.001% | Blocking | Passes in 2015–2025 | `validacion_derivados_compraventa` |
| `registradores_lectura` | Registradores (indicator 11): by year, missing provinces, regions or Spain, duplicate rows and empty figures | Exact | Blocking | 0 in 2015–2026 | `validacion_registradores` |
| `registradores_espana` | Spain, housing price per m² in 2025 (plan §11, question 45: €2,284/m²) | ±0.5 | Blocking | Passes: €2,283.52/m² | `validacion_registradores` |
| `registradores_suma` | Sales of the provinces against those of their region and of Spain, each quarter | Exact | Blocking | 0 in 2015–2026 | `validacion_registradores` |
| `registradores_agregado` | Price per m² of Spain and of the regions against the mean of their provinces weighted by sales | ±3% | Warning | From −0.6 to +1.5% (2015–2025): no warning | `validacion_registradores` |
| `registradores_rango` | Prices per m² outside €300–10,000 | Exact | Blocking | 0 | `validacion_registradores` |
| `registradores_tasado_espana` | Registradores price per m² over the appraised value per m², Spain, outside 0.85–1.25 (question 45 b) | Exact | Blocking | Passes: from 0.99 (2015) to 1.12 (2022) | `validacion_registradores` |
| `registradores_tasado_provincias` | The same ratio, province against province: % outside 0.6–1.6 | ±5% | Blocking | 0% every year (from 0.74 to 1.41) | `validacion_registradores` |
| `registradores_tasado_detalle` | Each province and year with the ratio outside 0.7–1.4 | Exact | Warning | Warns for Santa Cruz de Tenerife, 2022 (1.41) | `validacion_registradores` |
| `compraventa_renta_cobertura` | Published average net income per household (ADRH, table 53689): missing provinces, regions or Spain, with or without a figure, and duplicate rows | Exact | Blocking | 0 in 2015–2024 | `validacion_renta_hogar_publicada` |
| `compraventa_renta_publicada` | Median, by year and level, of the absolute deviation between household income of the municipalities aggregated with their households and the published one | ±0.5% | Blocking | 0.13% at most (Spain, 2021) | `validacion_renta_hogar_publicada` |
| `compraventa_renta_publicada_detalle` | Each province, region and year with the aggregate more than ±1% from the published one | ±1% | Warning | Warns for 6 of 691 figures: Guadalajara from 2015 to 2019 (from +1.1 to +1.3%) and Seville in 2016 (−1.4%) | `validacion_renta_hogar_publicada` |
| `cp_municipio_reparto` | Weights of a postcode that do not add up to 100, or with no single main municipality | ±0.001 | Blocking | Passes in all 11,046 postcodes | `validacion_cp_municipio` |
| `web_cp` | Postcode and municipality pairs of `web/datos/cp.json` (the website search box) missing or extra against the table, postcodes with their municipalities in another order and a manifest without the file path | Exact | Blocking | None in the 11,046 postcodes | `validacion_web_cp` |
| `zonas_tensionadas_resolucion` | Rows of the indicator 20 inventory without their BOE resolution downloaded, or with another publication date | Exact | Blocking | None of 321 | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_codigos` | Codes that are not municipalities of the 2021 tract map, with another INE name or outside the region of their BOE row | Exact | Blocking | None | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_completa` | Municipalities or areas in the BOE tables missing from the inventory | Exact | Blocking | None in the 31 rows of the 10 resolutions | `validacion_zonas_tensionadas` |
| `zonas_tensionadas_fechas` | Effective date other than the day after publication (for an extension, or the day after the end of the period it extends), end date other than the one set by the text, and extensions without an earlier declaration of the same area | Exact | Blocking | None of 321 | `validacion_zonas_tensionadas` |
| `web_zonas_tensionadas` | Website declarations that differ from those of the inventory | Exact | Blocking | None | `validacion_web_zonas_tensionadas` |
| `portales_codigos` | Figures of the portals layer with codes that are not regions, provinces or municipalities of the 2021 tract map (zones and localities: their municipality's) | Exact | Blocking | None, with `PORTALES=TRUE` | `validacion_portales` |
| `portales_idealista_espana` | Spain, Idealista rents, annual mean of the published months (at least 9) in 2015 and 2024 | ±0.005 | Blocking | Passes: 7.58 and 13.06 €/m² | `validacion_portales` |
| `portales_idealista_municipios` | Idealista municipalities with a series and, of them, with a series from 2015 or earlier | Exact | Blocking | Passes: 278 of 286 | `validacion_portales` |
| `web_portales` | Round trip of `datos/portales/`: figures, statuses, report links and zones against the layer, and no portal series in the general manifest | Exact | Blocking | No difference, with `PORTALES=TRUE` | `validacion_web_portales` |
| `entrar_tramos` | Bands of `inventario/entrar_tramos.csv`: each band of the gap, counting the limits, at least 15% wide from edge to edge, and the derived figures, without cut points of their own (§7.8) | Exact | Blocking | None, with `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_rango` | Gaps between asking rents and the stock outside 0.8–2.5, at any level | Exact | Blocking | None, with `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_rango_detalle` | Each gap of 2 or more | Exact | Warning | 17 municipal figures: 2 in 2017, 2 in 2018, 5 in 2023 and 8 in 2024 | `validacion_entrar` |
| `entrar_coherencia` | Pay to move in (typical floor area and 50 m²) and barrier to moving in (`barrera_entrar`) of the three tokens outside the range the website computes from the band of their gap | Exact | Blocking | None, with `PORTALES=TRUE` | `validacion_entrar` |
| `entrar_municipios` | Municipalities with asking rents and SERPAVI in the same year, against task 37 of the backlog | Exact | Blocking | Passes: 256 in 2015 and 259 in 2024 | `validacion_entrar` |
| `entrar_mediana` | Median gap of those municipalities in 2015 and 2024, against task 37 of the backlog | ±0.01 | Blocking | Passes within 0.01, not within 0.005: the reference divides by SERPAVI at source precision, and the pipeline at one decimal, as the website does (under review) | `validacion_entrar` |
| `entrar_mediana_rango` | Median gap of the municipalities in 2024, between 1.30 and 1.40 | ±0.05 | Blocking | Passes | `validacion_entrar` |
| `entrar_superficie` | Median typical floor area of those municipalities in 2024, against task 37 of the backlog | ±0.5 | Blocking | Passes: 77 m² | `validacion_entrar` |
| `entrar_ipva` | Provinces where asking rents grow from 2021 to 2024 more than twice as much as IPVA new tenancies | Exact | Warning | 7 of 47 provinces | `validacion_entrar` |
| `web_entrar` | Round trip of `datos/portales/entrar/`: band and status of each territory against R, the manifest's cut points and no value that is not a band | Exact | Blocking | No difference, with `PORTALES=TRUE` | `validacion_web_entrar` |
| `hist_series` | Historical module (§7.9): for each Spanish series, periods without a figure between the first and the last, duplicates and figures outside their plausible range | Exact | Blocking | 0 in the seven Spanish series (1987–2026) | `validacion_historico` |
| `hist_publicadas` | Years of income and theoretical burden from 2023 to 2026 in the Banco de España PDF table (5 Nov 2026; a year, the simple mean of its quarters) and the August 2026 reference rate in the Official State Gazette. A Banco de España revision warns and asks for the reference to be updated | ±0.05 | Warning | Passes: the 14 PDF figures and the Gazette one (3.134%) | `validacion_historico` |
| `hist_publicadas_enteras` | Spain's appraised value as reproduced by the Banco de España in whole euros, from 2023 to 2026 | ±0.5 | Warning | Passes: the 7 figures | `validacion_historico` |
| `hist_prensa` | Press figures in the plan that the series confirms (§7.9) | ±0.5 | Warning | Passes: 2.90 (Q1 1987), 9.46 (Q3 2007) and 72.47% (Q2 1990) | `validacion_historico` |
| `hist_fechas` | Key dates of the page: highs and lows in their period, the others within their series, and the breaks, those in `inventario/rupturas.csv` | Exact | Blocking | Passes: 14 dates, 3 of them breaks | `validacion_historico` |
| `hist_valor_tasado_bde` | Maximum difference between Spain's MIVAU appraised value and the one reproduced by the Banco de España | ±0.1 €/m² | Blocking | €0.0/m² in 126 quarters | `validacion_historico` |
| `hist_valor_tasado_ccaa` | By year, quarters with a multi-province region outside the range of its provinces, and quarters without a regional figure | Exact | Warning | Warns in 15 quarters (§7.9) | `validacion_historico` |
| `hist_salarios_suma` | National Accounts: compensation against wages plus contributions, and the total against the sum of the A10 industries (wages and employees) | ±1 | Blocking | 0 in 1995–2025 | `validacion_cne` |
| `web_historico` | Round trip of `datos/historico/historico.json`: figures, periods, series, territories, key dates and breaks | Exact | Blocking | 0 | `validacion_web_historico` |
| `cis_vivienda_publicada` | Housing as a problem (CIS), Spain and personal, rounded to one decimal, against the CIS press releases (§7.10) | ±0.1 points | Blocking | All five figures match exactly | `validacion_cis` |
| `cis_vivienda_suma` | Total mentions against the sum of the first, second and third | ±0.2 points | Blocking | At most 0.1 points in the HTML and 0.045 in the XLSX | `validacion_cis` |
| `cis_vivienda_rango` | Figures outside 0–100 or missing, barometers with fewer than 1,000 interviews, months with only one of the two questions and repeated studies | Exact | Blocking | None | `validacion_cis` |
| `cis_vivienda_categoria` | Barometers without the «La vivienda» category in one question (the month is left out of the series) | Exact | Warning | April and May 2020, Spain question | `validacion_cis` |
| `cis_vivienda_cobertura` | Barometers without open results in XLSX or HTML, or whose download failed | Exact | Warning | None: the six PDF-only months (July 2014 and February, April, May, June and July 2025) are transcribed | `validacion_cis` |
| `cis_vivienda_pdf` | Transcription of the PDF-only months (`inventario/cis_transcripcion_pdf.csv`): months with open results, studies of another month, missing questions, totals more than 0.2 points from the sum of the three problems or with fewer than 1,000 interviews, and links elsewhere | Exact | Blocking | None in the 12 rows | `validacion_cis` |
| `cis_vivienda_meses` | Months without a barometer between the first and the last, except August | Exact | Warning | Seven (§7.10) | `validacion_cis` |
| `cis_vivienda_web` | `datos/cis_vivienda.json` against the `cis_vivienda` table: periods, figures with one decimal, study and interviews | Exact | Blocking | No differences | `validacion_web_cis` |
| `calendario_fuentes` | `inventario/calendario_fuentes.csv`: sources in the inventory, vocabulary, months, days and periods (§9.3) | Exact | Blocking | None | `validacion_calendario` |
| `calendario_descargas` | Sources renewed from the calendar without any downloaded file | Exact | Warning | All have files | `validacion_calendario` |
| `ipc_variacion` | CPI (table 76144): published change in annual averages against the one recomputed from the indices, which INE gives with three decimals | ±0.06 points | Blocking | Maximum difference, 0.049 points | `validacion_ipc` |
| `ipc_serie` | Years without a general index from 2015 to 2024, those of the rent series | Exact | Blocking | None | `validacion_ipc` |
| `ipc_referencia` | Change in annual averages for 2022 published by INE | Exact | Blocking | 8.4% | `validacion_ipc` |
| `web_ipc` | `datos/ipc.json` against the `ipc` table: years and indices | Exact | Blocking | No difference | `validacion_web_ipc` |
| `ipc_deflactor_anios` | Base-year euros: years without an annual average between the first one in the table (2002) and the base year | Exact | Blocking | None | `validacion_ipc_deflactor` |
| `ipc_deflactor_base` | The website's base year is the last year with a published annual average | Exact | Blocking | 2025 | `validacion_ipc_deflactor` |
| `ipc_referencia_2008` | Change in annual averages for 2008 published by INE (base 2006), recomputed from the indices in base 2025 | Exact | Blocking | 4.1% | `validacion_ipc_deflactor` |
| `ipc_referencia_2009` | Same, 2009 | Exact | Blocking | −0.3% | `validacion_ipc_deflactor` |
| `web_ipc_control` | `datos/ipc_control.json` (appraised value and wage for Spain in base-year euros) against `ipc_deflactar()` | Exact | Blocking | No difference | `validacion_web_ipc_control` |

**Reading the results of `adrh_municipio`.** The median is 0.0% because most municipalities have a single tract. The warning `adrh_municipio_detalle` collects the cases in which the source does not match across scales with all tracts having data. In Madrid, for example, Alcobendas and Pozuelo de Alarcón stay above 5% every year (`inventario/referencias_validacion.csv`).

### 4.2 Pending checks

| `id` | What it compares | Tolerance | Type |
|---|---|---|---|
| `adrh_aeat` | ADRH income against AEAT gross income by municipality | Consistent trend | Warning |
| `serpavi_ipva` | SERPAVI trend against the IPVA | Consistent trend | Warning |
| `notariado_tasado` | Notaries' price against appraised value (indicators 11 and 12, F4) | Reasoned threshold | Warning |

The `registradores_*` checks, formerly in this list, have been in the pipeline since 11 Nov 2026 (§4.1). `adrh_aeat`, `serpavi_ipva` and `notariado_tasado` have no numeric tolerance yet. `validar_referencias()` does not accept text tolerances, so one has to be set before they enter the pipeline.

---

## 5. Income (indicators 1–3)

### 5.1 Source and reading

**Tables.** ADRH for all of Spain is downloaded from INEbase (`descargar_ine_adrh()`) in two tables:
- **30824:** mean and median income (`fichero_adrh_renta`);
- **30832:** demographic indicators (`fichero_adrh_demografia`).

They are CSV files separated by «;», with a decimal comma. The value «.» means an unpublished figure (statistical confidentiality) and those rows are dropped on reading (`leer_ine_adrh()`).

**Indicators** (`INDICADORES_ADRH_RENTA`, `leer_ine_adrh_renta()`):

| # | Code | Name in ADRH | Type |
|---|---|---|---|
| 1 | `renta_persona` | Average net income per person | Mean; weighted by population |
| 2 | `renta_hogar` | Average net income per household | Mean; weighted by households |
| 3 | `renta_uc_mediana` | Median income per consumption unit | Median (modified OECD scale); not aggregated |

**Weights** (`pesos_adrh()`):
- **Population:** the «Población» of the demographic table.
- **Households:** population ÷ mean household size. The source rounds mean household size to one decimal, so the number of households is approximate.

The national table rounds that size one tenth differently from the provincial tables in about 200 Madrid tracts per year. That is why, when moving from the Madrid table to the national one, 33 figures of income per household changed, by less than 0.3% (plan §6.3).

**Reading the figures** (`inventario/indicadores.csv`):
- Income is for year *t*, with population at 1 January *t* + 1.
- It does not include the imputed rent of owner-occupied housing.
- Income per household is income of several earners, not a wage.

### 5.2 Gate before reprojection

The gate applies to tract figures on their original tract map, before reprojection (`comprobar_adrh_municipio()`):
- `adrh_municipio` (blocking, §4.1): mean of the tracts weighted by population (indicator 1) or by households (indicator 2), against the published municipal figure.
- `adrh_municipio_detalle` (warning): the same, municipality by municipality.
- The median (indicator 3) has no aggregation gate, because it is not aggregated.

### 5.3 Reprojection to the 2021 tract map

It is done in `armonizar_ine_adrh()`, with the table of each year (`tablas_paso_adrh`: the nine combined ones and the 2020 identity).

**Means (indicators 1 and 2)** (`geo_reproyectar_media()`). For each 2021 tract *d*:

  value(*d*) = Σₒ value(*o*) · weight(*o*) · fraction(*o*, *d*) / Σₒ weight(*o*) · fraction(*o*, *d*)

where:
- the sum runs over the sources *o* with data;
- weight(*o*) is the population (indicator 1) or the households (indicator 2) of the source in the ADRH year;
- fraction(*o*, *d*) is that of the conversion table.

**Median (indicator 3)** (`geo_reproyectar_mediana()`):
- The value of the single source, or of the dominant source (≥ 95% of the weight *d* receives), is copied.
- If no source dominates, the figure is `ausente`.

**Final status of each figure.** The status of the table (§3.6) is combined with data coverage (`geo_cobertura_origenes()`):
- `secreto` (confidential) if none of the sources has a published value;
- `estimado` if the value of any of the sources received by the tract is missing, even if the table gives it as `dato`. For means, the value is then computed only with the sources that have data;
- `ausente` for medians without a dominant source;
- otherwise, the status of the table: `dato` or `estimado`.

**Municipal level.** The published municipal figure is taken, with status `dato`. It is not aggregated from the tracts: the source does not always match across scales (§4.1), and medians are not aggregated (rule 1 of the guide).

### 5.4 Result

2021 tracts by status, for each year (`tabla_larga`, rows with `fuente == "ine_adrh"` and `nivel == "sc"`):

| Year | Means (1 and 2): `dato` | Means: `estimado` | Means: `secreto` | Median (3): `dato` | Median: `estimado` | Median: `secreto` | Median: `ausente` |
|---|---|---|---|---|---|---|---|
| 2015 | 32,592 | 1,634 | 2,106 | 31,868 | 1,257 | 2,593 | 614 |
| 2016 | 33,002 | 1,456 | 1,874 | 32,323 | 1,127 | 2,361 | 521 |
| 2017 | 33,374 | 907 | 2,052 | 33,179 | 670 | 2,107 | 377 |
| 2018 | 33,886 | 391 | 2,056 | 33,751 | 297 | 2,148 | 137 |
| 2019 | 33,958 | 281 | 2,094 | 33,854 | 224 | 2,189 | 66 |
| 2020 | 35,826 | 0 | 507 | 34,349 | 0 | 1,984 | 0 |
| 2021 | 36,123 | 195 | 14 | 34,647 | 158 | 1,400 | 127 |
| 2022 | 35,645 | 613 | 74 | 34,070 | 478 | 1,391 | 393 |
| 2023 | 35,367 | 877 | 88 | 33,677 | 665 | 1,454 | 536 |
| 2024 | 35,043 | 1,194 | 95 | 33,184 | 886 | 1,509 | 753 |

The two mean indicators have the same counts by status.

**Why `secreto` is higher in 2015–2019.** In those years ADRH does not publish by tract between 1,327 and 1,629 codes that are in the street register, mostly in the Basque Country and Navarre (`fase_codigos`, column `callejero_sin_adrh`; plan §6.3).

**Rows in the long table.** 1,303,484 income rows (§9.1). Municipal level: 73,777 rows for each mean and 65,958 for the median. The `version` column carries the date of the source file: 7 Nov 2026.

### 5.5 Income distribution (indicators 4–6)

**Tables** (`descargar_ine_adrh()`, 9 Nov 2026). Three for all of Spain by tract, district and municipality, and three of totals:
- **30825:** distribution by income source, as a percentage of gross income (`fichero_adrh_fuentes`);
- **30829:** relative thresholds by sex (`fichero_adrh_umbrales`; 1.65 GB);
- **37677:** Gini index and P80/P20 (`fichero_adrh_gini`);
- **53687, 53694 and 53688:** Spain, regions, provinces and islands (`ficheros_adrh_totales`), with names and no codes. Regions are matched by their INE name and provinces by theirs within their region (`codigos_totales_adrh()`). Islands are left out.
- **53689:** average and median income for Spain, regions, provinces and islands (`fichero_adrh_renta_totales`, 416 KB), with the same format and the same matching; it gives the average net income per household at those levels for indicator 17 (§7.7; since 11 Nov 2026).

**Reading** (`leer_ine_adrh_distribucion()`, in chunks). It takes wages out of the five income sources, the population of both sexes below 40%, 50% and 60% of the median (40% and 50% only for the gate) and the Gini index. The CSV uses three marks: «.» is statistical confidentiality (`secreto`); «..», figure not available, and an empty cell, a year not published for that area (both `ausente`).

| # | Code | In ADRH | Reprojection |
|---|---|---|---|
| 4 | `peso_salarios` | Income source: wages (% of gross income) | Mean weighted by the tract's gross income (average gross income per person × population) |
| 5 | `bajo_60_mediana` | Population with income per consumption unit below 60% of the median | Population-weighted mean |
| 6 | `gini` | Gini index | Rule for medians and indices (§3.6) |

**Why indicators 4 and 5 are weighted** (author's decision, 9 Nov 2026). They are ratios of sums: wage income over gross income, and people below a threshold that is the same across Spain each year. Aggregated to municipality with those weights, they reproduce the published municipal figure (`adrh_dist_municipio`: median deviation of 0.006 points at most). INE computes them on the population it finds in tax records (over 98.6% of residents), while here the weight is the ADRH population: that gate measures the difference. The Gini index is not aggregated: it follows the rule for medians.

**Status.** As for income (§5.3), with one difference: a 2021 tract without a value is `secreto` if any of its sources is, and `ausente` if none is published (`reproyectar_adrh_distribucion()`). Municipalities, provinces, regions and Spain carry the published figure (rule 1 of the guide); for municipalities, published and confidential figures go in.

**Gate** (`comprobar_ine_adrh_distribucion()`, target `validacion_adrh_distribucion`; §4.1). It checks that each table covers the 52 provinces (the first download of table 30829 was cut off at Pontevedra without raising an error), that figures lie between 0 and 100, that the five income sources add up to 100, that thresholds are in order, that tract and municipality match in single-tract municipalities and that aggregated tracts reproduce municipalities and provinces.

**Foral territories** (break `adrh_forales_distribucion`). Bizkaia is in the whole series; Gipuzkoa, from 2016; Álava, from 2020, and Navarre, from 2021 (indicator 4 with about 80 tracts with data in 2017–2020 and the rest confidential). Spain, from 2021. Before that, `ausente`: Eustat and Nastat do not fill the gaps because they measure something else (author's decision, 9 Nov 2026; `eustat_nastat` in `inventario/fuentes.csv`).

**Breaks in indicator 5:**
- `adrh_umbral_mediana_2023`: the threshold is 60% of the median of the common tax territory up to the ADRH 2022 edition and of the median of all of Spain from the 2023 edition, according to INE's methodology, which does not say whether the current table recomputes earlier years.
- `adrh_umbrales_secreto_2024`: from the 2024 edition, confidentiality requires 50 men and 50 women per area instead of 500 residents. In the table only 2024 changes: confidential tracts fall from about 2,500–3,000 to 989. It changes how many figures are published, not the figures.

**Result** (2021 tracts; `larga_adrh_distribucion`):

| Indicator and year | `dato` | `estimado` | `secreto` | `ausente` |
|---|---|---|---|---|
| 4 (2015) | 32,085 | 1,608 | 1,274 | 1,365 |
| 4 (2020) | 34,410 | 0 | 1,841 | 82 |
| 4 (2024) | 33,699 | 1,195 | 1,435 | 3 |
| 5 (2015) | 29,306 | 1,591 | 4,070 | 1,365 |
| 5 (2020) | 31,563 | 0 | 4,194 | 576 |
| 5 (2024) | 33,437 | 1,194 | 1,700 | 1 |
| 6 (2015) | 31,666 | 1,246 | 1,487 | 1,933 |
| 6 (2020) | 34,349 | 0 | 1,408 | 576 |
| 6 (2024) | 33,206 | 887 | 1,485 | 754 |

In 2024 the median tract has 58.2% of gross income from wages, 19.2% of the population below 60% of the median and a Gini index of 27.9. Spain: 60.0%, 20.2% and 31.9.

**Rows in the long table.** 1,331,166: tract (1,089,972), municipality (239,034), province (1,560), region (570) and Spain (30). Version: 9 Nov 2026.

**Maps** (§9.2). Classes from the `cortes_web` column: for indicator 4, 50, 55, 60, 65 and 70%; for 5, 10, 15, 20, 25 and 30%; for 6, 25, 27, 29, 31 and 33. Since task 51, seven classes with one set of cut-offs per scale (§9.2) and one decimal.

### 5.6 Average wage per employee (indicator 7)

**Source and reading** (`descargar_aeat_salarios()`, `leer_aeat_salarios()`). AEAT, *Mercado de trabajo y pensiones en las fuentes tributarias*, table «Asalariados, percepciones salariales y salarios por provincia, edad y sexo», with both sexes and all age bands: one HTML page per band and year.
- Editions: from 2011 to 2025. Earlier ones are not on the AEAT website.
- The editions change layout: up to 2014, table headers without a prefix and indentation by margin (`aeat_sangria()`); up to 2017, filters in the subtitle. The age band is called «Edad», «Tramo de edad» or «Tramos de Edad», and Ourense, «Orense» until 2013.
- Average wage = wages / employees: pay received in the year by employees with tax residence in the area, including people who worked only a few months.

**Codes and levels** (`codificar_aeat_salarios()`; target `salarios_aeat`): the province, by its name in `inventario/provincias_aeat.csv`; the region, by its name in `geo/ccaa.csv`, with a key that does not depend on how each edition writes it (`clave_comunidad()`); Spain, «00». Single-province regions (Asturias, Balearic Islands, Cantabria, Madrid, Murcia and La Rioja), Ceuta and Melilla only have a region row, which is also that of their province.

**In the long table** (`armonizar_aeat_salarios()`; target `larga_salarios`): indicator `salario_medio`, source `aeat_mercado_trabajo`, with the published figure at each level (guide, rule 1). The total has no breakdown, and the 26 to 35 band has cut `edad` and group `Y26-35`. There are 2,160 rows: 15 years, 72 areas (52 provinces, 19 regions and Spain) and 2 bands.
- **Basque Country and Navarre.** AEAT does not cover them (foral tax residence): their 4 provinces and 2 regions are `ausente` every year (168 rows). Of the foral tax authorities, only Gipuzkoa publishes a comparable figure (form 190, average wage by age), in an annual PDF report; those of Bizkaia, Álava and Navarre publish none. Nastat's Municipal Wage Structure Statistics and INE's Annual Wage Structure Survey measure something else (another universe and another adjustment).
- **Spain** is the common-regime territory: without the Basque Country or Navarre.

**Gate** (`comprobar_aeat_salarios()`, `validacion_salarios`; §4.1): `aeat_provincia`, `aeat_salarios_cobertura`, `aeat_salarios_suma` and `aeat_salarios_media`, blocking. All 14 years pass. The provincial average moves at most €0.499 away from that published for its region or for Spain: the rounding to the euro.

**Result** (Spain, common regime):

| Year | Employees | Average wage (€) | Aged 26 to 35: employees | Aged 26 to 35: average wage (€) |
|---|---|---|---|---|
| 2011 | 17,788,121 | 19,102 | 4,996,038 | 15,842 |
| 2015 | 17,349,558 | 18,645 | 4,129,678 | 14,422 |
| 2019 | 19,157,767 | 20,566 | 4,006,014 | 16,594 |
| 2024 | 20,637,992 | 24,962 | 4,090,037 | 21,506 |
| 2025 | 21,139,690 | 25,830 | 4,182,983 | 22,468 |

In 2025, by province, from €18,595 (Jaén) to €32,924 (Madrid) overall, and from €16,167 (Huelva) to €26,974 (Madrid) at ages 26 to 35.

---

## 6. Token incomes

### 6.1 Common rule and tokens

**Common rule:** net monthly income spread over 12 (guide, rule 8; plan §3.1). Rent is paid twelve times a year; with the monthly pay of a wage paid in 14 instalments, the burden would come out inflated by about 17% (14 / 12 = 1.167).

**Dwelling.** Single-person tokens look for 50 m², so that their maps differ only by income. Token rent is that of apartments (plan §11, question 12).

| Token | Reference income | Source | Scale | Dwelling | Status |
|---|---|---|---|---|---|
| Neighbourhood household (llave) | Average net income per household ÷ 12 | INE, ADRH (indicator 2) | Tract | Median rent of its tract, no fixed floor area | Income computed (`perfiles`); burden (indicator 14), in `larga_derivados` (§7.4) |
| Young adult (mochila; aged 26 to 35) | Estimated median of pay received in the year, net, ÷ 12 | AEAT; check with the ECV | Province | 50 m² | Computed from 2015 to 2025 (`mochila_neta`, `perfiles`), as `estimado` |
| Minimum wage (tartera) | Net annual minimum wage (SMI) ÷ 12 | Royal decree of each year (RD 1106/2014 to RD 126/2026) | National | 50 m² | Computed from 2015 to 2026 (`perfiles`) |
| Pensioner (transistor) | Average retirement pension, net of income tax, ÷ 12 | INSS; AEAT withholding | Province | 50 m² | Computed from 2015 to 2025 (`transistor`, `perfiles`); Basque Country and Navarre, as `estimado` |
| Your token | Net monthly pay entered by the user: 12 or 14 instalments, optional second wage | — | — | 50 m² with one wage, 70 m² with two; can be changed to 50, 70 or 90 | Computed in the browser and not stored (`js/sueldo.js`) |

**Statistic of each token** (backlog task 44). The website states it in one line in the «Can you make rent?» profile, in the «Your pay» card and on the front page:
- neighbourhood household: household mean (average net income per household in the tract);
- young adult: individual median (pay at ages 26 to 35, estimated);
- minimum wage: individual legal minimum (statutory minimum wage);
- pensioner: individual mean (average retirement pension), with a note: Social Security does not publish the median pension by province (§6.5);
- your token: own figure, for one person or for two with the second pay.

**Money left** (backlog task 34). In «Can you make rent?», next to the rent share of income (15), the profile shows the euros left each month: the token's net monthly income minus the monthly rent of the same dwelling and year, the two terms of the percentage, each rounded to the euro before subtracting (`web/js/sueldo.js`). If rent exceeds income, the difference is shown as the amount short. The euros left are a subtraction, not a sufficiency threshold: they do not say whether that remainder covers a household's other expenses.

### 6.2 Young adult token: method B, gross-to-net step and series

The choice of method is the author's, of 7 Nov 2026 (plan §3.1; open question 7, closed). The series runs from 2015 to 2025 (10 Nov 2026; 2025, since 12 Nov 2026): each year, with AEAT data for that year and the ECV wave of the following year, which carries its income. The latest year has no ECV check until INE publishes that wave (the 2026 one, in February 2027; `ANIOS_MOCHILA_ECV`).

**1. Starting wage.** Average gross annual wage at ages 26 to 35 by province: indicator 7 (§5.6; target `salarios_aeat`).
- It is actual pay over the year: it includes people who worked only a few months.
- AEAT tables are HTML pages, one per combination of filters (`descargar_aeat_mercado()`, `leer_aeat_mercado()`).

**2. From mean to median.** It is multiplied by the median-to-mean ratio of the estimated average salary (SME, «full-year» module) at ages 26 to 35 in its region and year (`leer_modulo_sme()`, `formas_sme()`; targets `modulos_sme` and `formas_mochila`).
- AEAT does not publish that median. It is interpolated from two tables (`cuantil_tramos()`):
  - the counts of employees of each region and age in each national decile;
  - the limits of the national centiles.
- Assumption of the interpolation: within each national decile, the region is distributed like the country. Check against the counts by centile that AEAT gives by region, for all ages: between −0.19 and +0.45% from 2019 to 2025 (`aeat_mediana_deciles`).
- Assumption of the method: the median-to-mean ratio is the same in all provinces of a region.
- **Before 2019.** The full-year module starts with the 2019 edition: from 2015 to 2018 the 2019 ratio is used (column `anio_forma`). From 2020 to 2025, that of each region moves between −2.7% (Balearic Islands, 2021) and +1.8% (Extremadura, 2025) away from the 2019 one (`mochila_forma`); that of Spain is 0.844 in 2019 and in 2024, and 0.848 in 2025. Those four years are an estimate with another year's ratio: the column `metodo_forma` says so (`primer_anio`) and the token is `estimado`, like the whole Young adult token (plan §11, question 44 f as revised).
- **Check with the ECV from 2015 to 2018** (`ecv_mochila_correccion()`; targets `correccion_mochila` and `validacion_mochila_relacion`). Median-to-mean ratio of the gross pay of those who worked the twelve months, aged 26 to 35, in Spain: 0.930 in 2015, 0.904 in 2016, 0.879 in 2017, 0.892 in 2018 and 0.909 in 2019; from 0.857 to 0.899 from 2020 to 2024. It moves more than 2 points away from the 2019 one in 2015 (+2.1) and 2017 (−3.1): it warns (`mochila_relacion_ecv`). The planned correction, the 2019 ratio scaled by the change the ECV measures, is first validated in 2020–2024 and fails: it moves further from the module ratio of each region and year (mean error of 4.0 points) than the unscaled 2019 one (0.6), because the ECV ratio falls by 5.7% from 2019 to 2024 while the module's does not move. It is not corrected (`mochila_relacion_correccion`, warning); if a year validated, `ecv_mochila_aplicar()` would scale those years (`primer_anio_ecv`).
- Formula: gross annual = actual provincial average wage × median-to-mean ratio of the SME of its region (`calcular_mochila_serie()`, `mochila`).

**3. From gross to net** (`calcular_mochila_neta()`): net annual = gross × (1 − contribution − withholding); net monthly = net annual ÷ 12.
- **Employee contribution of the year** (`cotizacion_trabajador()`, that of the Minimum wage token in `SMI_FICHAS`): 6.35% until 2022, with common contingencies (4.70), unemployment (1.55) and vocational training (0.10); with the intergenerational equity mechanism (MEI), 6.45% in 2023, 6.47% in 2024 and 6.48% in 2025. With a temporary contract, 0.05 points more.
- **Withholding:** AEAT average rate for people who only earn wages, by region, annual income bracket and year (*Grupos de población por la naturaleza de sus retribuciones*; `retenciones_aeat()`, target `retenciones_mochila`). It comes from the same pages as that of the Pensioner token (§6.5).
  - It is interpolated linearly between the average wages of the brackets; outside them, the rate of the end bracket is taken (`tipo_retencion()`).
  - In Spain in 2024: between 1.6 and 1.8% below €12,000; 2.6% from €12,000 to €18,000; 9.0% from €18,000 to €24,000; 13.6% from €24,000 to €30,000.
  - It is the payroll withholding, not the final income tax liability.

**4. Pay received in the year.** The token uses pay received in the year, not that of someone working twelve months: AEAT does not publish that wage, because its «full year» annualises by days of contribution. In the ECV, between 68.0% (2015 income) and 77.6% (2021) of employees aged 26 to 35 with a wage worked all twelve months; with 2024 income, 73.9% (`ecv_mochila`, Spain).

**5. Check with the ECV of each year** (waves 2016 to 2025). Person microdata: gross wage (PY010G), net wage (PY010N), weight (PB040) and age at the end of the income year (`leer_ecv_asalariados()`, `resumir_ecv_asalariados()`).
- `mochila_ecv`: the Young adult token of each common-regime region and of Spain (`mochila_espana()`) against the ECV median gross pay. In 2024, the 15 regions lie between −10.6% (La Rioja) and +7.2% (Castilla y León) of the median; Spain, between −5.9% (2015) and +7.2% (2020) over the series. Since 11-Nov-2026, the tolerance comes from the sample size (plan §11, question 44 g), not from a fixed ±15%: the warning measures how far the token falls outside the 95% interval of the ECV median, with the effective sample size of the weights (Kish) and Woodruff's method (`resumir_ecv_asalariados()`). The interval goes from ±2.7% (Spain) to ±57% (regions with about 50 observations). It warns on 20 of the 160 figures (with the fixed ±15%, on 32), up to 19.5% outside the interval (Valencian Community, 2016, 151 observations). Spain falls outside its own in 2019, 2020, 2022 and 2023, by at most 1.9%: with 2,733 to 4,826 observations the interval is narrow, and what is left is an underlying difference between the AEAT and the ECV.
- `mochila_neto_ecv`: the gross-to-net step applied to the ECV median gross pay against the median net pay. In 2024, between −2.0% (Canary Islands) and +3.4% (Galicia); Spain, +0.5%. Over the series, Spain lies between −1.2 and +2.5%, and the warning goes off on 8 of the 170 regional figures.

**Result** (`mochila_neta`; `datos/intermedios/mochila/mochila_neta.csv`):
- **Coverage:** 46 common-regime provinces each year. The Basque Country and Navarre are not in the AEAT tables (separate foral systems); Ceuta and Melilla are not in the full-year module.
- **Series** (mean of the provinces weighted by employees; the minimum is always Huelva and the maximum, Barcelona):

| Year | Gross annual (€) | Net monthly (€) | Minimum (€) | Maximum (€) |
|---|---|---|---|---|
| 2015 | 12,313 | 920 | 633 | 1,100 |
| 2016 | 12,468 | 930 | 638 | 1,115 |
| 2017 | 12,793 | 952 | 666 | 1,148 |
| 2018 | 13,435 | 999 | 710 | 1,210 |
| 2019 | 14,170 | 1,055 | 762 | 1,270 |
| 2020 | 13,926 | 1,036 | 759 | 1,250 |
| 2021 | 15,079 | 1,112 | 817 | 1,331 |
| 2022 | 16,242 | 1,186 | 866 | 1,397 |
| 2023 | 17,401 | 1,267 | 922 | 1,473 |
| 2024 | 18,334 | 1,330 | 990 | 1,529 |
| 2025 | 19,212 | 1,381 | 1,044 | 1,572 |

- The 2024 figure is the same as before the series (differences below a thousandth of a euro). The net-to-gross ratio falls from 0.90 (2015) to 0.87 (2024 and 2025): average withholding rises from 3.7% (2015) to 6.0% (2024) and 6.8% (2025).

**Discarded options.** Options A and C are still computed for the record, in `mochila` (columns `A` and `C`; `datos/intermedios/mochila/mochila.csv`):
- In 2024, option A comes out between 1.24 and 1.49 times B (median, 1.34). Weighted mean: €24,257 against €18,334.
- Against the 2025 ECV, A lies 14% above the median of those working all twelve months. B lies 1.7% below the median of all employees, as a weighted mean of the regions (plan §3.1).

### 6.3 Minimum wage token

**Computation** (plan §3.1; `perfiles_fichas()`, `SMI_FICHAS`; target `perfiles`). Net monthly income = monthly minimum wage × 14 instalments × (1 − employee contribution) / 12, with no income tax withholding. The amount is that of the royal decree of each year (source `boe_smi`), and the contribution, the employee's of that year with a permanent contract: common contingencies (4.70%), unemployment (1.55%) and vocational training (0.10%), plus the MEI from 2023 (0.10% in 2023, 0.12% in 2024, 0.13% in 2025 and 0.15% in 2026). The contribution order of each year is cited in `SMI_FICHAS` without downloading it (author's decision, 9 Nov 2026).

| Year | Rule | Monthly minimum wage (€, 14 instalments) | Contribution (%) | Net monthly income over 12 (€) |
|---|---|---|---|---|
| 2015 | RD 1106/2014 | 648.60 | 6.35 | 708.65 |
| 2016 | RD 1171/2015 | 655.20 | 6.35 | 715.86 |
| 2017 | RD 742/2016 | 707.70 | 6.35 | 773.22 |
| 2018 | RD 1077/2017 | 735.90 | 6.35 | 804.03 |
| 2019 | RD 1462/2018 | 900 | 6.35 | 983.32 |
| 2020 | RD 231/2020 | 950 | 6.35 | 1,037.95 |
| 2021 | RD 231/2020 and RD 817/2021 | 955 | 6.35 | 1,043.42 |
| 2022 | RD 152/2022 | 1,000 | 6.35 | 1,092.58 |
| 2023 | RD 99/2023 | 1,080 | 6.45 | 1,178.73 |
| 2024 | RD 145/2024 | 1,134 | 6.47 | 1,237.40 |
| 2025 | RD 87/2025 | 1,184 | 6.48 | 1,291.82 |
| 2026 | RD 126/2026 | 1,221 | 6.50 | 1,331.91 |

- **2021.** It had two amounts: €950 from January to August (the 2020 one, extended) and €965 from 1 September (RD 817/2021). Their mean weighted by months in force, €955, is used, consistent with the annual incomes of ADRH and AEAT (plan §11, question 18).
- **Gate.** The 2015 to 2023 amounts are read from the BOE XML of each royal decree (`descargar_boe_smi()`, `leer_boe_smi()`, `comprobar_smi_boe()`; `smi_boe`, target `validacion_smi`); those of 2024 to 2026 are cited. `smi_neto` compares the 2026 one with the plan's €1,332 (§4.1).
- **Use.** The rent share of income in the long table (§7.4) and the website use the minimum wage of the same year as the rent (rule 4; author's decision, 9 Nov 2026): with 2024 rent, €1,237.40. Those of 2025 and 2026 have no rent of the same year; the website cites the latest next to that of the chosen year.

**Comparison with the Young adult token.**
- The 2024 Young adult token (€1,330 net on average) comes out almost equal to the Minimum wage token with the 2026 minimum wage. They are different years (rule 4).
- With the 2024 minimum wage (€1,237 net), the Young adult token lies 7.5% above (plan §3.1).
- The income tax exemption of the minimum wage applies to those who earn it all year. The AEAT table gives withholding of 1.6–1.8% also below €12,000.

### 6.4 Neighbourhood household token

**Income** (`perfiles`): ADRH average net income per household of each tract (indicator 2, §5) ÷ 12, with the status of its reprojection. In 2024, in the 36,237 tracts with a value: 10th percentile, €2,319; median, €3,021; 90th percentile, €4,501 a month (`resumen_perfiles_llave`).

**Dwelling:** the median apartment rent of the tract itself, no fixed floor area. It is the only token that varies on both sides, income and rent.

**Burden:** the cross with SERPAVI is indicator 14 (§7.4), «median rent over the area's average household income»: the neighbourhood household token in «Can you make rent?» is that same ratio and carries its reading note (task 41).

### 6.5 Pensioner token

**Statistic.** It is the mean, not the median: Social Security does not publish the median retirement pension by province (checked on 10 Nov 2026: the monthly Excel files by province give number, amount and average pension by scheme and class; the amount bands of the yearbook are national). The website says so in the token's line (task 44).

**Question.** It answers “if I had to rent today”: 89.1% of people aged over 65 live in a home they own (ECV 2023; plan §3.1), and the website says so next to the token.

**Method** (plan §3.1; author's decision of 9 Nov 2026):
1. **Starting pension.** Average retirement pension of the whole system by province (INSS, *Pensiones contributivas del Sistema de la Seguridad Social*; monthly Excel «Pensiones por CCAA y provincias»; `descargar_inss_pensiones()`, `leer_inss_pensiones()`). It excludes Clases Pasivas (civil service pensions). It is the average of one ordinary instalment; the province is that of the provincial office that manages the pension, not of residence, and pensions are counted, not pensioners.
2. **Average of the year.** Mean of the twelve monthly figures (pensions in payment on the 1st of each month), weighted by the number of pensions (`armonizar_inss_pensiones()`, `anual_inss_pensiones()`; targets `inss_mensual` and `inss_anual`). Unit names are turned into codes with a fixed table (`inventario/provincias_inss.csv`). The Excel changes shape over the years (sheet name, one sheet per scheme and, from 2024, the amount): the whole-system sheet and the retirement column are found by their text.
3. **From gross to net** (`calcular_transistor()`): gross a year = average × 14 instalments; net a month = gross a year × (1 − withholding) / 12. Pensions pay no contributions.
   - **Withholding:** AEAT average rate of people who only receive pensions (*Grupos de población por la naturaleza de sus retribuciones*, pensions block, «Pensionistas» column), by region and annual income band, of the same year, interpolated as for the Young adult token (`retenciones_pensiones()`, `tipo_retencion()`; target `retenciones_transistor`). In 2024, from 0.4% (Ourense) to 10.8% (Bizkaia); in 2025, from 1.3 to 11.6%.
   - AEAT does not separate retirement from other pensions (survivors', disability, partly exempt, and Clases Pasivas): the curve is that of all pensioners with that income. It is the withholding applied, not the final income tax.
   - **Basque Country and Navarre:** their income tax is foral and AEAT does not cover them; the Spain curve is used and the income is marked `estimado` (author's decision). Ceuta and Melilla have their own curve, with lower withholding because of their tax rebate.
4. **Gate** (§4.1; targets `validacion_inss` and `validacion_transistor`): each month, the provinces reproduce the number and the average pension published for their region and for Spain in the same Excel (`inss_suma`, `inss_media`), with no unit missing or repeated (`inss_cobertura`); the net income covers the 52 provinces every year, with withholding between 0 and 30% (`transistor_cobertura`, `transistor_retencion`).

**Result** (`transistor`; `datos/intermedios/transistor/transistor.csv`), in euros:

| Year | Average retirement pension in Spain (per instalment) | Net monthly income over 12: minimum (Ourense) | Maximum (Bizkaia) | Mean of the provinces weighted by pensions |
|---|---|---|---|---|
| 2015 | 1,021.19 | 825 | 1,411 | 1,151 |
| 2016 | 1,042.65 | 839 | 1,436 | 1,173 |
| 2017 | 1,063.50 | 855 | 1,457 | 1,192 |
| 2018 | 1,090.70 | 878 | 1,490 | 1,225 |
| 2019 | 1,137.81 | 923 | 1,542 | 1,281 |
| 2020 | 1,161.80 | 945 | 1,563 | 1,303 |
| 2021 | 1,189.65 | 972 | 1,588 | 1,328 |
| 2022 | 1,254.14 | 1,030 | 1,657 | 1,385 |
| 2023 | 1,374.58 | 1,136 | 1,796 | 1,503 |
| 2024 | 1,442.67 | 1,198 | 1,869 | 1,574 |
| 2025 | 1,506.06 | 1,245 | 1,926 | 1,631 |

- In 2024, the Pensioner token (€1,574 on average) lies above the Young adult token (€1,330) and the Minimum wage token (€1,237) of the same year.
- Sources, downloaded with the author's permission (9 Nov 2026): the 120 INSS Excel files from 2015 to 2024 (≈ 9.6 MB) and AEAT withholding from 2015 to 2023 (1,458 pages, ≈ 39 MB; 2024 was already there). On 12 Nov 2026, also with his permission, the 12 Excel files of 2025 (2.4 MB) and the 2025 AEAT edition (308 pages, 11 MB). AEAT editions up to 2017 have another layout and other region names («Región de Murcia»): `aeat_titulo()` and `aeat_menus()` read both.

### 6.6 Wage percentile of the required pay

The required pay (21) is also expressed as a percentile of the wage distribution, to compare over time without depending on each year's prices (plan §7, F3; 10 Nov 2026). It is a proposal pending review.

**Distribution** (`leer_aeat_tramos()`, `curvas_salariales()`; targets `tramos_salariales` and `curvas_salariales_aeat`): pay received in the year by employees of each region and of Spain, the same measure as indicator 7 and the Young adult token (§5.6 and §6.2), from 2015 to 2025.
- Source: AEAT, table «Asalariados, percepciones salariales y salarios por Comunidad Autónoma, tramos de salario y sexo», with both sexes: employees and wages in 13 annual wage bands, in multiples of the annual minimum wage of the year (14 payments). In 2020 and 2021 the table adds the furlough (ERTE) status (its total is taken) and does not include Ceuta or Melilla.
- Within each band, a linear density with the band mean; the last, open band is closed with its mean (uniform between 10 SMI and 2 × mean − 10 SMI). From that come percentiles 1 to 99 of gross annual pay (`cuantil_tramos_salario()`).
- To monthly net pay over 12 with the employee contribution and the AEAT withholding of its region and year, as for the Young adult token (§6.2). It is an increasing function of gross pay, so the order does not change.
- The Basque Country and Navarre are not in the statistics: they use the Spain curve. So do Ceuta and Melilla in 2020 and 2021.
- It includes people who worked only a few months: the percentile says what share of employees received less than that pay in the year, net and spread over 12 months.

**On the website** (`salarios_web()`; `datos/salarios.json`): on the required pay map, the tract profile (and that of municipalities, provinces and regions) gives the percentile of the pay it shows (the main figure, with actual monthly rent; task 40), with the chosen threshold, on the curve of its region and of the rent year (`web/js/percentil.js`): «Percentile 84 of wages (Comunidad de Madrid, 2024; …)». Below the 1st percentile or above the 99th, it says so.

**Gate** (`comprobar_curvas_salariales()`, `validacion_percentil`; `comprobar_salarios_web()`, `validacion_web_salarios`; §4.1): `percentil_cobertura`, `percentil_monotono`, `percentil_suma`, `percentil_limites` and `web_salarios` (blocking) and `percentil_media` (warning). The mean of the modelled distribution moves at most 0.12% away from the published one (2017); the bands are off from the total by one employee in 5 of the 11 years.

**Result** (Spain, monthly net pay over 12, in euros, and percentile of some amounts):

| Year | Percentile 10 | Median | Percentile 90 | €700 | €1,100 | €1,500 | €2,000 |
|---|---|---|---|---|---|---|---|
| 2015 | 118 | 1,071 | 2,408 | 34.5 | 51.4 | 69.2 | 82.6 |
| 2019 | 179 | 1,202 | 2,541 | 28.1 | 44.7 | 65.6 | 80.0 |
| 2024 | 249 | 1,422 | 2,879 | 21.5 | 33.4 | 54.2 | 73.2 |
| 2025 | 259 | 1,460 | 2,943 | 20.8 | 32.1 | 52.1 | 71.7 |

- Percentile 10 is low because it counts people who worked only a few months.
- With actual monthly rent, the median tract of Spain required €1,333 in 2015 (percentile 62.6 of wages in Spain) and €1,900 in 2024 (percentile 70.5); with the 50 m² minimum, €867 (40.7) and €1,217 (38.1).
- Tract 2807901001 (Madrid) required, with actual monthly rent, €2,667 in 2015 (percentile 87.2 of wages in Comunidad de Madrid) and €4,256 in 2024 (percentile 93.9), and with the 50 m² minimum, €2,000 (73.9) and €2,967 (84.1); tract 0801901001 (Barcelona), €2,000 (percentile 79.1 of those of Catalonia) and €2,790 (85.9), and €1,783 (73.2) and €2,400 (78.1).
- **Discarded alternative** (10 Nov 2026): the estimated average salary (SME) of the full-year module (§6.2), which annualises by days of contribution and leaves out those below the minimum wage. It only exists from 2019 to 2025, and its 1st percentile sits at the minimum wage: the median tract fell below percentile 3 every year.

### 6.7 Assumptions module

The calculation's assumptions live in one place, `inventario/supuestos.csv` (backlog, task 48; plan §7, F3), with their default value, their options, their unit, where they are used and where they were decided. R reads it (`leer_supuestos()`, `supuesto()`; the constants of the derived indicators come from it), and so does the website, through `web/js/supuestos.js`, which `generar_supuestos_js()` generates (target `fichero_supuestos_js`) and is not edited by hand.

| Assumption | Default | Options | Where |
|---|---|---|---|
| Floor area for one person | 50 m² | 50, 70 or 90 m² in «Your token» | Minimum wage, young adult and pensioner tokens; «Your token» with one wage; theoretical minimum of the required pay (21); rent share of income (15) |
| Floor area for two wages | 70 m² | 50, 70 or 90 m² | «Your token» with a second wage and the two-wage line of the panel |
| Threshold | 30% | 30 or 40% | Required pay (21), both figures |
| «Can you make rent?» bands | 30 and 40% | Fixed | Rent share of income (15) and barrier to moving in |
| Instalments | 12 | 12 or 14 | «Your token»: the instalment × instalments / 12 (§6.1) |
| Second wage | None | Optional | «Your token»: added to the first with the same instalments; the default floor area becomes the two-wage one |
| Standard dwelling for home purchase | 80 m², 80% financed over 25 years | Fixed | Indicators 16 and 17 (§7.7) |
| Other housing costs | Off | “Add other housing costs” | “Can you make rent?” and pay needed (21): added to rent (below) |

**Typical floor area** (backlog, decision 5; `superficie_tipica_serpavi()`, target `superficie_tipica`): SERPAVI median monthly rent / median rent per m², multi-family housing, with both terms as published, by territory and year, from the tract to the region. It is the ratio of two medians, not the median of floor areas, and it is in contract m². It comes from data already in the pipeline: neither the F1 Cadastre (the pipeline only keeps each building's dwellings and year) nor the 2021 Census tract indicators carry dwelling floor area. In 2024, a median of 82.1 m² across the 2,555 municipalities with both terms, from 45.8 to 153 m²; 62 m² in Madrid, 66 in Barcelona and 83 in València. With that of its own territory, the theoretical minimum of the required pay is the main figure (actual monthly rent / threshold), up to rounding. On the website (the author's decision, 11 Nov 2026; plan §11, question 59), «Your token» offers it as an option, «typical», alongside 50, 70 and 90 m², keeping 50 m² as default: that of the governing territory, which is the municipality of the tract in the panel, the territory chosen or, with no panel, the municipality at the centre of the view (a tract takes its municipality's, not its own). The municipal panel gives it in one line. The page computes it (`superficieTipica` in `web/js/sueldo.js`) from the two terms it already exports.

**Other housing costs** (author's decision, 12 Nov 2026; `calcular_otros_gastos_ecv()`, target `otros_gastos`; assumptions `otros_gastos_vivienda` and `otros_gastos_minimo_hogares`). The threshold is a convention that counts rent only; Law 12/2023 and Eurostat also count utilities and use household income. «Your pay» offers to add to each territory's rent what renting households pay on top each month, as in Eurostat's definition of housing costs (switch off by default, `gastos=1` in the address). It comes from the ECV microdata: HH070 (housing costs: rent, mortgage interest and other associated costs such as building fees, water, electricity or gas) minus HH060 (current rent), in euros a month, for households renting at market price (HH021 = 3) with both amounts; median weighted by the household weight (DB090), from 2016 to 2025. No household reports a total cost below its rent. A region's figure is not the median of its sample in each wave: with 50 to 150 households, it jumps by up to 46.8 € from one wave to the next (La Rioja, from 2023 to 2024), almost as much as the distance between regions. It is Spain's median for the wave times the region's factor (author's decision, 12 Nov 2026; `otros_gastos_factores()`): the weighted median, with the ten waves pooled and all weighing the same, of what each household pays relative to Spain's median for its wave. Spain sets each year's level and the 25,337 observations of the ten waves set the difference between regions (a household interviewed in several waves counts once per wave). In the 2024 ECV, 145.3 € a month in Spain (mean, 154.1 €); the factors run from 0.783 in the Canary Islands to 1.110 in La Rioja and the 2024 figures from 113.8 to 161.3 €; 149.1 € in Madrid and 148.8 € in Aragon. The largest jump between two waves is now 21.1 € (La Rioja, from 2021 to 2022, when Spain's median rises from 134.6 to 153.6 €). A region with fewer than 50 observations across all waves would take Spain's figure (factor 1), and the website would say so: there is none (the smallest samples are Ceuta's, 261, and Melilla's, 341). Eurostat does not impute a figure like this: in its overburden rate each household enters with its own cost and income; here there are no households by tract. Degree of urbanisation (DB100) is not crossed: by region, most of its cells fall short of 50 households and the website does not have each tract's degree. Year: that of the survey, because the costs are those at the time of the interview (ECV incomes are from the previous year); the website takes the wave of the rent's year and, for 2015, that of 2016, and says so. They are added to rent in the map, the legend, the profile, the summary, the CSV (column `otros_gastos`) and the PNG, and the text says how much; in the comparison, each column adds its own region's and the row gives both figures. Neither the INE nor Eurostat publishes this figure: internal gates `otros_gastos_*` (warning; `comprobar_otros_gastos()`, target `validacion_otros_gastos`) and the round trip of `datos/otros_gastos.json` (`web_otros_gastos`, block); the cases in `pruebas/datos/otros_gastos_inventado.json` are checked by `test-otros-gastos.R` and `pruebas/web/otros_gastos.test.mjs`. Median, households, minimum, regional factor and year: author's decisions of 12 Nov 2026 (§8).

**Gate on a sample** (`comprobar_supuestos()`, `validacion_supuestos`; §4.1): fourteen territories in 2024 (eight municipalities, four tracts, the province and the region of Madrid) × the 40 combinations of «Your token» (default floor area, 50, 70, 90 m² or typical, the municipality's in tracts; 30 or 40% threshold; 12 or 14 instalments; with or without a second wage) and the three one-person tokens. With the default assumptions, the page's calculations reproduce the required pay (21, both figures) and the rent share of income (15) of the long table (`supuestos_muestra_21`, `supuestos_muestra_15`). The R constants (`supuestos_r`), `web/js/supuestos.js` and the buttons of `web/mapa.html`, with the «typical» option (`supuestos_web`), are those of the CSV (`supuestos_inventario`). The sample cases are in `pruebas/datos/supuestos_muestra.json` (`escribir_muestra_supuestos()`; `supuestos_muestra_fichero` warns if they drift from the pipeline), checked by `test-supuestos.R` and `pruebas/web/supuestos.test.mjs`: R and the page agree on every combination. The typical floor area, with `supuestos_superficie_tipica`, `supuestos_superficie_tipica_mediana` and `supuestos_superficie_tipica_rango`.

---

## 7. Rent, renting households, tourist dwellings, derived indicators and overburden

### 7.1 Rent (indicators 8 and 9)

**Source.** The SERPAVI database of the MIVAU (`mivau_serpavi`), 2011–2024 edition. It is an Excel file with one sheet per level: regions (with the total for Spain), provinces, municipalities, districts and tracts. The whole series is on the 2021 tract map (plan §6.3). The file is downloaded by hand (§2.1); the `version` column carries its date, 6 Nov 2026.

**What it measures.** Current main-residence tenancies declared in personal income tax and matched with the Cadastre. It is the rented stock, not new contracts (guide, rule 5).

**Universe** (backlog, task 42). It is set by the Housing Ministry's official methodology of 18 March 2026 («Sistema Estatal de Referencia del Precio del Alquiler de Vivienda. Explotación estadística de fuentes tributarias. Metodología»), to which the Resolution of 16 April 2026 of the Secretary of State for Housing and Urban Agenda refers (BOE-A-2026-8691, BOE of 20 April 2026). The PDF is kept in `datos/brutos/mivau_serpavi/` (`inventario/fuentes.csv`), and the pages cited were checked by hand on 10-Nov-2026. SERPAVI counts properties with rental income from owners who are natural persons, declared in personal income tax form 100 (109 in Gipuzkoa) as the tenant's main residence, not tied to an economic activity and with no kinship between the parties (pp. 6, 8 and 17). Its only sources are personal income tax and the Cadastre (p. 16). Rent is the declared gross income, annualised, per m² of dwelling without common areas (p. 9): a contract of a few months is scaled up to a year. Left out:
- companies and other legal persons, including public bodies and their public housing (p. 6);
- undeclared lettings;
- lettings to relatives (pp. 6 and 17);
- lettings the landlord declares as an economic activity (pp. 8 and 17);
- properties in the common tax territory whose owners all reside in a foral territory or abroad, and those of common-territory taxpayers located outside it (p. 6);
- erroneous or highly atypical records (p. 6) and properties whose built area is three times that of their plot (p. 17).

The document does not deal with rooms, seasonal lettings or subsidised housing, nor does it set a minimum number of days let.

**How much is left out** (`serpavi_contraste_censo()`; target `contraste_serpavi_censo`). There is no open table of the rented stock by type of landlord and municipality: the 2021 Census does not identify the landlord, and the Cadastre's ownership statistics count the whole residential stock, not the rented one. Two figures bound the bias:
- in Spain, Banco de España estimates that private legal persons own 8% of the main dwellings rented at market prices, and puts social rental at about 300,000 dwellings, 1.5% of main dwellings (Annual Report 2023, chap. 4, p. 240); it gives no figures by municipality;
- in the same tracts and the same year, SERPAVI counts 2,186,305 rented dwellings (apartments and single-family) and the Census, 2,817,666 renting households: 77.6%, in the 32,084 tracts with both figures, without the Basque Country.

| Province | SERPAVI dwellings (2021) | Renting households (2021 Census) | SERPAVI / Census (%) |
|---|---|---|---|
| Melilla | 2,861 | 7,947 | 36.0 |
| Huelva | 9,229 | 24,428 | 37.8 |
| Almería | 21,215 | 41,534 | 51.1 |
| Santa Cruz de Tenerife | 50,265 | 87,604 | 57.4 |
| Ceuta | 2,427 | 4,217 | 57.6 |
| Barcelona | 368,857 | 521,222 | 70.8 |
| Madrid | 450,819 | 525,456 | 85.8 |
| Castellón | 29,550 | 29,048 | 101.7 |
| A Coruña | 64,718 | 62,788 | 103.1 |
| Pontevedra | 43,632 | 41,856 | 104.2 |
| Teruel | 5,451 | 5,010 | 108.8 |
| Salamanca | 17,546 | 14,754 | 118.9 |

The gap does not isolate legal persons: it adds up everything SERPAVI leaves out and differences in the Census in both directions. The Census counts households on 1 January, with tenure imputed for slightly under a quarter of them (INE, Census methodology, p. 86). SERPAVI counts properties let at some point in the year, including those of students registered elsewhere, whom the Census does not count as households of the tract: that is why it goes over 100% in university provinces such as Salamanca. By municipality, in the 1,739 with all their tracts and at least 100 renting households, the median is 73.3% (percentile 10, 25.9%; percentile 90, 117.3%); 441 fall below 50% and 328 exceed 100%. With that mix, the website does not flag municipalities: the indicator profile (`inventario/indicadores.csv`, column `lectura`) and this note say whom the source does not measure, and the split by type of landlord is pending review (§8).

**Reading** (`leer_mivau_serpavi()`; target `serpavi`, 1,099,500 rows). One row per unit, year (since 2015) and building type: apartments (`VC`) and single-family or rural houses (`VU`). Each row carries the count of observations (testigos) and the median, first and third quartile of monthly rent and of rent per m². Spain comes from the row without a code in the regions sheet and carries only the count.

**Long table** (`armonizar_mivau_serpavi()`; target `larga_serpavi`, 5,898,530 rows with the auxiliaries; plan §6.4):
- indicators `alquiler_mes` (8) and `alquiler_m2` (9);
- the median, in the cut `tipologia`, with groups `VC` and `VU`; the quartiles, in the cuts `tipologia_p25` and `tipologia_p75`, only where there are data;
- as auxiliaries, the contracts behind each median (`contratos_alquiler`) and its approximate margin (`margen_alquiler_mes` and `margen_alquiler_m2`; §7.6);
- no `total` rows: SERPAVI does not publish a joint median of the two building types (§1);
- levels: tract, district, municipality, province and region. Spain has no medians: only its count of contracts comes in (§7.6);
- `geo_ref = 2021`, no conversion table;
- values with the precision of the source, unrounded. The derived indicators take the value rounded to one decimal, the same one the website receives (§7.4).

**States** (`estado_serpavi()`):
- `dato`: published median;
- `secreto`: 1 to 9 observations. The source publishes only the count; the value is left empty, never 0;
- `ausente`: no observations; foral provinces before their entry (`ENTRADA_SERPAVI_FORALES`: Navarre 2021, Gipuzkoa 2022, Álava and Bizkaia 2024; break `serpavi_forales`); municipalities and districts that do not match their tracts (plan §11, question 13).

**Territorial coverage** (`larga_serpavi`, `jerarquia_2021`):
- The database has 36,293 of the 36,333 tracts of 2021. The other 40 go as `ausente` in every year and building type (`completar_secciones_serpavi()`; warning `serpavi_sin_fila`). 36 are single-tract municipalities (34 in Navarre, one in Álava and one in Bizkaia), which are not in the municipality and district sheets either. The other 4, in Madrid, Las Palmas de Gran Canaria (2) and Zaragoza, have no observations: their district adds up to the same as its published tracts. Thus indicators 8, 9, 15 and 21 have a row in all 36,333 tracts, like indicators 14, 18 and 19.
- 4 municipalities and 68 districts of the sheets that do not exist in the 2021 tract map are left out (`estado_serpavi()`). They are empty from 2015 to 2024; the municipalities are 15026, 15063, 36011 and 36012, merged into 15902 and 36902 (blocking check `serpavi_seccionado`).
- The 36 single-tract municipalities and their districts also go as `ausente`, as a municipality and as a district (warning `serpavi_sin_fila`; plan §11, question 26). The long table has all 8,131 municipalities and 10,479 districts of the hierarchy, 52 provinces and 19 regions.

**Errors in the municipality and district sheets** (warning `serpavi_escalas_detalle`, `descuadres_serpavi()`; plan §11, question 13). There are 164 figures of unit, year and building type that do not match their tracts. They go as `ausente`, and the tracts keep their data:
- in Navarre: 82 municipalities in 2022 with the apartment median and P25 swapped; 18 districts in 2022 with counts shifted by one row (31 rows); 40 municipality rows in 2023 and 2024 without the count that their tracts do have;
- outside Navarre, all in 2022: 7 municipalities with a single-family median and 0 observations; district 4622101 (2 rows); a non-integer count in Valmadrid (50275); Cabanes (17030), with a rent per m² different from that of its only tract.

(`inventario/referencias_validacion.csv`.)

**Result: tracts by year and building type** (`resumen_larga_serpavi`; the last two columns, from `larga_serpavi`). Indicator 9 has the same states as indicator 8.

| Year | `VC`: `dato` | `VC`: `secreto` | `VC`: `ausente` | `VU`: `dato` | `VU`: `secreto` | `VU`: `ausente` | With some median | Confidential only |
|---|---|---|---|---|---|---|---|---|
| 2015 | 21,627 | 5,995 | 8,711 | 5,543 | 15,250 | 15,540 | 23,497 | 7,885 |
| 2016 | 22,051 | 5,749 | 8,533 | 6,065 | 15,073 | 15,195 | 24,086 | 7,474 |
| 2017 | 22,447 | 5,511 | 8,375 | 6,537 | 14,907 | 14,889 | 24,575 | 7,059 |
| 2018 | 22,820 | 5,289 | 8,224 | 6,972 | 14,709 | 14,652 | 25,024 | 6,719 |
| 2019 | 23,136 | 5,123 | 8,074 | 7,430 | 14,443 | 14,460 | 25,444 | 6,391 |
| 2020 | 23,415 | 5,063 | 7,855 | 7,823 | 14,335 | 14,175 | 25,844 | 6,142 |
| 2021 | 23,988 | 5,023 | 7,322 | 8,180 | 14,409 | 13,744 | 26,440 | 6,160 |
| 2022 | 24,671 | 4,954 | 6,708 | 8,386 | 14,528 | 13,419 | 27,192 | 5,995 |
| 2023 | 24,878 | 4,861 | 6,594 | 8,697 | 14,412 | 13,224 | 27,420 | 5,862 |
| 2024 | 26,137 | 4,849 | 5,347 | 9,065 | 14,482 | 12,786 | 28,735 | 5,791 |

- «With some median»: `dato` in at least one building type.
- «Confidential only»: the tract has observations, but neither building type reaches 10.
- The 2024 figures reproduce those of the plan (§2.4).

**Apartment coverage by province** (% of tracts with a median; `resumen_larga_serpavi`, element `provincias`). The five lowest and five highest in 2024, and the missing foral provinces:

| Province | 2015 | 2020 | 2024 |
|---|---|---|---|
| Soria | 18.1 | 19.4 | 19.4 |
| Cuenca | 16.1 | 20.0 | 21.9 |
| Teruel | 19.3 | 21.8 | 22.5 |
| Zamora | 21.6 | 23.8 | 24.1 |
| Ávila | 21.5 | 25.3 | 27.6 |
| Illes Balears | 86.7 | 88.8 | 91.1 |
| Bizkaia | — | — | 92.1 |
| Barcelona | 90.7 | 92.2 | 92.6 |
| Madrid | 92.3 | 94.3 | 95.1 |
| Gipuzkoa | — | — | 95.4 |
| Navarre | — | — | 64.6 |
| Álava | — | — | 80.4 |

«—»: before the province entered SERPAVI. The denominator is the province's tracts in the 2021 tract map, including those the database does not have.

**2024 values, apartments** (`larga_serpavi`):
- In the 26,137 tracts with data, the median of each tract ranges from €150 to €3,504 a month. 10th percentile, €370; median, €570; 90th percentile, €893. For rent per m²: 4.2, 7.3 and 12.7 €/m².
- Provinces: Madrid, €800 and 12.1 €/m²; Barcelona, €753 and 11.0 €/m²; Bizkaia, €734 and 10.2 €/m²; Navarre, €598 and 6.9 €/m².

**Gate** (`comprobar_mivau_serpavi()`; §4.1): `serpavi_provincia`, `serpavi_espana`, `serpavi_secreto`, `serpavi_cuartiles`, `serpavi_escalas` and `serpavi_seccionado` (blocking), and `serpavi_escalas_detalle`, `serpavi_forales` and `serpavi_sin_fila` (warning). Medians are not aggregated: the gate adds up observations and checks the rules of the source. Contracts and margin have their own gate, on the long table (§7.6).

**Foral territories** (break `serpavi_forales` in `inventario/rupturas.csv`). Before their entry, those tracts have no data. The Basque Government deposits statistics (`gv_emal`) do not go down to tract and give the mean, not the median: they are shown as a separate municipal layer (plan §11, question 8).

### 7.2 Renting households (indicator 18)

**Source.** The CSV of indicators by tract of the INE 2021 Population and Housing Census (`ine_censo2021`), on the 2021 tract map: no conversion table is needed. The `version` column carries the file date, 8 Nov 2026.

**Computation** (`leer_ine_censo2021()`, `armonizar_ine_censo2021()`; target `larga_censo2021`). Renting households (%) = 100 × `t20_2` (main residences rented) / `t19_1` (main residences). Each main residence is a household: in no tract with both counts do `t21_1` (households) and `t19_1` differ (`censo2021`). The value is stored unrounded.

**States:**
- `dato`: 34,970 tracts;
- `secreto`: 1,363 tracts with the housing block left blank (`t19_1` or `t20_2` missing);
- `ausente` (no main residences): none.

Confidentiality is concentrated in rural provinces: Guadalajara, 173 of 394 tracts; Burgos, 161 of 587; Soria, 118 of 216; Ávila, 95 of 312; Teruel, 94 of 285. In 19 provinces no tract is under confidentiality (`larga_censo2021`).

**Result** (the 36,333 tracts of the 2021 tract map). It ranges from 0 to 65.5% (0801909055, in Barcelona). 1st percentile, 2.9%; 10th percentile, 6.1%; median, 13.8%; 90th percentile, 26.9%; 99th percentile, 40.0%. 12 tracts have 0%.

**Quirk of the source.** In 78 tracts, ownership, renting and other tenure (`t20_1` + `t20_2` + `t20_3`) do not add up to the main residences (`censo2021`). The percentage still uses `t20_2` / `t19_1`.

**Gate** (`comprobar_ine_censo2021()`; §4.1). It is compared with table 59523 of the 2021 Census. Spain: 16.10% of households renting in the tracts and in the table. The table only counts conventional dwellings; that is why, in some provinces, the tracts add up to more households (`inventario/referencias_validacion.csv`).

**Spain, regions and provinces** (`territorios_ine_censo2021()`; plan §11, question 25). These are the figures published in table 59523: Spain, 100 × 2,983,619 renting households / 18,536,616 households = 16.10%; the 19 regions and 52 provinces likewise (provinces, from 5.7% in Jaén to 31.6% in Melilla; regions, from 9.1% in Extremadura to 31.6% in Melilla). The CSV of indicators only has tracts, and their sum does not give these figures: the 1,363 tracts under confidentiality are missing. Ceuta and Melilla appear as a region (18 and 19) and as a province (51 and 52), with the same figure; province codes 18 and 19 are Granada and Guadalajara, and the level tells them apart. Gates: `censo2021_nacional` (the 52 provinces and the 19 regions add up exactly to the households and renting households of Spain) and `censo2021_alquiler` (each territory against its tracts, with the tracts under confidentiality as an interval; §4.1). These 72 rows are `dato` and carry no tract map (`geo_ref` empty).

**2011 Census** (plan §11, question 14; task 47). Indicators by tract from the 2011 Census (`ine_censo2011`; `paso2011_leer_censo2011()`, target `censo2011`): population (`t1_1`), dwellings (`t16_1`), main residences (`t17_1`) and rented (`t18_4`). It is a sample-based census: each figure is an estimate rounded to multiples of 5, and an empty cell is confidential (fewer than 5 sample units). Of the 35,960 Census tracts, 35,917 have a row; in 8,512 the rented or the main-residence count is missing.
- **Calculation on the 2021 tract map** (`paso2011_reproyectar_censo()`, target `censo2011_2021`): main and rented residences are carried as counts with the Census table (§3.11), and the percentage is recomputed in each 2021 tract. Status: that of the counts; `secreto` if any of its sources lacks either count; `ausente` if it receives nothing.
- **Result:** `dato`, 23,655 tracts; `estimado`, 3,931; `secreto`, 8,714; `ausente`, 33. Median, 9.7%; 90th percentile, 29.6%; 3,087 tracts at 0%, because small counts are rounded.
- **Spain, regions and provinces** (table 02003; `paso2011_leer_tenencia()`, target `censo2011_tenencia`): Spain, 100 × 2,438,574 / 18,083,692 = 13.48%. Single-province regions also give the province. Gates `paso2011_censo_alquiler`, `paso2011_censo_principales` and `paso2011_censo_paso` (§4.1).
- **Two snapshots** (break `censo_metodo_2021`): the 2011 Census is sample-based and the 2021 one comes from registers.

### 7.3 Tourist dwellings (indicator 19)

**Source.** INE's experimental statistics on tourist dwellings, built from platform listings (`ine_vut`). Table 5 (districts and tracts) is one xlsx per period, with 13 half-yearly periods from August 2020 to May 2026 (`PERIODOS_VUT`). Tables 39364 (dwellings) and 39365 (percentage) give Spain, the regions and the provinces. The `version` column carries the date of the last file, 8 Nov 2026.

**Tract map of each period** (checked code by code on 8 Nov 2026; break `vut_seccionado_2024` in `inventario/rupturas.csv`):

| Periods | Tracts in the file | Denominator of the INE percentage |
|---|---|---|
| August 2020 – February 2023 (6) | 35,960, those of the 2011 Census | 2011 Census dwellings |
| August 2023 | 37,063 codes: those of the 2011 Census and others from later tract maps | 2021 Census dwellings (`inventario/indicadores.csv`) |
| February 2024 | 2024 tract map, plus 258 old codes without tourist dwellings | 2021 Census dwellings (`t18_1`) |
| August 2024 – May 2026 (5) | 2024 tract map (36,477 tracts) | 2021 Census dwellings (`t18_1`) |

**Periods in the atlas** (plan §11, question 14). The six on the 2024 tract map, from February 2024 to May 2026 (`PERIODOS_VUT_2024`). Since task 47, also the six from August 2020 to February 2023 (`PERIODOS_VUT_2011`), on the 2011 Census tracts, with their conversion table (§3.11; below). August 2023 is read (`leer_ine_vut()`) and enters the gate of provincial counts, but not the indicator: it mixes the 2011 Census tracts with those of later tract maps, without saying which geography each code has (under review). Using the INE municipal level was ruled out, because it would mix scales in the series.

**Computation on the 2021 tract map** (`reproyectar_ine_vut()`; target `vut_2021`):
- The tourist dwellings of each 2024 tract go to 2021 with the combined 2024 → 2021 table (`paso_final_2024`; §3.5), as a count (`geo_reproyectar_recuento()`).
- If the 2021 tract receives a single 2024 tract, whole, the INE percentage is copied. There are 35,131 such tracts (`secciones_1a1_vut()`).
- In the rest, percentage = 100 × reprojected tourist dwellings / 2021 Census dwellings of the tract (`t18_1`), the same denominator INE uses.

**States:**
- `dato`: 1:1 tract or sum of whole tracts;
- `estimado`: some 2024 tract is split (877 tracts);
- `secreto`: percentage protected by INE or 2021 Census dwellings under confidentiality;
- `ausente`: the tract receives nothing from the conversion table. There is only one: 0309002003, the Mutxamel coverage exception (§3.8).

**Confidentiality.** INE always publishes the number of tourist dwellings and protects the percentage in some tracts. On the 2021 tract map, 1,371 tracts are `secreto` in February and August 2024 and 172 since November 2024; all are 1:1 tracts (`vut_2021`).

**Long table** (`armonizar_ine_vut()`; target `larga_vut`, 218,430 rows: 6 periods by 36,333 tracts, plus Spain, the 19 regions and the 52 provinces in each period; plan §6.4):
- `anio`: the year of the reference month;
- `corte = mes` and `grupo` `M02`, `M05`, `M08` or `M11`;
- no `total` rows: the website takes the last month;
- month rather than half-year: the calendar changed in 2024, which has three periods (break `vut_calendario_2024`).

**Result** (`larga_vut`; tourist dwellings, sum of `vut_2021`). The median and the 90th percentile are given with two decimals:

| Period | `dato` | `estimado` | `secreto` | `ausente` | Tourist dwellings (Spain) | Median (%) | 90th percentile | 99th percentile | Maximum | Tracts with 0% |
|---|---|---|---|---|---|---|---|---|---|---|
| February 2024 | 34,084 | 877 | 1,371 | 1 | 351,389 | 0.25 | 2.16 | 9.8 | 36.8 | 11,022 |
| August 2024 | 34,084 | 877 | 1,371 | 1 | 403,267 | 0.30 | 2.50 | 11.1 | 38.5 | 10,111 |
| November 2024 | 35,283 | 877 | 172 | 1 | 376,463 | 0.27 | 2.32 | 10.3 | 38.5 | 11,282 |
| May 2025 | 35,283 | 877 | 172 | 1 | 381,837 | 0.26 | 2.35 | 10.7 | 38.7 | 11,442 |
| November 2025 | 35,283 | 877 | 172 | 1 | 329,764 | 0.19 | 2.02 | 9.8 | 37.9 | 13,435 |
| May 2026 | 35,283 | 877 | 172 | 1 | 341,001 | 0.20 | 2.12 | 9.8 | 52.4 | 13,405 |

- The sum of tourist dwellings equals that of table 39364 (`vut_paso_2021`).
- Distribution figures are for tracts with `dato` or `estimado`.
- The May 2026 maximum is tract 2906703002, 1:1, with the percentage copied from INE: 460 tourist dwellings out of 878 dwellings.

**Same year** (guide, rule 4). Numerator and denominator are not from the same year: dwellings are those of the 2021 Census, as at INE. The indicator sheet says so (`inventario/indicadores.csv`).

**Gate** (`comprobar_ine_vut()`; §4.1). The tracts add up exactly to the published provincial totals in the 13 periods, also after the conversion table. In 1:1 tracts, the INE percentage is 100 × tourist dwellings / `t18_1`; since November 2024, between 194 and 225 tracts per period differ by up to 0.09 points (`inventario/referencias_validacion.csv`).

**Spain, regions and provinces** (`territorios_ine_vut()`; plan §11, question 25). The percentage published in table 39365, with two decimals, for Spain, the 19 regions and the 52 provinces, in the six periods of the tracts; all rows are `dato`. Spain: 1.33% in February 2024, 1.52% in August 2024, 1.41% in November 2024, 1.43% in May 2025, 1.24% in November 2025 and 1.28% in May 2026. Provinces, from 0.10% (Melilla, November 2025) to 4.96% (Las Palmas, November 2025); regions, from 0.10% (Melilla) to 4.71% (Canary Islands, November 2024). Ceuta and Melilla, as in indicator 18 (§7.2). The seven earlier periods are left out, as for the tracts; up to February 2023, moreover, the INE denominator is the 2011 Census dwellings. Gates (`nacional_vut()`, `territorios_vut()`):
- `vut_nacional_viviendas`: the 52 provinces add up exactly to the tourist dwellings of Spain in the 13 periods;
- `vut_nacional_porcentaje`: the mean of the provincial percentages, weighted by the 2021 Census dwellings of each province, differs from the percentage for Spain by −0.001 to +0.009 points (tolerance ±0.02: percentages have two decimals and Census tracts under confidentiality carry no weight);
- `vut_territorios`: the percentage of Spain, each region and each province against 100 × tourist dwellings of its tracts / 2021 Census dwellings, with the denominator INE uses in each period. In February and August 2024, INE divided by the dwellings of the published tracts. Since November 2024 it also counts those of the Census tracts under confidentiality, which are not published, and the figure falls by up to 0.11 points in the provinces that have most of them (Soria, May 2025: 0.65% published against 0.76% with the tracts with data). For those periods, the denominator is table 59521 of the 2021 Census (conventional family dwellings by region and province, `leer_ine_censo2021_viviendas()`; Spain, 26,623,708). All 432 figures match, up to rounding: tolerance ±0.005 points, half a unit of the last published decimal; maximum difference, 0.005 points (Jaén, February 2024: 0.255 published as 0.26). The table counts conventional dwellings only: in 11 provinces the tracts add up to slightly more (up to 791 dwellings, in Huelva).

The change of denominator in November 2024 is recorded as a break in `inventario/rupturas.csv` (`vut_denominador_2024`; plan §11, question 35): the long table carries INE's figure for each period, and in the territories with tracts under confidentiality the November 2024 figure falls slightly against August's because of the denominator alone.

**August 2020 to February 2023** (task 47; `paso2011_reproyectar_vut()`, target `vut_2011_2021`). Tourist dwellings on the 2011 Census tracts are carried to 2021 as a count, with their own table (`paso_final_2011_vut`; §3.11). The denominator is the 2011 Census dwellings (`t16_1`), INE's denominator in those periods, carried with the same table. If the 2021 tract receives a single whole Census tract, INE's percentage is copied (30,250 tracts). Status: that of the counts; `secreto` if INE protects the percentage of any of its sources or the 2011 Census does not give its dwellings; `ausente` if it receives nothing.

| Period | `dato` | `estimado` | `secreto` | `ausente` | Tourist dwellings (Spain) | Median (%) | 90th percentile | 99th percentile | Maximum | Tracts at 0% |
|---|---|---|---|---|---|---|---|---|---|---|
| August 2020 | 30,574 | 5,427 | 313 | 19 | 321,496 | 0.21 | 2.13 | 11.3 | 82.0 | 12,295 |
| February 2021 | 30,574 | 5,427 | 313 | 19 | 294,698 | 0.19 | 1.94 | 10.1 | 82.2 | 12,740 |
| August 2021 | 30,574 | 5,427 | 313 | 19 | 306,974 | 0.19 | 2.00 | 10.5 | 76.5 | 12,708 |
| February 2022 | 30,574 | 5,427 | 313 | 19 | 285,868 | 0.18 | 1.89 | 9.9 | 72.3 | 13,305 |
| August 2022 | 30,574 | 5,427 | 313 | 19 | 311,517 | 0.19 | 2.06 | 10.6 | 78.9 | 12,872 |
| February 2023 | 30,574 | 5,427 | 313 | 19 | 305,135 | 0.20 | 2.01 | 10.4 | 84.3 | 12,660 |

- The sum is that of table 39364, except for one tourist dwelling in August 2022 and in February 2023: that of tract 1502501002, which has no conversion (`paso2011_vut_paso`, `paso2011_sin_paso`).
- The 19 `ausente` tracts are those the table leaves empty (§3.11).
- Spain, regions and provinces: the percentage published in table 39365 (`territorios_ine_vut()`). Spain: 1.28% in August 2020, 1.17% in February 2021, 1.22% in August 2021, 1.13% in February 2022, 1.24% in August 2022 and 1.21% in February 2023. Gates `paso2011_vut_denominador` and `paso2011_vut_territorios` (§4.1).
- **Same year** (guide, rule 4): tourist dwellings for 2020–2023 over 2011 dwellings, as at INE. In February 2024 the tract map and the denominator change at the same time (break `vut_seccionado_2024`).

### 7.4 Derived indicators (14, 15 and 21)

**Definition** (plan §5, block C; `inventario/indicadores.csv`):

| # | Indicator | Formula | Unit | Terms |
|---|---|---|---|---|
| 14 | Median rent over the area's average household income (formerly resident rent burden) | Median monthly rent × 12 / average net income per household, same year | % of household income | Indicators 8 and 2 |
| 15 | Rent share of income | Median rent per m² × 50 / net monthly income of the token | % of the token's income | Indicator 9 and the token's income (§6) |
| 21 | Net pay needed (default map) | Median monthly rent / 0.30 (threshold can be changed to 40%); alongside, the theoretical minimum: median rent per m² × 50 / 0.30 | Net € a month | Indicators 8 and 9 |

**Building type** (plan §11, question 12): the rent of all three is apartment rent (`grupo = VC`).

**Status** (plan §11, question 15; `peor_estado()`): the worst of its terms, in the order `dato` < `estimado` < `secreto` < `ausente`.
- A tract with confidential rent is `secreto`.
- With rent `dato` and income `estimado`, the burden is `estimado`.
- If any term is missing, `ausente`. That is the case of the rent share with the Young adult token in the Basque Country, Navarre, Ceuta and Melilla, where the token has no income (§6.2).
- For 15, the token income does not count as a term (`estado_peso_alquiler()`; plan §11, question 15 extended): indicator 15 takes the status of the rent, and is `ausente` if the token has no income. The Young adult token goes as `estimado` (it is an estimate, §6.2), and that is explained once, in its method, not in each tract.
- Each figure of indicator 21 has a single term: the main one takes the status of indicator 8 and the 50 m² minimum that of indicator 9 (for apartments they match in every row).

**Rounded terms** (plan §11, question 19; `termino_publicado()`). Rent, household income and token income enter the computation rounded to one decimal with `sprintf("%.1f")` (§0), as the website receives them. So the figure from R and the one the website recomputes in the browser match exactly.

**Same year** (guide, rule 4). In the burden, SERPAVI and ADRH match in 2015–2024. The rent share in the long table uses the token income of the same year as the rent: the Minimum wage token, with the minimum wage of each year from 2015 to 2024; the Pensioner token, with the pension of each year; the Young adult token, with AEAT data for each year. The website does the same with the chosen token (author's decision, 9 Nov 2026).

**How to read them:**
- Indicator 15 is read in bands: up to 30%, 30 to 40% and over 40%.
- Indicator 21 is rent expressed in another unit. The 30% is a convention and counts rent only: Law 12/2023 (art. 18) and Eurostat also count utilities and use household income. The website lets renters' other housing costs be added (§6.7).
- **Two figures for indicator 21** (backlog decision 4; task 40). The main one pays the tract's median monthly rent; the 50 m² theoretical minimum always goes alongside. The implied floor area of the medians (monthly rent / rent per m²) is about 79 m² in 2015 and in 2024, and only 3.4% of tracts fall below 55 m² in 2024: the 50 m² flat sits below what is rented. The map shows the main figure; the minimum goes in the profile, the CSV and the front page (to be reviewed).
- The map of indicator 21 is drawn in six bands, with national cut-offs that are the same every year: €1,000, 1,300, 1,600, 2,000 and 2,600 with actual monthly rent (task 40; until then, €700, 900, 1,100, 1,500 and 2,000 with 50 m²; plan §11, question 20). The colour ramp has six steps that can also be told apart with colour blindness (`rampa_daltonismo`).
- Indicators 15 and 21 change with the threshold; 15 and the minimum of 21, with the floor area; and 15, with the pay of «Your token»: the website recomputes them in the browser (plan §6.6).
- **Indicator 14, profile only** (backlog decision 10; task 41). It divides renters' rent by the average income of all households in the tract, owners included, and barely tells areas apart: in 2024, the median is 18.3% in the fifth of tracts with the lowest household income and 17.5% in the highest, and the 5th and 95th percentiles are 11.6 and 25.3%. That is why it leaves the map selector and stays in the tract and municipality profile, renamed («median rent over the area's average household income») and with that note, which the neighbourhood household token carries too, being the same ratio (§6.4). The bands computed for a map, in the backlog, are kept as a reference.
- **The same share for every income** (backlog, task 45). The 30% threshold treats a low and a high income alike, and does not say whether what is left after paying for housing covers everything else. With a low income, the remainder may not cover basic expenses even if rent stays below 30%; with a high one, going over 30% still leaves a lot. The residual income approach compares what is left with a minimum budget for other expenses by household size and composition (Stone, M. E. (2006). «What is housing affordability? The case for the residual income approach». *Housing Policy Debate*, 17(1), 151–184). The atlas gives the money left over (§6.1), but does not set that budget: the residual income line is left for v1.1 (backlog).

**Computation** (`armonizar_derivados()`; target `larga_derivados`, 2,644,824 rows, source `calculo_propio`):
- **14** (`calcular_esfuerzo_residentes()`): in tracts and municipalities, the levels at which SERPAVI and ADRH publish both terms (`NIVELES_ESFUERZO`), and in the years with both, 2015–2024. No breakdown.
- **21** (`calcular_sueldo_necesario()`): at all SERPAVI levels, 2015–2024, with the 30% threshold: the main figure, with median monthly rent, no breakdown, and the 50 m² theoretical minimum, with cut `superficie` and group `50` (`CORTE_MINIMO_SUELDO`).
- **15** (`calcular_peso_alquiler_ingreso()`): cut `ficha`, with groups `tartera`, `mochila` and `transistor` (2015–2024). The Young adult and Pensioner tokens, in the provinces and their tracts, districts and municipalities; the Minimum wage token, also in the regions. It is a check: the website computes the rent share with the chosen token.
- **Token incomes** (`perfiles_fichas()`; target `perfiles`): the Minimum wage token (§6.3); the Young adult token of each province and year, from 2015 to 2025 (§6.2; 46 provinces with data and 6 `ausente` each year); the Neighbourhood household token (§6.4); the Pensioner token of each province and year (§6.5).
- **Version:** the most recent of its terms, 7 Nov 2026.

**Result: median rent over the area's average household income (14) in the tracts** (`larga_derivados`):

| Year | `dato` | `estimado` | `secreto` | `ausente` | 10th percentile (%) | Median (%) | 90th percentile (%) |
|---|---|---|---|---|---|---|---|
| 2015 | 20,671 | 937 | 6,014 | 8,711 | 13.0 | 17.6 | 23.8 |
| 2016 | 20,988 | 874 | 5,938 | 8,533 | 12.8 | 17.4 | 23.7 |
| 2017 | 21,888 | 543 | 5,527 | 8,375 | 12.8 | 17.3 | 23.8 |
| 2018 | 22,600 | 206 | 5,303 | 8,224 | 12.6 | 17.2 | 23.9 |
| 2019 | 22,989 | 134 | 5,136 | 8,074 | 12.8 | 17.7 | 24.7 |
| 2020 | 23,413 | 0 | 5,065 | 7,855 | 13.1 | 18.2 | 25.7 |
| 2021 | 23,858 | 130 | 5,023 | 7,322 | 13.0 | 18.1 | 25.4 |
| 2022 | 24,235 | 433 | 4,957 | 6,708 | 12.9 | 17.9 | 24.9 |
| 2023 | 24,275 | 592 | 4,872 | 6,594 | 12.6 | 17.6 | 24.2 |
| 2024 | 25,271 | 854 | 4,861 | 5,347 | 12.6 | 17.6 | 24.0 |

- The three derived indicators have a row in all 36,333 tracts and 8,131 municipalities; indicators 15 and 21, also in all 10,479 districts. Territories missing from the SERPAVI database are `ausente` (§7.1).
- `estimado` comes from reprojected income (§5.4): rent is not reprojected.
- Pay needed (21) has the same states as apartment rent (§7.1), in both its figures.

**2024 values in the tracts** (`larga_derivados`):

| Indicator | Tracts with a value | Minimum | 10th percentile | Median | 90th percentile | Maximum |
|---|---|---|---|---|---|---|
| Median rent over the area's average household income (%) | 26,125 | 6.2 | 12.6 | 17.6 | 24.0 | 51.3 |
| Net pay needed, with actual monthly rent (€ a month) | 26,137 | 500 | 1,235 | 1,900 | 2,976 | 11,679 |
| Net pay needed, 50 m² minimum (€ a month) | 26,137 | 300 | 700 | 1,217 | 2,117 | 4,283 |
| Rent share with the Young adult token (%) | 24,117 | 7.2 | 16.8 | 27.5 | 43.7 | 87.9 |
| Rent share with the Minimum wage token, 2024 minimum wage (%) | 26,137 | 7.3 | 17.0 | 29.5 | 51.3 | 103.8 |
| Rent share with the Pensioner token (%) | 26,137 | 6.2 | 14.3 | 23.3 | 37.9 | 73.2 |

**Rent share with the Minimum wage, Young adult and Pensioner tokens in the tracts, each year with that year's income** (`larga_derivados`; median and share of tracts with a value above 30%):

| Year | Minimum wage: median (%) | Minimum wage: above 30% | Young adult: median (%) | Young adult: above 30% | Pensioner: median (%) | Pensioner: above 30% |
|---|---|---|---|---|---|---|
| 2015 | 36.7 | 69.2% | 28.2 | 43.0% | 22.7 | 21.3% |
| 2016 | 36.3 | 70.8% | 28.4 | 43.4% | 22.6 | 21.3% |
| 2017 | 34.3 | 63.4% | 28.2 | 43.3% | 22.6 | 22.1% |
| 2018 | 34.2 | 61.9% | 27.8 | 41.5% | 22.7 | 23.1% |
| 2019 | 30.0 | 50.1% | 28.2 | 43.4% | 23.2 | 25.7% |
| 2020 | 28.9 | 46.2% | 29.7 | 49.1% | 23.4 | 26.5% |
| 2021 | 29.7 | 49.0% | 28.6 | 44.8% | 23.7 | 26.9% |
| 2022 | 29.7 | 49.7% | 27.9 | 41.9% | 23.8 | 27.2% |
| 2023 | 28.8 | 47.2% | 27.4 | 39.9% | 23.0 | 24.4% |
| 2024 | 29.5 | 48.4% | 27.5 | 40.2% | 23.3 | 24.1% |

With the Young adult token, 7,616 tracts are `ausente` in 2024: all those in the Basque Country, Navarre, Ceuta and Melilla, where the token has no income, and those without rent.

**Gate** (`comprobar_derivados()`, `validacion_derivados`; §4.1): `derivados_terminos`, `derivados_estado`, `derivados_rango`, `perfiles_mochila` and `smi_neto` (blocking), and `derivados_rango_detalle` (warning). Before that, the Minimum wage token goes through `smi_boe`, the Young adult token through `mochila_cobertura` and the Pensioner token through the INSS ones (§6.2, §6.3 and §6.5).

### 7.5 Overburden and access (indicators 22 and 23, v0.0)

**Eurostat method** (`calcular_sobrecarga_ecv()`, `tasa_sobrecarga()`):
- it counts people, not households;
- ratio: housing costs minus allowances over disposable income minus allowances, above 40%;
- for mortgages, interest only;
- income is that of the year before the survey.

**Waves.** Three ECV waves (2023–2025). Region × tenure and region × age are computed with the three waves pooled (`sobrecarga_agrupada`). All cells exceed 50 observations (plan §7, F1b).

**Gate against Eurostat** (`comprobaciones_sobrecarga`):

| Wave | Spain: computed (Eurostat) | Tenants at market price: computed (Eurostat) |
|---|---|---|
| 2023 | 8.24% (8.2) | 30.61% (30.6) |
| 2024 | 7.77% (7.8) | 28.07% (28.1) |
| 2025 | 7.17% (7.2) | 26.80% (26.8) |

The 19 regions and the four age groups are within ±0.05 points (plan §7, F1b).

**Intervals.** It is published without intervals, with the number of observations and the EU-SILC reliability flag (`fiabilidad_eusilc()`). Public microdata carry neither strata nor primary sampling units (plan §11, question 9).

**Income quintile** (`calcular_sobrecarga_quintil()`, `quintil_renta()`; target `sobrecarga_quintil`; plan §11, question 31). Spain by quintile of equivalised disposable income, each wave from 2023 to 2025: household income (HY020) divided by its consumption units (HX240, modified OECD scale). INE files include neither HX090 nor the HY025 factor, which equals 1. The 20, 40, 60 and 80% cut-offs are computed over the whole population with income, using each person's weight (RB050). An income equal to a cut-off goes to the upper quintile: in each wave there are 2 to 7 people per cut-off in that case, and with that rule the figures match Eurostat's (plan §11, question 36). Each figure carries its number of observations and the EU-SILC flag; all 15 are «normal». It goes to the website only: it does not enter the long table, because `inventario/vocabulario.csv` has no such cut. Europe, no quintile in v0.0.

Overburden rate (%) and, in brackets, people in the sample (`sobrecarga_quintil`):

| Wave | QU1 | QU2 | QU3 | QU4 | QU5 |
|---|---|---|---|---|---|
| 2023 | 32.0 (12,210) | 6.4 (12,936) | 2.2 (13,239) | 0.6 (14,274) | 0.1 (14,411) |
| 2024 | 29.6 (12,427) | 6.0 (14,007) | 2.1 (14,459) | 1.0 (15,564) | 0.3 (16,018) |
| 2025 | 27.7 (12,004) | 5.2 (13,298) | 1.9 (14,663) | 0.9 (15,348) | 0.2 (15,848) |

**Quintile gate** (`comprobar_sobrecarga_quintil()`, `validacion_quintil`; §4.1):
- `sobrecarga_quintil_total`: the mean of the five rates, weighted by their people, reproduces the overall rate of each wave (8.24, 7.77 and 7.17%) with no difference;
- `sobrecarga_quintil_reparto` (warning): each quintile holds from 19.95 to 20.05% of the population with income;
- `sobrecarga_quintil_eurostat`: each rate, unrounded, against the one Eurostat publishes for Spain in `ilc_lvho07b` for the same year (`descargar_eurostat_quintil()`, target `eurostat_quintil`), within ±0.1 points, like the other overburden figures. The pipeline stops if Eurostat has not published a wave. All 15 figures of 2023 to 2025 match, and to one decimal they are the same: largest difference, 0.045 points (second quintile of 2025: 5.245 against 5.2). With the cut-off household in the lower quintile, the first quintile of 2025 gave 27.75%, 27.8 on rounding, against Eurostat's 27.7 (plan §11, question 36). There remains an underlying difference, because Eurostat uses HX090.

**Indicator 23.** It comes from the tables of the housing access module of the 2025 ECV: by region, by age and sex, and by tenure (`armonizar_ine_ecv_modulo()`, `armonizar_ine_ecv_modulo_cortes()`).

**Eurostat flags** (`descargar_eurostat_europa()`, column `bandera`; plan §11, question 27). The query of `ilc_lvho07a`, `ilc_lvho07c` and `ilc_lvho07_r` brings the flag of each figure: b, break in series; u, low reliability; e, estimate; p, provisional. Of the 9,690 figures, 381 carry «b», 4 «bu», 493 «e», 28 «p» and 34 «u»; none changed from the query without flags. Spain has a single break, that of the total in 2008. The EU-27 carries estimates («e») in the total from 2014 to 2018 and in market-price renting from 2010 to 2018. From 2021 to 2025, only five Polish regions carry «u», in 2025. The fall in market-price renting in Spain from 2022 to 2023 (from 39.4 to 30.6%) carries no flag. Nor does 2013, when INE starts obtaining incomes by combining the interview with administrative registers (`ecv_ingresos_2013` in `inventario/rupturas.csv`): the website breaks the Spanish series there as a break set by the atlas, with its own note (`rupturas_serie_sobrecarga()`; plan §11, question 34).

**Website** (`exportar_web_sobrecarga()`, `ficheros_web_sobrecarga`). The overburden section reads `web/datos/sobrecarga/` (1.1 MB): a JSON file with twelve map views and two NUTS boundary files (GISCO 2021 and 2024; © EuroGeographics for the administrative boundaries, non-commercial use, outside the data licence; §2.3).
- Whole population, each year from 2021 to 2025: the map draws the ladder list (`armar_escalera()`), each country at the finest level published in `ilc_lvho07_r` and without grouped codes. That is NUTS 2, except Austria, Albania and Türkiye (and France since 2022), which publish only the country figure, and the Netherlands, at NUTS 1: they are hatched. The Spanish regions and Spain carry the microdata figure from 2023 to 2025, which, once rounded, matches Eurostat's in all 57 region-years.
- Bosnia and Herzegovina, which publishes at NUTS 1 in 2022 and 2023, takes the NUTS 2024 boundaries, because NUTS 2021 does not have them (`version_geometria()`; plan §11, question 29); from 2021 to 2023, the countries that NUTS 2021 does not have go into the map background. FI19_20, a grouped code, stays off the map and the ladder.
- By tenure (four groups) or age (three), 2025 only: Eurostat countries and Spanish regions with the three pooled waves.
- Six bands, fixed every year, from `cortes_web` of indicator 22 in `inventario/indicadores.csv` (`cortes_sobrecarga_web()`; plan §11, question 28): cut-offs at 4, 6, 8, 10 and 15%; for market-price renting, at 15, 20, 25, 30 and 40%.
- Figures are stored × 10 as integers. INE figures carry their number of people and households and the EU-SILC reliability flag, and have no value with fewer than 20 observations. Eurostat figures carry their flag, and those flagged «u» get the hatching of small-sample INE figures.
- The page adds the series for Spain and the EU-27 (Eurostat) from the first published year: Spain, 2004 (market-price renting, 2007); EU-27, 2010 (plan §11, question 30). The line breaks at flagged breaks («b») and, for Spain, also in 2013, a break set by the atlas that Eurostat does not flag, with a hollow point and a note below the chart. It also adds the annual breakdowns for Spain, with the income quintile, and the access module (indicator 23).

The gate (`comprobar_web_sobrecarga()`, `validacion_web_sobrecarga`; §4.1) reads the files back and compares them figure by figure with the pipeline targets: `web_sobrecarga_valores` and `web_sobrecarga_muestra` (blocking), also with the flags, cut-offs and quintile, and `web_sobrecarga_geometria` (warning: 0 in the 12 views).

---

### 7.6 Reliability of the rent medians

**Why** (plan §11, questions 12 and 15 extended; `docs/especificacion_contratos_margen.md`). `estado` says whether there is a figure, not whether it is reliable. In 2024, of the 26,137 apartment medians by tract, 2,360 come from 10 to 19 contracts and 2,047 from 20 to 29: 4,407 (16.9%) from fewer than 30. The typical tract has 72.

**Contracts** (`armonizar_fiabilidad_serpavi()`; auxiliary indicator `contratos_alquiler`, cut `tipologia`, groups `VC` and `VU`). It is the SERPAVI count of observations, from the tract up to Spain:
- `dato` when the source publishes a count, including 0;
- `ausente` when the cell is empty or the row is missing, when the foral province has not yet joined, or when the municipality or district does not match its tracts: the same cases in which the median goes as `ausente` (§7.1);
- Spain comes in with the count SERPAVI publishes: in 2024, 2,271,987 apartment contracts and 284,591 single-family ones. In 2022 and 2023 Gipuzkoa is not counted, as in the source (§7.1);
- no tract has a median with fewer than 10 contracts (`serpavi_secreto`); the only cases in the database are seven single-family municipalities in 2022, which already go as `ausente` (§7.1).

**Approximate margin of the median** (`margen_mediana()`; auxiliary indicators `margen_alquiler_mes` and `margen_alquiler_m2`, source `calculo_propio`). It is the relative standard error of the median of n contracts, in %: 1.2533 × σ / (P50 × √n), with σ ≈ (P75 − P25) / 1.349; in all, 0.929 × (P75 − P25) / (P50 × √n).
- It is computed with the quartiles of rent per m² for 9, 15 and 21, and with those of monthly rent for 8 and 14, only where there is a median (10 or more contracts).
- Example: P25 = 8, P50 = 10 and P75 = 12 €/m² with 10 contracts give ±11.8%.
- It is an approximation: it assumes a regular distribution within the area and does not correct the bias of the source (current tenancies, not new ones; §7.1).
- The long table keeps it unrounded; the website receives it with one decimal, the same figure R uses (plan §11, question 19).

**Results for 2024 in the tracts** (`resumen_fiabilidad`):

| Housing type | With a median | 10 to 19 contracts | 20 to 29 | Fewer than 30 | Contracts (median) | Margin per m² (median) | Margin per m² (90th percentile) | Monthly margin (median) | No median: 0 contracts | No median and no count |
|---|---|---|---|---|---|---|---|---|---|---|
| `VC` | 26,137 | 2,360 | 2,047 | 4,407 | 72 | 4.3% | 9.1% | 3.6% | 3,630 | 1,717 |
| `VU` | 9,065 | 4,925 | 1,883 | 6,808 | 18 | 13.4% | 26.6% | 11.2% | 10,064 | 2,722 |

- For apartments, the typical margin falls over the years, from 5.1% per m² in 2015 to 4.3% in 2024, because each tract has more contracts: a median of 51 in 2015 and 72 in 2024.
- The 1,717 apartment tracts with no count in 2024 are the 1,677 that the database has empty and the 40 it does not have (§7.1).

**On the website's tract profile** (`web/js/fiabilidad.js`; §9.2):
- under the figure, «Median of N contracts · approximate margin ±X%», flagged «few contracts» below 30 (`UMBRAL_POCOS_CONTRATOS`, which goes in the manifest);
- for pay needed and the rent maps, the range of the figure with that margin;
- in «Can you make rent?», the three bands do not change: if the range of the ratio crosses 30 or 40%, the profile says it is on the edge between two bands, also with «Your token» and with the 40% threshold;
- with no median: with 1 to 9 contracts, how many there are; with 0, «no registered rental contracts for flats» (or for single-family homes) instead of «no data», and a labelled context that is never shown on the map (guide, rule 1): the median of the other housing type in the tract and that of the same housing type in its municipality;
- the map does not change: without a visual test that justifies it, tracts with few contracts are not dimmed, and the flag goes in the profile and in the CSV;
- over time (backlog, task 43; `web/js/evolucion.js`), a chart of the map series with the margin band (the figure ± its margin, where the profile gives the range: the rent maps in any unit and «Can you make rent?») and a hollow dot in years with fewer than 30 contracts. In the table, the one-year change only appears with 30 or more contracts in both years; otherwise, the average annual change over the last three years, marked «†», or none («—») if the figure from three years earlier is missing. The contracts and margin of each year are read from the files of each period (§9.2).

**Gate** (`comprobar_fiabilidad_serpavi()`, `validacion_fiabilidad`; §4.1): `contratos_mediana` and `contratos_suma` (blocking), and `margen_rango` (warning). The margin is only checked in the tracts: in large areas it naturally falls below 1% (in the provinces, a median of 0.3%).

### 7.7 Home purchase (indicators 10, 12, 16 and 17)

**Notaries: no authorisation; indicator 11, from the Land Registrars.** The Notaries' websites reserve all rights: the terms and conditions of the Statistical Portal and its legal notice (checked on 10 Nov 2026) restrict the data to personal use and ask for the prior and express authorisation of the General Council of Notaries to reproduce, distribute or transform them, even when the source is cited. The atlas does not download its figures (`inventario/fuentes.csv`, `notariado`). Author's decision (10 Nov 2026): the sale price per m² (indicator 11) comes from the Land Registrars, by province, never mixed with the Notaries. The deeds arrive another way: the MIVAU publishes, under its own reuse conditions, the average value of open-market home sales signed before a notary (`mivau_transacciones`), without the floor area, and it serves the coherence gate.

**Sale price per m² (indicator 11), from Registradores** (`R/fuente_registradores.R`; plan §11, question 45 a as revised). Real Estate Registry Statistics of the Spanish Land Registrars' Association, open data under the ODbL (§2.2): registered home sales, average amount and average price per m², by quarter, for Spain, the 19 regions and the 52 provinces, since 2007. Level: province, the finest the open source publishes (author's decision, 10-Nov-2026, replacing the municipality of question 45); the region and Spain, with their published figure (rule 1). Each quarter accumulates the last four, so the year is the fourth quarter: the average price per m² of the sales in the calendar year (`registradores_anual()`), from 2015 to 2025 (`registradores_armonizar()`). It is not mixed with the Notaries, which measure another floor area: in Spain, in 2025, €2,284/m² against €1,902/m² (plan, question 45). Manual file (§2.1): reader (`registradores_leer()`), gate (`registradores_comprobar()`, §4.2) and tests with an invented CSV in the same format (`pruebas/datos/registradores_inventado.csv`); in the pipeline since 11 Nov 2026 (targets `fichero_registradores`, `registradores`, `validacion_registradores` and `larga_registradores`, within `larga_compraventa`): 52 provinces, 19 regions and Spain, from 2015 to 2025, all `dato`. With the published file (from 2007 to the second quarter of 2026), Spain gives €2,283.52/m² in 2025; the sales of the provinces add up to those of their regions and of Spain in every quarter, and the price per m² of Spain and of the regions deviates from the mean of their provinces weighted by sales by between −0.6 and +1.5% (the source does not give the m², so it is not an identity).

**Coherence of the appraised value with Registradores** (`registradores_coherencia_tasado()`; question 45 b). Registradores price per m² over MIVAU's appraised value per m², same territory and year, province against province: €/m² against €/m². With the published file, from 2015 to 2025: Spain, from 0.99 (2015) to 1.12 (2022); provinces, from 0.74 (Badajoz, 2015) to 1.41 (Santa Cruz de Tenerife, 2022). Threshold: Spain, from 0.85 to 1.25; provinces, from 0.6 to 1.6, with at most 5% outside (blocking), and a warning outside 0.7–1.4. The coherence by implied floor area with MIVAU's deeds (below) also stays.

**Annual change in rents (indicator 10).** Figure published by INE's IPVA (`leer_ine_ipva()`; target `larga_ipva`) at its native level: Spain, 17 regions, 48 provinces, 718 municipalities above 10,000 inhabitants and 407 districts of the provincial capitals, all in the 2021 tract map. No Basque Country or Navarre: the IPVA comes from the common-regime income tax. The «Resto» (rest of the province) rows are left out. It is an index: it is neither aggregated nor reprojected (guide, rule 1). In 2024, Spain rises by 3.5%, with a municipal median of 3.3%.

**New and existing tenancies (indicator 10, `contrato` breakdown; backlog, task 36).** Since the 2021 edition, the IPVA separates new from existing tenancies for Spain and the regions (table 59004) and for the provinces (table 59005), from 2021 to 2024; it does not publish them by municipality or district. `armonizar_ine_ipva()` adds to the long table the published annual change of each group (`nuevo` and `existente`) for Spain, 17 regions and 48 provinces; the total still comes from the general tables. What INE says (IPVA technical project, June 2023):
- **New tenancy:** one whose contract year is the reference year, using the contract date that the AEAT databases hold since 2019; the rest are existing tenancies. Declared income covers the whole year: if a dwelling had two contracts in the year, its annual price includes both, and the change only captures part of the effect of the new contract.
- **Base:** the published indices are base 2015 = 100, chaining each year's index onto the previous one. Contract age enters the strata from 2021, and the document does not say how the breakdown is linked to the base. The figures settle it: each group's 2021 index is the general 2020 index times the group's change, for Spain, the 17 regions and the 48 provinces (`ipva_contrato_enlace`, maximum difference of 0.049 points). Before 2021 the breakdown does not exist.

In Spain, from 2021 to 2024, new tenancies rise by 19.3% (index from 114.871 to 137.041) and existing ones by 7.5% (from 112.229 to 120.637), against 9.1% for the total (from 112.694 to 122.920); in 2024, by 8.8 and 2.8%. It is an index, not a price: it does not give the rent paid by newcomers and is not mixed with asking rents (§1). New tenancies belong to the «moving in» family and existing ones to «staying», but the `familia_alquiler` column holds one value per indicator and indicator 10 stays in «staying» (to be reviewed). The website does not export the breakdown: it has no map.

**Appraised value (indicator 12).** MIVAU's average appraised value of open-market housing per m², quarterly, for Spain, the regions, the provinces and the municipalities above 25,000 inhabitants (306 since 2020). The year is the average of its four quarters weighted by the number of appraisals (`valor_tasado_anual()`); without all four, `ausente` (3 to 9 municipalities a year up to 2020). The Ministry publishes no annual average and does not weight its regions by appraisals: the published region departs from the average of its provinces weighted that way by up to 3.3% (`valor_tasado_ccaa_media`), through composition, but it never leaves the range of its provinces (`valor_tasado_ccaa`). The Ministry's names are matched to INE codes by their normalised form (`casar_nombres_mivau()`), by a name that is unique in Spain when the municipal table carries the wrong province down (seven municipalities) and by `inventario/nombres_mivau.csv` (typos and different names). Spain: 1,475.6 €/m² in 2015 and 1,913.9 €/m² in 2024.

**Coherence between deeds and appraisals** (`comprobar_coherencia_compraventa()`, `validacion_coherencia_compraventa`; the «done when» of F4). The two sources do not share a unit: the average deed value is per dwelling and the appraised value, per m². Their ratio is the floor area the average dwelling sold would have if it were paid at the appraised value: the «implied floor area». If both measure the same market, it falls close to the average floor area of the dwellings sold, somewhat below, because the deed price tends to sit below the appraisal; an error of reading, unit or matching pushes it abruptly out of that range. Threshold: from 70 to 110 m² for Spain, every year, and from 50 to 150 m² in provinces and quarters, with at most 5% outside. Result: Spain, from 91.8 to 106.1 m² (2015–2025); in provinces, at most 1.9% outside (2021), with the Balearic Islands above 150 m² in 2021 and 2022.

**Average rate** (`ine_hipotecas`; target `tipo_hipotecario_anual`). INE's average initial interest rate of home mortgages, annual: 3.31% in 2015, 1.92% in 2021 and 3.26% in 2024. Since 11-Nov-2026 it only serves its gate (`validacion_hipotecas`).

**Banco de España rate** (`compraventa_tipo_bde()`; target `tipo_bde_anual`; plan §11, question 45 e as revised). The rate on new loans to households for house purchase (`D_IMVTIPLV`, §7.9), the same one the Banco de España uses for its theoretical burden; the year, the mean of its twelve months, to two decimals with ties rounded up on the decimal figure (`redondear_empate_arriba()`; author's decision, 11 Nov 2026, plan §11, question 59 b): 2.50% in 2015, 1.62% in 2021 and 3.47% in 2024. The 2024 mean is exactly 3.465, and `sprintf("%.2f")`, used before, left it at 3.46 because the binary stores it slightly below; from 2011 to 2025 it is the only tie.

**Derived indicators** (`armonizar_derivados_compraventa()`; target `derivados_compraventa`, source `calculo_propio`). With the appraised value of 80 m², of the same year as the other term (rule 4):
- years of wages to buy (16): appraised value × 80 / the Tax Agency's average gross annual wage per employee (indicator 7); for a municipality, that of its province;
- mortgage payment over household income (17; name of 12 Nov 2026): first-year payment of a French-amortisation loan for 80% of the value, over 25 years at the year's Banco de España rate (`cuota_hipoteca()`), × 12 / ADRH average net income per household × 100 (plan §11, question 45 d as revised; it is not the Banco de España's theoretical burden of §7.9, which does the same calculation with its standard home and the income of the median household and comes out at about twice as much: in Spain, in 2024, 34.6% on average against 18.1%; `compraventa_renta_hogar()`, target `renta_hogar_17`). At each level, the income INE publishes: the municipality's and, since 11 Nov 2026, the province's, the region's and Spain's, from totals table 53689 (`renta_hogar_publicada`; rule 1: there is a published figure and it prevails). Where INE does not publish it (Navarre from 2015 to 2020, Álava from 2015 to 2019, Gipuzkoa in 2015, their regions and Spain until 2020: 29 figures), the province and the region are `ausente`, without a figure, because municipal coverage is partial (Navarre from 2017 to 2019, about 60 of its 272 municipalities), and Spain takes the mean of its municipalities weighted by their households (population / average household size of their tracts), `estimado` (author's decision, 11 Nov 2026). Gate `validacion_renta_hogar_publicada` (§4.1): the aggregated mean deviates from the published one by 0.13% at most in the median of each year and level, and by more than 1% in 6 of 691 figures (Guadalajara from 2015 to 2019 and Seville in 2016).

Indicator 16, from 2015 to 2025, and 17, from 2015 to 2024 (the years with ADRH income: without it, the whole year would come in as `ausente`), for Spain, the regions, the provinces and the municipalities above 25,000 inhabitants. Indicator 16, without a Tax Agency wage (Basque Country and Navarre), `ausente`; 17 also covers the foral territories, with ADRH income. Status: the worst of its terms (17 for provinces, regions and Spain, `dato` where INE publishes the income: 508 provinces, 179 regions and Spain from 2021 to 2024; Spain from 2015 to 2020, `estimado`; 12 provinces and 11 regions, `ausente`). In Spain, 6.3 years in 2015, 6.1 in 2024 and 6.6 in 2025 (16), and 17.8% in 2015 (`estimado`) and 18.1% in 2024 (17; with the rate at 3.46%, 18.0%; with the income aggregated from the municipalities, 15.3% in 2021 against 15.2% with the published one; with the Tax Agency wage and the INE rate it gave 29.8 and 28.7%); among the municipalities in 2024, from 2.2 to 17.9 years (median, 5.3) and from 6.8% (Puertollano) to 39.8% (Santa Eulària des Riu), with a median of 15.4%. Gate: `compraventa_terminos`, `compraventa_estado` and `compraventa_rango` (blocking), and `compraventa_rango_detalle` (warning).

**Postcode ↔ municipality** (`leer_ine_callejero_cp()`, `geo_tabla_cp_municipio()`; target `fichero_cp_municipio`, in `geo/codigos_postales_2021.csv`). It comes from the street sections of the January 2021 street directory: 11,046 postcodes in 14,600 pairs, covering all 8,131 municipalities; 8,784 postcodes fall in a single municipality. The weight is the share of the postcode's street sections in each municipality. 50 pairs have a postcode from another province: enclaves such as the County of Treviño, with those of Álava, and typos in the street directory.

**Website.** Since 10 Nov 2026, the four have a municipal map without tracts (§9.2), with cut-offs to be reviewed: 0 · 1 · 2 · 3 · 4% (10), 1,000 · 1,500 · 2,000 · 2,500 · 3,500 € per m² (12), 3 · 4 · 5 · 7 · 10 years (16) and 15 · 20 · 25 · 30 · 40% (17). Since task 51, seven classes with one set for municipalities and another for provinces and regions (§9.2). Indicator 11 (Land Registrars), since 11 Nov 2026, has a provincial map at every zoom level, with municipalities and tracts switched off (`nivel_minimo` «provincia»), and seven bands with cut-offs at 950 · 1,200 · 1,400 · 1,650 · 1,950 · 2,550 € per m² (set `provincia_ccaa` in `inventario/cortes_web_niveles.csv`, septiles of the provinces in 2025; task 51); in `cortes_web`, 1,000 · 1,250 · 1,500 · 2,000 · 2,500.

### 7.8 Pressure: stressed areas (indicator 20) and asking prices (indicator 13)

**Stressed residential market zones (indicator 20).** Law 12/2023 on the right to housing leaves the declaration to the autonomous community and requires the Ministry of Housing and Urban Agenda to publish every quarter in the BOE a resolution listing the declared zones, their period in force and the link to the community's declaration (art. 18(2)(d)). Those resolutions are the atlas's source (`zonas_tensionadas`): 10, from the one of 15 March 2024 (`BOE-A-2024-5214`) to the one of 3 November 2026 (`BOE-A-2026-23088`), found by going through the BOE daily summaries since the law came into force; a correction of errata (`BOE-A-2025-20246`) only changes links. All set the same period: three years from the day after the resolution's publication; the period ends on the same day of the expiry year (Law 39/2015, art. 30(4)). None expires before 15 March 2027.

**Inventory and gate.** The decisions are in `inventario/zonas_tensionadas.csv`: one row per municipality and declaration, 321 rows and 320 municipalities (Llanes has two declarations for different villages), with the BOE's literal name, the INE code and name, the area, the dates and the links to the resolution and to the community's declaration. `descargar_zonas_tensionadas()` downloads the XML of each resolution and `leer_boe_zonas_tensionadas()` reads its tables; the gate (`comprobar_zonas_tensionadas()`, target `validacion_zonas_tensionadas`, all blocking) requires each row to have its resolution downloaded and its publication date, a municipality code of the 2021 tract map with its INE name and in the region of its BOE row, the literal name in its resolution's table, that no name in the tables is left out of the inventory, the effective date on the day after publication and the end date set by the text. The BOE omits a comma between Manresa and el Masnou (`BOE-A-2024-5214`) and splits the name of Castell d'Aro, Platja d'Aro i S'Agaró at its comma (`BOE-A-2024-20576`): the inventory keeps the names as they are and the gate finds them. To add resolutions, `proponer_zonas_tensionadas()` proposes the codes by matching the normalised names (postponed articles, bilingual forms) with INE's in their region; they are reviewed by hand. **Extensions** (plan §11, question 46 e): a declaration lasts three years and can be extended (art. 18, paragraph 3), and the extension reaches the BOE as a new resolution. It goes in as one more row, with the optional column `prorroga_de` (the resolution of the declaration it extends, for the same municipality and area). If its text counts the period from the end of the previous one, the gate checks it that way (`zt_desde_publicacion()`), and also that the extension has an earlier declaration and does not arrive once it has expired; the situation at 31 December joins all the periods of the municipality. As of 10-Nov-2026 there are none: the first declarations expire on 15-Mar-2027.

**Areas that are not a whole municipality.** Eight declarations cover only part of one: district 2 of Galdakao, Vitoria-Gasteiz except the rural area of the minor local entities, villages of Llanes (two declarations) and Cabrales, the neighbourhoods of La Arena and Cimadevilla in Gijón, La Magdalena in Avilés and Luanco in Gozón. The BOE does not give their geometry, which does not match the census tracts either, so the map paints the whole municipality with a category of its own, «declared in part of the municipality», and the profile gives the literal area.

**Long table** (`armonizar_zonas_tensionadas()`; target `larga_zonas_tensionadas`). The 8,131 municipalities of the 2021 tract map, from 2024 to 2026, with the situation on 31 December of each year: 2 if a declaration of the whole municipality is in force, 1 if only of part of it, 0 if none, also as `dato`, because the absence of a declaration is a published fact. No breakdown or other levels: a count of municipalities is no source's figure. Result: 271 municipalities declared in 2024, all in Catalonia; 304 in 2025 (302 whole and 2 in part), and 320 in 2026 (313 whole and 7 in part): Catalonia 271, Navarre 21, Basque Country 21, Asturias 5 and Galicia 2.

**Website.** Municipal map at every scale with the three categories (§9.2). The municipality's profile lists its declarations (BOE resolution, area, period in force and the community's declaration, with their links; `datos/zonas_tensionadas.json`, gate `web_zonas_tensionadas`) and says that it is a public policy layer, not a market measure.

**Portals' asking prices (indicator 13), removable and web-only layer** (plan §2.2; guide, rule 6; backlog, decision 3 and task 35). The pipeline downloads nothing from the portals. With the environment variable `PORTALES=TRUE` (off by default) it reads, outside git, the author's extraction of the rent reports in Idealista's press room, in `datos/brutos/portales/idealista/` (136,816 monthly figures in €/m², from January 2006 to October 2026, and 816 territories with their address), and any CSV files copied by hand in the layer's format (`R/fuente_portales.R`: portal, transaction, level, INE code, zone, name, period, price per m², report and link; sales and Fotocasa are left for v1.1, without data). Each Idealista territory is matched to its INE code by its address in `inventario/portales_idealista_territorios.csv`, matched by name and reviewed by hand: Spain, 19 regions (Ceuta only has a region page), 51 provinces, 286 municipalities, 449 zones and 10 localities that Idealista lists as municipalities but are not (`idealista_convertir()`).
- **Annual value:** the mean of the published months, with at least 9; with fewer, the year is `ausente` (`anualizar_portales()`). It replaces the previous rule, the last published month of the year, which is no longer used. The mean is rounded to two decimals with ties upwards (7.575 gives 7.58). The last year is the mean from January to October 2026; the website says up to which month it goes (`ultimo_mes`).
- **Levels:** Spain, regions, provinces and municipalities, from 2015 to 2026, each with the figure Idealista publishes for it (rule 1): nothing is aggregated or split. Municipalities with data: 262 in 2015, 259 in 2024 and 255 in 2026. Idealista's zones are not INE districts: they are kept with their municipality, without geometry, in a list for the municipality's profile (`portales_zonas()`). The eight localities within a single municipality go into that list, as zones; La Alcaidesa and La Manga del Mar Menor, which touch two municipalities, are not exported. With some data since 2015: 441 zones and seven localities, in 150 municipalities.
- **Web only:** the layer is not in the long table or anything that depends on it, nor in the downloads (the website's CSV and the Parquet), nor in the *release*: switching it on or off does not change the long table. It goes to its own folder, `datos/portales/` (`portales_exportar_web()`), with its manifest, the values by level and year, the link to the report of each figure and the zones by municipality; the website adds its series to those of the general manifest when loading. Off, the folder only holds an empty manifest (`portales_apagar_web()`). On the website, one municipal map per transaction and portal, with the label «private asking-price data» over the map, in the legend, the profile and the PNG; the CSV is not offered. A portal is never mixed with another, nor the asking price with SERPAVI, appraisals or deeds (rule 5).
- **Gate** (blocking): `portales_formato`, `portales_codigos`, `portales_rango`, `portales_repetidas` (no duplicate months), `portales_idealista_casados`, `portales_idealista_espana` (Spain: 7.58 €/m² in 2015 and 13.06 in 2024), `portales_idealista_municipios` (278 of the 286 municipalities, with a series from 2015 or earlier) and `web_portales`. Also tested with made-up data in `pruebas/` (`test-portales.R`).
- **What it measures** (Idealista's methodology of 30 July 2026): the asking price of the listings active in the previous three months, without seasonal rentals or duplicate listings; the median of each final zone, aggregated upwards with weights by number of listings. Months without a sufficient sample in a zone are estimated from nearby ones. The July 2026 method was applied backwards where the series required it, without saying from when.

**Moving-in indicators, bands only** (backlog, decisions 1, 5, 9 and 18, and task 37; `R/derivados_entrar.R`). With the layer on, the pipeline compares Idealista's asking rents (annual mean, above) with the SERPAVI rented stock (median for flats, §7.1) and with the income of the tokens (§6), by territory and year, with the terms as the website receives them (`termino_publicado()`; `entrar_terminos()`, `entrar_calcular()`):
- **Typical floor area:** median monthly rent / median rent per m² from SERPAVI. It is the ratio of two medians, not the median of floor areas, and they are the tenancy's m², not the listing's: the profile says so. Median of 77 m² in the municipalities with asking rents and SERPAVI in 2024.
- **Gap between moving in and staying** (`brecha_entrar_quedarse`): asking rent / SERPAVI median rent per m², in regions, provinces and municipalities (SERPAVI does not give Spain). It compares two sources that measure different things, the listing and the tenancy in force, and says so; it does not merge them into one figure (rule 5). Municipalities with both in the same year: 256 in 2015 and 259 in 2024. At 2 or more, the profile warns: in tourist municipalities asking rents may include seasonal lets and high-end housing, which SERPAVI does not cover.
- **Pay to move in** (`sueldo_entrar`): asking rent × typical floor area / 0.30, and its minimum with 50 m² (`sueldo_entrar_50`). **Barrier to moving in** (`barrera_entrar`): asking rent × 50 / net monthly income of the Minimum wage, Young adult or Pensioner token in the same year (rule 4), × 100, with the status of the asking rent, or `ausente` without income (`estado_peso_alquiler()`). Without a portal report or without SERPAVI that year, `ausente`.
- **Bands only** (decision 18). The exact figures do not leave the pipeline: with them the asking rent can be rebuilt (the gap, through SERPAVI rent, which is public; the 50 m² pay, through 0.30 / 50). Several sets of bands, one per indicator, would not do either: each indicator is the asking rent times a different public figure in each territory, so each set cuts the asking rent at different points and, together, they pin it down far more than any of them alone. Only the band of the gap reaches the website (`entrar_tramos_web()`): six bands, with cut points at 1; 1.15; 1.35; 1.6 and 2, and the gate limits, 0.8 and 2.5, at the ends (`inventario/entrar_tramos.csv`, under review). Each band spans at least 15%: with SERPAVI rent, it pins the asking rent down to ±7% of its centre at best.
- **Everything else as a range:** the pay to move in, the 50 m² pay and the barrier to moving in are the gap times a public «staying» figure (the pay needed, indicator 21, with its two figures: median monthly rent / 0.30 and the 50 m² minimum; the rent share of income, indicator 15), so the website gives them as the band limits times that figure (`entrar_intervalo()`), which say nothing the band does not. The barrier is read with the «Can you make rent?» bands (up to 30%, 30 to 40% and over 40%) and, if the range crosses a cut point, «on the edge» (`entrar_llega()`). The same goes for the pay the user types («Your token»), which thus does not need the exact asking rent in the browser.
- **Website:** `datos/portales/entrar/`, inside the layer (`entrar_escribir_web()`): one file per level and year with the band of each territory, and the `entrar` entry of the layer's manifest. Not in the long table, the downloads or the *release*. The interface belongs to tasks 38 and 39.
- **Gate** (`entrar_comprobar()`, `entrar_comprobar_web()`; §4.1). Blocking: `entrar_tramos` (minimum width, and derived figures without cut points of their own), `entrar_rango` (gaps outside 0.8–2.5), `entrar_estado`, `entrar_coherencia` (each exact figure, inside the range of its band), `entrar_municipios`, `entrar_mediana`, `entrar_mediana_rango` (the 2024 median, between 1.30 and 1.40), `entrar_superficie` and `web_entrar` (round trip of the bands and no value that is not a band). Warning: `entrar_rango_detalle` (each gap of 2 or more) and `entrar_ipva`, the contrast from task 36: provinces where asking rents grow from 2021 to 2024 more than twice as much as INE IPVA new tenancies (§7.7), chaining their annual changes. R and the page do the same arithmetic: `test-entrar.R` and `pruebas/web/entrar.test.mjs` share the made-up cases of `pruebas/datos/entrar_inventado.json`.

### 7.9 Historical module: the «time machine» (F6)

**Its own table, not the long table.** The module's series are national (the appraised value, also regional), quarterly, monthly or annual, and do not go down to census tracts. The `anio` of the long table is annual: adding quarters or months would force them to be averaged or would mix periods within one year (rule 4). They go into their own table (`hist_armar()`; target `historico`, also in `datos/intermedios/historico.parquet`) with `serie`, `geo_id`, `nivel`, `frecuencia`, `anio`, `subperiodo` (quarter, month or 0), `valor`, `unidad`, `fuente`, `codigo` and `version`, and the full grid of periods from the first figure to the last (`hist_completar()`). Each series keeps its source, unit and period: they are not combined into an indicator (rules 4 and 5). The table goes into the v1.0 *release* package as `historico.parquet`, in `descargas/` (`empaquetar_publicacion()`; plan §11, question 47 a).

**Banco de España affordability** (`bde_accesibilidad`; `hist_leer_bde_tablas()`, target `series_bde`). Table «Real estate market indicators» of the Summary indicators (`si_1_5`), as a CSV with a stable address, quarterly since Q1 1987:
- years of income (`D_TKB57110_IPV`): average price of a standard open-market home (93.75 m² until 2004, by interpolation; afterwards, the average floor area of registered sales) divided by the estimated gross income of the median household, which the Banco de España derives from the Survey of Household Finances, interpolated and extrapolated with the National Accounts and the Labour Force Survey;
- theoretical annual burden without deductions (`D_TKB57210_IPV`): first-year payments on a loan for 80% of the value, French amortisation, at the average rate on new housing loans and the average mortgage term, as a percentage of the disposable income of the median household.

The series with the main-residence tax deduction (in force until December 2012), cited in the Banco de España methodological note, is neither in the CSV nor in its API: the atlas only has the series without deductions. The Banco de España does not publish these indicators by region. Break `bde_tipo_circular_2003`: the new-loan rate used for the burden is reported under Circular 8/1990 until December 2002 and under Circular 4/2002 from January 2003. Reuse: the terms of use of the Banco de España statistics allow reuse without altering the content or the metadata, citing the source («own elaboration with data extracted from the Banco de España website») and the update date, without suggesting that it takes part in the atlas.

**Press figures in the plan, checked against the series** (plan §2.5 and §10.2; `inventario/historico_referencias.csv`):

| Press figure | Banco de España series (November 2026 table) | Check |
|---|---|---|
| Less than three years of income in 1987 | 2.90 in Q1 1987; 3.00 in Q2 | `hist_prensa` |
| 9.45 years of income at the 2007 record | 9.46 in Q3 2007, the series high | `hist_prensa` |
| 72% burden in June 1990 | 72.47% in Q2 1990, the series high | `hist_prensa` |
| 7.6 years of income in 2023 | Does not match: 7.24, 7.16, 7.11 and 6.97 (2023 mean, 7.1); 7.6 is the 2025 mean | none |

**Interest rates** (`bde_accesibilidad` and `bde_tipos_referencia`; same reader; plan §11, question 47 c as revised). Main line: the rate on new loans to households for house purchase (`D_IMVTIPLV`, in table `si_1_5`, monthly since January 1989), the same one the Banco de España uses for the theoretical burden: 17.05% in January 1991 (high) and 1.50% in December 2021 (low), with the break `bde_tipo_prestamos_2003` in January 2003 (from Circular 8/1990 to 4/2002), the same as the burden's. As a reference, a single line with two different indices: one-year MIBOR up to December 1998 (`D_1E723706.EUR`) and 12-month Euribor since January 1999 (`D_1NBAF472`, table `be1901`), each month with its code and the change marked (break `bde_mibor_euribor_1999`; `hist_enlazar_mibor_euribor()`). The MIBOR followed the Euribor from 1999, up to 0.14 points apart until July 2013, and matches it since August 2013. High, 16.43% in May 1987 (MIBOR); low, −0.505% in January 2021 (Euribor). The module table keeps the official reference rate on mortgage loans over three years for buying open-market housing (`D_1T9H0000`, since November 1990; annex 8 of Circular 5/2012), which the page no longer draws: 16.92% in January 1991 (high) and 1.412% in November 2021 (low); August 2026, 3.134%, the figure in the Banco de España resolution published in the Official State Gazette (`BOE-A-2026-19481`).

**Appraised value since 1995** (`mivau_valor_tasado`; `hist_valor_tasado()`). The quarterly reading from F4 (target `valor_tasado_trim`, §7.7) since Q1 1995, for Spain and the 19 regions and autonomous cities, in euros per m² and not turned into years; figures outside the plausible range of F4 are left without a value. Spain: €670.8 per m² in Q1 1995 and €2,355.0 per m² in Q2 2026.

**Average gross wage per employee** (`ine_cne`; `hist_leer_ine_cne()`, `hist_sueldo_asalariado()`). Annual Spanish National Accounts, base 2020 (INE tables 71129 and 71133): wages and salaries of the whole economy divided by the employees of the same year (rule 4), since 1995. It is the longest official series that measures the same thing every year: ESA 2010 in base 2020, with no breaks; the latest years are provisional and INE revises them every September. It is not the AEAT average wage (indicator 7, since 2011): it counts every employee of the year, including those who work part of it or part-time, and it comes from the national accounts, not from withholdings. €15,635 in 1995, €21,699 in 2007, €31,200 in 2024 and €32,706 in 2025. It lies above the AEAT average wage (€24,962 in 2024): it divides by the average number of employees over the year, so someone who works a few months counts only for that share, and it includes the Basque Country and Navarre, which the AEAT does not cover. The page says so, and that the series starts in 1995 (plan §11, question 47 d).

**Gate** (`hist_comprobar()`, target `validacion_historico`; `hist_comprobar_ine_cne()`, target `validacion_cne`; `hist_comprobar_web()`, target `validacion_web_historico`): the `hist_*` and `web_historico` checks in §4.1, with the published figures in `inventario/historico_referencias.csv`. Result (10 Nov 2026): all blocking checks pass. The 21 figures of the Banco de España PDF table and the Gazette one are reproduced; the MIVAU appraised value equals the one reproduced by the Banco de España in the 126 common quarters (maximum difference, €0.0 per m²), and the National Accounts add up without differences. The `hist_valor_tasado_ccaa` warning flags 15 quarters: 14 of regions that MIVAU publishes outside the range of their provinces, compared only when all their provinces have a figure (the Valencian Community from 1995 to 1997, Andalusia in 1995 and Extremadura in 1999, 2000 and 2012), and one without a figure for Melilla (2013). F4 checks the same, as blocking, since 2015 (`valor_tasado_ccaa`). Since 11-Nov-2026, a Banco de España revision (`hist_publicadas`, `hist_publicadas_enteras` and `hist_prensa`) warns and asks for the reference in `inventario/historico_referencias.csv` to be updated, without blocking (plan §11, question 47 g).

**Website** (`hist_exportar_web()`, target `ficheros_web_historico`). Page `historico.html`, «Time machine», without a map: one chart per block, all on the same time axis since 1987, with the key dates from `inventario/historico_fechas.csv` (highs and lows, checked against the series; breaks; and the end of the housing tax deduction), a reading without value judgements (first figure, high, low and latest) and the table of figures; the appraised value, also by region. The data go into `datos/historico/historico.json`, each series and territory as integers (× 100 years of income and burden, × 1,000 rates, × 10 appraised value; the wage, in euros). The «The Euribor goes up» square on the front page leads to its rates, and the Banco de España figures carry the citation its terms of use require.

### 7.10 CIS barometers: housing as a problem (F6)

**What is measured.** The monthly barometer of the Centro de Investigaciones Sociológicas (CIS) asks, with spontaneous answers and up to three mentions, «What, in your opinion, is the main problem in Spain today? And the second? And the third?» and «And which problem affects you personally the most?». The series takes the TOTAL column of the «La vivienda» (housing) category, which is different from «La ocupación de viviendas» (squatting): the share of respondents who name it in any of the three mentions. This is the sum of the three columns, because nobody repeats a problem. It is an opinion survey, not a register: it measures how often housing is named, not its price. It is national and monthly, with no barometer in August, and it is not part of the tract-level long table: it has a table of its own (target `cis_vivienda`; `cis_serie_vivienda()`).

**Source and reading** (`cis_descargar_estudios()`, `cis_leer_barometros()`; targets `cis_estudios` and `cis_barometros`). The page of each barometer lists its documents in JSON-LD, under a CC BY 4.0 licence; it is stored in `datos/brutos/cis_barometros/estudios/`. Each study is read from its XLSX tabulations («Resultados y cruces verticales», from February 2025, at full precision) or, without them, from its HTML results (January 2014 to January 2025, with one decimal; `cis_leer_xlsx()`, `cis_leer_html()`). The tables come in two layouts, with the problems in rows or in columns, and with changing headers («Primer problema [recod.]» in 2024): the reader handles all of them. Before 2014 there are only scattered open results (2009, 2011 and 2013) or microdata, so the series starts in January 2014.

**What is not used.** The CIS series catalogue is protected against automated access, and the data of its series pages are served through a path that `robots.txt` excludes. The microdata of each barometer, which would give the figure by autonomous community, require a form with an e-mail address and the acceptance of conditions: they are left out, and the comparison by region is still pending.

**Result** (10 Nov 2026). There are 134 barometers from January 2014 to October 2026: 126 months with a figure for Spain and 128 for the personal question (112 and 114 from the HTML; 14 and 14 from the XLSX); with the six months transcribed from the PDFs (below), 132 and 134. Housing rises from 1.5% in January 2014 to 11.5% in May 2023, 28.3% in January 2025, 48.9% in May 2026 and 55.7% in October 2026 (55.65 in the tabulations), the highest in the series; in the personal question, from 1.6 to 33.8%.

**PDF-only months.** July 2014 and February, April, May, June and July 2025 only publish their results as PDF (the CIS link to its tabulations fails and there is no HTML). They are transcribed by hand, without a PDF reader (plan §11, question 48 a), in `inventario/cis_transcripcion_pdf.csv`: the «La vivienda» row of both questions, with the page, the link to each PDF of marginal distributions, its size, its SHA-256 sum and the check of each row (the sum of the three problems against the total; two rows, also checked by eye on the page). `cis_aplicar_transcripcion()` adds them to the series with format `pdf_transcrito`, and the `cis_vivienda_pdf` gate checks them (`cis_comprobar_transcripcion()`). Housing, in those months: 1.6 and 1.7% in July 2014; from 25.6 to 34.1% (Spain) and from 18.3 to 22.5% (personal) in 2025. **Gaps.** None for lack of open results (warning `cis_vivienda_cobertura`). April and May 2020 do not include the «La vivienda» category in the Spain question (warning `cis_vivienda_categoria`) and are left out of the series: the category is missing, which is not a measured zero. Seven months have no barometer: July 2016; March, April, October and December 2019, and June and September 2023 (warning `cis_vivienda_meses`).

**Gate** (`cis_comprobar_vivienda()`; target `validacion_cis`). The five figures in the CIS press releases of 28 Jan 2026 and 14 Sep 2026 (January 2026, 42.6 and 28.2%; September, 37.5 and 27.9%; July, 37.5 + 5.5 = 43.0%) match exactly (`cis_vivienda_publicada`, ±0.1 points). The total differs from the sum of the three mentions by at most 0.1 points in the HTML and 0.045 in the XLSX (`cis_vivienda_suma`, ±0.2 points). No figure is out of range and no month has only one question (`cis_vivienda_rango`). If the month of a press release is missing, its figure goes to the coverage warning, and the gate only blocks if none can be checked.

**Website** (`cis_exportar_vivienda()`; target `ficheros_web_cis`). The file `datos/cis_vivienda.json` holds the two series (period, figure with one decimal, study and interviews), the source, the licence and the date of the latest barometer. It sits outside `datos/historico/`, which its own export deletes. Round trip: `cis_vivienda_web` (target `validacion_web_cis`), also for the study and the interviews of each month. The `historico.html` page now shows it, in the «Housing as a problem (CIS)» block after the historical series: both questions in a monthly chart on the same time axis since 1987, broken in the months without a figure (August does not count: there is no barometer); on hover or with the keyboard, the month, both figures, the study and the interviews; a reading without value judgements (first figure, high, latest and months without a figure), the CIS citation with its licence, the «opinion, not a register» warning and the table of figures. Without the file, the block says there are no data.

## 8. Known limitations

**Constant geography:**
- **Residual errors.** `estimado` figures carry a residual error. In the one-year test for all of Spain, 37 of the 6,180 tracts that the street register splits remain outside [0.8; 1.25] with the combined table (§3.9). Four or five years apart, that error cannot be separated from the real growth of neighbourhoods.
- **The Cadastre is a current snapshot** (`inventario/fuentes.csv`, period «actual»). Buildings demolished before the download are missing. The year of construction is the original one (`beginning`), even if the building was refurbished or extended. 1,574 buildings have no year and count in all tables.
- **The closure test is weak by construction** (§3.9). Detection of distribution errors relies on the one-year test.
- **Tracts outside the series.** The nine ADRH orphan tracts are left out of the conversion table. The two coverage exceptions leave one 2021 tract without data in six tract-years (§3.8) and one without tourist dwellings (§7.3).
- **Boundary changes after 2021.** Tracts that change after 2021 are drawn with their 2021 boundaries (§3.1).

**Hierarchy and base map:**
- Districts have no name (§3.10).
- Below zoom 12, borders are simplified by half a pixel; above it, MapLibre overzooms the zoom 12 tiles (§3.10).
- **Land without a tract** (§3.10): 1,495 km² of common land have no tract and no data and show as «no data». They are not divided between provinces when they touch several, and those touching the coast or the border are not detected. The IGN names cover 1,176.5 km²; thin unnamed strips remain along the edges, where the IGN and INE lines do not match.

**Income:**
- **The source does not match across scales.** ADRH does not always add up its tracts to the municipal total (`adrh_suma_secciones`, 160 municipality-years in 2015–2019). Its aggregated tract means move more than 5% away from the municipal figure in 135 figures (`adrh_municipio_detalle`). The atlas does not correct this: it shows the published figure at each scale.
- **Approximate households.** They come from a mean household size rounded to one decimal (§5.1).
- **Basque Country and Navarre in 2015–2019.** ADRH does not publish them by tract in those years: those tracts are `secreto` (§5.4).
- **Income distribution (4–6), foral gaps.** Navarre until 2020, Álava until 2019 and Gipuzkoa in 2015 are `ausente`; Spain has a figure from 2021 (§5.5).
- **Threshold of indicator 5.** It changes in 2023, from the median of the common tax territory to that of all of Spain, and in 2024 more tracts are published (§5.5).
- **Approximate weighting of indicators 4 and 5.** They are reprojected with the ADRH population, not the one INE finds in the records; aggregated to municipality, 98 figures move more than 1 point away from the published one (`adrh_dist_municipio_detalle`).

**Rent:**
- **Stock, not new contracts.** SERPAVI measures the rented stock: newcomers pay more (indicator 8).
- **Only landlords who are natural persons** (Housing Ministry methodology of 18 March 2026). SERPAVI does not count lettings by companies and other legal persons, including public housing, nor undeclared lettings or lettings to relatives. In 2021 it captures 77.6% of the Census renting households, from 36.0% in Melilla to 118.9% in Salamanca, although the gap mixes other causes; there is no open table of the rented stock by type of landlord and municipality to flag where it weighs most (§7.1).
- **Confidentiality and coverage.** In 2024, 4,849 tracts have the apartment median under confidentiality. Coverage ranges from 19.4% of tracts in Soria to 95.4% in Gipuzkoa: rural areas have fewer data (§7.1).
- **Two building types with no joint median.** The default map shows apartments; single-family houses go separately (§1).
- **Foral territories.** Short series: Navarre since 2021, Gipuzkoa since 2022, Álava and Bizkaia since 2024 (§7.1).
- **Territories missing from the source.** 40 tracts of 2021, 36 districts and 36 municipalities are not in the SERPAVI database: they go as `ausente` (§7.1).
- **Errors of the source.** 164 figures of municipalities and districts go as `ausente` (§7.1).
- **Approximate margin.** The margin of the median assumes a regular distribution within the tract and does not correct for current rather than new tenancies; with few contracts it is only an order of magnitude. In 2024, 4,407 apartment medians come from fewer than 30 contracts (§7.6).

**Renting households:**
- It is a snapshot of 2021, not a series (§7.2).
- 1,363 tracts are under confidentiality, mostly in rural provinces (§7.2).

**Tourist dwellings:**
- **Different years.** The denominator is the 2021 Census dwellings (§7.3).
- **Platform listings.** It is an INE experimental statistic built from listings, not a register (`inventario/indicadores.csv`).
- **Short series.** It starts in February 2024; from 2020 to 2023, in F6 (§7.3).
- **Different months.** Reference months changed in 2024 (§7.3).
- **Splitting.** 877 tracts are `estimado` in each period (§7.3).
- **Denominator of regions and provinces.** Since November 2024 INE counts the dwellings of the Census tracts under confidentiality, which are not published: in 33 provinces and 12 regions the gate only bounds the figure from above, and the change of criterion moves that of Soria by up to 0.11 points (§7.3).

**Derived indicators:**
- **Inherited gaps.** A derived indicator has no value where any of its terms is missing: in 2024, 10,208 of the 36,333 tracts have no burden (§7.4).
- **Vulnerability, not moving in.** The burden divides rent by the average income of all households in the tract, not only of those who rent (`inventario/indicadores.csv`).
- **The rent share in the long table is a check.** With the Minimum wage, Young adult and Pensioner tokens from 2015 to 2024; the website computes it with the chosen token (§7.4).
- **The same share for every income.** The 30% threshold of indicators 15 and 21 does not say whether what is left covers other expenses, and it weighs more on low incomes (residual income approach; §7.4).

**Wages (indicator 7):**
- **No Basque Country or Navarre.** AEAT does not cover them, and of the foral tax authorities only Gipuzkoa publishes a comparable figure (§5.6).
- **Pay received in the year.** It is a mean that includes people who worked only a few months, not the wage of a full-time job.

**Young adult token:**
- **Assumptions:**
  - from 2015 to 2018, the median-to-mean ratio is that of 2019;
  - the median-to-mean ratio of the SME of a region holds for all its provinces;
  - the distribution within each national decile is that of the country;
  - payroll withholding is the average of all ages;
  - the contribution is that of a permanent contract.
- **Coverage.** No Basque Country, Navarre, Ceuta or Melilla (§6.2).
- **Pay received in the year.** The token uses pay received in the year, which includes people who worked only a few months; the token says so in its method line, on the home page and on the map: «pay received in the year by employees aged 26 to 35 in their province, including those who did not work all twelve months».
- **Weak check before 2022.** The 2016 to 2022 ECV waves have smaller samples: the token of a region moves more than 15% away from the survey median in 32 figures, though that of Spain stays between −5.9 and +7.2% (§6.2).

**Pensioner token:**
- **Pensions, not pensioners.** Someone with two pensions counts twice, and the province is that of the provincial office that manages the pension (§6.5).
- **Withholding of all pensioners.** AEAT does not separate retirement; in the Basque Country and Navarre, the curve is that of Spain (`estimado`; §6.5).
- **Own home.** The great majority of people aged over 65 do not rent: the token answers “if I had to rent today” (§6.5).

**Token years.** The Minimum wage, Young adult and Pensioner tokens have an income for each year with rent data, from 2015 to 2024 (§7.4); the Young adult and Pensioner tokens reach 2025 and the Minimum wage token, 2026.

**Wage percentile.** It counts people who worked only a few months, so low percentiles are small amounts; within each wage band a linear density is assumed; the Basque Country and Navarre (and Ceuta and Melilla in 2020 and 2021) use the Spain curve (§6.6).

**Licences.** The State Cadastre and the foral cadastres of Bizkaia and Gipuzkoa have contradictory licences and are treated as open data by decision of the author (§2.2; withdrawal plan, §2.4).

**Overburden.** It is published without confidence intervals. The income quintile uses HY020 ÷ HX240, not Eurostat's HX090, which INE does not publish, and puts an income equal to a cut-off in the upper quintile, so that all 15 figures match Eurostat's to one decimal. The Spanish series is broken in 2013, the year in which the way incomes are obtained changes, although Eurostat does not flag it (§7.5).

**Home purchase.** The price is the appraisal, not the price in the notarial deed: the Notaries' websites reserve all rights and ask for express authorisation; indicator 11 comes from the Land Registrars, by province (§7.7). The year of the appraised value is an average of quarters that the Ministry does not publish. Years of wages use the province's individual gross wage, not household income, and do not cover the Basque Country or Navarre; neither does the IPVA. Mortgage payment over household income uses ADRH household income, estimated from the municipalities where INE does not publish it (Spain until 2020 and the foral territories not yet fully covered). The Land Registrars' sale price (11) only reaches the province.

**Stressed areas.** The eight declarations of part of a municipality are painted on the whole municipality, with a category of their own (§7.8). Only what is published in the BOE comes in: the declarations a community has published after 30 September 2026 will arrive with the fourth-quarter resolution, and refused applications appear in no resolution. The long table is a snapshot on 31 December; the exact dates are in the profile and in the inventory.

**Asking prices.** It is the asking price of listings, not a closing or contract price, and its mean changes with the type of home advertised (§7.8). Idealista publishes 286 municipalities, home to 59.3 % of the population (ADRH 2024); the rest has no data. The last year is partial (2026: January to October). Idealista's general terms require its written permission to include its content in another website and to deep-link its pages: it is still to be requested before the layer is published.

**Other housing costs (author's decisions, 12 Nov 2026; §6.7).** The method decisions behind the switch: the median rather than the mean (in 2024, 145.3 against 154.1 € in Spain), so that a few households with high costs do not move the figure; market-rate renters only, without reduced-rent ones; Spain's median for each wave times a regional factor drawn from the ten waves pooled, rather than each region's median in each wave, which jumped by up to 46.8 € from one wave to the next; a minimum of 50 observations, the EU-SILC convention; and the survey year as the rent's year. It is one figure per region, not per neighbourhood, and it is added to a median rent: the sum of two medians is not the median of the sum. The cut-offs of the pay-needed map do not change with it: in 2024, with the 30% threshold, the median tract goes from 1,900 to 2,372.7 € and the top band from 25.4 to 48.8% of the 26,137 tracts with data.

**Lag.** Income and wages run one or two years behind the current year (§1).

**Euros of each year and base-year euros.** Series in euros (income, wages, rent and pay needed) are published in euros of each year: so are the map, the legends, the home page cards, the stories, the downloads and the long table. Since 12 Nov 2026 (author's decision) they are also offered deflated, with a «{base year} euros · Euros of each year» switch, in two places: the Time machine, for the appraised value and the average wage, which open in base-year euros, and the profile's chart over time, for series in euros, which opens in euros of each year so that it matches the map. Index: annual averages of the INE national general CPI (table 76144, base 2025). Base year: the last year with a published annual average (currently 2025). Calculation: figure × base-year index / index of its year; a quarter uses the annual average of its year. Years without an annual average are left out of the deflated version and the chart note says so: those before 2002, because INE gives no index in base 2025 before January 2002 (its series «since January 1961», table 24077, is empty up to December 2001) and it is not spliced with earlier bases, and the current year, until its average is published in January. In 2025 euros, the appraised value of the first quarter of 2002 goes from 1,051.7 to 1,751.8 €/m² and that of the fourth quarter of 2025 stays at 2,230.0; the average wage of 2002, from 18,795 to 31,306 €, and that of 2025 stays at 32,706 €. From 2015 to 2024 the CPI rose 23.5%; from 2002 to 2025, 66.6% (§9.2; backlog, task 45).

---

## 9. Long table and website data

### 9.1 Long table

**Schema** (plan §6.4): `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo`, `valor`, `estado`, `fuente`, `geo_ref` and `version`. The key of a row is `geo_id`, `nivel`, `anio`, `indicador`, `corte` and `grupo`.

**Content** (`tabla_larga`; `exportar_tabla_larga()`, `datos/intermedios/tabla_larga.parquet`): 11,483,367 rows, plus 254,835 from task 47 (11 Nov 2026; §3.11).

| Source (`fuente`) | Rows | Levels | Version |
|---|---|---|---|
| `ine_adrh` | 2,634,650 | Tract (2,179,944), municipality (452,546), province (1,560), region (570) and Spain (30) | 7 Nov 2026 (1–3) and 9 Nov 2026 (4–6) |
| `mivau_serpavi` | 5,032,640 | Tract (3,419,452), district (926,724), municipality (676,872), province (7,032), region (2,540) and Spain (20) | 6 Nov 2026 |
| `ine_censo2021` | 36,405 | Tract (36,333), region (19), province (52) and Spain (1) | 8 Nov 2026 |
| `ine_vut` | 436,860 | Tract (435,996), region (228), province (624) and Spain (12); half of them for 2020–2023 (task 47) | 8 Nov 2026 |
| `ine_censo2011` | 36,405 | Tract (36,333), region (19), province (52) and Spain (1) | 10 Nov 2026 |
| `ine_ecv` | 261 | Region (228) and Spain (33) | 6 Nov 2026 |
| `ine_ecv_modulo` | 32 | Region (19) and Spain (13) | 6 Nov 2026 |
| `aeat_mercado_trabajo` | 2,016 | Province (1,456), region (532) and Spain (28) | 9 Nov 2026 |
| `ine_ipva` | 12,438 | District (4,070), municipality (7,180), province (864), region (306) and Spain (18) | 10 Nov 2026 |
| `mivau_valor_tasado` | 4,048 | Municipality (3,256), province (572), region (209) and Spain (11) | 10 Nov 2026 |
| `zonas_tensionadas` | 24,393 | Municipality (24,393) | 10 Nov 2026 |
| `calculo_propio` | 3,518,054 | Tract (2,436,386), district (568,152), municipality (506,960), province (5,076), region (1,460) and Spain (20) | 7 Nov 2026 |

**By status:** `dato`, 8,507,796 rows; `ausente`, 1,690,991; `secreto`, 1,233,209; `estimado`, 51,371.

**Publication.** The long table is published in the GitHub release `v0.1.0` (9 Nov 2026), and the website at `https://gastiaso.github.io/de-renta-en-renta/` (`docs/publicacion.md`).

### 9.2 Website data

The export follows the author's decisions of 8 Nov 2026 (plan §6.6; plan §11, questions 16 and 17). `exportar_web()` (target `ficheros_web`) writes into `web/datos/`, from the validated long table, the v0.1 core indicators and those with a map (`cortes_web` column and tract figures: indicators 4–6 of F3, since 9 Nov 2026), from tract to Spain:
- **Values.** One JSON file per series, level and period, with values × 10 as integers (× 100 for tourist dwellings, with two decimals, as INE publishes them: column `escala_web` of `inventario/indicadores.csv`, empty for the rest; plan §11, question 24), with the rounding of the guide to those decimals, and a string with the status of each unit, in the order of the index of its level. Compressed, it weighs the same as a binary (plan §11, question 17): each tract file takes 139 to 291 KB, and 19 to 98 KB with gzip.
- **Spain, regions and provinces.** Indicators 18 and 19 carry the published figures for Spain, the 19 regions and the 52 provinces (§7.2 and §7.3); those for Spain, in seven files. Rent (8 and 9) and pay needed (21) have regions and provinces but not Spain: SERPAVI publishes only its count of observations, which goes in the contracts series (§7.6). Income (1–3) and rent burden (14) go up to the municipality (§5.3 and §7.4). Income distribution (4–6) carries the published figures for regions, provinces and, from 2021, Spain (§5.5).
- **Sheet series.** One file per municipality (`fichas/<municipality>.json`) with the series of its tracts and of the municipality itself.
- **Reliability** (§7.6). The contracts and margin of the median go as auxiliary series of each rent series, of its same housing type (`fiabilidad` in the manifest), with no indicator number or map of their own. They are not in the per-municipality files, where they would weigh a quarter more: the tract profile reads them from the files of the period the map shows.
- **What is not exported.** The SERPAVI quartiles and the rent share of income (15), which the website computes with the chosen token. Pay needed (21) is recomputed in the browser when the threshold or the floor area change (`FORMULAS_WEB`): the main figure, from monthly rent, and the minimum alongside (`minimo` of the map), from rent per m² (task 40).
- **Website against R.** The website test (`pruebas/web/datos.test.mjs`, in node) recomputes with the page's own module, `web/js/formulas.js`, the pay needed from the base of its map (since task 40, monthly rent) in all tracts, districts, municipalities, provinces and regions from 2015 to 2024, and compares it with the one exported by R: 550,140 unit-years, 294,082 with a value, with no difference in value, nulls or status (plan §6.5). In addition, `comprobar_web_navegador()` opens the page in headless Chrome (`chromote`): with its own modules, it recomputes a sample of 300 tracts over the 10 years and reads their contracts and margin, and it opens six tract profiles. Locally and on the published site everything matches the long table, with no errors (9 Nov 2026; `docs/publicacion.md`).
- **Downloads.** The website downloads the map series as CSV, at the level in view (value with the precision of the series, status and source; for the rent series, contracts and margin; for indicator 21, floor area and threshold and the 50 m² minimum alongside, `valor_minimo`), and the map as PNG with its legend and source. With «Your token», neither carries the pay entered: the CSV gives the rent, not the ratio. The colours of the «Can you make rent?» PNG do let it be roughly inferred, so with «Your token» it is downloaded after a warning that can be cancelled (plan §11, question 23).
- **Year outside the series** (plan §11, question 32). With a year earlier than every period of a series (2020 for tourist dwellings), the map, the legend, the sheet, the comparison panel and both downloads show «no data» and say when the series starts; the CSV, with one row without a value per unit and the start of the series in the status column. With a later year, the last period is taken, and the legend says so.
- **Other files.** Unit names, municipality bounding boxes for the search box (`cajas_municipios`) and token incomes (`perfiles`), for each year (`anios`), so that the website uses that of the rent year, and the wage percentile curves (`salarios_web()`, `datos/salarios.json`; §6.6). The base map is copied to `web/teselas/`; on publication, it comes from a *release* (§3.10).
- **Volume** (`ficheros_web`, 9 Nov 2026): 8,970 files and 147.7 MB, including the PMTiles file (35.4 MB). On disk, `web/datos/` holds 9,354 files and 113.6 MB: the 8,969 of `ficheros_web` (112.3 MB; the per-municipality files, 57.9 MB), the 3 of the overburden section (`ficheros_web_sobrecarga`, 1.1 MB) and the versioned sample in `web/datos/ejemplo/` (382 files, 0.2 MB). The contracts and margin (§7.6) add about 17 MB, and the income distribution (§5.5) about 21 MB, 14 of them in the per-municipality files.
- **Gate** (`comprobar_web()`, `validacion_web`): `web_valores` and `web_fichas` (blocking) and `web_fuera_indice` (warning); the percentile, `web_salarios` (`comprobar_salarios_web()`, `validacion_web_salarios`, blocking) (§4.1).
- **Front page** (`exportar_portada()`, target `fichero_portada_web`; 10 Nov 2026). The three front-page cards carry figures from the long table, with the rounding of the guide, in `web/datos/portada.json`: in 2024, the median of the 26,137 tracts with data requires €1,900 net a month with its median monthly rent and the 30 % threshold (10th percentile, €1,234.7; 90th percentile, €2,976.5; R quantiles of type 7), and €1,216.7 with the 50 m² minimum, alongside (task 40); with the 2024 minimum wage (€1,237.4 net a month), the rent of 50 m² takes more than 30 % of income in 48.4 % of those tracts and more than 40 % in 24.7 %, and median monthly rent, in 89.9 % and 66.7 %; in the 2025 ECV, overburden is 26.8 % among tenants at market price and 7.2 % overall. The squares come from `inventario/casillas_portada.csv` (`escribir_casillas_portada()`, target `fichero_portada_html`). Gates `portada_valores` and `portada_casillas` (blocking, `validacion_portada`; §4.1).
- **Maps without tracts and category maps** (F5, 10 Nov 2026). The mapped series (column `cortes_web`) without tracts, indicator 20 and the home-purchase ones 10, 12, 16 and 17, carry `nivel_minimo` in the manifest: the website paints municipalities and lets users click them at every scale and switches tracts off, and a chosen tract is shown in its municipality's profile. Without municipalities, indicator 11 (Land Registrars; task 46, 11 Nov 2026) carries `nivel_minimo` «provincia»: the website paints provinces at every scale, switches municipalities and tracts off, and a chosen tract is shown in its province's profile. Indicator 20 also carries `categorias`, with the text of each value from `inventario/vocabulario.csv` in both languages, and `detalle`, its declarations (`datos/zonas_tensionadas.json`, 195 KB). The portals layer, with `PORTALES=TRUE`, gives one map per transaction and portal from its own folder, `datos/portales/` (§7.8). Home-purchase euros per m² are shown without decimals, and years of wages with one.
- **Profile by level** (backlog, task 26). At low zoom, the map colours and lets users click regions, provinces and municipalities with the figure published at their level, the same as in the value files; if a series that gives the colour does not reach that level, the profile says «no data at this level» and does not add up tracts (§5.3). In a region, the tokens with a provincial income (Young adult and pensioner) have no figure.
- **Map classes** (backlog, task 51; the author's decisions 13 to 15). Seven classes with cut-offs fixed across years and three sets per indicator, one per scale: tract, municipality, and province and region (`inventario/cortes_web_niveles.csv`, `leer_cortes_niveles()`; `juegos` of each map in the manifest). Each map layer is coloured with the set of its level, and the legend with that of the scale in view: zooming in or out changes its scale bar and says so. Method of each set: `recalibrado`, septiles of all years, if in the latest year no class holds more than 30% and in the first, more than 35%; otherwise `anclado`, sextiles of the latest year and a low cut-off at the median of the first, or `anclado_septiles`, septiles of the latest year, where that low cut-off leaves the first class empty in the latest year (provinces and regions for monthly rent, rent change and pay needed). In the anchored sets, the first years gather in the low classes (the rise over the decade, in current euros) and the legend says so: «bands set with the latest year». Cut-offs do not move when a new year comes in; they are reviewed at each major version. Without sets: tourist dwellings (very skewed distribution), stressed areas (categories) and overburden (own section); the «moving in» gap keeps the six classes of `inventario/entrar_tramos.csv` (§7.8). Seven-step ramp (`diseno/tokens.json`): the ends of the five-step ramp and five points along its OKLab path, at least 0.075 apart between neighbouring steps under simulated deuteranopia and 0.081 with normal vision; with those ends, seven single-hue steps cannot reach 0.08, and `rampa_daltonismo` requires 0.07. Gate `web_tramos` (warning; `comprobar_tramos_web()`, target `validacion_web_tramos`): by map and set, in the latest year, no class empty or with more than 35% of the units with data (provinces and regions together). Also, no tract outline below zoom 9, a loading indicator, the legend open on arrival (on phones, below the map) and an initial view including the Canary Islands.
- **Classes relative to the municipality** (the author's decision, 11 Nov 2026; `web/js/escala_municipio.js`). With the tract cut-offs, almost all of Madrid and Barcelona falls in the top class: for 2024 monthly rent, 87% of Madrid's tracts and 95% of Barcelona's. At tract scale, the legend offers to colour tracts with the septiles of those of one municipality, for the year and series in view, computed in the page; the national scale, the comparable one, stays the default. The governing municipality is that of the panel (the tract's, or the municipality chosen) and, with no panel, the one at the centre of the view. Only on maps with a tract set of cut-offs (not tourist dwellings, stressed areas, overburden or the portals layer) and in municipalities with 14 tracts with data or more (two per class). Cut-offs rounded to the largest step of 1, 2, 2.5 or 5 times a power of 10 that is no more than half the narrowest gap between cut-offs nor than a quarter of the median one. The legend gives its cut-offs and says «bands for <municipality>, not comparable with other municipalities»; tracts outside are left uncoloured, and the PNG and the link (`escala=municipio`) carry the chosen scale. On single-scale maps (11, provincial), a municipality or a tract chosen in the search box opens its province's panel (`nivel_minimo`).
- **Euros of each year, base-year euros and CPI** (backlog, task 45; author's decision of 12 Nov 2026; `ipc_exportar_web()`, target `ficheros_web_ipc`). The atlas series are published in euros of each year. With `datos/ipc.json` (the annual averages of the INE general index, `ine_ipc`, table 76144, base 2025, from 2002 to 2025, with their three decimals, `ipc_leer()`, and the base year of constant euros, `ipc_anio_base()`), the website also offers «{base year} euros» in the Time machine (appraised value and average wage; it opens that way, and the choice goes in the address, `?euros=corrientes`) and in the profile's chart over time (series in euros; it opens in euros of each year and the choice is kept while the page lasts, without going into the address, so that a link or a story always opens like the map). The table, chart, changes, reading and key dates follow the choice; the money left over in «Can you make rent?» and the share of income do not change. The note below the chart gives the unit, the base year, the periods left out and the CPI change between the first and the last year with a figure. The page deflates like R (`ipc_deflactar()`): `ipc_exportar_control()` writes `datos/ipc_control.json` with the appraised value and the wage for Spain in base-year euros, and `pruebas/web/historico.test.mjs` checks that the page gives the same figures. Blocking checks: `ipc_variacion`, `ipc_serie` and `ipc_referencia` (`ipc_comprobar()`, target `validacion_ipc`), `ipc_deflactor_anios`, `ipc_deflactor_base`, `ipc_referencia_2008` and `ipc_referencia_2009` (`ipc_comprobar_deflactor()`, target `validacion_ipc_deflactor`), `web_ipc` (`ipc_comprobar_web()`, target `validacion_web_ipc`) and `web_ipc_control` (`ipc_comprobar_control()`, target `validacion_web_ipc_control`).
- **Other housing costs** (author's decision, 12 Nov 2026; `exportar_web_otros_gastos()`, target `fichero_web_otros_gastos`). `datos/otros_gastos.json`, outside the manifest: each region's factor with its observations and, for each ECV wave, the figure for Spain with its households and for each region, with the flag of those that take Spain's (§6.7). Without the file, the switch is disabled.
- **Stories** (backlog, task 49; author's decisions of 11 Nov 2026; `R/web_historias.R`, target `fichero_historias_web`). Guided tours inside the map: each step sets the map, year, view, territory, scale and, where needed, a profile token (the map is then in "Can you make rent?" with it; never the pawn, which is the visitor's own pay), and carries a text in Spanish and in English and, where needed, a "How it is measured" note with the method caveats, which the website shows in a collapsible block. Texts, notes and each step's view are in `inventario/historias.csv`; figures are not typed into the text or the note but written as `{id}` markers filled from `inventario/historias_cifras.csv`, computed from the long table, the historical table, the CPI or the website cut-offs, with the guide's rounding and each language's separators. When a set of municipalities is compared between 2015 and 2024, the same municipalities are counted in both years (constant panel), with the figure at the map's decimals. The CPI goes alongside rises in each year's euros and deflates no figure. Output: `web/datos/historias.json`. The first two were rewritten after a review with six readings (author's decision, 11 Nov 2026): plain language, seven steps each, one idea and one named place per step, and the method caveats in the note. They are "What was a high rent in Madrid in 2015 is now almost the whole city" (monthly rent by tract and by district in Madrid and Barcelona from 2015 to 2024, the salary needed and the change in new and existing contracts) and "Three years of income in 1987, more than eight today" (the Banco de España series since 1987, years of income and theoretical effort, and indicator 16 by province and municipality). Two more followed (author's decision, 12 Nov 2026), of six to eight steps: "The minimum wage opened up half the rental map, then stalled in 2020" (indicator 15 with the minimum-wage token from 2015 to 2024, with the same definition as the home page card, and rent per square metre) and "Your parents saved seven months for the deposit; you need twenty" (the Banco de España series in 1987, 1990, 1997, 2007 and today: rate on home loans, theoretical effort and the 20% deposit in months of household income, and indicator 17 by province, which does not measure the same as theoretical effort). The gap between moving in and staying put is postponed until Idealista's authorisation.
- **Stories gate** (`comprobar_historias()`, target `validacion_historias`, blocking). `historias_cifras`: each computed figure, rounded to its decimals, equals the drafted one; this includes figures that only back a sentence, such as the year of the peak or the municipality that ranks first. If a data update moves a figure, the pipeline stops and the text is reviewed by hand before publication. `historias_textos`: markers without a figure or differing between the two languages, in the notes too, empty texts, notes in a single language and steps out of order. `historias_estado`: maps in the manifest, years within their series, keys and formats of `web/js/estado.js`, profile tokens (never the pawn), municipal scale only with a tract cut-off set, and links to anchors that exist. `historias_privado`: no map or figure from private listings or from "moving in".

### 9.3 Source calendar and updates (F6)

`inventario/calendario_fuentes.csv` has one row per pipeline source (29, with the CPI of task 45 and the 2011 Census). Each row gives its cadence, the usual publication months and day, the lag between the end of a period and its publication, and the latest period the atlas holds. It also gives its official calendar (INE, Eurostat, Banco de España or CIS), the targets that download it, its files and how it is renewed (`mover`, `invalidar`, `codigo`, `manual` or `fija`).

`cal_fuentes_pendientes()` says which sources are due on a given date:
- when an expected publication date has passed since the last download;
- or when a period later than the latest in the atlas should already be published.

The `fuentes_pendientes` target runs again whenever that set of sources changes, and warns with the list and with how to renew each source. Its signal, `cal_hay_cambios()`, is evaluated when `_targets.R` is read: it compares with the list left by the previous run in `datos/intermedios/calendario/pendientes.csv`, outside git. With the calendar up to date it forces nothing, and `tar_outdated()` stays empty. The CIS target, `cis_estudios`, only runs again when it is due (`cal_toca()`).

Nothing runs on its own or in the remote repository. The procedure, with the R commands, is in `docs/actualizacion.md` (`cal_actualizar()`, `cal_restaurar()`).

On 10 Nov 2026 one source is due, `inss_pensiones`: it has already published the whole of 2025 and the atlas reaches 2024. Gate: `calendario_fuentes` (blocking) and `calendario_descargas` (warning), in the `validacion_calendario` target.

---

## 10. How to reproduce the figures

**Requirements.** R 4.6 with `renv` (`renv.lock`). Raw data are not in git: the pipeline downloads them into `datos/brutos/`, except the SERPAVI Excel file, which is downloaded by hand (§2.1).

```r
renv::restore()                           # first time only
targets::tar_make()                       # downloads, computes and runs the gates
testthat::test_dir("pruebas/testthat")    # tests with made-up data
targets::tar_read(validacion_f1)          # one gate: columns calculado, referencia, correcto
```

**Duration.** A full run from scratch takes about three and a quarter hours (plan §6.3):
- reading the State Cadastre buildings, 2 h 16 min;
- comparing boundaries, 21 min;
- reading the foral cadastres, about 17 min.

The base map takes about 9 minutes: 7 min 29 s for the PMTiles file (`fichero_mapa_base`) and 1 min 18 s for its gate, which computes the gaps in the tract map and their IGN names (9 Nov 2026). With `PROVINCIA=28` (environment variable, before `tar_make()`), the computation is limited to one province, and the files carry the code in their name.

**Targets cited in this note:**
- **Geography:** `secciones_2021`, `tablas_paso_callejero`, `tablas_paso_finales`, `edificios_paso`, `edificios_forales`, `municipios_catastro_sel`, `grupos_municipio`, `huerfanas_adrh`, `fase_codigos`, `cambios_limites`, `comprobaciones_f1`, `diagnostico_f1`, `comparacion_vias`.
- **Hierarchy and base map:** `jerarquia_2021`, `territorios_2021`, `ficheros_jerarquia`, `unidades_ign`, `fichero_mapa_base`, `resumen_mapa_base`.
- **Income:** `comprobaciones_adrh`, `tablas_paso_adrh`, `larga_adrh`, `tabla_larga`, `fichero_adrh_fuentes`, `fichero_adrh_umbrales`, `fichero_adrh_gini`, `ficheros_adrh_totales`, `comprobaciones_adrh_distribucion`, `larga_adrh_distribucion`.
- **Rent:** `serpavi`, `larga_serpavi`, `resumen_larga_serpavi`, `comprobaciones_fiabilidad`, `resumen_fiabilidad`, `contraste_serpavi_censo`.
- **Renting households and tourist dwellings:** `censo2021`, `larga_censo2021`, `vut`, `vut_2021`, `larga_vut`.
- **Conversion table from the 2011 Census (task 47):** `secciones_censo2011`, `tramos_2012`, `grupos_2011`, `paso2011_descasados`, `edificios_censo2011`, `paso_final_2011`, `paso_final_2011_vut`, `resumen_paso2011`, `censo2011`, `censo2011_tenencia`, `censo2011_2021`, `vut_2011_2021`, `comprobaciones_paso2011`, `validacion_paso2011`, `larga_paso2011`.
- **Wages and Young adult token:** `salarios_aeat`, `larga_salarios`, `modulos_sme`, `formas_mochila`, `mochila`, `mochila_neta`, `retenciones_mochila`, `ecv_mochila`, `correccion_mochila`, `tramos_salariales`, `curvas_salariales_aeat`.
- **Tokens and derived indicators:** `perfiles`, `resumen_perfiles_llave`, `larga_derivados`, `inss_mensual`, `inss_anual`, `retenciones_transistor`, `transistor`, `fichero_supuestos`, `supuestos_inventario`, `fichero_supuestos_js`, `superficie_tipica`, `terminos_supuestos`, `validacion_supuestos`, `ecv_gastos_hogares`, `otros_gastos`.
- **Overburden:** `sobrecarga_agrupada`, `comprobaciones_sobrecarga`, `sobrecarga_quintil`, `eurostat_quintil`.
- **Home purchase:** `ipva`, `larga_ipva`, `valor_tasado_trim`, `larga_valor_tasado`, `tipo_hipotecario_anual`, `tipo_bde_anual`, `renta_hogar_publicada`, `validacion_renta_hogar_publicada`, `renta_hogar_17`, `derivados_compraventa`, `registradores`, `validacion_registradores`, `larga_registradores`, `larga_compraventa`, `cp_municipio`, `fichero_cp_municipio`.
- **Pressure:** `zonas_tensionadas`, `boe_zonas_tensionadas`, `larga_zonas_tensionadas`, `resumen_larga_zonas_tensionadas`, `portales`, `portales_anual`, `larga_portales`, `resumen_portales`, `ficheros_web_portales`, `tramos_entrar`, `terminos_entrar`, `indicadores_entrar`, `tramos_web_entrar`, `resumen_entrar`.
- **Website:** `ficheros_web`, `cajas_municipios`, `ficheros_web_sobrecarga`, `fichero_ipc`, `ipc`, `ficheros_web_ipc`, `fichero_web_otros_gastos`.
- **Historical module (F6):** `series_bde`, `cne_agregados`, `cne_empleo`, `historico`, `fichero_historico`, `ficheros_web_historico`.
- **CIS and calendar (F6):** `cis_estudios`, `cis_barometros`, `cis_transcripcion`, `cis_barometros_completos`, `cis_vivienda`, `fichero_cis_vivienda`, `ficheros_web_cis`, `calendario_fuentes`, `fuentes_pendientes`.
- **Gates:** `validacion_mochila_relacion`, `validacion_f1`, `validacion_adrh`, `validacion_adrh_distribucion`, `validacion_serpavi`, `validacion_fiabilidad`, `validacion_censo2021`, `validacion_vut`, `validacion_derivados`, `validacion_jerarquia`, `validacion_mapa_base`, `validacion_web`, `validacion_web_sobrecarga`, `validacion_sobrecarga`, `validacion_quintil`, `validacion_modulo`, `validacion_salarios`, `validacion_mochila`, `validacion_mochila_ecv`, `validacion_mochila_neto_ecv`, `validacion_mochila_serie`, `validacion_percentil`, `validacion_web_salarios`, `validacion_smi`, `validacion_inss`, `validacion_transistor`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`, `validacion_ipva`, `validacion_hipotecas`, `validacion_valor_tasado`, `validacion_coherencia_compraventa`, `validacion_derivados_compraventa`, `validacion_cp_municipio`, `validacion_web_cp`, `validacion_zonas_tensionadas`, `validacion_web_zonas_tensionadas`, `validacion_historico`, `validacion_cne`, `validacion_web_historico`, `validacion_cis`, `validacion_web_cis`, `validacion_calendario`, `validacion_portales`, `validacion_web_portales`, `validacion_entrar`, `validacion_web_entrar`, `validacion_ipc`, `validacion_web_ipc`, `validacion_otros_gastos`, `validacion_web_otros_gastos`.
