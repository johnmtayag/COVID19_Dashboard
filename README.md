# COVID19_Dashboard

This is a personal project to test my SQL data processing and Power BI visualization skills. 

The datasets used for the data shown were last updated on 9/13/2022. The data was pre-processed and organized into related tables using Microsoft SQL Server. A subset of these tables were uploaded to Power BI:

>**v_countrydata_covidinfo**: Contains individual location information/statistics<br>
>**v_location_data**: Contains daily information on COVID-19 cases, deaths, and vaccinations<br>
>**v_stringency_R_data**: Contains daily information on location response stringency and disease R value<br>

There are two pages - the first gives an overview of COVID-19's worldwide impact while the second focuses on vaccination rates.

<br>
<p align="center">
    <img src="images\COVID_DASH_PG_1_rev_NC.PNG" height="500"><br>
    <br>
    <img src="images\COVID_DASH_PG_2_rev_NC.PNG" height="500"><br>
</p>   
<br>

***
## Filtering Results

The information on both pages can be filtered according to different categories:

* Continent: The continent for each location, as noted in OWID's data
* Income: The income grouping for each location as determined by the World Bank
* Location: Typically countries, these are the individual locations that OWID has data on
* Region: The geographic region for each location as determined by the World Bank

The charts and visuals update dynamically according to the filtered selections. Only one category can be chosen, but multiple sub-categories can be applied to the filter.

<p align="center">
    <img src="images\filters_continent.PNG" height="200">
    <img src="images\filters_location.PNG" height="200"><br>
    <img src="images\filters_income.PNG" height="200">
    <img src="images\filters_region.PNG" height="200"><br>
    <em>Examples of the category and subcategory options</em>
</p>
<br>


****
## Visualizations

The report displays a lot of statistics in data tables, like the total number of people vaccinated, or the total reported cases for each location. There are a few key visuals to highlight to help understand the data.
<br>
<br>

### **Overview**

The overview section on the first page shows quick statistics regarding COVID-19 cases and deaths averaged across the selected locations. On the left are total confirmed cases, total confirmed deaths, and the average response stringency which is a statistic calculated over several metrics determining how stringent each location's response to COVID-19 was. To help compare COVID-19's severity, deaths per 100,000 people and percentage of the global rate are also displayed. When the death rate per 100,000 people is above the global death rate, the percentage shows a red positive number, whereas if it is lower, it shows a blue negative number.
<br>
<p align="center">
    <img src="images\overview_japan.PNG" height="150"><br>
    <img src="images\overview_brazil.PNG" height="150"><br>
    <em>Overview information for Japan (top) and Brazil (bottom)</em>
</p>
<br>

### **Confirmed Cases**

There are two line charts that show two similar metrics regarding case rates from the filtered set of locations. Sliders are included on both axes of both charts to allow the user to "zoom in" and view the data from a specific time interval. 

The first shows the daily 7-day average of newly confirmed cases for each location. The 7-day average was chosen to smooth out the chart as case rates often varied wildly daily. The locations shown on the chart had the highest maximum 7-day average values out of the filtered set of locations. By clicking on a location in the legend and adjusting the y-axis range, it is much easier to see the curve for an individual location.

The second chart depicts the running total of newly confirmed cases over time from the filtered set of locations. The steeper the slope on this chart, the higher the daily confirmed case rates are for each location. Step-shaped curves like with India reflect sharp spikes in daily case rates whereas more overall positive slopes like with the United States reflect consistently higher transmission levels.

<p align="center">
    <img src="images\confirmed_cases_over_time.PNG" height="225">
    <img src="images\confirmed_cases_over_time_zoom_japan.PNG" height="225"><br>
    <em><b>Left:</b> 7-day average total confirmed cases for the top 10 locations in the filtered set<br>
    <b>Right:</b> The adjusted view for a specific location (Japan in this example)</em><br><br>
    <img src="images\rolling_total_confirmed_cases.PNG" height="300"><br>
    <em>Rolling total of confirmed cases for the locations with the highest values</em><br>
</p>
<br>

Clicking on a location on the data table next to these charts will automatically filter for that location's curves and resize the charts accordingly. This makes the connection between the visualizations much more clear:

<p align="center">
    <img src="images\confirmed_cases_over_time_indonesia.PNG" height="500"><br>
    <em>The adjusted views for a specific location (Indonesia in this example). Note how both major spikes correspond with rapid increases in the rolling total, while the wider, lower spikes correspond with a steady increase in confirmed cases.</em>
</p>
<br><br>

### **Severity by Location**

This bubble map chart indicates the severity of COVID-19's impact on different locations around the world. Two metrics are reflected on this chart:

* **Bubble Size**: Total confirmed cases
    * Larger bubble sizes indicate higher total case rates
* **Bubble Color**: Deaths per 100,000 people
    * This metric was chosen over total deaths and deaths per capita to account for differences in population size between locations.
    * White bubbles indicate low death rates while red bubbles indicate high death rates

When hovering the mouse on a bubble, a tooltip will appear that gives the exact numbers for that location along with the total deaths statistic to contextualize the data.

<br>
<p align="center">
    <img src="images\severity_by_location_tooltip.PNG" height="350"><br>
    <em>The tooltips pop-up for the United States</em>
</p>
<br>

### **Percent of Population Vaccinated**

Three main charts help visualize vaccination rates around the world. The contents of both charts can be filtered by the category and subcategory filter options. Vaccination rates were calculated by dividing the rolling total of people vaccinated by the total population of a location.

The bar chart shows the average vaccination rate for the different locations sorted into the selected filter category (in the example below, the average vaccination rates are shown for the different continent categories). Both the single dose and full vaccination rates are shown along with the percentages.

The heat map shows the current full vaccination rate for the filtered set of locations. Darker blue loccations have higher reported vaccination rates than white locations.

The horizontal bar chart compares the vaccination rate directly between individual locations. It is sorted in descending order, and further information can be viewed in the tooltip by hovering over a specific location's bar. Clicking on a location will highlight that location's data on the first chart, directly comparing that individual location's vaccination rate to the average value of its subcategory.

<p align="center">
    <img src="images\percent_population_vaccinated_canada.PNG" height=600"><br>
    <em>The vaccination rates visualized for Canada</em>
</p>
<br>

***
## Citations

>The COVID-19 global data was taken from Our World in Data - the citation is here:<br>
*Hannah Ritchie, Edouard Mathieu, Lucas Rodés-Guirao, Cameron Appel, Charlie Giattino, Esteban Ortiz-Ospina, Joe Hasell, Bobbie Macdonald, Diana Beltekian and Max Roser (2020) - "Coronavirus Pandemic (COVID-19)". Published online at OurWorldInData.org. Retrieved from:* 'https://ourworldindata.org/coronavirus' *[Online Resource]*
>
>Additional information regarding regions and income levels were taken from the World Bank's GNI per capita data and 2020/2021 income brackets. For these locations, the latest GNI and relative income bracket was used, with 2020's being the latest. Locations where the latest GNI was reported earlier than 2020 are excluded from related calculations/filters. The data can be found and downloaded here:<br>
https://data.worldbank.org/indicator/NY.GNP.PCAP.CD
