-- looking at total cases vs total deaths--
-- shows likelihood of dying if you contact covid in your country --

select location, date, total_cases, total_deaths, (total_deaths/total_cases) as DeathPercentage
from covidproject.deathcsv
where continent = 'Africa' and location = 'Kenya'
order by 1,2;

-- Looking at total cases vs the population. --
-- shows what percentage of population has covid --

select location, date, total_cases, population, (total_cases/population * 100) as PercentageWithCovid
from covidproject.deathcsv
where continent = 'Africa' and location = 'Kenya'
order by date asc;

-- looking at countries with highest infection rate compared to population --

select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population * 100) as PercentageWithCovid
from covidproject.deathcsv
where continent = 'Africa'
group by location , population
order by PercentageWithCovid desc;

-- showing countries with the highest death count per population

SELECT location, population, 
       MAX(CAST(total_deaths AS SIGNED)) AS HighestDeathCount
FROM covidproject.deathcsv
WHERE continent = 'Africa'
GROUP BY location, population
ORDER BY HighestDeathCount DESC;

-- highest death count in Kenya in one day --
SELECT date, total_cases, total_deaths
FROM covidproject.deathcsv
WHERE location = 'Kenya' 
  AND total_deaths = (
    SELECT MAX(total_deaths) 
    FROM covidproject.deathcsv 
    WHERE location = 'Kenya'
  )
ORDER BY date ASC;

-- LET'S BREAK THINGS DOWN BY CONTINENT --
-- showing the continents with the highest death count per population --


select continent, max(cast(total_deaths as signed)) as TotalDeathCount
from covidproject.deathcsv
WHERE continent IS NOT NULL AND continent != ''
group by continent
order by TotalDeathCount desc;

-- showing the continents with the highest death count per population --

-- GLOBAL NUMBERS

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as signed)) as total_deaths
from covidproject.deathcsv
WHERE continent IS NOT NULL AND continent != ''
group by date
order by 1,2;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    -- Uncomment the next line if you want to calculate the vaccination percentage
    -- , (SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS VaccinationPercentage
FROM 
    covidproject.deathcsv dea
JOIN 
    covidproject.vaccsv vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
ORDER BY 
    dea.location, dea.date;



-- Using CTE to calculate rolling cumulative vaccinations and vaccination percentage

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM 
        covidproject.deathcsv dea
    JOIN 
        covidproject.vaccsv vac
    ON 
        dea.location = vac.location
    AND 
        dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
)

SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM 
    PopvsVac
ORDER BY 
    location, date;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(18, 2),
    New_vaccinations DECIMAL(18, 2),
    RollingPeopleVaccinated DECIMAL(18, 2)
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    covidproject.deathcsv dea
JOIN 
    covidproject.vaccsv vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date;

-- Query from the temporary table with calculated percentage
SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM 
    PercentPopulationVaccinated;




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    , (SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) / dea.population) * 100 AS VaccinationPercentage
FROM 
    covidproject.deathcsv dea
JOIN 
    covidproject.vaccsv vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;







