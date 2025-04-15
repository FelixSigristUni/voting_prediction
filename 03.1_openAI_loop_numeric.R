library(haven)
library(dplyr)
library(httr)
library(stringr)

# Specify the number of cases to process.
n_cases <- 1000       # Change to 1000 for actual use

# Step 1: Load the clean (.rds file)
voto_data <- readRDS("Datasets/VOTOdata_clean.rds")

# Step 2: Load your API key securely from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load your custom prompt text from a TXT file (in the current working directory)
base_prompt <- paste(readLines("numeric_prompt.txt"), collapse = " ")

# Step 4: Select relevant numeric variables.
# Variables chosen:
# - id: Identifier
# - vote_1: Actual vote decision (1 = voted for, 2 = voted against; 3 = blank/did not vote)
# - birthyear: To compute Age
# - dectime1: Decision Time for proposal 1
# - lrsp: Political Left-Right placement
# - income: Household Income
# - educ: Education level
# - trust_1: Trust in the Federal Council
# - importance_1: Importance of Voting
# - mediause_3: TV Voting Debates Use
selected_vars <- c("id", "vote_1", "birthyear", "dectime1", "lrsp", "income", "educ", "trust_1", "importance_1", "mediause_3")
voto_data_numeric <- voto_data %>% select(any_of(selected_vars))

# Step 5: Compute Age from birthyear (if available)
if("birthyear" %in% names(voto_data_numeric)){
  current_year <- 2020  # Adjust as needed
  voto_data_numeric <- voto_data_numeric %>% mutate(age = current_year - birthyear)
}

# Step 6: Keep only cases with vote_1 equal to 1 (voted for) or 2 (voted against)
voto_data_numeric <- voto_data_numeric %>% filter(vote_1 %in% c(1, 2))

# Step 7: Exclude cases with missing values in key numeric predictors.
valid_data <- voto_data_numeric %>%
  filter(!is.na(vote_1),
         !is.na(dectime1),
         !is.na(lrsp),
         !is.na(income),
         !is.na(educ),
         !is.na(trust_1),
         !is.na(importance_1),
         !is.na(mediause_3))
if("age" %in% names(voto_data_numeric)){
  valid_data <- valid_data %>% filter(!is.na(age))
}

# Step 8: Stratified sampling to obtain balanced groups for "voted for" (vote_1 == 1) and "voted against" (vote_1 == 2).
n_target <- round(n_cases / 2)
voted_for <- valid_data %>% filter(vote_1 == 1)
voted_against <- valid_data %>% filter(vote_1 == 2)

voted_for_sample <- if(nrow(voted_for) >= n_target) {
  voted_for %>% sample_n(n_target)
} else {
  voted_for
}

voted_against_sample <- if(nrow(voted_against) >= n_target) {
  voted_against %>% sample_n(n_target)
} else {
  voted_against
}

valid_data_sample <- bind_rows(voted_for_sample, voted_against_sample)

# Step 9: For rounds beyond the first, exclude cases already processed.
# prev_filename <- paste0("numeric_api_predictions_SCRUTIN_PROMPT_round", round_num - 1, ".csv")
# if(round_num > 1 && file.exists(prev_filename)){
#   previous_results <- read.csv(prev_filename, stringsAsFactors = FALSE)
#   valid_data_sample <- valid_data_sample %>% filter(!id %in% previous_results$id)
# }

# Step 10: Randomly sample n_cases from the remaining valid data if needed.
set.seed(123)  # For reproducibility
if(nrow(valid_data_sample) > n_cases) {
  valid_data_sample <- valid_data_sample %>% sample_n(n_cases)
}

# Step 11: Initialize a vector to store API responses.
api_responses <- vector("character", length = nrow(valid_data_sample))

# Step 12: Loop through each case, build the numeric prompt, and send it to the API.
for(i in seq_len(nrow(valid_data_sample))){
  # Build numeric details string. Include Age if available.
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
                            "Importance of Voting (importance_1) = ", valid_data_sample$importance_1[i], "; ",
                            "TV Voting Debates Use (mediause_3) = ", valid_data_sample$mediause_3[i], ".")
  
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
output_filename <- paste0("numeric_prompt_results", ".csv")
write.csv(results_df, output_filename, row.names = FALSE)

# Print a preview of the results dataframe.
print(head(results_df))
