library(haven)
library(dplyr)
library(ggplot2)
library(pROC)

# Step 1: Daten laden
data <- read_sav("Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav")

# Step 2: Variablen auswählen und filtern
model_data <- data %>%
  select(vote_1, birthyear, dectime1, lrsp, income, educ,
         trust_1, importance_1, mediause_3) %>%
  mutate(age = 2020 - birthyear) %>%
  filter(vote_1 %in% c(1, 2),
         !is.na(age),
         !is.na(dectime1),
         !is.na(lrsp),
         !is.na(income),
         !is.na(educ),
         !is.na(trust_1),
         !is.na(importance_1),
         !is.na(mediause_3)) %>%
  mutate(
    voted_flag = ifelse(vote_1 == 1, 1, 0),
    dectime_dummy = ifelse(dectime1 %in% c(12, 13), 1, 0),  # 1 = Spätentscheider, 0 = andere
    lrsp = as.numeric(lrsp),
    income = as.numeric(income),
    educ = as.numeric(educ),
    trust_1 = as.numeric(trust_1),
    importance_1 = as.numeric(importance_1),
    mediause_3 = as.numeric(mediause_3)
  )

# Step 3: Regressionsmodell bauen
model <- glm(voted_flag ~ age + dectime_dummy + lrsp + income + educ +
               trust_1 + importance_1 + mediause_3,
             data = model_data, family = binomial)

summary(model)

# Step 4: Vorhersagewahrscheinlichkeiten berechnen
model_data <- model_data %>%
  mutate(predicted_prob = predict(model, model_data, type = "response"))

# Step 5: ROC & optimaler Schwellenwert
roc_obj <- roc(model_data$voted_flag, model_data$predicted_prob)
optimal_threshold <- coords(roc_obj, "best", ret = "threshold", best.method = "youden")[[1]]
cat("Optimaler Schwellenwert (Youden):", optimal_threshold, "\n")

# Step 6: Klassifikation mit Delta-Bereich
delta <- 0.05
model_data <- model_data %>%
  mutate(predicted_vote = case_when(
    predicted_prob >= (optimal_threshold + delta) ~ 1,
    predicted_prob <= (optimal_threshold - delta) ~ 0,
    TRUE ~ 99
  ))

# Step 7: Bewertung nur für sichere Vorhersagen
eval_data <- model_data %>%
  filter(predicted_vote %in% c(0, 1))

conf_matrix <- table(Actual = eval_data$voted_flag, Predicted = eval_data$predicted_vote)
print("Konfusionsmatrix:")
print(conf_matrix)

# Step 8: Genauigkeit berechnen
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix) * 100
cat("Gesamtgenauigkeit:", round(accuracy, 2), "%\n")
