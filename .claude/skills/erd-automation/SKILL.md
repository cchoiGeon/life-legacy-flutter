---
name: erd-automation
description: DB 스키마가 변경될 때 기존 스키마와 변경된 스키마에 대한 ERD를 DBML 형식으로 추출합니다. dbdiagram.io에서 사용 가능한 코드를 생성하며, erd/ 폴더에 previous-erd.dbml(기존), new-erd.dbml(신규) 파일로 저장합니다. Use when the user mentions ERD extraction, schema diff, database diagram, or documenting schema changes.
compatibility: Requires ability to read schema definitions (TypeORM entities, Mongoose schemas, SQL DDL, etc.) and write files. Designed for NestJS/Node projects with database.
---

# ERD 자동화 스킬

DB 스키마 변경 시 **기존 스키마**와 **변경된 스키마**에 대한 ERD를 [dbdiagram.io](https://dbdiagram.io/d)에서 사용 가능한 **DBML(Database Markup Language)** 코드로 추출해 파일로 저장합니다.

## 사용 시점

- 사용자가 DB 스키마 변경, ERD 추출, 스키마 비교, DB 다이어그램 문서화를 요청할 때
- "ERD 뽑아줘", "스키마 변경 전후 ERD", "dbdiagram으로 보여줘" 등과 같은 요청일 때

## 출력 위치 및 파일

1. **폴더**: 프로젝트 루트에 `erd/` 폴더를 사용합니다. **이미 존재하면 새로 만들지 않습니다.**
2. **파일명**:
   - **기존(변경 전) 스키마**: `erd/previous-erd.dbml`
   - **신규(변경 후) 스키마**: `erd/new-erd.dbml`
3. **확장자**: `.dbml` — dbdiagram.io에서 그대로 붙여넣기 가능한 형식입니다.

## 작업 순서

1. **현재 스키마 파악**
   - TypeORM 엔티티(`*.entity.ts`), Mongoose 스키마(`*.schema.ts`), 또는 SQL 마이그레이션/DDL을 읽어 테이블·컬럼·관계를 파악합니다.

2. **erd/ 폴더**
   - 프로젝트 루트에 `erd/`가 없을 때만 생성합니다. 이미 있으면 생성하지 않습니다.

3. **previous-erd.dbml**
   - **변경 전(현재 적용 중인) 스키마**를 DBML로 작성해 `erd/previous-erd.dbml`에 저장합니다.
   - 사용자가 “변경할 스키마”를 명시한 경우, 그 **이전 상태**를 previous로 간주합니다.

4. **new-erd.dbml**
   - **변경 후(목표) 스키마**를 DBML로 작성해 `erd/new-erd.dbml`에 저장합니다.
   - 사용자가 제안한 수정사항이나, 코드/마이그레이션에 반영된 새 스키마를 반영합니다.

5. **DBML 문법**
   - 테이블, 컬럼, PK, 관계(Ref), 필요 시 Note·Records(샘플 데이터)까지 [DBML 스펙](https://dbml.dbdiagram.io/docs)에 맞게 작성합니다.
   - 상세 문법은 [references/dbml-syntax.md](references/dbml-syntax.md)를 참고합니다.

## DBML 작성 시 유의사항

- **테이블**: `Table 테이블명 { 컬럼 타입 [pk], ... }`
- **관계**: FK 컬럼에는 `[not null]` 등만 쓰고, 관계는 **파일 하단에서 `Ref:` 한 줄로만** 정의한다. 같은 관계를 컬럼 인라인(`ref: >`)과 `Ref:` 둘 다 쓰면 "References with same endpoints exist" 오류가 난다. 예: `Ref: 자식테이블.컬럼 > 부모테이블.컬럼`
- **스키마**: 다른 스키마를 쓰면 `Table 스키마명.테이블명 { ... }` 형태로 작성
- **문자열/날짜**: Records에서 문자열·날짜는 작은따옴표로 감쌈 (예: `'2026-01-01'`)
- dbdiagram.io에 붙여넣었을 때 오류 없이 렌더링되는지 문법을 맞출 것

## 참고 자료

- [references/dbml-syntax.md](references/dbml-syntax.md) — 테이블, 관계, 스키마, Records 요약
- [dbdiagram.io](https://dbdiagram.io/d) — DBML 붙여넣기 및 시각화
- [DBML 공식 문서](https://dbml.dbdiagram.io/docs)
- [dbdiagram Tables & Fields](https://docs.dbdiagram.io/tables), [Relationships](https://docs.dbdiagram.io/relationships), [Schemas](https://docs.dbdiagram.io/schemas)

## 출력 예시 (형식만 참고)

```dbml
// erd/previous-erd.dbml 또는 erd/new-erd.dbml

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

Ref: posts.user_id > users.id // many-to-one
```

Records(샘플 데이터)가 필요하면 동일 파일 하단에 `Records 테이블명(컬럼들) { ... }` 형태로 추가할 수 있습니다.
