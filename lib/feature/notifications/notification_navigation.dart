import 'package:get/get.dart';

import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 알림 탭 → 화면 이동. 홈 드롭다운과 알림 센터가 같이 쓴다.
abstract final class NotificationNavigation {
  /// 타입·딥링크 id로 목적지를 고른다. 책 id가 있으면 현재 책으로 저장한다.
  static Future<void> open(
    AppNotification notification, {
    required ToastService toast,
  }) async {
    final bookId = notification.bookId ?? Storage.currentBookId;
    if (notification.bookId != null) {
      await Storage.saveCurrentBookId(notification.bookId!);
    }

    switch (notification.type) {
      case NotificationType.dailyQuestion:
        if (bookId == null) {
          toast.show('아직 만든 자서전이 없어요');
          Get.offNamed(AppRoutes.intro);
          return;
        }
        Get.offNamed(
          AppRoutes.write,
          arguments: {
            'bookId': bookId,
            if (notification.questionId != null)
              'questionId': notification.questionId,
          },
        );
        return;

      case NotificationType.chapterDone:
        if (bookId == null) {
          toast.show('책 정보를 찾을 수 없어요');
          return;
        }
        final chapterId = notification.chapterId;
        if (chapterId == null) {
          Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId});
          return;
        }
        Get.offNamed(
          AppRoutes.bookReview,
          arguments: {'bookId': bookId, 'chapterId': chapterId},
        );
        return;

      case NotificationType.bookReady:
        if (bookId == null) {
          toast.show('책 정보를 찾을 수 없어요');
          return;
        }
        Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId});
        return;

      default:
        if (bookId != null) {
          Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId});
          return;
        }
        Get.offNamed(AppRoutes.home);
    }
  }
}
