library(haven)
library(dplyr)
library(httr)
library(stringr)

# Specify the number of cases to process and the round number
n_cases <- 100      # Change to a higher number (e.g., 1000) for your full run
# round_num <- 1      # Set to 1 for the first round; 2 (or higher) for subsequent rounds

# Step 1: Load the pre-filtered dataset for proposal 605
voto_data <- readRDS("Datasets/VOTOdata_clean_proposal_605.rds")

# Step 2: Load API key securely from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load custom prompt text from a TXT file
base_prompt <- paste(readLines("titletextandnumeric_prompt.txt"), collapse = " ")

# Step 4: Select relevant variables
selected_vars <- c("id", "vote_1", "birthyear", "dectime1", "lrsp", "income", "educ", 
                   "trust_1", "importance_1", "mediause_3", "mediause_1", "proposalx1")
voto_data_numeric <- voto_data %>% select(any_of(selected_vars))

# Add proposal title manually (already filtered for 605, so we can hardcode this)
proposal_title <- "‘Green Economy’ initiative (Proposal 605) – aiming to reduce Switzerland’s ecological footprint by 2050 and promote a circular economy"

# Step 5: Compute Age from birthyear if available.
if("birthyear" %in% names(voto_data_numeric)){
  current_year <- 2020  # Adjust as needed
  voto_data_numeric <- voto_data_numeric %>% mutate(age = current_year - birthyear)
}

# Step 6: Recode turnout
voto_data_numeric <- voto_data_numeric %>%
  filter(vote_1 %in% c(1, 2, 3)) %>%
  mutate(voted_flag = if_else(vote_1 %in% c(1, 2), 1, 2))

# Step 7: Exclude cases with missing values
valid_data <- voto_data_numeric %>%
  filter(!is.na(voted_flag),
         !is.na(dectime1),
         !is.na(lrsp),
         !is.na(income),
         !is.na(educ),
         !is.na(trust_1),
         !is.na(importance_1),
         !is.na(mediause_3),
         !is.na(mediause_1))
if("age" %in% names(voto_data_numeric)){
  valid_data <- valid_data %>% filter(!is.na(age))
}

# Step 8: Stratified sampling
n_non <- round(n_cases / 3)
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

# # Step 9: Exclude already processed cases
# prev_filename <- paste0("numeric_api_predictions_SCRUTIN_PROMPT_2round", round_num - 1, ".csv")
# if(round_num > 1 && file.exists(prev_filename)){
#   previous_results <- read.csv(prev_filename, stringsAsFactors = FALSE)
#   valid_data_sample <- valid_data_sample %>% filter(!id %in% previous_results$id)
# }

# Step 10: Final sample
set.seed(123)
valid_data_sample <- valid_data_sample %>% sample_n(n_cases)

# Step 11: Initialize vector for API responses
api_responses <- vector("character", length = nrow(valid_data_sample))

# Step 12: Loop through each case and build the prompt
for(i in seq_len(nrow(valid_data_sample))){
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
                            "TV Voting Debates Use (mediause_3) = ", valid_data_sample$mediause_3[i], "; ",
                            "Newspaper Articles Use (mediause_1) = ", valid_data_sample$mediause_1[i], ".")
  
  # Add proposal title to the prompt
  question <- paste0(base_prompt,
                     "\n\nProposal: ", proposal_title,
                     "\n\nThis is case ", i, ":\n", numeric_details)
  
  # Send API request
  r <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    content_type("application/json"),
    add_headers(Authorization = paste("Bearer", APIkey)),
    body = list(
      model = "gpt-4o",  # Change if needed
      messages = list(
        list(role = "system", content = question)
      )
    ),
    encode = "json"
  )
  
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

# Step 13: Combine responses with sample data
results_df <- valid_data_sample %>%
  mutate(api_response = api_responses,
         api_vote = as.integer(str_extract(api_responses, "^[0-9]+")))

# Step 14: Save results
output_filename <- paste0("numericandtext_api_predictions_SCRUTIN_PROMPT_2round", round_num, ".csv")
write.csv(results_df, output_filename, row.names = FALSE)

# Preview results
print(head(results_df))
