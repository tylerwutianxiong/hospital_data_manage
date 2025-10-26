# Schema Conventions
- snake_case；主键 `<entity>_id` (INTEGER)
- 跨院区带 `hospital_id` → hospital(hospital_id)
- 时间列：`*_date` / `*_dt`（ISO 字符串）
- 删除：优先软删（`deleted_at`）+ 审计表（`audit_log`）
- 外键：向上 RESTRICT/SET NULL；从 encounter 向下 CASCADE
- 给 FK/高频查询列建索引
