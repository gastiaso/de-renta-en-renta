# Method in two pages

What the atlas measures, with which sources and whom each one leaves out. The full version is the methodological note («Method» page); the Spanish version of this page, *Método en dos páginas*.

## What the atlas asks

Who has pay left after paying for housing? Where, since when and for whom the relationship between what housing costs and what people earn has changed. For those already on the board and for those joining the game.

## Two families that are never mixed

| | Staying | Moving in |
|---|---|---|
| Whom it measures | Those already renting | Those looking for a home today |
| Source | SERPAVI (Ministry of Housing), with Tax Agency and Cadastre data | Idealista asking prices; INE index for new leases |
| What the figure is | Median rent of existing leases | Median price asked in listings |
| Scale | Census tract | Municipalities with published listings, province, autonomous community and Spain |
| Period | 2015–2024 | 2006–2026 (municipalities, mostly since 2011) |
| On the site | Maps, profiles and downloads | Coming soon: Idealista asking prices are not published until it authorises it; their derivatives, only in bands and never in the downloads |

No figure in the atlas combines the two sources. When they appear together, each carries its name. From 2015 to 2024, in the 21,609 tracts with data in both years, the median rise in SERPAVI rent per m² is 42 %.

## Whom each source leaves out

- **SERPAVI:**
  - it comes from the income tax returns of landlords who are natural persons: it does not cover dwellings owned by companies, lets to relatives or undeclared rent (Ministry methodology of 18 March 2026);
  - there are data for Navarre from 2021; for Gipuzkoa, from 2022; for Álava and Bizkaia, only for 2024;
  - it measures the existing stock, not what those moving in pay;
  - with fewer than 10 leases there is no figure: in 2024, 72 % of tracts have data, home to around 84 % of the population.
- **Idealista:**
  - it is an asking price, not the rent of a signed lease;
  - it only covers the municipalities where it publishes its report;
  - its areas do not match districts or tracts.
- **INE index for new leases:** it is an index, not a price; it starts in 2021 and goes down to province. It serves to contrast asking prices: from 2021 to 2024, in Spain, the index for new leases rises by 19.3 % and the one for existing leases by 7.5 %.
- **Household income (INE):** it is that of all households in the tract, owners included, not that of renters.
- **Wages (Tax Agency):** it is what was earned in the year, which includes people who worked only a few months. It does not cover the Basque Country or Navarre.

## How to read the figures

- **Pay needed.** Always two figures:
  - with the tract's actual median monthly rent: in 2024, €1,900 net a month in the median tract;
  - with a theoretical 50 m² flat, as a minimum: €1,217. Rented flats measure about 79 m²: the median, across tracts, of the ratio of each tract's median monthly rent to its median rent per m², not the median of floor areas.
- **What is left.** Income minus rent, in euros a month. It is a subtraction: it does not say whether what is left is enough to live on.
- **Residual income line.** With the «Rule» selector, what is left is compared with a monthly line for the household: the guaranteed income of the minimum living income scheme (€604.21 for one person in 2024; up to 2019, the non-contributory pension) or the Living Conditions Survey at-risk-of-poverty threshold (€1,018.37). Neither is a budget for the other expenses. The pay needed also gives the rent plus the one-person line. The neighbourhood household has no line: its income is that of all the households in the tract.
- **Poverty after housing costs.** In the «Overburden» section, from 2016 to 2025, by region, by tenure and by age, alongside European countries in total and by age (and Spain by degree of urbanisation): people whose income, once housing costs are paid, falls below the at-risk-of-poverty threshold (60% of the median, before paying for housing). It is Eurostat's definition, computed from the EU-SILC microdata: in Spain, 28.7% in the 2025 survey, the same figure Eurostat publishes. The region crossed with tenure or with age, and the region's total alongside them, use rolling three-wave periods (each survey with the two before it), so that the sample is large enough.
- **30 % threshold.** It is a convention. The same share leaves much less room to a low wage than to a high one.
- **Profiles.** Each profile uses a different income and states it:
  - neighbourhood household: average net household income;
  - young adult, 26 to 35: estimated median of one person;
  - minimum wage: the legal amount;
  - pensioner: average retirement pension (the median is not published by province).
- **Margin.** Each median rent carries its number of leases and an approximate 95% margin. It is the margin of one figure: comparing two years calls for the margin of the difference, which is larger. With fewer than 30 leases, the figure is indicative and one-year changes are not interpreted.
- **Euros.** Series are in current euros unless stated otherwise.
- **Statuses.** «Published or computed value», «estimated» (rebuilt with a written rule), «statistical confidentiality» (there is rent, but fewer than 10 leases) and «no data».

## Licences

| Source | Condition | What it requires |
|---|---|---|
| INE, IGN, Eurostat (data) | CC BY 4.0 | Attribution |
| Ministry of Housing, Tax Agency, Social Security, Bank of Spain, BOE, CIS | Reuse with attribution | Cite the source and the date |
| State Cadastre and the foral cadastres of Bizkaia and Gipuzkoa | Contradictory across their own pages | Treated as open; withdrawal plan if clarified otherwise |
| Land Registrars (sale price, by province) | ODbL | Attribution; anything derived from their database is also published under ODbL |
| European geometries (GISCO) | Non-commercial use | © EuroGeographics notice on the map |
| Idealista | Terms of its website | Only on the site, with a link to the report, and «coming soon» until it authorises it; nothing of it in the downloads |
| General Council of Notaries (Statistical Portal and CIEN; indicators 25 to 29) | © Consejo General del Notariado, non-commercial use only | Website only, with the label on the map, the profile, the legend and the image, and no CSV download; outside the long table, the downloads and the *release* |
| Derivatives of the atlas | CC BY-SA 4.0 | Attribution and share-alike |

The full table, with what each source requires and the withdrawal plan, is in the methodological note (§2.2 and §2.4); the text of each licence, in `inventario/fuentes.csv`.

## Citing and correcting

- **Citation:** Astiaso Llamazares, G. (2026). *De renta en renta: atlas de vivienda y salarios por sección censal* [software and data]. https://gastiaso.github.io/de-renta-en-renta/. CC BY-SA 4.0. Data source: [original source]. Add the date of the data, which the map gives right below the map, and the date of access.
- **Errors:** they are reported in the issues of the public repository (<https://github.com/gastiaso/de-renta-en-renta/issues>), with the indicator, the area, the year and the source used for comparison (`CONTRIBUTING.md`). Corrections are recorded with their date in the errata below and in the changelog (`CHANGELOG.md`).

## Errata

<!-- erratas -->
