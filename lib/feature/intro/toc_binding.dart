import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'toc_controller.dart';

/// 09·10 공통 바인딩.
///
/// `fenix: true` — 09(로딩)에서 10(확인)으로 `offNamed`로 넘어가면 09가
/// 스택에서 빠지면서 컨트롤러가 지워질 수 있다. 다시 만들어 주도록 한다.
class TocBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => TocController(Get.find<ApiClient>(), Get.find<ToastService>()),
      fenix: true,
    );
  }
}
