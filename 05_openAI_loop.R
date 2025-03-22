library(haven)
library(dplyr)
library(httr)
library(stringr)

# Step 1: Load the cleaned .rds dataset
VOTOdata <- readRDS("Datasets/VOTOdata_clean.rds")

# Step 2: Load your API key securely from a text file
APIkey <- readLines("openai_key.txt")

# Step 3: Load prompt text
questiontext <- paste(readLines("prompt1.txt"), collapse = " ")

# Step 4: Select relevant variables
text_vars <- VOTOdata %>% select(where(is.character)) %>% names()
vote_vars <- c("vote_1", "vote_2", "vote_3", "vote_4", "vote_5")
vars_to_keep <- c("id", vote_vars, text_vars)
VOTOdata_clean <- VOTOdata %>% select(any_of(vars_to_keep))

# Step 5: Filter for cases where both reason1 AND reason2 have text
valid_data <- VOTOdata_clean %>%
  filter(
    grepl("[a-zA-Z]", reason1_acc1_txt),
    grepl("[a-zA-Z]", reason2_acc1_txt)
  ) %>%
  select(id, vote_1, reason1_acc1_txt, reason2_acc1_txt) %>%
  slice_head(n = 10)  # adjust to 100 later

# Step 6: Initialize vector for responses
chatgpt_responses <- vector("character", length = nrow(valid_data))

# Step 7: Loop through each case and send combined text
for (i in seq_len(nrow(valid_data))) {
  reason1 <- valid_data$reason1_acc1_txt[i]
  reason2 <- valid_data$reason2_acc1_txt[i]
  
  # Combine reasons into one text input for the prompt
  full_text <- paste(
    "Reason 1:", reason1, "\n",
    "Reason 2:", reason2
  )
  
  question <- paste(questiontext, "This is case", i, ":\n", full_text)
  
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
  
  # Save response or error message
  chatgpt_responses[i] <- tryCatch({
    content(r)$choices[[1]]$message$content
  }, error = function(e) {
    paste("Error in case", i)
  })
  
  cat("Finished case", i, "\n")
}

# Step 8: Combine everything into the final results dataframe
results_df <- valid_data %>%
  mutate(chatgpt_response = chatgpt_responses) %>%
  select(id, chatgpt_response, vote_1, reason1_acc1_txt, reason2_acc1_txt)

# Step 9: Optional - Save to CSV
write.csv(results_df, "chatgpt_analysis_results_combined.csv", row.names = FALSE)

# View a preview
print(head(results_df))

