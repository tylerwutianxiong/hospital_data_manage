PRAGMA foreign_keys = ON;

-- ===== Core master =====
CREATE TABLE hospital (
  hospital_id   INTEGER PRIMARY KEY,
  name          TEXT NOT NULL UNIQUE,
  short_name    TEXT,
  region        TEXT,
  created_at    TEXT DEFAULT (datetime('now'))
);

CREATE TABLE patient (
  patient_id    INTEGER PRIMARY KEY,
  hospital_id   INTEGER NOT NULL,
  mrn           TEXT NOT NULL UNIQUE,
  given_name    TEXT,
  family_name   TEXT,
  sex           TEXT CHECK (sex IN ('M','F','O') OR sex IS NULL),
  dob           TEXT,
  death_dt      TEXT,
  created_at    TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (hospital_id) REFERENCES hospital(hospital_id) ON DELETE RESTRICT
);
CREATE INDEX idx_patient_hosp ON patient(hospital_id);
CREATE INDEX idx_patient_mrn  ON patient(mrn);

CREATE TABLE provider (
  provider_id   INTEGER PRIMARY KEY,
  hospital_id   INTEGER NOT NULL,
  npi           TEXT UNIQUE,
  given_name    TEXT,
  family_name   TEXT,
  role          TEXT,
  department    TEXT,
  created_at    TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (hospital_id) REFERENCES hospital(hospital_id) ON DELETE RESTRICT
);
CREATE INDEX idx_provider_hosp ON provider(hospital_id);

CREATE TABLE location (
  location_id         INTEGER PRIMARY KEY,
  hospital_id         INTEGER NOT NULL,
  name                TEXT NOT NULL,
  loc_type            TEXT,
  parent_location_id  INTEGER,
  FOREIGN KEY (hospital_id)        REFERENCES hospital(hospital_id) ON DELETE RESTRICT,
  FOREIGN KEY (parent_location_id) REFERENCES location(location_id) ON DELETE SET NULL
);
CREATE INDEX idx_location_hosp ON location(hospital_id);

CREATE TABLE encounter (
  encounter_id  INTEGER PRIMARY KEY,
  patient_id    INTEGER NOT NULL,
  hospital_id   INTEGER NOT NULL,
  location_id   INTEGER,
  admit_dt      TEXT,
  discharge_dt  TEXT,
  enc_type      TEXT CHECK (enc_type IN ('inpatient','outpatient','emergency') OR enc_type IS NULL),
  status        TEXT CHECK (status IN ('open','closed','cancelled') OR status IS NULL),
  created_at    TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (patient_id)  REFERENCES patient(patient_id)   ON DELETE CASCADE,
  FOREIGN KEY (hospital_id) REFERENCES hospital(hospital_id) ON DELETE RESTRICT,
  FOREIGN KEY (location_id) REFERENCES location(location_id) ON DELETE SET NULL
);
CREATE INDEX idx_enc_patient ON encounter(patient_id);
CREATE INDEX idx_enc_hosp    ON encounter(hospital_id);
CREATE INDEX idx_enc_admit   ON encounter(admit_dt);

CREATE TABLE encounter_provider (
  encounter_id  INTEGER NOT NULL,
  provider_id   INTEGER NOT NULL,
  provider_role TEXT,
  PRIMARY KEY (encounter_id, provider_id),
  FOREIGN KEY (encounter_id) REFERENCES encounter(encounter_id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id)  REFERENCES provider(provider_id)   ON DELETE RESTRICT
);

-- ===== App RBAC =====
CREATE TABLE app_user (
  user_id        INTEGER PRIMARY KEY,
  username       TEXT UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,
  display_name   TEXT
);

CREATE TABLE app_role (
  role_id    INTEGER PRIMARY KEY,
  role_name  TEXT UNIQUE NOT NULL CHECK (role_name IN ('admin','manager','doctor','nurse','viewer'))
);

CREATE TABLE app_user_role (
  user_id INTEGER NOT NULL,
  role_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES app_user(user_id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES app_role(role_id) ON DELETE CASCADE
);

CREATE TABLE app_access (
  user_id      INTEGER NOT NULL,
  encounter_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, encounter_id),
  FOREIGN KEY (user_id)      REFERENCES app_user(user_id)      ON DELETE CASCADE,
  FOREIGN KEY (encounter_id) REFERENCES encounter(encounter_id) ON DELETE CASCADE
);

-- ===== Audit & demo soft-delete target =====
CREATE TABLE audit_log (
  audit_id    INTEGER PRIMARY KEY,
  table_name  TEXT NOT NULL,
  row_id      TEXT NOT NULL,
  action      TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  changed_at  TEXT NOT NULL DEFAULT (datetime('now')),
  changed_by  INTEGER,
  payload     TEXT
);

CREATE TABLE emr_document (
  doc_id        INTEGER PRIMARY KEY,
  encounter_id  INTEGER NOT NULL,
  patient_id    INTEGER NOT NULL,
  doc_type      TEXT,
  status        TEXT,
  author_id     INTEGER,
  created_dt    TEXT,
  storage_uri   TEXT NOT NULL,
  sha256        TEXT UNIQUE,
  deleted_at    TEXT,
  deleted_by    INTEGER,
  FOREIGN KEY (encounter_id) REFERENCES encounter(encounter_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id)   REFERENCES patient(patient_id)     ON DELETE CASCADE,
  FOREIGN KEY (author_id)    REFERENCES provider(provider_id)   ON DELETE SET NULL
);

CREATE TRIGGER trg_emr_document_soft_delete
BEFORE DELETE ON emr_document
FOR EACH ROW
BEGIN
  UPDATE emr_document
     SET deleted_at = COALESCE(deleted_at, datetime('now'))
   WHERE doc_id = OLD.doc_id;

  INSERT INTO audit_log(table_name, row_id, action, payload)
  VALUES ('emr_document', CAST(OLD.doc_id AS TEXT), 'DELETE', 'soft-delete');

  SELECT RAISE(IGNORE);
END;
