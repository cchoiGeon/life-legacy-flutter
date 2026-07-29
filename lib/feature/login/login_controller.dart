import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 02·03·04·05·06 — 로그인 · 전화번호 · 인증번호.
///
/// 세 화면이 하나의 컨트롤러를 공유한다. 전화번호를 다음 화면으로 넘겨야
/// 하는데, 라우트 인자로 던지면 뒤로 갔다 오는 동안 값이 사라지기 때문이다.
class LoginController extends GetxController {
  LoginController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final RxBool isSubmitting = false.obs;

  /// 인증번호 불일치. null이면 정상 상태.
  final RxnString codeError = RxnString();

  /// 화면에 보여줄 전화번호 — "010 1234 5678"
  final RxString phone = ''.obs;

  /// 입력된 인증번호. `codeController.text`를 그대로 읽으면 Obx가 갱신되지
  /// 않아서(TextEditingController는 Rx가 아니다) 별도 반응형 값으로 둔다.
  final RxString code = ''.obs;

  @override
  void onInit() {
    super.onInit();
    codeController.addListener(_onCodeChanged);
  }

  @override
  void onClose() {
    codeController.removeListener(_onCodeChanged);
    phoneController.dispose();
    codeController.dispose();
    super.onClose();
  }

  // ── 02 로그인 ─────────────────────────────────────────────

  Future<void> loginWithKakao() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _applySession(await _api.loginWithKakao());
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  void goPhone() => Get.toNamed(AppRoutes.phone);

  /// "자녀 계정으로 함께 쓰기" — 아직 화면이 없다.
  /// 시안 A섹션에 대응 프레임이 없어서 안내만 띄운다.
  void childAccount() =>
      _toast.show('자녀 계정 연결은 준비 중이에요', description: '설정에서 나중에 연결할 수 있어요');

  // ── 03·04 전화번호 ────────────────────────────────────────

  /// 숫자만 남긴 값. 11자리면 인증 요청을 보낼 수 있다.
  String get digits => phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get canRequestCode => digits.length == 11;

  void onPhoneChanged(String _) => phone.value = _format(digits);

  Future<void> requestCode() async {
    if (!canRequestCode || isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _api.requestVerificationCode(digits);
      codeController.clear();
      codeError.value = null;
      Get.toNamed(AppRoutes.code);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── 05·06 인증번호 ────────────────────────────────────────

  bool get canVerify => code.value.length == 6;

  /// 인증번호를 고치기 시작하면 에러 표시를 지운다.
  /// 틀린 번호가 빨갛게 남아 있으면 다시 입력하는 동안 계속 거슬린다.
  void _onCodeChanged() {
    code.value = codeController.text;
    if (codeError.value != null) codeError.value = null;
  }

  Future<void> verify() async {
    if (!canVerify || isSubmitting.value) return;
    isSubmitting.value = true;
    codeError.value = null;
    try {
      await _applySession(
        await _api.verifyCode(phone: digits, code: codeController.text),
      );
    } on ApiException catch (e) {
      // 코드 오류는 토스트가 아니라 입력칸 아래 문구로 보여준다(시안 06번).
      if (e.code == 'INVALID_CODE') {
        codeError.value = e.message;
      } else {
        _toast.showError(e);
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> resendCode() async {
    try {
      await _api.requestVerificationCode(digits);
      codeController.clear();
      codeError.value = null;
      _toast.show('인증번호를 다시 보냈어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  // ── 공통 ──────────────────────────────────────────────────

  Future<void> _applySession(AuthSession session) async {
    await _auth.applySession(session);
    Get.offAllNamed(session.needsIntro ? AppRoutes.intro : AppRoutes.home);
  }

  /// 01012345678 → "010 1234 5678"
  static String _format(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} '
        '${digits.substring(7)}';
  }
}
