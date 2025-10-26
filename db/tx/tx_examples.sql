-- db/tx/tx_examples.sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- 事务示例：一次就诊 + 检验 OBR + 检验 OBX（原子执行）
BEGIN IMMEDIATE;

-- 1) 新建 encounter
INSERT INTO encounter (patient_id, hospital_id, location_id, admit_dt, enc_type, status)
VALUES (1, 1, 1, datetime('now'), 'outpatient', 'open');

-- 2) 建 OBR（报告头）
WITH _enc AS (
  SELECT last_insert_rowid() AS encounter_id
)
INSERT INTO lab_obr (encounter_id, accession_no, specimen, collected_dt, status)
SELECT encounter_id, 'ACC-TX-0001', 'Blood', datetime('now'), 'final' FROM _enc;

-- 3) 建 OBX（检验结果）
WITH _obr AS (
  SELECT last_insert_rowid() AS obr_id
)
INSERT INTO lab_obx (obr_id, test_code, code_system, test_name, value_type, value_num, units, result_dt, abnormal_flag)
SELECT obr_id, '718-7', 'LOINC', 'Hemoglobin', 'NM', 13.2, 'g/dL', datetime('now'), 'N' FROM _obr;

COMMIT;

-- 验证查询（可注释掉）
SELECT e.encounter_id, o.obr_id, x.obx_id, x.test_name, x.value_num, x.units
FROM encounter e
JOIN lab_obr o ON e.encounter_id = o.encounter_id
JOIN lab_obx x ON o.obr_id = x.obr_id
ORDER BY e.encounter_id DESC LIMIT 1;
