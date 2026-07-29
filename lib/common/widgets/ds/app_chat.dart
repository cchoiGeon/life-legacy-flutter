import 'dart:math' as math;

import 'package:flutter/material.dart' show InputDecoration, TextField;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/data/data_manager.dart';

/// 채팅 말풍선 — Figma `bubble-ai`(130:2265) · `bubble-user`(130:2272).
///
/// 꼬리 쪽 모서리만 4px로 깎아 방향을 표시한다(AI는 왼쪽 위, 사용자는
/// 오른쪽 아래).
class AppChatBubble extends StatelessWidget {
  const AppChatBubble({super.key, required this.role, required this.text});

  final ChatRole role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isAi = role == ChatRole.ai;
    const r = Radius.circular(AppDimens.radiusBubble);
    const tail = Radius.circular(4);

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isAi ? AppColors.chatAiBg : AppColors.chatUserBg,
            borderRadius: BorderRadius.only(
              topLeft: isAi ? tail : r,
              topRight: r,
              bottomLeft: r,
              bottomRight: isAi ? r : tail,
            ),
          ),
          child: Text(
            text,
            style: AppTypography.bodyChat.copyWith(
              color: isAi ? AppColors.textStrong : AppColors.chatUserFg,
            ),
          ),
        ),
      ),
    );
  }
}

/// 채팅 하단 입력줄 — Figma `ChatComposer`(130:2274).
class AppChatComposer extends StatelessWidget {
  const AppChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMic,
    this.hint = '답변을 입력하세요.',
    this.sending = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final String hint;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandFg,
        boxShadow: AppShadows.composer,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stone100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  cursorColor: AppColors.brand,
                  style: AppTypography.bodyChat,
                  textInputAction: TextInputAction.send,
                  onSubmitted: sending ? null : (_) => onSend(),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: AppTypography.bodyChat.copyWith(
                      color: AppColors.stone400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CircleIcon(
              filled: false,
              semanticLabel: '음성으로 답하기',
              onTap: onMic,
              painter: const _MicPainter(color: AppColors.brand),
            ),
            const SizedBox(width: 10),
            _CircleIcon(
              filled: true,
              semanticLabel: '보내기',
              onTap: sending ? null : onSend,
              painter: const _SendPainter(color: AppColors.brandFg),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.filled,
    required this.painter,
    required this.onTap,
    required this.semanticLabel,
  });

  final bool filled;
  final CustomPainter painter;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.brand : AppColors.bubbleSys,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(size: const Size(20, 20), painter: painter),
          ),
        ),
      ),
    );
  }
}

/// 마이크 아이콘 — 둥근 캡슐 + 받침대.
class _MicPainter extends CustomPainter {
  const _MicPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.35, h * 0.1, w * 0.65, h * 0.58),
        Radius.circular(w * 0.15),
      ),
      Paint()..color = color,
    );
    canvas.drawArc(
      Rect.fromLTRB(w * 0.22, h * 0.32, w * 0.78, h * 0.82),
      0,
      math.pi,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.78),
      Offset(w * 0.5, h * 0.92),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_MicPainter old) => old.color != color;
}

/// 보내기 화살표 — 위쪽 방향(시안 15번의 원형 버튼).
class _SendPainter extends CustomPainter {
  const _SendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset(w * 0.5, h * 0.85), Offset(w * 0.5, h * 0.18), p);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.24, h * 0.44)
        ..lineTo(w * 0.5, h * 0.16)
        ..lineTo(w * 0.76, h * 0.44),
      p,
    );
  }

  @override
  bool shouldRepaint(_SendPainter old) => old.color != color;
}
