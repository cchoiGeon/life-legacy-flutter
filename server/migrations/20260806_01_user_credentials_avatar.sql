-- 아이디/비밀번호 로그인 + 프로필 아바타
-- app_user에 login_id · password_hash · avatar_object_key 추가

ALTER TABLE app_user
  ADD COLUMN IF NOT EXISTS login_id varchar(50) NULL,
  ADD COLUMN IF NOT EXISTS password_hash text NULL,
  ADD COLUMN IF NOT EXISTS avatar_object_key varchar(255) NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_app_user_login_id
  ON app_user (login_id)
  WHERE login_id IS NOT NULL AND deleted_at IS NULL;
