library(haven)
library(dplyr)
library(httr)
library(stringr)

# Specify the number of cases to process and the round number
n_cases <- 100       # Change to 1000 for actual use
round_num <- 1      # Set to 1 for the first round; 2 (or higher) for subsequent rounds

# Step 1: Load the scrutin dataset (.sav file)
voto_data <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# Step 2: Load your API key securely from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load your custom prompt text from a TXT file.
# The TXT file (e.g., "numeric_prompt.txt") should be in the Datasets folder.
base_prompt <- paste(readLines("numeric_prompt.txt"), collapse = " ")

# Step 4: Select relevant numeric variables.
# We select:
# - id: Identifier
# - vote_1: Actual vote decision (for later comparison)
# - birthyear: To compute Age
# - dectime1: Decision Time for proposal 1
# - lrsp: Political Left-Right placement (numeric scale, e.g. 0 to 10)
# - income: Household Income (numeric coded groups)
# - educ: Highest level of Education (numeric code)
# - trust_1: Trust in the Federal Council (numeric scale 0 to 10)
# - importance_1: Importance of Voting (numeric scale 0 to 10)
selected_vars <- c("id", "vote_1", "birthyear", "dectime1", "lrsp", "income", "educ", "trust_1", "importance_1")
voto_data_numeric <- voto_data %>% select(any_of(selected_vars))

# Step 5: Compute Age from birthyear (if available)
if("birthyear" %in% names(voto_data_numeric)){
  current_year <- 2020  # Adjust as needed
  voto_data_numeric <- voto_data_numeric %>% mutate(age = current_year - birthyear)
}

# Step 6: Recode turnout based on vote_1.
# According to the codebook for vote_1:
#   1 = yes (voted), 2 = no (voted), 3 = blank/did not vote.
# For predicting turnout, we recode:
#   If vote_1 is 1 or 2, then the person is coded as 1 (voted).
#   If vote_1 is 3, then the person is coded as 2 (did not vote).
voto_data_numeric <- voto_data_numeric %>%
  filter(vote_1 %in% c(1,2,3)) %>%
  mutate(voted_flag = if_else(vote_1 %in% c(1,2), 1, 2))  # 1 = voted, 2 = did not vote

# Step 7: Exclude cases with missing values in key numeric predictors.
valid_data <- voto_data_numeric %>%
  filter(!is.na(voted_flag),
         !is.na(dectime1),
         !is.na(lrsp),
         !is.na(income),
         !is.na(educ),
         !is.na(trust_1),
         !is.na(importance_1))
if("age" %in% names(voto_data_numeric)){
  valid_data <- valid_data %>% filter(!is.na(age))
}

# Step 8: Stratified sampling to target approximately one third non-voters.
# Set:
#   n_non: number of non-voters (voted_flag == 2) ≈ one third of n_cases.
#   n_voted: remaining cases (voted_flag == 1).
n_non <- round(n_cases/3)
n_voted <- n_cases - n_non

voters <- valid_data %>% filter(voted_flag == 1)
non_voters <- valid_data %>% filter(voted_flag == 2)

voters_sample <- if(nrow(voters) >= n_voted) {
  voters %>% sample_n(n_voted)
} else {
  voters
}

non_voters_sample <- if(nrow(non_voters) >= n_non) {
  non_voters %>% sample_n(n_non)
} else {
  non_voters
}

valid_data_sample <- bind_rows(voters_sample, non_voters_sample)

# Step 9: For rounds beyond the first, exclude cases that have already been processed.
prev_filename <- paste0("numeric_api_predictions_SCRUTIN_PROMPT_round", round_num - 1, ".csv")
if(round_num > 1 && file.exists(prev_filename)){
  previous_results <- read.csv(prev_filename, stringsAsFactors = FALSE)
  valid_data_sample <- valid_data_sample %>% filter(!id %in% previous_results$id)
}

# Step 10: Randomly sample n_cases from the remaining valid data.
set.seed(123)  # For reproducibility
valid_data_sample <- valid_data_sample %>% sample_n(n_cases)

# Step 11: Initialize a vector to store API responses.
api_responses <- vector("character", length = nrow(valid_data_sample))

# Step 12: Loop through each case, build the numeric prompt, and send it to the API.
for(i in seq_len(nrow(valid_data_sample))){
  # Build numeric details string; include Age if available.
  numeric_details <- ""
  if("age" %in% names(valid_data_sample)){
    numeric_details <- paste0("Age = ", valid_data_sample$age[i], "; ")
  }
  numeric_details <- paste0(numeric_details,
                            "Decision Time (dectime1) = ", valid_data_sample$dectime1[i], "; ",
                            "Left-Right (lrsp) = ", valid_data_sample$lrsp[i], "; ",
                            "Income = ", valid_data_sample$income[i], "; ",
                            "Education (educ) = ", valid_data_sample$educ[i], "; ",
                            "Trust in Federal Council (trust_1) = ", valid_data_sample$trust_1[i], "; ",
                            "Importance of Voting (importance_1) = ", valid_data_sample$importance_1[i], ".")
  
  # Build the final prompt by combining the base prompt with numeric details.
  question <- paste(base_prompt, "This is case", i, ":\n", numeric_details)
  
  # API call to get the numeric prediction.
  r <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    content_type("application/json"),
    add_headers(Authorization = paste("Bearer", APIkey)),
    body = list(
      model = "gpt-4o",  # Adjust model name if necessary.
      messages = list(
        list(role = "system", content = question)
      )
    ),
    encode = "json"
  )
  
  # Extract the API response with error handling.
  response_content <- tryCatch({
    content(r)$choices[[1]]$message$content
  }, error = function(e) {
    paste("Error in case", i)
  })
  
  if(length(response_content) == 0){
    response_content <- paste("Error in case", i)
  }
  
  api_responses[i] <- response_content
  cat("Finished case", i, "\n")
}

# Step 13: Combine the API responses with the original valid data sample.
results_df <- valid_data_sample %>%
  mutate(api_response = api_responses,
         # Extract the first numeric value from the API response.
         api_vote = as.integer(str_extract(api_responses, "^[0-9]+"))
  )

# Step 14: Save the results to a CSV file with a unique name.
output_filename <- paste0("numeric_api_predictions_SCRUTIN_PROMPT_round", round_num, ".csv")
write.csv(results_df, output_filename, row.names = FALSE)

# Print a preview of the results dataframe.
print(head(results_df))
