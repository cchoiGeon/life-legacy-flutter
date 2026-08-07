-- =============================================================================
-- 20260806_04 — device_push_token last_used_at / revoked_at
-- 근거: erd/new-erd.dbml Table device_push_token · api-spec §7.3
-- =============================================================================

BEGIN;

ALTER TABLE device_push_token
  ADD COLUMN IF NOT EXISTS last_used_at timestamptz;

ALTER TABLE device_push_token
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz;

COMMIT;
