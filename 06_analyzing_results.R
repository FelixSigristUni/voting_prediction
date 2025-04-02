# Load necessary libraries
library(ggplot2)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)

# Step 1: Load the results dataset
results_df <- read.csv("chatgpt_analysis_results_combined.csv", stringsAsFactors = FALSE)

# Step 2: Convert vote_1 (actual) and chatgpt_vote (predicted) to factors
results_df <- results_df %>%
  mutate(vote_1 = as.factor(vote_1),
         chatgpt_vote = as.factor(chatgpt_vote))

# Step 3: Create the confusion matrix
confusion_matrix <- table(Actual = results_df$vote_1, Predicted = results_df$chatgpt_vote)
cat("Confusion Matrix:\n")
print(confusion_matrix)

# Step 4: Visualize the confusion matrix as a heatmap
confusion_df <- as.data.frame(confusion_matrix)

heatmap_plot <- ggplot(confusion_df, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "black") +
  geom_text(aes(label = Freq), color = "white", size = 6) +
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Confusion Matrix: ChatGPT Prediction vs. Actual Vote",
       x = "Actual Vote (vote_1)",
       y = "ChatGPT Predicted Vote (chatgpt_vote)") +
  theme_minimal()

print(heatmap_plot)

# Optionally, save the heatmap as a PNG file
ggsave("confusion_matrix_plot.png", heatmap_plot, width = 8, height = 6)

# Step 5: Compute overall accuracy
cm <- as.matrix(confusion_matrix)
overall_accuracy <- sum(diag(cm)) / sum(cm) * 100

# Step 6: Calculate false positives and false negatives percentages per class (relative to total cases)
classes <- rownames(cm)

metrics_list <- data.frame(
  Class = classes,
  False_Positives_Percentage = sapply(classes, function(cls) {
    FP <- sum(cm[, cls]) - cm[cls, cls]
    FP / sum(cm) * 100
  }),
  False_Negatives_Percentage = sapply(classes, function(cls) {
    FN <- sum(cm[cls, ]) - cm[cls, cls]
    FN / sum(cm) * 100
  }),
  stringsAsFactors = FALSE
)

# Step 7: Create a table for overall accuracy
overall_accuracy_table <- data.frame(
  Metric = "Overall Accuracy",
  Value = paste0(round(overall_accuracy, 2), " %")
)

# Format the metrics_list for presentation
metrics_table <- metrics_list %>%
  mutate(
    False_Positives_Percentage = paste0(round(False_Positives_Percentage, 2), " %"),
    False_Negatives_Percentage = paste0(round(False_Negatives_Percentage, 2), " %")
  )

# Step 8: Display the tables in a visually appealing way using kableExtra

# Print Overall Accuracy Table
cat("\nOverall Accuracy:\n")
overall_accuracy_table %>%
  kable(caption = "Overall Accuracy Summary") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

# Print Class Metrics Table
cat("\nClass Metrics:\n")
metrics_table %>%
  kable(caption = "False Positives and False Negatives Percentages per Class") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))








# An overall accuracy of 77.1% was achieved only using open answers
