import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:life_legacy/data/data_manager.dart';

/// 테스트에서 컨트롤러를 세우기 전에 한 번 부른다.
///
/// ⚠️ [Storage]는 GetStorage를 쓰고, GetStorage는 path_provider 플러그인을
///    부른다. 테스트에는 플러그인이 없어 `MissingPluginException`이 난다 —
///    채널을 가로채 임시 디렉터리를 돌려준다.
///
/// ⚠️ 컨트롤러들이 `Get.toNamed`·`Get.offNamed`를 부른다. 네비게이터가 없는
///    테스트에서 실제 라우팅을 타지 않도록 GetX 테스트 모드를 켠다.
Future<void> initTestEnv(String name) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;

  final dir = await Directory.systemTemp.createTemp('life_legacy_$name');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => dir.path,
      );
  await Storage.init();
}
