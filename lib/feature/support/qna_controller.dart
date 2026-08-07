import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 문의 작성 · 내 문의.
class QnaController extends GetxController {
  QnaController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final questionController = TextEditingController();
  final RxList<QnaItem> items = <QnaItem>[].obs;
  final RxList<FaqCategory> categories = <FaqCategory>[].obs;
  final RxnString selectedCategoryId = RxnString();
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  bool get canSubmit =>
      questionController.text.trim().length >= 5 && !isSubmitting.value;

  @override
  void onInit() {
    super.onInit();
    questionController.addListener(_onTextChanged);
    load();
  }

  void _onTextChanged() => update(['composer']);

  @override
  void onClose() {
    questionController.removeListener(_onTextChanged);
    questionController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.myQna(),
        _api.faq(),
      ]);
      items.value = results[0] as List<QnaItem>;
      categories.value = (results[1] as FaqCatalog).categories;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String? id) {
    selectedCategoryId.value = id;
  }

  Future<void> submit() async {
    if (!canSubmit) return;
    isSubmitting.value = true;
    try {
      final created = await _api.createQna(
        question: questionController.text.trim(),
        category: selectedCategoryId.value,
      );
      items.insert(0, created);
      questionController.clear();
      selectedCategoryId.value = null;
      _toast.show('문의를 접수했어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
      update(['composer']);
    }
  }
}
