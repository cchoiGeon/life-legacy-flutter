import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// 마이크 녹음 — 전사는 서버 Clova STT([ApiClient.transcribeAudio]).
class SpeechService extends GetxService {
  AudioRecorder? _recorder;

  AudioRecorder get _rec => _recorder ??= AudioRecorder();

  /// 녹음을 쓸 수 있는지. [init] 전에는 null.
  final RxnBool available = RxnBool();

  final RxBool isListening = false.obs;

  /// 서버 전사 전엔 부분 결과가 없다. 녹음 중 안내 문구로만 쓴다.
  final RxString partial = ''.obs;

  final RxnString error = RxnString();

  String? _path;
  DateTime? _startedAt;

  Future<SpeechService> init() async {
    try {
      final ok = await _rec.hasPermission();
      available.value = ok;
      if (!ok) error.value = '마이크 권한이 필요해요';
    } on Exception {
      available.value = false;
      error.value = '이 기기에서는 음성 입력을 쓸 수 없어요';
    }
    return this;
  }

  /// 녹음 시작. onFinal은 호환용(무시) — 멈춘 뒤 서버 STT를 탄다.
  Future<bool> start({void Function(String text)? onFinal}) async {
    if (available.value != true) {
      error.value = error.value ?? '이 기기에서는 음성 인식을 쓸 수 없어요';
      return false;
    }
    if (isListening.value) return true;

    partial.value = '듣고 있어요…';
    error.value = null;

    try {
      final dir = await getTemporaryDirectory();
      _path =
          '${dir.path}/ll_stt_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _path!,
      );
      _startedAt = DateTime.now();
      isListening.value = true;
      return true;
    } on Exception {
      available.value = false;
      error.value = '마이크를 열지 못했어요';
      isListening.value = false;
      return false;
    }
  }

  /// 녹음 종료 후 업로드할 바이트. 실패면 null.
  Future<({List<int> bytes, int durationMs, String filename})?>
      stopToAudio() async {
    try {
      final path = await _rec.stop() ?? _path;
      isListening.value = false;
      partial.value = '';
      final durationMs = _startedAt == null
          ? 0
          : DateTime.now().difference(_startedAt!).inMilliseconds;
      _startedAt = null;
      _path = null;
      if (path == null || path.isEmpty) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      try {
        await file.delete();
      } catch (_) {}
      if (bytes.isEmpty) return null;
      return (bytes: bytes, durationMs: durationMs, filename: 'audio.m4a');
    } on Exception {
      isListening.value = false;
      partial.value = '';
      return null;
    }
  }

  Future<void> stop() async {
    if (!isListening.value) return;
    await _rec.stop();
    isListening.value = false;
  }

  Future<void> cancel() async {
    try {
      if (await _rec.isRecording()) await _rec.stop();
    } catch (_) {}
    isListening.value = false;
    partial.value = '';
    _path = null;
    _startedAt = null;
  }
}
