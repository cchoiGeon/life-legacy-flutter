import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// FAQ + 게시 QnA.
class FaqController extends GetxController {
  FaqController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final Rxn<FaqCatalog> catalog = Rxn<FaqCatalog>();
  final RxList<PublishedQna> published = <PublishedQna>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString selectedCategoryId = RxnString();
  final RxList<String> expandedKeys = <String>[].obs;

  List<FaqSection> get visibleSections {
    final all = catalog.value?.sections ?? const [];
    final id = selectedCategoryId.value;
    if (id == null) return all;
    return all.where((s) => s.id == id).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.faq(),
        _api.publishedQna(),
      ]);
      catalog.value = results[0] as FaqCatalog;
      published.value = results[1] as List<PublishedQna>;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String? id) {
    selectedCategoryId.value = id;
  }

  void toggleExpanded(String key) {
    if (expandedKeys.contains(key)) {
      expandedKeys.remove(key);
    } else {
      expandedKeys.add(key);
    }
  }

  void openQna() => Get.toNamed(AppRoutes.settingsQna);
}
