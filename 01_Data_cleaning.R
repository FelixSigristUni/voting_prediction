# Load required packages
library(haven)    # for read_sav() / write_sav()
library(dplyr)    # for data manipulation
library(stringr)  # for string processing

# 1. Load the original scrutin dataset
VOTOdata <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# 2. Identify text variables needed for the ChatGPT Text Model.
#    These are assumed to include variables with open-ended responses.
#    For example, variables such as reason1_acc1_txt, reason2_acc1_txt, reason1_den1_txt, and reason2_den1_txt.
text_vars <- VOTOdata %>% 
  select(contains("_txt")) %>% 
  names()

# 3. Define vote and identifier variables. These include the vote decision variables and id.
vote_vars <- c("id", "vote_1", "vote_2", "vote_3", "vote_4", "vote_5")

# 4. Define numeric variables needed for the Numeric, Combined, and Regression models.
#    For example, variables for computing Age, Decision Time, Political Orientation, Income, Education,
#    Trust in the Federal Council, Importance of Voting, and Media Usage (TV and Newspaper).
numeric_vars <- c("birthyear", "dectime1", "lrsp", "income", "educ", 
                  "trust_1", "importance_1", "mediause_3", "mediause_1")

# 5. Combine all variable names you want to retain.
vars_to_keep <- union(text_vars, union(vote_vars, numeric_vars))

# 6. Reduce the dataset to only the selected variables.
VOTOdata_clean <- VOTOdata %>% select(any_of(vars_to_keep))

# (Optional) 7. Save the cleaned dataset for further analysis.
# Save as an RDS file (recommended for use in R)
saveRDS(VOTOdata_clean, "Datasets/VOTOdata_clean.rds")
# And/or save as an SPSS .sav file (if needed for external use)
write_sav(VOTOdata_clean, "Datasets/VOTOdata_clean.sav")
