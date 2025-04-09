library(haven)
library(dplyr)
library(ggplot2)
library(pROC)
library(knitr)
library(kableExtra)

# Step 1: Load the dataset
data <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# Step 2: Keep only strong, significant predictors
model_data <- data %>%
  select(vote_1, birthyear, sex, income, partya,
         typex1, issue1gx1,
         dectime1, importance_1, trust_1) %>%
  mutate(age = 2020 - birthyear) %>%
  filter(vote_1 %in% c(1, 2),
         !is.na(age),
         !is.na(sex),
         !is.na(income),
         !is.na(partya),
         !is.na(typex1),
         !is.na(issue1gx1),
         !is.na(dectime1),
         !is.na(importance_1),
         !is.na(trust_1)) %>%
  mutate(
    vote_1 = factor(vote_1, levels = c(1, 2)),
    sex = as.factor(sex),
    income = as.factor(income),
    partya = as.factor(partya),
    typex1 = as.factor(typex1),
    issue1gx1 = as.factor(issue1gx1),
    dectime1 = as.factor(dectime1),
    importance_1 = as.numeric(importance_1),
    trust_1 = as.numeric(trust_1)
  )

# Step 3: Build the improved logistic regression model
model <- glm(vote_1 ~ age + sex + income + partya +
               typex1 + issue1gx1 + dectime1 + importance_1 + trust_1,
             data = model_data, family = binomial)
summary(model)

# Step 4: Predict probabilities
model_data <- model_data %>%
  mutate(predicted_prob = predict(model, model_data, type = "response"))

# Step 5: Create binary outcome for ROC
model_data <- model_data %>%
  mutate(actual_binary = ifelse(vote_1 == "1", 1, 0))

roc_obj <- roc(response = model_data$actual_binary, predictor = model_data$predicted_prob)
optimal_threshold <- coords(roc_obj, "best", ret = "threshold", best.method = "youden")[[1]]
cat("Optimal threshold (Youden):", optimal_threshold, "\n")

# Step 6: Classify predictions
delta <- 0.05
model_data <- model_data %>%
  mutate(predicted_vote = case_when(
    predicted_prob >= (optimal_threshold + delta) ~ 1,
    predicted_prob <= (optimal_threshold - delta) ~ 2,
    TRUE ~ 99
  ))

# Step 7: Evaluate predictions (excluding ambiguous)
eval_data <- model_data %>%
  filter(predicted_vote %in% c(1, 2))

conf_matrix <- table(Actual = eval_data$vote_1, Predicted = eval_data$predicted_vote)
print("Confusion Matrix:")
print(conf_matrix)

# Step 8: Accuracy and class-specific metrics
cm <- as.matrix(conf_matrix)
overall_accuracy <- sum(diag(cm)) / sum(cm) * 100

overall_accuracy_table <- data.frame(
  Metric = "Overall Accuracy",
  Value = paste0(round(overall_accuracy, 2), " %")
)

classes <- union(rownames(cm), colnames(cm))
metrics_list <- data.frame(
  Class = classes,
  False_Positives_Percentage = sapply(classes, function(cls) {
    FP <- if (cls %in% colnames(cm)) sum(cm[, cls]) else 0
    diag_val <- if (cls %in% rownames(cm) && cls %in% colnames(cm)) cm[cls, cls] else 0
    FP <- FP - diag_val
    FP / sum(cm) * 100
  }),
  False_Negatives_Percentage = sapply(classes, function(cls) {
    FN <- if (cls %in% rownames(cm)) sum(cm[cls, ]) else 0
    diag_val <- if (cls %in% rownames(cm) && cls %in% colnames(cm)) cm[cls, cls] else 0
    FN <- FN - diag_val
    FN / sum(cm) * 100
  })
) %>%
  mutate(
    False_Positives_Percentage = paste0(round(False_Positives_Percentage, 2), " %"),
    False_Negatives_Percentage = paste0(round(False_Negatives_Percentage, 2), " %")
  )

# Step 9: Display results
overall_accuracy_table %>%
  kable(caption = "Overall Accuracy Summary (Optimized Model)") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

metrics_list %>%
  kable(caption = "Class Metrics: False Positives and False Negatives Percentages") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

