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

**Question.** Where, since when and for whom the link between the cost of living and the ability to pay has broken (plan §1).

**Audience.** Primary: data journalists and analysts in public bodies and organisations. Secondary: a layer for the general public.

**Scale and period.** Census tract, from 2015 to the latest data available. All series are drawn on the 2021 Census tract map (§3).

**Two families of indicators** (plan §3):
- **Resident burden:** income of those who already live in the tract against rent in that tract.
- **Access barrier:** rent in the tract against a reference income («tokens», §6).

The second family corrects a bias in the first: expensive areas look affordable because higher-income people live there.

**Staging** (plan §2.3):

| Version | Content | Computation status (8 Nov 2026) |
|---|---|---|
| v0.0 | Indicators 22 (housing cost overburden, Eurostat method) and 23 (unsuccessful housing search) | In the long table: 261 and 32 rows (`tabla_larga`, sources `ine_ecv` and `ine_ecv_modulo`) |
| v0.1 | Core of 10 indicators: 1–3, 8, 9, 14, 15, 18, 19 and 21 | All 10, in the long table; the barrier (15), only with the Under-35 and Minimum wage tokens of 2024 (§7.4) |
| v1.0 | The 23 indicators of the catalogue (plan §5) | — |

**v0.1 core** (`inventario/indicadores.csv`, column `nucleo_v01`):

| # | Indicator | Source | Native level | Series | Status |
|---|---|---|---|---|---|
| 1 | Average net income per person | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 2 | Average net income per household | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 3 | Median income per consumption unit | INE, ADRH | Tract | 2015–2024 | Computed (`larga_adrh`) |
| 8 | Monthly rent (median) | MIVAU, SERPAVI | Tract (2021 tract map) | 2015–2024 | Computed (`larga_serpavi`) |
| 9 | Rent per m² (median) | MIVAU, SERPAVI | Tract (2021 tract map) | 2015–2024 | Computed (`larga_serpavi`) |
| 14 | Resident rent burden | SERPAVI and ADRH | Tract | 2015–2024 | Computed (`larga_derivados`) |
| 15 | Rental access barrier | SERPAVI and the income of each token | Tract × income | 2015–2024 | Check in `larga_derivados` (Minimum wage and Pensioner tokens, 2015–2024; Under-35 token, 2024); the website computes it with each token |
| 18 | Renting households | INE, 2021 Census | Tract (2021 tract map) | 2021 (2011, in F6) | Computed (`larga_censo2021`) |
| 19 | Tourist dwellings | INE, experimental statistics | Tract (2024 tract map, carried to 2021) | February 2024 – May 2026, twice a year (2020–2023, in F6) | Computed (`larga_vut`) |
| 21 | Net pay needed (default map) | SERPAVI | Tract | 2015–2024 | Computed (`larga_derivados`) |

**Rental building type** (plan §11, question 12). SERPAVI does not publish a joint median for apartments (vivienda colectiva) and single-family houses (vivienda unifamiliar). The rent map shows apartments by default, which account for 88.9% of observations in 2024: 2,271,987 against 284,591 (`serpavi`, regions sheet). Single-family houses are an option, and the two are never combined in one map. The derived indicators (14, 15 and 21) use apartments.

**Indicator 7.** The provincial wage from AEAT (the tax agency) is brought forward in a minimal version. Indicator 15 needs it through the «Under-35» token (plan §7, F2). The Under-35 token is already computed for 2024 (`mochila_neta`, §6.2).

**Lag.** The atlas runs one or two years behind on income and wages. ADRH has a lag of about 22 months: the 2024 edition was published on 19 Oct 2026. AEAT's *Mercado de trabajo y pensiones* (labour market and pensions) has one of about 11 months (plan §8).

---

## 2. Sources and licences

### 2.1 Sources used by v0.1

The full inventory, with address, access, frequency and notes, is in `inventario/fuentes.csv`. The `licencia` column quotes the text of each source.

| Source (`id`) | Body | Use | Licence (summary from `fuentes.csv`) |
|---|---|---|---|
| `ine_adrh` | INE | Indicators 1–6; population and households for the geography tests; municipality names | CC BY 4.0 |
| `mivau_serpavi` | MIVAU | Indicators 8, 9, 14, 15 and 21 | Reuse authorised by the MIVAU legal notice (Law 37/2007 and RD 1495/2011), citing the source and the date, without distorting the information |
| `ine_censo2021` | INE | Indicator 18; denominator of 19 | CC BY 4.0 |
| `ine_vut` | INE | Indicator 19 | CC BY 4.0 |
| `aeat_mercado_trabajo` | AEAT | «Under-35» token (indicator 7) and «Pensioner» token (pensioners' withholding) | Free reuse, including commercial, citing the source and the date of last update |
| `boe_smi` | BOE | «Minimum wage» token (2015–2026) | Reusable |
| `inss_pensiones` | INSS (Social Security) | «Pensioner» token | Reuse citing the source and the date of last update |
| `ine_ecv` | INE | Check of the Under-35 token; indicator 22 | CC BY 4.0 |
| `ine_ecv_modulo` | INE | Indicator 23 | CC BY 4.0 |
| `eurostat_ilc_lvho07`, `eurostat_ilc_lvho07_r` | Eurostat | Gate of indicator 22, also by income quintile (`ilc_lvho07b`); European series and map of the website | CC BY 4.0 |
| `eurostat_nuts` | Eurostat (GISCO) | Geometries of the European map | Non-commercial use with the notice «© EuroGeographics for the administrative boundaries». Not CC BY |
| `ine_seccionado` | INE | Tract maps from 2016 to 2025; territorial hierarchy and base map | CC BY 4.0 |
| `ign_au` | IGN | Name and type of the land without a tract in the base map (§3.10) | CC BY 4.0 (Order FOM/2807/2015), with the attribution `Obra derivada de BDDAE 2026 CC-BY 4.0 ign.es` |
| `ine_callejero` | INE | Conversion tables, route (a) | CC BY 4.0 |
| `catastro_inspire` | Directorate General for the Cadastre | Conversion tables, route (b) | Contradictory: see below |
| `catastro_foral` | Provincial councils of Álava, Bizkaia and Gipuzkoa; Government of Navarre | Route (b) in the Basque Country and Navarre | Different in each territory: see below |
| `gv_emal` | Basque Government | Municipal context layer (deposits); not combined with indicator 8 | CC BY 4.0 |
| `calculo_propio` | De renta en renta | Derived indicators 14, 15 and 21, from the sources of each term, and approximate margin of the rent median (§7.6) | CC BY-SA 4.0 |

**Manual download of SERPAVI.** The MIVAU website blocks automated downloads. If the Excel file is missing, `descargar_mivau_serpavi()` stops the pipeline and gives the page and the name under which to save it (`inventario/fuentes.csv`, column `acceso`).

### 2.2 Contradictory licences

**State Cadastre.** The official sources disagree:
- the IDEE metadata say CC BY 4.0;
- the Cadastre's INSPIRE page links to a licence from 2016 that requires transforming the data before disseminating them;
- the general ATOM feed says «all rights reserved»;
- the buildings feeds of each province allow free use citing the Directorate General for the Cadastre as author and owner.

**Foral cadastres:**
- Álava and Navarre: CC BY 4.0, without contradictions.
- Bizkaia: CC BY 3.0 ES with conditions from Law 37/2007; the municipal entries of its feed say «all rights reserved».
- Gipuzkoa: attribution only in the WFS and CC BY-SA 4.0 in the metadata and in the feed.

(`inventario/fuentes.csv`; plan §6.3.)

### 2.3 Licence of the derived data

**Author's decision (8 Nov 2026):** sources are treated as open data. Derived data, texts and the inventory are published under CC BY-SA 4.0 (`LICENCIA_DATOS.md`; plan §6.1). Until that date, the licence was CC BY 4.0.

ShareAlike accepts sources under CC BY and those that require sharing alike, such as Gipuzkoa. In return, whoever reuses the derived data must publish their own under the same licence.

**What it covers:**
- Since that date, the conversion tables combined with the Cadastre are versioned in `geo/tablas_paso/combinada_<year>_2021.csv` (target `fichero_paso_final_<tracts>`).
- The territorial hierarchy (`geo/jerarquia_2021.csv`, `geo/territorios_2021.csv`) and the PMTiles base map derive from the INE tract map and carry the same licence. The PMTiles file is not in git: it is published from a repository *release* (§3.10).

**Exceptions:**
- The GISCO NUTS geometries are outside the licence of the derived data.
- The layer of portal asking prices is not redistributed and is off by default (`PORTALES=FALSE`; plan §2.2).
- The web libraries, MapLibre GL JS 6.15.0 and PMTiles 4.5.0 (`web/vendor/`), keep their BSD-3 licence (plan §6.6).
- The code is under the MIT licence (`LICENSE`).

**Suggested attribution:** «De renta en renta (Guillermo Astiaso Llamazares), from [original source]» (`LICENCIA_DATOS.md`).

---

## 3. Reference tract map and constant geography

### 3.1 Reference: the 2021 Census tract map

**What it is.** The map and all series use the INE tract map at 1 January 2021: 36,333 tracts (`secciones_2021`; plan §1 and §6.3).

**Why.** SERPAVI (2011–2024) and the 2021 Census (indicator 18) publish their whole series on that tract map: neither needs a conversion table (plan §6.3). With the latest tract map, the SERPAVI medians would have to be split: 227 of the 26,137 tracts with data in 2024 have a code that disappears before 2025 (plan §11, question 4).

**What is reprojected:**
- ADRH income, published each year on its own tract map (§3.2 and §5);
- tourist dwellings (indicator 19), published on the 2024 tract map since February 2024 (§7.3; break `vut_seccionado_2024` in `inventario/rupturas.csv`). The plan placed them on the 2021 tract map from v0.9; this was corrected in v0.20.

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
| `cobertura_destino` | 2021 tracts that receive nothing | Exact | Blocking | None, except the exceptions | `validacion_f1` |
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
| `derivados_rango` | Derived figures outside the possible range: burden, from 0.1 to 100%; barrier, from 0.1 to 300%; pay needed, from 100 to 10,000 net € a month | Exact | Blocking | 0 in the 41 figures | `validacion_derivados` |
| `perfiles_mochila` | Provinces of the Under-35 token without an INE code in `inventario/provincias_aeat.csv`, repeated codes and names without the token | Exact | Blocking | 0 in the 3 figures | `validacion_derivados` |
| `smi_boe` | Monthly minimum wage of each year in `SMI_FICHAS` against that of the royal decree in its BOE XML, and the cited rule; 2021, mean weighted by months in force | Exact | Blocking | 0 in the 18 figures (2015–2023) | `validacion_smi` |
| `inss_cobertura` | Provinces, multi-province regions and Spain missing or repeated in any month of the year (INSS Excel) | Exact | Blocking | 0 in the 10 years | `validacion_inss` |
| `inss_suma` | Retirement pensions of the provinces against the number published for their region and for Spain, each month | Exact | Blocking | 0 in the 10 years (132 figures a month) | `validacion_inss` |
| `inss_media` | Average retirement pension of the provinces, weighted, against the one published for their region and for Spain, each month | ±€0.01 | Blocking | €4.5 × 10⁻¹³ at most | `validacion_inss` |
| `transistor_cobertura` | Provinces without a net Pensioner income in any year | Exact | Blocking | 0 in the 10 years | `validacion_transistor` |
| `transistor_retencion` | Pensioner withholding outside [0, 30%] | Exact | Blocking | 0 in the 10 years | `validacion_transistor` |
| `web_valores` | Value files in `web/datos/` whose values or states are not those of the long table (with the rounding of the guide to the precision of each series: one decimal; two for indicator 19) or whose length is not that of the index; series without a file. Also the contracts and margin of each rent series | Exact | Blocking | 0 in the 830 figures | `validacion_web` |
| `web_fichas` | By municipality: cells of the series of its sheet that do not reproduce the long table with the precision of each series, and tracts in excess or missing | Exact | Blocking | 0 in the 8,131 municipalities | `validacion_web` |
| `web_sobrecarga_valores` | Website overburden section: by view, value, rank, block, source and flag of each figure against the pipeline targets (with the rounding of the guide), and units in excess or missing; Spain series, annual breakdowns with the quintile, access module and map cut-offs against `cortes_web` of indicator 22 | Exact | Blocking | 0 in the 17 figures | `validacion_web_sobrecarga` |
| `web_sobrecarga_muestra` | INE figures without a sample size, with a sample different from that of the computation, with a flag other than the EU-SILC one or with a value and fewer than 20 observations; Eurostat figures without their table, with a sample size or with a flag other than that of the source | Exact | Blocking | 0 in the 13 figures | `validacion_web_sobrecarga` |
| `sobrecarga_es_total`, `sobrecarga_es_mercado`, `sobrecarga_ccaa` | Overburden from ECV microdata against Eurostat | ±0.1 points | Blocking | Pass in 2023–2025 (§7.5) | `validacion_sobrecarga` |
| `sobrecarga_quintil_total` | By wave: mean of the overburden rates of the five income quintiles, weighted by their people, against the overall rate | ±0.01 points | Blocking | Difference 0 in all three waves | `validacion_quintil` |
| `sobrecarga_quintil_eurostat` | Overburden in Spain by income quintile, from ECV microdata and unrounded, against Eurostat (`ilc_lvho07b`) for the same year | ±0.1 points | Blocking | All 15 figures of 2023–2025 pass, equal to one decimal; maximum difference, 0.045 points (§7.5) | `validacion_quintil` |
| `modulo_acceso_lectura` | Sum of the regions against the national total of the ECV 2025 module | ±0.1% | Blocking | Passes | `validacion_modulo` |
| `i18n_completo`, `contraste_texto`, `rampa_contorno`, `rampa_daltonismo` | ES/EN dictionaries, website contrasts and a six-step ramp distinguishable under simulated colour blindness | Exact | Blocking | Pass | `validacion_i18n`, `validacion_diseno` |
| `adrh_municipio_detalle` | Deviation of each municipality between aggregated tract means and the municipal figure | ±1% | Warning | Warns in 579 of 146,306 figures of municipality, year and indicator; 135 exceed 5% | `comprobaciones_adrh` |
| `adrh_dist_municipio_detalle` | Deviation (points) of each municipality between the tracts of indicators 4 and 5 aggregated as a weighted mean and the municipal figure | ±1 point | Warning | Warns in 98 of 108,360 figures of municipality, year and indicator; 33 exceed 2 points and the largest is 5.8 | `comprobaciones_adrh_distribucion` |
| `adrh_suma_secciones` | ADRH population by tract added up by municipality against the municipal total of the same table | ±0.5% | Warning | Warns in 160 municipality-years, all in 2015–2019 (38, 34, 30, 29 and 29) | `comprobaciones_f1` |
| `adrh_seccion_huerfana` | ADRH tracts with no code in any tract map of 2016–2025 | Exact | Warning | 9 (§3.8) | `huerfanas_adrh` |
| `cobertura_destino_excepcion` | 2021 tracts left empty by a known defect of the source | Exact | Warning | 2 tracts, 6 tract-years (§3.8) | `comprobaciones_f1` |
| `mapa_base_huecos` | Gaps of at least 0.01 km² in the 2021 tract map (land in no tract): number and area, in total and named after an IGN unit | Exact | Warning | Warns with 95 gaps and 1,495 km² (the largest, 418.4 km²); named after an IGN unit, 57 and 1,176.5 km² (§3.10) | `validacion_mapa_base` |
| `serpavi_escalas_detalle` | Each municipality or district, year and building type that does not match its tracts | Exact | Warning | Warns in 164 rows, which go as `ausente` (§7.1) | `validacion_serpavi` |
| `serpavi_forales` | First year with observations of each foral province against that of the break `serpavi_forales` | Exact | Warning | All four match | `validacion_serpavi` |
| `serpavi_sin_fila` | Tracts, districts and municipalities of the 2021 tract map that the database does not have (they go as `ausente`) | Exact | Warning | Warns with 40 tracts, 36 districts and 36 municipalities (§7.1) | `validacion_serpavi` |
| `margen_rango` | Tracts with the approximate margin of the median outside 1–40%, by year, indicator and housing type | Exact | Warning | Warns in the 40 figures: 2,414 tracts and years in 2015–2024, 2,242 of them single-family; in 2024, 16 apartment and 268 single-family (§7.6) | `validacion_fiabilidad` |
| `vut_denominador_detalle` | The tracts of `vut_denominador`, one by one (only those more than 0.001 points apart) | ±0.1 points | Warning | Passes: 839 tract-periods, all since November 2024; maximum difference, 0.091 points | `validacion_vut` |
| `derivados_rango_detalle` | Each derived figure outside the usual range: burden, below 3% or above 60%; barrier, 3% or 150%; pay needed, €200 or €4,000 | Exact | Warning | Warns in 23 figures: three burdens above 60% (2019 and 2022), 18 pay-needed figures below €200 in 2015–2018 and two above €4,000 (two tracts in Madrid, 2024) | `validacion_derivados` |
| `web_fuera_indice` | Long-table rows going to the website with no slot in the index of their level | Exact | Warning | Warns in 16 municipality rows; at the other levels, 0 | `validacion_web` |
| `web_sobrecarga_geometria` | Units of a view of the overburden map with no geometry in their NUTS version or in the fallback one | Exact | Warning | Passes: 0 in the 12 views (§7.5) | `validacion_web_sobrecarga` |
| `aeat_mediana_deciles` | Median of the SME by region interpolated from deciles against centiles | ±0.5% | Warning | Between −0.11 and +0.20% | `validacion_mochila` |
| `mochila_ecv` | Under-35 token of each region against the median gross pay in the ECV | ±15% | Warning | Between −10.6 and +7.2% | `validacion_mochila_ecv` |
| `mochila_neto_ecv` | Gross-to-net step applied to the ECV median gross pay against the median net pay | ±5% | Warning | Between −2.0 and +3.4%; Spain, +0.5% | `validacion_mochila_neto_ecv` |
| `sobrecarga_es_edad` | Overburden in Spain by age group | ±0.1 points | Warning | Passes in 2023–2025; maximum difference, 0.05 points (plan §7, F1b) | `validacion_sobrecarga` |
| `sobrecarga_quintil_reparto` | Population with income (weight RB050) in each quintile, by wave | ±1 point around 20% | Warning | Passes: from 19.95 to 20.05% | `validacion_quintil` |
| `nuts_geometria` | Regions with data and no geometry in their NUTS version or, as a fallback, in a later one | Exact | Warning | Warns: the grouped code FI19_20 in 2021–2025 | `validacion_nuts` |
| `contraste_declarado` | Contrast declared in `tokens.json` against the recomputed one | ±0.05 | Warning | Passes; maximum difference, 0.003 | `validacion_diseno` |

**Reading the results of `adrh_municipio`.** The median is 0.0% because most municipalities have a single tract. The warning `adrh_municipio_detalle` collects the cases in which the source does not match across scales with all tracts having data. In Madrid, for example, Alcobendas and Pozuelo de Alarcón stay above 5% every year (`inventario/referencias_validacion.csv`).

### 4.2 Pending checks

| `id` | What it compares | Tolerance | Type |
|---|---|---|---|
| `aeat_provincia` | Provincial average wage as read against the published AEAT table | Exact | Blocking |
| `adrh_aeat` | ADRH income against AEAT gross income by municipality | Consistent trend | Warning |
| `serpavi_ipva` | SERPAVI trend against the IPVA | Consistent trend | Warning |
| `notariado_tasado` | Notaries' price against appraised value (indicators 11 and 12, F4) | Reasoned threshold | Warning |

`adrh_aeat`, `serpavi_ipva` and `notariado_tasado` have no numeric tolerance yet. `validar_referencias()` does not accept text tolerances, so one has to be set before they enter the pipeline.

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

**Maps** (§9.2). Classes from the `cortes_web` column: for indicator 4, 50, 55, 60, 65 and 70%; for 5, 10, 15, 20, 25 and 30%; for 6, 25, 27, 29, 31 and 33. They use the six-step ramp of the other maps and one decimal.

---

## 6. Token incomes

### 6.1 Common rule and tokens

**Common rule:** net monthly income spread over 12 (guide, rule 8; plan §3.1). Rent is paid twelve times a year; with the monthly pay of a wage paid in 14 instalments, the burden would come out inflated by about 17% (14 / 12 = 1.167).

**Dwelling.** Single-person tokens look for 50 m², so that their maps differ only by income. Token rent is that of apartments (plan §11, question 12).

| Token | Reference income | Source | Scale | Dwelling | Status |
|---|---|---|---|---|---|
| Neighbourhood household (llave) | Average net income per household ÷ 12 | INE, ADRH (indicator 2) | Tract | Median rent of its tract, no fixed floor area | Income computed (`perfiles`); burden (indicator 14), in `larga_derivados` (§7.4) |
| Under-35 (mochila; aged 26 to 35) | Estimated median of pay received in the year, net, ÷ 12 | AEAT; check with the ECV | Province | 50 m² | Computed for 2024 (`mochila_neta`, `perfiles`), as `estimado` |
| Minimum wage (tartera) | Net annual minimum wage (SMI) ÷ 12 | Royal decree of each year (RD 1106/2014 to RD 126/2026) | National | 50 m² | Computed from 2015 to 2026 (`perfiles`) |
| Pensioner (transistor) | Average retirement pension, net of income tax, ÷ 12 | INSS; AEAT withholding | Province | 50 m² | Computed from 2015 to 2024 (`transistor`, `perfiles`); Basque Country and Navarre, as `estimado` |
| Your token | Net monthly pay entered by the user: 12 or 14 instalments, optional second wage | — | — | 50 m² with one wage, 70 m² with two; can be changed to 50, 70 or 90 | Computed in the browser and not stored (`js/sueldo.js`) |

### 6.2 Under-35 token: method B and gross-to-net step

The author's decision dates from 7 Nov 2026 (plan §3.1; open question 7, closed). AEAT data are for 2024, and the ECV is the 2025 wave, which carries 2024 income.

**1. Starting wage.** Average gross annual wage at ages 26 to 35 by province (AEAT, *Mercado de trabajo y pensiones*; table «Asalariados, percepciones salariales y salarios por provincia, edad y sexo»; `aeat_provincia`).
- It is actual pay over the year: it includes people who worked only a few months.
- AEAT tables are HTML pages, one per combination of filters (`descargar_aeat_mercado()`, `leer_aeat_mercado()`).

**2. From mean to median.** It is multiplied by the median-to-mean ratio of the estimated average salary (SME, «full-year» module) at ages 26 to 35 in its region.
- AEAT does not publish that median. It is interpolated from two tables (`cuantil_tramos()`, `calcular_mochila_opciones()`):
  - the counts of employees of each region and age in each national decile;
  - the limits of the national centiles.
- Assumption of the interpolation: within each national decile, the region is distributed like the country. Check against the counts by centile that AEAT gives by region, for all ages: between −0.11 and +0.20% (`aeat_mediana_deciles`).
- Assumption of the method: the median-to-mean ratio is the same in all provinces of a region.
- Formula: gross annual = actual provincial average wage × median-to-mean ratio of the SME of its region (`calcular_mochila()`, `mochila`).

**3. From gross to net** (`calcular_mochila_neta()`): net annual = gross × (1 − contribution − withholding); net monthly = net annual ÷ 12.
- **Employee contribution in 2024:** 6.47% (`COTIZACION_TRABAJADOR`). It adds common contingencies (4.70), unemployment (1.55), vocational training (0.10) and the intergenerational equity mechanism, MEI (0.12). With a temporary contract it would be 6.52%.
- **Withholding:** AEAT average rate for people who only earn wages, by region and annual income bracket (*Grupos de población por la naturaleza de sus retribuciones*; `aeat_retenciones`, `retenciones_aeat()`).
  - It is interpolated linearly between the average wages of the brackets; outside them, the rate of the end bracket is taken (`tipo_retencion()`).
  - In Spain (`retenciones_mochila`): between 1.6 and 1.8% below €12,000; 2.6% from €12,000 to €18,000; 9.0% from €18,000 to €24,000; 13.6% from €24,000 to €30,000.
  - It is the payroll withholding, not the final income tax liability.

**4. Pay received in the year.** The token uses pay received in the year, not that of someone working twelve months: AEAT does not publish that wage, because its «full year» annualises by days of contribution. In the 2025 ECV, 73.9% of employees aged 26 to 35 with a wage worked all twelve months (`ecv_mochila`, Spain).

**5. Check with the 2025 ECV.** Person microdata: gross wage (PY010G), net wage (PY010N), weight (PB040) and age at the end of the income year (`leer_ecv_asalariados()`, `resumir_ecv_asalariados()`).
- `mochila_ecv`: the Under-35 token of each of the 15 common-regime regions lies between −10.6% (La Rioja) and +7.2% (Castilla y León) of the ECV median gross pay.
- `mochila_neto_ecv`: the gross-to-net step applied to the ECV median gross pay lies between −2.0% (Canary Islands) and +3.4% (Galicia) of the median net pay. In Spain, +0.5%, with 4,857 observations.

**2024 result** (`mochila_neta`; `datos/intermedios/mochila/mochila_neta_2024.csv`):
- **Coverage:** 46 common-regime provinces. The Basque Country and Navarre are not in the AEAT tables (separate foral systems); Ceuta and Melilla are not in the full-year module.
- **Gross annual:** €18,334 as the mean of the provinces weighted by employees.
- **Net monthly:** from €990 (Huelva) to €1,529 (Barcelona); weighted mean, €1,330. The net-to-gross ratio is 0.87.

**Discarded options.** Options A and C are still computed for the record (`mochila_opciones`):
- Option A comes out between 1.24 and 1.49 times B (median, 1.34). Weighted mean: €24,257 against €18,334.
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
- **Use.** The barrier in the long table (§7.4) and the website use the minimum wage of the same year as the rent (rule 4; author's decision, 9 Nov 2026): with 2024 rent, €1,237.40. Those of 2025 and 2026 have no rent of the same year; the website cites the latest next to that of the chosen year.

**Comparison with the Under-35 token.**
- The 2024 Under-35 token (€1,330 net on average) comes out almost equal to the Minimum wage token with the 2026 minimum wage. They are different years (rule 4).
- With the 2024 minimum wage (€1,237 net), the Under-35 token lies 7.5% above (plan §3.1).
- The income tax exemption of the minimum wage applies to those who earn it all year. The AEAT table gives withholding of 1.6–1.8% also below €12,000.

### 6.4 Neighbourhood household token

**Income** (`perfiles`): ADRH average net income per household of each tract (indicator 2, §5) ÷ 12, with the status of its reprojection. In 2024, in the 36,237 tracts with a value: 10th percentile, €2,319; median, €3,021; 90th percentile, €4,501 a month (`resumen_perfiles_llave`).

**Dwelling:** the median apartment rent of the tract itself, no fixed floor area. It is the only token that varies on both sides, income and rent.

**Burden:** the cross with SERPAVI is indicator 14 (§7.4).

### 6.5 Pensioner token

**Question.** It answers “if I had to rent today”: 89.1% of people aged over 65 live in a home they own (ECV 2023; plan §3.1), and the website says so next to the token.

**Method** (plan §3.1; author's decision of 9 Nov 2026):
1. **Starting pension.** Average retirement pension of the whole system by province (INSS, *Pensiones contributivas del Sistema de la Seguridad Social*; monthly Excel «Pensiones por CCAA y provincias»; `descargar_inss_pensiones()`, `leer_inss_pensiones()`). It excludes Clases Pasivas (civil service pensions). It is the average of one ordinary instalment; the province is that of the provincial office that manages the pension, not of residence, and pensions are counted, not pensioners.
2. **Average of the year.** Mean of the twelve monthly figures (pensions in payment on the 1st of each month), weighted by the number of pensions (`armonizar_inss_pensiones()`, `anual_inss_pensiones()`; targets `inss_mensual` and `inss_anual`). Unit names are turned into codes with a fixed table (`inventario/provincias_inss.csv`). The Excel changes shape over the years (sheet name, one sheet per scheme and, from 2024, the amount): the whole-system sheet and the retirement column are found by their text.
3. **From gross to net** (`calcular_transistor()`): gross a year = average × 14 instalments; net a month = gross a year × (1 − withholding) / 12. Pensions pay no contributions.
   - **Withholding:** AEAT average rate of people who only receive pensions (*Grupos de población por la naturaleza de sus retribuciones*, pensions block, «Pensionistas» column), by region and annual income band, of the same year, interpolated as for the Under-35 token (`retenciones_pensiones()`, `tipo_retencion()`; target `retenciones_transistor`). In 2024, from 0.4% (Ourense) to 10.8% (Bizkaia).
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

- In 2024, the Pensioner token (€1,574 on average) lies above the Under-35 token (€1,330) and the Minimum wage token (€1,237) of the same year.
- Sources, downloaded with the author's permission (9 Nov 2026): the 120 INSS Excel files from 2015 to 2024 (≈ 9.6 MB) and AEAT withholding from 2015 to 2023 (1,458 pages, ≈ 39 MB; 2024 was already there). AEAT editions up to 2017 have another layout and other region names («Región de Murcia»): `aeat_titulo()` and `aeat_menus()` read both.

---

## 7. Rent, renting households, tourist dwellings, derived indicators and overburden

### 7.1 Rent (indicators 8 and 9)

**Source.** The SERPAVI database of the MIVAU (`mivau_serpavi`), 2011–2024 edition. It is an Excel file with one sheet per level: regions (with the total for Spain), provinces, municipalities, districts and tracts. The whole series is on the 2021 tract map (plan §6.3). The file is downloaded by hand (§2.1); the `version` column carries its date, 6 Nov 2026.

**What it measures.** Current main-residence tenancies declared in personal income tax and matched with the Cadastre. It is the rented stock, not new contracts (guide, rule 5).

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

**2011 Census** (plan §11, question 14). It is on the 2011 tract map and there is no conversion table from 2011 to 2021: v0.1 carries only the 2021 snapshot. The 2011 → 2021 conversion table (street register and 2011 tract map, plus route b) is built in F6, with the historical series.

### 7.3 Tourist dwellings (indicator 19)

**Source.** INE's experimental statistics on tourist dwellings, built from platform listings (`ine_vut`). Table 5 (districts and tracts) is one xlsx per period, with 13 half-yearly periods from August 2020 to May 2026 (`PERIODOS_VUT`). Tables 39364 (dwellings) and 39365 (percentage) give Spain, the regions and the provinces. The `version` column carries the date of the last file, 8 Nov 2026.

**Tract map of each period** (checked code by code on 8 Nov 2026; break `vut_seccionado_2024` in `inventario/rupturas.csv`):

| Periods | Tracts in the file | Denominator of the INE percentage |
|---|---|---|
| August 2020 – February 2023 (6) | 35,960, those of the 2011 Census | 2011 Census dwellings |
| August 2023 | 37,063 codes: those of the 2011 Census and others from later tract maps | 2021 Census dwellings (`inventario/indicadores.csv`) |
| February 2024 | 2024 tract map, plus 258 old codes without tourist dwellings | 2021 Census dwellings (`t18_1`) |
| August 2024 – May 2026 (5) | 2024 tract map (36,477 tracts) | 2021 Census dwellings (`t18_1`) |

**Periods in the atlas** (plan §11, question 14). The six on the 2024 tract map, from February 2024 to May 2026 (`PERIODOS_VUT_2024`). The seven earlier ones are read (`leer_ine_vut()`) and enter the gate of provincial counts, but not the indicator: there is no conversion table from the 2011 tract map, which is built in F6. Using the INE municipal level for those years was ruled out, because it would mix scales in the series.

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

### 7.4 Derived indicators (14, 15 and 21)

**Definition** (plan §5, block C; `inventario/indicadores.csv`):

| # | Indicator | Formula | Unit | Terms |
|---|---|---|---|---|
| 14 | Resident rent burden | Median monthly rent × 12 / average net income per household, same year | % of household income | Indicators 8 and 2 |
| 15 | Access barrier | Median rent per m² × 50 / net monthly income of the token | % of the token's income | Indicator 9 and the token's income (§6) |
| 21 | Net pay needed (default map) | Median rent per m² × 50 / 0.30 (threshold can be changed to 40%) | Net € a month | Indicator 9 |

**Building type** (plan §11, question 12): the rent of all three is apartment rent (`grupo = VC`).

**Status** (plan §11, question 15; `peor_estado()`): the worst of its terms, in the order `dato` < `estimado` < `secreto` < `ausente`.
- A tract with confidential rent is `secreto`.
- With rent `dato` and income `estimado`, the burden is `estimado`.
- If any term is missing, `ausente`. That is the case of the barrier with the Under-35 token in the Basque Country, Navarre, Ceuta and Melilla, where the token has no income (§6.2).
- For 15, the token income does not count as a term (`estado_barrera()`; plan §11, question 15 extended): the barrier takes the status of the rent, and is `ausente` if the token has no income. The Under-35 token goes as `estimado` (it is an estimate, §6.2), and that is explained once, in its method, not in each tract.
- Indicator 21 has a single term: it takes the status of indicator 9.

**Rounded terms** (plan §11, question 19; `termino_publicado()`). Rent, household income and token income enter the computation rounded to one decimal with `sprintf("%.1f")` (§0), as the website receives them. So the figure from R and the one the website recomputes in the browser match exactly.

**Same year** (guide, rule 4). In the burden, SERPAVI and ADRH match in 2015–2024. The barrier in the long table uses the token income of the same year as the rent: the Minimum wage token, with the minimum wage of each year from 2015 to 2024; the Pensioner token, with the pension of each year; the Under-35 token, only in 2024 (AEAT 2024). The website does the same with the chosen token (author's decision, 9 Nov 2026); with the Under-35 token and rent of another year, it uses the 2024 one and says so.

**How to read them:**
- Indicator 15 is read in bands: up to 30%, 30 to 40% and over 40%.
- Indicator 21 is rent expressed in another unit. The 30% threshold draws on the stressed-zone criterion of Law 12/2023 (art. 18), which uses household income and utilities; it is not that criterion.
- The map of indicator 21 is drawn in six bands, with national cut-offs that are the same every year: €700, 900, 1,100, 1,500 and 2,000 (plan §11, question 20). The colour ramp has six steps that can also be told apart with colour blindness (`rampa_daltonismo`).
- Indicators 15 and 21 change with the threshold, the floor area and the pay of «Your token»: the website recomputes them in the browser (plan §6.6).

**Computation** (`armonizar_derivados()`; target `larga_derivados`, 2,149,869 rows, source `calculo_propio`):
- **14** (`calcular_esfuerzo_residentes()`): in tracts and municipalities, the levels at which SERPAVI and ADRH publish both terms (`NIVELES_ESFUERZO`), and in the years with both, 2015–2024. No breakdown.
- **21** (`calcular_sueldo_necesario()`): at all SERPAVI levels, 2015–2024, with 50 m² and the 30% threshold. No breakdown.
- **15** (`calcular_barrera_acceso()`): cut `ficha`, with groups `tartera` and `transistor` (2015–2024) and `mochila` (2024). The Under-35 and Pensioner tokens, in the provinces and their tracts, districts and municipalities; the Minimum wage token, also in the regions. It is a check: the website computes the barrier with the chosen token.
- **Token incomes** (`perfiles_fichas()`; target `perfiles`): the Minimum wage token (§6.3); the Under-35 token of each province, with its INE code in `inventario/provincias_aeat.csv` (46 provinces with data and 6 `ausente`); the Neighbourhood household token (§6.4); the Pensioner token of each province and year (§6.5).
- **Version:** the most recent of its terms, 7 Nov 2026.

**Result: resident rent burden (14) in the tracts** (`larga_derivados`):

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
- Pay needed (21) has the same states as apartment rent (§7.1).

**2024 values in the tracts** (`larga_derivados`):

| Indicator | Tracts with a value | Minimum | 10th percentile | Median | 90th percentile | Maximum |
|---|---|---|---|---|---|---|
| Resident rent burden (%) | 26,125 | 6.2 | 12.6 | 17.6 | 24.0 | 51.3 |
| Net pay needed (€ a month) | 26,137 | 300 | 700 | 1,217 | 2,117 | 4,283 |
| Barrier with the Under-35 token (%) | 24,117 | 7.2 | 16.8 | 27.5 | 43.7 | 87.9 |
| Barrier with the Minimum wage token, 2024 minimum wage (%) | 26,137 | 7.3 | 17.0 | 29.5 | 51.3 | 103.8 |
| Barrier with the Pensioner token (%) | 26,137 | 6.2 | 14.3 | 23.3 | 37.9 | 73.2 |

**Barrier with the Minimum wage and Pensioner tokens in the tracts, each year with that year's income** (`larga_derivados`; median and share of tracts with a value above 30%):

| Year | Minimum wage: median (%) | Minimum wage: above 30% | Pensioner: median (%) | Pensioner: above 30% |
|---|---|---|---|---|
| 2015 | 36.7 | 69.2% | 22.7 | 21.3% |
| 2016 | 36.3 | 70.8% | 22.6 | 21.3% |
| 2017 | 34.3 | 63.4% | 22.6 | 22.1% |
| 2018 | 34.2 | 61.9% | 22.7 | 23.1% |
| 2019 | 30.0 | 50.1% | 23.2 | 25.7% |
| 2020 | 28.9 | 46.2% | 23.4 | 26.5% |
| 2021 | 29.7 | 49.0% | 23.7 | 26.9% |
| 2022 | 29.7 | 49.7% | 23.8 | 27.2% |
| 2023 | 28.8 | 47.2% | 23.0 | 24.4% |
| 2024 | 29.5 | 48.4% | 23.3 | 24.1% |

With the Under-35 token, 7,616 tracts are `ausente` in 2024: all those in the Basque Country, Navarre, Ceuta and Melilla, where the token has no income, and those without rent.

**Gate** (`comprobar_derivados()`, `validacion_derivados`; §4.1): `derivados_terminos`, `derivados_estado`, `derivados_rango`, `perfiles_mochila` and `smi_neto` (blocking), and `derivados_rango_detalle` (warning). Before that, the Minimum wage token goes through `smi_boe` and the Pensioner token through the INSS ones (§6.3 and §6.5).

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
- the map does not change: without a visual test that justifies it, tracts with few contracts are not dimmed, and the flag goes in the profile and in the CSV.

**Gate** (`comprobar_fiabilidad_serpavi()`, `validacion_fiabilidad`; §4.1): `contratos_mediana` and `contratos_suma` (blocking), and `margen_rango` (warning). The margin is only checked in the tracts: in large areas it naturally falls below 1% (in the provinces, a median of 0.3%).

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
- **Vulnerability, not access.** The burden divides rent by the average income of all households in the tract, not only of those who rent (`inventario/indicadores.csv`).
- **The barrier in the long table is a check.** With the Minimum wage and Pensioner tokens from 2015 to 2024 and the Under-35 token of 2024; the website computes it with the chosen token (§7.4).

**Under-35 token:**
- **Assumptions:**
  - the median-to-mean ratio of the SME of a region holds for all its provinces;
  - the distribution within each national decile is that of the country;
  - payroll withholding is the average of all ages;
  - the contribution is that of a permanent contract.
- **Coverage.** No Basque Country, Navarre, Ceuta or Melilla (§6.2).
- **Pay received in the year.** The token uses pay received in the year, which includes people who worked only a few months; the token says so.

**Pensioner token:**
- **Pensions, not pensioners.** Someone with two pensions counts twice, and the province is that of the provincial office that manages the pension (§6.5).
- **Withholding of all pensioners.** AEAT does not separate retirement; in the Basque Country and Navarre, the curve is that of Spain (`estimado`; §6.5).
- **Own home.** The great majority of people aged over 65 do not rent: the token answers “if I had to rent today” (§6.5).

**Token years.** The Minimum wage and Pensioner tokens have an income for each year from 2015 to 2024; the Under-35 token, only for 2024: with rent of another year, the website uses the 2024 one and says so (§7.4).

**Licences.** The State Cadastre and the foral cadastres of Bizkaia and Gipuzkoa have contradictory licences and are treated as open data by decision of the author (§2.2).

**Overburden.** It is published without confidence intervals. The income quintile uses HY020 ÷ HX240, not Eurostat's HX090, which INE does not publish, and puts an income equal to a cut-off in the upper quintile, so that all 15 figures match Eurostat's to one decimal. The Spanish series is broken in 2013, the year in which the way incomes are obtained changes, although Eurostat does not flag it (§7.5).

**Lag.** Income and wages run one or two years behind the current year (§1).

---

## 9. Long table and website data

### 9.1 Long table

**Schema** (plan §6.4): `geo_id`, `nivel`, `anio`, `indicador`, `corte`, `grupo`, `valor`, `estado`, `fuente`, `geo_ref` and `version`. The key of a row is `geo_id`, `nivel`, `anio`, `indicador`, `corte` and `grupo`.

**Content** (`tabla_larga`; `exportar_tabla_larga()`, `datos/intermedios/tabla_larga.parquet`): 10,938,177 rows.

| Source (`fuente`) | Rows | Levels | Version |
|---|---|---|---|
| `ine_adrh` | 2,634,650 | Tract (2,179,944), municipality (452,546), province (1,560), region (570) and Spain (30) | 7 Nov 2026 (1–3) and 9 Nov 2026 (4–6) |
| `mivau_serpavi` | 5,032,640 | Tract (3,419,452), district (926,724), municipality (676,872), province (7,032), region (2,540) and Spain (20) | 6 Nov 2026 |
| `ine_censo2021` | 36,405 | Tract (36,333), region (19), province (52) and Spain (1) | 8 Nov 2026 |
| `ine_vut` | 218,430 | Tract (217,998), region (114), province (312) and Spain (6) | 8 Nov 2026 |
| `ine_ecv` | 261 | Region (228) and Spain (33) | 6 Nov 2026 |
| `ine_ecv_modulo` | 32 | Region (19) and Spain (13) | 6 Nov 2026 |
| `calculo_propio` | 3,015,759 | Tract (2,109,389), district (473,841), municipality (427,881), province (3,568) and region (1,080) | 7 Nov 2026 |

**By status:** `dato`, 8,201,688 rows; `ausente`, 1,533,535; `secreto`, 1,151,583; `estimado`, 51,371.

**Publication.** The long table is published in the GitHub release `v0.1.0` (9 Nov 2026), and the website at `https://gastiaso.github.io/de-renta-en-renta/` (`docs/publicacion.md`).

### 9.2 Website data

The export follows the author's decisions of 8 Nov 2026 (plan §6.6; plan §11, questions 16 and 17). `exportar_web()` (target `ficheros_web`) writes into `web/datos/`, from the validated long table, the v0.1 core indicators and those with a map (`cortes_web` column and tract figures: indicators 4–6 of F3, since 9 Nov 2026), from tract to Spain:
- **Values.** One JSON file per series, level and period, with values × 10 as integers (× 100 for tourist dwellings, with two decimals, as INE publishes them: column `escala_web` of `inventario/indicadores.csv`, empty for the rest; plan §11, question 24), with the rounding of the guide to those decimals, and a string with the status of each unit, in the order of the index of its level. Compressed, it weighs the same as a binary (plan §11, question 17): each tract file takes 139 to 291 KB, and 19 to 98 KB with gzip.
- **Spain, regions and provinces.** Indicators 18 and 19 carry the published figures for Spain, the 19 regions and the 52 provinces (§7.2 and §7.3); those for Spain, in seven files. Rent (8 and 9) and pay needed (21) have regions and provinces but not Spain: SERPAVI publishes only its count of observations, which goes in the contracts series (§7.6). Income (1–3) and rent burden (14) go up to the municipality (§5.3 and §7.4). Income distribution (4–6) carries the published figures for regions, provinces and, from 2021, Spain (§5.5).
- **Sheet series.** One file per municipality (`fichas/<municipality>.json`) with the series of its tracts and of the municipality itself.
- **Reliability** (§7.6). The contracts and margin of the median go as auxiliary series of each rent series, of its same housing type (`fiabilidad` in the manifest), with no indicator number or map of their own. They are not in the per-municipality files, where they would weigh a quarter more: the tract profile reads them from the files of the period the map shows.
- **What is not exported.** The SERPAVI quartiles and the barrier (15), which the website computes with the chosen token. Pay needed (21) is recomputed in the browser from rent per m² when the floor area or the threshold change (`FORMULAS_WEB`).
- **Website against R.** The website test (`pruebas/web/datos.test.mjs`, in node) recomputes with the page's own module, `web/js/formulas.js`, the pay needed from rent per m² in all tracts, districts, municipalities, provinces and regions from 2015 to 2024, and compares it with the one exported by R: 550,140 unit-years, 294,082 with a value, with no difference in value, nulls or status (plan §6.5). In addition, `comprobar_web_navegador()` opens the page in headless Chrome (`chromote`): with its own modules, it recomputes a sample of 300 tracts over the 10 years and reads their contracts and margin, and it opens six tract profiles. Locally and on the published site everything matches the long table, with no errors (9 Nov 2026; `docs/publicacion.md`).
- **Downloads.** The website downloads the map series as CSV, at the level in view (value with the precision of the series, status and source; for the rent series, contracts and margin; for indicator 21, floor area and threshold), and the map as PNG with its legend and source. With «Your token», neither carries the pay entered: the CSV gives the rent, not the ratio. The colours of the «Can you make rent?» PNG do let it be roughly inferred, so with «Your token» it is downloaded after a warning that can be cancelled (plan §11, question 23).
- **Year outside the series** (plan §11, question 32). With a year earlier than every period of a series (2020 for tourist dwellings), the map, the legend, the sheet, the comparison panel and both downloads show «no data» and say when the series starts; the CSV, with one row without a value per unit and the start of the series in the status column. With a later year, the last period is taken, and the legend says so.
- **Other files.** Unit names, municipality bounding boxes for the search box (`cajas_municipios`) and token incomes (`perfiles`), for each year (`anios`), so that the website uses that of the rent year. The base map is copied to `web/teselas/`; on publication, it comes from a *release* (§3.10).
- **Volume** (`ficheros_web`, 9 Nov 2026): 8,970 files and 147.7 MB, including the PMTiles file (35.4 MB). On disk, `web/datos/` holds 9,354 files and 113.6 MB: the 8,969 of `ficheros_web` (112.3 MB; the per-municipality files, 57.9 MB), the 3 of the overburden section (`ficheros_web_sobrecarga`, 1.1 MB) and the versioned sample in `web/datos/ejemplo/` (382 files, 0.2 MB). The contracts and margin (§7.6) add about 17 MB, and the income distribution (§5.5) about 21 MB, 14 of them in the per-municipality files.
- **Gate** (`comprobar_web()`, `validacion_web`): `web_valores` and `web_fichas` (blocking) and `web_fuera_indice` (warning) (§4.1).

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
- **Rent:** `serpavi`, `larga_serpavi`, `resumen_larga_serpavi`, `comprobaciones_fiabilidad`, `resumen_fiabilidad`.
- **Renting households and tourist dwellings:** `censo2021`, `larga_censo2021`, `vut`, `vut_2021`, `larga_vut`.
- **Under-35 token:** `mochila_opciones`, `mochila`, `mochila_neta`, `retenciones_mochila`, `ecv_mochila`.
- **Tokens and derived indicators:** `perfiles`, `resumen_perfiles_llave`, `larga_derivados`, `inss_mensual`, `inss_anual`, `retenciones_transistor`, `transistor`.
- **Overburden:** `sobrecarga_agrupada`, `comprobaciones_sobrecarga`, `sobrecarga_quintil`, `eurostat_quintil`.
- **Website:** `ficheros_web`, `cajas_municipios`, `ficheros_web_sobrecarga`.
- **Gates:** `validacion_f1`, `validacion_adrh`, `validacion_adrh_distribucion`, `validacion_serpavi`, `validacion_fiabilidad`, `validacion_censo2021`, `validacion_vut`, `validacion_derivados`, `validacion_jerarquia`, `validacion_mapa_base`, `validacion_web`, `validacion_web_sobrecarga`, `validacion_sobrecarga`, `validacion_quintil`, `validacion_modulo`, `validacion_mochila`, `validacion_mochila_ecv`, `validacion_mochila_neto_ecv`, `validacion_smi`, `validacion_inss`, `validacion_transistor`, `validacion_i18n`, `validacion_diseno`, `validacion_nuts`.
