library(plyr)
library(caret)
library(tidyverse)
library(tm)
library(knitr)
library(DT)
library(rvest)
library(here)

multipleChoiceResponses <- read_csv(
  here("data", "multipleChoiceResponses.csv"))
conversionRates <- read_csv(here("data", "conversionRates.csv"))

multipleChoiceResponses <- multipleChoiceResponses %>% 
  mutate(CompensationAmount = as.numeric(CompensationAmount)) %>% 
  mutate(Country = ifelse(
    Country == "Republic of China", "China", 
    ifelse(Country == "People 's Republic of China", "China",
           Country)))

df <- multipleChoiceResponses %>% 
  select(GenderSelect:EmploymentStatus, CurrentEmployerType,
         DataScienceIdentitySelect:LearningCategoryOther,
         ParentsEducation:EmployerSearchMethod, RemoteWork,
         CompensationAmount, CompensationCurrency) %>%
  select(-LearningCategoryOther) %>% 
  filter(!is.na(CompensationAmount),
         CompensationAmount > 1)  %>% 
  mutate(CompensationCurrency = ifelse(CompensationCurrency == "Other", NA,
                                       CompensationCurrency))

df <- df %>% 
  filter(Country != "Other")

countries_20 <- df %>% 
  group_by(Country) %>% 
  tally() %>% 
  filter(n >= 20) %>% 
  arrange(desc(n))

df_20 <- df %>% 
  filter(Country %in% countries_20$Country)

df_Compens <- df_20 %>% select(CompensationAmount, CompensationCurrency)

df_20_temp <-  df_20 %>% 
  select(-CompensationAmount, -CompensationCurrency) %>%
  select_if(is.numeric) %>%
  replace(is.na(.), 0)

df_20_temp2 <-  df_20 %>%
  select(-CompensationAmount, -CompensationCurrency) %>%
  select_if(is.character) %>%
  replace(is.na(.), "")

df_20 <- bind_cols(df_20_temp, bind_cols(df_20_temp2, df_Compens))
rm(df_Compens, df_20_temp, df_20_temp2)

df_20 <- df_20 %>% 
  mutate_if(is.character, as.factor)

df_20 <- df_20 %>%
  mutate(FormalEducation_Q = recode_factor(
    FormalEducation,
    "I did not complete any formal education past high school" = 1,
    "Professional degree" = 2,
    "Some college/university study without earning a bachelor's degree" = 3,
    "Bachelor's degree" = 4,
    "Master's degree" = 5,
    "Doctoral degree" = 6,
    "I prefer not to answer" = 0,
    "0" = 0)) %>% 
  mutate(Tenure_Q = recode_factor(
    Tenure,
    "Less than a year" = 0.5,
    "1 to 2 years" = 1.5,
    "3 to 5 years" = 4,
    "6 to 10 years" = 7.5,
    "More than 10 years" = 15,
    "0" = -1,
    "I don't write code to analyze data" = 0)) %>% 
  mutate(EmployerSize_Q = recode_factor(EmployerSize,
                                        "Fewer than 10 employees" = 5,
                                        "10 to 19 employees" = 15,
                                        "20 to 99 employees" = 60,
                                        "100 to 499 employees" = 300,
                                        "500 to 999 employees" = 750,
                                        "1,000 to 4,999 employees" = 2500,
                                        "5,000 to 9,999 employees" = 7500,
                                        "10,000 or more employees" = 50000,
                                        "0" = 0,
                                        "I don't know" = -1,
                                        "I prefer not to answer" = 0)) %>% 
  mutate(FormalEducation_Q = as.numeric(FormalEducation_Q),
         Tenure_Q = as.numeric(Tenure_Q),
         EmployerSize_Q = as.numeric(EmployerSize_Q))

df_20 <- df_20 %>% select(-CurrentEmployerType, -PastJobTitlesSelect,
                          FormalEducation, Tenure, EmployerSize)

df_20 <- df_20 %>% filter(!is.na(CompensationCurrency)) 

country_currency <- df_20 %>% 
  select(Country, CompensationCurrency) %>% 
  group_by(Country, CompensationCurrency) %>% 
  tally() %>%
  ungroup() %>% 
  left_join(conversionRates,
            by = c("CompensationCurrency" = "originCountry")) %>% 
  filter(n > 1) %>% 
  group_by(Country) %>% 
  mutate(frac = round(n/sum(n),2))

df_20 <- df_20 %>% 
  left_join(country_currency, by="Country") %>% 
  mutate(Salary_USD = CompensationAmount * exchangeRate) %>% 
  filter(!is.na(n)) %>% 
  select(-n) %>% 
  group_by(Country) %>% 
  mutate(Compensation_Median_USD = median (Salary_USD)) %>% 
  mutate(Median_to_Salary = Compensation_Median_USD/Salary_USD)

df_20 <- df_20 %>% 
  mutate(Salary_USD = ifelse(
    between(Median_to_Salary, 500, 5000), Salary_USD*1000, 
    ifelse(between(Median_to_Salary, 6, 36), Salary_USD*12, Salary_USD))) %>% 
  mutate(Compensation_Median_USD = median (Salary_USD)) %>% 
  mutate(Median_to_Salary = Compensation_Median_USD/Salary_USD)

write.csv(df_20, here("data", "processed", "cleaned_salaries.csv"),
          row.names = FALSE)

print("Finished data wrangling")