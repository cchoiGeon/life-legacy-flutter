import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 라벨 + 입력칸 — Figma `sec/폼 · Forms`(130:2153).
///
/// 시니어 대상이라 시안의 입력 글자가 15px로 큰 편이고 테두리도 1.5px로
/// 두껍다. 에러는 테두리 색과 아래 문구로만 알린다.
///
/// 테두리·배경은 [Container]가 그리고 [TextField]는 `collapsed` 데코레이션으로
/// 알맹이만 담당한다. Material의 기본 밑줄·플로팅 라벨을 끄고 시안 모양을
/// 맞추는 가장 짧은 방법이다.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.textStyle,
    this.height,
    this.readOnly = false,
    this.showCursor,
    this.obscureText = false,
  });

  final String? label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;

  /// null이 아니면 에러 상태.
  final String? errorText;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 입력칸 오른쪽에 붙는 것(마이크 아이콘 등)
  final Widget? suffix;

  /// 전화번호처럼 크게 보여야 하는 입력에서 글자 크기를 키운다.
  final TextStyle? textStyle;

  /// 고정 높이. 시안 A·F의 한 줄 입력칸은 모두 [AppDimens.fieldHeight]다.
  /// null이면 패딩이 높이를 정한다(여러 줄 입력).
  final double? height;

  /// [AppNumberPad]가 값을 넣는 입력칸은 OS 키보드가 뜨면 안 된다.
  /// `readOnly: true` + `showCursor: true` 조합으로 커서만 남긴다.
  final bool readOnly;

  final bool? showCursor;

  /// 비밀번호 입력용.
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final style = textStyle ?? AppTypography.bodyChat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.weight(
              AppTypography.caption,
              AppTypography.medium,
            ).copyWith(color: AppColors.textStrong),
          ),
          const SizedBox(height: AppDimens.space2),
        ],
        Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: height == null ? 14 : 20,
            vertical: height == null ? 12 : 0,
          ),
          alignment: height == null ? null : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusBase),
            border: Border.all(
              color: hasError ? AppColors.destructive : AppColors.borderSoft,
              width: AppDimens.borderWidthStrong,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  showCursor: showCursor,
                  obscureText: obscureText,
                  style: style.copyWith(
                    color: hasError
                        ? AppColors.destructive
                        : AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.brand,
                  maxLines: obscureText ? 1 : maxLines,
                  minLines: obscureText ? 1 : minLines,
                  autofocus: autofocus,
                  textAlign: textAlign,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: style.copyWith(color: AppColors.stone400),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: AppDimens.space2),
                suffix!,
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppDimens.space2),
          Text(
            errorText!,
            style: AppTypography.label.copyWith(color: AppColors.destructive),
          ),
        ],
      ],
    );
  }
}

/// 6자리 인증번호 칸 — Figma 343:702 (A5) · 343:761 (A6 에러).
///
/// **입력을 받지 않는 표시 전용 위젯이다.** 값은 [AppNumberPad]가 컨트롤러에
/// 넣고 이 위젯은 [value]를 그리기만 한다. 예전에는 칸 뒤에 투명 [TextField]를
/// 숨겨 OS 키보드를 받았지만, 시안이 앱 자체 키패드로 바뀌면서 그 숨은 필드가
/// OS 키보드를 불러 화면을 밀어 올리는 원인이 됐다.
class AppCodeBoxes extends StatelessWidget {
  const AppCodeBoxes({
    super.key,
    required this.value,
    this.length = 6,
    this.hasError = false,
  });

  /// 지금까지 입력된 숫자. [length]보다 길면 앞에서 잘라 그린다.
  final String value;

  final int length;

  /// 인증 실패. 모든 칸이 빨간 테두리가 된다.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final text = value.length > length ? value.substring(0, length) : value;

    return Row(
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimens.space2),
          Expanded(child: _box(i, text)),
        ],
      ],
    );
  }

  Widget _box(int index, String text) {
    final filled = index < text.length;

    // 다음에 채워질 칸만 브랜드색으로 굵게 — 어디를 누르고 있는지 알려준다.
    final isCursor = !hasError && index == text.length;

    final (color, width) = switch ((hasError, isCursor)) {
      (true, _) => (AppColors.destructive, AppDimens.borderWidthSelected),
      (_, true) => (AppColors.borderSelected, AppDimens.borderWidthSelected),
      _ => (AppColors.borderSoft, AppDimens.borderWidthStrong),
    };

    return Container(
      height: AppDimens.fieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusBase),
        border: Border.all(color: color, width: width),
      ),
      child: Text(
        filled ? text[index] : '',
        style: AppTypography.weight(
          AppTypography.titlePage,
          AppTypography.bold,
        ).copyWith(
          color: hasError ? AppColors.destructive : AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}
