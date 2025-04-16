# Predicting Swiss Voting Outcomes at the Individual Level

This project looks into how individual citizens in Switzerland voted in recent popular votes—specifically, whether they voted in favor (coded as 1) or against (coded as 2) a proposal. All analysis is based on individual-level data, without any aggregation, which allows us to take a closer look at personal motivations and decision-making patterns.

## Project Overview

The analysis compares four different models:

1. **ChatGPT Text Model**  
   This model uses the voters' own written justifications to predict how they voted. Along with the prediction (yes or no), it provides a brief explanation of why it thinks the person voted that way.

2. **ChatGPT Numeric Model**  
   Here, only structured data is used—things like age, political orientation, income, education, trust in the government, and so on. The model receives these inputs and gives back a prediction and a short explanation. If the information is unclear, it returns a 99 to indicate uncertainty.

3. **ChatGPT Combined Model**  
   This model uses both the open-ended text responses and the structured numeric data. Combining these inputs allows the model to make more informed predictions and offer better explanations.

4. **Logistic Regression Model**  
   A traditional model that only works with the numeric inputs. It acts as a baseline for comparison. Since it's a classical statistical approach, it doesn’t offer any text-based explanations.

## Data

The dataset used comes from post-vote surveys of Swiss voters. The version used here is in SPSS format:

- `Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav`

Key variables include:

- `birthyear` (used to calculate age)
- `dectime1` – when the voting decision was made
- `lrsp` – political left-right self-assessment (0 to 10 scale)
- `income` – household income bracket
- `educ` – level of education
- `trust_1` – trust in the Federal Council (0 to 10)
- `importance_1` – how important the person considered the vote
- `mediause_3` – how often TV debates were used
- `mediause_1` – how often newspaper articles were used

The main target variable is `vote_1`, where only respondents who voted either in favor (1) or against (2) are considered for prediction. Cases coded as 3 (non-voters) are excluded or handled separately in sampling.

## Methodology

- **Prompt Design**  
  Custom prompts were written to guide ChatGPT’s predictions. For the numeric-only model, the prompt defines each variable and asks for a prediction with an explanation. The combined model extends this by adding excerpts from open-ended answers.

- **Sampling Strategy**  
  Samples were drawn to keep the task non-trivial. For example, groups were balanced to avoid a lopsided dataset that could bias predictions.

- **Evaluation Approach**  
  All predictions are stored in separate CSV files. Model performance is evaluated using confusion matrices, overall accuracy, and false positive/negative rates. A Quarto document provides a complete report of the results and includes comparisons across models.

## Repository Contents

- **Data Files:**
  - `Datasets/1231_VOTO_CumulativeDataset_Data_scrutin_v1.0.0.sav` – Main dataset.
  - `openai_key.txt` – Your OpenAI API key (keep this private).

- **Prompt Files:**
  - `numeric_prompt.txt` – Template used for numeric-only and combined models.

- **Code Files:**
  - `chatgpt_text_model.R` – For predictions based only on open-ended responses.
  - `numeric_api_model.R` – For numeric-only input using ChatGPT.
  - `combined_api_model.R` – Combines text and numeric data for predictions.
  - `regression_model.R` – Standard logistic regression using numeric data.
  - `evaluation_report.R` or `Model_Comparison_Report.qmd` – Runs comparisons and generates the main report.

- **Output Files:**
  - CSV files for each run, e.g., `chatgpt_analysis_results_combined.csv`, `regression_predictions.csv`, etc.

- **Research Note:**
  - `Model_Comparison_Report.qmd` – Walkthrough of the full analysis and results.

## File Structure

This is a quick overview of the scripts and files in this repository and what they’re used for.

### Data Exploration and Preprocessing
- `00_Data_exploration.R` – First look at the raw data.
- `01_Data_cleaning.R` – Main cleaning and recoding script.
- `099_Data_cleaning_old.R` – Older version, kept for backup/reference.

### API Setup and Prompt Templates
- `02_Set_up_OpenAI_API.R` – Loads the OpenAI API key and verifies access.
- `prompt1.txt`, `prompt2.txt`, `numeric_prompt.txt`, `textandnumeric_prompt.txt` – Variants of prompts for different models.

### Model Execution Scripts
- `03_openAI_loop.R` – General script for looping through cases.
- `03.1_openAI_loop_numeric.R` – Runs predictions based on numeric data.
- `03.2_openAI_loop_text_and_numeric.R` – Runs predictions using both data types.
- `03.3_regression.R` – Sets up and runs the logistic regression model.
- `03_openAI_loop_proposaltitle.R` – Variant using proposal titles; no longer in active use.

### Analysis Scripts
- `04.1_analyzing_results_numeric.R` – Evaluates predictions from the numeric model.
- `04.2_analyzing_results_textandnumeric.R` – Evaluates the combined model.
- `04.3_analyzing_results_regression_prediction.R` – Evaluation for the regression model.
- `04_analyzing_results.R` – Earlier script used for general analysis.

### Documentation and Reporting
- `05_report.qmd` – Source file for the full written report.
- `05_report.pdf` – Exported PDF version.
- `Milestones.xlsx` – Timeline and planning document.
- `README.md` – This file.
- `voting_prediction.Rproj` – RStudio project file.

## Research Note

The full analysis, including discussion of each model’s performance and limitations, is included in the Quarto report. The models based on ChatGPT offer explanations in natural language, while the logistic regression model is more limited to numeric output.

## Future Directions

Things that could be added or improved:
- Try additional variables, such as political interest or more detailed media use.
- Experiment with ensemble models or other machine learning methods.
- Tune prompts more carefully to improve explanation quality.
- Combine outputs from different models for better overall accuracy.

## Conclusion

This project combines traditional statistical tools with large language models to explore how people vote in Swiss popular votes. One of the most useful features of using ChatGPT is that it doesn't just give a prediction—it also tells you why. This adds a layer of interpretability that’s hard to get from standard models. The full report provides more detail and context behind all the results and modeling choices.

