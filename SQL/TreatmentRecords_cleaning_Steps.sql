--CREATING DATABASE
CREATE DATABASE CareNova

SELECT * FROM TreatmentRecords

--CHECKING COLUMN NAMES
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TreatmentRecords';

--1. INSPECTING THE TABLE (TreatmentRecords)
SELECT TOP 10 *
FROM TreatmentRecords

--RENAME COLUMNS
EXEC sp_rename 'dbo.TreatmentRecords.RecordID', 'Record_ID', 'COLUMN'
EXEC sp_rename 'dbo.TreatmentRecords.PatientID', 'Patient_ID', 'COLUMN'
EXEC sp_rename 'dbo.TreatmentRecords.DoctorID', 'Doctor_ID', 'COLUMN' 
EXEC sp_rename 'dbo.TreatmentRecords.TreatmentDate', 'Treatment_Date','COLUMN' 
EXEC sp_rename 'dbo.TreatmentRecords.TreatmentDurationDays', 'Treatment_Duration_Days', 'COLUMN'
EXEC sp_rename 'dbo.TreatmentRecords.TreatmentCost', 'Treatment_Cost', 'COLUMN'
EXEC sp_rename 'dbo.TreatmentRecords.SatisfactionScore', 'Satisfaction_Score', 'COLUMN' 

--CHECKING DATATYPES OF COLUMNS
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = 'TreatmentRecords'

--CHANGE DATA TYPES OF COLUMNS (Patient_ID, Doctor_ID to nvarchar & Treatment_Duration_Days to nvarchar)

ALTER TABLE TreatmentRecords
ALTER COLUMN Treatment_Cost decimal(10,2)

ALTER TABLE TreatmentRecords
ALTER COLUMN Satisfaction_Score decimal(10,2)

--FIND DUPLICATES rows
WITH DUPLICATE_COUNT AS 
(
SELECT *, COUNT(*) OVER 
(PARTITION BY Record_ID, Patient_ID, Doctor_ID, Treatment_Date, Treatment_Duration_Days, Treatment_Cost, Satisfaction_Score ) AS CNT
FROM TreatmentRecords
)
SELECT * FROM DUPLICATE_COUNT
WHERE CNT > 1;

--REMOVING DUPLICATES 
--(Since there is no duplicate data - no need for removal, but running the duplicate removal query for safety)
WITH RANKED AS
(SELECT *,
ROW_NUMBER() OVER 
(PARTITION BY Record_ID, Patient_ID, Doctor_ID, Outcome, Treatment_Date, Treatment_Duration_Days, 
Treatment_Cost, Satisfaction_Score ORDER BY (SELECT NULL)) AS RN
FROM TreatmentRecords)

DELETE FROM RANKED
WHERE RN>1

--FINDING NULLS (No Null Values in this record)
SELECT
SUM(CASE WHEN Record_ID IS NULL THEN 1 ELSE 0 END) AS Record_ID_NULLs,
SUM(CASE WHEN Patient_ID IS NULL THEN 1 ELSE 0 END) AS Patient_ID_NULLs,
SUM(CASE WHEN Doctor_ID IS NULL THEN 1 ELSE 0 END) AS Doctor_ID_NULLs,
SUM(CASE WHEN Outcome IS NULL THEN 1 ELSE 0 END) AS Outcome_NULLs,
SUM(CASE WHEN Treatment_Date IS NULL THEN 1 ELSE 0 END) AS Treatment_Date_NULLs,
SUM(CASE WHEN Treatment_Duration_Days IS NULL THEN 1 ELSE 0 END) AS Treatment_Duration_Days_NULLs,
SUM(CASE WHEN Treatment_Cost IS NULL THEN 1 ELSE 0 END) AS Treatment_Cost_NULLs,
SUM(CASE WHEN Satisfaction_Score IS NULL THEN 1 ELSE 0 END) AS Satisfaction_Score_NULLs
FROM TreatmentRecords

-- REPLACE NULLS
--(Since there is no nulls in our record we are skipping fillnulls)
--STANDARDIZE FORMATS
--TRIM SPACES
UPDATE TreatmentRecords
SET
Record_ID = LTRIM(RTRIM(Record_ID)),
Patient_ID = LTRIM(RTRIM(Patient_ID)),
Doctor_ID = LTRIM(RTRIM(Doctor_ID)),
Outcome = LTRIM(RTRIM(Outcome)),
Treatment_Date = LTRIM(RTRIM(Treatment_Date)),
Treatment_Duration_Days = LTRIM(RTRIM(Treatment_Duration_Days)),
Satisfaction_Score = LTRIM(RTRIM(Satisfaction_Score))

--COPYING IT TO A CLEAN _TABLE
SELECT * 
INTO TreatmentRecords_Cleaned
FROM TreatmentRecords