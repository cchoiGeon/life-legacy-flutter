-- 약관·개인정보·환불정책 본문(markdown)을 DB에 보관
-- consent_document.content · is_consent_item

ALTER TABLE consent_document
  ADD COLUMN IF NOT EXISTS content text NULL,
  ADD COLUMN IF NOT EXISTS is_consent_item boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN consent_document.content IS '마크다운 본문. 가입 동의·설정 열람용';
COMMENT ON COLUMN consent_document.is_consent_item IS 'true면 가입 시 동의 체크리스트에 노출';
