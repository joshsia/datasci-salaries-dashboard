# datasci-salaries-dashboard

## About

A simple Dash-py app deployed on Heroku which shows the distribution of data science salaries for different countries.

## Data

Data for this project was obtained from [Kaggle Data Scientists Salaries Around the World](https://www.kaggle.com/ikleiman/data-scientists-salaries-around-the-world/data). Specifically, the files `conversionRates.csv` and `multipleChoiceResponses.csv` are used in this project.

The data is processed using `src/data_cleaning.R` to mainly remove observations that do not have salary data, and to convert all salaries to USD.

## Description of app

The app has a single landing page which shows two plots. The plot on the left corresponds to the boxplots of salaries for all the different countries in the data set. A slider is located below the plot to control the y-axis limits so that users can zoom into regions of the y-axis that they want.

The plot on the right corresponds to the histogram of salaries for a specific country. A dropdown box is located above the plot to select the desired country.

![dashboard](https://github.com/joshsia/datasci-salaries-dashboard/blob/main/dashboard.png)
