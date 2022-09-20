-- GNI data
-- Collect all necessary data into one table
ALTER VIEW gni_combined_data AS
SELECT d.[Country Code] AS country_code,
	d.[Country Name] AS location,
	m.Region,
	m.IncomeGroup,
	d.[2021] AS 'gni_2021',
	d.[2020] AS 'gni_2020'
FROM portfolio_project..Data$ d
INNER JOIN portfolio_project..Metadata_Countries$ m
	ON d.[Country Code] = m.[Country Code];

SELECT * FROM gni_combined_data;


-- Nation stats (No GNI for states where no GNI is provided beyond 2020)
ALTER VIEW national_gni_data AS
SELECT country_code,
	location,
	Region,
	IncomeGroup,
	COALESCE(gni_2021, gni_2020) AS latest_gni
FROM gni_combined_data
WHERE Region IS NOT NULL;



-- v_country_data
-- Shows population of countries, ranks them according to population size
ALTER VIEW v_country_data AS 
WITH RN_locations AS (
		SELECT location,
			date,
			ROW_NUMBER() OVER (PARTITION BY location ORDER BY date) AS row_num
		FROM portfolio_project..owid_covid_data$
		WHERE continent IS NOT NULL
	)
SELECT o.iso_code, o.continent, gni.region, gni.IncomeGroup, o.location, o.population, o.population_density, o.median_age, o.aged_65_older,
	o.aged_70_older, o.gdp_per_capita, o.extreme_poverty, o.cardiovasc_death_rate, o.diabetes_prevalence,
	o.female_smokers, o.male_smokers, o.handwashing_facilities, o.hospital_beds_per_thousand,
	o.life_expectancy, o.human_development_index, o.excess_mortality_cumulative_absolute,
	o.excess_mortality_cumulative, o.excess_mortality, o.excess_mortality_cumulative_per_million
FROM portfolio_project..owid_covid_data$ o
INNER JOIN RN_locations RN
	ON RN.location = o.location AND RN.date = o.date
LEFT JOIN national_gni_data gni
	ON gni.country_code = o.iso_code
WHERE RN.row_num = 1;

SELECT * FROM v_country_data;

-- v_vaccinated_data
-- Finding vaccination perc over time 
-- Some country data is sparse - some update weekly
-- Create rolling totals to bridge the gaps and replace NULL values
CREATE VIEW v_vaccinated_data AS
WITH coalesced_cv AS (
		SELECT continent,
			location,
			date,
			population,
			COALESCE(CAST(people_vaccinated AS BIGINT), 0) AS people_vaccinated,
			COALESCE(CAST(people_fully_vaccinated AS BIGINT), 0) AS people_fully_vaccinated,
			COUNT(CAST(people_vaccinated AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS tpv_nullzero, -- To fill in data gaps
			COUNT(CAST(people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY location ORDER BY date) AS tpfv_nullzero
		FROM portfolio_project..owid_covid_data$
		WHERE continent IS NOT NULL
		),
	rollingtot_cv AS (
		SELECT *,
			MAX(people_vaccinated) OVER (PARTITION BY location, tpv_nullzero) AS rollingtot_vaccinated,
			MAX(people_fully_vaccinated) OVER (PARTITION BY location, tpfv_nullzero) AS rollingtot_fullvaccinated
		FROM coalesced_cv
		)
SELECT continent,
	location, 
	date,
	population,
	rollingtot_vaccinated,
	(rollingtot_vaccinated / population) * 100 AS vaccination_perc,
	rollingtot_fullvaccinated,
	(rollingtot_fullvaccinated / population) * 100 AS fullvaccination_perc
FROM rollingtot_cv
WHERE continent IS NOT NULL -- AND ccd.pop_rank <= 30 -- AND cv.location LIKE '%states' -- US data only
;


--  v_cases_data
-- Find confirmed cases over time
-- 7 day rolling average of new cases is also included
CREATE VIEW v_cases_data AS
SELECT continent, 
	location,
	date, 
	COALESCE(new_cases, 0) AS new_cases,
	SUM(COALESCE(new_cases, 0)) OVER 
		(PARTITION BY location ORDER BY date) AS total_cases,
	ROUND(AVG(COALESCE(new_cases, 0)) OVER 
		(PARTITION BY location ORDER BY date
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
		, 2) AS avg7d_new_cases
FROM portfolio_project..owid_covid_data$ 
WHERE continent IS NOT NULL;

SELECT * FROM v_cases_data
ORDER BY pop_rank, date;

-- v_deaths_data
-- Find new and total deaths over time 
-- 7 day rolling average of new deaths is also included
CREATE VIEW v_deaths_data AS
SELECT continent,
	location,
	date,
	COALESCE(CAST(new_deaths AS INT), 0) AS new_deaths,
	SUM(COALESCE(CAST(new_deaths AS INT), 0)) OVER
		(PARTITION BY location ORDER BY date) AS total_deaths,
	ROUND(AVG(COALESCE(CAST(new_deaths AS FLOAT), 0)) OVER
		(PARTITION BY location ORDER BY date
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
		, 2) AS avg7d_new_deaths
FROM portfolio_project..owid_covid_data$
WHERE continent IS NOT NULL
GROUP BY continent, location, date, new_deaths;

SELECT * FROM v_deaths_data
ORDER BY pop_rank, date;



-- v_location_data
-- Combine previously calculated values into one table
CREATE VIEW v_location_data AS
SELECT cc.continent,
	cc.location,
	cc.date, 
	SUM(cc.new_cases) AS new_cases, 
	SUM(SUM(cc.new_cases)) OVER (PARTITION BY cc.location ORDER BY cc.date) AS runningtotal_cases, 
	ROUND(AVG(SUM(cc.new_cases)) OVER
		(PARTITION BY cc.location ORDER BY cc.date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS avg7d_new_cases,
	SUM(cd.new_deaths) AS new_deaths, 
	SUM(SUM(cd.new_deaths)) OVER (PARTITION BY cc.location ORDER BY cc.date) AS runningtotal_deaths,
	ROUND(AVG(SUM(CAST(cd.new_deaths AS FLOAT))) OVER
		(PARTITION BY cc.location ORDER BY cc.date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS avg7d_new_deaths,
	SUM(cv.rollingtot_vaccinated) AS rollingtot_vaccinated,
	ROUND(SUM(cv.rollingtot_vaccinated) / ccd.population * 100, 2) AS perc_one_dose,
	SUM(cv.rollingtot_fullvaccinated) AS rollingtot_fullvaccinated,
	ROUND(SUM(COALESCE(CAST(cv.rollingtot_fullvaccinated AS BIGINT), 0)) / ccd.population * 100, 2) AS perc_full_dose
FROM v_cases_data cc
INNER JOIN v_deaths_data cd
	ON cc.location = cd.location AND cc.date = cd.date
INNER JOIN v_vaccinated_data cv
	ON cc.location = cv.location AND cc.date = cv.date
INNER JOIN v_country_data ccd
	ON cc.location = ccd.location
GROUP BY cc.continent, cc.location, cc.date, ccd.population;

SELECT * FROM v_location_data
ORDER BY continent, location, date;

-- v_stringency_R_data
-- Create a table that contains stringency over time
-- R value for each day is also included
CREATE VIEW v_stringency_R_data AS
SELECT continent,
	location,
	date,
	stringency_index,
	reproduction_rate
FROM portfolio_project..owid_covid_data$
WHERE continent IS NOT NULL;

SELECT * FROM v_stringency_R_data;



-- v_countrydata_covidinfo
-- For all countries, show population data and aggregated values from the dataset
-- average stringency
-- highest stringency
-- total cases/deaths/vaccination_percentage
-- average rolling 7 day average new cases and new deaths
-- highest 7 day average new cases and deaths
-- Join onto the existing v_country_data table
ALTER VIEW v_countrydata_covidinfo AS
WITH rolling_avg_stringency AS (
		SELECT continent,
			location,
			stringency_index,
			ROUND(AVG(stringency_index) OVER 
				(PARTITION BY location ORDER BY date
				ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS avg7d_stringency
		FROM portfolio_project..owid_covid_data$
		),
	with_groupings AS (
		SELECT ld.location AS Location,
			ROUND(AVG(cs.stringency_index), 2) AS avg_stringency,
			MAX(cs.stringency_index) AS max_stringency,
			ROUND(AVG(cs.avg7d_stringency), 2) AS avg7d_stringency,
			MAX(cs.avg7d_stringency) AS max7d_stringency,
			MAX(ld.runningtotal_cases) AS tot_cases,
			ROUND(AVG(ld.avg7d_new_cases), 2) AS avg7d_new_cases,
			MAX(ld.avg7d_new_cases) AS max7d_new_cases,
			MAX(ld.runningtotal_deaths) AS tot_deaths,
			ROUND(AVG(ld.avg7d_new_deaths), 2) AS avg7d_new_deaths,
			MAX(ld.avg7d_new_deaths) AS max7d_new_deaths,
			MAX(perc_one_dose) AS perc_one_dose,
			MAX(perc_full_dose) AS perc_full_dose,
			ROUND(MAX(ld.runningtotal_cases)/1000000, 2) AS permillion_tot_cases,
			ROUND(AVG(ld.avg7d_new_cases)/1000000, 2) AS permillion_avg7d_new_cases,
			ROUND(MAX(ld.avg7d_new_cases)/1000000, 2) AS permillion_max7d_new_cases,
			ROUND(MAX(ld.runningtotal_deaths)/1000000, 2) AS permillion_tot_deaths,
			ROUND(AVG(ld.avg7d_new_deaths)/1000000, 2) AS permillion_avg7d_new_deaths,
			ROUND(MAX(ld.avg7d_new_deaths)/1000000, 2) AS permillion_max7d_new_deaths
		FROM v_location_data ld
		INNER JOIN rolling_avg_stringency cs
			ON ld.location = cs.location
		WHERE cs.avg7d_stringency IS NOT NULL
		GROUP BY ld.location
	)
SELECT o.iso_code, o.continent AS Continent, o.region AS Region, o.IncomeGroup AS Income, o.population, o.population_density, o.median_age, o.aged_65_older,
	o.aged_70_older, o.gdp_per_capita, o.extreme_poverty, o.cardiovasc_death_rate, o.diabetes_prevalence,
	o.female_smokers, o.male_smokers, o.handwashing_facilities, o.hospital_beds_per_thousand,
	o.life_expectancy, o.human_development_index, o.excess_mortality_cumulative_absolute,
	o.excess_mortality_cumulative, o.excess_mortality, o.excess_mortality_cumulative_per_million,
	wg.*
FROM v_country_data o
INNER JOIN with_groupings wg
	ON wg.location = o.location;

SELECT * FROM v_countrydata_covidinfo
ORDER BY population DESC;













