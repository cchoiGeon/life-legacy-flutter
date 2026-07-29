# Life Legacy

> 말씀만 하시면 AI가 한 권의 자서전으로 써 드려요.

시니어 사용자가 **말로 답하면** AI가 자서전 문체로 다듬어 한 권의 책으로 엮어주는 앱.

- **디자인**: Figma `PickDam` — 디자인 시스템 [`130:2`](https://www.figma.com/design/apsdRjQLt8xVVMbxzU60HC/PickDam?node-id=130-2) · UI [`134:2`](https://www.figma.com/design/apsdRjQLt8xVVMbxzU60HC/PickDam?node-id=134-2)
- **스택**: Flutter + GetX (Pickle · IAM_flutter와 동일 구조)
- **API**: 아직 **전부 목업**이다. 아래 "API 갈아 끼우기" 참고.

## 실행

```bash
flutter pub get
flutter run
```

인증번호는 문자가 오지 않으므로 **`482915`** 를 쓴다(화면에도 안내가 뜬다).
`MockApiClient.demoCode` 를 바꾸면 같이 바뀐다.

## 구조

IAM_flutter와 같은 배치다. 화면 하나 = `binding` + `controller` + `view` 세 파일.

```
lib/
├── common/
│   ├── constants/          colors · typography · dimens (Figma 토큰 이식)
│   └── widgets/ds/         디자인 시스템 위젯 (ds.dart 하나만 import)
├── core/
│   ├── network/
│   │   ├── api_client.dart       ← 추상 인터페이스 (교체 지점)
│   │   └── mock_api_client.dart  ← 지금의 유일한 구현
│   └── route/              app_pages.dart + app_routes.dart
├── data/
│   ├── models/ · enums/    plain Dart. fromJson/toJson 수동 작성
│   ├── storage.dart        GetStorage 래퍼 (토큰 · 온보딩 통과 여부)
│   └── data_manager.dart   barrel — 화면은 이것만 import
├── feature/<화면>/         binding · controller · view
└── service/                AuthService · ToastService (전역 싱글턴)
```

## 화면 ↔ Figma 대응

시안 22개 프레임 중 여럿은 **같은 화면의 다른 상태**라 라우트는 그보다 적다.

| 라우트 | 시안 | 비고 |
|---|---|---|
| `/` | 01 | 세션 있으면 홈/자기소개로 자동 이동 |
| `/login` | 02 | |
| `/login/phone` | 03 · 04 | 입력 전/후 상태 |
| `/login/code` | 05 · 06 | 정상/에러 상태 |
| `/intro` | 01~05 자기소개 | 1번은 키보드, 2~5번은 고르기 (아래 참고) |
| `/intro/loading` | 09 | 뒤로가기 차단 |
| `/intro/toc` | 10 | |
| `/home` | 11 · 12 · 13 | 데이터 있음/빈 상태 · 알림 드롭다운(오버레이) |
| `/write` | 13 · 14 · 15 · 16 | `WriteStage` 4단계 상태 기계 |
| `/book` | 19 | |
| `/book/preview` | 20 | |
| `/book/complete` | 21 | |
| `/settings` | 22 | |
| `/notifications` | 14 알림 센터 | 홈 드롭다운의 "전체 보기"에서 들어온다 |

### 자기소개 5문항

| # | 질문 | 답변 방식 |
|---|---|---|
| 1 | 성함이 어떻게 되세요? | 키보드 입력 |
| 2 | 성별이 어떻게 되세요? | 남 / 여 |
| 3 | 결혼은 하셨나요? | 예 / 아니요 |
| 4 | 자녀는 있으신가요? | 예 / 아니요 |
| 5 | 대학교까지 다니셨나요? | 예 / 아니요 |

고르기 문항(`IntroAnswerType.choice`)은 **누르는 즉시 다음으로 넘어간다.**
시니어 사용자가 "고르고 → 다음 누르고" 두 번 조작하지 않게 한 것이다.

⚠️ 자기소개에는 **음성 입력이 없다.** 작성 탭(13)과 달리 답이 이름 한 단어나
두 갈래 선택이라 받아쓰기가 오히려 손이 더 간다. `IntroController`는
`SpeechService`를 아예 받지 않는다 — 되살릴 일이 생기면 작성 탭의 사용 방식을
그대로 가져오면 된다.

⚠️ 선택지 두 개는 **항상 같은 모양**이다(둘 다 outline). 고른 쪽을 채워서
표시하면 한쪽만 색이 진해져 기본값처럼 보인다. 대신 뒤로 왔을 때 무엇을
골랐는지 화면에 남지 않는다 — 답 자체는 `answers`에 그대로 있다.

⚠️ 1번 답변은 사용자 이름으로 저장돼 목차 로딩 문구와 홈 인사말에 쓰인다.
순서를 바꾸거나 지우면 그 연결(`MockApiClient.generateToc`)도 손봐야 한다.

⚠️ 화면은 선택지가 **두 개**라고 가정하고 가로로 배치한다. 세 개 이상이
필요해지면 `_ChoiceBody`도 같이 고쳐야 한다.

### 자기소개와 작성이 공유하는 것

두 화면의 글자 입력은 **같은 컴포넌트**를 쓴다. 한쪽만 고쳐지는 일을 막기 위해서다.

| 공유물 | 위치 | 쓰는 곳 |
|---|---|---|
| "키보드로 입력할게요" 버튼 | `ds/app_keyboard_button.dart` (Figma 158:370) | 13 작성 |
| 질문 + 입력칸 + CTA | `feature/shared/answer_keyboard_body.dart` | 08 자기소개 · 15 작성 |

자기소개는 `onMic`을 주지 않는다 — 그러면 입력칸의 마이크 버튼과
"음성으로 바꾸려면…" 안내가 함께 빠진다.

### 뺀 화면

시안에 있었지만 **없앤** 흐름이다. 답변은 사용자가 말하거나 적은 그대로 저장된다.

- **AI 글 다듬기** — 원문을 문어체로 고쳐 보여주던 단계
- **직접 고치기** — 다듬은 글을 손보던 편집 화면
- **채팅 모드** — 말풍선으로 주고받던 글자 입력. 위의 공용 키보드 입력이 대신한다

이에 맞춰 `ApiClient`에서 `submitAnswer` · `repolish` · `chatHistory` 를 뺐다.
저장은 `saveAnswer` 하나만 지난다.

### 헤더 알림 드롭다운

벨을 누르면 헤더 아래로 목록이 펼쳐진다 (Figma `13 홈 · 알림 드롭다운`).
별도 라우트가 아니라 홈 화면 위의 오버레이라 뒤로가기 스택에 쌓이지 않는다.
드롭다운은 **3건까지만** 보여주고 나머지는 알림 센터(`14 알림 센터`)로 넘긴다 —
길게 늘어지면 뒤 화면을 다 덮어 드롭다운이 아니라 전체 화면처럼 보인다.

알림 한 줄(`AppNotificationTile`)은 드롭다운과 알림 센터가 **같은 컴포넌트**를 쓴다.

⚠️ 참고용으로 붙어 있던 프레임(`169:446`)은 **IAM 팔레트**(파랑 #4360e6 ·
코랄 #ff6b52)로 그려져 있었다. 이 앱은 파란색을 쓰지 않으므로 구조만 가져오고
색은 웜 브라운 토큰으로 옮겼다 — 배지·안읽음 점은 `destructive`, 안 읽은 행
배경은 `cream`, 강조 글자는 `brand`.

## API 갈아 끼우기

**화면·컨트롤러는 한 줄도 고치지 않는다.** 모두 `ApiClient` 추상 타입만 알고 있다.

1. `pubspec.yaml` 에 `dio` · `retrofit` · `json_annotation` 추가
2. `lib/data/models/*.dart` 의 `fromJson` 을 실제 응답 스키마에 맞게 수정
   (또는 `@JsonSerializable` 로 바꾸고 `build_runner` 로 생성)
3. `RealApiClient implements ApiClient` 작성
4. `lib/main.dart` 의 이 **한 줄**만 교체:
   ```dart
   final api = Get.put<ApiClient>(MockApiClient(), permanent: true);
   //                             ^^^^^^^^^^^^^^^ 여기
   ```

`ApiClient` 의 메서드는 서버 계약이 아니라 **화면이 필요로 하는 모양**으로 잡았다.
실제 엔드포인트가 더 잘게 쪼개져 있으면 구현체가 여러 호출을 합쳐서 맞춰주면 된다.

### 정해지면 시그니처가 바뀔 곳

| 메서드 | 이유 |
|---|---|
| `generateToc()` | 오래 걸리는 작업이라 폴링·웹소켓이 될 수도 있다 |

## 음성 인식 (STT) — 목업 아님

**여기만 실제로 동작한다.** `speech_to_text` 로 단말의 음성 인식을 쓴다
(안드로이드 `SpeechRecognizer`, iOS Speech 프레임워크). 오디오를 서버로
올리지 않으므로 `ApiClient`가 아니라 `SpeechService`(GetxService)에 있다.

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
| **09 → 10 목차 전달** | `offNamed` 로 로딩 라우트가 빠지면 GetX가 컨트롤러를 폐기한다. 목차는 필드가 아니라 **라우트 인자**로 넘겨야 한다 (`toc_controller_test.dart` 가 잠가 뒀다) |
| **Column 안의 좌측 정렬** | 바깥 Column이 center 정렬이면 안쪽 블록이 자식 폭으로 줄어든다. 가로 전체를 쓰려면 `CrossAxisAlignment.stretch` 나 `SizedBox(width: double.infinity)` 로 감싼다 |
| **`dart analyze` 를 쓴다** | 경로에 한글(`회사`)이 있으면 `flutter analyze` 의 LSP 채널이 깨진다 |
| **테스트의 GetStorage** | path_provider 플러그인이 없어 `MissingPluginException` 이 난다. 테스트에서 채널을 임시 디렉터리로 물려준다 |
| **녹음 상태를 따로 들지 않는다** | 컨트롤러가 자체 `isRecording` 플래그를 두면 인식기가 스스로 멈췄을 때(무음 타임아웃) 화면이 "듣고 있어요…"에 갇힌다. `SpeechService.isListening` 을 그대로 본다 |
| **핫 리스타트는 앱을 다시 띄우면 날아간다** | 살아 있는 VM에만 적용된다. `pm clear` + 재실행하면 **설치된 예전 빌드**가 뜬다. 네이티브(매니페스트·권한)를 건드렸으면 반드시 전체 재빌드 |

## 진행률 바

앱의 진행률 표시는 **`AppProgressBar` 하나**다. 예전에는 세 군데에 따로 있었다
(홈 카드 · 자기소개 5칸 분절 · 작성 인라인).

| 쓰는 곳 | 높이 | 채움 |
|---|---|---|
| 자기소개 07·08 · 작성 13 | 6 | `warm #c4a77d` |
| 홈 카드 11 | 10 | `brand #6b5344` |

트랙은 세 곳 모두 `#f0ebe3`, 반경은 항상 높이의 절반이다.

⚠️ 자기소개의 5칸 분절 바(`AppStepBar`)는 없앴다. 한 장의 문항 수가 6~8개로
다르고 더 늘어날 수 있어 분절은 칸이 실처럼 얇아진다. 개수는 바 아래
"질문 N / M" 텍스트가 알려준다 — 자기소개와 작성이 같은 문구를 쓴다.

## 목업의 한계

- 앱을 재시작하면 **상태가 초기화된다** (메모리 보관). 실제 서버가 들어오면 버릴 코드라 일부러 영속화하지 않았다.
- 진행률은 답변 수로 **계산**한다. 시안의 "42%" 같은 정적 수치와 정확히 같지는 않다.
- 카카오 로그인은 SDK 없이 성공만 돌려준다.
- TTS("다시 들려줘")·공유·인쇄본 신청은 안내 토스트만 띄운다. 대응 화면이 시안에 없다.
- **음성 인식은 목업이 아니다** (위 "음성 인식" 참고). 다만 에뮬레이터에는
  실제 마이크 입력이 없어 한국어 인식 정확도는 실기기에서 확인해야 한다.

## 확인 방법

```bash
dart analyze     # No issues found!
flutter test     # 10개 통과
```
