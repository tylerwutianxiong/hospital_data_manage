PRAGMA foreign_keys = ON;

-- ===== Imaging Core Tables =====
--Main Table of Imaging Inspection Report
CREATE TABLE imaging_report (
  report_id          INTEGER PRIMARY KEY,
  encounter_id       INTEGER NOT NULL,
  patient_id         INTEGER NOT NULL,

  filler_order_no    TEXT UNIQUE,
  report_no          TEXT UNIQUE,
  requested_procedure_id TEXT,
  report_status      TEXT NOT NULL,
  report_status_desc TEXT NOT NULL,
  requested_dt       TEXT NOT NULL,
  result_dt          TEXT,
  final_result_dt    TEXT NOT NULL,
  publish_dt         TEXT,
  
  --Report content
  imaging_findings   TEXT NOT NULL,
  imaging_conclusion TEXT NOT NULL,
  class_id           TEXT,
  class_description  TEXT NOT NULL,
  project_code       TEXT,
  project_name       TEXT,
  relevant_clinical_info TEXT,
  
  --Soft delete
  is_deleted         INTEGER DEFAULT 0 CHECK (is_deleted IN (0,1)),
  deleted_at         TEXT,
  deleted_by         INTEGER,
  
  created_at         TEXT DEFAULT (datetime('now')),
  updated_at         TEXT DEFAULT (datetime('now')),
  
  FOREIGN KEY (encounter_id) REFERENCES encounter(encounter_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id)   REFERENCES patient(patient_id)     ON DELETE CASCADE,
  FOREIGN KEY (deleted_by)   REFERENCES app_user(user_id)       ON DELETE SET NULL
);

CREATE INDEX idx_imaging_report_enc ON imaging_report(encounter_id);
CREATE INDEX idx_imaging_report_patient ON imaging_report(patient_id);
CREATE INDEX idx_imaging_report_filler ON imaging_report(filler_order_no);
CREATE INDEX idx_imaging_report_status ON imaging_report(report_status);
CREATE INDEX idx_imaging_report_deleted ON imaging_report(is_deleted);

--Image file table
CREATE TABLE imaging_file (
  file_id          INTEGER PRIMARY KEY,
  report_id        INTEGER NOT NULL,
  patient_id       INTEGER NOT NULL,
  image_no         TEXT UNIQUE NOT NULL,
  data_enter_dt    TEXT NOT NULL,
  study_dt         TEXT NOT NULL,
  
  --Storage Information
  file_path        TEXT,
  file_size        INTEGER,
  file_hash        TEXT,
  
 --Remarks Information
  memo             TEXT,
  
--Soft delete
  is_deleted       INTEGER DEFAULT 0 CHECK (is_deleted IN (0,1)),
  deleted_at       TEXT,
  deleted_by       INTEGER,
  
  created_at       TEXT DEFAULT (datetime('now')),
  
  FOREIGN KEY (report_id)  REFERENCES imaging_report(report_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id)       ON DELETE CASCADE,
  FOREIGN KEY (deleted_by) REFERENCES app_user(user_id)         ON DELETE SET NULL
);

CREATE INDEX idx_imaging_file_report ON imaging_file(report_id);
CREATE INDEX idx_imaging_file_patient ON imaging_file(patient_id);
CREATE INDEX idx_imaging_file_no ON imaging_file(image_no);
CREATE INDEX idx_imaging_file_deleted ON imaging_file(is_deleted);

--Department Table
CREATE TABLE imaging_department (
  dept_id          INTEGER PRIMARY KEY,
  hospital_id      INTEGER NOT NULL,
  dept_code        TEXT UNIQUE NOT NULL,
  dept_name        TEXT NOT NULL,
  dept_type        TEXT,
  parent_dept_id   INTEGER,
  
  -- 软删除相关字段
  is_deleted       INTEGER DEFAULT 0 CHECK (is_deleted IN (0,1)),
  deleted_at       TEXT,
  deleted_by       INTEGER,
  
  created_at       TEXT DEFAULT (datetime('now')),
  
  FOREIGN KEY (hospital_id)    REFERENCES hospital(hospital_id) ON DELETE RESTRICT,
  FOREIGN KEY (parent_dept_id) REFERENCES imaging_department(dept_id) ON DELETE SET NULL,
  FOREIGN KEY (deleted_by)     REFERENCES app_user(user_id)     ON DELETE SET NULL
);

CREATE INDEX idx_img_dept_hosp ON imaging_department(hospital_id);
CREATE INDEX idx_img_dept_code ON imaging_department(dept_code);
CREATE INDEX idx_img_dept_deleted ON imaging_department(is_deleted);

-- Department Association Table
CREATE TABLE imaging_report_department (
  report_id        INTEGER NOT NULL,
  dept_id          INTEGER NOT NULL,
  dept_role        TEXT CHECK (dept_role IN ('ordering','technical','performing')),
  
  PRIMARY KEY (report_id, dept_id, dept_role),
  FOREIGN KEY (report_id) REFERENCES imaging_report(report_id) ON DELETE CASCADE,
  FOREIGN KEY (dept_id)   REFERENCES imaging_department(dept_id) ON DELETE CASCADE
);

-- Report - Medical Personnel Association Table
CREATE TABLE imaging_report_provider (
  report_id        INTEGER NOT NULL,
  provider_id      INTEGER NOT NULL,
  provider_role    TEXT CHECK (provider_role IN ('ordering','reading_primary','reading_secondary','technician')),
  
  PRIMARY KEY (report_id, provider_id, provider_role),
  FOREIGN KEY (report_id)   REFERENCES imaging_report(report_id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id) REFERENCES provider(provider_id)     ON DELETE CASCADE
);

-- ===== Soft Delete Triggers =====

-- Video report soft delete trigger
CREATE TRIGGER trg_imaging_report_soft_delete
BEFORE DELETE ON imaging_report
FOR EACH ROW
BEGIN
  -- Update the associated files to deleted status first
  UPDATE imaging_file 
  SET is_deleted = 1,
      deleted_at = datetime('now'),
      deleted_by = (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1)
  WHERE report_id = OLD.report_id;
  
  -- update report itself
  UPDATE imaging_report
  SET is_deleted = 1,
      deleted_at = datetime('now'),
      deleted_by = (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1)
  WHERE report_id = OLD.report_id;
  
  -- Record audit logs
  INSERT INTO audit_log(table_name, row_id, action, changed_by, payload)
  VALUES (
    'imaging_report', 
    CAST(OLD.report_id AS TEXT), 
    'DELETE',
    (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1),
    json_object(
      'filler_order_no', OLD.filler_order_no,
      'report_status', OLD.report_status,
      'deleted_at', datetime('now')
    )
  );
  
  SELECT RAISE(IGNORE);
END;

-- Video file soft deletion trigger
CREATE TRIGGER trg_imaging_file_soft_delete
BEFORE DELETE ON imaging_file
FOR EACH ROW
BEGIN
  UPDATE imaging_file
  SET is_deleted = 1,
      deleted_at = datetime('now'),
      deleted_by = (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1)
  WHERE file_id = OLD.file_id;
  
  INSERT INTO audit_log(table_name, row_id, action, changed_by, payload)
  VALUES (
    'imaging_file', 
    CAST(OLD.file_id AS TEXT), 
    'DELETE',
    (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1),
    json_object(
      'image_no', OLD.image_no,
      'report_id', OLD.report_id,
      'deleted_at', datetime('now')
    )
  );
  
  SELECT RAISE(IGNORE);
END;

-- Soft deletion trigger for imaging department
CREATE TRIGGER trg_imaging_department_soft_delete
BEFORE DELETE ON imaging_department
FOR EACH ROW
BEGIN
  -- Check if there are any active reports associated with this department
  SELECT CASE WHEN EXISTS (
    SELECT 1 FROM imaging_report_department 
    WHERE dept_id = OLD.dept_id 
    AND report_id IN (SELECT report_id FROM imaging_report WHERE is_deleted = 0)
  ) THEN RAISE(ABORT, 'Cannot delete department with active reports') END;
  
  UPDATE imaging_department
  SET is_deleted = 1,
      deleted_at = datetime('now'),
      deleted_by = (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1)
  WHERE dept_id = OLD.dept_id;
  
  INSERT INTO audit_log(table_name, row_id, action, changed_by, payload)
  VALUES (
    'imaging_department', 
    CAST(OLD.dept_id AS TEXT), 
    'DELETE',
    (SELECT user_id FROM app_user WHERE username = 'system' LIMIT 1),
    json_object(
      'dept_code', OLD.dept_code,
      'dept_name', OLD.dept_name,
      'deleted_at', datetime('now')
    )
  );
  
  SELECT RAISE(IGNORE);
END;

-- ===== Update Timestamp Triggers =====

-- Image report update timestamp trigger
CREATE TRIGGER trg_imaging_report_update_timestamp
AFTER UPDATE ON imaging_report
FOR EACH ROW
BEGIN
  UPDATE imaging_report 
  SET updated_at = datetime('now') 
  WHERE report_id = NEW.report_id;
END;

-- ===== Views for Easy Querying =====

-- Detailed view of active image report
-- (excluding deleted records)
CREATE VIEW v_imaging_report_active AS
SELECT 
  ir.report_id,
  ir.filler_order_no,
  ir.report_no,
  p.patient_id,
  p.mrn,
  p.given_name || ' ' || COALESCE(p.family_name, '') AS patient_name,
  e.encounter_id,
  e.admit_dt,
  ir.report_status,
  ir.report_status_desc,
  substr(ir.imaging_findings, 1, 100) || '...' AS imaging_findings_preview,
  substr(ir.imaging_conclusion, 1, 100) || '...' AS imaging_conclusion_preview,
  ir.requested_dt,
  ir.final_result_dt,
  COUNT(if.file_id) AS image_count,
  ir.created_at,
  ir.updated_at
FROM imaging_report ir
JOIN patient p ON ir.patient_id = p.patient_id
JOIN encounter e ON ir.encounter_id = e.encounter_id
LEFT JOIN imaging_file if ON ir.report_id = if.report_id AND if.is_deleted = 0
WHERE ir.is_deleted = 0
GROUP BY ir.report_id;

-- All image report views
-- (including deleted records)
CREATE VIEW v_imaging_report_all AS
SELECT 
  ir.report_id,
  ir.filler_order_no,
  ir.report_no,
  p.patient_id,
  p.mrn,
  p.given_name || ' ' || COALESCE(p.family_name, '') AS patient_name,
  e.encounter_id,
  e.admit_dt,
  ir.report_status,
  ir.report_status_desc,
  substr(ir.imaging_findings, 1, 100) || '...' AS imaging_findings_preview,
  substr(ir.imaging_conclusion, 1, 100) || '...' AS imaging_conclusion_preview,
  ir.requested_dt,
  ir.final_result_dt,
  COUNT(if.file_id) AS image_count,
  ir.is_deleted,
  ir.deleted_at,
  u.username AS deleted_by_username,
  ir.created_at,
  ir.updated_at
FROM imaging_report ir
JOIN patient p ON ir.patient_id = p.patient_id
JOIN encounter e ON ir.encounter_id = e.encounter_id
LEFT JOIN imaging_file if ON ir.report_id = if.report_id AND if.is_deleted = 0
LEFT JOIN app_user u ON ir.deleted_by = u.user_id
GROUP BY ir.report_id;

-- Detailed View of Image Files
CREATE VIEW v_imaging_file_detail AS
SELECT 
  if.file_id,
  if.image_no,
  if.report_id,
  ir.filler_order_no,
  p.patient_id,
  p.mrn,
  p.given_name || ' ' || COALESCE(p.family_name, '') AS patient_name,
  if.study_dt,
  if.data_enter_dt,
  if.file_path,
  if.file_size,
  if.memo,
  if.is_deleted,
  if.deleted_at,
  if.created_at
FROM imaging_file if
JOIN imaging_report ir ON if.report_id = ir.report_id
JOIN patient p ON if.patient_id = p.patient_id
WHERE if.is_deleted = 0;
