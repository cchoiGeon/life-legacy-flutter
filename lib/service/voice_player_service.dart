import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// 서버 TTS(mp3) 재생 — Clova 키는 앱에 두지 않는다.
class VoicePlayerService extends GetxService {
  final AudioPlayer _player = AudioPlayer();
  final RxBool isPlaying = false.obs;

  /// 0.0 ~ 1.0. 작성 진입 보이스 점검·질문 TTS에 같이 쓴다.
  final RxDouble volume = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  Future<void> setVolume(double value) async {
    volume.value = value.clamp(0.0, 1.0);
    await _player.setVolume(volume.value);
  }

  /// mp3를 재생한다. 로딩된 길이를 돌려줘 타이핑 애니와 맞출 수 있다.
  Future<Duration?> playMpeg(List<int> bytes) async {
    if (bytes.isEmpty) return null;
    await stop();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ll_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(bytes, flush: true);
    final duration = await _player.setFilePath(file.path);
    await _player.setVolume(volume.value);
    await _player.play();
    // 재생이 끝날 때까지 기다린다 (청크 순차 재생용).
    await _player.processingStateStream.firstWhere(
      (s) => s == ProcessingState.completed || s == ProcessingState.idle,
    );
    return duration;
  }

  Future<void> stop() async {
    if (_player.playing) await _player.stop();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
