PRAGMA foreign_keys = ON;

.read db/migrations/V001__core_init.sql
.read db/migrations/V002__lab.sql
.read db/migrations/V003__imaging.sql

-- 后续模块追加：
-- .read db/migrations/V002__lab.sql
-- .read db/migrations/V003__imaging.sql
-- .read db/migrations/V004__orders.sql
-- .read db/migrations/V005__emr_document.sql
-- .read db/migrations/V006__path_anesthesia.sql

.read db/seeds/core_seed.sql
