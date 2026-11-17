
CREATE TABLE Department (
    department_id     INT            PRIMARY KEY,
    department_name   VARCHAR(100)   NOT NULL UNIQUE,
    building          VARCHAR(100),
    phone             VARCHAR(20),
    head_faculty_id   INT            NULL
) ENGINE=InnoDB;

CREATE TABLE Program (
    program_id        INT            PRIMARY KEY,
    program_name      VARCHAR(100)   NOT NULL,
    degree_level      VARCHAR(20)    NOT NULL,
    department_id     INT            NOT NULL,
    CONSTRAINT chk_program_degree
        CHECK (degree_level IN ('Bachelor','Master','PhD','Diploma')),
    CONSTRAINT fk_program_dept
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Faculty (
    faculty_id        INT            PRIMARY KEY,
    first_name        VARCHAR(50)    NOT NULL,
    last_name         VARCHAR(50)    NOT NULL,
    email             VARCHAR(120)   NOT NULL UNIQUE,
    phone             VARCHAR(20),
    hire_date         DATE           NOT NULL DEFAULT (CURRENT_DATE),
    title             VARCHAR(50),
    salary            DECIMAL(12,2),
    department_id     INT            NOT NULL,
    mentor_id         INT            NULL,
    CONSTRAINT chk_faculty_email
        CHECK (email LIKE '%@%'),
    CONSTRAINT chk_faculty_title
        CHECK (title IS NULL OR title IN ('Professor','Associate Professor',
                                          'Assistant Professor','Lecturer','Researcher')),
    CONSTRAINT chk_faculty_salary
        CHECK (salary IS NULL OR salary >= 0),
    CONSTRAINT fk_faculty_dept
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_faculty_mentor
        FOREIGN KEY (mentor_id) REFERENCES Faculty(faculty_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

ALTER TABLE Department
    ADD CONSTRAINT fk_dept_head
    FOREIGN KEY (head_faculty_id) REFERENCES Faculty(faculty_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

DELIMITER $$

CREATE TRIGGER trg_faculty_no_self_mentor_insert
BEFORE INSERT ON Faculty
FOR EACH ROW
BEGIN
    IF NEW.mentor_id IS NOT NULL AND NEW.mentor_id = NEW.faculty_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A faculty member cannot be their own mentor.';
    END IF;
END$$

CREATE TRIGGER trg_faculty_no_self_mentor_update
BEFORE UPDATE ON Faculty
FOR EACH ROW
BEGIN
    IF NEW.mentor_id IS NOT NULL AND NEW.mentor_id = NEW.faculty_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A faculty member cannot be their own mentor.';
    END IF;
END$$

DELIMITER ;


CREATE TABLE Student (
    student_id        INT            PRIMARY KEY,
    first_name        VARCHAR(50)    NOT NULL,
    last_name         VARCHAR(50)    NOT NULL,
    email             VARCHAR(120)   NOT NULL UNIQUE,
    phone             VARCHAR(20),
    date_of_birth     DATE,
    enrollment_date   DATE           NOT NULL DEFAULT (CURRENT_DATE),
    academic_status   VARCHAR(20)    NOT NULL DEFAULT 'Active',
    program_id        INT            NOT NULL,
    supervisor_id     INT            NULL,
    CONSTRAINT chk_student_email
        CHECK (email LIKE '%@%'),
    CONSTRAINT chk_student_status
        CHECK (academic_status IN ('Active','Suspended','Graduated','Withdrawn')),
    CONSTRAINT fk_student_program
        FOREIGN KEY (program_id) REFERENCES Program(program_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_student_supervisor
        FOREIGN KEY (supervisor_id) REFERENCES Faculty(faculty_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE ResearchProject (
    project_id        INT            PRIMARY KEY,
    project_title     VARCHAR(200)   NOT NULL,
    start_date        DATE           NOT NULL DEFAULT (CURRENT_DATE),
    end_date          DATE,
    status            VARCHAR(20)    NOT NULL DEFAULT 'Active',
    department_id     INT            NOT NULL,
    lead_faculty_id   INT            NULL,
    CONSTRAINT chk_project_status
        CHECK (status IN ('Proposed','Active','Completed','Cancelled')),
    CONSTRAINT chk_project_dates
        CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT fk_project_dept
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_project_lead
        FOREIGN KEY (lead_faculty_id) REFERENCES Faculty(faculty_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE FacultyProject (
    faculty_id        INT            NOT NULL,
    project_id        INT            NOT NULL,
    supervision_role  VARCHAR(50)    NOT NULL DEFAULT 'Co-Investigator',
    start_date        DATE           NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (faculty_id, project_id),
    CONSTRAINT chk_fp_role
        CHECK (supervision_role IN ('Principal Investigator','Co-Investigator',
                                    'Supervisor','Advisor','Consultant')),
    CONSTRAINT fk_fp_faculty
        FOREIGN KEY (faculty_id) REFERENCES Faculty(faculty_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fp_project
        FOREIGN KEY (project_id) REFERENCES ResearchProject(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE StudentProject (
    student_id               INT            NOT NULL,
    project_id               INT            NOT NULL,
    project_role             VARCHAR(50)    NOT NULL DEFAULT 'Researcher',
    contribution_percentage  DECIMAL(5,2)   NOT NULL DEFAULT 0,
    join_date                DATE           NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (student_id, project_id),
    CONSTRAINT chk_sp_role
        CHECK (project_role IN ('Researcher','Assistant','Lead Student','Intern','Volunteer')),
    CONSTRAINT chk_sp_contrib
        CHECK (contribution_percentage BETWEEN 0 AND 100),
    CONSTRAINT fk_sp_student
        FOREIGN KEY (student_id) REFERENCES Student(student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sp_project
        FOREIGN KEY (project_id) REFERENCES ResearchProject(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE FundingSource (
    source_id         INT            PRIMARY KEY,
    source_name       VARCHAR(150)   NOT NULL UNIQUE,
    source_type       VARCHAR(50),
    contact_email     VARCHAR(120),
    country           VARCHAR(60),
    CONSTRAINT chk_source_type
        CHECK (source_type IS NULL OR source_type IN
               ('Government','Industry','University','Non-Profit','International'))
) ENGINE=InnoDB;

CREATE TABLE Funding (
    funding_id        INT            PRIMARY KEY,
    project_id        INT            NOT NULL,
    source_id         INT            NOT NULL,
    funding_amount    DECIMAL(14,2)  NOT NULL,
    funding_date      DATE           NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_funding_amount
        CHECK (funding_amount >= 0),
    CONSTRAINT fk_funding_project
        FOREIGN KEY (project_id) REFERENCES ResearchProject(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_funding_source
        FOREIGN KEY (source_id) REFERENCES FundingSource(source_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Publication (
    publication_id    INT            PRIMARY KEY,
    title             VARCHAR(300)   NOT NULL,
    publication_type  VARCHAR(30)    NOT NULL,
    publication_year  INT            NOT NULL,
    doi               VARCHAR(100)   UNIQUE,
    journal_name      VARCHAR(150),
    CONSTRAINT chk_pub_type
        CHECK (publication_type IN ('Journal','Conference','Book Chapter','Workshop')),
    CONSTRAINT chk_pub_year
        CHECK (publication_year BETWEEN 1900 AND 2100)
) ENGINE=InnoDB;

CREATE TABLE PublicationAuthor (
    publication_id    INT            NOT NULL,
    faculty_id        INT            NOT NULL,
    author_order      INT            NOT NULL,
    is_corresponding  BOOLEAN        NOT NULL DEFAULT FALSE,
    PRIMARY KEY (publication_id, faculty_id),
    CONSTRAINT uq_pub_author_order UNIQUE (publication_id, author_order),
    CONSTRAINT chk_author_order CHECK (author_order > 0),
    CONSTRAINT fk_pa_publication
        FOREIGN KEY (publication_id) REFERENCES Publication(publication_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pa_faculty
        FOREIGN KEY (faculty_id) REFERENCES Faculty(faculty_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Conference (
    conference_id       INT            PRIMARY KEY,
    conference_name     VARCHAR(200)   NOT NULL,
    location            VARCHAR(150),
    conference_date     DATE           NOT NULL,
    submission_deadline DATE,
    CONSTRAINT chk_conf_dates
        CHECK (submission_deadline IS NULL OR submission_deadline <= conference_date)
) ENGINE=InnoDB;

CREATE TABLE Submission (
    submission_id     INT            PRIMARY KEY,
    publication_id    INT            NOT NULL,
    conference_id     INT            NOT NULL,
    submission_date   DATE           NOT NULL DEFAULT (CURRENT_DATE),
    decision          VARCHAR(20)    NOT NULL DEFAULT 'Pending',
    decision_date     DATE,
    CONSTRAINT chk_sub_decision
        CHECK (decision IN ('Pending','Accepted','Rejected','Revision')),
    CONSTRAINT uq_sub_pub_conf UNIQUE (publication_id, conference_id),
    CONSTRAINT fk_sub_publication
        FOREIGN KEY (publication_id) REFERENCES Publication(publication_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sub_conference
        FOREIGN KEY (conference_id) REFERENCES Conference(conference_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Review (
    review_id           INT            PRIMARY KEY,
    submission_id       INT            NOT NULL,
    reviewer_faculty_id INT            NULL,
    reviewer_name       VARCHAR(120),
    review_score        DECIMAL(4,2)   NOT NULL,
    review_comments     TEXT,
    review_date         DATE           NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT chk_review_score CHECK (review_score BETWEEN 0 AND 10),
    CONSTRAINT fk_review_submission
        FOREIGN KEY (submission_id) REFERENCES Submission(submission_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_review_faculty
        FOREIGN KEY (reviewer_faculty_id) REFERENCES Faculty(faculty_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

CREATE TRIGGER trg_review_reviewer_present_insert
BEFORE INSERT ON Review
FOR EACH ROW
BEGIN
    IF NEW.reviewer_faculty_id IS NULL AND NEW.reviewer_name IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A review must have either a reviewer_faculty_id or a reviewer_name.';
    END IF;
END$$

CREATE TRIGGER trg_review_reviewer_present_update
BEFORE UPDATE ON Review
FOR EACH ROW
BEGIN
    IF NEW.reviewer_faculty_id IS NULL AND NEW.reviewer_name IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A review must have either a reviewer_faculty_id or a reviewer_name.';
    END IF;
END$$

DELIMITER ;

CREATE TABLE Revision (
    revision_id       INT            PRIMARY KEY,
    submission_id     INT            NOT NULL,
    revision_number   INT            NOT NULL,
    revision_date     DATE           NOT NULL DEFAULT (CURRENT_DATE),
    revision_notes    TEXT,
    CONSTRAINT chk_revision_number CHECK (revision_number > 0),
    CONSTRAINT uq_revision_number UNIQUE (submission_id, revision_number),
    CONSTRAINT fk_revision_submission
        FOREIGN KEY (submission_id) REFERENCES Submission(submission_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Equipment (
    equipment_id      INT            PRIMARY KEY,
    equipment_name    VARCHAR(150)   NOT NULL,
    serial_number     VARCHAR(80)    UNIQUE,
    purchase_date     DATE,
    condition_status  VARCHAR(20)    NOT NULL DEFAULT 'Good',
    department_id     INT            NOT NULL,
    CONSTRAINT chk_equip_condition
        CHECK (condition_status IN ('Good','Fair','Poor','Out of Service')),
    CONSTRAINT fk_equipment_dept
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE EquipmentUsage (
    equipment_id      INT            NOT NULL,
    project_id        INT            NOT NULL,
    usage_date        DATE           NOT NULL,
    usage_purpose     VARCHAR(200),
    PRIMARY KEY (equipment_id, project_id, usage_date),
    CONSTRAINT fk_eu_equipment
        FOREIGN KEY (equipment_id) REFERENCES Equipment(equipment_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_eu_project
        FOREIGN KEY (project_id) REFERENCES ResearchProject(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE AuditLog (
    audit_id          BIGINT         NOT NULL AUTO_INCREMENT,
    db_user           VARCHAR(100)   NOT NULL DEFAULT (CURRENT_USER()),
    operation         VARCHAR(10)    NOT NULL,
    table_name        VARCHAR(60)    NOT NULL,
    record_pk         VARCHAR(100)   NOT NULL,
    old_value         TEXT,
    new_value         TEXT,
    change_time       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (audit_id),
    CONSTRAINT chk_audit_op
        CHECK (operation IN ('INSERT','UPDATE','DELETE'))
) ENGINE=InnoDB;

SELECT 'Schema created successfully' AS status;


INSERT INTO Department (department_id, department_name, building, phone) VALUES
(1, 'Information Technology', 'Building A', '20395'),
(2, 'Computer Engineering',  'Building B', '20396'),
(3, 'Computer Science',  'Building C', '20394'),
(4, 'Cybersecurity',  'Building D', '20927'),
(5, 'Mechanical Engineering',  'Building E', '20456');

INSERT INTO Program (program_id, program_name, degree_level, department_id) VALUES
(1, 'BSc Information Technology',        'Bachelor', 1),
(2, 'MSc Information Technology',        'Master',   1),
(3, 'PhD Information Technology',        'PhD',      1),
(4, 'BSc Computer Engineering',        'Bachelor', 2),
(5, 'MSc Computer Engineering',        'Master',   2),
(6, 'BSc Computer Science',        'Bachelor', 3),
(7, 'MSc Computer Science',        'Master',   3),
(8, 'PhD Computer Science',        'PhD',      3),
(9, 'MSc Cybersecurity',  'Master', 4),
(10, 'MSc Mechanical Engineering',  'Master', 5);

INSERT INTO Faculty
(faculty_id, first_name, last_name, email, phone, hire_date, title, salary, department_id, mentor_id) VALUES
(1,  'Ahmed',   'Al-Farsi',    'alfarsi@qu.edu.sa',    '050-1001', '2010-09-01', 'Professor',           22000.00, 1, NULL),
(2,  'Sara',    'Hassan',      'hassan@qu.edu.sa',      '050-1002', '2013-01-15', 'Associate Professor', 18000.00, 1, 1),
(3,  'Omar',    'Khalid',      'khalid@uqu.edu.sa',      '050-1003', '2015-08-20', 'Assistant Professor', 14000.00, 1, 2),
(4,  'Lina',    'Nasser',      'lina@qu.edu.sa',      '050-1004', '2016-03-10', 'Assistant Professor', 14000.00, 1, 1),
(5,  'Yousef',  'Saleh',       'yousef@qu.edu.sa',     '050-1005', '2012-05-01', 'Professor',           21000.00, 2, NULL),
(6,  'Mona',    'Rahman',      'mona@qu.edu.sa',      '050-1006', '2017-09-01', 'Lecturer',            11000.00, 2, 5),
(7,  'Khaled',  'Othman',      'khaled@qu.edu.sa',    '050-1007', '2014-11-11', 'Associate Professor', 17500.00, 3, NULL),
(8,  'Huda',    'Mansour',     'mansour@qu.edu.sa',     '050-1008', '2018-02-01', 'Assistant Professor', 13500.00, 3, 7),
(9,  'Faisal',  'Ali',         'faisal@qu.edu.sa',       '050-1009', '2011-07-07', 'Professor',           23000.00, 4, NULL),
(10, 'Noura',   'Ibrahim',     'noura@qu.edu.sa',    '050-1010', '2019-10-01', 'Lecturer',            10500.00, 4, 9),
(11, 'Tariq',   'Mahmoud',     'mahmoud@qu.edu.sa',    '050-1011', '2016-06-15', 'Assistant Professor', 13800.00, 5, NULL),
(12, 'Reem',    'Yahya',       'yahya@qu.edu.sa',       '050-1012', '2020-01-10', 'Lecturer',            10800.00, 5, 11),
(13, 'Sami',    'Zaid',        'zaid@qu.edu.sa',        '050-1013', '2013-04-04', 'Associate Professor', 17200.00, 1, 1),
(14, 'Dina',    'Bakr',        'dina@qu.edu.sa',        '050-1014', '2017-12-12', 'Assistant Professor', 14200.00, 2, 5),
(15, 'Hassan',  'Farouk',      'farouk@qu.edu.sa',    '050-1015', '2019-03-03', 'Lecturer',            10900.00, 3, 7);

UPDATE Department SET head_faculty_id = 1 WHERE department_id = 1;
UPDATE Department SET head_faculty_id = 5 WHERE department_id = 2;
UPDATE Department SET head_faculty_id = 7 WHERE department_id = 3;
UPDATE Department SET head_faculty_id = 9 WHERE department_id = 4;
UPDATE Department SET head_faculty_id = 11 WHERE department_id = 5;


INSERT INTO Student
(student_id, first_name, last_name, email, phone, date_of_birth, enrollment_date, academic_status, program_id, supervisor_id) VALUES
(1,  'Shakil',     'Hossain',      '472118102@qu.edu.sa',     '055-2001', '2000-02-11', '2019-09-01', 'Active',    1, 1),
(2,  'Fatima',  'Saleh',      '425631523@qu.edu.sa',  '055-2002', '2001-03-22', '2020-09-01', 'Active',    1, 2),
(3,  'Mohammed','Hussain',    '47215364@qu.edu.sa',    '055-2003', '1999-07-15', '2018-09-01', 'Graduated', 1, 1),
(4,  'Aisha',   'Omar',       '485362154@qu.edu.sa',    '055-2004', '2002-01-09', '2021-09-01', 'Active',    1, 3),
(5,  'Saud',    'Nasser',     '423664125@qu.edu.sa',   '055-2005', '2000-11-30', '2019-09-01', 'Active',    2, 2),
(6,  'Maryam',  'Khalid',     '456321546@qu.edu.sa', '055-2006', '1998-05-19', '2018-09-01', 'Active',    2, 1),
(7,  'Abdullah','Rahman',     '48795412@qu.edu.sa',    '055-2007', '1997-08-25', '2017-09-01', 'Active',    3, 1),
(8,  'Layla',   'Faisal',     '456321456@qu.edu.sa',  '055-2008', '2001-12-14', '2020-09-01', 'Active',    3, 13),
(9,  'Nawaf',   'Sultan',     '463214535@qu.edu.sa',  '055-2009', '2000-04-08', '2019-09-01', 'Suspended', 1, 4),
(10, 'Hind',    'Majed',      '412546325@qu.edu.sa',    '055-2010', '2002-06-17', '2021-09-01', 'Active',    1, 2),
(11, 'Sultan',  'Turki',      '451235478@qu.edu.sa',  '055-2011', '1999-09-09', '2018-09-01', 'Graduated', 4, 5),
(12, 'Amal',    'Saad',       '412365423@qu.edu.sa',     '055-2012', '2001-10-21', '2020-09-01', 'Active',    4, 6),
(13, 'Fahad',   'Nayef',      '423654125@qu.edu.sa',   '055-2013', '2000-03-03', '2019-09-01', 'Active',    4, 5),
(14, 'Razan',   'Waleed',     '436541254@qu.edu.sa',  '055-2014', '2002-08-12', '2021-09-01', 'Active',    5, 14),
(15, 'Bader',   'Hamad',      '445874524@qu.edu.sa',   '055-2015', '1998-12-01', '2017-09-01', 'Active',    5, 5),
(16, 'Jawaher', 'Salem',      '465425834@qu.edu.sa', '055-2016', '2001-05-27', '2020-09-01', 'Active',    6, 7),
(17, 'Mansour', 'Ibrahim',    '475863254@qu.edu.sa',     '055-2017', '2000-07-04', '2019-09-01', 'Active',    6, 8),
(18, 'Ghada',   'Yousef',     '446354125@qu.edu.sa',  '055-2018', '2002-11-16', '2021-09-01', 'Active',    6, 7),
(19, 'Rakan',   'Fahad',      '465235415@qu.edu.sa',   '055-2019', '1999-01-23', '2018-09-01', 'Withdrawn', 6, 15),
(20, 'Shahad',  'Nawaf',      '425413546@qu.edu.sa',  '055-2020', '2001-09-05', '2020-09-01', 'Active',    7, 9),
(21, 'Talal',   'Hamza',      '445687452@qu.edu.sa',   '055-2021', '2000-06-30', '2019-09-01', 'Active',    7, 10),
(22, 'Wafa',    'Adel',       '489657243@qu.edu.sa',     '055-2022', '1998-02-18', '2018-09-01', 'Active',    7, 9),
(23, 'Ziyad',   'Mazen',      '469874536@qu.edu.sa',   '055-2023', '2001-04-11', '2020-09-01', 'Active',    8, 11),
(24, 'Asma',    'Rashed',     '425413658@qu.edu.sa',   '055-2024', '1997-10-07', '2017-09-01', 'Active',    8, 12),
(25, 'Saeed',   'Nabil',      '442548796@qu.edu.sa',   '055-2025', '2000-12-25', '2019-09-01', 'Active',    8, 11),
(26, 'Lama',    'Fouad',      '415789635@qu.edu.sa',    '055-2026', '2002-03-14', '2021-09-01', 'Active',    1, 4),
(27, 'Yara',    'Tariq',      '475236452@qu.edu.sa',    '055-2027', '2001-08-08', '2020-09-01', 'Active',    2, 3),
(28, 'Othman',  'Jamil',      '475863265@qu.edu.sa',  '055-2028', '1999-11-19', '2018-09-01', 'Active',    3, 13),
(29, 'Dalal',   'Khaled',     '425635412@qu.edu.sa',  '055-2029', '2002-01-02', '2021-09-01', 'Active',    4, 6),
(30, 'Nasser',  'Ayman',      '445698753@qu.edu.sa',  '055-2030', '2000-05-20', '2019-09-01', 'Active',    5, 14);


INSERT INTO ResearchProject
(project_id, project_title, start_date, end_date, status, department_id, lead_faculty_id) VALUES
(1,  'AI for Healthcare Diagnostics',          '2022-01-15', '2025-01-14', 'Active',    1, 1),
(2,  'Cybersecurity in IoT Networks',           '2021-06-01', '2024-05-31', 'Active',    1, 2),
(3,  'Natural Language Processing for Arabic',  '2023-02-01', NULL,         'Active',    1, 3),
(4,  'Renewable Energy Storage Systems',        '2021-09-01', '2024-08-31', 'Completed', 2, 5),
(5,  '5G Network Optimization',                 '2022-03-15', '2025-03-14', 'Active',    2, 6),
(6,  'Robotic Assembly Line Automation',        '2020-11-01', '2023-10-31', 'Completed', 3, 7),
(7,  'Advanced Materials for Aerospace',        '2022-07-01', '2025-06-30', 'Active',    3, 8),
(8,  'Computational Number Theory',             '2021-01-10', '2024-01-09', 'Active',    4, 9),
(9,  'Statistical Models for Climate Data',     '2023-03-01', NULL,         'Active',    4, 10),
(10, 'Quantum Computing Algorithms',            '2022-05-20', '2025-05-19', 'Active',    5, 11),
(11, 'Particle Physics Simulation',             '2021-08-15', '2024-08-14', 'Active',    5, 12),
(12, 'Machine Learning for Finance',            '2023-01-01', NULL,         'Proposed',  1, 13),
(13, 'Smart Grid Cybersecurity',                '2022-10-01', '2025-09-30', 'Active',    2, 14),
(14, 'Autonomous Vehicle Navigation',           '2021-04-01', '2024-03-31', 'Active',    3, 15),
(15, 'Astrophysics Data Mining',                '2023-06-01', NULL,         'Proposed',  5, 11);


INSERT INTO FacultyProject (faculty_id, project_id, supervision_role, start_date) VALUES
(1,  1,  'Principal Investigator', '2022-01-15'),
(2,  1,  'Co-Investigator',        '2022-01-15'),
(3,  1,  'Supervisor',             '2022-02-01'),
(2,  2,  'Principal Investigator', '2021-06-01'),
(4,  2,  'Co-Investigator',        '2021-06-01'),
(3,  3,  'Principal Investigator', '2023-02-01'),
(13, 3,  'Advisor',                '2023-02-01'),
(5,  4,  'Principal Investigator', '2021-09-01'),
(6,  4,  'Co-Investigator',        '2021-09-01'),
(6,  5,  'Principal Investigator', '2022-03-15'),
(14, 5,  'Co-Investigator',        '2022-03-15'),
(7,  6,  'Principal Investigator', '2020-11-01'),
(8,  6,  'Supervisor',             '2020-11-01'),
(8,  7,  'Principal Investigator', '2022-07-01'),
(15, 7,  'Co-Investigator',        '2022-07-01'),
(9,  8,  'Principal Investigator', '2021-01-10'),
(10, 8,  'Co-Investigator',        '2021-01-10'),
(10, 9,  'Principal Investigator', '2023-03-01'),
(9,  9,  'Advisor',                '2023-03-01'),
(11, 10, 'Principal Investigator', '2022-05-20'),
(12, 10, 'Co-Investigator',        '2022-05-20'),
(12, 11, 'Principal Investigator', '2021-08-15'),
(11, 11, 'Co-Investigator',        '2021-08-15'),
(13, 12, 'Principal Investigator', '2023-01-01'),
(14, 13, 'Principal Investigator', '2022-10-01'),
(6,  13, 'Co-Investigator',        '2022-10-01'),
(15, 14, 'Principal Investigator', '2021-04-01'),
(7,  14, 'Co-Investigator',        '2021-04-01'),
(11, 15, 'Principal Investigator', '2023-06-01');


INSERT INTO StudentProject
(student_id, project_id, project_role, contribution_percentage, join_date) VALUES
(1,  1,  'Lead Student', 40.00, '2022-01-20'),
(2,  1,  'Researcher',   30.00, '2022-02-01'),
(4,  1,  'Assistant',    20.00, '2022-03-01'),
(5,  2,  'Lead Student', 50.00, '2021-06-10'),
(6,  2,  'Researcher',   30.00, '2021-07-01'),
(7,  3,  'Lead Student', 60.00, '2023-02-10'),
(8,  3,  'Researcher',   40.00, '2023-03-01'),
(11, 4,  'Lead Student', 45.00, '2021-09-15'),
(12, 4,  'Researcher',   35.00, '2021-10-01'),
(14, 5,  'Lead Student', 55.00, '2022-03-20'),
(15, 5,  'Researcher',   45.00, '2022-04-01'),
(16, 6,  'Lead Student', 50.00, '2020-11-15'),
(17, 6,  'Researcher',   30.00, '2020-12-01'),
(18, 7,  'Lead Student', 60.00, '2022-07-10'),
(20, 8,  'Lead Student', 50.00, '2021-01-20'),
(21, 8,  'Researcher',   50.00, '2021-02-01'),
(22, 9,  'Lead Student', 60.00, '2023-03-10'),
(23, 10, 'Lead Student', 50.00, '2022-05-25'),
(24, 10, 'Researcher',   30.00, '2022-06-01'),
(25, 11, 'Lead Student', 55.00, '2021-08-20'),
(26, 12, 'Researcher',   100.00,'2023-01-15'),
(27, 13, 'Lead Student', 60.00, '2022-10-10'),
(28, 14, 'Lead Student', 50.00, '2021-04-10'),
(29, 14, 'Researcher',   50.00, '2021-05-01'),
(30, 15, 'Lead Student', 100.00,'2023-06-10'),
(1,  2,  'Researcher',   10.00, '2021-08-01'),
(5,  1,  'Researcher',   10.00, '2022-06-01'),
(7,  1,  'Assistant',    10.00, '2022-07-01'),
(11, 5,  'Researcher',   10.00, '2022-09-01'),
(16, 7,  'Researcher',   20.00, '2022-09-01');


INSERT INTO FundingSource (source_id, source_name, source_type, contact_email, country) VALUES
(1, 'Ministry of Higher Education',  'Government',    'grants@mhe.gov',         'Saudi Arabia'),
(2, 'National Science Foundation',   'Government',    'info@nsf.gov',           'USA'),
(3, 'TechCorp Industries',           'Industry',      'funding@techcorp.com',   'Saudi Arabia'),
(4, 'King Abdulaziz University Fund','University',    'fund@kau.edu.sa',        'Saudi Arabia'),
(5, 'Gates Foundation',              'Non-Profit',    'grants@gates.org',       'USA'),
(6, 'EU Horizon Program',            'International', 'horizon@eu.int',         'Belgium'),
(7, 'Saudi Aramco Research',         'Industry',      'research@aramco.com',    'Saudi Arabia'),
(8, 'UNESCO Research Fund',          'International', 'research@unesco.org',    'France');


INSERT INTO Funding (funding_id, project_id, source_id, funding_amount, funding_date) VALUES
(1,  1,  1, 500000.00, '2022-01-10'),
(2,  1,  3, 250000.00, '2022-03-15'),
(3,  2,  2, 400000.00, '2021-05-20'),
(4,  2,  7, 150000.00, '2021-08-01'),
(5,  3,  1, 300000.00, '2023-01-20'),
(6,  4,  6, 600000.00, '2021-08-15'),
(7,  5,  3, 350000.00, '2022-03-01'),
(8,  6,  7, 450000.00, '2020-10-15'),
(9,  7,  2, 380000.00, '2022-06-20'),
(10, 8,  4, 200000.00, '2021-01-05'),
(11, 9,  5, 180000.00, '2023-02-15'),
(12, 10, 6, 700000.00, '2022-05-10'),
(13, 11, 8, 320000.00, '2021-08-01'),
(14, 13, 3, 280000.00, '2022-09-15'),
(15, 14, 7, 410000.00, '2021-03-20'),
(16, 12, 1, 100000.00, '2023-01-05'),
(17, 15, 2,  75000.00, '2023-05-25');


INSERT INTO Publication (publication_id, title, publication_type, publication_year, doi, journal_name) VALUES
(1,  'Deep Learning for Medical Image Analysis',        'Journal',      2023, '10.1000/pub001', 'IEEE Transactions on Medical Imaging'),
(2,  'IoT Security Challenges and Solutions',           'Journal',      2022, '10.1000/pub002', 'Journal of Cybersecurity'),
(3,  'Arabic NLP: A Survey',                            'Journal',      2023, '10.1000/pub003', 'ACM Computing Surveys'),
(4,  'Battery Storage for Renewable Energy',            'Journal',      2022, '10.1000/pub004', 'Renewable Energy Journal'),
(5,  '5G Network Slicing Optimization',                 'Conference',   2023, '10.1000/pub005', NULL),
(6,  'Robotic Automation in Manufacturing',             'Journal',      2021, '10.1000/pub006', 'Robotics and Automation Letters'),
(7,  'Advanced Alloys for Aerospace',                   'Journal',      2023, '10.1000/pub007', 'Materials Science Journal'),
(8,  'Prime Distribution Algorithms',                   'Journal',      2022, '10.1000/pub008', 'Journal of Number Theory'),
(9,  'Climate Data Statistical Analysis',               'Journal',      2023, '10.1000/pub009', 'Climate Statistics'),
(10, 'Quantum Algorithm Design',                        'Journal',      2023, '10.1000/pub010', 'Quantum Information Processing'),
(11, 'Particle Simulation Techniques',                  'Conference',   2022, '10.1000/pub011', NULL),
(12, 'ML for Stock Prediction',                         'Journal',      2023, '10.1000/pub012', 'Financial ML Journal'),
(13, 'Smart Grid Intrusion Detection',                  'Conference',   2023, '10.1000/pub013', NULL),
(14, 'Autonomous Navigation Systems',                   'Journal',      2022, '10.1000/pub014', 'IEEE Robotics'),
(15, 'Astrophysics Data Mining Techniques',             'Journal',      2023, '10.1000/pub015', 'Astroinformatics'),
(16, 'Federated Learning for Healthcare',               'Conference',   2023, '10.1000/pub016', NULL),
(17, 'Blockchain for Supply Chain',                     'Journal',      2022, '10.1000/pub017', 'Blockchain Journal'),
(18, 'Edge Computing for IoT',                          'Journal',      2023, '10.1000/pub018', 'Edge Computing Review'),
(19, 'Sentiment Analysis in Arabic Tweets',             'Conference',   2022, '10.1000/pub019', NULL),
(20, 'Solar Panel Efficiency Optimization',             'Journal',      2021, '10.1000/pub020', 'Solar Energy'),
(21, 'Deep Reinforcement Learning for Games',           'Journal',      2023, '10.1000/pub021', 'AI Journal'),
(22, 'Privacy-Preserving Data Mining',                  'Conference',   2023, '10.1000/pub022', NULL),
(23, 'Wireless Sensor Network Protocols',               'Journal',      2022, '10.1000/pub023', 'Sensor Networks'),
(24, 'Graph Neural Networks for Chemistry',             'Journal',      2023, '10.1000/pub024', 'Chemical Informatics'),
(25, 'Fault-Tolerant Distributed Systems',              'Conference',   2022, '10.1000/pub025', NULL);


INSERT INTO PublicationAuthor (publication_id, faculty_id, author_order, is_corresponding) VALUES
(1,  1, 1, TRUE),  (1, 2, 2, FALSE), (1, 3, 3, FALSE),
(2,  2, 1, TRUE),  (2, 4, 2, FALSE),
(3,  3, 1, TRUE),  (3, 13, 2, FALSE),
(4,  5, 1, TRUE),  (4, 6, 2, FALSE),
(5,  6, 1, TRUE),  (5, 14, 2, FALSE),
(6,  7, 1, TRUE),  (6, 8, 2, FALSE),
(7,  8, 1, TRUE),  (7, 15, 2, FALSE),
(8,  9, 1, TRUE),  (8, 10, 2, FALSE),
(9,  10, 1, TRUE), (9, 9, 2, FALSE),
(10, 11, 1, TRUE), (10, 12, 2, FALSE),
(11, 12, 1, TRUE), (11, 11, 2, FALSE),
(12, 13, 1, TRUE), (12, 1, 2, FALSE),
(13, 14, 1, TRUE), (13, 6, 2, FALSE),
(14, 15, 1, TRUE), (14, 7, 2, FALSE),
(15, 11, 1, TRUE), (15, 12, 2, FALSE),
(16, 1, 1, TRUE),  (16, 2, 2, FALSE), (16, 4, 3, FALSE), (16, 13, 4, FALSE),
(17, 13, 1, TRUE), (17, 3, 2, FALSE),
(18, 4, 1, TRUE),  (18, 2, 2, FALSE), (18, 6, 3, FALSE), (18, 14, 4, FALSE),
(19, 3, 1, TRUE),  (19, 13, 2, FALSE),
(20, 5, 1, TRUE),  (20, 6, 2, FALSE),
(21, 1, 1, TRUE),  (21, 3, 2, FALSE), (21, 13, 3, FALSE), (21, 4, 4, FALSE),
(22, 2, 1, TRUE),  (22, 14, 2, FALSE),
(23, 6, 1, TRUE),  (23, 14, 2, FALSE), (23, 5, 3, FALSE), (23, 4, 4, FALSE),
(24, 8, 1, TRUE),  (24, 7, 2, FALSE),
(25, 12, 1, TRUE), (25, 11, 2, FALSE), (25, 10, 3, FALSE);


INSERT INTO Conference (conference_id, conference_name, location, conference_date, submission_deadline) VALUES
(1, 'IEEE International Conference on AI',        'Riyadh, Saudi Arabia', '2023-12-15', '2023-09-01'),
(2, 'ACM SIGCOMM',                                'New York, USA',        '2023-08-20', '2023-04-15'),
(3, 'International Conference on NLP',            'Dubai, UAE',           '2023-11-10', '2023-07-01'),
(4, 'IEEE Power Engineering Conference',          'Berlin, Germany',      '2023-06-05', '2023-02-01'),
(5, 'ACM Conference on Robotics',                 'Tokyo, Japan',         '2023-10-25', '2023-06-15'),
(6, 'International Cybersecurity Symposium',      'London, UK',           '2023-09-12', '2023-05-01'),
(7, 'World Quantum Computing Summit',             'Geneva, Switzerland',  '2023-07-18', '2023-03-15'),
(8, 'International Data Mining Conference',       'Paris, France',        '2023-05-22', '2023-01-20');


INSERT INTO Submission (submission_id, publication_id, conference_id, submission_date, decision, decision_date) VALUES
(1,  5,  2, '2023-04-10', 'Accepted', '2023-06-15'),
(2,  11, 7, '2023-03-10', 'Accepted', '2023-05-20'),
(3,  13, 6, '2023-05-05', 'Accepted', '2023-07-01'),
(4,  16, 1, '2023-08-25', 'Accepted', '2023-10-20'),
(5,  19, 3, '2023-06-20', 'Revision', '2023-08-15'),
(6,  22, 8, '2023-01-10', 'Accepted', '2023-03-25'),
(7,  25, 2, '2023-04-05', 'Accepted', '2023-06-10'),
(8,  17, 6, '2023-05-15', 'Rejected', '2023-07-05'),
(9,  18, 2, '2023-04-20', 'Accepted', '2023-06-20'),
(10, 21, 1, '2023-08-30', 'Accepted', '2023-10-25'),
(11, 24, 5, '2023-06-10', 'Revision', '2023-08-01'),
(12, 14, 5, '2023-06-12', 'Accepted', '2023-08-05'),
(13, 20, 4, '2023-01-25', 'Accepted', '2023-03-30'),
(14, 15, 8, '2023-01-15', 'Pending',  NULL),
(15, 23, 6, '2023-05-10', 'Accepted', '2023-07-15'),
(16, 12, 1, '2023-08-28', 'Revision', '2023-10-15'),
(17, 1,  8, '2023-01-18', 'Accepted', '2023-03-20'),
(18, 9,  8, '2023-01-22', 'Accepted', '2023-03-28'),
(19, 10, 7, '2023-03-20', 'Accepted', '2023-05-25'),
(20, 3,  3, '2023-06-25', 'Accepted', '2023-08-20');


INSERT INTO Review (review_id, submission_id, reviewer_faculty_id, reviewer_name, review_score, review_comments, review_date) VALUES
(1,  1,  1,    NULL,              8.5, 'Strong contribution, well written.',           '2023-05-01'),
(2,  1,  3,    NULL,              7.5, 'Good but needs more experiments.',             '2023-05-02'),
(3,  1,  NULL, 'Dr. External A',  8.0, 'Solid work.',                                  '2023-05-03'),
(4,  2,  11,   NULL,              9.0, 'Excellent paper.',                             '2023-04-01'),
(5,  2,  12,   NULL,              8.5, 'Minor revisions recommended.',                 '2023-04-02'),
(6,  3,  14,   NULL,              7.0, 'Needs clearer motivation.',                    '2023-06-01'),
(7,  3,  NULL, 'Dr. External B',  8.0, 'Good contribution.',                           '2023-06-02'),
(8,  4,  1,    NULL,              8.5, 'Well structured.',                             '2023-09-15'),
(9,  4,  2,    NULL,              9.0, 'Excellent.',                                   '2023-09-16'),
(10, 4,  4,    NULL,              8.0, 'Accept with minor changes.',                   '2023-09-17'),
(11, 5,  3,    NULL,              6.5, 'Needs more data.',                             '2023-07-10'),
(12, 5,  13,   NULL,              7.0, 'Moderate contribution.',                       '2023-07-11'),
(13, 6,  2,    NULL,              8.0, 'Interesting approach.',                        '2023-02-05'),
(14, 6,  14,   NULL,              7.5, 'Good.',                                        '2023-02-06'),
(15, 7,  12,   NULL,              8.5, 'Solid systems work.',                          '2023-05-01'),
(16, 7,  11,   NULL,              8.0, 'Well evaluated.',                              '2023-05-02'),
(17, 8,  13,   NULL,              5.0, 'Limited novelty.',                             '2023-06-01'),
(18, 8,  NULL, 'Dr. External C',  5.5, 'Reject.',                                      '2023-06-02'),
(19, 9,  4,    NULL,              8.5, 'Good contribution.',                           '2023-05-05'),
(20, 9,  6,    NULL,              8.0, 'Accept.',                                      '2023-05-06'),
(21, 10, 1,    NULL,              9.0, 'Excellent.',                                   '2023-09-20'),
(22, 10, 3,    NULL,              8.5, 'Strong.',                                      '2023-09-21'),
(23, 11, 8,    NULL,              7.0, 'Minor revision.',                              '2023-07-01'),
(24, 11, 7,    NULL,              7.5, 'Good.',                                        '2023-07-02'),
(25, 12, 15,   NULL,              8.0, 'Accept.',                                      '2023-07-05'),
(26, 13, 5,    NULL,              8.5, 'Good paper.',                                  '2023-02-20'),
(27, 14, 11,   NULL,              7.0, 'Pending decision.',                            '2023-03-01'),
(28, 15, 6,    NULL,              8.5, 'Accept.',                                      '2023-06-01'),
(29, 16, 13,   NULL,              6.0, 'Needs revision.',                              '2023-09-10'),
(30, 17, 9,    NULL,              9.0, 'Excellent.',                                   '2023-02-15');


INSERT INTO Revision (revision_id, submission_id, revision_number, revision_date, revision_notes) VALUES
(1,  5,  1, '2023-07-15', 'Added more experimental results.'),
(2,  5,  2, '2023-08-10', 'Improved clarity and fixed typos.'),
(3,  11, 1, '2023-07-05', 'Expanded related work section.'),
(4,  11, 2, '2023-07-28', 'Added comparison with baseline.'),
(5,  16, 1, '2023-09-20', 'Improved methodology description.'),
(6,  16, 2, '2023-10-05', 'Added more datasets.'),
(7,  1,  1, '2023-05-20', 'Addressed reviewer 2 comments.'),
(8,  2,  1, '2023-04-15', 'Minor formatting fixes.'),
(9,  3,  1, '2023-06-15', 'Clarified motivation.'),
(10, 4,  1, '2023-09-25', 'Added ablation study.'),
(11, 6,  1, '2023-02-15', 'Improved figures.'),
(12, 7,  1, '2023-05-10', 'Added more baselines.'),
(13, 9,  1, '2023-05-15', 'Fixed references.'),
(14, 10, 1, '2023-09-30', 'Minor edits.'),
(15, 12, 1, '2023-07-15', 'Added results table.'),
(16, 13, 1, '2023-03-01', 'Improved abstract.'),
(17, 15, 1, '2023-06-10', 'Added discussion.'),
(18, 17, 1, '2023-02-25', 'Fixed typos.'),
(19, 18, 1, '2023-02-28', 'Improved conclusion.'),
(20, 20, 1, '2023-07-01', 'Added limitations section.');


INSERT INTO Equipment (equipment_id, equipment_name, serial_number, purchase_date, condition_status, department_id) VALUES
(1,  'GPU Server NVIDIA A100',      'SN-GPU-001', '2022-01-10', 'Good',           1),
(2,  'High-Performance Cluster',    'SN-HPC-002', '2021-06-15', 'Good',           1),
(3,  'Network Analyzer',            'SN-NET-003', '2020-03-20', 'Fair',           2),
(4,  'Oscilloscope 500MHz',         'SN-OSC-004', '2019-08-01', 'Good',           2),
(5,  '3D Printer Industrial',       'SN-3DP-005', '2021-11-11', 'Good',           3),
(6,  'CNC Milling Machine',         'SN-CNC-006', '2018-05-05', 'Fair',           3),
(7,  'MATLAB Workstation',          'SN-MAT-007', '2022-02-28', 'Good',           4),
(8,  'Statistical Computing Server','SN-STA-008', '2021-09-09', 'Good',           4),
(9,  'Particle Detector',           'SN-PAR-009', '2020-12-12', 'Poor',           5),
(10, 'Spectrometer',                'SN-SPE-010', '2022-07-07', 'Good',           5);


INSERT INTO EquipmentUsage (equipment_id, project_id, usage_date, usage_purpose) VALUES
(1,  1,  '2022-02-01', 'Training deep learning models'),
(1,  1,  '2022-05-10', 'Model evaluation'),
(1,  3,  '2023-03-01', 'NLP model training'),
(2,  2,  '2021-07-01', 'Security simulations'),
(2,  10, '2022-06-01', 'Quantum simulations'),
(3,  2,  '2021-08-15', 'Network traffic analysis'),
(4,  5,  '2022-04-01', '5G signal measurement'),
(5,  6,  '2021-01-10', 'Prototype printing'),
(5,  7,  '2022-08-01', 'Material sample printing'),
(6,  6,  '2021-03-01', 'Component machining'),
(7,  8,  '2021-02-01', 'Number theory computations'),
(7,  9,  '2023-04-01', 'Climate data analysis'),
(8,  9,  '2023-05-01', 'Statistical modeling'),
(9,  11, '2021-09-01', 'Particle detection experiments'),
(10, 11, '2021-10-01', 'Spectral analysis'),
(10, 15, '2023-07-01', 'Astrophysics measurements'),
(1,  12, '2023-02-01', 'Financial ML training'),
(2,  13, '2022-11-01', 'Smart grid simulation'),
(5,  14, '2021-05-01', 'Autonomous vehicle parts'),
(7,  5,  '2022-06-01', 'Network optimization modeling');


SELECT 'Departments'        AS table_name, COUNT(*) AS row_count FROM Department
UNION ALL SELECT 'Programs',          COUNT(*) FROM Program
UNION ALL SELECT 'Students',          COUNT(*) FROM Student
UNION ALL SELECT 'Faculty',           COUNT(*) FROM Faculty
UNION ALL SELECT 'Research Projects', COUNT(*) FROM ResearchProject
UNION ALL SELECT 'Funding Sources',   COUNT(*) FROM FundingSource
UNION ALL SELECT 'Funding Records',   COUNT(*) FROM Funding
UNION ALL SELECT 'Publications',      COUNT(*) FROM Publication
UNION ALL SELECT 'Publication Authors', COUNT(*) FROM PublicationAuthor
UNION ALL SELECT 'Conferences',       COUNT(*) FROM Conference
UNION ALL SELECT 'Submissions',       COUNT(*) FROM Submission
UNION ALL SELECT 'Reviews',           COUNT(*) FROM Review
UNION ALL SELECT 'Revisions',         COUNT(*) FROM Revision
UNION ALL SELECT 'Equipment',         COUNT(*) FROM Equipment
UNION ALL SELECT 'Equipment Usage',   COUNT(*) FROM EquipmentUsage
UNION ALL SELECT 'Faculty-Project',   COUNT(*) FROM FacultyProject
UNION ALL SELECT 'Student-Project',   COUNT(*) FROM StudentProject;



SELECT s.student_id,
       CONCAT(s.first_name,' ',s.last_name) AS student_name,
       p.program_name,
       p.degree_level,
       d.department_name
FROM Student s
JOIN Program p    ON s.program_id = p.program_id
JOIN Department d ON p.department_id = d.department_id
ORDER BY d.department_name, p.program_name, s.last_name;



SELECT s.student_id,
       CONCAT(s.first_name,' ',s.last_name) AS student_name,
       CONCAT(f.first_name,' ',f.last_name) AS supervisor_name,
       f.title,
       f.email
FROM Student s
LEFT JOIN Faculty f ON s.supervisor_id = f.faculty_id
ORDER BY supervisor_name, student_name;



SELECT f.faculty_id,
       CONCAT(f.first_name,' ',f.last_name) AS faculty_name,
       COUNT(s.student_id) AS num_students
FROM Faculty f
JOIN Student s ON s.supervisor_id = f.faculty_id
GROUP BY f.faculty_id, f.first_name, f.last_name
HAVING COUNT(s.student_id) > 2
ORDER BY num_students DESC;



SELECT rp.project_id,
       rp.project_title,
       COUNT(sp.student_id) AS num_students
FROM ResearchProject rp
JOIN StudentProject sp ON rp.project_id = sp.project_id
GROUP BY rp.project_id, rp.project_title
HAVING COUNT(sp.student_id) > 3
ORDER BY num_students DESC;



SELECT rp.project_id,
       rp.project_title,
       SUM(f.funding_amount) AS total_funding
FROM ResearchProject rp
JOIN Funding f ON rp.project_id = f.project_id
GROUP BY rp.project_id, rp.project_title
HAVING SUM(f.funding_amount) > 500000
ORDER BY total_funding DESC;



SELECT s.student_id,
       CONCAT(s.first_name,' ',s.last_name) AS student_name,
       COUNT(sp.project_id) AS num_projects
FROM Student s
JOIN StudentProject sp ON s.student_id = sp.student_id
GROUP BY s.student_id, s.first_name, s.last_name
HAVING COUNT(sp.project_id) > 1
ORDER BY num_projects DESC;



SELECT DISTINCT f.faculty_id,
       CONCAT(f.first_name,' ',f.last_name) AS faculty_name
FROM Faculty f
JOIN PublicationAuthor pa ON f.faculty_id = pa.faculty_id
ORDER BY faculty_name;



SELECT p.publication_id,
       p.title,
       COUNT(pa.faculty_id) AS num_authors
FROM Publication p
JOIN PublicationAuthor pa ON p.publication_id = pa.publication_id
GROUP BY p.publication_id, p.title
HAVING COUNT(pa.faculty_id) > 3
ORDER BY num_authors DESC;



SELECT p.publication_id,
       p.title,
       p.publication_year,
       CONCAT(f.first_name,' ',f.last_name) AS corresponding_author
FROM Publication p
JOIN PublicationAuthor pa ON p.publication_id = pa.publication_id
JOIN Faculty f            ON pa.faculty_id = f.faculty_id
WHERE pa.is_corresponding = TRUE
  AND f.faculty_id = 1
ORDER BY p.publication_year DESC;



SELECT c.conference_id,
       c.conference_name,
       COUNT(s.submission_id) AS num_submissions
FROM Conference c
JOIN Submission s ON c.conference_id = s.conference_id
GROUP BY c.conference_id, c.conference_name
HAVING COUNT(s.submission_id) > 2
ORDER BY num_submissions DESC;



SELECT s.submission_id,
       p.title,
       c.conference_name,
       s.decision,
       s.decision_date
FROM Submission s
JOIN Publication p ON s.publication_id = p.publication_id
JOIN Conference c  ON s.conference_id  = c.conference_id
WHERE s.decision = 'Accepted'
ORDER BY s.decision_date DESC;



SELECT s.student_id,
       CONCAT(s.first_name,' ',s.last_name) AS student_name,
       p.program_name
FROM Student s
JOIN Program p ON s.program_id = p.program_id
WHERE NOT EXISTS (
    SELECT 1
    FROM StudentProject sp
    WHERE sp.student_id = s.student_id
)
ORDER BY s.student_id;



SELECT f.faculty_id,
       CONCAT(f.first_name,' ',f.last_name) AS faculty_name,
       f.title
FROM Faculty f
WHERE NOT EXISTS (
    SELECT 1
    FROM Student s
    WHERE s.supervisor_id = f.faculty_id
)
ORDER BY f.faculty_id;



SELECT DISTINCT rp.project_id,
       rp.project_title,
       e.equipment_name
FROM ResearchProject rp
JOIN EquipmentUsage eu ON rp.project_id = eu.project_id
JOIN Equipment e       ON eu.equipment_id = e.equipment_id
WHERE e.equipment_id = 1
ORDER BY rp.project_id;



SELECT DISTINCT
       m.faculty_id   AS mentor_id,
       CONCAT(m.first_name,' ',m.last_name) AS mentor_name,
       CONCAT(mt.first_name,' ',mt.last_name) AS mentee_name
FROM Faculty m
JOIN Faculty mt ON mt.mentor_id = m.faculty_id
ORDER BY mentor_name, mentee_name;



SELECT f.faculty_id,
       CONCAT(f.first_name,' ',f.last_name) AS faculty_name,
       f.title
FROM Faculty f
WHERE f.mentor_id IS NULL
ORDER BY f.faculty_id;



SELECT rp.project_id,
       rp.project_title,
       (SELECT SUM(f.funding_amount)
        FROM Funding f
        WHERE f.project_id = rp.project_id) AS total_funding
FROM ResearchProject rp
WHERE (SELECT SUM(f.funding_amount)
       FROM Funding f
       WHERE f.project_id = rp.project_id) = (
           SELECT MAX(proj_total)
           FROM (SELECT SUM(funding_amount) AS proj_total
                 FROM Funding
                 GROUP BY project_id) AS totals
       );


SELECT rp.project_id,
       rp.project_title,
       SUM(f.funding_amount) AS total_funding
FROM ResearchProject rp
JOIN Funding f ON rp.project_id = f.project_id
GROUP BY rp.project_id, rp.project_title
ORDER BY total_funding DESC
LIMIT 1;



SELECT f.faculty_id,
       CONCAT(f.first_name,' ',f.last_name) AS author_name,
       COUNT(pa.publication_id) AS num_publications
FROM Faculty f
JOIN PublicationAuthor pa ON f.faculty_id = pa.faculty_id
GROUP BY f.faculty_id, f.first_name, f.last_name
HAVING COUNT(pa.publication_id) = (
    SELECT MAX(pub_count)
    FROM (SELECT COUNT(publication_id) AS pub_count
          FROM PublicationAuthor
          GROUP BY faculty_id) AS counts
)
ORDER BY author_name;



SELECT d.department_id,
       d.department_name,
       COUNT(rp.project_id) AS num_projects
FROM Department d
JOIN ResearchProject rp ON d.department_id = rp.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(rp.project_id) = (
    SELECT MAX(proj_count)
    FROM (SELECT COUNT(project_id) AS proj_count
          FROM ResearchProject
          GROUP BY department_id) AS counts
);



SELECT rp.project_id,
       rp.project_title,
       COUNT(sp.student_id) AS num_students,
       ROUND(AVG(sp.contribution_percentage), 2) AS avg_contribution
FROM ResearchProject rp
JOIN StudentProject sp ON rp.project_id = sp.project_id
GROUP BY rp.project_id, rp.project_title
ORDER BY avg_contribution DESC;



CREATE OR REPLACE VIEW vw_StudentResearchProfile AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name)        AS student_name,
    s.email,
    p.program_name,
    p.degree_level,
    d.department_name,
    CONCAT(f.first_name, ' ', f.last_name)        AS supervisor_name,
    f.title                                       AS supervisor_title,
    COUNT(DISTINCT sp.project_id)                 AS num_projects,
    COALESCE(SUM(sp.contribution_percentage), 0)  AS total_contribution,
    GROUP_CONCAT(DISTINCT rp.project_title
                 ORDER BY rp.project_title
                 SEPARATOR '; ')                  AS project_titles
FROM Student s
JOIN Program p        ON s.program_id    = p.program_id
JOIN Department d     ON p.department_id = d.department_id
LEFT JOIN Faculty f   ON s.supervisor_id = f.faculty_id
LEFT JOIN StudentProject sp ON s.student_id = sp.student_id
LEFT JOIN ResearchProject rp ON sp.project_id = rp.project_id
GROUP BY s.student_id, s.first_name, s.last_name, s.email,
         p.program_name, p.degree_level, d.department_name,
         f.first_name, f.last_name, f.title;



CREATE OR REPLACE VIEW vw_FacultyResearchProfile AS
SELECT
    f.faculty_id,
    CONCAT(f.first_name, ' ', f.last_name)  AS faculty_name,
    f.title,
    f.email,
    d.department_name,
    (SELECT COUNT(*) FROM Student s
     WHERE s.supervisor_id = f.faculty_id)   AS num_supervised_students,
    (SELECT COUNT(*) FROM FacultyProject fp
     WHERE fp.faculty_id = f.faculty_id)     AS num_projects,
    (SELECT COUNT(*) FROM PublicationAuthor pa
     WHERE pa.faculty_id = f.faculty_id)     AS num_publications,
    (SELECT COUNT(*) FROM PublicationAuthor pa
     WHERE pa.faculty_id = f.faculty_id
       AND pa.is_corresponding = TRUE)       AS num_corresponding_pubs,
    (SELECT COALESCE(SUM(fu.funding_amount), 0)
     FROM Funding fu
     JOIN FacultyProject fp ON fu.project_id = fp.project_id
     WHERE fp.faculty_id = f.faculty_id)     AS total_funding_attributed,
    CONCAT(m.first_name, ' ', m.last_name)   AS mentor_name
FROM Faculty f
JOIN Department d   ON f.department_id = d.department_id
LEFT JOIN Faculty m ON f.mentor_id = m.faculty_id;


CREATE OR REPLACE VIEW vw_ProjectFundingSummary AS
SELECT
    rp.project_id,
    rp.project_title,
    rp.status,
    d.department_name,
    CONCAT(f.first_name, ' ', f.last_name)   AS lead_faculty,
    COUNT(DISTINCT fu.funding_id)             AS num_funding_records,
    COUNT(DISTINCT fu.source_id)              AS num_funding_sources,
    COALESCE(SUM(fu.funding_amount), 0)       AS total_funding,
    MIN(fu.funding_date)                      AS first_funding_date,
    MAX(fu.funding_date)                      AS last_funding_date
FROM ResearchProject rp
JOIN Department d          ON rp.department_id = d.department_id
LEFT JOIN Faculty f        ON rp.lead_faculty_id = f.faculty_id
LEFT JOIN Funding fu       ON rp.project_id = fu.project_id
GROUP BY rp.project_id, rp.project_title, rp.status,
         d.department_name, f.first_name, f.last_name;



CREATE OR REPLACE VIEW vw_PublicationAuthorSummary AS
SELECT
    p.publication_id,
    p.title,
    p.publication_type,
    p.publication_year,
    p.journal_name,
    GROUP_CONCAT(
        CONCAT(f.first_name, ' ', f.last_name,
               CASE WHEN pa.is_corresponding THEN ' (*)' ELSE '' END)
        ORDER BY pa.author_order
        SEPARATOR ', '
    )                                          AS author_list,
    MAX(CASE WHEN pa.is_corresponding
             THEN CONCAT(f.first_name,' ',f.last_name) END) AS corresponding_author,
    COUNT(pa.faculty_id)                       AS num_authors
FROM Publication p
JOIN PublicationAuthor pa ON p.publication_id = pa.publication_id
JOIN Faculty f            ON pa.faculty_id = f.faculty_id
GROUP BY p.publication_id, p.title, p.publication_type,
         p.publication_year, p.journal_name;





CREATE OR REPLACE VIEW vw_StudentOwnProfile AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    s.enrollment_date,
    s.academic_status,
    p.program_name,
    p.degree_level,
    d.department_name,
    CONCAT(f.first_name, ' ', f.last_name) AS supervisor_name
FROM Student s
JOIN Program p      ON s.program_id = p.program_id
JOIN Department d   ON p.department_id = d.department_id
LEFT JOIN Faculty f ON s.supervisor_id = f.faculty_id
WHERE s.student_id = CAST(
        SUBSTRING_INDEX(CURRENT_USER(), 'stu_', -1) AS UNSIGNED
      );




CREATE OR REPLACE VIEW vw_FacultyOwnProfile AS
SELECT
    f.faculty_id,
    CONCAT(f.first_name, ' ', f.last_name) AS faculty_name,
    f.title,
    f.email,
    d.department_name,
    (SELECT COUNT(*) FROM FacultyProject fp
     WHERE fp.faculty_id = f.faculty_id)    AS num_projects,
    (SELECT COUNT(*) FROM PublicationAuthor pa
     WHERE pa.faculty_id = f.faculty_id)    AS num_publications,
    (SELECT COUNT(*) FROM Student s
     WHERE s.supervisor_id = f.faculty_id)  AS num_supervised_students,
    CONCAT(m.first_name, ' ', m.last_name)  AS mentor_name
FROM Faculty f
JOIN Department d   ON f.department_id = d.department_id
LEFT JOIN Faculty m ON f.mentor_id = m.faculty_id
WHERE f.faculty_id = CAST(
        SUBSTRING_INDEX(CURRENT_USER(), 'fac_', -1) AS UNSIGNED
      );




CREATE OR REPLACE VIEW vw_ConferenceSubmissionStatus AS
SELECT
    c.conference_id,
    c.conference_name,
    c.location,
    c.conference_date,
    COUNT(s.submission_id)                                        AS total_submissions,
    SUM(CASE WHEN s.decision = 'Accepted' THEN 1 ELSE 0 END)      AS accepted,
    SUM(CASE WHEN s.decision = 'Rejected' THEN 1 ELSE 0 END)      AS rejected,
    SUM(CASE WHEN s.decision = 'Revision' THEN 1 ELSE 0 END)      AS under_revision,
    SUM(CASE WHEN s.decision = 'Pending'  THEN 1 ELSE 0 END)      AS pending,
    ROUND(
        100.0 * SUM(CASE WHEN s.decision = 'Accepted' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(s.submission_id), 0), 2
    )                                                             AS acceptance_rate_pct
FROM Conference c
LEFT JOIN Submission s ON c.conference_id = s.conference_id
GROUP BY c.conference_id, c.conference_name, c.location, c.conference_date;

SELECT 'Views created' AS status;
SHOW FULL TABLES WHERE Table_type = 'VIEW';

SELECT * FROM vw_StudentResearchProfile ORDER BY num_projects DESC LIMIT 10;
SELECT * FROM vw_FacultyResearchProfile ORDER BY num_publications DESC LIMIT 10;
SELECT * FROM vw_ProjectFundingSummary ORDER BY total_funding DESC LIMIT 10;
SELECT * FROM vw_PublicationAuthorSummary ORDER BY num_authors DESC LIMIT 10;
SELECT * FROM vw_ConferenceSubmissionStatus ORDER BY total_submissions DESC;



DELIMITER $$
CREATE PROCEDURE sp_AddResearchProject (
    IN  p_project_id       INT,
    IN  p_project_title    VARCHAR(200),
    IN  p_start_date       DATE,
    IN  p_end_date         DATE,
    IN  p_status           VARCHAR(20),
    IN  p_department_id    INT,
    IN  p_lead_faculty_id  INT,
    OUT p_result_message   VARCHAR(255)
)
proc_body: BEGIN
    DECLARE v_dept_exists     INT DEFAULT 0;
    DECLARE v_faculty_exists  INT DEFAULT 0;
    DECLARE v_faculty_dept    INT DEFAULT NULL;

    IF p_project_id IS NULL OR p_project_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'project_id must be a positive integer.';
    END IF;

    IF p_project_title IS NULL OR TRIM(p_project_title) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'project_title cannot be empty.';
    END IF;

    IF p_start_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'start_date is required.';
    END IF;

    IF p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'end_date cannot be earlier than start_date.';
    END IF;

    IF p_status NOT IN ('Proposed','Active','Completed','Cancelled') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'status must be Proposed, Active, Completed, or Cancelled.';
    END IF;

    SELECT COUNT(*) INTO v_dept_exists
    FROM Department WHERE department_id = p_department_id;

    IF v_dept_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Department does not exist.';
    END IF;

    IF p_lead_faculty_id IS NOT NULL THEN
        SELECT COUNT(*), MAX(department_id)
          INTO v_faculty_exists, v_faculty_dept
        FROM Faculty WHERE faculty_id = p_lead_faculty_id;

        IF v_faculty_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lead faculty does not exist.';
        END IF;

        IF v_faculty_dept <> p_department_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Lead faculty must belong to the project department.';
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM ResearchProject WHERE project_id = p_project_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A project with this project_id already exists.';
    END IF;

    INSERT INTO ResearchProject
        (project_id, project_title, start_date, end_date,
         status, department_id, lead_faculty_id)
    VALUES
        (p_project_id, p_project_title, p_start_date, p_end_date,
         p_status, p_department_id, p_lead_faculty_id);

    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('INSERT', 'ResearchProject', CAST(p_project_id AS CHAR),
            NULL, CONCAT('title=', p_project_title, '; status=', p_status));

    SET p_result_message = CONCAT('Project ', p_project_id, ' created successfully.');

END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_RegisterStudentInProject (
    IN  p_student_id       INT,
    IN  p_project_id       INT,
    IN  p_project_role     VARCHAR(50),
    IN  p_contribution_pct DECIMAL(5,2),
    OUT p_result_message   VARCHAR(255)
)
proc_body: BEGIN
    DECLARE v_student_exists  INT DEFAULT 0;
    DECLARE v_project_exists  INT DEFAULT 0;
    DECLARE v_already_reg     INT DEFAULT 0;
    DECLARE v_current_total   DECIMAL(10,2) DEFAULT 0;

    IF p_student_id IS NULL OR p_project_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'student_id and project_id are required.';
    END IF;

    IF p_contribution_pct IS NULL
       OR p_contribution_pct < 0
       OR p_contribution_pct > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'contribution_percentage must be between 0 and 100.';
    END IF;

    IF p_project_role NOT IN ('Researcher','Assistant','Lead Student','Intern','Volunteer') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid project_role.';
    END IF;

    SELECT COUNT(*) INTO v_student_exists
    FROM Student WHERE student_id = p_student_id;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student does not exist.';
    END IF;

    SELECT COUNT(*) INTO v_project_exists
    FROM ResearchProject WHERE project_id = p_project_id;
    IF v_project_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Project does not exist.';
    END IF;

    SELECT COUNT(*) INTO v_already_reg
    FROM StudentProject
    WHERE student_id = p_student_id AND project_id = p_project_id;
    IF v_already_reg > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student is already registered in this project.';
    END IF;

    SELECT COALESCE(SUM(contribution_percentage), 0)
      INTO v_current_total
    FROM StudentProject
    WHERE student_id = p_student_id;

    IF v_current_total + p_contribution_pct > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total contribution for this student would exceed 100%.';
    END IF;

    INSERT INTO StudentProject
        (student_id, project_id, project_role, contribution_percentage, join_date)
    VALUES
        (p_student_id, p_project_id, p_project_role, p_contribution_pct, CURDATE());

    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('INSERT', 'StudentProject',
            CONCAT(p_student_id,'-',p_project_id),
            NULL,
            CONCAT('role=', p_project_role, '; pct=', p_contribution_pct));

    SET p_result_message = CONCAT('Student ', p_student_id,
                                  ' registered in project ', p_project_id, '.');

END$$
DELIMITER ;




DELIMITER $$

CREATE PROCEDURE sp_SubmitPublicationToConference (
    IN  p_publication_id INT,
    IN  p_conference_id  INT,
    IN  p_submission_date DATE,
    OUT p_result_message VARCHAR(255)
)
proc_body: BEGIN
    DECLARE v_pub_exists       INT DEFAULT 0;
    DECLARE v_conf_exists      INT DEFAULT 0;
    DECLARE v_deadline         DATE DEFAULT NULL;
    DECLARE v_duplicate        INT DEFAULT 0;
    DECLARE v_new_sub_id       INT DEFAULT 0;

    IF p_publication_id IS NULL OR p_conference_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'publication_id and conference_id are required.';
    END IF;

    IF p_submission_date IS NULL THEN
        SET p_submission_date = CURDATE();
    END IF;

    IF p_submission_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'submission_date cannot be in the future.';
    END IF;

    SELECT COUNT(*) INTO v_pub_exists
    FROM Publication WHERE publication_id = p_publication_id;
    IF v_pub_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Publication does not exist.';
    END IF;

    SELECT COUNT(*), MAX(submission_deadline)
      INTO v_conf_exists, v_deadline
    FROM Conference WHERE conference_id = p_conference_id;
    IF v_conf_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Conference does not exist.';
    END IF;

    IF v_deadline IS NOT NULL AND p_submission_date > v_deadline THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Submission date is after the conference deadline.';
    END IF;

    SELECT COUNT(*) INTO v_duplicate
    FROM Submission
    WHERE publication_id = p_publication_id
      AND conference_id  = p_conference_id;
    IF v_duplicate > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This publication is already submitted to this conference.';
    END IF;

    SELECT COALESCE(MAX(submission_id), 0) + 1 INTO v_new_sub_id FROM Submission;

    INSERT INTO Submission
        (submission_id, publication_id, conference_id,
         submission_date, decision, decision_date)
    VALUES
        (v_new_sub_id, p_publication_id, p_conference_id,
         p_submission_date, 'Pending', NULL);

    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('INSERT', 'Submission', CAST(v_new_sub_id AS CHAR), NULL,
            CONCAT('pub=', p_publication_id, '; conf=', p_conference_id));

    SET p_result_message = CONCAT('Submission ', v_new_sub_id, ' created with Pending status.');

END$$
DELIMITER ;



DELIMITER $$
CREATE FUNCTION fn_CalculateTotalProjectFunding (p_project_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total   DECIMAL(14,2) DEFAULT 0;
    DECLARE v_exists  INT DEFAULT 0;

    IF p_project_id IS NULL OR p_project_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_CalculateTotalProjectFunding: project_id must be positive.';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM ResearchProject WHERE project_id = p_project_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_CalculateTotalProjectFunding: project does not exist.';
    END IF;

    SELECT COALESCE(SUM(funding_amount), 0) INTO v_total
    FROM Funding WHERE project_id = p_project_id;

    RETURN v_total;
END$$
DELIMITER ;




DELIMITER $$
CREATE FUNCTION fn_CountFacultyPublications (p_faculty_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count  INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;

    IF p_faculty_id IS NULL OR p_faculty_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_CountFacultyPublications: faculty_id must be positive.';
    END IF;

    SELECT COUNT(*) INTO v_exists FROM Faculty WHERE faculty_id = p_faculty_id;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_CountFacultyPublications: faculty does not exist.';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM PublicationAuthor WHERE faculty_id = p_faculty_id;

    RETURN v_count;
END$$
DELIMITER ;



DELIMITER $$
CREATE FUNCTION fn_TotalStudentContribution (p_student_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;

    IF p_student_id IS NULL OR p_student_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_TotalStudentContribution: student_id must be positive.';
    END IF;

    SELECT COUNT(*) INTO v_exists FROM Student WHERE student_id = p_student_id;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_TotalStudentContribution: student does not exist.';
    END IF;

    SELECT COALESCE(SUM(contribution_percentage), 0) INTO v_total
    FROM StudentProject WHERE student_id = p_student_id;

    RETURN v_total;
END$$
DELIMITER ;



CALL sp_AddResearchProject(
    101, 'Test Project', '2024-01-01', '2025-12-31',
    'Active', 1, 1, @msg);
SELECT @msg AS procedure_1_result;


CALL sp_RegisterStudentInProject(28, 1, 'Researcher', 10, @msg);
SELECT @msg AS procedure_2_result;


CALL sp_SubmitPublicationToConference(7, 3, '2023-06-01', @msg);
SELECT @msg AS procedure_3_result;


SELECT fn_CalculateTotalProjectFunding(1)  AS funding_project_1;
SELECT fn_CalculateTotalProjectFunding(6)  AS funding_project_6;
SELECT fn_CalculateTotalProjectFunding(12) AS funding_project_12;

SELECT fn_CountFacultyPublications(1)      AS pubs_faculty_1;
SELECT fn_CountFacultyPublications(2)      AS pubs_faculty_2;

SELECT fn_TotalStudentContribution(1)      AS contrib_student_1;
SELECT fn_TotalStudentContribution(9)      AS contrib_student_9; 






DELIMITER $$
CREATE TRIGGER trg_studentproject_contrib_limit_insert
BEFORE INSERT ON StudentProject FOR EACH ROW
BEGIN
    DECLARE v_current_total DECIMAL(10,2);
    SELECT COALESCE(SUM(contribution_percentage),0) INTO v_current_total
    FROM StudentProject WHERE student_id = NEW.student_id;
    IF v_current_total + NEW.contribution_percentage > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total contribution for this student would exceed 100%.';
    END IF;
END$$

CREATE TRIGGER trg_studentproject_contrib_limit_update
BEFORE UPDATE ON StudentProject FOR EACH ROW
BEGIN
    DECLARE v_other_total DECIMAL(10,2);
    SELECT COALESCE(SUM(contribution_percentage),0) INTO v_other_total
    FROM StudentProject
    WHERE student_id = NEW.student_id
      AND NOT (student_id = OLD.student_id AND project_id = OLD.project_id);
    IF v_other_total + NEW.contribution_percentage > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Total contribution for this student would exceed 100%.';
    END IF;
END$$


CREATE TRIGGER trg_student_valid_supervisor_insert
BEFORE INSERT ON Student FOR EACH ROW
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_fac_dept INT;
    DECLARE v_fac_title VARCHAR(50);
    DECLARE v_stu_dept INT;
    IF NEW.supervisor_id IS NOT NULL THEN
        SELECT COUNT(*), MAX(department_id), MAX(title)
          INTO v_exists, v_fac_dept, v_fac_title
        FROM Faculty WHERE faculty_id = NEW.supervisor_id;
        IF v_exists = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Supervisor does not exist in Faculty.';
        END IF;
        SELECT department_id INTO v_stu_dept FROM Program WHERE program_id = NEW.program_id;
        IF v_fac_dept <> v_stu_dept THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Supervisor must belong to the same department as the student''s program.';
        END IF;
        IF v_fac_title NOT IN ('Professor','Associate Professor','Assistant Professor') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Only Professor/Associate/Assistant Professor may supervise.';
        END IF;
    END IF;
END$$


CREATE TRIGGER trg_student_valid_supervisor_update
BEFORE UPDATE ON Student FOR EACH ROW
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_fac_dept INT;
    DECLARE v_fac_title VARCHAR(50);
    DECLARE v_stu_dept INT;
    IF NEW.supervisor_id IS NOT NULL THEN
        SELECT COUNT(*), MAX(department_id), MAX(title)
          INTO v_exists, v_fac_dept, v_fac_title
        FROM Faculty WHERE faculty_id = NEW.supervisor_id;
        IF v_exists = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Supervisor does not exist in Faculty.';
        END IF;
        SELECT department_id INTO v_stu_dept FROM Program WHERE program_id = NEW.program_id;
        IF v_fac_dept <> v_stu_dept THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Supervisor must belong to the same department as the student''s program.';
        END IF;
        IF v_fac_title NOT IN ('Professor','Associate Professor','Assistant Professor') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Only Professor/Associate/Assistant Professor may supervise.';
        END IF;
    END IF;
END$$


CREATE TRIGGER trg_funding_no_negative_insert
BEFORE INSERT ON Funding FOR EACH ROW
BEGIN
    IF NEW.funding_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funding amount cannot be negative.';
    END IF;
    IF NEW.funding_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funding date cannot be in the future.';
    END IF;
END$$

CREATE TRIGGER trg_funding_no_negative_update
BEFORE UPDATE ON Funding FOR EACH ROW
BEGIN
    IF NEW.funding_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funding amount cannot be negative.';
    END IF;
    IF NEW.funding_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funding date cannot be in the future.';
    END IF;
END$$


CREATE TRIGGER trg_project_audit_insert AFTER INSERT ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('INSERT','ResearchProject',CAST(NEW.project_id AS CHAR),NULL,
            CONCAT('title=',NEW.project_title,'; status=',NEW.status,
                   '; start=',NEW.start_date,'; end=',COALESCE(NEW.end_date,'NULL'),
                   '; dept=',NEW.department_id,'; lead=',COALESCE(NEW.lead_faculty_id,'NULL')));
END$$

CREATE TRIGGER trg_project_audit_update AFTER UPDATE ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('UPDATE','ResearchProject',CAST(NEW.project_id AS CHAR),
            CONCAT('title=',OLD.project_title,'; status=',OLD.status,
                   '; start=',OLD.start_date,'; end=',COALESCE(OLD.end_date,'NULL'),
                   '; dept=',OLD.department_id,'; lead=',COALESCE(OLD.lead_faculty_id,'NULL')),
            CONCAT('title=',NEW.project_title,'; status=',NEW.status,
                   '; start=',NEW.start_date,'; end=',COALESCE(NEW.end_date,'NULL'),
                   '; dept=',NEW.department_id,'; lead=',COALESCE(NEW.lead_faculty_id,'NULL')));
END$$

CREATE TRIGGER trg_project_audit_delete AFTER DELETE ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('DELETE','ResearchProject',CAST(OLD.project_id AS CHAR),
            CONCAT('title=',OLD.project_title,'; status=',OLD.status,
                   '; start=',OLD.start_date,'; end=',COALESCE(OLD.end_date,'NULL'),
                   '; dept=',OLD.department_id,'; lead=',COALESCE(OLD.lead_faculty_id,'NULL')),NULL);
END$$

CREATE TRIGGER trg_faculty_prevent_delete_if_supervising
BEFORE DELETE ON Faculty FOR EACH ROW
BEGIN
    DECLARE v_students INT DEFAULT 0;
    DECLARE v_projects INT DEFAULT 0;
    DECLARE v_lead     INT DEFAULT 0;
    SELECT COUNT(*) INTO v_students FROM Student        WHERE supervisor_id  = OLD.faculty_id;
    SELECT COUNT(*) INTO v_projects FROM FacultyProject WHERE faculty_id     = OLD.faculty_id;
    SELECT COUNT(*) INTO v_lead     FROM ResearchProject WHERE lead_faculty_id = OLD.faculty_id;
    IF v_students > 0 OR v_projects > 0 OR v_lead > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete faculty: still assigned as supervisor/lead. Reassign first.';
    END IF;
END$$

CREATE TRIGGER trg_publication_audit_insert AFTER INSERT ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('INSERT','Publication',CAST(NEW.publication_id AS CHAR),NULL,
            CONCAT('title=',NEW.title,'; type=',NEW.publication_type,
                   '; year=',NEW.publication_year,'; doi=',COALESCE(NEW.doi,'NULL'),
                   '; journal=',COALESCE(NEW.journal_name,'NULL')));
END$$

CREATE TRIGGER trg_publication_audit_update AFTER UPDATE ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('UPDATE','Publication',CAST(NEW.publication_id AS CHAR),
            CONCAT('title=',OLD.title,'; type=',OLD.publication_type,
                   '; year=',OLD.publication_year,'; doi=',COALESCE(OLD.doi,'NULL'),
                   '; journal=',COALESCE(OLD.journal_name,'NULL')),
            CONCAT('title=',NEW.title,'; type=',NEW.publication_type,
                   '; year=',NEW.publication_year,'; doi=',COALESCE(NEW.doi,'NULL'),
                   '; journal=',COALESCE(NEW.journal_name,'NULL')));
END$$

CREATE TRIGGER trg_publication_audit_delete AFTER DELETE ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (operation, table_name, record_pk, old_value, new_value)
    VALUES ('DELETE','Publication',CAST(OLD.publication_id AS CHAR),
            CONCAT('title=',OLD.title,'; type=',OLD.publication_type,
                   '; year=',OLD.publication_year,'; doi=',COALESCE(OLD.doi,'NULL'),
                   '; journal=',COALESCE(OLD.journal_name,'NULL')),NULL);
END$$
DELIMITER ;



INSERT INTO StudentProject (student_id, project_id, project_role, contribution_percentage)
VALUES (1, 11, 'Researcher', 50);

UPDATE ResearchProject SET status = 'Completed' WHERE project_id = 2;
SELECT * FROM AuditLog WHERE table_name = 'ResearchProject' ORDER BY audit_id DESC LIMIT 1;

UPDATE Publication SET journal_name = 'New Journal' WHERE publication_id = 1;
SELECT * FROM AuditLog WHERE table_name = 'Publication' ORDER BY audit_id DESC LIMIT 1;






SET @app_user = 'faculty:ahmed.alfarsi';

DELIMITER $$
CREATE FUNCTION fn_current_app_user()
RETURNS VARCHAR(100)
NOT DETERMINISTIC
NO SQL
BEGIN
    RETURN COALESCE(@app_user, CURRENT_USER());
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_student_audit_insert;
DROP TRIGGER IF EXISTS trg_student_audit_update;
DROP TRIGGER IF EXISTS trg_student_audit_delete;
DELIMITER $$

CREATE TRIGGER trg_student_audit_insert
AFTER INSERT ON Student
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'INSERT', 'Student', CAST(NEW.student_id AS CHAR),
            NULL,
            CONCAT('name=', NEW.first_name,' ',NEW.last_name,
                   '; email=', NEW.email,
                   '; status=', NEW.academic_status,
                   '; program=', NEW.program_id,
                   '; supervisor=', COALESCE(NEW.supervisor_id,'NULL')));
END$$

CREATE TRIGGER trg_student_audit_update
AFTER UPDATE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'UPDATE', 'Student', CAST(NEW.student_id AS CHAR),
            CONCAT('name=', OLD.first_name,' ',OLD.last_name,
                   '; email=', OLD.email,
                   '; phone=', COALESCE(OLD.phone,'NULL'),
                   '; status=', OLD.academic_status,
                   '; program=', OLD.program_id,
                   '; supervisor=', COALESCE(OLD.supervisor_id,'NULL')),
            CONCAT('name=', NEW.first_name,' ',NEW.last_name,
                   '; email=', NEW.email,
                   '; phone=', COALESCE(NEW.phone,'NULL'),
                   '; status=', NEW.academic_status,
                   '; program=', NEW.program_id,
                   '; supervisor=', COALESCE(NEW.supervisor_id,'NULL')));
END$$

CREATE TRIGGER trg_student_audit_delete
AFTER DELETE ON Student
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'DELETE', 'Student', CAST(OLD.student_id AS CHAR),
            CONCAT('name=', OLD.first_name,' ',OLD.last_name,
                   '; email=', OLD.email,
                   '; phone=', COALESCE(OLD.phone,'NULL'),
                   '; status=', OLD.academic_status,
                   '; program=', OLD.program_id,
                   '; supervisor=', COALESCE(OLD.supervisor_id,'NULL')),
            NULL);
END$$

DELIMITER ;


DROP TRIGGER IF EXISTS trg_funding_audit_insert;
DROP TRIGGER IF EXISTS trg_funding_audit_update;
DROP TRIGGER IF EXISTS trg_funding_audit_delete;
DELIMITER $$

CREATE TRIGGER trg_funding_audit_insert
AFTER INSERT ON Funding
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'INSERT', 'Funding', CAST(NEW.funding_id AS CHAR),
            NULL,
            CONCAT('project=', NEW.project_id,
                   '; source=', NEW.source_id,
                   '; amount=', NEW.funding_amount,
                   '; date=', NEW.funding_date));
END$$

CREATE TRIGGER trg_funding_audit_update
AFTER UPDATE ON Funding
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'UPDATE', 'Funding', CAST(NEW.funding_id AS CHAR),
            CONCAT('project=', OLD.project_id,
                   '; source=', OLD.source_id,
                   '; amount=', OLD.funding_amount,
                   '; date=', OLD.funding_date),
            CONCAT('project=', NEW.project_id,
                   '; source=', NEW.source_id,
                   '; amount=', NEW.funding_amount,
                   '; date=', NEW.funding_date));
END$$

CREATE TRIGGER trg_funding_audit_delete
AFTER DELETE ON Funding
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(), 'DELETE', 'Funding', CAST(OLD.funding_id AS CHAR),
            CONCAT('project=', OLD.project_id,
                   '; source=', OLD.source_id,
                   '; amount=', OLD.funding_amount,
                   '; date=', OLD.funding_date),
            NULL);
END$$

DELIMITER ;


DROP TRIGGER IF EXISTS trg_project_audit_insert;
DROP TRIGGER IF EXISTS trg_project_audit_update;
DROP TRIGGER IF EXISTS trg_project_audit_delete;
DROP TRIGGER IF EXISTS trg_publication_audit_insert;
DROP TRIGGER IF EXISTS trg_publication_audit_update;
DROP TRIGGER IF EXISTS trg_publication_audit_delete;
DELIMITER $$

CREATE TRIGGER trg_project_audit_insert AFTER INSERT ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'INSERT','ResearchProject',CAST(NEW.project_id AS CHAR),NULL,
            CONCAT('title=',NEW.project_title,'; status=',NEW.status,
                   '; start=',NEW.start_date,'; end=',COALESCE(NEW.end_date,'NULL'),
                   '; dept=',NEW.department_id,'; lead=',COALESCE(NEW.lead_faculty_id,'NULL')));
END$$

CREATE TRIGGER trg_project_audit_update AFTER UPDATE ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'UPDATE','ResearchProject',CAST(NEW.project_id AS CHAR),
            CONCAT('title=',OLD.project_title,'; status=',OLD.status,
                   '; start=',OLD.start_date,'; end=',COALESCE(OLD.end_date,'NULL'),
                   '; dept=',OLD.department_id,'; lead=',COALESCE(OLD.lead_faculty_id,'NULL')),
            CONCAT('title=',NEW.project_title,'; status=',NEW.status,
                   '; start=',NEW.start_date,'; end=',COALESCE(NEW.end_date,'NULL'),
                   '; dept=',NEW.department_id,'; lead=',COALESCE(NEW.lead_faculty_id,'NULL')));
END$$

CREATE TRIGGER trg_project_audit_delete AFTER DELETE ON ResearchProject FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'DELETE','ResearchProject',CAST(OLD.project_id AS CHAR),
            CONCAT('title=',OLD.project_title,'; status=',OLD.status,
                   '; start=',OLD.start_date,'; end=',COALESCE(OLD.end_date,'NULL'),
                   '; dept=',OLD.department_id,'; lead=',COALESCE(OLD.lead_faculty_id,'NULL')),NULL);
END$$

CREATE TRIGGER trg_publication_audit_insert AFTER INSERT ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'INSERT','Publication',CAST(NEW.publication_id AS CHAR),NULL,
            CONCAT('title=',NEW.title,'; type=',NEW.publication_type,
                   '; year=',NEW.publication_year,'; doi=',COALESCE(NEW.doi,'NULL'),
                   '; journal=',COALESCE(NEW.journal_name,'NULL')));
END$$

CREATE TRIGGER trg_publication_audit_update AFTER UPDATE ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'UPDATE','Publication',CAST(NEW.publication_id AS CHAR),
            CONCAT('title=',OLD.title,'; type=',OLD.publication_type,
                   '; year=',OLD.publication_year,'; doi=',COALESCE(OLD.doi,'NULL'),
                   '; journal=',COALESCE(OLD.journal_name,'NULL')),
            CONCAT('title=',NEW.title,'; type=',NEW.publication_type,
                   '; year=',NEW.publication_year,'; doi=',COALESCE(NEW.doi,'NULL'),
                   '; journal=',COALESCE(NEW.journal_name,'NULL')));
END$$

CREATE TRIGGER trg_publication_audit_delete AFTER DELETE ON Publication FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (db_user, operation, table_name, record_pk, old_value, new_value)
    VALUES (fn_current_app_user(),'DELETE','Publication',CAST(OLD.publication_id AS CHAR),
            CONCAT('title=',OLD.title,'; type=',OLD.publication_type,
                   '; year=',OLD.publication_year,'; doi=',COALESCE(OLD.doi,'NULL'),
                   '; journal=',COALESCE(OLD.journal_name,'NULL')),NULL);
END$$

DELIMITER ;


DELIMITER $$
CREATE TRIGGER trg_auditlog_no_update BEFORE UPDATE ON AuditLog FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AuditLog is append-only; UPDATE is not permitted.';
END$$

CREATE TRIGGER trg_auditlog_no_delete BEFORE DELETE ON AuditLog FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AuditLog is append-only; DELETE is not permitted.';
END$$
DELIMITER ;


CREATE OR REPLACE VIEW vw_AuditTrail AS
SELECT
    audit_id,
    db_user,
    operation,
    table_name,
    record_pk,
    old_value,
    new_value,
    change_time,
    DATE(change_time)   AS change_date,
    TIME(change_time)   AS change_time_only
FROM AuditLog
ORDER BY audit_id DESC;




SET @app_user = 'research_admin:mona.rahman';

INSERT INTO Student (student_id, first_name, last_name, email, program_id, supervisor_id)
VALUES (99, 'Test', 'Student', 'test.student99@student.edu', 1, 1);

UPDATE Student SET academic_status = 'Suspended' WHERE student_id = 99;

UPDATE ResearchProject SET status = 'Completed' WHERE project_id = 2;

INSERT INTO Funding (funding_id, project_id, source_id, funding_amount, funding_date)
VALUES (900, 1, 1, 50000.00, CURDATE());

UPDATE Funding SET funding_amount = 60000.00 WHERE funding_id = 900;

UPDATE Publication SET journal_name = 'Updated Journal' WHERE publication_id = 1;

SELECT audit_id, db_user, operation, table_name, record_pk, change_time
FROM AuditLog
WHERE table_name IN ('Student','ResearchProject','Funding','Publication')
ORDER BY audit_id DESC
LIMIT 20;











