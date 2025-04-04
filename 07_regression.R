library(haven)
library(dplyr)
library(ggplot2)
library(pROC)
library(knitr)
library(kableExtra)

# Step 1: Load your .sav dataset
data <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# Step 2: Select relevant variables and compute age.
# Variables assumed to be present:
# - vote_1: Voting decision (e.g., 1 = yes, 2 = no)
# - birthyear: Year of birth (for computing age)
# - sex: Gender
# - lrsp: Political left–right placement
# - educ: Highest level of education
# - income: Gross monthly household income
# - bigregion: Region of residence
# - partya: Party closeness (proxy for party alignment)
model_data <- data %>%
  select(vote_1, birthyear, sex, lrsp, educ, income, bigregion, partya) %>%
  mutate(age = 2020 - birthyear) %>%  # Adjust current_year as needed
  filter(!is.na(vote_1),
         !is.na(age),
         !is.na(sex),
         !is.na(lrsp),
         !is.na(educ),
         !is.na(income),
         !is.na(bigregion),
         !is.na(partya)) %>%
  mutate(
    vote_1 = as.factor(vote_1),
    sex = as.factor(sex),
    educ = as.factor(educ),
    income = as.factor(income),
    bigregion = as.factor(bigregion),
    partya = as.factor(partya),
    lrsp = as.numeric(lrsp)
  )

# Step 3: Build the logistic regression model.
model <- glm(vote_1 ~ age + sex + lrsp + educ + income + bigregion + partya,
             data = model_data, family = binomial)
summary(model)

# Step 4: Predict probabilities.
model_data <- model_data %>%
  mutate(predicted_prob = predict(model, model_data, type = "response"))

# For ROC analysis, define a binary outcome:
# Assume vote_1 == "1" is positive (1) and vote_1 == "2" is negative (0)
model_data <- model_data %>%
  mutate(actual_binary = ifelse(vote_1 == "1", 1, 0))

roc_obj <- roc(response = model_data$actual_binary, predictor = model_data$predicted_prob)
optimal_threshold <- coords(roc_obj, "best", ret = "threshold", best.method = "youden")[[1]]
cat("Optimal threshold (Youden):", optimal_threshold, "\n")

# Define a delta for ambiguity.
delta <- 0.05

# Step 5: Classify predictions based on the optimal threshold and delta.
# - If predicted_prob >= (optimal_threshold + delta): classify as 1 (yes)
# - If predicted_prob <= (optimal_threshold - delta): classify as 2 (no)
# - Otherwise, classify as 99 (ambiguous)
model_data <- model_data %>%
  mutate(predicted_vote = case_when(
    predicted_prob >= (optimal_threshold + delta) ~ 1,
    predicted_prob <= (optimal_threshold - delta) ~ 2,
    TRUE ~ 99
  ))

# Step 6: Create a confusion matrix.
conf_matrix <- table(Actual = model_data$vote_1, Predicted = model_data$predicted_vote)
print("Confusion Matrix:")
print(conf_matrix)

# Step 7: Calculate quality metrics.
cm <- as.matrix(conf_matrix)
overall_accuracy <- sum(diag(cm)) / sum(cm) * 100

overall_accuracy_table <- data.frame(
  Metric = "Overall Accuracy",
  Value = paste0(round(overall_accuracy, 2), " %")
)

# Get all classes present (in either rows or columns)
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
)

metrics_list <- metrics_list %>%
  mutate(
    False_Positives_Percentage = paste0(round(False_Positives_Percentage, 2), " %"),
    False_Negatives_Percentage = paste0(round(False_Negatives_Percentage, 2), " %")
  )

# Step 8: Display quality metrics tables using kableExtra.
overall_accuracy_table %>%
  kable(caption = "Overall Accuracy Summary") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))

metrics_list %>%
  kable(caption = "Class Metrics: False Positives and False Negatives Percentages") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"))
