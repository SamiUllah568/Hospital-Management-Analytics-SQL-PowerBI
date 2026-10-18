--# HOSPITAL MANAGEMENT ANALYTICS PROJECT
--# SQL BUSINESS ANALYSIS QUERIES
--# Database: PostgreSQL


-- =========================================
-- CREATE PATIENT TABLE
-- =========================================

CREATE TABLE patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(10),
    date_of_birth DATE,
    contact_number VARCHAR(20),
    address VARCHAR(100),
    registration_date DATE,
    insurance_provider VARCHAR(50),
    insurance_number VARCHAR(20),
    email VARCHAR(100)
);


-- =========================================
-- CREATE DOCTOR TABLE
-- =========================================

CREATE TABLE doctors (
    doctor_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(50),
    phone_number VARCHAR(20),
    years_experience INT,
    hospital_branch VARCHAR(50),
    email VARCHAR(100)
);


-- =========================================
-- CREATE APPOINTMENTS TABLE
-- =========================================

CREATE TABLE appointments (
    appointment_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    doctor_id VARCHAR(20),
    appointment_date DATE,
    appointment_time TIME,
    reason_for_visit VARCHAR(100),
    status VARCHAR(20),

    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);


-- =========================================
-- CREATE TREATMENTS TABLE
-- =========================================

CREATE TABLE treatments (
    treatment_id VARCHAR(10) PRIMARY KEY,
    appointment_id VARCHAR(10),
    treatment_type VARCHAR(50),
    description VARCHAR(100),
    cost NUMERIC(10,2),
    treatment_date DATE,

    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);


-- =========================================
-- CREATE BILLS TABLE
-- =========================================

CREATE TABLE bills (
    bill_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    treatment_id VARCHAR(10),
    bill_date DATE,
    amount NUMERIC(12,2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(20),

    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (treatment_id) REFERENCES treatments(treatment_id)
);




SELECT * FROM patients;
SELECT * FROM doctors;
SELECT * FROM appointments;
SELECT * FROM treatments;
SELECT * FROM bills;



-- =========================================
-- 1. PATIENT ANALYTICS
-- =========================================

-- Q1. How many unique patients visited the hospital during the analysis period?

SELECT
    COUNT(DISTINCT PATIENT_ID) AS TOTAL_UNIQUE_PATIENTS
FROM
    PATIENTS;


-- Q2. How many new patients registered in each month and year?

SELECT
    EXTRACT(YEAR FROM REGISTRATION_DATE) AS REGISTRATION_YEARS,
    EXTRACT(MONTH FROM REGISTRATION_DATE) AS REGISTRATION_MONTH,
    COUNT(*) AS NEW_PATIENTS
FROM PATIENTS
GROUP BY
    EXTRACT(YEAR FROM REGISTRATION_DATE),
    EXTRACT(MONTH FROM REGISTRATION_DATE)
ORDER BY
    REGISTRATION_YEARS,
    REGISTRATION_MONTH;


-- Q3. What is the distribution of patients by gender?

SELECT
    GENDER,
    COUNT(*) AS PATIENT_COUNT
FROM PATIENTS
GROUP BY GENDER
ORDER BY PATIENT_COUNT DESC;


-- Q4. Which patients have the highest number of appointments?

SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    COUNT(a.appointment_id) AS appointment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY
    p.patient_id,
    p.first_name,
    p.last_name
ORDER BY appointment_count DESC;


-- Q5. How many patients are returning patients versus patients with only one appointment?

WITH patient_visits AS (
    SELECT
        patient_id,
        COUNT(*) AS appointment_count
    FROM appointments
    GROUP BY patient_id
)
SELECT
    CASE
        WHEN appointment_count = 1 THEN 'One-Time Patient'
        ELSE 'Returning Patient'
    END AS patient_type,
    COUNT(*) AS patient_count
FROM patient_visits
GROUP BY
    CASE
        WHEN appointment_count = 1 THEN 'One-Time Patient'
        ELSE 'Returning Patient'
    END;


-- =========================================
-- 2. DOCTOR & HOSPITAL OPERATIONS
-- =========================================

-- Q6. How many doctors work in the hospital?

SELECT
    COUNT(*) AS TOTAL_DOCTORS
FROM DOCTORS;


-- Q7. How many doctors work in each hospital branch?

SELECT
    hospital_branch,
    COUNT(*) AS doctor_count
FROM doctors
GROUP BY hospital_branch
ORDER BY doctor_count DESC;


-- Q8. What are the different medical specializations, and how many doctors belong to each specialization?

SELECT
    specialization,
    COUNT(*) AS doctor_count
FROM doctors
GROUP BY specialization
ORDER BY doctor_count DESC;


-- Q9. How many appointments does each doctor handle?

SELECT
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization,
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization
ORDER BY appointment_count DESC;


-- Q10. How does doctor workload vary across hospital branches?

SELECT
    d.hospital_branch,
    COUNT(a.appointment_id) AS total_appointments,
    COUNT(DISTINCT d.doctor_id) AS doctor_count,
    ROUND(
        COUNT(a.appointment_id)::numeric /
        NULLIF(COUNT(DISTINCT d.doctor_id), 0),
        2
    ) AS avg_appointments_per_doctor
FROM doctors d
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.hospital_branch
ORDER BY avg_appointments_per_doctor DESC;


-- Q11. Which doctors have the highest appointment workload relative to other doctors in the same specialization?

WITH doctor_workload AS (
    SELECT
        d.doctor_id,
        d.first_name,
        d.last_name,
        d.specialization,
        COUNT(a.appointment_id) AS appointment_count
    FROM doctors d
    LEFT JOIN appointments a
        ON d.doctor_id = a.doctor_id
    GROUP BY
        d.doctor_id,
        d.first_name,
        d.last_name,
        d.specialization
)
SELECT
    *,
    RANK() OVER (
        PARTITION BY specialization
        ORDER BY appointment_count DESC
    ) AS specialization_rank
FROM doctor_workload
ORDER BY specialization, specialization_rank;


-- =========================================
-- 3. APPOINTMENT & PATIENT VISIT ANALYTICS
-- =========================================

-- Q12. How many appointments were scheduled during the analysis period?

SELECT COUNT(*) AS total_appointments
FROM appointments;


-- Q13. How do appointment volumes change by month?

SELECT
    DATE_TRUNC('month', appointment_date)::date AS month,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY DATE_TRUNC('month', appointment_date)
ORDER BY month;


-- Q14. What is the distribution of appointments by status?

SELECT
    status,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY status
ORDER BY appointment_count DESC;


-- Q15. What percentage of appointments were completed, cancelled, or marked as no-show?

SELECT
    status,
    COUNT(*) AS appointment_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM appointments
GROUP BY status
ORDER BY percentage DESC;


-- Q16. What are the busiest hours of the day based on scheduled appointments?

SELECT
    EXTRACT(HOUR FROM appointment_time) AS appointment_hour,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY EXTRACT(HOUR FROM appointment_time)
ORDER BY appointment_count DESC;


-- Q17. Which days of the week have the highest appointment demand?

SELECT
    TO_CHAR(appointment_date, 'Day') AS day_of_week,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY TO_CHAR(appointment_date, 'Day')
ORDER BY appointment_count DESC;


-- Q18. Which doctors have the highest number of cancelled and no-show appointments?

SELECT
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization,
    COUNT(*) FILTER (WHERE a.status = 'Cancelled') AS cancelled,
    COUNT(*) FILTER (WHERE a.status = 'No-show') AS no_show,
    COUNT(*) FILTER (
        WHERE a.status IN ('Cancelled', 'No-show')
    ) AS total_problem_appointments
FROM doctors d
JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization
ORDER BY total_problem_appointments DESC;


-- Q19. Which branches have the highest appointment cancellation and no-show rates?

SELECT
    d.hospital_branch,
    ROUND((COUNT(*) FILTER(WHERE a.status='Cancelled'))*100.0/COUNT(*),2) AS Cancelled,
    ROUND((COUNT(*) FILTER(WHERE a.status='No-show'))*100.0/COUNT(*),2) AS no_show,
    ROUND(
        COUNT(*) FILTER (
            WHERE a.status IN ('Cancelled', 'No-show')
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_no_show_rate
FROM doctors d
JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.hospital_branch
ORDER BY cancellation_no_show_rate DESC;


-- Q20. How do appointment statuses vary by reason for visit?

SELECT
    reason_for_visit,
    COUNT(*) FILTER (WHERE status = 'Completed') AS completed,
    COUNT(*) FILTER (WHERE status = 'Scheduled') AS scheduled,
    COUNT(*) FILTER (WHERE status = 'Cancelled') AS cancelled,
    COUNT(*) FILTER (WHERE status = 'No-show') AS no_show
FROM appointments
GROUP BY reason_for_visit
ORDER BY reason_for_visit;


-- Q21. Is there a relationship between appointment volume and appointment completion rate across months?

SELECT
    DATE_TRUNC('month', appointment_date)::date AS month,
    COUNT(*) AS total_appointments,
    COUNT(*) FILTER (WHERE status = 'Completed') AS completed_appointments,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'Completed') * 100.0
        / COUNT(*),
        2
    ) AS completion_rate
FROM appointments
GROUP BY DATE_TRUNC('month', appointment_date)
ORDER BY month;


-- =========================================
-- 4. TREATMENT ANALYTICS
-- =========================================

-- Q22. How many treatments were performed during the analysis period?

SELECT COUNT(*) AS total_treatments
FROM treatments;


-- Q23. How many treatments were performed for each treatment type?

SELECT
    treatment_type,
    COUNT(*) AS treatment_count
FROM treatments
GROUP BY treatment_type
ORDER BY treatment_count DESC;


-- Q24. What is the total treatment cost?

SELECT SUM(cost) AS TOTAL_TREATMENT_COST
FROM treatments;


-- Q25. What is the average cost of each treatment type?

SELECT
    treatment_type,
    ROUND(AVG(cost), 2) AS average_cost
FROM treatments
GROUP BY treatment_type
ORDER BY average_cost DESC;


-- Q26. Which treatment types generate the highest total treatment cost?

SELECT
    treatment_type,
    ROUND(SUM(cost), 2) AS total_cost
FROM treatments
GROUP BY treatment_type
ORDER BY total_cost DESC;


-- Q27. How does treatment volume change by month?

SELECT
    DATE_TRUNC('month', treatment_date)::date AS month_,
    COUNT(*) AS treatment_count
FROM treatments
GROUP BY DATE_TRUNC('month', treatment_date)
ORDER BY month_;


-- Q28. Which doctors perform the highest number of treatments?

SELECT
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization,
    COUNT(t.treatment_id) AS treatment_count
FROM doctors d
JOIN appointments a
    ON d.doctor_id = a.doctor_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name,
    d.specialization
ORDER BY treatment_count DESC;


-- Q29. How does treatment cost vary across hospital branches?

SELECT
    d.hospital_branch,
    COUNT(t.treatment_id) AS treatment_count,
    ROUND(SUM(t.cost), 2) AS total_treatment_cost,
    ROUND(AVG(t.cost), 2) AS average_treatment_cost
FROM doctors d
JOIN appointments a
    ON d.doctor_id = a.doctor_id
JOIN treatments t
    ON a.appointment_id = t.appointment_id
GROUP BY d.hospital_branch
ORDER BY total_treatment_cost DESC;


-- =========================================
-- 5. BILLING & PAYMENT ANALYTICS
-- =========================================

-- Q30. What is the total amount billed by the hospital?

SELECT SUM(amount) AS total_amount
FROM bills;


-- Q31. How does billed amount change by month?

SELECT
    DATE_TRUNC('month', bill_date)::date AS month_,
    ROUND(SUM(amount), 2) AS total_billed_amount
FROM bills
GROUP BY DATE_TRUNC('month', bill_date)
ORDER BY month_;


-- Q32. What is the distribution of bills by payment status?

SELECT
    payment_status,
    COUNT(*) AS bill_count
FROM bills
GROUP BY payment_status
ORDER BY bill_count DESC;


-- Q33. How much revenue is associated with Paid, Pending, and Failed bills?

SELECT
    payment_status,
    COUNT(*) AS bill_count,
    ROUND(SUM(amount), 2) AS total_amount
FROM bills
GROUP BY payment_status
ORDER BY total_amount DESC;


-- Q34. Which payment methods generate the highest billed amount?

SELECT
    payment_method,
    COUNT(*) AS bill_count,
    ROUND(SUM(amount), 2) AS total_billed_amount
FROM bills
GROUP BY payment_method
ORDER BY total_billed_amount DESC;


-- Q35. Which payment methods have the highest number of failed payments?

SELECT
    payment_method,
    COUNT(*) FILTER (
        WHERE payment_status = 'Failed'
    ) AS failed_payments
FROM bills
GROUP BY payment_method
ORDER BY failed_payments DESC;


-- Q36. What is the average bill amount?

SELECT
    ROUND(AVG(amount), 2) AS average_bill_amount
FROM bills;


-- Q37. Which treatment types generate the highest billing amounts?

SELECT
    t.treatment_type,
    COUNT(b.bill_id) AS bill_count,
    ROUND(SUM(b.amount), 2) AS total_billed_amount
FROM bills b
JOIN treatments t
    ON b.treatment_id = t.treatment_id
GROUP BY t.treatment_type
ORDER BY total_billed_amount DESC;


-- Q38. Which patients have the highest total billed amounts?

SELECT
    p.patient_id,
    p.first_name,
    p.last_name,
    COUNT(b.bill_id) AS bill_count,
    ROUND(SUM(b.amount), 2) AS total_billed_amount
FROM patients p
JOIN bills b
    ON p.patient_id = b.patient_id
GROUP BY
    p.patient_id,
    p.first_name,
    p.last_name
ORDER BY total_billed_amount DESC;


-- Q39. Which specializations generate the highest billed amounts?

SELECT
    d.specialization,
    COUNT(b.bill_id) AS bill_count,
    ROUND(SUM(b.amount), 2) AS total_billed_amount
FROM bills b
JOIN treatments t
    ON b.treatment_id = t.treatment_id
JOIN appointments a
    ON t.appointment_id = a.appointment_id
JOIN doctors d
    ON a.doctor_id = d.doctor_id
GROUP BY d.specialization
ORDER BY total_billed_amount DESC;


-- Q40. What percentage of the total billed amount is Paid, Pending, and Failed?

SELECT
    payment_status,
    ROUND(SUM(amount), 2) AS amount,
    ROUND(
        SUM(amount) * 100.0 /
        SUM(SUM(amount)) OVER (),
        2
    ) AS percentage_of_total
FROM bills
GROUP BY payment_status
ORDER BY percentage_of_total DESC;


-- Q41. Which payment methods have the highest payment failure rate?

SELECT
    payment_method,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (
        WHERE payment_status = 'Failed'
    ) AS failed_transactions,
    ROUND(
        COUNT(*) FILTER (
            WHERE payment_status = 'Failed'
        ) * 100.0 / COUNT(*),
        2
    ) AS failure_rate
FROM bills
GROUP BY payment_method
ORDER BY failure_rate DESC;


-- =========================================
-- 6. CROSS-FUNCTIONAL BUSINESS ANALYTICS
-- =========================================

-- Q42. What is the relationship between appointment volume and treatment volume by month?

WITH monthly_appointments AS (
    SELECT
        DATE_TRUNC('month', appointment_date)::date AS month,
        COUNT(*) AS appointment_count
    FROM appointments
    GROUP BY DATE_TRUNC('month', appointment_date)
),
monthly_treatments AS (
    SELECT
        DATE_TRUNC('month', treatment_date)::date AS month,
        COUNT(*) AS treatment_count
    FROM treatments
    GROUP BY DATE_TRUNC('month', treatment_date)
)
SELECT
    COALESCE(a.month, t.month) AS month,
    COALESCE(a.appointment_count, 0) AS appointment_count,
    COALESCE(t.treatment_count, 0) AS treatment_count
FROM monthly_appointments a
FULL OUTER JOIN monthly_treatments t
    ON a.month = t.month
ORDER BY month;


-- Q43. What percentage of appointments result in a treatment?

SELECT
    COUNT(DISTINCT t.appointment_id) AS appointments_with_treatment,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    ROUND(
        COUNT(DISTINCT t.appointment_id) * 100.0 /
        COUNT(DISTINCT a.appointment_id),
        2
    ) AS treatment_rate
FROM appointments a
LEFT JOIN treatments t
    ON a.appointment_id = t.appointment_id;


-- Q44. What is the average treatment cost per patient?

SELECT
    ROUND(
        SUM(t.cost) / COUNT(DISTINCT a.patient_id),
        2
    ) AS average_treatment_cost_per_patient
FROM appointments a
JOIN treatments t
    ON a.appointment_id = t.appointment_id;


-- Q45. What is the average billed amount per patient?

SELECT
    ROUND(
        SUM(amount) / COUNT(DISTINCT patient_id),
        2
    ) AS average_billed_amount_per_patient
FROM bills;

 







