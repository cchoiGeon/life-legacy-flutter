import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 생년월일 입력 — 탭하면 년·월·일 휠 피커 시트가 열린다.
///
/// 순서는 한국식(년→월→일). 라벨은 `1990년` · `3월` · `15일`.
class AppBirthDateField extends StatelessWidget {
  const AppBirthDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = '생년월일을 선택해 주세요',
    this.minimumYear = 1920,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final int minimumYear;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _minimumDate => DateTime(minimumYear, 1, 1);

  /// 자서전 앱 주 사용층에 맞춘 초기 위치.
  DateTime get _initialDate {
    if (value != null) return value!;
    final candidate = DateTime(_today.year - 70, 1, 1);
    if (candidate.isBefore(_minimumDate)) return _minimumDate;
    if (candidate.isAfter(_today)) return _today;
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Semantics(
      button: true,
      label: hasValue ? _format(value!) : hint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPicker(context),
        child: Container(
          height: AppDimens.fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusBase),
            border: Border.all(
              color: hasValue ? AppColors.borderSelected : AppColors.borderSoft,
              width: hasValue
                  ? AppDimens.borderWidthSelected
                  : AppDimens.borderWidthStrong,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? _format(value!) : hint,
                  style: AppTypography.weight(
                    AppTypography.bodyBase,
                    AppTypography.medium,
                  ).copyWith(
                    color:
                        hasValue ? AppColors.textPrimary : AppColors.stone400,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: hasValue ? AppColors.brand : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _BirthDatePickerSheet(
          initial: _initialDate,
          minimumYear: minimumYear,
          maximumDate: _today,
          onConfirm: (date) {
            onChanged(date);
            Navigator.of(sheetContext).pop();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  static String _format(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';
}

class _BirthDatePickerSheet extends StatefulWidget {
  const _BirthDatePickerSheet({
    required this.initial,
    required this.minimumYear,
    required this.maximumDate,
    required this.onConfirm,
    required this.onCancel,
  });

  final DateTime initial;
  final int minimumYear;
  final DateTime maximumDate;
  final ValueChanged<DateTime> onConfirm;
  final VoidCallback onCancel;

  @override
  State<_BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<_BirthDatePickerSheet> {
  late int _year;
  late int _month;
  late int _day;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  List<int> get _years => [
        for (var y = widget.minimumYear; y <= widget.maximumDate.year; y++) y,
      ];

  List<int> get _months {
    final maxMonth = _year == widget.maximumDate.year
        ? widget.maximumDate.month
        : 12;
    return [for (var m = 1; m <= maxMonth; m++) m];
  }

  List<int> get _days {
    final maxInMonth = DateTime(_year, _month + 1, 0).day;
    final maxDay = _year == widget.maximumDate.year &&
            _month == widget.maximumDate.month
        ? widget.maximumDate.day
        : maxInMonth;
    return [for (var d = 1; d <= maxDay; d++) d];
  }

  static final _itemStyle = AppTypography.weight(
    AppTypography.titlePage,
    AppTypography.medium,
  ).copyWith(color: AppColors.textPrimary, height: 1.2);

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _day = widget.initial.day;
    _yearCtrl = FixedExtentScrollController(
      initialItem: _years.indexOf(_year).clamp(0, _years.length - 1),
    );
    _monthCtrl = FixedExtentScrollController(
      initialItem: (_month - 1).clamp(0, _months.length - 1),
    );
    _dayCtrl = FixedExtentScrollController(
      initialItem: (_day - 1).clamp(0, _days.length - 1),
    );
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  void _clampDay() {
    final max = _days.last;
    if (_day > max) _day = max;
  }

  void _onYearChanged(int index) {
    setState(() {
      _year = _years[index];
      if (_month > _months.last) {
        _month = _months.last;
        _monthCtrl.jumpToItem(_month - 1);
      }
      _clampDay();
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      _month = _months[index];
      _clampDay();
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(_day - 1);
      }
    });
  }

  void _onDayChanged(int index) {
    setState(() => _day = _days[index]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    '취소',
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '생년월일',
                    textAlign: TextAlign.center,
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.semibold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      widget.onConfirm(DateTime(_year, _month, _day)),
                  child: Text(
                    '확인',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.semibold,
                    ).copyWith(color: AppColors.brand),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CupertinoPicker(
                      scrollController: _yearCtrl,
                      itemExtent: 40,
                      onSelectedItemChanged: _onYearChanged,
                      children: [
                        for (final y in _years)
                          Center(child: Text('$y년', style: _itemStyle)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: _monthCtrl,
                      itemExtent: 40,
                      onSelectedItemChanged: _onMonthChanged,
                      children: [
                        for (final m in _months)
                          Center(child: Text('$m월', style: _itemStyle)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      scrollController: _dayCtrl,
                      itemExtent: 40,
                      onSelectedItemChanged: _onDayChanged,
                      children: [
                        for (final d in _days)
                          Center(child: Text('$d일', style: _itemStyle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
