-- 2026-08-06 qna_question
-- 사용자 문의. FAQ는 테이블 없이 읽기 전용 응답으로 제공한다.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'qna_status') THEN
    CREATE TYPE qna_status AS ENUM (
      'pending',
      'answered',
      'published',
      'closed'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS qna_question (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  category varchar(30),
  question text NOT NULL,
  status qna_status NOT NULL DEFAULT 'pending',
  answer text,
  answered_by varchar(100),
  answered_at timestamptz,
  admin_note text,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_qna_status_created
  ON qna_question (status, created_at);

CREATE INDEX IF NOT EXISTS ix_qna_user
  ON qna_question (user_id);
