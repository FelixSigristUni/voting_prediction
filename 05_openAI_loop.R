# 100 cases test

library(httr)
# Read the rds file into an R dataframe

VOTOdata<- readRDS("Datasets/VOTOdata_clean.rds")

# Load your API key (make sure it's already stored securely)
# APIkey <- "your_actual_api_key"

# Authentication
APIkey <- readLines("openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)

library(haven)
library(dplyr)
library(httr)

# Load your OpenAI API key
# Make sure you have a variable called APIkey with your actual key
# APIkey <- "your_api_key_here"


# Step 2: Keep only text variables + vote_1 to vote_5
text_vars <- VOTOdata %>% select(where(is.character)) %>% names()
vote_vars <- c("vote_1", "vote_2", "vote_3", "vote_4", "vote_5")
vars_to_keep <- c("id", vote_vars, text_vars)
VOTOdata_clean <- VOTOdata %>% select(any_of(vars_to_keep))

# Step 3: Load the prompt text
questiontext <- paste(readLines("prompt1.txt"), collapse = " ")

# Step 4: Filter first 100 non-empty text responses
valid_data <- VOTOdata_clean %>%
  filter(grepl("[a-zA-Z]", reason1_acc1_txt)) %>%
  select(id, vote_1, reason1_acc1_txt) %>%
  slice_head(n = 10)

# Step 5: Initialize empty vector for responses
chatgpt_responses <- vector("character", length = nrow(valid_data))

# Step 6: Loop over the valid cases
for (i in seq_len(nrow(valid_data))) {
  input_text <- valid_data$reason1_acc1_txt[i]
  question <- paste(questiontext, "This is case", i, ":", input_text)
  
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
  
  # Handle the response safely
  chatgpt_responses[i] <- tryCatch({
    content(r)$choices[[1]]$message$content
  }, error = function(e) {
    paste("Error in case", i)
  })
  
  cat("Finished case", i, "\n")
}

# Step 7: Combine everything into a final data frame (in your desired column order)
results_df <- valid_data %>%
  mutate(chatgpt_response = chatgpt_responses) %>%
  select(id, chatgpt_response, vote_1, reason1_acc1_txt)

# Step 8: Optional - Save to CSV
write.csv(results_df, "chatgpt_analysis_results.csv", row.names = FALSE)

# Done!
print(head(results_df))
