library(haven)
library(dplyr)
library(httr)
library(stringr)

# Specify the number of cases to process and the round number
n_cases <- 10       # Change to 1000 for actual use
round_num <- 1      # Set to 1 for the first round; 2 (or higher) for subsequent rounds

# Step 1: Load the cleaned .rds dataset
VOTOdata <- readRDS("Datasets/VOTOdata_clean.rds")

# Step 2: Load your API key securely from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load prompt text
questiontext <- paste(readLines("prompt2.txt"), collapse = " ")

# Step 4: Select relevant variables
text_vars <- VOTOdata %>% select(where(is.character)) %>% names()
vote_vars <- c("vote_1", "vote_2", "vote_3", "vote_4", "vote_5")
vars_to_keep <- c("id", vote_vars, text_vars)
VOTOdata_clean <- VOTOdata %>% select(any_of(vars_to_keep))

# Step 5: Filter cases where at least one complete pair of open responses exists:
# either both reason1_acc1_txt and reason2_acc1_txt have text
# or both reason1_den1_txt and reason2_den1_txt have text.
valid_data <- VOTOdata_clean %>%
  filter(
    (grepl("[a-zA-Z]", reason1_acc1_txt) & grepl("[a-zA-Z]", reason2_acc1_txt)) |
      (grepl("[a-zA-Z]", reason1_den1_txt) & grepl("[a-zA-Z]", reason2_den1_txt))
  ) %>%
  select(id, vote_1, reason1_acc1_txt, reason2_acc1_txt, reason1_den1_txt, reason2_den1_txt)

# For rounds beyond the first, exclude cases that have already been processed
if(round_num > 1 && file.exists("chatgpt_analysis_results_combined.csv")){
  previous_results <- read.csv("chatgpt_analysis_results_combined.csv", stringsAsFactors = FALSE)
  valid_data <- valid_data %>% filter(!id %in% previous_results$id)
}

# Randomly sample n_cases cases from the remaining valid data
set.seed(123)  # Optionally set a seed for reproducibility
valid_data <- valid_data %>% sample_n(n_cases)

# Step 6: Initialize a vector to store ChatGPT responses
chatgpt_responses <- vector("character", length = nrow(valid_data))

# Step 7: Loop through each case and send the combined text to the API
for (i in seq_len(nrow(valid_data))) {
  combined_text <- ""
  
  # If the acc pair responses are available, add them to the combined text
  if (grepl("[a-zA-Z]", valid_data$reason1_acc1_txt[i]) & grepl("[a-zA-Z]", valid_data$reason2_acc1_txt[i])) {
    combined_text <- paste0("Acc Pair - Reason 1: ", valid_data$reason1_acc1_txt[i], "\n",
                            "Acc Pair - Reason 2: ", valid_data$reason2_acc1_txt[i])
  }
  
  # If the den pair responses are available, add them (with a newline separator if needed)
  if (grepl("[a-zA-Z]", valid_data$reason1_den1_txt[i]) & grepl("[a-zA-Z]", valid_data$reason2_den1_txt[i])) {
    if (nchar(combined_text) > 0) {
      combined_text <- paste(combined_text, "\n")
    }
    combined_text <- paste0(combined_text,
                            "Den Pair - Reason 1: ", valid_data$reason1_den1_txt[i], "\n",
                            "Den Pair - Reason 2: ", valid_data$reason2_den1_txt[i])
  }
  
  # Build the final prompt with the combined text
  question <- paste(questiontext, "This is case", i, ":\n", combined_text)
  
  # API call to get ChatGPT's response
  r <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    content_type("application/json"),
    add_headers(Authorization = paste("Bearer", APIkey)),
    body = list(
      model = "gpt-4o",
      messages = list(
        list(role = "system", content = question)
      )
    ),
    encode = "json"
  )
  
  # Save the response or an error message
  chatgpt_responses[i] <- tryCatch({
    content(r)$choices[[1]]$message$content
  }, error = function(e) {
    paste("Error in case", i)
  })
  
  cat("Finished case", i, "\n")
}

# Step 8: Combine everything into the final results dataframe
results_df <- valid_data %>%
  mutate(
    chatgpt_response = chatgpt_responses,
    chatgpt_vote = as.integer(str_extract(chatgpt_responses, "^[0-9]+"))
  ) %>%
  select(id, chatgpt_response, chatgpt_vote, vote_1, 
         reason1_acc1_txt, reason2_acc1_txt, reason1_den1_txt, reason2_den1_txt)

# Step 9: Optionally save the results to a CSV file
# For round > 1, append new results to the existing file.
if(round_num > 1 && file.exists("chatgpt_analysis_results_combined.csv")){
  previous_results <- read.csv("chatgpt_analysis_results_combined.csv", stringsAsFactors = FALSE)
  final_results <- bind_rows(previous_results, results_df)
  write.csv(final_results, "chatgpt_analysis_results_combined.csv", row.names = FALSE)
} else {
  write.csv(results_df, "chatgpt_analysis_results_combined.csv", row.names = FALSE)
}

# Print a preview of the results dataframe
print(head(results_df))
