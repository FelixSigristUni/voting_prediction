library(ggplot2)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)

# Step 1: Lade die Ergebnisse mit den Vorhersagen
results_df <- read.csv("numeric_regression_predictions.csv", stringsAsFactors = FALSE)

# Step 2: Konvertiere tatsächliche und vorhergesagte Werte in Faktoren
results_df <- results_df %>%
  mutate(voted_flag = as.factor(voted_flag),
         regression_prediction = as.factor(regression_prediction))

# Step 3: Erstelle die Konfusionsmatrix
confusion_matrix <- table(Actual = results_df$voted_flag, Predicted = results_df$regression_prediction)
cat("Konfusionsmatrix:\n")
print(confusion_matrix)

# Step 4: Visualisiere die Konfusionsmatrix als Heatmap
confusion_df <- as.data.frame(confusion_matrix)

heatmap_plot <- ggplot(confusion_df, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "black") +
  geom_text(aes(label = Freq), color = "white", size = 6) +
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Confusion Matrix: Regression Prediction vs. Actual Vote",
       x = "Actual Vote (voted_flag)",
       y = "Predicted Vote (regression_prediction)") +
  theme_minimal()

print(heatmap_plot)

# Optional: Speichere die Heatmap als PNG
ggsave("confusion_matrix_plot_regression.png", heatmap_plot, width = 8, height = 6)

# Step 5: Berechne die Gesamtgenauigkeit
cm <- as.matrix(confusion_matrix)
overall_accuracy <- sum(diag(cm)) / sum(cm) * 100

# Step 6: Berechne False Positives & False Negatives pro Klasse
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

# Prozente hübsch formatieren
metrics_list <- metrics_list %>%
  mutate(
    False_Positives_Percentage = paste0(round(False_Positives_Percentage, 2), " %"),
    False_Negatives_Percentage = paste0(round(False_Negatives_Percentage, 2), " %")
  )

# Step 7: Tabelle mit Gesamtgenauigkeit
overall_accuracy_table <- data.frame(
  Metric = "Overall Accuracy",
  Value = paste0(round(overall_accuracy, 2), " %")
)

# Step 8: Ausgabe als Tabellen (kableExtra)
cat("\nOverall Accuracy:\n")
overall_accuracy_table %>%
  kable(caption = "Overall Accuracy Summary") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

cat("\nClass Metrics:\n")
metrics_list %>%
  kable(caption = "False Positives and False Negatives Percentages per Class") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
