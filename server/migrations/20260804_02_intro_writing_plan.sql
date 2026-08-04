-- =============================================================================
-- 20260804_02 — intro 확장 · writing_plan
-- 근거: erd/new-erd.dbml §2 · api-spec §2.1·§2.6
-- =============================================================================

BEGIN;

DO $$ BEGIN
  CREATE TYPE intro_answer_type AS ENUM ('text', 'choice', 'date', 'multi_choice');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE intro_question
  ADD COLUMN IF NOT EXISTS answer_type intro_answer_type NOT NULL DEFAULT 'choice';

ALTER TABLE intro_question
  ADD COLUMN IF NOT EXISTS is_skippable boolean NOT NULL DEFAULT false;

-- 선택지 상세 (학업 단계 → 학사/석사/박사 등)
ALTER TABLE intro_choice
  ADD COLUMN IF NOT EXISTS parent_choice_id uuid;

ALTER TABLE intro_choice
  DROP CONSTRAINT IF EXISTS ux_intro_choice_order;

DROP INDEX IF EXISTS ux_intro_choice_order;

CREATE UNIQUE INDEX ux_intro_choice_order
  ON intro_choice (
    intro_question_id,
    (COALESCE(parent_choice_id, '00000000-0000-0000-0000-000000000000'::uuid)),
    sort_order
  );

CREATE INDEX IF NOT EXISTS ix_intro_choice_parent ON intro_choice (parent_choice_id);

ALTER TABLE intro_choice
  ADD CONSTRAINT fk_intro_choice_parent
  FOREIGN KEY (parent_choice_id) REFERENCES intro_choice(id) ON DELETE CASCADE;

ALTER TABLE user_intro_answer
  ADD COLUMN IF NOT EXISTS detail_choice_id uuid;

ALTER TABLE user_intro_answer
  ADD COLUMN IF NOT EXISTS value_json jsonb;

ALTER TABLE user_intro_answer
  ADD COLUMN IF NOT EXISTS is_skipped boolean NOT NULL DEFAULT false;

ALTER TABLE user_intro_answer
  ADD CONSTRAINT fk_user_intro_answer_detail
  FOREIGN KEY (detail_choice_id) REFERENCES intro_choice(id) ON DELETE SET NULL;

ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS birth_date date;

ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS education_detail varchar(30);

CREATE TABLE IF NOT EXISTS writing_plan (
  user_id uuid PRIMARY KEY REFERENCES app_user(id) ON DELETE CASCADE,
  daily_minutes smallint NOT NULL,
  available_weekdays jsonb NOT NULL,
  available_periods jsonb NOT NULL,
  duration_weeks smallint NOT NULL,
  duration_source varchar(12) NOT NULL,
  alarm_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- i1 비활성 (성함은 가입 이름 사용)
UPDATE intro_question SET is_active = false WHERE code = 'i1';

-- 성별 라벨 갱신
UPDATE intro_choice c
SET label = CASE c.label WHEN '남성' THEN '남' WHEN '여성' THEN '여' ELSE c.label END
FROM intro_question q
WHERE c.intro_question_id = q.id AND q.code = 'i2';

UPDATE intro_question SET is_skippable = true WHERE code IN ('i3', 'i4');
UPDATE intro_question SET answer_type = 'choice' WHERE code IN ('i2', 'i3', 'i4', 'i5');

-- 생년월일 문항 (없으면 추가)
INSERT INTO intro_question (id, code, sort_order, text, subtitle, hint, answer_type, is_skippable, axis, is_active, created_at, updated_at)
SELECT gen_random_uuid(), 'i6', 2, E'생년월일을\n알려주세요', NULL, NULL, 'date', false, 'always', true, now(), now()
WHERE NOT EXISTS (SELECT 1 FROM intro_question WHERE code = 'i6');

-- 기존 문항 순서 재정렬: i2=1, i6=2, i3=3, i4=4, i5=5
UPDATE intro_question SET sort_order = 1 WHERE code = 'i2' AND is_active;
UPDATE intro_question SET sort_order = 2 WHERE code = 'i6';
UPDATE intro_question SET sort_order = 3 WHERE code = 'i3' AND is_active;
UPDATE intro_question SET sort_order = 4 WHERE code = 'i4' AND is_active;
UPDATE intro_question SET sort_order = 5 WHERE code = 'i5' AND is_active;

COMMIT;
