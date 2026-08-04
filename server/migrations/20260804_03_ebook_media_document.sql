-- 2026-08-04 ebook PDF + media_kind.document
-- PostgreSQL enum에 document 값 추가. ebook_export/media_asset는 엔티티로 동기화되는 환경도 있음.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'media_kind') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_enum e
      JOIN pg_type t ON e.enumtypid = t.oid
      WHERE t.typname = 'media_kind' AND e.enumlabel = 'document'
    ) THEN
      ALTER TYPE media_kind ADD VALUE 'document';
    END IF;
  END IF;
END $$;
