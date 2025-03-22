# Read in Dataset and start exploration

## load necessary packages
# install.packages("haven")
# install.packages("dplyr")

library(haven)
library(dplyr)


# Read the SPSS file into an R dataframe
VOTOdata <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# Select variables containing "txt"
txt_vars <- VOTOdata %>% dplyr::select(contains("txt"))

# Get a summary overview
summary(txt_vars)

# Quick glance at structure and data types
glimpse(txt_vars)

# Anzahl Fälle OHNE Buchstaben (keine Antwort oder fehlend)
num_no_answer <- sum(!grepl("[a-zA-Z]", txt_vars$reason1_acc1_txt) | 
                       is.na(txt_vars$reason1_acc1_txt))

# Anzahl Fälle MIT mindestens einem Buchstaben (Antwort vorhanden)
num_answered <- sum(grepl("[a-zA-Z]", txt_vars$reason1_acc1_txt))

# Ergebnisse anzeigen
cat("Keine Antwort (keine Buchstaben oder NA):", num_no_answer, "\n")
cat("Antwort gegeben (mindestens ein Buchstabe):", num_answered, "\n")


