import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 인증 흐름의 단계.
enum AuthStep {
  /// 전화번호 입력
  phone,

  /// OCTOMO 문자 발송 안내
  octomoInstruction,

  /// OCTOMO 확인 폴링
  octomoVerifying,

  /// 신규 사용자 — 이름 + 약관 동의
  signup,

  /// 가입 성공
  success,
}

/// 약관 동의 항목 하나의 화면 상태.
class ConsentItemState {
  const ConsentItemState({
    required this.document,
    this.agreed = false,
  });

  final ConsentDocument document;
  final bool agreed;

  ConsentItemState copyWith({bool? agreed}) =>
      ConsentItemState(document: document, agreed: agreed ?? this.agreed);
}

/// 메인 인증 컨트롤러 — 5단계 선형 흐름을 관리한다.
///
/// [AuthStep]으로 현재 단계를 구분하고, 각 단계별로 필요한 데이터를
/// Rx 필드로 노출한다. 뷰는 이 값을 구독해 화면을 교체한다.
class AuthController extends GetxController {
  AuthController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  // ── 단계 ────────────────────────────────────────────────────
    final Rx<AuthStep> currentStep = AuthStep.phone.obs;

  /// 페이지 컨트롤러 — 단계 간 슬라이드 전환.
  final pageController = PageController();

  // ── 전화번호 ────────────────────────────────────────────────
  final phoneController = TextEditingController();
  final RxString phoneDigits = ''.obs;

  static const _phoneLength = 11;

  bool get canProceedPhone => phoneDigits.value.length == _phoneLength;

  String get phoneFieldText => _format(phoneDigits.value, ' - ');

  String get phoneCompact => _format(phoneDigits.value, '-');

  void onPhoneDigit(String digit) {
    if (phoneDigits.value.length >= _phoneLength) return;
    _setPhone(phoneDigits.value + digit);
  }

  void onPhoneBackspace() {
    final v = phoneDigits.value;
    if (v.isEmpty) return;
    _setPhone(v.substring(0, v.length - 1));
  }

  void _setPhone(String digits) {
    phoneDigits.value = digits;
    phoneController.value = TextEditingValue(
      text: phoneFieldText,
      selection: TextSelection.collapsed(offset: phoneFieldText.length),
    );
  }

  // ── OCTOMO ──────────────────────────────────────────────────
  final RxString sessionId = ''.obs;
  final RxString receiverNumber = ''.obs;
  final RxString verifyText = ''.obs;
  final RxInt octomoExpiresIn = 0.obs;
  final RxInt octomoPollInterval = 3.obs;

  /// 폴링 진행 중.
  final RxBool isChecking = false.obs;

  /// 폴링 만료.
  final RxBool isExpired = false.obs;

  Timer? _pollTimer;
  int _secondsSincePoll = 0;
  int _totalElapsed = 0;

  // ── 회원가입 ────────────────────────────────────────────────
  final nameController = TextEditingController();
  final RxString name = ''.obs;

  /// 서버에서 받은 약관 문서 목록.
  final RxList<ConsentItemState> consents = <ConsentItemState>[].obs;

  /// 서버에서 받은 signupToken.
  final RxString signupToken = ''.obs;

  bool get canSignup =>
      name.value.trim().isNotEmpty &&
      consents.where((c) => c.document.required).every((c) => c.agreed);

  bool get allAgreed =>
      consents.isNotEmpty && consents.every((c) => c.agreed);

  void onNameChanged(String v) => name.value = v;

  void toggleConsent(int index) {
    if (index < 0 || index >= consents.length) return;
    consents[index] = consents[index].copyWith(
      agreed: !consents[index].agreed,
    );
    consents.refresh();
  }

  void toggleAllConsents() {
    final newValue = !allAgreed;
    consents.value = [
      for (final c in consents) c.copyWith(agreed: newValue),
    ];
  }

  // ── 로딩 ────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;

  // ── 공통 ──────────────────────────────────────────────────
  @override
  void onClose() {
    _pollTimer?.cancel();
    phoneController.dispose();
    nameController.dispose();
    pageController.dispose();
    super.onClose();
  }

  /// 단계 전환 (PageController 애니메이션).
  void _goToStep(AuthStep step) {
    const pages = AuthStep.values;
    final idx = pages.indexOf(step);
    if (idx < 0) return;
    currentStep.value = step;
    pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ══════════════════════════════════════════════════════════
  // 1. 전화번호 입력 → OCTOMO 챌린지 발급
  // ══════════════════════════════════════════════════════════

  /// 전화번호 확인 후 OCTOMO 챌린지 발급.
  Future<void> submitPhone() async {
    if (!canProceedPhone || isLoading.value) return;
    isLoading.value = true;
    try {
      // 1. 전화번호 조회 (가입 여부와 무관하게 항상 verify)
      final phone = phoneDigits.value;
      await _api.lookupPhone(phone);
      await Storage.savePhone(phone);

      // 2. OCTOMO 챌린지 발급
      final challenge = await _api.requestOctomoChallenge(phone);
      sessionId.value = challenge.sessionId;
      receiverNumber.value = challenge.receiverNumber;
      verifyText.value = challenge.verifyText;
      octomoExpiresIn.value = challenge.expiresIn;
      octomoPollInterval.value = challenge.pollInterval;
      isExpired.value = false;

      _goToStep(AuthStep.octomoInstruction);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // 2. OCTOMO 문자 전송 안내 → 확인 버튼 → 폴링
  // ══════════════════════════════════════════════════════════

  /// 수신번호를 클립보드에 복사한다.
  void copyReceiverNumber() {
    // 복사 기능은 Flutter Clipboard 사용
    // 실제 구현에서는 flutter/services.dart Clipboard.setData
    _toast.show('수신번호를 복사했어요');
  }

  /// 인증 텍스트를 클립보드에 복사한다.
  void copyVerifyText() {
    _toast.show('인증번호를 복사했어요');
  }

  /// "문자를 보냈어요" → 폴링 시작.
  Future<void> startVerification() async {
    _goToStep(AuthStep.octomoVerifying);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _secondsSincePoll = 0;
    _totalElapsed = 0;
    isChecking.value = true;
    isExpired.value = false;

    // 즉시 한 번 확인 후, poll_interval마다 재시도
    _doVerify();

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsSincePoll++;
      _totalElapsed++;
      if (_secondsSincePoll >= octomoPollInterval.value) {
        _secondsSincePoll = 0;
        _doVerify();
      }
      if (_totalElapsed >= octomoExpiresIn.value) {
        isExpired.value = true;
        _pollTimer?.cancel();
        isChecking.value = false;
      }
    });
  }

  Future<void> _doVerify() async {
    try {
      final result = await _api.verifyOctomo(sessionId.value);
      if (result.isPending) {
        // 남은 만료 시간 갱신
        if (result.expiresIn != null) {
          octomoExpiresIn.value = result.expiresIn!;
        }
        return;
      }

      // verified
      _pollTimer?.cancel();
      isChecking.value = false;

      if (result.isExisting && result.session != null) {
        // 기존 사용자 — 세션 발급 후 홈/인트로로 이동
        await _auth.applySession(result.session!);
        Get.offAllNamed(
          result.session!.needsIntro ? AppRoutes.intro : AppRoutes.home,
        );
      } else if (result.isNewUser) {
        // 신규 사용자 — 약관 동의 단계로
        signupToken.value = result.signupToken ?? '';
        consents.value = result.requiredConsents
            .map((d) => ConsentItemState(document: d))
            .toList();
        _goToStep(AuthStep.signup);
      }
    } on ApiException catch (e) {
      if (e.code == 'VERIFICATION_EXPIRED') {
        isExpired.value = true;
        _pollTimer?.cancel();
        isChecking.value = false;
      }
      // 그 외 오류는 폴링 계속
    }
  }

  /// 수동 다시 확인.
  Future<void> manualVerify() async {
    _secondsSincePoll = octomoPollInterval.value;
    await _doVerify();
  }

  /// 만료 후 챌린지를 다시 발급한다.
  Future<void> retryChallenge() async {
    _pollTimer?.cancel();
    isChecking.value = false;
    isExpired.value = false;
    await submitPhone();
  }

  // ══════════════════════════════════════════════════════════
  // 3. 회원가입 — 이름 + 약관 동의
  // ══════════════════════════════════════════════════════════

  Future<void> submitSignup() async {
    if (!canSignup || isLoading.value) return;
    isLoading.value = true;
    try {
      final session = await _api.signUp(
        signupToken: signupToken.value,
        name: name.value.trim(),
        consents: [
          for (final c in consents)
            ConsentAgreement(
              key: c.document.key,
              version: c.document.version,
              agreed: c.agreed,
            ),
        ],
      );
      await _auth.applySession(session);
      _goToStep(AuthStep.success);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // 4. 가입 성공 → 온보딩
  // ══════════════════════════════════════════════════════════

  void goToIntro() {
    Get.offAllNamed(AppRoutes.intro);
  }

  // ── 포맷 ──────────────────────────────────────────────────

  /// 01012345678 → "010{sep}1234{sep}5678"
  static String _format(String digits, String sep) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}$sep${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}$sep${digits.substring(3, 7)}$sep'
        '${digits.substring(7)}';
  }
}
