# Predicting Swiss Voting Outcomes at the Individual Level

This project explores methods for predicting how individuals voted—whether in favor (coded as 1) or against (coded as 2)—in Swiss popular votes. All analyses are performed on individual-level data, capturing the nuances of personal voting behavior without aggregation.

## Project Overview

We implement four distinct modeling approaches:

1. **ChatGPT Text Model**  
   Uses open-ended textual responses from voters to predict their vote choice. In addition to a numeric prediction, ChatGPT generates a detailed natural language explanation for its decision.

2. **ChatGPT Numeric Model**  
   Employs a custom-engineered numeric prompt based on key demographic and political indicators (such as Age, Decision Time, Political Left-Right Placement, Income, Education, Trust in the Federal Council, Importance of Voting, TV Voting Debates Use, and Newspaper Articles Use) to predict the vote choice. ChatGPT returns a numeric prediction (1 for in favor, 2 for against, or 99 if ambiguous) along with a brief explanation.

3. **ChatGPT Combined Model**  
   Integrates both textual and numeric inputs. This model leverages information from open-ended responses _and_ numeric indicators, providing a richer context for prediction. Like the other ChatGPT models, it outputs a numeric answer and a brief natural language justification.

4. **Logistic Regression Model**  
   A classical statistical model built on the same key numeric and categorical predictors as the ChatGPT Numeric Model to serve as a baseline.  
   **Note:** This regression model is purely quantitative and does not incorporate any open text responses.

## Data

The analyses are based on individual-level data from Swiss popular vote studies. The original dataset is provided in SPSS format:
- **`Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav`**

Key variables used in the models include:

- **Age:** Computed from `birthyear`.
- **Decision Time (dectime1):** Indicates when the vote decision was made (1 = clear from the onset, 2 = in the course of the campaign, 3 = at the last moment, 8 = don’t know, 9 = no answer).
- **Political Left-Right (lrsp):** A scale from 0 (extreme left) to 10 (extreme right).
- **Income:** Household income, coded into numeric groups.
- **Education (educ):** Highest level of education (numeric code).
- **Trust in the Federal Council (trust_1):** A rating from 0 (no trust) to 10 (complete trust).
- **Importance of Voting (importance_1):** A rating from 0 (not important) to 10 (very important).
- **TV Voting Debates Use (mediause_3):** Usage intensity on a scale from 0 to 10.
- **Newspaper Articles Use (mediause_1):** Usage intensity on a scale from 0 to 10.

For vote choice, the variable `vote_1` is recoded so that only cases with values 1 (voted in favor) or 2 (voted against) are used; cases with value 3 (blank/did not vote) are handled by stratified sampling.

## Methodology

- **Prompt Engineering:**  
  For the ChatGPT models, custom prompts are used.  
  - The **ChatGPT Numeric Model** relies on a prompt (stored in `numeric_prompt.txt`) that explains the meaning and range of each numeric variable and instructs ChatGPT to produce a single numeric response (1, 2, or 99) plus an explanation.  
  - The **ChatGPT Combined Model** further augments this prompt by including both the numeric indicators and select open text responses, providing richer context for prediction.

- **Stratified Sampling:**  
  The sampling approach ensures that the prediction task is challenging. For example, when predicting vote choice, the sample is stratified so that roughly one-third of cases are non-voters (or have voted against), preventing the model from leveraging an imbalanced distribution.

- **Model Evaluation:**  
  Predictions from all models are saved into uniquely named CSV files. Evaluation is performed using confusion matrices, overall accuracy, and error metrics (e.g., false positive and false negative rates). A detailed research note, provided as a Quarto document (`Model_Comparison_Report.qmd`), discusses the methodology, results, and future research directions.

## Repository Contents

- **Data Files:**
  - `Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav` – The original individual-level dataset.
  - `openai_key.txt` – Contains your private OpenAI API key (do not share publicly).

- **Prompt Files:**
  - `numeric_prompt.txt` – Contains the custom prompt for the ChatGPT Numeric and Combined Models. (Edit as needed.)

- **Code Files:**
  - `chatgpt_text_model.R` – Generates predictions using open-ended text responses.
  - `numeric_api_model.R` – Uses numeric variables to generate predictions via ChatGPT.
  - `combined_api_model.R` – Uses a combination of numeric and text inputs for ChatGPT predictions.
  - `regression_model.R` – Builds a logistic regression model (purely numeric/categorical; does not process any open text responses).
  - `evaluation_report.R` or `Model_Comparison_Report.qmd` – Generates an integrated report comparing all models.

- **Output Files:**
  - CSV files with unique names (e.g., `chatgpt_analysis_results_combined.csv`, `numeric_api_predictions_SCRUTIN_PROMPT_roundX.csv`, `combined_api_predictions_roundX.csv`, `regression_predictions.csv`) containing model predictions.

- **Research Note (Quarto Document):**
  - `Model_Comparison_Report.qmd` – A detailed document outlining the workflow, analysis, model comparisons, and future research directions.

## Research Note

A comprehensive research note is provided as a Quarto document. This document details the full analysis pipeline—including data pre-processing, model building, and evaluation—and discusses the unique benefit of ChatGPT’s ability to output natural language explanations with its predictions. In contrast, the regression model relies solely on structured data. The note offers insights into the strengths and limitations of each approach.

## Future Directions

Future enhancements may include:
- Incorporating additional predictors (e.g., further media usage indicators or measures of political interest).
- Experimenting with ensemble methods or alternative machine learning models.
- Refining prompt engineering to optimize the explanatory power of ChatGPT responses.
- Combining predictions from different models to achieve higher accuracy.

## Conclusion

This project demonstrates a multi-method approach to predicting individual vote choice in Swiss popular votes. A key innovation is the use of ChatGPT, which not only predicts vote choice but also provides natural language explanations—enhancing interpretability beyond what traditional regression models offer. The research note further documents and discusses these findings, setting the stage for future work in this area.

---

This README provides an overview of the project’s objectives, methodology, and outputs, along with a brief on the accompanying Quarto research note. Feel free to modify and extend it as necessary.
