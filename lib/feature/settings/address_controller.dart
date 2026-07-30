import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// F4 인쇄본 배송지 수정 — Figma 370:901.
class AddressController extends GetxController {
  AddressController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final recipient = TextEditingController();
  final phone = TextEditingController();
  final postalCode = TextEditingController();
  final line1 = TextEditingController();
  final line2 = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  /// 필드 값이 바뀔 때마다 오르는 값. "저장하기" 활성 판단에 쓴다 —
  /// `TextEditingController`는 Rx가 아니라 Obx가 스스로 갱신되지 않는다.
  final RxInt _revision = 0.obs;

  late final List<TextEditingController> _fields = [
    recipient,
    phone,
    postalCode,
    line1,
    line2,
  ];

  @override
  void onInit() {
    super.onInit();
    for (final f in _fields) {
      f.addListener(_onChanged);
    }
    load();
  }

  @override
  void onClose() {
    for (final f in _fields) {
      f
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.onClose();
  }

  void _onChanged() => _revision.value++;

  Future<void> load() async {
    isLoading.value = true;
    try {
      _apply(await _api.shippingAddress());
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _apply(Address a) {
    recipient.text = a.recipient;
    phone.text = Address.formatPhone(a.phone);
    postalCode.text = a.postalCode;
    line1.text = a.line1;
    line2.text = a.line2;
  }

  Address get draft => Address(
    recipient: recipient.text.trim(),
    // 서버에는 숫자만 보낸다 — 화면에서만 띄어 쓴다.
    phone: phone.text.replaceAll(RegExp(r'\D'), ''),
    postalCode: postalCode.text.trim(),
    line1: line1.text.trim(),
    line2: line2.text.trim(),
  );

  /// 상세 주소는 없어도 된다(단독주택). 나머지 넷은 있어야 책이 도착한다.
  bool get canSave {
    _revision.value; // Obx가 이 getter를 다시 읽게 하는 의존성
    return draft.isComplete && !isSaving.value;
  }

  Future<void> save() async {
    if (!canSave) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isSaving.value = true;
    try {
      _apply(await _api.updateShippingAddress(draft));
      _toast.show('배송지를 저장했어요');
      Get.back();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  /// "주소 찾기" — 우편번호 검색 SDK를 아직 넣지 않았다.
  /// 붙는 자리만 남겨 두고 지금은 안내만 띄운다.
  void searchPostalCode() =>
      _toast.show('주소 찾기는 준비 중이에요', description: '우편번호를 직접 적어 주세요');
}
