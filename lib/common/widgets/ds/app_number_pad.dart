import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 화면 하단에 붙는 **앱 자체 숫자 키패드** — Figma 342:686 · 343:718.
///
/// ⚠️ OS 키보드를 쓰지 않는다. 시니어 대상이라 키 크기(56)와 배치를 앱이
///    직접 통제해야 하고, 기종마다 다른 숫자 자판이 뜨면 안내를 할 수 없다.
///    이 키패드를 쓰는 입력칸은 `readOnly: true`로 두고 OS 키보드를 막는다.
///
/// 왼쪽 아래 한 칸은 **빈 칸**이다. 시안에 아무것도 없고, 실수로 눌러도
/// 아무 일이 없어야 해서 [GestureDetector]도 달지 않는다.
class AppNumberPad extends StatelessWidget {
  const AppNumberPad({super.key, required this.onDigit, required this.onBackspace});

  /// 눌린 숫자 한 글자('0'~'9')
  final ValueChanged<String> onDigit;

  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceSoft,
      // ⚠️ 판(배경)은 시안대로 **화면 바닥까지** 내려가지만, 키는 내비게이션
      //    바 위로 들어 올린다. 시안(iPhone)은 홈 인디케이터가 마지막 키 줄에
      //    얹히는 걸 전제로 그렸는데, 안드로이드 내비바는 불투명이라 그대로
      //    두면 `0`·`⌫`가 절반쯤 가린다.
      padding: EdgeInsets.fromLTRB(6, 8, 6, AppInsets.bottom(context, 8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, row) in _rows.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (final (j, key) in row.indexed) ...[
                  if (j > 0) const SizedBox(width: 6),
                  Expanded(child: _Key(label: key, onTap: _handler(key))),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 빈 칸은 콜백이 없다 — [_Key]가 눌리지 않는 판으로 그린다.
  VoidCallback? _handler(String key) => switch (key) {
    '' => null,
    _backspace => onBackspace,
    _ => () => onDigit(key),
  };

  static const _backspace = '⌫';

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', _backspace],
  ];
}

class _Key extends StatefulWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // 빈 칸 — 배경도 그리지 않는다. 키패드 판 색이 그대로 비친다.
    if (widget.onTap == null) {
      return const SizedBox(height: AppDimens.keyHeight);
    }

    final isBackspace = widget.label == AppNumberPad._backspace;
    return Semantics(
      button: true,
      label: isBackspace ? '지우기' : widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          height: AppDimens.keyHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.stone200 : AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusKey),
          ),
          child: Text(
            widget.label,
            style: isBackspace
                // ⌫는 글리프 자체가 커서 숫자보다 작게 잡아야 같은 크기로 보인다.
                ? AppTypography.bodyBase.copyWith(fontSize: 20, height: 1.2)
                : AppTypography.weight(
                    AppTypography.bodyBase,
                    AppTypography.medium,
                  ).copyWith(fontSize: 25, height: 1.2),
          ),
        ),
      ),
    );
  }
}
