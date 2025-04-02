-- EDA (Exploratory Data Analysis)

-- with this cleaned dataset we are gonna see if we can find anything interesting, imp insights or any trends and patterns

-- normally when you start the EDA process you have some idea of what you're looking for

-- with this info we are just going to explore and see what we find!


SELECT * 
FROM world_layoffs.layoffs_staging2;



SELECT MAX(total_laid_off), MAX(percentage_laid_off)        
FROM world_layoffs.layoffs_staging2;                                        

-- 12k is the highest laid off and 1 is the highest percentage laid off by the company
-- 1 means 100% laid off from the company, the whole company went under
                  
                  
-- Identify companies that completely shut down (100% layoffs)

SELECT *                                   
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1; 



-- Companies from highest layoff to lowest  within 100% layoff category

SELECT *                                   
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC; 


-- if we order by funds_raised_millions we can see 
-- companies that had maximum funding to min funding within 100% layoff category
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- ----------------------------------------------------------------------------------
-- Layoff analysis by company

-- how much each individual company laid off 
SELECT company, SUM(total_laid_off)        
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;



-- Top 5 Companies with the biggest single Layoff
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 5;


-- Top 10 companies with most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;



SELECT MIN(`date`), MAX(`date`)
FROM world_layoffs.layoffs_staging2;
-- probably we have 3 years of layoffs data according to min and max dates 



 -- Layoff analysis by industry and country

SELECT industry, SUM(total_laid_off)           
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


SELECT country, SUM(total_laid_off)           
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- Unites states and India had the max layoffs during this time



-- Layoff analysis by year

SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;
-- 2023 had the max layoffs of all and that too with just 3 months of data from 2023


-- Most calculation we re gonna do will be based off of laid off column 
-- perc laid off column doesn't help us that much


-- by location
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- By stage
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- ----------------------------------------------------------------------------------

-- Analyze layoffs by year, date, and month to identify trends over time



-- How many layoffs happened on which dates in the past three years
SELECT `date`, SUM(total_laid_off)           
FROM world_layoffs.layoffs_staging2
GROUP BY `date`
ORDER BY 1 DESC ;                           -- most recent dates on the up


-- How many layoffs occurred in which year   -- yearly total of layoffs
SELECT YEAR(`date`), SUM(total_laid_off)          
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC ;                            


-- How many layoffs occurred in which month over the past three years   -- monthly total of layoffs
SELECT SUBSTRING(date, 1, 7) AS MONTH, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(date, 1, 7) IS NOT NULL
GROUP BY MONTH
ORDER BY 1 ;


-- ------------------------------------------------------------------------------------------------------------------

-- Rolling Total of Layoffs Per Month 

WITH Rolling_total AS
(
SELECT SUBSTRING(date,1,7) AS MONTH, SUM(total_laid_off) AS total_off
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(date,1,7) IS NOT NULL
GROUP BY MONTH
)
SELECT MONTH, total_off, SUM(total_off) OVER(ORDER BY MONTH) AS rolling_total
FROM Rolling_total
ORDER BY MONTH ;
 
 
 -- We are looking at the company by the year & how many ppl they laid off :-
 
SELECT company, YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY  company, YEAR(date)                             
ORDER BY 3 DESC;

-- Now use it in a CTE so we can query off of it :-


WITH Company_Year(company, years, total_laid_off) AS 
(
SELECT company, YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY  company, YEAR(date)                            
)
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS RANKK
FROM Company_Year
WHERE years IS NOT NULL;   


-- These are a lot of Rankings, we can also just query off and Rank top 3 companies from each year with the highest layoffs and take a look at those!

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM world_layoffs.layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- we can check for Industry Trends Over Time
SELECT industry, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY industry, years
HAVING years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- we can look at peak layoff periods for each year
SELECT QUARTER(date) AS quarter, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY years, quarter
HAVING years IS NOT NULL
ORDER BY years ASC, quarter ASC;


-- we can also check any correlation between funding and layoff
SELECT company, funds_raised_millions, SUM(total_laid_off) AS total_laid_off
FROM world_layoffs.layoffs_staging2
GROUP BY company, funds_raised_millions
ORDER BY funds_raised_millions desc; 


