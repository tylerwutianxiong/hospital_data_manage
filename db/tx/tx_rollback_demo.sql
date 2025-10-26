-- db/tx/tx_rollback_demo.sql
PRAGMA foreign_keys = ON;

BEGIN;

-- 故意用重复的 MRN 触发唯一性失败（你已有 MRN=MRN0001 的病人）
INSERT INTO patient (hospital_id, mrn, given_name, family_name, sex)
VALUES (1, 'MRN0001', 'Dup', 'Test', 'M');

-- 如果上面的语句报错，事务会自动回滚到 BEGIN 之前
COMMIT;
