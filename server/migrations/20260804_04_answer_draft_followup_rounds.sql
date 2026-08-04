-- 꼬리질문 3라운드용 draft 확장 (erd answer_draft)

ALTER TABLE answer_draft
  ADD COLUMN IF NOT EXISTS followup_round smallint NOT NULL DEFAULT 0;

ALTER TABLE answer_draft
  ADD COLUMN IF NOT EXISTS followups jsonb;
