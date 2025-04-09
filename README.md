# Predicting Swiss Voting Outcomes at the Individual Level

This project explores methods to predict how individuals voted—whether in favor (coded as 1) or against (coded as 2)—in Swiss popular votes. All analyses are performed on individual-level data, capturing the nuances of personal voting behavior without any aggregation.

## Project Overview

Three distinct modeling approaches are employed:

1. **ChatGPT Text Model**  
   Uses open-ended textual responses to predict vote choice. In addition to a numeric prediction, ChatGPT generates a detailed natural language explanation, providing insight into its reasoning.

2. **ChatGPT Numeric Model**  
   Uses a custom-engineered numeric prompt based on individual-level political and demographic indicators such as Age, Decision Time, Political Left-Right placement, Income, Education, Trust in the Federal Council, Importance of Voting, TV Voting Debates Use, and Newspaper Articles Use. This model excludes the direct participation indicator to force reliance on other predictors. ChatGPT returns a numeric prediction (1 for in favor, 2 for against, or 99 if ambiguous) plus a short explanation.

3. **Logistic Regression Model**  
   A traditional statistical model built on the same numeric and categorical predictors as the ChatGPT Numeric Model. This model serves as a baseline and produces only numeric predictions—without any open text explanation.

**What Makes This Project Special**

A unique feature of the ChatGPT models is their ability to provide a natural language explanation for each prediction, offering insight into why a vote was predicted as in favor or against. In contrast, the regression model produces only numerical outputs and coefficients. This layered interpretability can enrich our understanding of the factors influencing vote choice.

## Data

The analyses are based on individual-level data from Swiss popular vote studies. The original dataset is stored in SPSS format:

- `Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav`

Key variables used in the models include:

- **Age:** Computed from `birthyear`
- **Decision Time (dectime1):** When the vote decision was made (1 = clear from the onset, 2 = in the course of the campaign, 3 = at the last moment, 8 = don’t know, 9 = no answer)
- **Political Left-Right (lrsp):** A scale from 0 (extreme left) to 10 (extreme right)
- **Income:** Household income coded into numeric groups
- **Education (educ):** Highest level of education (numeric code)
- **Trust in the Federal Council (trust_1):** Rating from 0 (no trust) to 10 (complete trust)
- **Importance of Voting (importance_1):** Rating from 0 (not important) to 10 (very important)
- **TV Voting Debates Use (mediause_3):** Scale from 0 to 10
- **Newspaper Articles Use (mediause_1):** Scale from 0 to 10

For vote choice, the variable `vote_1` is recoded so that cases with values 1 and 2 (voted in favor or against) are used, while other codes (e.g., 3 for blank or did not vote) are excluded or recoded accordingly.

## Methodology

- **Prompt Engineering (ChatGPT Numeric Model):**  
  A custom prompt is stored in a text file (`numeric_prompt.txt`) located in the working directory. This prompt explains the meaning and range of each numeric indicator and instructs ChatGPT to return a single number along with an explanatory text (using `;;` as a separator). For example, the prompt instructs:  
  *"Based on these indicators, decide whether the individual voted in favor (1) or against (2). If insufficient information is provided, answer 99."*

- **Stratified Sampling:**  
  To ensure a balanced challenge for the numeric model, we exclude the direct participation variable and perform stratified sampling so that roughly one third of the cases are non-voters while two thirds are voters.

- **Evaluation:**  
  Predictions from all three models are saved into uniquely named CSV files. An evaluation script and an accompanying Quarto document (`Model_Comparison_Report.qmd`) generate confusion matrices, overall accuracy metrics, and error rates (false positives and false negatives), and provide a narrative discussion of the results.

## Repository Contents

- **Data Files:**
  - `Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav` – The original individual-level dataset.
  - `openai_key.txt` – Contains your private OpenAI API key (this file must remain confidential).

- **Prompt File:**
  - `numeric_prompt.txt` – Contains the custom prompt for the ChatGPT Numeric Model. Edit this file as needed.

- **Code Files:**
  - `chatgpt_text_model.R` – Code for generating predictions from open-ended text responses.
  - `numeric_api_model.R` – Code for generating predictions using numeric inputs via ChatGPT.
  - `regression_model.R` – Code for building a logistic regression model (note: this model does not process any open text responses).
  - `evaluation_report.R` or `Model_Comparison_Report.qmd` – Integrated reporting script/Quarto document comparing the three models.

- **Output Files:**
  - CSV files with unique names (e.g., `chatgpt_analysis_results_combined.csv`, `numeric_api_predictions_SCRUTIN_PROMPT_roundX.csv`, `regression_predictions.csv`) containing the predictions from each model.

- **Research Note:**
  - A detailed research note is available as a Quarto document (`Model_Comparison_Report.qmd`), documenting the methodology, results, and future research directions.

## Research Note (Quarto Document)

In addition to the code-based analysis, a comprehensive research note is provided as a Quarto document. This document details the complete workflow—from data pre-processing and model building to evaluation—and discusses the unique capability of ChatGPT models to output natural language explanations along with their predictions. The research note also compares these explanations to the purely numeric output of the regression model and offers insights into the strengths and limitations of each approach.

## Future Directions

Future enhancements may include:
- Incorporating additional predictors, such as other media use indicators or measures of political interest.
- Exploring alternative machine learning models (e.g., decision trees, ensemble methods).
- Refining prompt engineering to further optimize ChatGPT responses.
- Utilizing ensemble methods to combine predictions from multiple models for improved accuracy.

## Conclusion

This project demonstrates a multi-method approach for predicting individual vote choice in Swiss popular votes. A key advantage of the ChatGPT-based models is their ability to provide natural language explanations for each prediction—a feature that enhances interpretability compared to traditional regression models, which only provide numerical outputs. This repository, along with the accompanying research note, provides a comprehensive overview of the methodology, evaluation, and future research directions.

---

