# Lade benötigte Pakete
library(haven)   # für read_sav()
library(dplyr)   # für die Datenmanipulation
library(stringr) # für Textverarbeitung

# 1. Datensatz einlesen
VOTOdata <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# 2. Alle Variablennamen mit Text (z. B. *_txt oder ähnliches) filtern
# Alternativ: alle Variablen vom Typ character (also Texte) herausfiltern
text_vars <- VOTOdata %>%
  select(where(is.character)) %>% 
  names()

# 3. Zusätzliche Variablen, die du behalten willst:
vote_vars <- c("vote_1", "vote_2", "vote_3", "vote_4", "vote_5", "id")

# 4. Kombinieren der ausgewählten Variablennamen
vars_to_keep <- c(text_vars, vote_vars)

# 5. Datensatz reduzieren
VOTOdata_clean <- VOTOdata %>%
  select(any_of(vars_to_keep))  # any_of schützt vor Fehlern, falls eine Variable fehlt

# 6. Optional: bereinigten Datensatz speichern (als .rds oder .sav, je nach Wunsch)

# Variante A: als .rds-Datei speichern (empfohlen für R)
saveRDS(VOTOdata_clean, "Datasets/VOTOdata_clean.rds")

# Variante B: als SPSS .sav speichern (wenn du den Datensatz in SPSS weiterverwenden willst)
library(haven)
write_sav(VOTOdata_clean, "Datasets/VOTOdata_clean.sav")

