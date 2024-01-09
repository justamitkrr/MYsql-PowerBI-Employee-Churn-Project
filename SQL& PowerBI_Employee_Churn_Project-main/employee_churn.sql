USE employee_churn;

SELECT COUNT(1)
FROM employee_churn;

-- Analysis : Satisfaction Score vs Employee Turn Over

/*
First of all we have two variables, company_left which is a nominal variable and 
	satisfaction which is a range of values. We will check the population of 
    employees who left the company of who did not.
        (Yes = employee left the company
         No = employee is still in the company)
*/
SELECT company_left,
		COUNT(IF(company_left = 'yes',1,0)) AS churn
FROM employee_churn
GROUP BY company_left;

/*
Now, we will find the average rate of satisfaction level of employee so that 
	we can see how much correlated satisfaction rate or employees who left the company are?
*/
SELECT company_left,
		ROUND(
			AVG(satisfaction)*100,2
            ) AS Avg_satisfaction
FROM employee_churn
GROUP BY company_left;
/*
Satisfaction rate is the same of both employee's group
*/

/*
Let's finish computing the standard deviation, we can do so.
*/
SELECT ROUND(
		STDDEV(satisfaction)*100,2
			) AS std_satisfaction
FROM employee_churn;
/*
Standard Deviation carry quite wide range of value, It seems satisfaction
is not stable in between employees
*/

/*
P='no' is the proportion for thr group (did not left)
Q ='Yes is the proportion for the group (left the company)
*/
SELECT company_left,
		ROUND(
			COUNT(IF(company_left = 'yes',1,0))
			/ (SELECT COUNT(1) 
				FROM employee_churn)*100,2
			) AS churn_percent
FROM employee_churn
GROUP BY company_left;
/*
P = 70.82% and Q = 29.18%
Around 30% employees left the company and satisfaction is not impacted 
to retention the employees
*/

-- Finding #1
-- It seems there is no correlation between satisfaction score and employee turnover

SELECT *
FROM employee_churn;

-- Analysis : Employee Turnover Rate By Department

-- Turnover Rate = no of left employees / total no of employees of that department

WITH cte1 AS (
	SELECT department,
			COUNT(company_left) AS left_employee
	FROM employee_churn
	WHERE company_left = 'Yes'
	GROUP BY department
			),
-- cte1: This CTE calculates the count of employees who left the company ('Yes') in each department.
cte2 AS (
	SELECT department,
			COUNT(1) AS total_employees
    FROM employee_churn
    GROUP BY department
		)
-- cte2: This CTE calculates the total count of employees in each department.
SELECT cte1.department,
		left_employee,
		total_employees,
		ROUND(
			left_employee / total_employees
				*100,2) AS TurnOver_Rate
FROM cte1
JOIN cte2
ON cte1.department = cte2.department
GROUP BY department
ORDER BY Turnover_Rate DESC;
/*
Main Query :
	The main query takes cte1 and cte2 then inner join on the department column
    , then to calculate the employee turnover rate column left_employee divided
    by total_employees and multiple 100 to change into a percentage values and rounded up
    the value upto 2 decimal to enhance the readibility 
    Then finally ordering the department in hight turnover rate.
*/

-- Finding #2
/*
We can See all the departments has TurnOver Rate
around 28% - 30%, 
However, There are four departments tend to have high turnover rate than others.
Departments : IT, Logistics, Retail, Marketing.
*/

-- Analysis 3 : Are Promoted employees more likely to stay in the company ?

WITH cte1 AS (
		SELECT Department,
				COUNT(CASE WHEN company_left = 'Yes' THEN 1 END) AS emp_left,
				COUNT(CASE WHEN company_left = 'No' THEN 1 END) AS emp_stay
		FROM employee_churn
		WHERE promoted = 1
		-- Promoted = 1 (Yes)
		GROUP BY Department
			),
-- cte1 : This CTE calculate the number of promoted employees who has either left the company or stay in the company 
cte2 AS (
		SELECT department,
				COUNT(1) AS total_promoted_employee
		FROM employee_churn
		WHERE promoted = 1
		GROUP BY department
		)
-- cte2 : This CTE calculate the overall promoted employees of each department
SELECT cte1.*,
		ROUND(
			emp_left/total_promoted_employee
             *100, 2) AS emp_left_ratio,
		ROUND(
			emp_stay/total_promoted_employee
             *100, 2) AS emp_stay_ratio,
		AVG(emp_left/total_promoted_employee*100) OVER() AS avg_emp_left
FROM cte1
JOIN cte2 
ON cte1.department = cte2.department
GROUP BY cte1.department;
-- Finding #3 
/*
This is a clear illustration that, most of them who were promoted,
	stayed in the company. Seems like promotion could be a factor 
		to retent the employees.
			Retail Department has above churn ratio (23.08%) among all
				department churn rates.
*/

-- Analysis 4 : Project Involvement vs Turnover Rate

/*
Hypothesis : Are employees that are more involved in the project 
			are more likely to stay in the company or leave from 
            the company ? 
My Hypothesis : If the employees are more involved in the projects
				, then they have more responsibilities, leads to 
                make more sense to stay with the company.
*/

WITH cte1 AS (
		SELECT department, 
				SUM(projects) AS total_projects,
				COUNT(company_left) AS total_employees
		FROM employee_churn
		GROUP BY department
			),
-- Cte1 - > The table broke down each department with total no of projects and total employees in that department.
cte2 AS (
		SELECT department,
				COUNT(1) AS left_employee
        FROM employee_churn
        WHERE company_left = 'Yes'
        GROUP BY department
        )
-- Cte2 - > The table divided the departments with the no of employees who left the company.
SELECT cte1.*, cte2.left_employee,
		ROUND(
			left_employee / total_employees
			*100,2) AS Turnover_Rate
FROM cte1
JOIN cte2
ON cte1.department = cte2.department
GROUP BY department
ORDER BY Turnover_Rate DESC;
/*
Main Query :
	Taking with both Cte tables (cte1 and cte2) applied the inner join on the 
    department column. To calculate the Employee Turnover Rate, Divided left_employee
    with total_employees and multiply with 100 to bring the percentage values 
    and rounded upto 2 decimals to show better way
    , Finally Ordered Departments with high turnover rate.
*/

-- Finding #4
/*
The result is telling the different story : 
			Projects involvement is not quite big factor
            to be stayed employees with the company.
*/

-- Analysis 5 : Employees Performance Review vs Turnover Rate
-- M1 & M2 (M1 = Left the company), (M2 = Stay in the company)
SELECT company_left,
	  ROUND(
			AVG(review)
			,2) AS avg_review
FROM employee_churn
GROUP BY company_left;

-- Standard Deviation of Review
SELECT ROUND(
		STDDEV(review) 
			,3) AS std_review
FROM employee_churn;

SELECT company_left,
	ROUND(
		COUNT(1)/
        (SELECT COUNT(1) 
         FROM employee_churn)
         *100,2) AS 'stay/left'
FROM employee_churn
GROUP BY company_left;
-- Q = 29% (Who left the job), P = 70% (Who stay in the company)

-- The Point - Biserial Correlation factor will then be (M1-M2)/std_review * sqrt(pq)
-- M1 = 0.69
-- M2 = 0.64
-- std_review = 0.085
-- P = 70.82
-- Q = 29.18

SET @m1 = 0.69;
SET @m2 = 0.64;
SET @std_review = 0.085;
SET @P = 70.82;
SET @Q = 29.18;

SELECT
	ROUND(
		( @m1 - @m2 ) / @std_review
		*
		SQRT( @P * @Q ) 
		,2 ) AS Correlation;

-- Finding #5
/*
The Relationship is 26, Which shows too week between Performance of employees
and Employee Turnover Rate. That correlation suggest is low performance is not
a decisive factor for employee's turnover.
*/

-- Analysis 6 : Salary vs Employee Turnover Rate
WITH cte1 AS (
SELECT company_left,
		salary,
		COUNT(1) AS total,
        CASE 
			WHEN salary = 'low' THEN 1
            WHEN salary = 'medium' THEN 2
            ELSE 3 END AS rn 
FROM employee_churn
WHERE company_left = 'Yes'
GROUP BY company_left, salary
ORDER BY rn),
/* cte1: This CTE calculates the count of 
employees who left the company ('Yes') for each salary category 
('low', 'medium', 'high'). The rn column assigns a numeric value to each 
salary category for sorting purposes.*/
cte2 AS (
SELECT company_left,
		salary,
		COUNT(1) AS total,
        CASE 
			WHEN salary = 'low' THEN 1
            WHEN salary = 'medium' THEN 2
            ELSE 3 END AS rn
FROM employee_churn
WHERE company_left = 'No'
GROUP BY company_left, salary
ORDER BY rn)
/*
cte2: This CTE calculates the count of employees who stayed 
in the company ('No') for each salary category ('low', 'medium', 'high'). 
Similar to cte1, the rn column assigns a numeric value to each salary category.
*/
SELECT cte1.company_left,
		cte1.salary, 
		ROUND((cte1.total/cte2.total)*100,2) AS salary_impact,
        ROUND(AVG((cte1.total/cte2.total)*100) OVER(),2) AS Overall_avg_impact
FROM cte1
JOIN cte2
ON cte1.rn = cte2.rn;
/*
Main Query:
The main query takes data from cte1 and cte2 and calculates the following metrics 
for each salary category:

salary_impact: This metric calculates the percentage of employees who left the company 
('Yes') for each salary category compared to the total number of employees who stayed 
('No') in the same salary category. This gives insight into how salary levels impact employee turnover.

Overall_avg_impact: This metric calculates the average salary impact across all salary 
categories. It uses the window function AVG() to provide the average impact percentage.
*/
-- Finding #6
/*
The number of low salaries employees who left the job
		is approx 1/3 of those who are stay in the company with the 
			lowest salary, It seems salary is not quite impacted 
				creating a chance to decrease the turnover rate.
                */

-- Analysis 7 : Average Hours Work vs Employee Turnover Rate
SELECT company_left,
	ROUND(
		AVG(avg_hrs_month)
        ,2) AS avg_monthly_working_hrs
FROM employee_churn
GROUP BY company_left;

-- Analysis 8 : Tenure Impact on Employee Turnover Rate

/*
Tenure : Tenure refers to the length of time an individual has been employed by a company 
or in a specific position. It measures how long someone has been part of an organization 
or held a particular job role.
*/

WITH cte1 AS (
SELECT tenure, 
	COUNT(1) AS left_employees 
FROM employee_churn 
WHERE company_left = 'yes' 
GROUP BY tenure),
/*
cte1: This CTE calculates the count of employees who left the company ('yes') 
for each unique tenure value. It groups the data by tenure and counts the number 
of employees who left the company with that particular tenure.
*/
cte2 AS (
SELECT tenure, 
	COUNT(1) AS total_employees 
FROM employee_churn
GROUP BY tenure)
/*
cte2: This CTE calculates the total count of employees for each unique tenure value. 
It groups the data by tenure and counts the total number of employees with that 
particular tenure.
*/
SELECT cte1.tenure, 
		ROUND(cte1.left_employees/cte2.total_employees*100,2) AS churn_percent
FROM cte1
JOIN cte2
ON cte1.tenure = cte2.tenure;
/*
Main Query:
The main query takes data from cte1 and cte2 and calculates the churn percentage for 
each unique tenure value:

churn_percent: This metric calculates the percentage of employees who left the company 
within each specific tenure group, out of the total number of employees in the same tenure 
group. This gives insight into how employee turnover varies based on the length of time 
employees have spent at the company.
*/

-- Finding #8 :
/*
1. Employees with shorter tenures (2-3 years) have significantly higher churn percentages, 
	indicating a higher likelihood of leaving the company.
2. Churn percentages gradually decrease as tenure increases from 4 to 9 years, suggesting 
	that employees tend to become more stable and committed to the organization over time.
3. A noticeable exception is employees with a tenure of 5 years, which has a relatively high 
	churn percentage. This could indicate a specific factor or trend affecting this group.
*/

/*
Insights / Conclusion :
    1. Promotion Factor - > 
    There are 4 Departments IT, Retail, Logistics, Marketing
	promoted few amount of employees, Because highest 
	Churn Rate is coming from these department (30%) Churn Rate.
	The Reason could be behind that Retail has also 23.08% churn rate
	after being the employees promoted, which is above of among
	all departments churn average rate 18.74%.
	We believe to employees be promoted in these departments can bring lower employee churn rate.
    2. Salary Impact on Turnover - >
	Employees across all salary levels exhibit turnover, indicating that salary alone does not guarantee retention.
	Middle salary range ('medium') shows higher turnover than low or high salary levels, suggesting a need to address factors beyond compensation for this group.
	3. Tenure and Churn - >
	Shorter tenures (2-3 years) have notably higher churn percentages 53% - 66%, emphasizing the importance of improving early employee experiences.
	As tenure increases, churn percentages decrease, indicating that long-term employees tend to stay committed to the company.
*/
/*
1. Holistic Retention Strategies:
Implement retention strategies that consider more than just salary, focusing on job satisfaction, career growth, 
and work-life balance for employees at all pay levels.
2. Early Employee Engagement:
Enhance onboarding and engagement efforts for employees with short tenures to improve their experience and reduce early turnover.
3. Mid-Salary Analysis:
Investigate factors contributing to higher turnover among employees with medium salaries. Address potential issues like job satisfaction, 
growth opportunities, or work environment.
4. Long-Term Employee Recognition:
Recognize and reward long-term employees (4-9 years) to reinforce their loyalty and encourage continued commitment.
*/