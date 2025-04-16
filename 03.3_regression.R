library(haven)
library(dplyr)
library(ggplot2)
library(pROC)

# Step 1: Load the clean (.rds file)
voto_data <- readRDS("Datasets/VOTOdata_clean.rds")

# Step 2: Select only the relevant variables and filter out any cases where vote_1 is not 1 or 2.
# Also, compute age from birthyear.
model_data <- voto_data %>%
  select(vote_1, birthyear, income, trust_1, importance_1) %>%
  mutate(age = 2020 - birthyear) %>%
  filter(vote_1 %in% c(1, 2),
         !is.na(age),
         !is.na(income),
         !is.na(trust_1),
         !is.na(importance_1)) %>%
  mutate(
    income = as.numeric(income),
    trust_1 = as.numeric(trust_1),
    importance_1 = as.numeric(importance_1)
  )

# IMPORTANT: Relevel vote_1 so that the target outcome ("voted for" = 1) is the second level.
# By default, glm() with family = binomial returns the probability of the second level.
model_data <- model_data %>%
  mutate(vote_1 = factor(vote_1, levels = c(2, 1)))
# Now, predicted probabilities correspond to vote_1 == "1" (voted for).

# Step 3: Build the logistic regression model using only the predictors that help.
model <- glm(vote_1 ~ age + income + trust_1 + importance_1,
             data = model_data, family = binomial)
summary(model)

# Step 4: Calculate predicted probabilities.
model_data <- model_data %>%
  mutate(predicted_prob = predict(model, model_data, type = "response"))

# Step 5: Perform ROC analysis and determine the optimal threshold (using Youden's index).
roc_obj <- roc(model_data$vote_1, model_data$predicted_prob)
optimal_threshold <- coords(roc_obj, "best", ret = "threshold", best.method = "youden")[[1]]
cat("Optimal threshold (Youden):", optimal_threshold, "\n")

# Step 6: Classify predictions with a small delta range for uncertainty.
delta <- 0.05
model_data <- model_data %>%
  mutate(predicted_vote = case_when(
    predicted_prob >= (optimal_threshold + delta) ~ 1,
    predicted_prob <= (optimal_threshold - delta) ~ 2,
    TRUE ~ 99  # Uncertain predictions are coded as 99.
  ))

# Step 7: Evaluate only the clear predictions (predicted_vote equal to 1 or 2).
eval_data <- model_data %>%
  filter(predicted_vote %in% c(1, 2))

conf_matrix <- table(Actual = eval_data$vote_1, Predicted = eval_data$predicted_vote)
print("Confusion matrix:")
print(conf_matrix)

# Step 8: Calculate overall accuracy.
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix) * 100
cat("Overall accuracy:", round(accuracy, 2), "%\n")

# Step 9: Export predictions in the desired format.
export_df <- model_data %>%
  filter(predicted_vote %in% c(1, 2)) %>%   # Only clear predictions are exported
  select(vote_1, predicted_vote) %>%
  rename(regression_prediction = predicted_vote)

# Optional: Preview the exported table.
table(export_df$vote_1, export_df$regression_prediction)

# Step 10: Save the export_df as a CSV file for external analysis.
write.csv(export_df, "numeric_regression_predictions.csv", row.names = FALSE)
