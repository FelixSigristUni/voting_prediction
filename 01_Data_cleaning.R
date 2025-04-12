# Load required packages
library(haven)    # for reading SPSS .sav files
library(dplyr)    # for data manipulation
library(stringr)  # for string handling

# 1. Load the original scrutin dataset
VOTOdata <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# 2. Identify open-ended text response variables
text_vars <- VOTOdata %>%
  select(contains("_txt")) %>%
  names()

# 3. Define relevant variables: vote_1, proposalx1, respondent ID
vote_vars <- c("id", "vote_1", "proposalx1")

# 4. Define numeric predictors
numeric_vars <- c("birthyear", "dectime1", "lrsp", "income", "educ",
                  "trust_1", "importance_1", "mediause_3", "mediause_1")

# 5. Keep only relevant variables
vars_to_keep <- union(text_vars, union(vote_vars, numeric_vars))
VOTOdata_selected <- VOTOdata %>% select(any_of(vars_to_keep))

# 6. Filter for a specific proposal (e.g., proposal number 605)
VOTOdata_filtered <- VOTOdata_selected %>%
  filter(proposalx1 == 605)

# 7. Keep only cases with at least one non-empty open-ended text answer
text_cols <- names(VOTOdata_filtered) %>% str_subset("_txt$")
VOTOdata_filtered <- VOTOdata_filtered %>%
  filter(if_any(all_of(text_cols), ~ !is.na(.) & . != ""))

# 8. Save the filtered and cleaned dataset
saveRDS(VOTOdata_filtered, "Datasets/VOTOdata_clean_proposal_605.rds")
write_sav(VOTOdata_filtered, "Datasets/VOTOdata_clean_proposal_605.sav")
