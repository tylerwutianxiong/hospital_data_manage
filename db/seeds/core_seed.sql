INSERT INTO hospital (name, short_name, region) VALUES
  ('PolyU Affiliated Hospital', 'PAH', 'HK');

INSERT INTO app_role (role_name) VALUES
  ('admin'), ('manager'), ('doctor'), ('nurse'), ('viewer');

INSERT INTO app_user (username, password_hash, display_name) VALUES
  ('admin', 'demo-hash', 'Administrator'),
  ('dr_lee', 'demo-hash', 'Dr Lee');

INSERT INTO app_user_role (user_id, role_id)
SELECT u.user_id, r.role_id
FROM app_user u, app_role r
WHERE u.username='admin' AND r.role_name='admin';

INSERT INTO patient (hospital_id, mrn, given_name, family_name, sex, dob)
VALUES (1, 'MRN0001', 'Ann', 'Chan', 'F', '1990-01-01');

INSERT INTO provider (hospital_id, npi, given_name, family_name, role, department)
VALUES (1, 'NPI001', 'Henry', 'Lee', 'physician', 'IM');

INSERT INTO location (hospital_id, name, loc_type)
VALUES (1, 'OPD-101', 'outpatient');

INSERT INTO encounter (patient_id, hospital_id, location_id, admit_dt, enc_type, status)
VALUES (1, 1, 1, datetime('now'), 'outpatient', 'open');

INSERT INTO encounter_provider (encounter_id, provider_id, provider_role)
VALUES (1, 1, 'attending');

INSERT INTO emr_document (encounter_id, patient_id, doc_type, status, author_id, created_dt, storage_uri, sha256)
VALUES (1, 1, 'progress', 'signed', 1, datetime('now'), 's3://bucket/demo1.txt', 'sha256-demo-1');
