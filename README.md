# Feiertage als CSV-Datensatz

Daten der kantonalen Feiertage 1900 bis 2100 basierend auf den Angaben des Wikipedia-Artikels [Feiertage in der Schweiz](https://de.wikipedia.org/wiki/Feiertage_in_der_Schweiz) und den Oster-Berechnungen des R-Packages [timeDate](https://cran.r-project.org/web/packages/timeDate/index.html) als CSV oder RDS-Datei.

```
# A tibble: 60,099 × 4
Datum      Feiertag   Kanton Typ  
<date>     <chr>      <chr>  <ord>
...
2023-04-07 Karfreitag ZH     A    
2023-04-07 Karfreitag BE     A    
2023-04-07 Karfreitag LU     A    
2023-04-07 Karfreitag UR     A    
2023-04-07 Karfreitag SZ     A    
2023-04-07 Karfreitag OW     A    
2023-04-07 Karfreitag NW     A    
2023-04-07 Karfreitag GL     A    
2023-04-07 Karfreitag ZG     A    
2023-04-07 Karfreitag FR     A    
...
```