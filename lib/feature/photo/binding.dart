import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

import 'photo_attach_controller.dart';

/// 책 사진첩 컨트롤러.
class PhotoAlbumController extends GetxController {
  PhotoAlbumController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  late final String bookId;

  final RxBool isLoading = true.obs;
  final Rx<BookPhotosResponse?> response = Rx<BookPhotosResponse?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    bookId = args['bookId'] as String;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      response.value = await _api.bookPhotos(bookId);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }
}

/// 장 사진 상세 컨트롤러 (G4 + chapter-read).
class ChapterPhotoDetailController extends GetxController {
  ChapterPhotoDetailController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  late final String bookId;
  late final String chapterId;
  late final String chapterTitle;
  late final int chapterOrder;

  final RxBool isLoading = true.obs;
  final Rx<ChapterPhotosDetail?> detail = Rx<ChapterPhotosDetail?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    bookId = args['bookId'] as String;
    chapterId = args['chapterId'] as String;
    chapterTitle = args['chapterTitle'] as String? ?? '';
    chapterOrder = args['chapterOrder'] as int? ?? 0;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      detail.value = await _api.chapterPhotosDetail(bookId, chapterId);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }
}

/// G1~G4 binding
class PhotoAttachBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PhotoAttachController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}

/// 사진첩 binding
class PhotoAlbumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PhotoAlbumController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}

/// 장 사진 상세 binding
class ChapterPhotoDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ChapterPhotoDetailController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}