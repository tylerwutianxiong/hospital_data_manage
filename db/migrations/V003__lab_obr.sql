PRAGMA foreign_keys = ON;

-- ===== Core Entities =====
CREATE TABLE patient (
  patient_id           INTEGER PRIMARY KEY,
  patient_name         TEXT,
  patient_sex          TEXT CHECK (patient_sex IN ('M', 'F', 'O') OR patient_sex IS NULL),
  patient_class        TEXT,
  patient_age_hours    INTEGER,
  patient_age_unit     TEXT,
  patient_age_text     TEXT,
  patient_diag         TEXT,
  patient_nation       TEXT,
  patient_nation_name  TEXT,
  visit_number         TEXT,
  barcode              TEXT,
  ssn                  TEXT
);
CREATE TABLE assigned_bed (
  assigned_bed_id              INTEGER PRIMARY KEY,
  bed_no                       TEXT,
  assigned_location_unit       TEXT,
  assigned_location_unit_desc  TEXT,
  assigned_location_unit_his   TEXT
);
CREATE TABLE hospital_service (
  hospital_service_id          INTEGER PRIMARY KEY,
  hospital_service_name        TEXT,
  hospital_service_desc        TEXT,
  hospital_service_his         TEXT
);

CREATE TABLE facility (
  facility_id              INTEGER PRIMARY KEY,
  ordering_facility_name   TEXT,
  ordering_facility_id     TEXT,
  ordering_department_name TEXT,
  ordering_department_id   TEXT
);
CREATE TABLE medical_staff (
  medical_staff_id          INTEGER PRIMARY KEY,
  ordering_provider_no      TEXT,
  ordering_provider_name    TEXT,
  principle_result_interpreter TEXT,
  assistant_result_interpreter TEXT,
  perform_staff_no          TEXT,
  specimen_collector        TEXT,
  specimen_receiver         TEXT
);

CREATE TABLE laboratory_order (
  laboratory_order_id     INTEGER PRIMARY KEY,
  requested_procedure_id  TEXT,
  result_status           TEXT,
  placer_order_number     TEXT,
  order_callback_phone_no TEXT,
  request_datetime        TEXT,
  filler_order_no         TEXT,
  relevant_clinical_info  TEXT
);
CREATE TABLE specimen (
  specimen_id                 INTEGER PRIMARY KEY,
  specimen_internal_no        TEXT,
  specimen_status_code        TEXT,
  specimen_source_code        TEXT,
  specimen_source_name        TEXT,
  specimen_source_site_code   TEXT,
  specimen_source_site_name   TEXT,
  specimen_collection_datetime TEXT,
  specimen_receive_datetime   TEXT,
  specimen_status_name        TEXT,
  culture                     TEXT
);

CREATE TABLE test_item (
  test_item_id           INTEGER PRIMARY KEY,
  observation_id         TEXT,
  observation_en         TEXT,
  observation_cn         TEXT,
  observation_code       TEXT,
  observation_value      TEXT,
  observation_original_value TEXT,
  observation_Datetime   DATE,
  reference_range        TEXT,
  result_type            TEXT,
  abnormal_flag          TEXT,
  units                  TEXT,
  perform_datetime       TEXT,
  final_result_datetime  TEXT
);
CREATE TABLE laboratory_service (
  laboratory_service_id  INTEGER PRIMARY KEY,
  universal_service_id   TEXT,
  universal_service_name TEXT
);

CREATE TABLE diagnostic_service_section (
  diagnostic_service_section_id INTEGER PRIMARY KEY,
  diagnostic_service_description TEXT
);
CREATE TABLE instruction (
  instruction_id     INTEGER PRIMARY KEY,
  responsible_observer TEXT
);

CREATE TABLE system_audit (
  audit_id       INTEGER PRIMARY KEY,
  feed_value     TEXT,
  feed_key       TEXT,
  is_deleted     INTEGER DEFAULT 0,
  timestamp      TEXT DEFAULT (datetime('now')),
  last_import_dtm TEXT,
  last_update_dtm TEXT
);

-- ===== Relationships (FKs) =====
-- Patient assigned bed
CREATE TABLE patient_bed_assignment (
  patient_id       INTEGER NOT NULL,
  assigned_bed_id  INTEGER NOT NULL,
  PRIMARY KEY (patient_id, assigned_bed_id),
  FOREIGN KEY (patient_id)      REFERENCES patient(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_bed_id) REFERENCES assigned_bed(assigned_bed_id) ON DELETE CASCADE
);

-- Patient request hospital service
CREATE TABLE patient_service_request (
  patient_id            INTEGER NOT NULL,
  hospital_service_id   INTEGER NOT NULL,
  PRIMARY KEY (patient_id, hospital_service_id),
  FOREIGN KEY (patient_id)          REFERENCES patient(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (hospital_service_id) REFERENCES hospital_service(hospital_service_id) ON DELETE CASCADE 
);
CREATE TABLE hospitalservice_facility (
  hospital_service_id  INTEGER NOT NULL,
  facility_id          INTEGER NOT NULL,
  PRIMARY KEY (hospital_service_id, facility_id),
  FOREIGN KEY (hospital_service_id) REFERENCES hospital_service(hospital_service_id) ON DELETE CASCADE,
  FOREIGN KEY (facility_id)         REFERENCES facility(facility_id) ON DELETE CASCADE
);
-- Laboratory order relations
CREATE TABLE laboratory_order_specimen (
  laboratory_order_id INTEGER NOT NULL,
  specimen_id         INTEGER NOT NULL,
  PRIMARY KEY (laboratory_order_id, specimen_id),
  FOREIGN KEY (laboratory_order_id) REFERENCES laboratory_order(laboratory_order_id) ON DELETE CASCADE,
  FOREIGN KEY (specimen_id)         REFERENCES specimen(specimen_id) ON DELETE CASCADE
);

CREATE TABLE specimen_test_item (
  specimen_id   INTEGER NOT NULL,
  test_item_id  INTEGER NOT NULL,
  PRIMARY KEY (specimen_id, test_item_id),
  FOREIGN KEY (specimen_id)  REFERENCES specimen(specimen_id) ON DELETE CASCADE,
  FOREIGN KEY (test_item_id) REFERENCES test_item(test_item_id) ON DELETE CASCADE
);

-- Laboratory services and sections
CREATE TABLE laboratory_service_section (
  laboratory_service_id          INTEGER NOT NULL,
  diagnostic_service_section_id  INTEGER NOT NULL,
  PRIMARY KEY (laboratory_service_id, diagnostic_service_section_id),
  FOREIGN KEY (laboratory_service_id)         REFERENCES laboratory_service(laboratory_service_id) ON DELETE CASCADE,
  FOREIGN KEY (diagnostic_service_section_id) REFERENCES diagnostic_service_section(diagnostic_service_section_id) ON DELETE CASCADE
);

-- Medical staff and laboratory order
CREATE TABLE laboratory_order_staff (
  laboratory_order_id  INTEGER NOT NULL,
  medical_staff_id     INTEGER NOT NULL,
  role                 TEXT,
  PRIMARY KEY (laboratory_order_id, medical_staff_id),
  FOREIGN KEY (laboratory_order_id) REFERENCES laboratory_order(laboratory_order_id) ON DELETE CASCADE,
  FOREIGN KEY (medical_staff_id)    REFERENCES medical_staff(medical_staff_id) ON DELETE CASCADE
);

-- Laboratory service and instruction
CREATE TABLE laboratory_instruction (
  laboratory_service_id INTEGER NOT NULL,
  instruction_id        INTEGER NOT NULL,
  PRIMARY KEY (laboratory_service_id, instruction_id),
  FOREIGN KEY (laboratory_service_id) REFERENCES laboratory_service(laboratory_service_id) ON DELETE CASCADE,
  FOREIGN KEY (instruction_id)        REFERENCES instruction(instruction_id) ON DELETE CASCADE
);
CREATE TABLE laborder_audit (
  laboratory_order_id  INTEGER NOT NULL,
  audit_id             INTEGER NOT NULL,
  PRIMARY KEY (laboratory_order_id, audit_id),
  FOREIGN KEY (laboratory_order_id) REFERENCES laboratory_order(laboratory_order_id) ON DELETE CASCADE,
  FOREIGN KEY (audit_id)            REFERENCES system_audit(audit_id) ON DELETE CASCADE
);
CREATE TABLE laborder_hospital_service (
  hospital_service_id   INTEGER NOT NULL,
  laboratory_order_id   INTEGER NOT NULL,

  PRIMARY KEY (hospital_service_id, laboratory_order_id),
    FOREIGN KEY (hospital_service_id) REFERENCES hospital_service(hospital_service_id) ON DELETE CASCADE,
  FOREIGN KEY (laboratory_order_id) REFERENCES laboratory_order(laboratory_order_id) ON DELETE CASCADE
  
);

CREATE TABLE serve_lab_request (
  laboratory_order_id  INTEGER NOT NULL,
  laboratory_service_id INTEGER NOT NULL,
  PRIMARY KEY (laboratory_order_id,laboratory_service_id),
  FOREIGN KEY (laboratory_order_id) REFERENCES laboratory_order(laboratory_order_id) ON DELETE CASCADE,
  FOREIGN KEY (laboratory_service_id) REFERENCES laboratory_service(laboratory_service_id) ON DELETE CASCADE
);


CREATE INDEX idx_patient_name        ON patient(patient_name);
CREATE INDEX idx_patient_visit       ON patient(visit_number);
CREATE INDEX idx_bed_no              ON assigned_bed(bed_no);
CREATE INDEX idx_hospital_service    ON hospital_service(hospital_service_name);
CREATE INDEX idx_facility_dept       ON facility(ordering_department_name);
CREATE INDEX idx_medical_staff_name  ON medical_staff(ordering_provider_name);


CREATE INDEX idx_laborder_requestdt  ON laboratory_order(request_datetime);
CREATE INDEX idx_laborder_status     ON laboratory_order(result_status);
CREATE INDEX idx_specimen_status     ON specimen(specimen_status_code);
CREATE INDEX idx_specimen_collectdt  ON specimen(specimen_collection_datetime);
CREATE INDEX idx_testitem_code       ON test_item(observation_code);
CREATE INDEX idx_testitem_abflag     ON test_item(abnormal_flag);
CREATE INDEX idx_labservice_name     ON laboratory_service(universal_service_name);
CREATE INDEX idx_diag_section_desc   ON diagnostic_service_section(diagnostic_service_description);


CREATE INDEX idx_patient_bed         ON patient_bed_assignment(patient_id, assigned_bed_id);
CREATE INDEX idx_patient_service     ON patient_service_request(patient_id, hospital_service_id);
CREATE INDEX idx_laborder_specimen   ON laboratory_order_specimen(laboratory_order_id, specimen_id);
CREATE INDEX idx_specimen_testitem   ON specimen_test_item(specimen_id, test_item_id);
CREATE INDEX idx_labservice_section  ON laboratory_service_section(laboratory_service_id, diagnostic_service_section_id);
CREATE INDEX idx_laborder_staff      ON laboratory_order_staff(laboratory_order_id, medical_staff_id);
CREATE INDEX idx_labservice_instr    ON laboratory_instruction(laboratory_service_id, instruction_id);
CREATE INDEX idx_laborder_audit      ON laborder_audit(laboratory_order_id, audit_id);
CREATE INDEX idx_laborder_hospserv   ON laborder_hospital_service(laboratory_order_id, hospital_service_id);
CREATE INDEX idx_serve_lab_request   ON serve_lab_request(laboratory_order_id, laboratory_service_id);
CREATE INDEX idx_hospserv_facility   ON hospitalservice_facility(hospital_service_id, facility_id);

CREATE INDEX idx_audit_feedkey       ON system_audit(feed_key);
CREATE INDEX idx_audit_timestamp     ON system_audit(timestamp);

ALTER TABLE patient ADD COLUMN updated_at TEXT DEFAULT (datetime('now'));

CREATE TRIGGER IF NOT EXISTS trg_patient_updated_at
AFTER UPDATE ON patient
FOR EACH ROW
BEGIN
    UPDATE patient SET updated_at = CURRENT_TIMESTAMP WHERE patient_id = OLD.patient_id;
END;
