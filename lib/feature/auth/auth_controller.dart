import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 인증 흐름의 단계.
enum AuthStep {
  /// 전화번호 입력
  phone,

  /// 로컬 문자 앱 전송 + OCTOMO 수신 확인
  octomoSms,

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

/// 메인 인증 컨트롤러 — 선형 흐름을 관리한다.
///
/// SMS 단계는 로컬 문자 앱에 수신번호·본문을 채운 뒤 열고,
/// 앱으로 돌아오면 OCTOMO 수신 여부를 폴링한다. 제한 시간은 5분.
class AuthController extends GetxController with WidgetsBindingObserver {
  AuthController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  /// 클라이언트 카운트다운 상한(초). 서버 TTL과 맞춤.
  static const smsTimeoutSeconds = 300;

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

  /// OS 키보드 입력. 숫자만 모아 11자리까지 두고 표시는 `010 - 0000 - 0000` 형식.
  void onPhoneChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final clipped =
        digits.length > _phoneLength ? digits.substring(0, _phoneLength) : digits;
    final formatted = _format(clipped, ' - ');
    if (clipped == phoneDigits.value && phoneController.text == formatted) {
      return;
    }
    _setPhone(clipped);
  }

  void _setPhone(String digits) {
    phoneDigits.value = digits;
    final formatted = _format(digits, ' - ');
    phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // ── OCTOMO / SMS ────────────────────────────────────────────
  final RxString sessionId = ''.obs;
  final RxString receiverNumber = ''.obs;
  final RxString verifyText = ''.obs;
  final RxInt octomoPollInterval = 3.obs;

  /// 남은 인증 시간(초). UI 카운트다운.
  final RxInt remainingSeconds = smsTimeoutSeconds.obs;

  /// 폴링 진행 중.
  final RxBool isChecking = false.obs;

  /// 폴링 만료.
  final RxBool isExpired = false.obs;

  Timer? _pollTimer;
  int _secondsSincePoll = 0;
  int _totalElapsed = 0;
  int _timeoutSeconds = smsTimeoutSeconds;

  String get remainingLabel {
    final s = remainingSeconds.value.clamp(0, smsTimeoutSeconds);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

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
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    phoneController.dispose();
    nameController.dispose();
    pageController.dispose();
    super.onClose();
  }

  /// 문자 앱에서 돌아와 앱이 다시 보이면 즉시 수신 확인.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (currentStep.value != AuthStep.octomoSms) return;
    if (isExpired.value || sessionId.value.isEmpty) return;
    unawaited(manualVerify());
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
  // 1. 전화번호 입력 → 챌린지 → 문자 앱 → 폴링
  // ══════════════════════════════════════════════════════════

  /// 전화번호 확인 후 OCTOMO 챌린지 발급 → 문자 앱 오픈 → 수신 폴링.
  Future<void> submitPhone() async {
    if (!canProceedPhone || isLoading.value) return;
    isLoading.value = true;
    try {
      final phone = phoneDigits.value;
      await _api.lookupPhone(phone);
      await Storage.savePhone(phone);

      final challenge = await _api.requestOctomoChallenge(phone);
      sessionId.value = challenge.sessionId;
      receiverNumber.value = challenge.receiverNumber;
      verifyText.value = challenge.verifyText;
      octomoPollInterval.value = challenge.pollInterval;
      _timeoutSeconds = challenge.expiresIn > 0
          ? challenge.expiresIn.clamp(1, smsTimeoutSeconds)
          : smsTimeoutSeconds;
      remainingSeconds.value = _timeoutSeconds;
      isExpired.value = false;

      _goToStep(AuthStep.octomoSms);
      await openSmsApp();
      _startPolling();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 로컬 문자 앱을 연다. 수신번호 + 보낼 문자(본문)가 채워진 상태.
  Future<void> openSmsApp() async {
    final number = receiverNumber.value.replaceAll(RegExp(r'[\s-]'), '');
    final body = verifyText.value;
    if (number.isEmpty || body.isEmpty) {
      _toast.show('인증 정보가 아직 준비되지 않았어요');
      return;
    }

    final uri = Uri.parse(
      'sms:$number?body=${Uri.encodeComponent(body)}',
    );

    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        _toast.show('문자 앱을 열 수 없어요. 아래 번호로 직접 보내 주세요');
      }
    } catch (_) {
      _toast.show('문자 앱을 열 수 없어요. 아래 번호로 직접 보내 주세요');
    }
  }

  /// "문자를 보냈어요" — 폴링이 꺼져 있으면 다시 시작하고, 즉시 한 번 확인.
  Future<void> confirmSmsSent() async {
    if (isExpired.value) return;
    if (!isChecking.value) {
      _startPolling();
      return;
    }
    await manualVerify();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _secondsSincePoll = 0;
    _totalElapsed = 0;
    remainingSeconds.value = _timeoutSeconds;
    isChecking.value = true;
    isExpired.value = false;

    _doVerify();

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsSincePoll++;
      _totalElapsed++;
      remainingSeconds.value =
          (_timeoutSeconds - _totalElapsed).clamp(0, _timeoutSeconds);

      if (_secondsSincePoll >= octomoPollInterval.value) {
        _secondsSincePoll = 0;
        _doVerify();
      }
      if (_totalElapsed >= _timeoutSeconds) {
        isExpired.value = true;
        _pollTimer?.cancel();
        isChecking.value = false;
        remainingSeconds.value = 0;
      }
    });
  }

  Future<void> _doVerify() async {
    if (sessionId.value.isEmpty || isExpired.value) return;
    try {
      final result = await _api.verifyOctomo(sessionId.value);
      if (result.isPending) {
        if (result.expiresIn != null) {
          final left = result.expiresIn!.clamp(0, smsTimeoutSeconds);
          // 서버 잔여 시간이 더 짧으면 맞춤
          if (left < remainingSeconds.value) {
            remainingSeconds.value = left;
            _timeoutSeconds = _totalElapsed + left;
          }
        }
        return;
      }

      _pollTimer?.cancel();
      isChecking.value = false;

      if (result.isExisting && result.session != null) {
        await _auth.applySession(result.session!);
        Get.offAllNamed(
          result.session!.needsIntro ? AppRoutes.intro : AppRoutes.home,
        );
      } else if (result.isNewUser) {
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
        remainingSeconds.value = 0;
      }
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
  // 2. 회원가입 — 이름 + 약관 동의
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
  // 3. 가입 성공 → 온보딩
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
