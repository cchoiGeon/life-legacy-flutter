import 'dart:io';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// 서버 TTS(mp3) 재생 — Clova 키는 앱에 두지 않는다.
class VoicePlayerService extends GetxService {
  final AudioPlayer _player = AudioPlayer();
  final RxBool isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });
  }

  Future<void> playMpeg(List<int> bytes) async {
    if (bytes.isEmpty) return;
    await stop();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/ll_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(bytes, flush: true);
    await _player.setFilePath(file.path);
    await _player.play();
    // 재생이 끝날 때까지 기다린다 (청크 순차 재생용).
    await _player.processingStateStream.firstWhere(
      (s) => s == ProcessingState.completed || s == ProcessingState.idle,
    );
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
