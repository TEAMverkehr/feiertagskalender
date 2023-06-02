library(dplyr)
library(timeDate)
library(lubridate)
library(clock)
library(tidyr)

JAHRE = 1900:2100
rohdaten = readxl::read_excel("input.xlsx", skip = 1, sheet = "Wikipedia")
rohdaten_typen = readxl::read_excel("input.xlsx", sheet = "Erläuterungen") |> filter(!is.na(Typ))

# Feiertage Ostern vorbereiten ####
datum_ostern = function(year, shift = 0) {
	x = timeDate::Easter(year, shift = shift)
	y = lubridate::as_date(x@Data)
	return(y)
}

apply_rows = function(df, func, bind = TRUE) {
	df1 = lapply(split(df, 1:nrow(df)), func)
	if(bind) df1 <- bind_rows(df1)
	return(df1)
}

feiertage_ostern = rohdaten |>
	filter(!is.na(Ostern_Relation)) |>
	select(Feiertag, Ostern_Offset) |>
	apply_rows(\(df_row) {
		daten = datum_ostern(JAHRE, df_row$Ostern_Offset)
		tibble(Feiertag = df_row$Feiertag, Datum = daten)
	})

# Feiertage mit Datum ####
feiertage_datum = rohdaten |>
	filter(is.na(Ostern_Relation)) |>
	select(Feiertag, Monat, Tag) |>
	apply_rows(\(df_row) {
		daten = clock::date_build(JAHRE, df_row$Monat, df_row$Tag)
		tibble(Feiertag = df_row$Feiertag, Datum = daten)
	})

feiertage = feiertage_datum |>
	bind_rows(feiertage_ostern) |>
	arrange(Datum)

# Daten Kantone zusammenstellen ####
# https://de.wikipedia.org/wiki/Feiertage_in_der_Schweiz#Nationale_und_allgemeine_Feiertage
# Erläuterungen:
# A Den Sonntagen gleichgestellter Feiertag gemäss Art. 20a Abs. 1 ArG im gesamten Kanton
# a Den Sonntagen gleichgestellter oder sonstiger gesetzlich anerkannter Feiertag nur in
#   einigen Gemeinden des Kantons. Bei einigen weiträumig begangenen Ereignissen ist jedoch
#   eventuell auch in den übrigen Kantonsteilen mit Einschränkungen oder Feierlichkeiten zu rechnen
# B Gesetzlich anerkannter öffentlicher Ruhetag im gesamten Kanton
# C Gesetzlich anerkannter halber Feiertag (meist ab 12.00 Uhr) im gesamten Kanton
# c Gesetzlich anerkannter halber Feiertag (meist ab 12.00 Uhr) nur für Mitarbeiter im
#   öffentlichen Dienst, wird in der Regel aber von allen Arbeitsgruppen begangen
# D Gesetzlich nicht anerkannter Feiertag, an dem in der Regel aber trotzdem im gesamten
#   Kanton Arbeitsruhe ist
# d Gesetzlich nicht anerkannter Feiertag, an dem in der Regel aber trotzdem in einigen
#   bestimmten Gemeinden Arbeitsruhe ist
daten_kantone = rohdaten |>
	select(-Datum, -Monat, -Tag, -Ostern_Relation, -Ostern_Offset)

# Fussnoten entfernen
daten_kantone[2:ncol(daten_kantone)] <- daten_kantone[2:ncol(daten_kantone)] |> lapply(substr, 0, 1)

daten_kantone_long = daten_kantone |>
	tidyr::gather("Kanton", "Typ", -Feiertag, na.rm = T) |>
	mutate(Typ = factor(Typ, c("A", "a", "B", "C", "c", "D", "d"), ordered = T))

daten_kantone_long_beschreibung = daten_kantone_long |>
	left_join(rohdaten_typen, "Typ") |>
	mutate(Typ_Beschreibung = factor(Typ_Beschreibung, rohdaten_typen$Typ_Beschreibung))

# Volle Tabelle erstellen
feiertage_kt = feiertage |>
	left_join(daten_kantone, "Feiertag")

feiertage_fulldata = feiertage |>
	full_join(daten_kantone_long, "Feiertag", relationship = "many-to-many") |>
	select(Datum, Feiertag, Kanton, Typ)

feiertage_fulldata_beschreibung = feiertage_fulldata |>
	full_join(daten_kantone_long_beschreibung, "Feiertag", relationship = "many-to-many")

# Export ####
write.csv(daten_kantone, "csv/feiertage_kantone.csv", na = "", row.names = F)
write.csv(rohdaten_typen, "csv/beschreibung_typen.csv", row.names = F)
write.csv(feiertage_fulldata, paste0("csv/feiertage_kantone_", paste(min(JAHRE), max(JAHRE), sep = "-"), ".csv"), row.names = F)
readr::write_rds(feiertage_fulldata, paste0("rds/feiertage_kantone_", paste(min(JAHRE), max(JAHRE), sep = "-"), ".rds"), compress = "xz")
