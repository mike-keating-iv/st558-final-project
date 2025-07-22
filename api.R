# Author: Mike Keating
# Build Date: 7/21/2025

library(plumber)
library(tidyverse)
library(tidymodels)

#* @apiTitle Diabetes Prediction API
#* @apiDescription Predict whether a person has diabetes or not by querying a Random Forest model.

# Load dataset (to compute mean/most frequent values)
diabetes <- read_csv("data/diabetes_binary_health_indicators_BRFSS2015.csv")


defaults <- list(
  # Numeric
  BMI = mean(diabetes$BMI, na.rm = TRUE),
  # Factors
  Age = names(which.max(table(diabetes$Age))),
  Education = as.integer(names(which.max(table(diabetes$Education)))),
  NoDocbcCost = names(which.max(table(diabetes$NoDocbcCost))),
  Income = names(which.max(table(diabetes$Income))),
  PhysActivity = names(which.max(table(diabetes$PhysActivity)))
  
)

# Load our random forest model
load("deployment_model.rda")




#* Make a prediction
#* @param Age:numeric
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
         NoDocbcCost = defaults$NoDocbcCost, # fixed typo
         PhysActivity = defaults$PhysActivity){

  # Get levels from training data
  education_levels <- as.integer(sort(unique(diabetes$Education)))
  income_levels <- as.integer(sort(unique(diabetes$Income)))
  nodoccost_levels <- as.integer(sort(unique(diabetes$NoDocbcCost)))
  physactivity_levels <- as.integer(sort(unique(diabetes$PhysActivity)))

  input_data <- tibble(
    Age = Age,
    BMI = as.numeric(BMI),
    Education = factor(as.integer(Education), levels = education_levels),
    Income = factor(as.integer(Income), levels = income_levels),
    NoDocbcCost = factor(as.integer(NoDocbcCost), levels = nodoccost_levels),
    PhysActivity = factor(as.integer(PhysActivity), levels = physactivity_levels)
  )

  prediction <- predict(rf_deployment_fit, input_data)
  return(prediction)
}


#* Info
#* @get /info
function(){
  info <- list(name = "Mike Keating", link = "https://github.com/mike-keating-iv/st558-final-project")
  return(info)
}

# Examples (test via browser or curl):
# http://localhost:8000/pred?Age=45&BMI=30&Education=1Income=2
# http://localhost:8000/pred?Age=60
# http://localhost:8000/pred