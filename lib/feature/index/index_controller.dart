import 'package:get/get.dart';
import 'package:life_legacy/core/route/app_pages.dart';

class IndexController extends GetxController {
  void goToLogin() {
    Get.toNamed(AppRoutes.login);
  }
}
