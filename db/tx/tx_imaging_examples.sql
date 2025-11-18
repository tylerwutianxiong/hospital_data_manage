PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

INSERT OR IGNORE INTO hospital (hospital_id, name, short_name, region)
VALUES (1, 'Test Medical Center', 'TMC', 'Local');

INSERT OR IGNORE INTO patient (patient_id, hospital_id, mrn, given_name, family_name, sex, dob)
VALUES (1, 1, 'TEST-MRN-001', 'Alice', 'Johnson', 'F', '1990-05-15');

INSERT OR IGNORE INTO encounter (encounter_id, patient_id, hospital_id, location_id, admit_dt, enc_type, status)
VALUES (1, 1, 1, 1, datetime('now'), 'outpatient', 'open');

-- Transaction Example 1: Create Image Report+Image File (Atomic Execution)
BEGIN IMMEDIATE;

-- 1) Create an image report (insert only if report_no does not exist)
INSERT OR IGNORE INTO imaging_report (
  encounter_id, patient_id, filler_order_no, report_no, requested_procedure_id,
  report_status, report_status_desc, requested_dt, result_dt, final_result_dt,
  publish_dt, imaging_findings, imaging_conclusion, class_id, class_description,
  project_code, project_name, relevant_clinical_info
)
VALUES (
  1, 1, 'FO-2025001', 'RP-2025001', 'PROC-CT-CHEST-001',
  'final', 'Final Report - Approved', datetime('now'), datetime('now'), datetime('now'),
  datetime('now'),
  'CT scan of the chest shows a 2cm nodule in the right upper lobe with spiculated margins.',
  'Suspicious pulmonary nodule, recommend follow-up PET-CT.',
  'CT-CHEST-CONTRAST', 'Chest CT with Contrast',
  'ONCO-PROJ-2025', 'Oncology Screening Project',
  'Patient has history of smoking, presenting for routine screening.'
);

-- 2) Create image files (only executed when the report is actually inserted)
WITH _report AS (
  SELECT last_insert_rowid() AS report_id
)
INSERT OR IGNORE INTO imaging_file (report_id, patient_id, image_no, data_enter_dt, study_dt,
  file_path, file_size, file_hash, memo)
SELECT report_id, 1, 'IMG-2025001-01', datetime('now'), datetime('now'),
  '/storage/images/ct_chest_2025001.dcm', 5242880,
  'sha256:a1b2c3d4e5f6789012345678901234567890abcdef',
  'Primary CT chest image set' FROM _report WHERE report_id > 0;

COMMIT;

-- Verification query 1: Check the creation result
SELECT
  ir.report_id,
  ir.filler_order_no,
  ir.report_status,
  ifile.image_no,
  ifile.file_path
FROM imaging_report ir
JOIN imaging_file ifile ON ir.report_id = ifile.report_id
WHERE ir.filler_order_no = 'FO-2025001'
ORDER BY ir.report_id DESC LIMIT 1;

-- Transaction Example 2: Soft deletion of image report
BEGIN IMMEDIATE;
DELETE FROM imaging_report WHERE filler_order_no = 'FO-2025001';
COMMIT;

-- Verification query 2: Check the effectiveness of soft deletion(reports and files should be marked as deleted)
SELECT
  ir.report_id,
  ir.filler_order_no,
  ir.is_deleted AS report_deleted,
  ir.deleted_at AS report_deleted_at,
  ifile.file_id,
  ifile.image_no,
  ifile.is_deleted AS file_deleted,
  ifile.deleted_at AS file_deleted_at
FROM imaging_report ir
LEFT JOIN imaging_file ifile ON ir.report_id = ifile.report_id
WHERE ir.filler_order_no = 'FO-2025001';

-- Verification query 3: Check audit logs(should see two DELETE records)
SELECT
  audit_id,
  table_name,
  row_id,
  action,
  changed_at,
  json_extract(payload, '$.filler_order_no') AS filler_order_no,
  json_extract(payload, '$.image_no') AS image_no,
  json_extract(payload, '$.deleted_at') AS deleted_at
FROM audit_log
WHERE table_name IN ('imaging_report', 'imaging_file')
  AND action = 'DELETE'
ORDER BY changed_at DESC LIMIT 5;