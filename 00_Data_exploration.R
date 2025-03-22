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

VOTOdata$vo

# Get a summary overview
summary(txt_vars)

# Quick glance at structure and data types
glimpse(txt_vars)

# Initialize an empty result tibble
result <- tibble(
  Variable = character(),
  Num_Answered = integer(),
  Num_Not_Answered = integer()
)

# Loop through each variable (column) in the dataframe txt_vars
for (var_name in names(txt_vars)) {
  
  # Count valid responses (at least one letter present)
  num_answered <- sum(grepl("[a-zA-Z]", txt_vars[[var_name]]))
  
  # Count invalid responses (no letters or NA)
  num_not_answered <- sum(!grepl("[a-zA-Z]", txt_vars[[var_name]]) |
                            is.na(txt_vars[[var_name]]))
  
  # Append counts to the results tibble
  result <- result %>% 
    add_row(
      Variable = var_name,
      Num_Answered = num_answered,
      Num_Not_Answered = num_not_answered
    )
}

# Display the summary results
print(result)


# Fälle im Datensatz VOTOdata auswählen, bei denen vote_1 == 3 ist
selected_cases <- VOTOdata %>%
  filter(vote_1 == 3) %>%         # filtere nach vote_1 == 3
  select(reason1_acc1_txt)        # wähle nur die Variable reason1_acc1_txt aus

# Zeige die Werte an
print(selected_cases)

