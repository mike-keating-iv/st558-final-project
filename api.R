# Author: Mike Keating
# Build Date: 7/21/2025
# API 

library(plumber)
library(tidyverse)
library(tidymodels)

#* @apiTitle Diabetes Prediction API
#* @apiDescription 
#* Predict whether a person has diabetes or not by querying a Random Forest model.
#* 
#* **Inputs include:**
#* 
#* - `Age`: Age group (categorical)  
#*   Valid values: "18-24", "25-29", "30-34", "35-39", "40-44",  
#*   "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80 or older"
#* 
#* - `Income`: Annual income (categorical)  
#*   Valid values: "LT $10K", "$10-15K", "$15-20K", "$20-25K",  
#*   "$25-35K", "$35-50K", "$50-75K", "GT $75K"
#* 
#* - `Education`: Highest education level (categorical)  
#*   Valid values: "None", "Elementary", "Some HS",  
#*   "HS Graduate", "Some College", "College Graduate"
#* 
#* - `NoDocbcCost`: Could not see doctor due to cost (binary)  
#*   Valid values: "No", "Yes"
#* 
#* - `BMI`: Body Mass Index (numeric)



# Load data
diabetes <- read_csv("data/diabetes_binary_health_indicators_BRFSS2015.csv", 
                     show_col_types = FALSE)

# Treat as factor and assign labels
diabetes <- diabetes |> 
  mutate(Income = factor(Income, 
                         levels = 1:8, 
                         labels = c("LT $10k", "$10-15k", 
                                    "$15-20k", "$20-25k", 
                                    "$25-35k","$35-50k", 
                                    "$50-75k", "GT $75k")),
         Education = factor(Education,
                            levels = 1:6,
                            labels = c("None", "Elementary", 
                                       "Some HS", "HS Graduate", 
                                       "Some College", "College Graduate")),
         NoDocbcCost = factor(NoDocbcCost,
                              levels = 0:1,
                              labels = c("No Barrier", "Cost Barrier")),
         Diabetes_binary = factor(Diabetes_binary,
                                  levels = 0:1,
                                  labels = c("Nondiabetic", "Diabetic")),
         PhysActivity = factor(PhysActivity,
                               levels = 0:1,
                               labels = c("No", "Yes")),
         Age = factor(Age, 
                      levels = 1:13,
                      labels = c("18-24","25-29",
                                 "30-34","35-39",
                                 "40-44","45-49",
                                 "50-54","55-59",
                                 "60-64","65-69",
                                 "70-74","75-79",
                                 "80 or older"))) |>
  select(Diabetes_binary, Income, Education, NoDocbcCost, PhysActivity, Age, BMI)


# Get default parameters
# This is tricky because we need to retrieve the most common factor type
# and then return it as a character
defaults <- list(
  Age = diabetes |>
    count(Age) |>
    slice_max(n, n=1) |>
    pull(Age) |>
    as.character(),
  BMI = mean(diabetes$BMI, na.rm = TRUE),
  Income = diabetes |> 
    count(Income) |> 
    slice_max(n, n = 1) |> 
    pull(Income) |> 
    as.character(),
  Education = diabetes |> 
    count(Education) |> 
    slice_max(n, n = 1) |> 
    pull(Education) |> 
    as.character(),
  NoDocbcCost = diabetes |> 
    count(NoDocbcCost) |> 
    slice_max(n, n = 1) |> 
    pull(NoDocbcCost) |> 
    as.character(),
  PhysActivity = diabetes |>
    count(PhysActivity) |>
    slice_max(n, n=1) |>
    pull(PhysActivity) |>
    as.character()
) 
print(defaults)


# Load our random forest model
loaded_wkf <- readRDS("final_model.rds")




#* Make a prediction
#* @param Age
#* @param BMI:numeric
#* @param Education
#* @param NoDocbcCost
#* @param Income
#* @param PhysActivity
#* @get /pred
function(Age = defaults$Age, 
         BMI = defaults$BMI, 
         Education = defaults$Education, 
         Income = defaults$Income, 
         NoDocbcCost = defaults$NoDocbcCost, 
         PhysActivity = defaults$PhysActivity){


  input_data <- tibble(
    Age = factor(Age),
    BMI = as.numeric(BMI),
    Education = factor(Education),
    Income = factor(Income),
    NoDocbcCost = factor(NoDocbcCost),
    PhysActivity = factor(PhysActivity)
    )

  prediction <- predict(loaded_wkf, input_data)
  return(prediction)
}


#* Info
#* @get /info
function(){
  info <- list(name = "Mike Keating", link = "https://github.com/mike-keating-iv/st558-final-project")
  return(info)
}

# Example API calls (you can test in browser or with curl):

# 1. Predict with default values (no parameters passed)
# http://localhost:8000/pred

# 2. Predict with full input — common values
# http://localhost:8000/pred?Age=50-54&BMI=30&Income=GT%20%2475K&Education=Some%20College&NoDocbcCost=No

# 3. Predict with a younger age and lower income
# http://localhost:8000/pred?Age=25-29&BMI=22&Income=LT%20%2410K&Education=High%20School&NoDocbcCost=Yes