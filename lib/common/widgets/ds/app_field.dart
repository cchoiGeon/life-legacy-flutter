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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusBase),
            border: Border.all(
              color: hasError ? AppColors.destructive : AppColors.stone200,
              width: AppDimens.borderWidthStrong,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: style.copyWith(
                    color: hasError
                        ? AppColors.destructive
                        : AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.brand,
                  maxLines: maxLines,
                  minLines: minLines,
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

/// 6자리 인증번호 입력 — Figma 05·06번 화면.
///
/// 칸은 여섯 개로 보이지만 입력은 **투명한 필드 하나**가 받는다.
/// 칸마다 TextField를 두면 지우기·붙여넣기·포커스 이동이 전부 특수 케이스가
/// 되기 때문이다.
class AppCodeInput extends StatefulWidget {
  const AppCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;

  /// 마지막 칸까지 채워지면 호출된다.
  final ValueChanged<String>? onCompleted;

  @override
  State<AppCodeInput> createState() => _AppCodeInputState();
}

class _AppCodeInputState extends State<AppCodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimens.space2),
                Expanded(child: _cell(i, text)),
              ],
            ],
          ),
          // 실제 입력을 받는 투명 필드. 눈에 보이지 않지만 키패드·붙여넣기는
          // 여기로 들어온다. `Opacity(0)`이라 IME 후보창 위치가 칸 위에 잡힌다.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                showCursor: false,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int index, String text) {
    final filled = index < text.length;
    final char = filled ? text[index] : '';

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusBase),
        border: Border.all(
          color: widget.hasError
              ? AppColors.destructive
              : (filled ? AppColors.stone400 : AppColors.stone200),
          width: AppDimens.borderWidthStrong,
        ),
      ),
      child: Text(
        char,
        style: AppTypography.weight(AppTypography.headingXl, AppTypography.bold)
            .copyWith(
              color: widget.hasError ? AppColors.destructive : AppColors.brand,
            ),
      ),
    );
  }
}
