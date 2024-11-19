SELECT *
FROM dbo.CovidDeaths
ORDER BY 3, 4;
SELECT *
FROM dbo.CovidVaccinations
ORDER BY 3, 4;

-- Select data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1, 2;


-- Looking at total case vs total deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM dbo.CovidDeaths
WHERE location like '%state%'
ORDER BY 1, 2;

-- Looking at total cases vs population
-- Shows what percentage population got covid

SELECT Location, total_cases, population, (total_cases/population)*100 as ContractPertenage
FROM dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Looking at Countries with highest infection rate compared to population 
SELECT location, population, AVG((total_cases/population)*100) OVER (PARTITION BY location) as AvgInfectionPercentage
FROM dbo.CovidDeaths
ORDER BY 3 DESC

SELECT location, population, MAX(total_cases) as HighestTotalCase, MAX(total_cases/population)*100 AS PertentagePopulationInfected
FROM dbo.CovidDeaths
GROUP BY location, population 
ORDER BY 4 DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT 



-- Showing countries with highest death count per population 

SELECT continent, MAX(CAST(total_deaths AS int)) AS HighestDeath
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

-- Showing continents with the highest death count per population

SELECT continent, MAX((total_deaths/population)*100) as DeathPertentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathPertentage DESC;

SELECT date,continent, CAST(total_deaths AS int)
FROM dbo.CovidDeaths
WHERE continent = 'South America'
ORDER BY 3 DESC;

SELECT location, population, MAX(total_deaths) AS HighestDeath, MAX(total_deaths/population)*100 AS DeathPertentage
FROM dbo.CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC;

-- GLOBAL NUMBERS

SELECT SUM(CAST(total_deaths AS int)) AS Total_WorldDeath, SUM(total_cases) AS Total_WorldCases, SUM(CAST(total_deaths AS int))/SUM(total_cases)*100 AS WorldDeathPercentage
FROM dbo.CovidDeaths
WHERE continent is not null
ORDER BY 2,3 DESC;

SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, 
death.date) as RollingPeopleVaccinated
FROM dbo.CovidDeaths death
JOIN dbo.CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
order by 2, 3;


-- Use CTE

;WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vaccine.new_vaccinations, 
SUM(CONVERT(int, vaccine.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS dea
JOIN dbo.CovidVaccinations AS vaccine
	ON dea.location = vaccine.location
	AND dea.date = vaccine.date
WHERE dea.continent IS NOT NULL
)

--SELECT *, (RollingPeopleVaccinated/Population)*100
--FROM PopvsVac


-- Use Temporary table

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated 
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, 
SUM(CONVERT(int, vacc.new_vaccinations)) 
OVER (PARTITION BY death.location ORDER BY death.location, death.date)
FROM dbo.CovidDeaths AS death
JOIN dbo.CovidVaccinations AS vacc
   ON death.location = vacc.location
   AND death.date = vacc.date;
--WHERE death.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100 AS abc
FROM #PercentPopulationVaccinated;

-- Creating View To store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, 
death.date) as RollingPeopleVaccinated
FROM dbo.CovidDeaths death
JOIN dbo.CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--order by 2, 3;

SELECT * 
FROM PercentPopulationVaccinated