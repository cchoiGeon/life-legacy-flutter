# Mic Equalizer Ring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 녹음 중 `AppMicButton` 바깥에 실제 마이크 음량에 반응하는 이퀄라이저 링을 추가하고, 기존 파문·자리 비점유를 유지한다.

**Architecture:** `SpeechService`가 `onSoundLevelChange`로 0..1 `soundLevel`을 노출한다. `RecordingStage`가 Obx로 `AppMicButton(level:)`에 넘긴다. 버튼은 CustomPainter로 원형 막대 링을 그린다(단일 레벨 × 위상 오프셋).

**Tech Stack:** Flutter, GetX, speech_to_text, 기존 DS(`AppColors`, `AppMicButton`)

**Spec:** `docs/superpowers/specs/2026-08-07-mic-equalizer-design.md`

---

## File map

| File | Responsibility |
|------|----------------|
| `lib/service/speech_service.dart` | raw → 0..1 `soundLevel`, listen/stop 시 리셋 |
| `lib/feature/write/write_controller.dart` | `micLevel` getter (선택·얇은 노출) |
| `lib/common/widgets/ds/app_voice.dart` | EQ 링 UI + `level` |
| `lib/feature/write/stages/recording_stage.dart` | level 전달 |
| `test/widget/app_mic_button_test.dart` | EQ 표시·자리·paused |
| `test/service/speech_service_sound_level_test.dart` | 정규화 단위 (순수 함수면 여기) |

---

### Task 1: SpeechService soundLevel

**Files:**
- Modify: `lib/service/speech_service.dart`
- Test: `test/service/speech_level_normalize_test.dart` (정규화 순수 함수)

- [ ] **Step 1:** `SpeechService.normalizeSoundLevel(double raw)` 실패 테스트 작성 (예: -2→0, 10→1, 중간값)
- [ ] **Step 2:** 테스트 실패 확인
- [ ] **Step 3:** 정규화 + `RxDouble soundLevel` + `listen(onSoundLevelChange:)` + pause/stop/cancel/status에서 0으로 리셋
- [ ] **Step 4:** 테스트 통과 확인

### Task 2: AppMicButton EQ ring (TDD)

**Files:**
- Modify: `lib/common/widgets/ds/app_voice.dart`
- Modify: `test/widget/app_mic_button_test.dart`

- [ ] **Step 1:** 테스트 추가 — `recording && level>0`이면 `eqKey` 존재; paused면 없음; 자리 크기 idle==busy
- [ ] **Step 2:** 실패 확인
- [ ] **Step 3:** `_MicEqualizer` + painter, `level` 파라미터, 자리 비점유
- [ ] **Step 4:** 기존+신규 테스트 통과

### Task 3: Wire RecordingStage

**Files:**
- Modify: `lib/feature/write/write_controller.dart` (getter)
- Modify: `lib/feature/write/stages/recording_stage.dart`

- [ ] **Step 1:** `micLevel` → `AppMicButton(level: …)`
- [ ] **Step 2:** 위젯/레이아웃 관련 기존 테스트 회귀 실행

### Task 4: Docs touch-up

- [ ] `app_voice.dart` 주석 — “speech_to_text가 음량을 안 준다” 문구 수정
- [ ] (선택) `docs/api-spec.md` D2 문장에 EQ 링 한 줄 추가
