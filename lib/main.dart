import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:dio/dio.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/api_env.dart';
import 'package:life_legacy/core/network/auth_interceptor.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/core/network/real_api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 고정 — 시안이 390×844 세로 한 가지뿐이다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ⚠️ **화면 전체를 앱이 그린다(edge-to-edge).**
  //
  // 이걸 켜지 않으면 안드로이드 내비게이션 바(약 27dp)만큼 앱 창이 짧아져서
  // 시안의 844 캔버스가 817이 된다. 그러면 **아래에서부터 잰 좌표가 전부
  // 밀린다** — 로그인 버튼 블록이 27px 위로 뜨는 식이다. 시안은 iPhone
  // 프레임이라 홈 인디케이터가 내용 위에 얹히는 걸 전제로 그려져 있다.
  //
  // 상태바·내비바 아이콘은 밝은 배경에 맞춰 어둡게 고정한다.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await Storage.init();

  _registerGlobals();

  runApp(const LifeLegacyApp());
}

/// dio를 세우고 토큰 인터셉터를 붙인다.
///
/// 인터셉터가 만료된 액세스 토큰을 **한 번** 되살려 재시도한다. 그래도
/// 안 되면 세션을 버려서, 다음 앱 시작 때 스플래시가 로그인으로 보낸다.
ApiClient _buildRealApi() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEnv.baseUrl,
      connectTimeout: ApiEnv.connectTimeout,
      receiveTimeout: ApiEnv.receiveTimeout,
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(dio, onSessionExpired: Storage.clearSession),
  );

  return RealApiClient(dio);
}

/// 앱 생애주기 내내 살아있는 싱글턴. 등록 순서가 곧 의존성 순서다.
void _registerGlobals() {
  // ⚠️ **여기가 API 교체 지점이다.** 화면·컨트롤러는 `ApiClient` 추상 타입만
  //    알고 있어서, 목업이든 실제 서버든 손댈 게 없다.
  //    기본은 목업이고 `--dart-define=USE_MOCK=false`로 실제 서버에 붙는다.
  final api = Get.put<ApiClient>(
    ApiEnv.useMock ? MockApiClient() : _buildRealApi(),
    permanent: true,
  );

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
          // 입력칸 **바깥**을 누르면 키보드를 내린다.
          //
          // 화면마다 붙이면 새 입력칸이 생길 때마다 빠뜨린다. 앱 최상단에
          // 한 번만 얹어서 모든 라우트가 자동으로 얻게 했다.
          //
          // ⚠️ `translucent` 라 자식이 안 잡은 탭만 여기로 온다. 버튼·입력칸은
          //    자기 제스처가 먼저 이기므로 영향받지 않는다.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimens.maxContent,
                ),
                // 토스트는 라우트마다 띄우지 않고 여기 한 번만 얹는다.
                child: AppToastHost(
                  service: Get.find<ToastService>(),
                  child: child ?? const SizedBox.shrink(),
                ),
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
