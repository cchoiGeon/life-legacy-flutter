# DBML 문법 요약 (dbdiagram.io)

[DBML](https://dbml.dbdiagram.io/docs)은 dbdiagram.io에서 사용하는 데이터베이스 정의 언어입니다. 아래는 ERD 추출 시 자주 쓰는 문법만 정리한 것입니다.

## 테이블 (Tables & Fields)

- 공식: [Tables & Fields | dbdiagram Docs](https://docs.dbdiagram.io/tables)

```dbml
Table 테이블명 {
  컬럼명 타입 [설정들]
}
```

- **기본 스키마**: 스키마를 안 쓰면 `public` 스키마로 간주됩니다.
- **다른 스키마**: `Table 스키마명.테이블명 { ... }` (예: `Table core.users { ... }`)

### 컬럼 타입

- 한 단어로 쓰기 (공백 없음). 예: `int`, `integer`, `varchar`, `varchar(255)`, `text`, `datetime`, `timestamp`, `boolean`, `decimal(1,2)`, `json`, `jsonb` 등.

### 컬럼 설정 (대괄호 `[]`)

| 설정 | 의미 |
|------|------|
| `primary key` / `pk` | 기본키 |
| `not null` | NOT NULL |
| `unique` | 유니크 |
| `default: 값` | 기본값 (숫자 그대로, 문자열은 `'...'`, 함수는 백틱 `` `now()` ``) |
| `note: '설명'` | 컬럼 설명(호버 시 표시) |

예:

```dbml
Table users {
  id int [pk]
  email varchar(255) [unique, not null]
  created_at timestamp [default: `now()`]
  body text [note: 'Content of the post']
}
```

### 테이블 노트

```dbml
Table users {
  id int [pk]
  name varchar
  Note: 'Stores user data'
}
```

---

## 관계 (Relationships)

- 공식: [Relationships | dbdiagram Docs](https://docs.dbdiagram.io/relationships)

**주의:** 하나의 관계를 **인라인(ref:)** 과 **Ref: 한 줄** 둘 다로 정의하면 "References with same endpoints exist" 오류가 납니다. **둘 중 하나만** 사용하세요. 권장: 컬럼에는 `[not null]` 등만 쓰고, 관계는 파일 하단의 `Ref:` 한 줄로만 정의.

### 관계 기호

| 기호 | 의미 | 예 |
|------|------|-----|
| `>` | many-to-one | `posts.user_id > users.id` |
| `<` | one-to-many | `users.id < posts.user_id` |
| `-` | one-to-one | `users.id - user_infos.user_id` |
| `<>` | many-to-many | `authors.id <> books.id` |

### 작성 방법

**1) Ref 한 줄 (Short form) — 권장**

한 관계당 `Ref:` 한 줄만 사용하고, 테이블 정의의 컬럼에는 `ref:`를 넣지 않습니다. (같은 관계를 인라인과 Ref 둘 다 쓰면 오류 발생.)

```dbml
Table posts {
  id integer [pk]
  user_id integer [not null]
}
Ref: posts.user_id > users.id
```

**2) 인라인 (테이블 정의 안에서)**

인라인을 쓰면 같은 관계를 아래에서 `Ref:`로 다시 정의하면 안 됩니다.

```dbml
Table posts {
  id integer [pk]
  user_id integer [ref: > users.id]
  ...
}
```

**3) Long form**

```dbml
Ref user_posts {
  posts.user_id > users.id
}
```

- 스키마를 쓰는 경우: `Ref: blog.posts.user_id > core.users.id` 처럼 `스키마.테이블.컬럼`으로 씁니다.

---

## 스키마 (Schemas)

- 공식: [Schemas | dbdiagram Docs](https://docs.dbdiagram.io/schemas)

- 테이블을 특정 스키마에 두려면 `스키마명.테이블명`으로 정의합니다.

```dbml
Table ecommerce.order_items {
  id int [pk]
  order_id int
  ...
}

Table orders {
  id int [pk]
  status core.order_status
  ...
}

Enum core.order_status {
  pending
  shipped
}
```

- 스키마를 붙이지 않으면 `public` 스키마입니다.

---

## 샘플 데이터 (Records)

- [DBML Data Sample](https://dbml.dbdiagram.io/docs#data-sample) 참고.

```dbml
Table users {
  id integer [pk]
  username varchar
  role varchar
  created_at timestamp
}

Records users(id, username, role) {
  0, 'Alice', 'admin'
  1, 'Bob', 'moderator'
}

Records posts(id, title, user_id) {
  0, 'Welcome to the forum!', 0
  1, 'Guidelines', 1
}
```

- **문자열**: 작은따옴표 `'...'`, 안에 작은따옴표는 `\'`로 이스케이프.
- **숫자**: 그대로 (예: `0`, `1`, `3.14`).
- **날짜/시간**: 작은따옴표 (예: `'2026-01-01'`, `'2026-02-28'`).
- **NULL**: `null` 또는 빈 값.
- **함수/식**: 백틱 (예: `` `now()` ``).

---

## 전체 예시 (dbdiagram.io에 붙여넣기용)

```dbml
// Use DBML to define your database structure
// Docs: https://dbml.dbdiagram.io/docs

Table follows {
  following_user_id integer
  followed_user_id integer
  created_at timestamp
}

Table users {
  id integer [primary key]
  username varchar
  role varchar
  created_at timestamp
}

Table posts {
  id integer [primary key]
  title varchar
  body text [note: 'Content of the post']
  user_id integer [not null]
  status varchar
  created_at timestamp
}

Ref: posts.user_id > users.id
Ref: users.id < follows.following_user_id
Ref: users.id < follows.followed_user_id

Records users(id, username, role) {
  0, 'Alice', 'admin'
  1, 'Bob', 'moderator'
  2, 'Candice', 'moderator'
  3, 'David', 'member'
}

Records follows(following_user_id, followed_user_id, created_at) {
  1, 0, '2026-01-01'
  3, 2, '2026-02-28'
}

Records posts(id, title, user_id) {
  0, 'Welcome to the forum!', 0
  1, 'Guidelines', 1
  2, 'Hello all!', 3
}
```

이 내용을 [dbdiagram.io](https://dbdiagram.io/d)에 붙여넣으면 다이어그램으로 렌더링됩니다.
