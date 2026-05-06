-- =========================
-- SCHEMA (USER)
-- =========================
CREATE USER HMS IDENTIFIED BY hms123;
GRANT CONNECT, RESOURCE TO HMS;
ALTER USER HMS QUOTA UNLIMITED ON USERS;

ALTER SESSION SET CURRENT_SCHEMA = HMS;

-- =========================
-- MASTER TABLES
-- =========================

CREATE TABLE Gender (
    GenderID NUMBER PRIMARY KEY,
    Name NVARCHAR2(50),
    Status NUMBER(1) DEFAULT 1
);

CREATE TABLE Department (
    DepartmentID NUMBER PRIMARY KEY,
    Name NVARCHAR2(50),
    IsClinical NUMBER(1),
    Status NUMBER(1) DEFAULT 1
);

CREATE TABLE Country (
    CountryID NUMBER PRIMARY KEY,
    Name NVARCHAR2(50)
);

CREATE TABLE State (
    StateID NUMBER PRIMARY KEY,
    Name NVARCHAR2(50),
    CountryID NUMBER,
    CONSTRAINT FK_State_Country FOREIGN KEY (CountryID)
    REFERENCES Country(CountryID)
);

CREATE TABLE City (
    CityID NUMBER PRIMARY KEY,
    Name NVARCHAR2(50),
    StateID NUMBER,
    CONSTRAINT FK_City_State FOREIGN KEY (StateID)
    REFERENCES State(StateID)
);

-- =========================
-- CORE TABLES
-- =========================

CREATE TABLE Patient (
    PatientID NUMBER PRIMARY KEY,
    FirstName NVARCHAR2(150),
    LastName NVARCHAR2(150),
    GenderID NUMBER,
    CityID NUMBER,
    Status NUMBER(1) DEFAULT 1,

    CONSTRAINT FK_Patient_Gender FOREIGN KEY (GenderID)
    REFERENCES Gender(GenderID),

    CONSTRAINT FK_Patient_City FOREIGN KEY (CityID)
    REFERENCES City(CityID)
);

CREATE TABLE Doctor (
    DoctorID NUMBER PRIMARY KEY,
    FirstName NVARCHAR2(150),
    LastName NVARCHAR2(150),
    DepartmentID NUMBER,
    GenderID NUMBER,
    CityID NUMBER,

    CONSTRAINT FK_Doctor_Department FOREIGN KEY (DepartmentID)
    REFERENCES Department(DepartmentID),

    CONSTRAINT FK_Doctor_Gender FOREIGN KEY (GenderID)
    REFERENCES Gender(GenderID),

    CONSTRAINT FK_Doctor_City FOREIGN KEY (CityID)
    REFERENCES City(CityID)
);

CREATE TABLE Visit (
    VisitId NUMBER PRIMARY KEY,
    PatientId NUMBER,
    DoctorID NUMBER,
    VisitDate DATE DEFAULT SYSDATE,

    CONSTRAINT FK_Visit_Patient FOREIGN KEY (PatientId)
    REFERENCES Patient(PatientID),

    CONSTRAINT FK_Visit_Doctor FOREIGN KEY (DoctorID)
    REFERENCES Doctor(DoctorID)
);

CREATE TABLE Admission (
    AdmissionId NUMBER PRIMARY KEY,
    PatientId NUMBER,
    DoctorId NUMBER,
    AdmissionDate DATE DEFAULT SYSDATE,

    CONSTRAINT FK_Admission_Patient FOREIGN KEY (PatientId)
    REFERENCES Patient(PatientID),

    CONSTRAINT FK_Admission_Doctor FOREIGN KEY (DoctorId)
    REFERENCES Doctor(DoctorID)
);

CREATE TABLE Bill (
    BillId NUMBER PRIMARY KEY,
    VisitId NUMBER,
    AdmissionId NUMBER,
    TotalAmount NUMBER(18,2),

    CONSTRAINT FK_Bill_Visit FOREIGN KEY (VisitId)
    REFERENCES Visit(VisitId),

    CONSTRAINT FK_Bill_Admission FOREIGN KEY (AdmissionId)
    REFERENCES Admission(AdmissionId)
);

-- =========================
-- CHILD TABLES
-- =========================

CREATE TABLE Prescription (
    PrescriptionId NUMBER PRIMARY KEY,
    VisitId NUMBER,
    Path VARCHAR2(500),

    CONSTRAINT FK_Prescription_Visit FOREIGN KEY (VisitId)
    REFERENCES Visit(VisitId)
);

CREATE TABLE ClinicalNote (
    ClinicalNoteId NUMBER PRIMARY KEY,
    AdmissionId NUMBER,
    Path VARCHAR2(500),

    CONSTRAINT FK_ClinicalNote_Admission FOREIGN KEY (AdmissionId)
    REFERENCES Admission(AdmissionId)
);

-- =========================
-- SEQUENCES + TRIGGERS
-- =========================

CREATE SEQUENCE Gender_SEQ;
CREATE SEQUENCE Department_SEQ;
CREATE SEQUENCE Country_SEQ;
CREATE SEQUENCE State_SEQ;
CREATE SEQUENCE City_SEQ;
CREATE SEQUENCE Patient_SEQ;
CREATE SEQUENCE Doctor_SEQ;
CREATE SEQUENCE Visit_SEQ;
CREATE SEQUENCE Admission_SEQ;
CREATE SEQUENCE Bill_SEQ;
CREATE SEQUENCE Prescription_SEQ;
CREATE SEQUENCE ClinicalNote_SEQ;

-- Generic Trigger Template

CREATE OR REPLACE TRIGGER Gender_TRG
BEFORE INSERT ON Gender FOR EACH ROW
BEGIN
    IF :NEW.GenderID IS NULL THEN
        SELECT Gender_SEQ.NEXTVAL INTO :NEW.GenderID FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Patient_TRG
BEFORE INSERT ON Patient FOR EACH ROW
BEGIN
    IF :NEW.PatientID IS NULL THEN
        SELECT Patient_SEQ.NEXTVAL INTO :NEW.PatientID FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Doctor_TRG
BEFORE INSERT ON Doctor FOR EACH ROW
BEGIN
    IF :NEW.DoctorID IS NULL THEN
        SELECT Doctor_SEQ.NEXTVAL INTO :NEW.DoctorID FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Visit_TRG
BEFORE INSERT ON Visit FOR EACH ROW
BEGIN
    IF :NEW.VisitId IS NULL THEN
        SELECT Visit_SEQ.NEXTVAL INTO :NEW.VisitId FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Admission_TRG
BEFORE INSERT ON Admission FOR EACH ROW
BEGIN
    IF :NEW.AdmissionId IS NULL THEN
        SELECT Admission_SEQ.NEXTVAL INTO :NEW.AdmissionId FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Bill_TRG
BEFORE INSERT ON Bill FOR EACH ROW
BEGIN
    IF :NEW.BillId IS NULL THEN
        SELECT Bill_SEQ.NEXTVAL INTO :NEW.BillId FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER Prescription_TRG
BEFORE INSERT ON Prescription FOR EACH ROW
BEGIN
    IF :NEW.PrescriptionId IS NULL THEN
        SELECT Prescription_SEQ.NEXTVAL INTO :NEW.PrescriptionId FROM dual;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER ClinicalNote_TRG
BEFORE INSERT ON ClinicalNote FOR EACH ROW
BEGIN
    IF :NEW.ClinicalNoteId IS NULL THEN
        SELECT ClinicalNote_SEQ.NEXTVAL INTO :NEW.ClinicalNoteId FROM dual;
    END IF;
END;
/

-- =========================
-- VIEWS
-- =========================

CREATE OR REPLACE VIEW View_Patient AS
SELECT 
    P.PatientID,
    P.FirstName,
    P.LastName,
    G.Name AS Gender,
    C.Name AS City
FROM Patient P
JOIN Gender G ON P.GenderID = G.GenderID
JOIN City C ON P.CityID = C.CityID;

CREATE OR REPLACE VIEW View_Doctor AS
SELECT 
    D.DoctorID,
    D.FirstName,
    D.LastName,
    DP.Name AS Department
FROM Doctor D
JOIN Department DP ON D.DepartmentID = DP.DepartmentID;


------------------
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- MASTER DATA INSERT ---');

    ---------------- PATIENT CATEGORY ----------------
    INSERT INTO PatientCategory (PatientCategoryId, Name, AddedBy, UpdatedBy)
    VALUES (1, 'General', 1, 1);

    INSERT INTO PatientCategory VALUES (2, 'Corporate', 1, 1);
    INSERT INTO PatientCategory VALUES (3, 'Insurance', 1, 1);

    ---------------- GENDER ----------------
    INSERT INTO Gender VALUES (1, 'Male', 1, 1);
    INSERT INTO Gender VALUES (2, 'Female', 1, 1);

    ---------------- DEPARTMENT ----------------
    INSERT INTO Department VALUES (1, 'Cardiology', 1, 1, 1);
    INSERT INTO Department VALUES (2, 'Neurology', 1, 1, 1);
    INSERT INTO Department VALUES (3, 'Orthopedic', 1, 1, 1);
    INSERT INTO Department VALUES (4, 'Billing', 0, 1, 1);
    INSERT INTO Department VALUES (5, 'Administration', 0, 1, 1);

    ---------------- CITY ----------------
    INSERT INTO City VALUES (1, 'Pune', 1, 1, 1);
    INSERT INTO City VALUES (2, 'Nagpur', 1, 1, 1);
    INSERT INTO City VALUES (3, 'Mumbai', 1, 1, 1);

    ---------------- UNIT ----------------
    INSERT INTO Unit VALUES (1, 'Unit A', 1, 1);
    INSERT INTO Unit VALUES (2, 'Unit B', 1, 1);

    ---------------- WARD ----------------
    INSERT INTO Ward VALUES (1, 'General Ward', 1, 1, 1);
    INSERT INTO Ward VALUES (2, 'Special Ward', 1, 1, 1);

    ---------------- ROOM ----------------
    INSERT INTO Room VALUES (1, 'Room 101', 1, 1, 1);
    INSERT INTO Room VALUES (2, 'Room 102', 2, 1, 1);

    ---------------- BED ----------------
    FOR i IN 1..10 LOOP
        INSERT INTO Bed VALUES (i, 'Bed-' || i, 1, NULL, 1, 1);
    END LOOP;

    ---------------- STAFF ----------------
    DBMS_OUTPUT.PUT_LINE('--- STAFF INSERT ---');

    FOR dept IN 4..5 LOOP
        FOR i IN 1..5 LOOP
            INSERT INTO Staff (
                StaffId, DepartmentId, FirstName, LastName,
                GenderId, ContactNo1, CityId, AddedBy, UpdatedBy
            )
            VALUES (
                (dept*100)+i,
                dept,
                'Staff_' || dept || '_' || i,
                'Emp',
                MOD(i,2)+1,
                '9999999999',
                MOD(i,3)+1,
                1,
                1
            );
        END LOOP;
    END LOOP;

    ---------------- DOCTOR ----------------
    DBMS_OUTPUT.PUT_LINE('--- DOCTOR INSERT ---');

    FOR dept IN 1..3 LOOP
        FOR i IN 1..3 LOOP
            INSERT INTO Doctor (
                DoctorId, DepartmentId, FirstName, LastName,
                Qualification, GenderId, ContactNo1, CityId,
                AddedBy, UpdatedBy
            )
            VALUES (
                (dept*10)+i,
                dept,
                'Dr_' || dept || '_' || i,
                'Specialist',
                'MBBS',
                MOD(i,2)+1,
                '8888888888',
                MOD(i,3)+1,
                1,
                1
            );
        END LOOP;
    END LOOP;

    ---------------- PATIENT ----------------
    DBMS_OUTPUT.PUT_LINE('--- PATIENT INSERT ---');

    FOR i IN 1..100 LOOP
        INSERT INTO Patient (
            PatientId, FirstName, LastName, GenderId,
            ContactNo1, CityId, AddedBy, UpdatedBy
        )
        VALUES (
            i,
            'Patient_' || i,
            'Test',
            MOD(i,2)+1,
            '7777777777',
            MOD(i,3)+1,
            1,
            1
        );
    END LOOP;

    ---------------- VISIT ----------------
    DBMS_OUTPUT.PUT_LINE('--- VISIT INSERT ---');

    FOR i IN 1..50 LOOP
        INSERT INTO Visit (
            VisitId, PatientCategoryId, PatientId,
            DoctorId, UnitId, VisitDate,
            AddedBy, UpdatedBy
        )
        VALUES (
            i,
            MOD(i,3)+1,
            MOD(i,100)+1,
            MOD(i,9)+1,
            MOD(i,2)+1,
            SYSDATE - DBMS_RANDOM.VALUE(1,100),
            1,
            1
        );
    END LOOP;

    ---------------- SERVICE ----------------
    DBMS_OUTPUT.PUT_LINE('--- SERVICE INSERT ---');

    INSERT INTO Service VALUES (1, 'Consultation', 1, 200, 1, NULL, 1, 1);
    INSERT INTO Service VALUES (2, 'X-Ray', 2, 500, 1, NULL, 1, 1);
    INSERT INTO Service VALUES (3, 'Bed Charges', 3, 1000, 2, NULL, 1, 1);

    ---------------- CHARGE ----------------
    DBMS_OUTPUT.PUT_LINE('--- CHARGE INSERT ---');

    FOR i IN 1..50 LOOP
        INSERT INTO Charge (
            ChargeId, VisitId, ServiceId,
            Rate, Quantity, Amount,
            AddedBy, UpdatedBy
        )
        VALUES (
            i,
            i,
            MOD(i,3)+1,
            200,
            1,
            200,
            1,
            1
        );
    END LOOP;

    ---------------- BILL ----------------
    DBMS_OUTPUT.PUT_LINE('--- BILL INSERT ---');

    FOR i IN 1..50 LOOP
        INSERT INTO Bill (
            BillId, VisitId, TotalAmount,
            Concession, FinalBillAmount,
            AddedBy, UpdatedBy
        )
        VALUES (
            i,
            i,
            200,
            20,
            180,
            1,
            1
        );
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--- DATA INSERT COMPLETED SUCCESSFULLY ---');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/


SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- MASTER TABLES ---');

    FOR rec IN (SELECT * FROM Department) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Gender) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM InsuranceCompany) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Nationality) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM PatientCategory) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Relation) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM ServiceCategory) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM ServiceType) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Unit) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Ward) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Country) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Room) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Service) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Bed) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM State) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM City) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Doctor) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Patient) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Staff) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Visit) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Admission) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Advance) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Charge) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Bill) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Discharge) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM ApplicationFunctionality) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM "User") LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM AccessRights) LOOP NULL; END LOOP;

    DBMS_OUTPUT.PUT_LINE('--- TOP 10 ADMISSION ---');

    FOR rec IN (SELECT * FROM Admission WHERE ROWNUM <= 10) LOOP NULL; END LOOP;

    ------------------ OPD ------------------
    DBMS_OUTPUT.PUT_LINE('--- OPD DATA ---');

    FOR rec IN (SELECT * FROM Patient WHERE PatientId = 28203) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Visit WHERE VisitId = 4394) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Admission WHERE PatientId = 28615) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Charge WHERE VisitId = 4394) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Bill WHERE VisitId = 4394) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Discharge) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Advance) LOOP NULL; END LOOP;

    ------------------ IPD ------------------
    DBMS_OUTPUT.PUT_LINE('--- IPD DATA ---');

    FOR rec IN (SELECT * FROM Patient WHERE PatientId = 6396) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Visit WHERE PatientId = 6396) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Admission WHERE PatientId = 6396) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Charge WHERE AdmissionId = 11) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Bill WHERE AdmissionId = 11) LOOP NULL; END LOOP;
    FOR rec IN (SELECT * FROM Discharge WHERE AdmissionId = 11) LOOP NULL; END LOOP;

    ------------------ SERVICE JOIN ------------------
    DBMS_OUTPUT.PUT_LINE('--- SERVICE DETAILS ---');

    FOR rec IN (
        SELECT 
            ST.Name AS ServiceType,
            SC.Name AS ServiceCategory,
            S.Name AS ServiceName,
            S.Rate,
            S.CompanyId
        FROM Service S
        LEFT JOIN ServiceCategory SC 
            ON S.ServiceCategoryId = SC.ServiceCategoryId
        LEFT JOIN ServiceType ST 
            ON S.ServiceTypeID = ST.ServiceTypeID
        ORDER BY ST.Name
    ) LOOP NULL; END LOOP;

    DBMS_OUTPUT.PUT_LINE('--- ALL QUERIES EXECUTED SUCCESSFULLY ---');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/


SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('===== HMS PL/SQL QUESTIONS (1–5) =====');

    -------------------------------------------------
    -- Q1: COUNT TOTAL PATIENTS
    -------------------------------------------------
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM Patient;
        DBMS_OUTPUT.PUT_LINE('Q1: Total Patients = ' || v_count);
    END;

    -------------------------------------------------
    -- Q2: DISPLAY DOCTORS WITH DEPARTMENT
    -------------------------------------------------
    DECLARE
        CURSOR doc_cur IS
            SELECT D.FirstName, D.LastName, DP.Name
            FROM Doctor D
            JOIN Department DP ON D.DepartmentID = DP.DepartmentID;

        v_fname Doctor.FirstName%TYPE;
        v_lname Doctor.LastName%TYPE;
        v_dept  Department.Name%TYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Q2: Doctor List');

        OPEN doc_cur;
        LOOP
            FETCH doc_cur INTO v_fname, v_lname, v_dept;
            EXIT WHEN doc_cur%NOTFOUND;

            DBMS_OUTPUT.PUT_LINE(v_fname || ' ' || v_lname || ' - ' || v_dept);
        END LOOP;
        CLOSE doc_cur;
    END;

    -------------------------------------------------
    -- Q3: INSERT NEW VISIT
    -------------------------------------------------
    BEGIN
        INSERT INTO Visit (VisitId, PatientId, DoctorID, VisitDate)
        VALUES (Visit_SEQ.NEXTVAL, 1, 1, SYSDATE);

        DBMS_OUTPUT.PUT_LINE('Q3: New Visit Inserted');
    END;

    -------------------------------------------------
    -- Q4: TOTAL BILL FOR VISIT
    -------------------------------------------------
    DECLARE
        v_total NUMBER;
        v_visit_id NUMBER := 1;
    BEGIN
        SELECT TotalAmount INTO v_total
        FROM Bill
        WHERE VisitId = v_visit_id;

        DBMS_OUTPUT.PUT_LINE('Q4: Total Bill = ' || v_total);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Q4: No Bill Found');
    END;

    -------------------------------------------------
    -- Q5: DISPLAY ADMITTED PATIENTS
    -------------------------------------------------
    DECLARE
        CURSOR admit_cur IS
            SELECT P.FirstName, P.LastName, A.AdmissionDate
            FROM Patient P
            JOIN Admission A ON P.PatientID = A.PatientId;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Q5: Admitted Patients');

        FOR rec IN admit_cur LOOP
            DBMS_OUTPUT.PUT_LINE(
                rec.FirstName || ' ' || rec.LastName ||
                ' - ' || TO_CHAR(rec.AdmissionDate, 'DD-MON-YYYY')
            );
        END LOOP;
    END;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('===== EXECUTION COMPLETED =====');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
