import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// F3 내 정보 (보기 전용) — Figma 368:901.
///
/// **고치는 기능이 없다.** 시안에 이름·전화번호·자기소개를 바꾸는 화면이
/// 없어서다(배송지만 F4에서 고친다). 여기는 "무엇으로 등록돼 있는지"를
/// 확인하는 자리다.
class ProfileController extends GetxController {
  ProfileController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final Rxn<Address> address = Rxn<Address>();
  final Rxn<IntroProfile> introProfile = Rxn<IntroProfile>();
  final RxBool isLoading = true.obs;

  User? get user => _auth.user.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.shippingAddress(),
        _api.introProfile(),
      ]);
      address.value = results[0] as Address;
      introProfile.value = results[1] as IntroProfile;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// "김영희 · 010 1234 5678"
  String get recipientLine {
    final a = address.value;
    if (a == null || !a.isComplete) return '아직 등록하지 않았어요';
    return '${a.recipient} · ${Address.formatPhone(a.phone)}';
  }

  String get addressLine {
    final a = address.value;
    if (a == null || !a.isComplete) return '아직 등록하지 않았어요';
    return a.oneLine;
  }
}
