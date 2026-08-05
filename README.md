# Life Legacy

> 말씀만 하시면 AI가 한 권의 자서전으로 써 드려요.

시니어 사용자가 **말로 답하면** AI가 자서전 문체로 다듬어 한 권의 책으로 엮어주는 앱.

- **디자인**: Figma `PickDam` — **[★★ 최종 · A~F 전체 (C+ 방향) `340:592`](https://www.figma.com/design/apsdRjQLt8xVVMbxzU60HC/PickDam?node-id=340-592)** 가 현재 기준이다.
  디자인 시스템 [`130:2`](https://www.figma.com/design/apsdRjQLt8xVVMbxzU60HC/PickDam?node-id=130-2) 는 토큰 출처로만 남아 있고,
  예전 UI [`134:2`](https://www.figma.com/design/apsdRjQLt8xVVMbxzU60HC/PickDam?node-id=134-2) 는 **더 이상 따르지 않는다.**
  파일명 `PickDam`은 회사 계정 파일이라 바꿀 수 없다 — 프로젝트명은 **LifeLegacy**다. 문서에 남은 `PickDam`은 전부 이 Figma 파일을 가리킨다.
- **스택**: Flutter + GetX (Pickle · IAM_flutter와 동일 구조)
- **API**: NestJS `/v1` — `RealApiClient`(dio). 빈 데이터는 서버 응답대로 비어 보이거나 생성 플로우로 이어진다(목업 시드 없음).

## 실행

로컬 Nest가 `http://localhost:3000` 에서 떠 있어야 한다.

### 1. DB · 서버

PostgreSQL에 DB `life_legacy`가 있어야 한다. 로컬 기본 계정은 `server/.env.local`을 따른다.

```bash
cd server
npm install
npm run start:local   # Nest watch · NODE_ENV=local · :3000
# (최초/시드 갱신) npm run seed
```

- API: `http://localhost:3000/v1`
- Swagger: `http://localhost:3000/docs`
- DB 구조 요약: [`docs/db-schema.md`](docs/db-schema.md) · ERD DBML: [`erd/new-erd.dbml`](erd/new-erd.dbml)

### 2. Flutter 앱

```bash
# 레포 루트
flutter pub get
```

| 환경 | 명령 | API baseUrl |
|---|---|---|
| **Android 에뮬레이터** | 아래 「에뮬」 참고 후 `flutter run` | 기본 `http://10.0.2.2:3000/v1` (에뮬→호스트 PC) |
| **Chrome / Edge (브라우저)** | `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/v1` | **반드시** `localhost` (기본값 10.0.2.2는 브라우저에서 안 됨) |
| **실기기** | `flutter run --dart-define=API_BASE_URL=http://<PC_IP>:3000/v1` | PC LAN IP |

#### Android 에뮬레이터

```bash
flutter emulators                         # 목록
flutter emulators --launch Pixel_6_API_34 # 기동 (이름에 맞게)
flutter devices                           # emulator-5554 등이 보여야 함
flutter run
```

에뮬이 꺼져 있으면 `No supported devices connected`가 난다. Windows/Chrome만 보이는 건 이 프로젝트가 **Android·iOS·web**만 쓰도록 잡혀 있어서다(desktop 미지원).

#### 브라우저 (Chrome / Edge)

웹 플랫폼(`web/`)이 있어야 한다. 없으면:

```bash
flutter create . --platforms=web
```

실행:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/v1
# 또는
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:3000/v1
```

#### 포트가 이미 쓰일 때 (서버)

```text
Error: listen EADDRINUSE :::3000
```

→ `3000`을 쓰는 기존 Node를 종료한 뒤 `npm run start:local`을 다시 돌린다.

인증은 OCTOMO SMS(앱) · 웹 ID/PW 등은 서버·화면 MD를 따른다. 목업 고정 코드(`482915`)는 없다.

> **형제 프로젝트:** 웹 lifelegacy는 `C:\Users\laptop\Desktop\lifelegacy` (Neon DB).  
> 이 Flutter/Nest 앱의 로컬 DB는 `life_legacy`다. 서로 다른 DB다.

## 구조

IAM_flutter와 같은 배치다. 화면 하나 = `binding` + `controller` + `view` 세 파일.

```
lib/
├── common/
│   ├── constants/          colors · typography · dimens (Figma 토큰 이식)
│   └── widgets/ds/         디자인 시스템 위젯 (ds.dart 하나만 import)
├── core/
│   ├── network/
│   │   ├── api_client.dart       ← 추상 인터페이스
│   │   ├── real_api_client.dart  ← Nest `/v1` 구현
│   │   └── api_env.dart          ← API_BASE_URL · 타임아웃
│   └── route/              app_pages.dart + app_routes.dart
├── data/
│   ├── models/ · enums/    plain Dart. fromJson/toJson 수동 작성
│   ├── storage.dart        GetStorage 래퍼 (토큰 · 온보딩 통과 여부)
│   └── data_manager.dart   barrel — 화면은 이것만 import
├── feature/<화면>/         binding · controller · view
└── service/                AuthService · ToastService (전역 싱글턴)
```

## 화면 ↔ Figma 대응

시안(`340:592`) 28개 프레임 중 여럿은 **같은 화면의 다른 상태**라 라우트는 그보다 적다.

| 라우트 | 시안 | 비고 |
|---|---|---|
| `/` | A1 | 버튼 없는 스플래시. 세션을 보고 자동으로 넘어간다 |
| `/login` | A2 | 카카오 · 전화번호 |
| `/login/phone` | A3 · A4 | 입력 전/후. **앱 자체 숫자 키패드** |
| `/login/code` | A5 · A6 | 정상/에러. 6칸 박스 + 3분 타이머 |
| `/intro` | B1~B5 | 1번은 키보드, 2~5번은 고르기 (아래 참고) |
| `/intro/loading` | B6 | 뒤로가기 차단 |
| `/intro/toc` | B7 | 순서 바꾸기 포함 |
| `/home` | C1 · C2 · C3 | 데이터 있음/빈 상태 · 알림 드롭다운(오버레이) |
| `/notifications` | C4 | 홈 드롭다운의 "알림 모두 보기"에서 들어온다 |
| `/write` | D1~D5 | `WriteStage` 4단계 상태 기계 + 저장 실패 상태 |
| `/book` | E1 | |
| `/book/preview` | E2 | 장을 눌러 들어온다. **쪽 단위** 넘김 |
| `/book/complete` | E3 | |
| `/settings` | F1 | |
| `/settings/profile` | F3 | 내 정보 (보기 전용) |
| `/settings/address` | F4 | 인쇄본 배송지 수정 |

시안에 **F2 는 없다.** G 섹션(사진 첨부)은 "추가 제안"이라 아직 만들지 않았다.

### 자기소개 5문항

| # | 질문 | 부제 | 답변 방식 |
|---|---|---|---|
| 1 | 성함을 알려주세요 | 책 표지에 들어갈 이름이에요 | 키보드 입력 |
| 2 | 성별을 알려주세요 | 책에서 부르는 말을 정할 때 써요 | 여성 / 남성 |
| 3 | 결혼은 하셨나요? | 가족 이야기를 여쭤볼 때 참고해요 | 했어요 / 안 했어요 |
| 4 | 자녀가 있으신가요? | 자녀 이야기를 여쭤볼지 정해요 | 있어요 / 없어요 |
| 5 | 학교는 어디까지 다니셨나요? | 학창 시절 질문을 고를 때 써요 | 초등학교 / 중학교 / 고등학교 / 대학교 이상 |

**고르기 문항은 누른다고 넘어가지 않는다.** 고른 값이 크림으로 채워진 채
화면에 남고, 하단 "다음"을 눌러야 넘어간다.

> ⚠️ 예전에는 반대였다(누르는 즉시 이동 · 고른 표시 없음). 5번이 4지선다가
> 되면서 잘못 누른 걸 고칠 여지가 필요해져 시안이 뒤집었다.
> `intro_controller_test.dart` 가 이 규칙을 잠가 뒀다.

⚠️ 자기소개에는 **음성 입력이 없다.** 작성 탭(D)과 달리 답이 이름 한 단어나
보기 중 하나라 받아쓰기가 오히려 손이 더 간다. `IntroController`는
`SpeechService`를 아예 받지 않는다 — 되살릴 일이 생기면 작성 탭의 사용 방식을
그대로 가져오면 된다.

⚠️ 선택지 개수 제한이 없다. 둘이면 높이 96, 셋 이상이면 74로 줄어든다
(`AppChoiceTile.heightFor`). 예전의 "두 개 가로 배치" 가정은 없앴다.

⚠️ 1번 답변은 사용자 이름으로 저장돼 홈 카드 라벨과 책 표지에 쓰인다.
순서를 바꾸거나 지우면 그 연결(intro answers · `introProfile`)도
손봐야 한다.

### 뺀 화면

시안에 있었지만 **없앤** 흐름이다. 답변은 사용자가 말하거나 적은 그대로 저장된다.

- **AI 글 다듬기** — 원문을 문어체로 고쳐 보여주던 단계
- **직접 고치기** — 다듬은 글을 손보던 편집 화면
- **채팅 모드** — 말풍선으로 주고받던 글자 입력

이에 맞춰 `ApiClient`에서 `submitAnswer` · `repolish` · `chatHistory` 를 뺐다.
저장은 `saveAnswer` 하나만 지난다.

⚠️ 자기소개와 작성이 쓰던 **공용 입력 컴포넌트도 없앴다**
(`AnswerKeyboardBody` · `AppKeyboardButton`). 시안이 두 화면을 갈라놓았다 —
자기소개는 한 줄 입력칸, 작성(D3)은 높이 176의 여러 줄 판이다.

### 작성 탭에는 탭바가 없다

시안 D1~D5 어디에도 탭바가 그려져 있지 않다. 말하거나 적는 동안 다른 탭이
눈에 들어오면 하던 이야기를 놓치기 때문이다. 나가는 길은 상단 `←` 하나다.

### 헤더 알림 드롭다운

헤더의 "알림 2"를 누르면 아래로 목록이 펼쳐진다 (Figma `C3`).
별도 라우트가 아니라 홈 화면 위의 오버레이라 뒤로가기 스택에 쌓이지 않는다.
드롭다운은 **3건까지만** 보여주고 나머지는 알림 센터(`C4`)로 넘긴다 —
길게 늘어지면 뒤 화면을 다 덮어 드롭다운이 아니라 전체 화면처럼 보인다.

⚠️ 헤더의 알림은 **벨 아이콘이 아니라 글자**다("알림 2"). 시안이 아이콘+배지를
걷어냈다 — 시니어 사용자에게 벨 그림보다 "알림"이라는 말이 빠르고, 배지 숫자가
작아서 안 보이는 문제도 같이 없어진다.

⚠️ 드롭다운 줄(`_DropdownNote`)과 알림 센터 줄(`AppNotificationTile`)은
**모양이 다르다.** 드롭다운은 좁은 카드 안이라 구분선으로만 나누고, 센터는
줄마다 카드가 된다. 안 읽음 표시(굵기·점) 규칙만 둘이 같다.

## API

**화면·컨트롤러는 `ApiClient` 추상 타입만 본다.** 구현체는 `RealApiClient` 하나이며 `main.dart`에서 등록한다.

```dart
final api = Get.put<ApiClient>(_buildRealApi(), permanent: true);
```

`ApiClient` 메서드는 화면이 필요로 하는 모양이다. 엔드포인트가 더 잘게 쪼개져 있으면 구현체가 합친다. 데이터가 없으면 빈 목록·토스트·생성 CTA로 이어지고, 목업으로 채우지 않는다.

### 시그니처가 바뀔 수 있는 곳

| 메서드 | 이유 |
|---|---|
| `generateToc()` / intro answers | 오래 걸리는 작업이라 폴링·웹소켓이 될 수도 있다 |
| `verificationCodeTtl` | `requestVerificationCode`가 만료 시각을 주면 클라이언트가 초를 세는 게터는 지울 수 있다 |

## 음성 인식 (STT)

단말 STT는 `speech_to_text`를 쓴다 (안드로이드 `SpeechRecognizer`, iOS Speech).
서버 Clova STT도 API로 호출할 수 있다. 단말 경로는 `SpeechService`(GetxService)에 있다.

- 로케일은 기기에 설치된 한국어를 고르고, 없으면 시스템 기본으로 물러난다
- 말하는 동안 부분 인식 결과가 화면에 그대로 뜬다
- 침묵 6초 또는 "멈춤"을 누르면 끝난다 (어르신 말씀 속도를 감안한 값)
- 권한 거부·인식기 없음·무음은 모두 **키보드 입력으로 안내**한다

### 필요한 네이티브 설정

| 플랫폼 | 설정 |
|---|---|
| Android | `RECORD_AUDIO` 권한 + `<queries>` 에 `android.speech.RecognitionService` |
| iOS | `NSMicrophoneUsageDescription` · `NSSpeechRecognitionUsageDescription` |

⚠️ 안드로이드의 `<queries>` 가 없으면 기기에 인식기가 있어도 조회되지 않아
`initialize()` 가 **항상 false**를 돌려준다. 권한만 넣고 끝내면 안 된다.

## 함정

| 함정 | 내용 |
|---|---|
| **가변 폰트 굵기** | Noto Sans KR은 가변 폰트 파일 **하나**로만 배포돼서 굵기별 등록이 불가능하다. `fontWeight` 만 주면 **굵기가 안 바뀐다**. 굵기를 조정할 땐 반드시 `AppTypography.weight(style, w)` 를 쓴다 |
| **09 → 10 목차 전달** | `offNamed` 로 로딩 라우트가 빠지면 GetX가 컨트롤러를 폐기한다. 목차는 필드가 아니라 **라우트 인자**로 넘겨야 한다 |
| **Column 안의 좌측 정렬** | 바깥 Column이 center 정렬이면 안쪽 블록이 자식 폭으로 줄어든다. 가로 전체를 쓰려면 `CrossAxisAlignment.stretch` 나 `SizedBox(width: double.infinity)` 로 감싼다 |
| **`dart analyze` 를 쓴다** | 경로에 한글(`회사`)이 있으면 `flutter analyze` 의 LSP 채널이 깨진다 |
| **`lazyPut` + 컨트롤러 안 쓰는 뷰** | 뷰가 `GetView`가 아니면 `Get.find`를 부르는 사람이 없어 **컨트롤러가 생성조차 안 된다.** A1 스플래시·B6 목차 로딩이 영영 안 넘어갔다. 두 바인딩은 `Get.put`(즉시 생성)이다 |
| **`Obx(() => 자식위젯(...))`** | Obx 클로저는 위젯을 만들기만 하고 Rx 읽기는 자식의 build에서 일어난다 → "improper use of a GetX" 빨간 화면. Obx는 **Rx를 읽는 build 안**에 둔다 |
| **작성 화면의 `Get.back()`** | 탭 전환이 `offNamed`라 작성이 홈을 갈아 끼운 상태다. `Get.back()`은 돌아갈 스택이 없어 **앱이 꺼진다** — `Get.offNamed(home)`을 쓴다 |
| **고정 높이 안의 터치 패딩** | 시안 실측 높이(예: 헤더 36)로 `SizedBox`를 고정하면 터치 영역 패딩을 가진 자식이 잘린다. "알림 2"의 받침이 잘려 "아리 ㄱ"으로 보였다 |
| **`Container(alignment:)` 는 늘어난다** | alignment를 주면 자식이 `Align`으로 감싸여 **부모 최대 폭까지 확장**된다. 콘텐츠 폭 버튼("글로 답하기" 129)이 화면 전체로 퍼졌다 |
| **테스트의 GetStorage** | path_provider 플러그인이 없어 `MissingPluginException` 이 난다. `test/support/test_env.dart` 가 채널을 임시 디렉터리로 물려준다 |
| **접근성 라벨 중복** | `Semantics(label: ...)` 안의 `Text`가 같은 글자를 내보내면 스크린리더가 **두 번 읽는다**("여성 여성"). 자식이 이미 그 글자를 그리면 `label:`을 주지 말고, 라벨이 화면 글자와 달라야 하면 자식을 `ExcludeSemantics`로 감싼다 |
| **숫자 입력칸에 `readOnly`** | A3~A6은 앱 자체 키패드([`AppNumberPad`])로만 입력받는다. 입력칸에 `readOnly: true`를 빼면 눌렀을 때 OS 키보드가 올라와 키패드와 겹친다 |
| **`Chapter.copyWith`로 상태 재계산 금지** | `nextQuestionText`가 `?? this.x` 라 null을 넘겨도 예전 값이 남는다. 장을 다 끝냈는데 "다음 질문"이 계속 붙어 있게 된다 — 서버/클라이언트에서 장을 재구성할 때 생성자로 새로 만든다 |
| **녹음 상태를 따로 들지 않는다** | 컨트롤러가 자체 `isRecording` 플래그를 두면 인식기가 스스로 멈췄을 때(무음 타임아웃) 화면이 "듣고 있어요…"에 갇힌다. `SpeechService.isListening` 을 그대로 본다 |
| **핫 리스타트는 앱을 다시 띄우면 날아간다** | 살아 있는 VM에만 적용된다. `pm clear` + 재실행하면 **설치된 예전 빌드**가 뜬다. 네이티브(매니페스트·권한)를 건드렸으면 반드시 전체 재빌드 |

## 진행률 바

앱의 진행률 표시는 **`AppProgressBar` 하나**다.

| 쓰는 곳 | 높이 | 채움 | 모서리 |
|---|---|---|---|
| 자기소개 B1~B5 · 작성 D1~D5 | 4 | `warm #c4a77d` | **각짐** (`rounded: false`) |
| 홈 카드 C1 | 8 | `brand #6b5344` | 굴림 |

트랙은 두 곳 모두 `#f0ebe3`(`surfaceSoft`)다.

⚠️ 상단 진행바는 **화면 가장자리까지 닿는다.** 좌우 여백이 없으므로 모서리를
굴리면 화면 끝에서 바가 떠 보인다 — 그래서 `rounded: false`다.

⚠️ 자기소개의 5칸 분절 바(`AppStepBar`)는 없앴다. 한 장의 문항 수가 6~8개로
다르고 더 늘어날 수 있어 분절은 칸이 실처럼 얇아진다. 개수는 우상단 "3 / 5"와
바 아래 "질문 N / M" 텍스트가 알려준다.

## 시안 캔버스(390×844)를 안드로이드에 얹기

시안은 **iPhone 프레임**이다. 화면 전체가 844이고 홈 인디케이터가 내용 **위에
얹히는** 걸 전제로 그려져 있다. 안드로이드는 다르다 — 그대로 옮기면 두 군데가
어긋난다.

### 1. edge-to-edge를 켜지 않으면 아래 좌표가 전부 밀린다

`main.dart`가 `SystemUiMode.edgeToEdge`를 켠다. 이걸 빼면 앱 창이 내비게이션
바(약 27dp)만큼 짧아져 **844가 817이 되고**, 아래에서부터 잰 좌표가 전부
그만큼 위로 뜬다(로그인 버튼 블록이 27px 위로 뜨는 식).

### 2. 아래 여백은 `AppInsets.bottom()` 을 지난다

edge-to-edge를 켜면 이번엔 내비바가 내용을 **덮는다.** iPhone의 홈 인디케이터는
반투명이라 시안이 그 위에 버튼을 겹쳐 놔도 됐지만, 안드로이드 내비바는
불투명이다.

```dart
padding: EdgeInsets.only(bottom: AppInsets.bottom(context, 22)),
```

시안 여백을 기본으로 쓰되 내비바를 못 비키면 그때만 들어 올린다
(`max(시안값, 인셋 + 8)`). A2(64)·B7(58)처럼 이미 충분한 화면은 **시안 그대로**
남고, 자기소개 "다음"(22)·자서전 "이어서 쓰기"(16)처럼 모자란 곳만 내려앉는다.

숫자 키패드는 조금 다르다 — **판(배경)은 시안대로 화면 바닥까지** 내려가고
키만 들어 올린다. 판이 중간에 끊기면 시안과 확연히 달라 보인다.

### 3. 남는 차이 — 상태바 높이

세로 위치가 5~11px 어긋난다. 시안은 상태바 44px(iPhone) 전제인데 안드로이드는
기기마다 다르다. 고정 오프셋을 박으면 맞출 수 있지만 다른 기기에서 깨지므로
**맞추지 않았다.**

## 서체가 화면을 가른다

시안의 핵심 원칙이 **읽는 영역과 누르는 영역을 서체로 구분**하는 것이다.

| 자리 | 서체 | 예 |
|---|---|---|
| 화면 제목 · 질문 · 책 본문 · 퍼센트 | **명조**(`NanumMyeongjo`) | `AppTypography.titleScreen` · `titleSerifSm` · `bookBody` |
| 버튼 · 라벨 · 입력 · 목록 | 고딕(`NotoSansKR`) | `ctaLabel` · `subtitle` · `optionLabel` |

⚠️ 화면 제목에 고딕(`titlePage`)을 쓰면 이 구분이 무너진다. 제목은 반드시
`AppScreenHeading` 이나 `titleScreen`·`titleSerifSm` 을 지난다.

⚠️ 명조도 **가변 폰트**이고 wght 기본값이 **200(ExtraLight)** 이다. `fontWeight`만
주면 실처럼 얇게 나오므로 `AppTypography`가 `fontVariations`로 축을 직접 준다 —
예전 나눔명조(정적 400/700)에는 없던 함정이다.

## 목업의 한계

- 앱을 재시작하면 **상태가 초기화된다** (메모리 보관). 실제 서버가 들어오면 버릴 코드라 일부러 영속화하지 않았다.
- 진행률은 답변 수로 **계산**한다. 시안의 "42%" 같은 정적 수치와 정확히 같지는 않다.
- 카카오 로그인은 SDK 없이 성공만 돌려준다.
- TTS("다시 들려줘")·공유·인쇄본 신청은 안내 토스트만 띄운다. 대응 화면이 시안에 없다.
- **음성 인식은 서버 없이도 단말에서 동작한다** (위 "음성 인식" 참고). 다만 에뮬레이터에는
  실제 마이크 입력이 없어 한국어 인식 정확도는 실기기에서 확인해야 한다.

## 확인 방법

```bash
dart analyze     # No issues found!
flutter test     # 63개 통과
```

테스트는 **시안이 뒤집은 규칙**을 잠그는 데 집중돼 있다:

| 파일 | 잠그는 것 |
|---|---|
| `intro_controller_test` | 고르기는 즉시 안 넘어간다 · 고른 값이 남고 되살아난다 · 4지선다 |
| `login_controller_test` | 키패드 자릿수·서식 · 3분 타이머(`fake_async`) · 자동 확인 안 함 |
| `write_controller_test` | 저장 실패해도 화면을 안 떠난다 · 글이 남는다 · 재시도 |
| `preview_controller_test` | 쪽 단위 넘김 경계 · 장별 진입 시 쪽번호는 책 전체 기준 |
| `home_controller_test` | 목차 인라인 데이터 · 상태별 문구 |
| `address_controller_test` | 필수값 검증(상세 주소만 선택) |
| `widget/` | `AppNumberPad` · `AppCodeBoxes` · `AppChoiceTile` |
