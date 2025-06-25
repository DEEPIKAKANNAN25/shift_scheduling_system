create database shift_scheduler_system;
show databases; --  display a list of all databases present on the MySQL server

/*
 Description:
 This system manages employees, shift types, their availability,
 leaves, shift assignments, swap requests, and audit logging—
 fully implemented in MySQL without any external application code.

 Make sure to create and select your database before running this:
 CREATE DATABASE shift_scheduler_system;
 USE shift_scheduler_system;
*/
-- ========== TABLE DEFINITIONS ===============
-- ============================================

-- Employee master table
-- Stores identity, contact, job role, skills, and shift preferences

USE shift_scheduler_system; -- use this scehema

CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,                      -- Full name
    email VARCHAR(100) UNIQUE,                       -- Email address (must be unique)
    phone_number VARCHAR(15),                        -- Contact number
    role VARCHAR(50),                                -- Job title (e.g., Developer, QA)
    department VARCHAR(50),                          -- Associated team or department
    hire_date DATE,                                  -- Joining date
    employment_status ENUM('Active', 'On Leave', 'Resigned') DEFAULT 'Active', -- Current work status
    skillset TEXT,                                   -- Skill list (e.g., SQL, Java)
    preferred_shift ENUM('Morning', 'Evening', 'Night') -- Preferred working hours
);

-- Shift types offered by the company
CREATE TABLE shifts (
    shift_id INT AUTO_INCREMENT PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL,     -- Name of shift (e.g., Morning)
    start_time TIME NOT NULL,            -- When shift starts
    end_time TIME NOT NULL               -- When shift ends
);

-- Availability of employees by specific date
CREATE TABLE availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,                     -- Foreign key to employees
    available_date DATE,                 -- Date on which the employee is available
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Leave records for employees to prevent shift conflicts
CREATE TABLE leave_requests (
    leave_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,                     -- Foreign key to employees
    leave_start DATE,                    -- Leave start date
    leave_end DATE,                      -- Leave end date
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Shift assignments for specific employee-date combinations
CREATE TABLE shift_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,                     -- FK to employees
    shift_id INT,                        -- FK to shifts
    shift_date DATE,                     -- Date of the shift
    UNIQUE (employee_id, shift_date),    -- Prevent double-booking
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (shift_id) REFERENCES shifts(shift_id)
);

-- Logs swap requests to change shift allocations
CREATE TABLE shift_swap_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    from_employee_id INT,               -- Request initiator
    to_employee_id INT,                 -- Proposed replacement
    shift_date DATE,                    -- Date of the shift
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending', -- Approval status
    FOREIGN KEY (from_employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (to_employee_id) REFERENCES employees(employee_id)
);

-- Audit trail for tracking shift operations
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100),                -- Description of what happened
    employee_id INT,                    -- Affected employee
    shift_id INT,                       -- Related shift
    shift_date DATE,                    -- Date of change
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Auto-timestamp
);


-- TRIGGERS

DELIMITER //

-- Trigger: Log every new shift assignment
CREATE TRIGGER trg_log_shift_assignment
AFTER INSERT ON shift_assignments
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, employee_id, shift_id, shift_date)
  VALUES ('Assigned', NEW.employee_id, NEW.shift_id, NEW.shift_date);
END;
//

-- Trigger: Prevent assignment if employee is on leave
CREATE TRIGGER trg_prevent_assignment_on_leave
BEFORE INSERT ON shift_assignments
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM leave_requests
    WHERE employee_id = NEW.employee_id
    AND NEW.shift_date BETWEEN leave_start AND leave_end
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assignment blocked: employee is on leave';
  END IF;
END;
//

DELIMITER ;


--  STORED PROCEDURE 

DELIMITER //

-- Procedure: Automatically assign available employees to Morning shift
CREATE PROCEDURE auto_assign_shift(IN shift_date_input DATE)
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE emp_id INT;

  DECLARE emp_cursor CURSOR FOR
    SELECT employee_id FROM availability
    WHERE available_date = shift_date_input;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN emp_cursor;

  read_loop: LOOP
    FETCH emp_cursor INTO emp_id;
    IF done THEN LEAVE read_loop; END IF;

    -- Skip if already assigned or on leave
    IF NOT EXISTS (
      SELECT 1 FROM shift_assignments
      WHERE employee_id = emp_id AND shift_date = shift_date_input
    ) AND NOT EXISTS (
      SELECT 1 FROM leave_requests
      WHERE employee_id = emp_id AND shift_date_input BETWEEN leave_start AND leave_end
    ) THEN
      INSERT INTO shift_assignments (employee_id, shift_id, shift_date)
      VALUES (emp_id, 1, shift_date_input); -- Assign shift_id 1 (Morning)
    END IF;

  END LOOP;

  CLOSE emp_cursor;
END;
//

DELIMITER ;

-- VIEWS


-- View: Full shift coverage report with employee info
CREATE VIEW view_shift_coverage AS
SELECT 
    sa.shift_date,
    s.shift_name,
    e.name AS employee_name,
    e.role,
    e.department
FROM shift_assignments sa
JOIN shifts s ON sa.shift_id = s.shift_id
JOIN employees e ON sa.employee_id = e.employee_id;

-- View: Shows who is available but unassigned on a date
CREATE VIEW view_unassigned_employees AS
SELECT 
    a.available_date,
    e.name,
    e.role
FROM availability a
JOIN employees e ON a.employee_id = e.employee_id
LEFT JOIN shift_assignments sa
    ON a.employee_id = sa.employee_id AND a.available_date = sa.shift_date
WHERE sa.assignment_id IS NULL;

-- ============================================
-- ========== SAMPLE DATA =====================
-- ============================================

-- Employees
INSERT INTO employees (name, email, phone_number, role, department, hire_date, employment_status, skillset, preferred_shift)
VALUES 
('Ankit Sharma', 'ankit@techcore.in', '9876543210', 'Software Engineer', 'Development', '2021-03-15', 'Active', 'Java,Spring Boot,REST APIs', 'Morning'),
('Neha Verma', 'neha@techcore.in', '9876543211', 'QA Analyst', 'Quality Assurance', '2020-06-10', 'Active', 'Selenium,TestNG,JIRA', 'Evening'),
('Ravi Menon', 'ravi@techcore.in', '9876543212', 'DevOps Engineer', 'Infrastructure', '2019-09-01', 'Active', 'Docker,Kubernetes,Jenkins,AWS', 'Morning'),
('Sonal Desai', 'sonal@techcore.in', '9876543213', 'Technical Support', 'IT Support', '2022-01-05', 'Active', 'Networking,Troubleshooting', 'Night');

-- Shift definitions
INSERT INTO shifts (shift_name, start_time, end_time)
VALUES 
('Morning', '08:00:00', '14:00:00'),
('Evening', '14:00:00', '20:00:00'),
('Night', '20:00:00', '02:00:00');

-- Availability on June 26, 2025
INSERT INTO availability (employee_id, available_date)
VALUES 
(1, '2025-06-26'),
(2, '2025-06-26'),
(3, '2025-06-26'),
(4, '2025-06-26');

-- Neha's leave entry
INSERT INTO leave_requests (employee_id, leave_start, leave_end)
VALUES 
(2, '2025-06-27', '2025-06-28');

-- Shift assignments for the same date
INSERT INTO shift_assignments (employee_id, shift_id, shift_date)
VALUES 
(1, 1, '2025-06-26'), -- Ankit: Morning
(2, 2, '2025-06-26'), -- Neha: Evening
(3, 1, '2025-06-26'), -- Ravi: Morning
(4, 3, '2025-06-26'); -- Sonal: Night

-- Swap requests by employees (continued)
INSERT INTO shift_swap_requests (from_employee_id, to_employee_id, shift_date, status)
VALUES 
(2, 4, '2025-06-26', 'Pending'),     -- Neha requests to swap with Sonal
(1, 3, '2025-06-26', 'Rejected'),    -- Ankit’s request to swap with Ravi was declined
(4, 1, '2025-06-26', 'Approved');    -- Sonal’s swap with Ankit was approved

-- Manual audit log entries (triggers will populate automatically during real inserts)
INSERT INTO audit_log (action, employee_id, shift_id, shift_date)
VALUES 
('Assigned', 1, 1, '2025-06-26'),              -- Ankit assigned to Morning
('Assigned', 2, 2, '2025-06-26'),              -- Neha assigned to Evening
('Assigned', 3, 1, '2025-06-26'),              -- Ravi assigned to Morning
('Assigned', 4, 3, '2025-06-26'),              -- Sonal assigned to Night
('Manual swap override', 1, 1, '2025-06-26');  -- Ankit involved in a manual swap

-- ADDITIONAL QUERIES WE CAN PREFORM 

-- Get All Shifts Assigned to an Employee
SELECT s.shift_name, sa.shift_date
FROM shift_assignments sa
JOIN shifts s ON sa.shift_id = s.shift_id
WHERE sa.employee_id = 1;

-- Check Shift Coverage for a Specific Date
SELECT s.shift_name, e.name AS employee_name
FROM shift_assignments sa
JOIN shifts s ON sa.shift_id = s.shift_id
JOIN employees e ON sa.employee_id = e.employee_id
WHERE sa.shift_date = '2025-06-26';

-- Pending Shift Swap Requests
SELECT sr.shift_date, f.name AS from_employee, t.name AS to_employee, sr.status
FROM shift_swap_requests sr
JOIN employees f ON sr.from_employee_id = f.employee_id
JOIN employees t ON sr.to_employee_id = t.employee_id
WHERE sr.status = 'Pending';

-- Generate Workload Report by Employee
SELECT e.name, COUNT(sa.assignment_id) AS total_shifts
FROM employees e
LEFT JOIN shift_assignments sa ON e.employee_id = sa.employee_id
GROUP BY e.employee_id;


-- Employees Currently on Leave
SELECT name, leave_start, leave_end
FROM employees e
JOIN leave_requests l ON e.employee_id = l.employee_id
WHERE CURDATE() BETWEEN l.leave_start AND l.leave_end;


