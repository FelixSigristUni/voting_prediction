# Load required packages
library(haven)    # for reading SPSS .sav files
library(dplyr)    # for data manipulation
library(stringr)  # for string handling

# 1. Load the original scrutin dataset
VOTOdata <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# 2. Identify open-ended text response variables for Proposal 1 only (ending in _1_txt)
text_vars <- VOTOdata %>%
  select(contains("_txt")) %>%
  names() %>%
  str_subset("_1_txt$")  # keep only those referring to proposal 1

# 3. Define relevant vote and proposal variables
vote_vars <- c("id", "vote_1", "proposalx1")

# 4. Define numeric predictors
numeric_vars <- c("birthyear", "dectime1", "lrsp", "income", "educ",
                  "trust_1", "importance_1", "mediause_3", "mediause_1")

# 5. Combine all variable names to keep
vars_to_keep <- union(text_vars, union(vote_vars, numeric_vars))
VOTOdata_selected <- VOTOdata %>% select(any_of(vars_to_keep))

# 6. Filter for a specific proposal number (e.g., 605)
VOTOdata_filtered <- VOTOdata_selected %>%
  filter(proposalx1 == 605)

# 7. Keep only rows where at least one relevant text field is non-empty
VOTOdata_filtered <- VOTOdata_filtered %>%
  filter(if_any(all_of(text_vars), ~ !is.na(.) & . != ""))

# 8. Save the cleaned and filtered dataset
saveRDS(VOTOdata_filtered, "Datasets/VOTOdata_clean_proposal_605.rds")
write_sav(VOTOdata_filtered, "Datasets/VOTOdata_clean_proposal_605.sav")
