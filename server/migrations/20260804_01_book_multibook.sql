-- =============================================================================
-- 20260804_01 — 다권 book 전환
-- 근거: erd/new-erd.dbml 마이그레이션 노트 · api-spec §0.6 (레거시 경로 제거)
--
-- 전제
--   · PostgreSQL
--   · v1: book.user_id PK, user_chapter.user_id, book_page.user_id
--   · 점검 창에서 실행. DB_SYNCHRONIZE=true 환경과 병행하지 말 것
--
-- 실행
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f 20260804_01_book_multibook.sql
--
-- 롤백
--   6·7 단계 이전까지는 가능. 이 파일 하단 COMMENT 참고.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 0) chapter_source enum
-- -----------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE chapter_source AS ENUM ('template', 'custom');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- 1) book: id · owner_user_id 추가 · 기존 행 id 채움
-- -----------------------------------------------------------------------------
ALTER TABLE book ADD COLUMN IF NOT EXISTS id uuid;
ALTER TABLE book ADD COLUMN IF NOT EXISTS owner_user_id uuid;

UPDATE book
SET id = gen_random_uuid(),
    owner_user_id = user_id
WHERE id IS NULL;

ALTER TABLE book ALTER COLUMN id SET NOT NULL;
ALTER TABLE book ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE book ALTER COLUMN owner_user_id SET NOT NULL;

-- -----------------------------------------------------------------------------
-- 2) 검증: 행마다 id·owner 가 있는지
-- -----------------------------------------------------------------------------
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing FROM book WHERE id IS NULL OR owner_user_id IS NULL;
  IF missing > 0 THEN
    RAISE EXCEPTION 'book backfill incomplete: % rows missing id/owner', missing;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3) user_chapter.book_id · source_type
-- -----------------------------------------------------------------------------
ALTER TABLE user_chapter ADD COLUMN IF NOT EXISTS book_id uuid;
ALTER TABLE user_chapter ADD COLUMN IF NOT EXISTS source_type chapter_source NOT NULL DEFAULT 'template';

UPDATE user_chapter uc
SET book_id = b.id
FROM book b
WHERE uc.user_id = b.user_id
  AND uc.book_id IS NULL;

DO $$
DECLARE orphan int;
BEGIN
  SELECT count(*) INTO orphan FROM user_chapter WHERE book_id IS NULL;
  IF orphan > 0 THEN
    -- 목차만 있고 book 행이 없는 사용자 → book 행을 만들어 붙인다
    INSERT INTO book (id, owner_user_id, user_id, title, author_name, page_count, photo_count, is_complete)
    SELECT gen_random_uuid(), uc.user_id, uc.user_id, '나의 이야기',
           COALESCE(u.name, '나의 이야기'), 0, 0, false
    FROM (SELECT DISTINCT user_id FROM user_chapter WHERE book_id IS NULL) uc
    JOIN app_user u ON u.id = uc.user_id
    WHERE NOT EXISTS (SELECT 1 FROM book b WHERE b.user_id = uc.user_id);

    UPDATE user_chapter uc
    SET book_id = b.id
    FROM book b
    WHERE uc.user_id = b.user_id AND uc.book_id IS NULL;
  END IF;

  SELECT count(*) INTO orphan FROM user_chapter WHERE book_id IS NULL;
  IF orphan > 0 THEN
    RAISE EXCEPTION 'user_chapter.book_id backfill failed: % orphans', orphan;
  END IF;
END $$;

ALTER TABLE user_chapter ALTER COLUMN book_id SET NOT NULL;

-- -----------------------------------------------------------------------------
-- 4) book_page.book_id
-- -----------------------------------------------------------------------------
ALTER TABLE book_page ADD COLUMN IF NOT EXISTS book_id uuid;

UPDATE book_page bp
SET book_id = b.id
FROM book b
WHERE bp.user_id = b.user_id
  AND bp.book_id IS NULL;

DO $$
DECLARE orphan int;
BEGIN
  SELECT count(*) INTO orphan FROM book_page WHERE book_id IS NULL;
  IF orphan > 0 THEN
    RAISE EXCEPTION 'book_page.book_id backfill failed: % orphans', orphan;
  END IF;
END $$;

ALTER TABLE book_page ALTER COLUMN book_id SET NOT NULL;

-- -----------------------------------------------------------------------------
-- 5) 유니크·인덱스 교체 (book 범위)
-- -----------------------------------------------------------------------------
ALTER TABLE user_chapter DROP CONSTRAINT IF EXISTS ux_user_chapter_order;
DROP INDEX IF EXISTS ux_user_chapter_order;
DROP INDEX IF EXISTS ix_user_chapter_status;
DROP INDEX IF EXISTS ux_user_chapter_writing;

CREATE UNIQUE INDEX ux_user_chapter_order ON user_chapter (book_id, sort_order);
CREATE INDEX ix_user_chapter_status ON user_chapter (book_id, status);
CREATE UNIQUE INDEX ux_user_chapter_writing
  ON user_chapter (book_id) WHERE status = 'writing';

ALTER TABLE book_page DROP CONSTRAINT IF EXISTS ux_book_page_number;
DROP INDEX IF EXISTS ux_book_page_number;

CREATE UNIQUE INDEX ux_book_page_number ON book_page (book_id, page_number);

-- -----------------------------------------------------------------------------
-- 6) user_id 드롭 (장·페이지)
-- -----------------------------------------------------------------------------
ALTER TABLE user_chapter DROP CONSTRAINT IF EXISTS fk_user_chapter_user;
ALTER TABLE user_chapter DROP COLUMN IF EXISTS user_id;

ALTER TABLE book_page DROP CONSTRAINT IF EXISTS fk_book_page_user;
ALTER TABLE book_page DROP COLUMN IF EXISTS user_id;

ALTER TABLE user_chapter
  ADD CONSTRAINT fk_user_chapter_book
  FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE;

ALTER TABLE book_page
  ADD CONSTRAINT fk_book_page_book
  FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE;

-- -----------------------------------------------------------------------------
-- 7) book PK 전환: user_id → id
-- -----------------------------------------------------------------------------
ALTER TABLE book DROP CONSTRAINT IF EXISTS book_pkey;
ALTER TABLE book DROP CONSTRAINT IF EXISTS fk_book_user;

-- user_id 컬럼은 소유자 복제본. owner_user_id로 대체하므로 drop
ALTER TABLE book DROP COLUMN IF EXISTS user_id;

ALTER TABLE book ADD PRIMARY KEY (id);
ALTER TABLE book
  ADD CONSTRAINT fk_book_owner
  FOREIGN KEY (owner_user_id) REFERENCES app_user(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS ix_book_owner ON book (owner_user_id, created_at);

COMMIT;

-- =============================================================================
-- 건수 대조 (커밋 후 수동 확인)
--   SELECT count(*) FROM book;
--   SELECT count(*) FROM user_chapter;
--   SELECT count(*) FROM user_chapter uc
--     LEFT JOIN book b ON b.id = uc.book_id WHERE b.id IS NULL;  -- 0이어야 함
-- =============================================================================
