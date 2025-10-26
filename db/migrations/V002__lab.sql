PRAGMA foreign_keys = ON;

-- OBR: 一次检验申请/报告头
CREATE TABLE lab_obr (
  obr_id          INTEGER PRIMARY KEY,
  encounter_id    INTEGER NOT NULL,
  accession_no    TEXT UNIQUE,
  specimen        TEXT,
  collected_dt    TEXT,
  received_dt     TEXT,
  status          TEXT,
  placer_order_no TEXT,
  filler_order_no TEXT,
  FOREIGN KEY (encounter_id) REFERENCES encounter(encounter_id) ON DELETE CASCADE
);
CREATE INDEX idx_lab_obr_enc ON lab_obr(encounter_id);
CREATE INDEX idx_lab_obr_acc ON lab_obr(accession_no);

-- OBX: 单条检验结果
CREATE TABLE lab_obx (
  obx_id        INTEGER PRIMARY KEY,
  obr_id        INTEGER NOT NULL,
  test_code     TEXT,
  code_system   TEXT,           -- e.g., LOINC
  test_name     TEXT,
  value_type    TEXT,           -- NM/TX/DT/...
  value_num     REAL,
  value_text    TEXT,
  units         TEXT,
  ref_range     TEXT,
  abnormal_flag TEXT,           -- H/L/A/N
  result_dt     TEXT,
  FOREIGN KEY (obr_id) REFERENCES lab_obr(obr_id) ON DELETE CASCADE
);
CREATE INDEX idx_lab_obx_obr  ON lab_obx(obr_id);
CREATE INDEX idx_lab_obx_code ON lab_obx(test_code, code_system);
