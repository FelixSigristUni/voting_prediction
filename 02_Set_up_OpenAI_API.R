# Read the rds file into an R dataframe

VOTOdata_clean <- readRDS("Datasets/VOTOdata_clean.rds")


# Send request to open ai

library(tidyverse)
library(httr)

# Authentication
APIkey <- readLines("openai_key.txt")   # place your API key in a .txt file
bearer <- stringr::str_c("Authorization: Bearer ", APIkey)


#first request
 questiontext<- paste(readLines("prompt1.txt"),collapse = " ")
 # Extract the first non-empty text response from reason1_acc1_txt
 firstcase <- VOTOdata_clean$reason1_acc1_txt[grepl("[a-zA-Z]", VOTOdata_clean$reason1_acc1_txt)][1]
 
 # Display the result
 print(firstcase)

question1<- paste(questiontext, "This is the first case:", firstcase, collapse = " ")

print (question1)

r <- httr::POST(
  url = "https://api.openai.com/v1/chat/completions", 
  content_type("application/json"), 
  add_headers(Authorization = paste("Bearer", APIkey, sep = " ")), 
  body = list(
    model = "gpt-4o", 
    # messages is a list of lists
    messages = list(
      list(role = "system", 
           content = question1 ))
  ), 
  encode = "json"
)
content(r)
cat(content(r)$choices[[1]]$message$content)