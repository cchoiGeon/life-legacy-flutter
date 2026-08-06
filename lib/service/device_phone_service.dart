import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 기기 전화번호를 읽어 온다 — Android만 지원.
///
/// 1. `READ_PHONE_*` 권한 허용 시 SIM `line1Number` 시도
/// 2. 비어 있으면 Google Phone Number Hint(번호 선택 시트)로 보완
///
/// iOS는 시스템 API로 본인 번호를 읽을 수 없어 항상 null.
class DevicePhoneService {
  DevicePhoneService();

  static const _channel = MethodChannel('kr.lifelegacy.girogi/phone');

  /// 한국 휴대폰 11자리(`010…`)로 정규화. 실패 시 null.
  Future<String?> resolveKoreanMobile() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    final status = await Permission.phone.request();
    if (status.isGranted || status.isLimited) {
      final sim = await _invoke('getSimPhoneNumber');
      final fromSim = normalizeKoreanMobile(sim);
      if (fromSim != null) return fromSim;
    }

    // 권한이 거부됐거나 SIM에 번호가 없으면 Hint 시트로 한 번 더 시도.
    final hint = await _invoke('requestPhoneHint');
    return normalizeKoreanMobile(hint);
  }

  Future<String?> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<String>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// `+82 10-1234-5678`, `01012345678` 등 → `01012345678`.
  static String? normalizeKoreanMobile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('82') && digits.length >= 10) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('10')) {
      digits = '0$digits';
    }
    if (digits.length == 11 && digits.startsWith('01')) return digits;
    return null;
  }
}
