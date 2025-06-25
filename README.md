# 🗓️ Shift Scheduling System (SQL-Only)

A comprehensive shift management system built entirely with **MySQL**, designed to automate employee scheduling, manage leave conflicts, and track audit history—all without needing a backend or frontend application.

---

## 📌 Overview

This SQL-only project simulates a real-world IT department’s shift management process. It supports:

- Managing employee records and skillsets
- Defining Morning, Evening, and Night shifts
- Recording employee availability and leave
- Assigning employees to shifts (manually or automatically)
- Requesting and resolving shift swaps
- Auditing every shift assignment and change

---

## 🛠 Tech Stack

| Component  | Purpose                |
|------------|------------------------|
| MySQL      | Core database engine   |
| SQL        | Business logic & rules |
| Triggers   | Prevent conflicts, log changes |
| Procedures | Automate assignments   |
| Views      | Real-time reporting    |

> No frontend. No application code. Pure SQL power.

---

## 🧱 Database Schema

### 📋 Tables

- `employees` – Master info: roles, skills, shift preferences
- `shifts` – Defines available shift types
- `availability` – Stores who is available on which dates
- `leave_requests` – Prevents assigning during personal leave
- `shift_assignments` – Actual shift allocations
- `shift_swap_requests` – Handles inter-employee swaps
- `audit_log` – Logs all assignment changes

### 🔄 Triggers

- `trg_log_shift_assignment` – Inserts a log on every new assignment
- `trg_prevent_assignment_on_leave` – Blocks assignments if employee is on leave

### 🧠 Stored Procedure

- `auto_assign_shift(date)` – Loops through all available employees and auto-assigns them to the Morning shift (or modify to suit)

### 🧪 Views

- `view_shift_coverage` – Who’s working what shift and when
- `view_unassigned_employees` – Shows who is available but not yet scheduled

---

## 🧰 Setup Instructions

1. Install MySQL & Set Up Your Environment 
Make sure you have one of the following installed: 
MySQL Workbench (recommended for GUI-based interaction) 
XAMPP/phpMyAdmin (for browser-based SQL interface) 
MySQL CLI (for command-line execution)  
2. Create and Open Your SQL File 
Open your SQL IDE (e.g., MySQL Workbench), then: 
Create a new SQL file 
Copy and paste the entire content of your .sql project (the one we just finished) 
3. Execute the Script 
Your script already contains: 
sql 
Copy 
Edit 
CREATE DATABASE IF NOT EXISTS shift_scheduler_system; 
USE shift_scheduler_system; 
So when you run it: 
The database will be created if it doesn’t exist 
All tables, triggers, stored procedures, views, and sample data will be initialized 
In MySQL Workbench, press Ctrl + Shift + Enter or click the ￾ Execute button. 
4. Verify It’s Working 
Try some basic tests: 
sql 
Copy 
Edit 
-- See available databases 
SHOW DATABASES; 
-- Use your new database 
USE shift_scheduler_system; 
-- See all employees 
SELECT * FROM employees; 
-- View shift coverage report 
SELECT * FROM view_shift_coverage; 
-- Try assigning shifts automatically 
CALL auto_assign_shift(’2025-06-26’); 
5. Explore, Modify, and Extend 
You can now: 
Add more employees or shift types 
Insert availability or leave records 
Test triggers by trying to assign a shift during a leave period 
Approve or reject swap requests manually 
Use the views for daily shift coverage reports or admin dashboard
