-- =============================================================================
-- 20260807_05 — media_placement.caption (사진 첨부 G3 설명)
-- 근거: 설계서 G 사진 첨부 (추가 제안)
--
-- 전제
--   · PostgreSQL
--   · media_placement 테이블이 이미 존재 (20260806_03)
--
-- 실행
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f 20260807_05_media_placement_caption.sql
-- =============================================================================

BEGIN;

ALTER TABLE media_placement
  ADD COLUMN IF NOT EXISTS caption text;

-- 책 단위 photo_count 도우미 (업로드/삭제 시 트리거로 갱신 가능, 여기선 수동 갱신 룰)
-- photo_count는 book.entity에 이미 존재. API에서 직접 카운트한다.

COMMIT;
