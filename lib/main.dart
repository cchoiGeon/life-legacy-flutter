import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 고정 — 시안이 390×844 세로 한 가지뿐이다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Storage.init();

  _registerGlobals();

  runApp(const LifeLegacyApp());
}

/// 앱 생애주기 내내 살아있는 싱글턴. 등록 순서가 곧 의존성 순서다.
void _registerGlobals() {
  // ⚠️ **여기가 API 교체 지점이다.** 실제 서버가 정해지면 이 한 줄을
  //    `Get.put<ApiClient>(RealApiClient(...))` 로 바꾸면 된다.
  //    화면·컨트롤러는 `ApiClient` 추상 타입만 알고 있어서 손댈 게 없다.
  final api = Get.put<ApiClient>(MockApiClient(), permanent: true);

  Get.put(AuthService(api), permanent: true);
  Get.put(ToastService(), permanent: true);

  // 음성 인식은 서버가 아니라 **단말 기능**이라 ApiClient 바깥에 둔다.
  // init()은 권한 요청을 포함하고, 실패해도 예외를 던지지 않는다 —
  // 음성이 안 되는 기기에서도 키보드 입력으로 앱을 쓸 수 있어야 한다.
  Get.put(SpeechService(), permanent: true).init();
}

class LifeLegacyApp extends StatelessWidget {
  const LifeLegacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Life Legacy',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      theme: _theme,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('ko', 'KR'),

      builder: (context, child) {
        // 시니어 대상이라 시스템 글자 크기를 존중하되, 레이아웃이 깨지는
        // 극단값(2.0배 등)은 막는다. 시안 자체가 이미 큰 편이다.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppDimens.maxContent),
              // 토스트는 라우트마다 띄우지 않고 여기 한 번만 얹는다.
              child: AppToastHost(
                service: Get.find<ToastService>(),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  static ThemeData get _theme => ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.fontFamily,
    scaffoldBackgroundColor: AppColors.surfacePage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.background,
      error: AppColors.destructive,
    ),
    // 시안에 물결 효과가 없다. 눌림은 컴포넌트가 축소로 표현한다.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.brand,
      selectionColor: AppColors.bubbleSys,
      selectionHandleColor: AppColors.brand,
    ),
  );
}
