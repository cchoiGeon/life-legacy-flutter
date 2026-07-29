import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType, showDialog;
import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/service/services.dart';

import 'app_button.dart';

/// 확인 다이얼로그 — Figma `Dialog`(130:2201).
abstract final class AppDialog {
  /// [confirmLabel]을 누르면 true, 그 외에는 null/false로 닫힌다.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = '확인',
    String cancelLabel = '닫기',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlayScrim,
      builder: (ctx) => Semantics(
        scopesRoute: true,
        namesRoute: true,
        // ⚠️ `scopesRoute: true`면 `explicitChildNodes: true`가 강제다
        //    (rendering/object.dart의 assert). 빼면 다이얼로그를 띄우는
        //    순간 빌드가 터진다.
        explicitChildNodes: true,
        label: title,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              // ⚠️ `showDialog`는 `Material`을 깔아주지 않는다. 없으면
              //    WidgetsApp의 "빠졌다" 표시용 기본 TextStyle이 상속돼
              //    모든 글자에 노란 이중 밑줄이 그려진다.
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.space5),
                  decoration: BoxDecoration(
                    color: AppColors.brandFg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSheet),
                    boxShadow: AppShadows.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.weight(
                          AppTypography.titleSection,
                          AppTypography.bold,
                        ).copyWith(color: AppColors.textStrong),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          message,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: cancelLabel,
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.neutral,
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          const SizedBox(width: AppDimens.space2),
                          AppButton(
                            label: confirmLabel,
                            size: AppButtonSize.sm,
                            variant: danger
                                ? AppButtonVariant.danger
                                : AppButtonVariant.primary,
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

/// 화면 위에 잠깐 떠 있는 토스트 — Figma `Toast`(130:2210).
///
/// [ToastService]의 값을 구독해 그린다. 라우트마다 따로 띄우지 않고
/// 앱 껍데기(main.dart의 builder)에 한 번만 얹는다.
class AppToastHost extends StatefulWidget {
  const AppToastHost({super.key, required this.service, required this.child});

  final ToastService service;
  final Widget child;

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  ToastMessage? _shown;
  StreamSubscription<ToastMessage?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.service.current.listen(_onMessage);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onMessage(ToastMessage? m) {
    if (!mounted) return;
    setState(() => _shown = m);
    if (m == null) return;
    // 3초 뒤 자동으로 사라진다. 그 사이 새 토스트가 오면 아래 조건에서
    // 걸러져 새 것을 지우지 않는다.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && identical(_shown, m)) widget.service.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _shown;
    return Stack(
      children: [
        widget.child,
        if (m != null)
          Positioned(
            left: AppDimens.space4,
            right: AppDimens.space4,
            bottom: 90,
            child: SafeArea(
              // 토스트는 손가락 아래를 가리기만 하고 눌러도 통과시킨다.
              child: IgnorePointer(child: _Toast(message: m)),
            ),
          ),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});

  final ToastMessage message;

  @override
  Widget build(BuildContext context) {
    final dot = message.kind == ToastKind.error
        ? AppColors.destructive
        : AppColors.accentSoft;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
      decoration: BoxDecoration(
        color: AppColors.brandFg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: AppTypography.weight(
                    AppTypography.bodySm,
                    AppTypography.medium,
                  ).copyWith(color: AppColors.textStrong),
                ),
                if (message.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    message.description!,
                    style: AppTypography.label.copyWith(
                      color: AppColors.stone500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
