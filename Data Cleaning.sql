-- SQL Project  -- Data Cleaning : fixing a lot of issues in the raw data to get it in a more usable format 

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022



SELECT * 
FROM world_layoffs.layoffs;




-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens

CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;



-- Primary steps of data cleaning or make sure to :-
-- 1. Remove duplicates (repititive rows within the table)
-- 2. Standardize the data (fix any spelling, text issues or unnecessary gaps)
-- 3. Null values or Blank values (populate the null values if possible)
-- 4. Remove columns or rows that are unnecesaary




-- 1. Remove Duplicates

# First let's check for duplicates


SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- partitioning by few columns first to see the results


SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- let's just look at oda to confirm

SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate


-- therefore we will partition by every single column of the table instead of few :-

-- these are our real duplicates 
SELECT *
FROM (
		SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
             ROW_NUMBER() OVER (
				PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially


-- now you may want to write it like this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;                             
-- but we cannot update a cte in Mysql

-- one solution is: creating anather table with that row no column and deleting duplicate rows by filterig them out
-- so let's do it!
-- from layoff_staging: copy to clipboard > create statement > paste 


CREATE TABLE `world_layoffs`.`layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;


SELECT *
FROM world_layoffs.layoffs_staging2;

-- now that we have this we can delete rows were row_num is greater than 1

DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;




-- 2. Standardize Data

-- lets look at the company column 
SELECT * 
FROM world_layoffs.layoffs_staging2
ORDER BY company ;
-- we see spaces before few company names, we fill fix that 

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT company, TRIM(company)
FROM layoffs_staging2
WHERE company LIKE ' %' OR company LIKE '% ';


-- lets check location column

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;              -- no issues 

-- lets check for industry column if there are any issues with the data

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

-- it looks like we have some null and empty rows, let's take a look at these


SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;
-- let's take a look at these


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'Bally%';
-- nothing wrong here

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all null

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


-- ---------------------------------------------------

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's set all to Crypto
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- now that's taken care of:
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- --------------------------------------------------

-- we also need to look at other columns

SELECT *
FROM world_layoffs.layoffs_staging2;


-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's remove the period 
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;


-- Let's also fix the date column format :

-- for this we can use str to date function to update this field
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');  

SELECT `date`
FROM world_layoffs.layoffs_staging2
ORDER BY `date` DESC;


-- now we can convert the data type of the date column from text to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- check the fix
SELECT *
FROM world_layoffs.layoffs_staging2;


-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal, we can't populate them based on the given data, we will keep them as they are
-- though we can check for rows that have multiple attributes null and aren't relevant in the table

-- 4. remove any columns and rows we need to

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL;


SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- we dont need row_num column anymore

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT * 
FROM world_layoffs.layoffs_staging2;
