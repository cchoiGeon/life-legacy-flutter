-- 카카오 등 소셜 로그인 계정 연결
-- social_account: app_user 1:N provider 계정 (provider + provider_user_id 유니크)

CREATE TABLE IF NOT EXISTS social_account (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  provider varchar(20) NOT NULL,
  provider_user_id varchar(100) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_social_provider_uid
  ON social_account (provider, provider_user_id);

CREATE INDEX IF NOT EXISTS ix_social_account_user
  ON social_account (user_id);
