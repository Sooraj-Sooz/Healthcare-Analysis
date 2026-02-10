--SQL: TREATMENT AND SATISFACTION ANALYSIS

--1. Calculate the average treatment cost per department.
SELECT Specialty AS DEPARTMENT, ROUND(AVG(CAST(Treatment_Cost AS Float)),2) AS AVERAGE_TREATMENT_COST
FROM
DoctorDetails_Cleaned AS D INNER JOIN TreatmentRecords_Cleaned AS T
ON
D.Doctor_ID = T.Doctor_ID
GROUP BY D.Specialty
ORDER BY AVERAGE_TREATMENT_COST DESC

--2.Find total number of patients treated by each doctor.
SELECT D.Doctor_ID, D.Name AS Doctor, count(T.Patient_ID) AS Patient_Count
FROM
DoctorDetails_Cleaned As D INNER JOIN TreatmentRecords_Cleaned AS T
ON
D.Doctor_ID = T.Doctor_ID
GROUP BY D.Doctor_ID, D.Name
ORDER BY Patient_Count DESC

--3.Get conversion rate of successful treatments by department.
SELECT D.Specialty AS Department, Count(*) AS Total_Cases,
sum(Case when T.Outcome = 'Recovered' then 1 else 0 End) as Successful_count,
Round(1.0 * sum(Case when T.Outcome = 'Recovered' then 1 else 0 End)/Count(*),4) AS Conversion_Rate
from
DoctorDetails_Cleaned as D INNER JOIN TreatmentRecords_Cleaned AS T
on
D.Doctor_ID = T.Doctor_ID
GROUP BY D.Specialty
ORDER BY Conversion_Rate DESC

--4.Retrieve readmission count per condition.
With Visits As(
Select P.Disease, T.Patient_ID, T.Treatment_Date, 
LAG(T.Treatment_Date) over (Partition by P.Disease, T.Patient_ID Order by T.Treatment_Date) As Prev_Visit
from 
TreatmentRecords_Cleaned As T INNER JOIN PatientInfo_Cleaned As P
on
T.Patient_ID = P.Patient_ID
)

Select Disease, Count(*) As Readmission_Count
from Visits
where 
Prev_Visit IS NOT NULL AND DATEDIFF(Day, Prev_Visit, Treatment_Date)<=30
Group by Disease
Order by Readmission_Count Desc

--5.List doctors with average satisfaction score above 4.5.
Select D.Name, Round(AVG(CAST(T.Satisfaction_Score As Float)),4) As Avg_Satisfaction_Score
from 
DoctorDetails_Cleaned AS D INNER JOIN TreatmentRecords_Cleaned As T
on
D.Doctor_ID = T.Doctor_ID
Group by D.Name
Having AVG(T.Satisfaction_Score) > 4.5
Order by Avg_Satisfaction_Score

--6 Find patients who were admitted more than once in 30 days.
Select T1.Patient_ID, count(*) As Visit_in_30days
from
TreatmentRecords_Cleaned T1 INNER JOIN TreatmentRecords_Cleaned T2
on 
T1.Patient_ID = T2.Patient_ID AND 
T2.Treatment_Date BETWEEN DATEADD(Day, -30, T1.Treatment_Date) AND T1.Treatment_Date
Where T1.Record_ID <> T2.Record_ID
GROUP BY T1.Patient_ID
HAVING COUNT(*) > 1
ORDER BY Visit_in_30days DESC;

--checking details of patient with Highest Readmission
select * from PatientInfo_Cleaned
where Patient_ID = 'P2672'

--7.Compare treatment cost between two departments.
--Between(Pulmonoligist & Cardiologist)

Select D.Specialty, Round(AVG(Cast(T.Treatment_Cost As Float)),3) As Avg_Treatment_Cost
from
DoctorDetails_Cleaned As D INNER JOIN TreatmentRecords_Cleaned As T
on
D.Doctor_ID = T.Doctor_ID
where Specialty in ('Pulmonologist', 'Cardiologist')
Group By D.Specialty
Order By Avg_Treatment_Cost Desc

--(Between Neurologist & Endocrinologist)
Select D.Specialty, Round(AVG(Cast(T.Treatment_Cost As Float)),3) As Avg_Treatment_Cost
from
DoctorDetails_Cleaned As D INNER JOIN TreatmentRecords_Cleaned As T
on
D.Doctor_ID = T.Doctor_ID
where Specialty in ('Neurologist', 'Endocrinologist')
Group By D.Specialty
Order By Avg_Treatment_Cost Desc

--8.Retrieve top 5 conditions with highest average treatment duration.
Select Top 5 P.Disease, AVG(Cast(T.Treatment_Duration_Days As Float)) AS Avg_TreatmentDuration_Days
from 
PatientInfo_Cleaned As P INNER JOIN TreatmentRecords_Cleaned As T
on
P.Patient_ID = T.Patient_ID
Group By P.Disease
Order BY Avg_TreatmentDuration_Days Desc

--9 Find most common admission reason by age group.
With AgeGroup As(
Select Patient_ID,
Case 
When Age < 18 Then 'Child'
When Age BETWEEN 18 AND 59 Then 'Adult'
Else 'Senior'
End As Age_Group
From PatientInfo_Cleaned 
)

Select P.Disease, A.Age_Group,Count(T.Record_ID) As Admissions
from
AgeGroup As A INNER JOIN TreatmentRecords_Cleaned As T 
on
A.Patient_ID = T.Patient_ID
INNER JOIN PatientInfo_Cleaned As P
on
P.Patient_ID = T.Patient_ID
Group By P.Disease, A.Age_Group
Order by Admissions Desc

--OR (USe Multiple CTE to find the most common reasons for Age groups)

With AgeGroup As(
Select Patient_ID,
Case 
When Age < 18 Then 'Child'
When Age BETWEEN 18 AND 59 Then 'Adult'
Else 'Senior'
End As Age_Group
From PatientInfo_Cleaned 
),
Admission As(
Select P.Disease, A.Age_Group,Count(T.Record_ID) As Admissions_Count
from
AgeGroup As A INNER JOIN TreatmentRecords_Cleaned As T 
on
A.Patient_ID = T.Patient_ID
INNER JOIN PatientInfo_Cleaned As P
on
P.Patient_ID = T.Patient_ID
Group By P.Disease, A.Age_Group
)

Select Age_Group, Disease, Admissions_Count
from (
Select *,
ROW_NUMBER() OVER (Partition By Age_Group Order by Admissions_Count Desc) As RN
from Admission) TopAdm
where RN = 1
Order By Age_Group

--10 Get doctors with more than 20 cases and recovery rate >80%.

Select D.Name, Count(*) As Total_Cases,
SUM(Case When T.Outcome = 'Recovered' Then 1 else 0 End) As Success_Count,
1.0 * SUM(Case When T.Outcome = 'Recovered' Then 1 else 0 End) / Count(*) As Success_Rate
From 
DoctorDetails_Cleaned As D INNER JOIN TreatmentRecords_Cleaned As T
on
D.Doctor_ID = T.Doctor_ID
Group By D.Name
Having Count(*) > 20 AND 1.0 * SUM(Case When T.Outcome = 'Recovered' Then 1 else 0 End) / Count(*) > 0.80
Order By Success_Rate Desc



---OVERALL READMISSION RATE (For analysis purpose)
WITH Visits AS (
    SELECT 
        T.Patient_ID,
        T.Treatment_Date,
        LAG(T.Treatment_Date) OVER (
            PARTITION BY T.Patient_ID
            ORDER BY T.Treatment_Date
        ) AS Prev_Visit
    FROM TreatmentRecords_Cleaned T
),
Readmission AS (
    SELECT 
        *,
        CASE 
            WHEN Prev_Visit IS NOT NULL
                 AND DATEDIFF(DAY, Prev_Visit, Treatment_Date) <= 30
            THEN 1
            ELSE 0
        END AS Is_Readmission
    FROM Visits
)
SELECT 
    SUM(Is_Readmission) * 1.0 / COUNT(*) AS Overall_Readmission_Rate,
    SUM(Is_Readmission) AS Total_Readmissions,
    COUNT(*) AS Total_Visits
FROM Readmission;





