-- =============================================================================
-- 20260806_03 — media_asset / media_placement (챕터 리뷰 다중 사진)
-- 근거: erd/new-erd.dbml media_asset · media_placement
--
-- 전제
--   · PostgreSQL
--   · book, chapter_review 테이블이 이미 존재
--   · 파일 바이너리는 DB BYTEA가 아니라 object_key(로컬/객체 저장소)
--
-- 실행
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f 20260806_03_media_asset_placement.sql
-- =============================================================================

BEGIN;

DO $$ BEGIN
  CREATE TYPE media_kind AS ENUM ('image', 'audio', 'video', 'document');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE media_source AS ENUM ('user_upload', 'ai_generated', 'system');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ebook 마이그레이션이 먼저 돌았을 수 있음 — document 누락 시 보강
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

CREATE TABLE IF NOT EXISTS media_asset (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id uuid NOT NULL REFERENCES book (id) ON DELETE CASCADE,
  kind media_kind NOT NULL,
  source media_source NOT NULL,
  object_key varchar(500) NOT NULL,
  mime_type varchar(100) NOT NULL,
  byte_size bigint NOT NULL,
  checksum varchar(128),
  duration_ms integer,
  expires_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_media_asset_book
  ON media_asset (book_id, kind);

CREATE TABLE IF NOT EXISTS media_placement (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chapter_review_id uuid NOT NULL REFERENCES chapter_review (id) ON DELETE CASCADE,
  media_asset_id uuid NOT NULL REFERENCES media_asset (id) ON DELETE CASCADE,
  paragraph_index integer NOT NULL,
  anchor varchar(200),
  sort_order smallint NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_media_placement_order
  ON media_placement (chapter_review_id, paragraph_index, sort_order);

COMMIT;
