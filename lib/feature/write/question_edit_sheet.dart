import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// D10 질문 문구 고치기.
///
/// `⋯` 메뉴에서 연다. 시안에 없던 화면이라 **전용 화면 대신 바텀시트**로
/// 만들었다 — 질문을 고치는 건 답하다 잠깐 들르는 일이지 별도 단계가
/// 아니어서, 화면을 넘겨 버리면 하던 이야기의 맥이 끊긴다.
///
/// 고칠 수 있는 건 문구뿐이다. 질문을 더하거나 빼는 길은 두지 않았다.
///
/// 고친 문구를 돌려주고, 취소하거나 그대로면 null을 돌려준다.
Future<String?> showQuestionEditSheet(
  BuildContext context, {
  required String question,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.background,
    // 키보드가 올라오면 시트가 그만큼 밀려 올라가야 입력칸이 가리지 않는다.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusSheet),
      ),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _QuestionEditBody(question: question),
    ),
  );
}

/// ⚠️ 입력 컨트롤러를 **이 위젯이 소유한다.**
///
/// 바깥에서 만들어 `showModalBottomSheet(...).whenComplete(dispose)`로
/// 정리하면, 닫히는 애니메이션이 끝나기 전에 컨트롤러가 죽어서
/// "A TextEditingController was used after being disposed"가 난다.
/// 위젯이 들고 있으면 트리에서 빠질 때 함께 정리된다.
class _QuestionEditBody extends StatefulWidget {
  const _QuestionEditBody({required this.question});

  final String question;

  @override
  State<_QuestionEditBody> createState() => _QuestionEditBodyState();
}

class _QuestionEditBodyState extends State<_QuestionEditBody> {
  late final controller = TextEditingController(text: widget.question);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          AppDimens.space6,
          AppDimens.gutter,
          AppDimens.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // 버튼이 폭을 채우게 한다 — 앱의 다른 시트·화면이 모두 전체 폭이라
          // 여기만 글자 크기로 쪼그라들면 누르는 자리가 좁아지고 낯설어진다.
          // 글자는 textAlign 기본값(왼쪽)이라 늘려도 그대로 붙어 있는다.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('질문을 고쳐 주세요', style: AppTypography.titleSerifSm),
            const SizedBox(height: AppDimens.space2),
            Text(
              '이 질문은 나에게만 바뀌어요',
              style: AppTypography.subtitle.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppDimens.space5),
            AppField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              hint: '묻고 싶은 말을 적어 주세요',
            ),
            const SizedBox(height: AppDimens.space5),
            // ⚠️ setState로 시트 전체를 다시 그리지 않는다. 그러면 글자를
            //    칠 때마다 입력칸까지 새로 만들어져 포커스가 흔들린다.
            //    버튼 하나만 컨트롤러를 듣게 한다.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => AppButton(
                label: '이렇게 고칠게요',
                enabled: value.text.trim().isNotEmpty,
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
              ),
            ),
            const SizedBox(height: AppDimens.space3),
            AppButton(
              label: '그만두기',
              variant: AppButtonVariant.neutral,
              size: AppButtonSize.assist,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
