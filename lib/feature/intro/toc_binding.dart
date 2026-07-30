import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'toc_controller.dart';

/// B6(목차 준비 중)·B7(목차 제안) 공통 바인딩.
///
/// ⚠️ `lazyPut`이 아니라 **`put`(즉시 생성)** 이다.
///
/// B6은 도는 링만 보여주는 화면이라 [TocLoadingView]가 컨트롤러를 읽지 않는다.
/// `lazyPut`이면 `Get.find`를 부르는 사람이 없어 컨트롤러가 만들어지지 않고,
/// `onInit`의 목차 생성이 시작되지 않아 **"목차를 만들고 있어요"에서 멈춘다.**
///
/// 라우트마다 바인딩이 새로 도므로 B6 → B7로 `offNamed` 할 때 컨트롤러도 새로
/// 만들어진다. 그래서 목차는 필드가 아니라 **라우트 인자**로 넘어온다
/// (`toc_controller_test.dart` 가 이 규칙을 잠가 뒀다).
class TocBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TocController(Get.find<ApiClient>(), Get.find<ToastService>()));
  }
}
