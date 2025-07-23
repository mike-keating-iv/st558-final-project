# Author: Mike Keating
# Base image with R
FROM rocker/r-ver:4.3.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('plumber', 'tidymodels', 'tidyverse', 'ranger'))"

# Create and set working directory
WORKDIR /app

# Copy all necessary files into the container
COPY diabetes-api.R /app/
COPY final_model.rds /app/
COPY data/diabetes_binary_health_indicators_BRFSS2015.csv /app/data/

# Expose port for Plumber
EXPOSE 8000

# Run the API when container starts
CMD ["R", "-e", "pr <- plumber::plumb('diabetes-api.R'); pr$run(host='0.0.0.0', port=8000)"]
