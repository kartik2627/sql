select * from salaries;
select job_title from salaries;
/*Identifying Fully Remote Work for Managers with Salaries Over $90,000 USD:*/
SELECT DISTINCT(company_location) 
FROM salaries 
WHERE job_title LIKE '%Manager%' 
AND salary_IN_usd > 90000 
AND remote_ratio = 100;

/*2.AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. you're tasked WITH 
Identifying top 5 Country Having  greatest count of large(company size) number of companies.*/
/*Identifying Top 5 Countries with Large Companies for Freshers:
The query correctly groups and counts companies based on location and size. It provides a helpful insight for your startup.*/
SELECT company_location, COUNT(company_size) AS cnt 
FROM (
    SELECT * 
    FROM salaries 
    WHERE experience_level = 'EN' AND company_size = 'L'
) AS t  
GROUP BY company_location 
ORDER BY cnt DESC
LIMIT 5;

/*3. Picture yourself AS a data scientist Working for a workforce management platform. Your objective is to calculate the percentage of employees. 
Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying remote positions IN today's job market.*/
SET @COUNT = (SELECT COUNT(*) FROM salaries WHERE salary_IN_usd > 100000 AND remote_ratio = 100);
SET @total = (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000);
SET @percentage = ROUND((((SELECT @COUNT) / (SELECT @total)) * 100), 2);
SELECT @percentage AS '% of people working remotely and having salary > $100,000 USD';

SELECT company_location, t.job_title, average_per_country, average 
FROM (
    SELECT company_location, job_title, AVG(salary_IN_usd) AS average_per_country 
    FROM salaries 
    WHERE experience_level = 'EN' 
    GROUP BY company_location, job_title
) AS t 
INNER JOIN (
    SELECT job_title, AVG(salary_IN_usd) AS average 
    FROM salaries 
    WHERE experience_level = 'EN'  
    GROUP BY job_title
) AS p 
ON t.job_title = p.job_title 
WHERE average_per_country > average;


SELECT company_location, job_title, average 
FROM (
    SELECT *, DENSE_RANK() OVER (PARTITION BY job_title ORDER BY average DESC) AS num 
    FROM (
        SELECT company_location, job_title, AVG(salary_IN_usd) AS average 
        FROM salaries 
        GROUP BY company_location, job_title
    ) AS k
) AS t  
WHERE num = 1;

/*6.  AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations.
 Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years (Countries WHERE data is available for 3 years Only(this and pst two years) 
 providing Insights into Locations experiencing Sustained salary growth.*/
WITH t AS (
    SELECT * 
    FROM salaries 
    WHERE company_location IN (
        SELECT company_location 
        FROM (
            SELECT company_location, AVG(salary_IN_usd) AS AVG_salary, COUNT(DISTINCT work_year) AS num_years 
            FROM salaries 
            WHERE work_year >= YEAR(CURRENT_DATE()) - 2 
            GROUP BY company_location 
            HAVING num_years = 3 
        ) AS m
    )
)
SELECT 
    company_location,
    MAX(CASE WHEN work_year = 2022 THEN average END) AS AVG_salary_2022,
    MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023,
    MAX(CASE WHEN work_year = 2024 THEN average END) AS AVG_salary_2024
FROM (
    SELECT company_location, work_year, AVG(salary_IN_usd) AS average 
    FROM t 
    GROUP BY company_location, work_year
) AS q 
GROUP BY company_location 
HAVING AVG_salary_2024 > AVG_salary_2023 AND AVG_salary_2023 > AVG_salary_2022;

 /* 7.	Picture yourself AS a workforce strategist employed by a global HR tech startup. Your missiON is to determINe the percentage of  fully remote work for each 
 experience level IN 2021 and compare it WITH the correspONdINg figures for 2024, highlightINg any significant INcreASes or decreASes IN remote work adoptiON
 over the years.*/
WITH t1 AS (
    SELECT 
        a.experience_level, 
        total_remote,
        total_2021, 
        ROUND(((total_remote / total_2021) * 100), 2) AS '2021 remote %' 
    FROM (
        SELECT 
            experience_level, 
            COUNT(experience_level) AS total_remote 
        FROM salaries 
        WHERE work_year = 2021 AND remote_ratio = 100 
        GROUP BY experience_level
    ) a
    INNER JOIN (
        SELECT  
            experience_level, 
            COUNT(experience_level) AS total_2021 
        FROM salaries 
        WHERE work_year = 2021 
        GROUP BY experience_level
    ) b ON a.experience_level = b.experience_level
),
t2 AS (
    SELECT 
        a.experience_level, 
        total_remote,
        total_2024, 
        ROUND(((total_remote / total_2024) * 100), 2) AS '2024 remote %' 
    FROM (
        SELECT 
            experience_level, 
            COUNT(experience_level) AS total_remote 
        FROM salaries 
        WHERE work_year = 2024 AND remote_ratio = 100 
        GROUP BY experience_level
    ) a
    INNER JOIN (
        SELECT  
            experience_level, 
            COUNT(experience_level) AS total_2024 
        FROM salaries 
        WHERE work_year = 2024 
        GROUP BY experience_level
    ) b ON a.experience_level = b.experience_level
)
SELECT * FROM t1 INNER JOIN t2 ON t1.experience_level = t2.experience_level;

/* 8. AS a compensatiON specialist at a Fortune 500 company, you're tASked WITH analyzINg salary trends over time. Your objective is to calculate the average 
salary INcreASe percentage for each experience level and job title between the years 2023 and 2024, helpINg the company stay competitive IN the talent market.*/
WITH t AS (
    SELECT 
        experience_level, 
        job_title,
        work_year, 
        ROUND(AVG(salary_in_usd), 2) AS 'average'  
    FROM salaries 
    WHERE work_year IN (2023, 2024) 
    GROUP BY experience_level, job_title, work_year
)
SELECT 
    *, 
    ROUND((((AVG_salary_2024 - AVG_salary_2023) / AVG_salary_2023) * 100), 2) AS changes
FROM (
    SELECT 
        experience_level, 
        job_title,
        MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023,
        MAX(CASE WHEN work_year = 2024 THEN average END) AS AVG_salary_2024
    FROM t 
    GROUP BY experience_level, job_title
) a 
WHERE (((AVG_salary_2024 - AVG_salary_2023) / AVG_salary_2023) * 100) IS NOT NULL;

/* 9. You're a database administrator tasked with role-based access control for a company's employee database. Your goal is to implement a security measure where employees
 in different experience level (e.g.Entry Level, Senior level etc.) can only access details relevant to their respective experience_level, ensuring data 
 confidentiality and minimizing the risk of unauthorized access.*/
CREATE USER 'Entry_level'@'%' IDENTIFIED BY 'EN';
CREATE USER 'Junior_Mid_level'@'%' IDENTIFIED BY 'MI'; 
CREATE USER 'Intermediate_Senior_level'@'%' IDENTIFIED BY 'SE';
CREATE USER 'Expert_Executive_level'@'%' IDENTIFIED BY 'EX';
CREATE VIEW entry_level AS
SELECT * FROM salaries WHERE experience_level = 'EN';
GRANT SELECT ON campusx.entry_level TO 'Entry_level'@'%';


/* 10.	You are working with an consultancy firm, your client comes to you with certain data and preferences such as 
( their year of experience , their employment type, company location and company size )  and want to make an transaction into different domain in data industry
(like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.)
your work is to  guide them to which domain they should switch to base on  the input they provided, so that they can now update thier knowledge as  per the suggestion/.. 
The Suggestion should be based on average salary.*/
CREATE PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT 
        job_title, 
        experience_level, 
        company_location, 
        company_size, 
        employment_type, 
        ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE 
        experience_level = exp_lev 
        AND company_location = comp_loc 
        AND company_size = comp_size 
        AND employment_type = emp_type 
        GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;

