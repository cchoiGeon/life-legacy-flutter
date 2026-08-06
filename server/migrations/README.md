# DB 마이그레이션

`erd/new-erd.dbml` 구현 계약을 PostgreSQL에 적용하는 SQL입니다.
**`DB_SYNCHRONIZE=true`와 동시에 쓰지 마세요.**

## 순서

| # | 파일 | 내용 |
|---|------|------|
| 1 | `20260804_01_book_multibook.sql` | 다권 `book.id` · `user_chapter.book_id` · `book_page.book_id` |
| 2 | `20260804_02_intro_writing_plan.sql` | intro `answer_type`/`is_skippable` · `writing_plan` · i1 비활성 |
| 3 | `20260806_01_user_credentials_avatar.sql` | `login_id` · `password_hash` · `avatar_object_key` |
| 4 | `20260806_02_coupon.sql` | `coupon` · `coupon_redemption` (T1~T4 쿠폰 코드) |
| 5 | `20260806_03_social_account.sql` | `social_account` (카카오 로그인 계정 연결) |
| 6 | `20260806_04_consent_document_content.sql` | `consent_document.content` · `is_consent_item` (약관 본문) |

## 실행

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f server/migrations/20260804_01_book_multibook.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f server/migrations/20260804_02_intro_writing_plan.sql
```

로컬 Docker 예:

```bash
docker compose exec -T db psql -U lifelegacy -d lifelegacy < server/migrations/20260804_01_book_multibook.sql
```

## 검증

```sql
-- 고아 장 없어야 함
SELECT count(*) FROM user_chapter uc
LEFT JOIN book b ON b.id = uc.book_id WHERE b.id IS NULL;

-- book PK
SELECT a.attname FROM pg_index i
JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
WHERE i.indrelid = 'book'::regclass AND i.indisprimary;

-- writing_plan 존재
SELECT to_regclass('public.writing_plan');
```

## 새 환경

엔티티가 이미 To-Be라면 synchronize로 스키마를 만들고 seed만 돌려도 됩니다.
이 스크립트는 **v1 As-Is DB → To-Be** 이전용입니다.
