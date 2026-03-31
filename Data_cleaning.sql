select *
from layoff_dbs.layoffs;
select count(*)
from layoff_dbs.layoffs; #2361

-- 1. Remove Duplicates if any
-- 2. Standardise Date: spell checks, punctuations
-- 3. Null Values or blank values: populating?
-- 4. Remove Unnecessary columns

-- Staging Safety: Ensure integrity of data outside of your work
-- We are conducting a lot of changes and do not want to lose the raw data

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
	SELECT *
    FROM layoffs;

-- Removing Duplicates
/*select *
from (
	select*,
	row_number() 
	over(partition by company, industry, total_laid_off,percentage_laid_off, `date`) as row_num
	from layoffs_staging) as Row_nums
where row_num > 1;
*/ 

# cte

/*
Since  we are partitoning based on the given columns, row number for unique companies should return 1,
anything more than 1 suggests potential duplicates
*/
with check_duplicates as (
select*,
	row_number() 
	over(partition by company,location, industry, total_laid_off,percentage_laid_off, `date`, stage,country, funds_raised_millions) as row_num,
    count(*) 
    over(partition by company,location, industry, total_laid_off,percentage_laid_off, `date`, stage,country, funds_raised_millions) as count_num
    
	from layoffs_staging
)

select * from check_duplicates
where row_num > 1;



-- Verifying duplicates
select * from layoffs_staging
where company = 'Casper';


# Second staging for deleting duplicate rows
CREATE TABLE `layoffs_staging2` (
  `company` varchar(29) NOT NULL,
  `location` varchar(16) NOT NULL,
  `industry` varchar(15) DEFAULT NULL,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` decimal(6,4) DEFAULT NULL,
  `date` varchar(29) DEFAULT NULL,
  `stage` varchar(14) DEFAULT NULL,
  `country` varchar(20) NOT NULL,
  `funds_raised_millions` decimal(10,4) DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
select*,
	row_number() 
	over(partition by company,location, industry, total_laid_off,percentage_laid_off, `date`, stage,country, funds_raised_millions) as row_num
from layoffs_staging;

delete
from layoffs_staging2
where row_num > 1;

select * from layoffs_staging2
where row_num > 1;
select * from layoffs_staging2
having company ='Oda';

-- Standardizing data

# Company
select count(company)
from layoffs_staging2;#2358

Select count(distinct(trim(company)))
from layoffs_staging2;#1885

UPDATE layoffs_staging2
SET company = trim(company);

# Industry
select distinct(industry)
from layoffs_staging2
where industry like 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
where industry like 'Crypto%';

# Location and country

select distinct location
from layoffs_staging2
order by location;

select distinct country
from layoffs_staging2
order by 1; # United States vs United States.

select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET country = trim(trailing '.' from country)
WHERE country like 'United States%';

select `date`,
STR_TO_DATE(`date`, '%m/%d/%y')
from layoffs_staging2;

UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;

# NULLS AND BLANKS
select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select *
from layoffs_staging2
where industry is null
or industry = ' '; #populating nulls industry = travels,

UPDATE layoffs_staging2
SET industry = NULL
where industry = ' ';

select *
from layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company = t2.company and t1.location = t2.location
where (t1.industry is null or t1.industry=' ')
and t2.industry is not null;

UPDATE layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
SET t1.industry = t2.industry
where (t1.industry is null)
and t2.industry is not null;

select *
from layoffs_staging2
where company like "Bally%"; # Bally's Interactive

-- REMOVING DATA
select *
from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null; #361