use Covid_19

select * from covid_19

delete from covid_19 where country = 'Pitcairn'

-- 1. What is the total number of COVID-19 cases recorded in each continent?

select continent, sum(new_cases) as total_cases
from covid_19
group by continent
order by total_cases desc



-- 2. What is the country with the highest total COVID-19 cases?

with Countrywise_cases as(
	select country, 
			sum(new_cases) as total_cases,
			row_number() over (order by sum(new_cases) desc) as ranking
	from covid_19
	group by country
)
select country, total_cases
from Countrywise_cases
where ranking = 1



-- 3. What is the 7-day rolling average of new cases for each country?

select country, 
		[date], 
		new_cases,
		round(avg(new_cases) over (partition by country 
								order by [date]
								rows between 6 preceding and current row), 2) as rolling_avg_7days
from covid_19
order by country, [date]



-- 4. Which country has the highest death rate (total deaths/total cases)?

select  top 1 country,
		100 * sum(new_deaths)/sum(new_cases) as death_rate
from covid_19
group by country
having sum(new_deaths) > 0 and sum(new_cases) > 0
order by death_rate desc



-- 5. How many countries have reported zero deaths despite reporting cases?

select country,
		sum(new_deaths) as total_deaths,
		sum(new_cases) as total_cases
from covid_19
group by country
having sum(new_deaths) = 0 and sum(new_cases) > 0



-- 6. What percentage of the world's population has been fully vaccinated?

select format(round(100.0 * sum(people_fully_vaccinated)/sum(population), 2), 'N2') as percentage_of_people_fully_vaccinated
from covid_19



-- 7. Which countries had the highest and lowest testing rates compared to their population?

go
with test_rate as (
	select country,
			sum(new_tests) as total_test,
			[population] as total_population,
			format(round(100.0 * sum(new_tests)/[population], 2), 'N2') as testing_rates,
			row_number() over (order by round(100.0 * sum(new_tests)/[population], 2) desc) as  highest_ranking,
			row_number() over (order by round(100.0 * sum(new_tests)/[population], 2) asc) as  lowest_ranking
	from covid_19
	where new_tests is not null
	group by country, [population]
)

select country, total_test, total_population, testing_rates
from test_rate
where highest_ranking = 1 

union all

select country, total_test, total_population, testing_rates
from test_rate
where lowest_ranking = 1



-- 8. What is the average positive rate per continent?

select continent, avg(positive_rate) as Average_Positive_rate
from covid_19
group by continent
order by Average_Positive_rate desc



-- 9. Which countries had the highest case fatality rate (deaths/cases) over time?

select  top 1 country,
		100.0 * sum(new_deaths)/nullif(sum(new_cases),0) as Fatality_rate
from covid_19
group by country
order by Fatality_rate desc



-- 10. What is the month-over-month growth rate of total COVID-19 cases globally?

go
with month_over_month as(
select year([date]) as years,
		month([date]) as months,
		sum(new_cases) as current_total_cases,
		lag(sum(new_cases), 1, null) over (order by year([date]), month([date])) as previous_total_cases
from covid_19
group by year([date]), month([date])
)

select *,
		format(round(100.0 * (current_total_cases - previous_total_cases)/previous_total_cases, 2), 'N2') as growth_rate_mom
from month_over_month



-- 11. Which five countries had the highest number of new cases on any single day?

select top 5 country,
		max(new_cases) as highest_cases_perday
from covid_19
group by country
order by highest_cases_perday desc



-- 12. What is the total number of cases recorded in each country by year?

select country,
		year([date]) as years,
		sum(new_cases) as total_cases
from covid_19
group by country, year([date])
order by country, years



-- 13. How does the vaccination rate compare across continents?

with ContinentVaccination as (
    select 
        continent,
        sum(people_fully_vaccinated) as total_vaccinated,
        sum([population]) as total_population,
        round(
            sum(people_fully_vaccinated) * 100.0 / SUM([population]), 2
        ) as vaccination_rate
    from covid_19
    group by continent
)

select * from ContinentVaccination
order by vaccination_rate desc;


