# COVID19_Dashboard

This is a personal project to test my SQL data processing and Power BI visualization skills. 

The COVID-19 global data was taken from Our World in Data - the citation is here:<br>
*Hannah Ritchie, Edouard Mathieu, Lucas Rodés-Guirao, Cameron Appel, Charlie Giattino, Esteban Ortiz-Ospina, Joe Hasell, Bobbie Macdonald, Diana Beltekian and Max Roser (2020) - "Coronavirus Pandemic (COVID-19)". Published online at OurWorldInData.org. Retrieved from:* 'https://ourworldindata.org/coronavirus' *[Online Resource]*

Additional information regarding regions and income levels were taken from the World Bank's GNI per capita data and 2020/2021 income brackets. For these locations, the latest GNI and relative income bracket was used, with 2020's being the latest. Locations where the latest GNI was reported earlier than 2020 are excluded from related calculations/filters. The data can be found and downloaded here:<br>
https://data.worldbank.org/indicator/NY.GNP.PCAP.CD

The data was pre-processed and organized into related tables using Microsoft SQL Server. A subset of these tables were uploaded to Power BI:

>**v_countrydata_covidinfo**: Contains individual country information/statistics<br>
>**v_location_data**: Contains daily information on COVID cases, deaths, and vaccinations<br>
>**v_stringency_R_data**: Contains daily information on country response stringency and disease R value<br>

The dashboard has two pages. The first is an overview containing general case/death data while the second focuses on vaccination status. Both pages can be filtered on a continent, income level, location, or region level which aggregates the data and displays it accordingly
