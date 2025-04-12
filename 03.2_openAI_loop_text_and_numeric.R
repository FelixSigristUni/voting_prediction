library(haven)
library(dplyr)
library(httr)
library(stringr)

# Specify the number of cases to process
n_cases <- 1000       # Change to 1000 for actual use
# round_num <- 1      

# Step 1: Load the cleaned .rds dataset
VOTOdata <- readRDS("Datasets/VOTOdata_clean.rds")

# Step 2: Load your OpenAI API key from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load prompt text (which explains the task to ChatGPT)
questiontext <- paste(readLines("textandnumeric_prompt.txt"), collapse = " ")

# Step 4: Select relevant variables: voting data, numeric indicators, and open-ended text responses
vote_vars <- c("vote_1", "vote_2", "vote_3", "vote_4", "vote_5")
numeric_vars <- c("birthyear", "dectime1", "lrsp", "income", "educ", "trust_1", 
                  "importance_1", "mediause_3", "mediause_1")
text_vars <- c("reason1_acc1_txt", "reason2_acc1_txt", "reason1_den1_txt", "reason2_den1_txt")
vars_to_keep <- c("id", vote_vars, numeric_vars, text_vars)

VOTOdata_clean <- VOTOdata %>% select(any_of(vars_to_keep))

# Step 5: Compute age based on birthyear
if("birthyear" %in% names(VOTOdata_clean)){
  current_year <- 2020
  VOTOdata_clean <- VOTOdata_clean %>% mutate(age = current_year - birthyear)
}

# Step 6: Keep only cases that contain at least one complete pair of open responses (acc or den)
valid_data <- VOTOdata_clean %>%
  filter(
    (grepl("[a-zA-Z]", reason1_acc1_txt) & grepl("[a-zA-Z]", reason2_acc1_txt)) |
      (grepl("[a-zA-Z]", reason1_den1_txt) & grepl("[a-zA-Z]", reason2_den1_txt))
  ) %>%
  filter(
    !is.na(dectime1), !is.na(lrsp), !is.na(income), !is.na(educ),
    !is.na(trust_1), !is.na(importance_1), !is.na(mediause_3), !is.na(mediause_1),
    !is.na(age)
  )

# Step 7: OPTIONAL – Exclude already processed cases for subsequent rounds
# if(round_num > 1 && file.exists("chatgpt_analysis_results_combined.csv")){
#   previous_results <- read.csv("chatgpt_analysis_results_combined.csv", stringsAsFactors = FALSE)
#   valid_data <- valid_data %>% filter(!id %in% previous_results$id)
# }

# Step 8: Randomly sample up to n_cases from the valid dataset
set.seed(123)  # Ensures reproducibility
valid_data <- valid_data %>% sample_n(min(n_cases, nrow(valid_data)))

# Step 9: Initialize an empty vector to store ChatGPT responses
chatgpt_responses <- vector("character", length = nrow(valid_data))

# Step 10: Loop over each case, build the prompt, and send it to the OpenAI API
for (i in seq_len(nrow(valid_data))) {
  # --- Build the text response part ---
  combined_text <- ""
  
  if (grepl("[a-zA-Z]", valid_data$reason1_acc1_txt[i]) & grepl("[a-zA-Z]", valid_data$reason2_acc1_txt[i])) {
    combined_text <- paste0("Acc Pair - Reason 1: ", valid_data$reason1_acc1_txt[i], "\n",
                            "Acc Pair - Reason 2: ", valid_data$reason2_acc1_txt[i])
  }
  if (grepl("[a-zA-Z]", valid_data$reason1_den1_txt[i]) & grepl("[a-zA-Z]", valid_data$reason2_den1_txt[i])) {
    if (nchar(combined_text) > 0) {
      combined_text <- paste(combined_text, "\n")
    }
    combined_text <- paste0(combined_text,
                            "Den Pair - Reason 1: ", valid_data$reason1_den1_txt[i], "\n",
                            "Den Pair - Reason 2: ", valid_data$reason2_den1_txt[i])
  }
  
  # --- Build the numeric variable summary string ---
  numeric_info <- paste0(
    "Age = ", valid_data$age[i], "; ",
    "Decision Time (dectime1) = ", valid_data$dectime1[i], "; ",
    "Left-Right (lrsp) = ", valid_data$lrsp[i], "; ",
    "Income = ", valid_data$income[i], "; ",
    "Education (educ) = ", valid_data$educ[i], "; ",
    "Trust in Federal Council (trust_1) = ", valid_data$trust_1[i], "; ",
    "Importance of Voting (importance_1) = ", valid_data$importance_1[i], "; ",
    "TV Voting Debates Use (mediause_3) = ", valid_data$mediause_3[i], "; ",
    "Newspaper Articles Use (mediause_1) = ", valid_data$mediause_1[i], "."
  )
  
  # --- Combine the prompt with case-specific data ---
  full_prompt <- paste(questiontext,
                       "\nThis is case", i, ":\n\n",
                       "Open Responses:\n", combined_text, "\n\n",
                       "Numeric Indicators:\n", numeric_info)
  
  # Send the request to the ChatGPT API
  r <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    content_type("application/json"),
    add_headers(Authorization = paste("Bearer", APIkey)),
    body = list(
      model = "gpt-4o",  # You can change the model name here if needed
      messages = list(
        list(role = "system", content = full_prompt)
      )
    ),
    encode = "json"
  )
  
  # Try to extract the response, ensuring that a non-empty string is always returned
  response_content <- tryCatch({
    out <- content(r)$choices[[1]]$message$content
    if(length(out) == 0) {
      paste("Leere Antwort in Fall", i)
    } else {
      out
    }
  }, error = function(e) {
    paste("Fehler in Fall", i, ":", e$message)
  })
  
  chatgpt_responses[i] <- response_content
  
  cat("Finished case", i, "\n")
}

# Step 11: Combine responses with input data
results_df <- valid_data %>%
  mutate(
    chatgpt_response = chatgpt_responses,
    chatgpt_vote = as.integer(str_extract(chatgpt_responses, "^[0-9]+"))
  ) %>%
  select(id, chatgpt_response, chatgpt_vote, vote_1,
         reason1_acc1_txt, reason2_acc1_txt, reason1_den1_txt, reason2_den1_txt,
         age, dectime1, lrsp, income, educ, trust_1, importance_1, mediause_3, mediause_1)

# Step 12: Save the result as a CSV file
# If you want to merge with previous results, you can uncomment the code below
# if(round_num > 1 && file.exists("chatgpt_analysis_results_combined.csv")){
#   previous_results <- read.csv("chatgpt_analysis_results_combined.csv", stringsAsFactors = FALSE)
#   final_results <- bind_rows(previous_results, results_df)
#   write.csv(final_results, "chatgpt_analysis_results_combined.csv", row.names = FALSE)
# } else {
#   write.csv(results_df, "chatgpt_analysis_results_combined.csv", row.names = FALSE)
# }

# Save normally (no appending)
write.csv(results_df, "textandnumeric_results.csv", row.names = FALSE)

# Step 13: Print a preview of the results
print(head(results_df))
