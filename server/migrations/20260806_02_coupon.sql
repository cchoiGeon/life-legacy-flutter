-- 쿠폰 코드 발급·교환
-- coupon: 관리자가 발급하는 플랜 코드 (T1~T4)
-- coupon_redemption: 사용자별 1회 교환 기록

CREATE TABLE IF NOT EXISTS coupon (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(40) NOT NULL,
  plan_code varchar(10) NOT NULL,
  max_redemptions int NULL,
  redemption_count int NOT NULL DEFAULT 0,
  expires_at timestamptz NULL,
  note text NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ck_coupon_plan_code CHECK (plan_code IN ('T1', 'T2', 'T3', 'T4')),
  CONSTRAINT ck_coupon_max_redemptions CHECK (
    max_redemptions IS NULL OR max_redemptions > 0
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_coupon_code
  ON coupon (upper(code));

CREATE TABLE IF NOT EXISTS coupon_redemption (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id uuid NOT NULL REFERENCES coupon (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  plan_code varchar(10) NOT NULL,
  redeemed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ux_coupon_redemption_user UNIQUE (coupon_id, user_id)
);

CREATE INDEX IF NOT EXISTS ix_coupon_redemption_user
  ON coupon_redemption (user_id);
