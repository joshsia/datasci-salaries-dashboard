from dash import Dash, html, dcc, Input, Output
import pandas as pd
import altair as alt
from altair import pipe, limit_rows, to_values

alt.renderers.enable('html')
t = lambda data: pipe(data, limit_rows(max_rows=1_000_000), to_values)
alt.data_transformers.register('custom', t)
alt.data_transformers.enable('custom')

# Read in global data
data = pd.read_csv("data/processed/cleaned_salaries.csv")

country_names = data["Country"].unique()
country_names.sort()

education_order = ["Less than bachelor's degree", "Bachelor's degree",
"Master's degree", "Doctoral degree"]

# Setup app
app = Dash(
    __name__,
    external_stylesheets=['https://codepen.io/chriddyp/pen/bWLwgP.css']
    )
server = app.server

app.layout = html.Div([
    html.H2("Data Science Salaries Dashboard"),
    html.Div([
        html.P("Distribution of salaries for different countries"),
        html.Iframe(
            id="boxplot-countries",
            style={'border-width': '0', 'width': '100%', 'height': '455px'}
        ),
        html.P("Set y-axis limits"),
        dcc.RangeSlider(
            id="y-axis-widget", allowCross=False,
            min=0, max=2_600_000, value=[0, 2_600_000],
            marks={i: str(i) for i in range(0, 2_600_001, 500_000)}
        )], style={'width': '48%', 'display': 'inline-block'}),
    html.Div([], style={'width': '4%', 'display': 'inline-block'}),
    html.Div([
        html.P("Histogram of selected country"),
        dcc.Dropdown(
            id="select-country",
            value="Canada",
            options=[{"label": country, "value": country} for country in country_names]
        ),
        html.Div(style={'height': '50px'}),
        html.Iframe(
            id="histogram-country",
            style={'border-width': '0', 'width': '100%', 'height': '400px'}
        )
    ], style={'width': '48%', 'display': 'inline-block'})
    ])

# Plotting functions
@app.callback(
    Output("boxplot-countries", "srcDoc"),
    Input("y-axis-widget", "value")
)
def countries_boxplot(value):
    boxplot_order = (data.groupby("Country")["Salary_USD"]
    .median().sort_values(ascending=False).index.tolist())

    chart = (alt.Chart(data).mark_boxplot(clip=True).encode(
        x=alt.X("Country", sort=boxplot_order),
        y=alt.Y("Salary_USD", title="Salary in USD", 
                scale=alt.Scale(
                    domain=(value[0], value[1])
                    )
                )
            )
        )
    
    return chart.to_html()


@app.callback(
    Output("histogram-country", "srcDoc"),
    Input("select-country", "value")
)
def country_hist(value):
    country = data.query("Country == @value")
    for idx, i in enumerate(country["FormalEducation"]):
        if i in education_order[1:]:
            continue
        else:
            print("Change")
            country["FormalEducation"].iloc[idx] = "Less than bachelor's degree"

    chart = (alt.Chart(country).mark_bar().encode(
        x=alt.X("Salary_USD", bin=alt.Bin(maxbins=20), title="Salary in USD"),
        y=alt.Y("count()", title="Counts"),
        color=alt.Color("FormalEducation", sort=education_order,
        title="Education level"),
        order=alt.Order('education_order:Q')
    ).configure_legend(
        orient='bottom')
    )

    return chart.to_html()



if __name__ == '__main__': app.run_server(debug=True)