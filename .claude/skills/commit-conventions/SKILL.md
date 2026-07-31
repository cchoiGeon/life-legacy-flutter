---
name: commit-conventions
description: 이 프로젝트에서 사용하는 Git 커밋 메시지 형식과 규칙. 커밋을 남길 때 항상 이 형식을 따릅니다.
---

# 커밋 메시지 컨벤션

이 프로젝트에서 커밋 메시지는 **Conventional Commits** 스타일을 따르며, 요약은 **한국어**로 작성합니다.

## 형식

```
<type>(<scope>): <요약 (한국어)>

- 선택: 상세 내용 불릿
- 선택: 변경 파일/기능 요약
```

- **한 줄 요약**: 72자 이내. 마침표 생략.
- **본문**: 필요 시 빈 줄 뒤 불릿으로 추가 설명.

## Type

| type | 용도 |
|------|------|
| **feat** | 새로운 기능 |
| **fix** | 버그 수정 |
| **refactor** | 리팩터링 (동작 변경 없음) |
| **chore** | 빌드, 설정, 기타 자동화 |
| **docs** | 문서만 변경 |
| **style** | 코드 스타일/포맷 (로직 변경 없음) |

## Scope

변경이 일어난 **도메인 또는 모듈**을 괄호 안에 씁니다.

- 예: `users`, `open-api`, `auth`, `message`

## 예시

```
feat(users): PATCH me 비밀번호 전용 수정, Application 추가/이름 존재 API 분리

- PATCH me: newPassword 필수로 비밀번호만 수정 (applicationName 제거)
- POST me/applications: 플랜별 한도·이름 중복 검증 후 애플리케이션 추가
- GET me/applications/name-exists: 애플리케이션 이름 존재 여부 조회
```

```
feat(open-api): API 호출 시 api-usage-monthly 갱신 및 Plan별 월 한도 검사

- UsersService: getUserIdByApiKey, recordApiCall(userId), checkApiCallLimit(apiKey) 추가
- MessageService: 호출 시 getUserIdByApiKey → recordApiCall로 당월 사용량 1 증가
- Guard: API Key 검증 후 checkApiCallLimit 호출, 한도 초과 시 429 반환
```

```
feat(users): 애플리케이션 이름 검증 추가 (공백 불가, 영문/숫자/_- 만 허용)

- application-name-validation.const: 패턴 및 에러 메시지 상수
- CreateApplicationDto, CheckApplicationNameExistsDto에 @Matches 적용
```

```
fix(auth): 이메일 인증 코드 만료 시 400 메시지 정정
```

```
chore: eslint rule no-console 추가
```

## 적용 시점

- 사용자가 "커밋 남겨줘", "commit 추가" 등으로 커밋을 요청할 때 이 형식으로 메시지를 작성합니다.
- 여러 변경이 한 커밋에 포함될 경우, 요약 한 줄 뒤 불릿으로 항목을 나열합니다.
