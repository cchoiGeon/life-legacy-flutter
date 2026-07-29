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
| `/intro` | 07 · 08 | 음성/키보드 모드 (`ComposeMode`) |
| `/intro/loading` | 09 | 뒤로가기 차단 |
| `/intro/toc` | 10 | |
| `/home` | 11 · 12 | 데이터 있음/빈 상태 |
| `/write` | 13~18 | `WriteStage` 6단계 상태 기계 |
| `/book` | 19 | |
| `/book/preview` | 20 | |
| `/book/complete` | 21 | |
| `/settings` | 22 | |

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
| `transcribe()` | STT를 단말에서 할지(speech_to_text) 서버로 올릴지 미정. 지금은 파라미터가 없다 |
| `generateToc()` | 오래 걸리는 작업이라 폴링·웹소켓이 될 수도 있다 |

## 함정

| 함정 | 내용 |
|---|---|
| **가변 폰트 굵기** | Noto Sans KR은 가변 폰트 파일 **하나**로만 배포돼서 굵기별 등록이 불가능하다. `fontWeight` 만 주면 **굵기가 안 바뀐다**. 굵기를 조정할 땐 반드시 `AppTypography.weight(style, w)` 를 쓴다 |
| **09 → 10 목차 전달** | `offNamed` 로 로딩 라우트가 빠지면 GetX가 컨트롤러를 폐기한다. 목차는 필드가 아니라 **라우트 인자**로 넘겨야 한다 (`toc_controller_test.dart` 가 잠가 뒀다) |
| **Column 안의 좌측 정렬** | 바깥 Column이 center 정렬이면 안쪽 블록이 자식 폭으로 줄어든다. 가로 전체를 쓰려면 `SizedBox(width: double.infinity)` 로 감싼다 |
| **`dart analyze` 를 쓴다** | 경로에 한글(`회사`)이 있으면 `flutter analyze` 의 LSP 채널이 깨진다 |
| **테스트의 GetStorage** | path_provider 플러그인이 없어 `MissingPluginException` 이 난다. 테스트에서 채널을 임시 디렉터리로 물려준다 |

## 목업의 한계

- 앱을 재시작하면 **상태가 초기화된다** (메모리 보관). 실제 서버가 들어오면 버릴 코드라 일부러 영속화하지 않았다.
- 진행률은 답변 수로 **계산**한다. 시안의 "42%" 같은 정적 수치와 정확히 같지는 않다.
- 카카오 로그인은 SDK 없이 성공만 돌려준다.
- TTS("다시 들려줘")·공유·인쇄본 신청은 안내 토스트만 띄운다. 대응 화면이 시안에 없다.

## 확인 방법

```bash
dart analyze     # No issues found!
flutter test     # 10개 통과
```
