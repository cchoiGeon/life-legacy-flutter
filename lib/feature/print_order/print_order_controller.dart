import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 종이책 주문 화면 상태.
class PrintOrderController extends GetxController {
  PrintOrderController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final Rxn<Book> book = Rxn<Book>();
  final Rxn<Address> address = Rxn<Address>();
  final RxInt quantity = 4.obs;
  final noteController = TextEditingController();

  late final String bookId;

  @override
  void onInit() {
    super.onInit();
    bookId = _resolveBookId();
    load();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  String _resolveBookId() {
    final args = Get.arguments;
    if (args is Map && args['bookId'] is String) {
      return args['bookId'] as String;
    }
    final stored = Storage.currentBookId;
    if (stored != null) return stored;
    throw const ApiException('책을 선택해 주세요');
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      book.value = await _api.book(bookId);
      address.value = await _api.shippingAddress();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAddress() async {
    try {
      address.value = await _api.shippingAddress();
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  void setQuantity(int value) {
    if (value < 4) return;
    if (value > 50) return;
    quantity.value = value;
  }

  Future<void> openAddressEditor() async {
    await Get.toNamed(AppRoutes.settingsAddress);
    await refreshAddress();
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    final addr = address.value;
    if (addr == null || !addr.isComplete) {
      _toast.show('배송지를 먼저 등록해 주세요');
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await _api.createPrintOrder(
        bookId: bookId,
        quantity: quantity.value,
        note: noteController.text,
      );
      await Get.offNamed(
        AppRoutes.printOrderSuccess,
        arguments: {
          'order': result,
          'bookTitle': book.value?.title ?? '나의 자서전',
          'address': addr,
        },
      );
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
