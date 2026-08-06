import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/legal/legal_document_view.dart';
import 'package:life_legacy/service/services.dart';

/// A2·A3·A4·A5·A6 — 로그인 · 전화번호 · 인증번호.
///
/// 세 화면이 하나의 컨트롤러를 공유한다. 전화번호를 다음 화면으로 넘겨야
/// 하는데, 라우트 인자로 던지면 뒤로 갔다 오는 동안 값이 사라지기 때문이다.
///
/// ⚠️ 숫자는 **앱 자체 키패드**([AppNumberPad])로만 들어온다. OS 키보드를
///    쓰지 않으므로 `TextEditingController`에 사용자가 직접 타이핑하는 경로가
///    없다 — 값 변경은 전부 아래 `onXxxDigit`/`onXxxBackspace`를 지난다.
class LoginController extends GetxController {
  LoginController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  /// 화면에 보이는 전화번호 칸. 키패드가 넣은 값을 서식만 입혀 담는다.
  final phoneController = TextEditingController();

  final RxBool isSubmitting = false.obs;

  /// 인증번호 불일치. null이면 정상 상태.
  final RxnString codeError = RxnString();

  /// 입력된 전화번호 숫자 11자리 (서식 없음)
  final RxString phoneDigits = ''.obs;

  /// 입력된 인증번호 숫자 6자리
  final RxString code = ''.obs;

  /// 인증번호 만료까지 남은 초. 화면의 "2분 47초 남음".
  final RxInt secondsLeft = 0.obs;

  /// 재발송이 열릴 때까지 남은 초. 0이면 "다시 받기"를 누를 수 있다.
  ///
  /// 만료 시간과 **따로 센다.** 하나로 묶으면 문자가 안 온 사람이 번호가
  /// 만료될 때까지 아무것도 못 하고 기다리게 된다.
  final RxInt resendSecondsLeft = 0.obs;

  Timer? _tick;

  @override
  void onClose() {
    _tick?.cancel();
    phoneController.dispose();
    super.onClose();
  }

  // ── A2 로그인 ─────────────────────────────────────────────

  Future<void> loginWithKakao() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final accessToken = await _kakaoLogin();
      // null이면 사용자가 카카오 로그인 화면에서 뒤로 가기 등으로 취소한
      // 것이다 — 별도 에러 토스트 없이 조용히 돌아간다.
      if (accessToken == null) return;

      // 신규(needsIntro)면 세션 적용 후 약관·마케팅 동의 화면으로 보낸다.
      await _applySession(
        await _api.loginWithKakao(accessToken),
        collectConsentsIfNew: true,
        loginProvider: 'kakao',
      );
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 카카오톡이 깔려 있으면 톡으로, 아니면 카카오계정(웹)으로 로그인해
  /// 액세스 토큰을 받는다. 사용자가 취소하면 null.
  Future<String?> _kakaoLogin() async {
    if (await isKakaoTalkInstalled()) {
      try {
        final token = await UserApi.instance.loginWithKakaoTalk();
        return token.accessToken;
      } catch (error) {
        // 사용자가 카카오톡 권한 화면에서 뒤로 가기로 취소한 경우 — 계정
        // 로그인으로 넘어가지 않고 그대로 취소 처리한다.
        if (error is PlatformException && error.code == 'CANCELED') {
          return null;
        }
        // 카카오톡에 연결된 카카오계정이 없는 등 — 계정 로그인으로 이어간다.
      }
    }

    try {
      final token = await UserApi.instance.loginWithKakaoAccount();
      return token.accessToken;
    } catch (error) {
      if (error is PlatformException && error.code == 'CANCELED') {
        return null;
      }
      _toast.show('카카오 로그인에 실패했어요');
      return null;
    }
  }

  void goPhone() => Get.toNamed(AppRoutes.phone);

  /// OCTOMO 인증 흐름으로 이동한다.
  /// 신규 가입 시 전화 인증 이후 [SignupStep]에서 약관·마케팅 동의를 받는다.
  void goAuth() => Get.toNamed(AppRoutes.auth);

  void goPasswordLogin() => Get.toNamed(AppRoutes.passwordLogin);

  /// 로그인 화면 하단 열람 링크 — 실제 동의 체크는 가입 직후에 한다.
  void openTerms() => LegalDocumentView.open('terms_of_service');

  void openPrivacy() => LegalDocumentView.open('privacy_policy');

  // 인증번호 입력 화면으로.

  // ── A3·A4 전화번호 ────────────────────────────────────────

  static const _phoneLength = 11;

  bool get canRequestCode => phoneDigits.value.length == _phoneLength;

  /// 입력칸에 뜨는 형태 — "010 - 1234 - 5678" (시안 342:730)
  String get phoneFieldText => _format(phoneDigits.value, ' - ');

  /// 문장 안에 들어가는 형태 — "010-1234-5678 로 보냈어요" (시안 343:701)
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
    // 입력칸은 표시 전용이다. 커서를 끝에 두면 서식 문자 사이에 끼지 않는다.
    phoneController.value = TextEditingValue(
      text: phoneFieldText,
      selection: TextSelection.collapsed(offset: phoneFieldText.length),
    );
  }

  Future<void> requestCode() async {
    if (!canRequestCode || isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final challenge = await _api.requestVerificationCode(phoneDigits.value);
      code.value = '';
      codeError.value = null;
      _startTimer(challenge);
      Get.toNamed(AppRoutes.code);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── A5·A6 인증번호 ────────────────────────────────────────

  static const _codeLength = 6;

  bool get canVerify => code.value.length == _codeLength;

  /// 인증번호를 고치기 시작하면 에러 표시를 지운다.
  /// 틀린 번호가 빨갛게 남아 있으면 다시 입력하는 동안 계속 거슬린다.
  void onCodeDigit(String digit) {
    if (code.value.length >= _codeLength) return;
    codeError.value = null;
    code.value = code.value + digit;
  }

  void onCodeBackspace() {
    final v = code.value;
    if (v.isEmpty) return;
    codeError.value = null;
    code.value = v.substring(0, v.length - 1);
  }

  /// "2분 47초 남음" — 다 지나면 문구가 바뀐다 (시안 343:713).
  String get timerLabel {
    final s = secondsLeft.value;
    if (s <= 0) return '시간이 지났어요';
    return '${s ~/ 60}분 ${s % 60}초 남음';
  }

  /// 대기 시간이 지나야 "다시 받기"가 눌린다 —
  /// 문자를 연달아 보내면 어느 번호가 맞는지 사용자가 헷갈린다.
  bool get canResend => resendSecondsLeft.value <= 0;

  /// 만료·재발송 두 시계를 서버가 준 값으로 맞춘다.
  ///
  /// 타이머는 하나로 돌린다 — 두 개를 두면 둘이 어긋났을 때 화면이
  /// 설명할 수 없는 상태가 된다.
  void _startTimer(VerificationChallenge challenge) {
    _tick?.cancel();
    secondsLeft.value = challenge.expiresIn.inSeconds;
    resendSecondsLeft.value = challenge.resendAfter.inSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value > 0) secondsLeft.value--;
      if (resendSecondsLeft.value > 0) resendSecondsLeft.value--;
      if (secondsLeft.value == 0 && resendSecondsLeft.value == 0) t.cancel();
    });
  }

  Future<void> verify() async {
    if (!canVerify || isSubmitting.value) return;
    isSubmitting.value = true;
    codeError.value = null;
    try {
      await _applySession(
        await _api.verifyCode(phone: phoneDigits.value, code: code.value),
        loginProvider: 'phone',
      );
    } on ApiException catch (e) {
      // 코드 오류는 토스트가 아니라 칸 위 문구로 보여준다(시안 343:819).
      if (e.code == 'INVALID_CODE') {
        codeError.value = '인증번호가 맞지 않아요. 다시 입력해주세요.';
      } else {
        _toast.showError(e);
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> resendCode() async {
    if (!canResend) return;
    try {
      final challenge = await _api.requestVerificationCode(phoneDigits.value);
      code.value = '';
      codeError.value = null;
      _startTimer(challenge);
      _toast.show('인증번호를 다시 보냈어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  // ── 공통 ──────────────────────────────────────────────────

  Future<void> _applySession(
    AuthSession session, {
    bool collectConsentsIfNew = false,
    String? loginProvider,
  }) async {
    _tick?.cancel();
    await _auth.applySession(session, loginProvider: loginProvider);
    if (collectConsentsIfNew && session.needsIntro) {
      Get.offAllNamed(AppRoutes.consents);
      return;
    }
    Get.offAllNamed(session.needsIntro ? AppRoutes.intro : AppRoutes.home);
  }

  /// 01012345678 → "010{sep}1234{sep}5678". 덜 채운 동안에도 자연스럽게 끊는다.
  static String _format(String digits, String sep) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}$sep${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}$sep${digits.substring(3, 7)}$sep'
        '${digits.substring(7)}';
  }
}
