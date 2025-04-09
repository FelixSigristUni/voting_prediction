library(ggplot2)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)

# Step 1: Load the results dataset from the CSV file.
results_df <- read.csv("numericandtext_api_predictions_SCRUTIN_PROMPT_2round1.csv", stringsAsFactors = FALSE)

# Step 2: Convert the actual turnout (voted_flag) and API predicted turnout (api_vote) to factors.
results_df <- results_df %>%
  mutate(voted_flag = as.factor(voted_flag),
         api_vote = as.factor(api_vote))

# Step 3: Create the confusion matrix comparing Actual (voted_flag) vs. Predicted (api_vote).
confusion_matrix <- table(Actual = results_df$voted_flag, Predicted = results_df$api_vote)
cat("Confusion Matrix:\n")
print(confusion_matrix)

# Step 4: Visualize the confusion matrix as a heatmap.
confusion_df <- as.data.frame(confusion_matrix)

heatmap_plot <- ggplot(confusion_df, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "black") +
  geom_text(aes(label = Freq), color = "white", size = 6) +
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Confusion Matrix: API Prediction vs. Actual Turnout",
       x = "Actual Turnout (voted_flag)",
       y = "API Predicted Turnout (api_vote)") +
  theme_minimal()

print(heatmap_plot)

# Optionally, save the heatmap as a PNG file.
ggsave("confusion_matrix_plot_numeric.png", heatmap_plot, width = 8, height = 6)

# Step 5: Compute overall accuracy.
cm <- as.matrix(confusion_matrix)
overall_accuracy <- sum(diag(cm)) / sum(cm) * 100

# Step 6: Calculate false positives and false negatives percentages per class (relative to total cases).
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
  })
)

# Format percentages with a percentage sign.
metrics_list <- metrics_list %>%
  mutate(
    False_Positives_Percentage = paste0(round(False_Positives_Percentage, 2), " %"),
    False_Negatives_Percentage = paste0(round(False_Negatives_Percentage, 2), " %")
  )

# Step 7: Create a table for overall accuracy.
overall_accuracy_table <- data.frame(
  Metric = "Overall Accuracy",
  Value = paste0(round(overall_accuracy, 2), " %")
)

# Step 8: Display the tables in a visually appealing way using kableExtra.
cat("\nOverall Accuracy:\n")
overall_accuracy_table %>%
  kable(caption = "Overall Accuracy Summary") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

cat("\nClass Metrics:\n")
metrics_list %>%
  kable(caption = "False Positives and False Negatives Percentages per Class") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
