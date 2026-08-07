-- =============================================================================
-- 20260806_02 — notification.book_id (다권 딥링크)
-- 근거: erd/new-erd.dbml Table notification · api-spec §7 확정 대기 딥링크
-- =============================================================================

BEGIN;

ALTER TABLE notification
  ADD COLUMN IF NOT EXISTS book_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_notification_book'
  ) THEN
    ALTER TABLE notification
      ADD CONSTRAINT fk_notification_book
      FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE;
  END IF;
END $$;

COMMIT;
