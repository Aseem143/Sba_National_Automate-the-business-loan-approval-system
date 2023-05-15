Sba_National Dataset

-remove unwanted after decimal numbers to convert into integer
SELECT * FROM public.sbadata
update sbadata
set balancegross = replace (balancegross,'.000','')

select cast (disbursementgross as int ) as Disbursement_gross
from sbadata

Alter table sbadata
add column Disbursement_gross int;

update sbadata
set Disbursement_gross=cast (disbursementgross as int )

select Disbursement_gross from sbadata limit 10

select avg(disbursement_gross) from sbadata

-- 2nd column to delete $ , , space from the column and creating a new column to add the existing 
--converted int column dat into that column
update sbadata
set balancegross = Replace(replace (balancegross,'.000',''),',','')

select cast (balancegross as int ) as balance_gross
from sbadata

Alter table sbadata
add column balance_gross int;

update sbadata
set balance_gross=cast (balancegross as int )

select avg(balance_gross) from sbadata

select (balance_gross) from sbadata

--3rd column (ChgOffPrinGr)
update sbadata
set ChgOffPrinGr = Replace(replace (ChgOffPrinGr,'.00',''),',','')

select cast (ChgOffPrinGr as int ) as ChgOff_PrinGr
from sbadata

Alter table sbadata
add column ChgOff_PrinGr int;

update sbadata
set ChgOff_PrinGr =cast (ChgOffPrinGr as int )

select avg(ChgOff_PrinGr) from sbadata

--4th columns (GrAppv)

		
update sbadata
set GrAppv = Replace(replace (GrAppv,'.00',''),',','')

select cast (GrAppv as int ) as ChgOff_PrinGr
from sbadata

Alter table sbadata
add column Gr_Appv int;

update sbadata
set Gr_Appv =cast (GrAppv as int )

select avg(Gr_Appv) from sbadata



--5th columns (SBA_Appv)
update sbadata
set SBA_Appv = Replace(replace (SBA_Appv,'.00',''),',','')

select cast (SBA_Appv as int ) as SBA_Appv1
from sbadata

Alter table sbadata
add column SBA_Appv1 int;

update sbadata
set SBA_Appv1 =cast (SBA_Appv as int )

select avg(SBA_Appv1) from sbadata

-------------------------

select * from sbadata limit 5

--Delete the old columns

ALTER TABLE sbadata DROP COLUMN SBA_Appv 
, DROP COLUMN GrAppv ,  DROP COLUMN ChgOffPrinGr ,  DROP COLUMN balancegross , DROP COLUMN disbursementgross


----------------
update sbadata
set loannr_chkdgt = Replace(replace (loannr_chkdgt,'.00',''),',','')

select cast (loannr_chkdgt as bigint ) as loannr_chkdgt1
from sbadata

Alter table sbadata
add column loannr_chkdgt1 bigint;

update sbadata
set loannr_chkdgt1 =cast (loannr_chkdgt as bigint )

ALTER TABLE sbadata DROP COLUMN loannr_chkdgt

--Checking the duplicates values in loan Account No 

SELECT  loannr_chkdgt1, COUNT(*)
FROM sbadata
GROUP BY loannr_chkdgt1
HAVING COUNT(*) > 1


-- Checking the null values & deleting the unwanted columns 
Delete from sbadata
where name is null

Delete from sbadata
where city is null

Delete from sbadata
where Bank is null

Delete from sbadata
where state is null

Delete from sbadata
where bankstate is null

select * from sbadata

select distinct approvalfy from sbadata 

select cast (approvalfy as int ) as approvalfy1
from sbadata

Alter table sbadata
add column approvalfy1 int;

update sbadata
set approvalfy1 =cast (approvalfy as int )

ALTER TABLE sbadata DROP COLUMN approvalfy

select * from sbadata limit 10

--Dropping Unwanted Columns

ALTER TABLE sbadata DROP COLUMN state
ALTER TABLE sbadata DROP COLUMN franchisecode
ALTER TABLE sbadata DROP COLUMN chgoffdate
ALTER TABLE sbadata DROP COLUMN newexist


--Analysing Columns to Select the best Metrics for Loan Automation
SELECT
    AVG(Term) AS avg_loan_term,
    AVG(NoEmp) AS avg_number_of_employees,
    AVG(CreateJob) AS avg_jobs_created,
    AVG(RetainedJob) AS avg_jobs_retained,
    SUM(CASE WHEN RevLineCr = 'Y' THEN 1 ELSE 0 END) AS num_revolving_credit,
    SUM(CASE WHEN LowDoc = 'Y' THEN 1 ELSE 0 END) AS num_low_doc_loans,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 ELSE 0 END) AS num_approved_loans,
    SUM(CASE WHEN MIS_Status = 'PIF' THEN 1 ELSE 0 END) AS num_disapproved_loans
FROM sbadata;


--This query calculates the following metrics:

avg_loan_term: Average length of the loan in months
avg_number_of_employees: Average number of employees in the business
avg_jobs_created: Average number of jobs created by the loan
avg_jobs_retained: Average number of jobs retained by the loan
num_revolving_credit: Number of loans with a revolving line of credit
num_low_doc_loans: Number of loans through the LowDoc Loan Program
total_loans: Total number of loans in the dataset
num_approved_loans: Number of loans that were approved
num_disapproved_loans: Number of loans that were disapproved or charged off
-----------------------------------------------------------------------------------------
--Debt-to-Income Ratio (DTI):
--DTI is the ratio of a borrower's monthly debt payments to their monthly income.
--A lower DTI indicates that the borrower has more disposable income available to repay the loan.

--coalesce is used to consider null values as zero
SELECT COALESCE((SUM(ChgOff_PrinGr) + SUM(Balance_Gross)) / NULLIF(SUM(Disbursement_Gross), 0), 0) AS DTI
FROM public.sbadata;

SELECT 
    SUM(ChgOff_PrinGr) AS total_ChargedOff_principal,
    SUM(Balance_Gross) AS total_Balance_Gross,
    SUM(Disbursement_Gross) AS total_Disbursement_Gross,
    Round((SUM(ChgOff_PrinGr) + SUM(Balance_Gross)) / SUM(Disbursement_Gross),6) AS DTI
FROM public.sbadata;

-----------------------------------------------------------------------------------------
-- 1). Using Window functions, explore the top 5  customers based on certain metrics
(Eg - Find the top 5 customers with highest bank balance who have not defaulted on a loan in the last 3 years).
This will help you understand your ideal loan applicants.

SELECT *
FROM (
    SELECT name,city,balance_gross,Mis_status,chgoff_pringr,approvalfy1,
        ROW_NUMBER() OVER (ORDER BY Balance_Gross DESC) AS rank
    FROM SBAdata
    WHERE DisbursementDate >= CURRENT_DATE - INTERVAL '3 years'
) AS subquery
WHERE rank <= 10 and chgoff_pringr =0;

-- Princess Manufacturing co,Kings Inn,Curtis Johnson are the ideal loan applicants

-----------------------------------------------------------------------------------------
# We can use more different metrics as per business need to get insights from the data such as 
We can check the name and defaulted or paid loan amounts more than 5000000

select Name,gr_appv,mis_status from sbadata where Gr_Appv >= 5000000 order by Gr_Appv desc;

-- we can say that if Gross amount of loan approved by bank is greater than 5000000 then there are 100% chances of loan getting paid in Full

-----------------------------------------------------------------------------------------
-- 2)checking the number of paid and defaults as per urban and rural status 

SELECT UrbanRural,
       100.0 * COUNT(CASE WHEN MIS_Status = 'P I F' THEN 0 END) / COUNT(*) AS percentage_paid,
       100.0 * COUNT(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 END) / COUNT(*) AS percentage_defaulted
FROM SBAdata
GROUP BY UrbanRural; 

-- The deafaulters in urban are more compared to rural

---------------------------------------------------------------------------------------

-- 3).Count of loan (paid and defaulted )application by credit score :
This metric is very important as this will give bank an idea of what the ratio of loan defaulted and paid by new and existing business

SELECT COUNT(*) AS record_count,
       lowdoc,
       CASE
           WHEN lowdoc = 'Y' THEN 'Good Credit score'
           WHEN lowdoc = 'N' THEN 'Bad credit score'
           ELSE 'not_defined'
       END AS BUSINESS_STATUS
FROM sbadata
WHERE lowdoc = 'Y' OR lowdoc = 'N'
GROUP BY lowdoc;

SELECT lowdoc,
       100.0 * COUNT(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 END) / COUNT(*) AS percentage_charged_off
FROM sbadata
WHERE lowdoc = 'Y' OR lowdoc = 'N'
GROUP BY lowdoc;

--90% of the customers credit score is not good and the percentage of chgoff is 18% when compared to customers with good credit score is 8.9% 
-----------------------------------------------------------------------------------------
--4).Next, try checking your credit standing using different metrics. You can differentiate between key figures and use different key figures according to your bank's needs.
WITH cte AS (
    SELECT LoanNr_ChkDgt1, MIS_Status, Gr_Appv, term, NoEmp, Disbursement_Gross, ChgOff_PrinGr,
           CASE
               WHEN Gr_Appv >= 50000 AND Gr_Appv <= 250000 AND term <= 84 AND NoEmp <= 50 
                   AND Disbursement_Gross <= 250000 AND ChgOff_PrinGr <= 10000 THEN 'Approved'
               ELSE 'Declined'
           END AS Loan_Status
    FROM sbadata
)
SELECT Loan_Status, COUNT(*) AS Loan_Count
FROM cte
GROUP BY Loan_Status;

-----------------------------------------------------------------------------------------
--5).Calculate the average loan amount approved for each fiscal year, comparing it to the overall average loan amount approved across all years:

SELECT ApprovalFY1, AVG(Gr_Appv) AS avg_loan_amount,
       AVG(Gr_Appv)  AS overall_avg_loan_amount
FROM SBAdata
WHERE ApprovalFY1 IS NOT NULL
GROUP BY ApprovalFY1
ORDER BY ApprovalFY1 desc;

--The gross approval amount was highest in 2011 from (1962-2014)

-----------------------------------------------------------------------------------------
--6).Top Defaulters highlights
WITH cte AS (
    SELECT name, MIS_Status, Gr_Appv, term, NoEmp, Disbursement_Gross, ChgOff_PrinGr,approvalfy1,
           ROW_NUMBER() OVER (PARTITION BY MIS_Status ORDER BY Gr_Appv DESC) AS rn
    FROM sbadata
)
SELECT name, MIS_Status, Gr_Appv, term, NoEmp, Disbursement_Gross, ChgOff_PrinGr,approvalfy1
FROM cte
WHERE rn <= 10
order by gr_appv desc;


Top Defaulters highlights are 
1. "CHOICE VENDING INC"	            has taken loan of 24 Lakhs with 22lakhs 23 thousand chgoff amount, loan approved was in 1999
2. "UNITED YARNS, CO. INC."         has taken loan of 24 Lakhs with 21lakhs 57 thousand chgoff amount, loan approved was in 1999
3. "DOLPHIN LANES OF SOUTH FLORIDA"	has taken loan of 22 Lakhs with 17lakhs 98 thousand chgoff amount, loan approved was in 2000	
4. "DWG & ASSOCIATES, INC."         has taken loan of 35 lakhs and with 15lakhs 86 thousand chgoff amount
5. "FLORIDA COMPUTERIZED MACHINING" has taken loan of 29 Lakhs with 15lakhs 49 thousand chgoff amount
6. "DAYS INN-CINCINNATI"            has taken loan of 24 Lakhs with 12lakhs 99 thousand chgoff amount
-----------------------------------------------------------------------------------------

7). Best Optimal Loan term to provide for clients

SELECT term, COUNT(*) AS total_loans,
       COUNT(CASE WHEN MIS_Status = 'P I F' THEN 1 END) AS paid_in_full,
       COUNT(CASE WHEN MIS_Status = 'CHGOFF' THEN 1 END) AS charged_off,
       COUNT(CASE WHEN MIS_Status = 'PIF' OR MIS_Status = 'CHGOFF' THEN 1 END) * 100.0 / COUNT(*) AS approval_rate
FROM sbadata
GROUP BY term
order by approval_rate desc;

--The Loan with term 40-60 have the most charged off Accounts

-----------------------------------------------------------------------------------------

8). Percentile Calculation for charged of & Pif
SELECT MIS_Status, 
       PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Gr_Appv) AS q1,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Gr_Appv) AS median,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Gr_Appv) AS q3
FROM sbadata
GROUP BY MIS_Status;


-----------------------------------------------------------------------------------------
9).Top industries by loan amount:

SELECT NAICS, SUM(Gr_Appv) AS total_loan_amount
FROM sbadata
GROUP BY NAICS
ORDER BY total_loan_amount DESC
LIMIT 7;

These are the top three Industries with highest loan Amounts
Accommodation and food services
Health care and social assistance
Retail trade

-----------------------------------------------------------------------------------------

10). calculate the level of charge-off (CHGOFF) for each loan

WITH recursive cte AS (
    SELECT LoanNr_ChkDgt1, MIS_Status, Gr_Appv, ChgOff_PrinGr, 1 AS level
    FROM sbadata
    WHERE MIS_Status = 'CHGOFF'
    UNION ALL
    SELECT c.LoanNr_ChkDgt1, c.MIS_Status, c.Gr_Appv, c.ChgOff_PrinGr, cte.level + 1
    FROM sbadata c
    JOIN cte ON c.LoanNr_ChkDgt1 = cte.LoanNr_ChkDgt1
    WHERE c.MIS_Status = 'CHGOFF'
)
SELECT LoanNr_ChkDgt1, MIS_Status, Gr_Appv, ChgOff_PrinGr, level
FROM cte;






