# 녹음 버튼 이퀄라이저 링 — Design Spec

**날짜:** 2026-08-07  
**상태:** 승인됨 (접근 1 · 레이아웃 §1 합의 후 개발 진행)

## 목표

녹음 중 마이크 버튼에 **실제 음량에 반응하는 원형 이퀄라이저 링**을 추가한다.  
기존 파문·정지 사각은 유지한다. 세로 레이아웃을 깨지 않는다.

## 결정 요약

| 항목 | 선택 |
|------|------|
| 형태 | 버튼 바깥 링 막대 EQ |
| 파문 | 유지 (EQ와 함께) |
| 레벨 | `speech_to_text` `onSoundLevelChange` (실제 음량) |
| 스펙트럼 | 단일 레벨을 위상만 다르게 펼친 가짜 밴드 (FFT 없음) |

## §1 화면·레이아웃

녹음 중(`recording && !paused`) Stack (바깥→안):

1. **파문** — 기존 `_MicRipple` (`bloom=26`, 자리 비점유)
2. **EQ 링** — 버튼 원 바로 바깥, ~24개 막대, 반지름 방향으로 길이 변화
3. **브라운 원 + 정지 사각** — 기존 탭 타깃

제약:

- EQ도 `OverflowBox`/`IgnorePointer`로 **자리를 차지하지 않음** (기존 파문과 동일)
- 링 기준 반경 ≈ `size/2 + 10`, 막대 최대 길이는 `bloom` 안쪽
- 색: `AppColors.warm`
- 대기·일시정지: EQ·파문 숨김
- `MediaQuery.disableAnimations`: 막대는 최소 높이 고정

## §2 데이터 흐름

```
SpeechToText.onSoundLevelChange
  → SpeechService.soundLevel (RxDouble, 0..1 정규화)
  → WriteController 노출 (또는 RecordingStage가 SpeechService/컨트롤러에서 구독)
  → AppMicButton(level: …)
  → CustomPainter가 막대 높이 계산
```

- `listen` 시작 시 `onSoundLevelChange` 연결
- `pause` / `stop` / `cancel` / 듣기 종료 시 `soundLevel = 0`
- 플러그인 raw 레벨(대략 -2~10대)을 clamp 후 0..1로 매핑. 플랫폼 차이는 상수로 조정 가능

## §3 컴포넌트·테스트

**변경 파일**

- `lib/service/speech_service.dart` — `soundLevel` + 콜백
- `lib/common/widgets/ds/app_voice.dart` — EQ 링 painter, `level` 파라미터
- `lib/feature/write/stages/recording_stage.dart` — `Obx`로 level 전달
- `lib/feature/write/write_controller.dart` — 필요 시 getter
- `test/widget/app_mic_button_test.dart` — EQ 키·자리 비점유·paused 숨김
- (선택) speech_service 단위 테스트 — 정규화

**비범위**

- FFT/진짜 주파수 밴드
- `record` 패키지 병렬 마이크
- 파문 제거 또는 파문-음량 연동
- Figma 신규 프레임 (기존 D2 위에 덧그림)

## 성공 기준

1. 녹음 중 말하면 EQ 막대가 움직이고, 파문도 보인다
2. 녹음 시작/종료 시 마이크 버튼 위치가 변하지 않는다
3. 일시정지 시 EQ·파문 없음
4. 기존 `app_mic_button_test` 통과 + EQ 관련 케이스 추가
