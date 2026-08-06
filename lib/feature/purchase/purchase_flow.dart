import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/service/services.dart';

import 'purchase_content.dart';

/// 구매 화면 이동 · 웹 구매 안내 · 유료 챕터 게이트.
abstract final class PurchaseFlow {
  static void openList({bool paywall = false}) {
    Get.toNamed(
      AppRoutes.purchase,
      arguments: {'paywall': paywall},
    );
  }

  static void openPlan(String code) {
    Get.toNamed(
      AppRoutes.purchaseDetail,
      arguments: {'code': code.toUpperCase()},
    );
  }

  static void openCoupon() {
    Get.toNamed(AppRoutes.purchaseCoupon);
  }

  /// 2장 이상이면 무료 플랜일 때 구매 화면으로 보내고 false를 반환한다.
  static Future<bool> allowChapter({
    required ApiClient api,
    required String bookId,
    required int chapterOrder,
  }) async {
    if (chapterOrder <= 1) return true;
    try {
      final entitlements = await api.entitlements(bookId);
      final plan = entitlements.planCode.toUpperCase();
      if (plan != 'FREE' && plan.isNotEmpty) return true;
    } on ApiException {
      // 권한 조회 실패 시에도 무료 체험 범위를 넘기지 않는다.
    }
    openList(paywall: true);
    return false;
  }

  /// 웹 구매 전 안내 다이얼로그 → 확인 시 웹사이트 오픈.
  static Future<void> openWebsiteForPurchase(BuildContext context) async {
    final auth = Get.find<AuthService>();
    final user = auth.user.value;
    final needsCredentials = user == null || !user.hasPassword;
    final isKakao = auth.isKakaoLogin;

    final buffer = StringBuffer(PurchaseContent.webOnlyLead);
    if (needsCredentials) {
      buffer
        ..writeln()
        ..writeln()
        ..write(PurchaseContent.credentialsNeeded);
    }
    if (isKakao) {
      buffer
        ..writeln()
        ..writeln()
        ..write(PurchaseContent.kakaoAlsoOk);
    }

    final goWeb = await AppDialog.confirm(
      context,
      title: PurchaseContent.webOnlyTitle,
      message: buffer.toString(),
      confirmLabel: PurchaseContent.openWebsiteLabel,
      cancelLabel: '닫기',
    );

    if (goWeb) await _launchWebsite();
  }

  static Future<void> _launchWebsite() async {
    final toast = Get.find<ToastService>();
    final uri = Uri.parse(PurchaseContent.websiteUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        toast.show('웹사이트를 열 수 없어요', description: PurchaseContent.websiteLabel);
      }
    } catch (_) {
      toast.show('웹사이트를 열 수 없어요', description: PurchaseContent.websiteLabel);
    }
  }
}
