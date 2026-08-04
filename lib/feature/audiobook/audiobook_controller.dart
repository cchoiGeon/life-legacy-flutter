import 'dart:io';

import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 06-1-2 오디오북 — CLOVA TTS 생성은 서버에서 처리.
class AudiobookController extends GetxController {
  AudiobookController(this._api, this._toast, this._player);

  final ApiClient _api;
  final ToastService _toast;
  final VoicePlayerService _player;

  final RxBool isLoading = true.obs;
  final RxBool isWorking = false.obs;
  final Rxn<AudiobookOverview> overview = Rxn<AudiobookOverview>();
  final RxList<AudiobookVoice> voices = <AudiobookVoice>[].obs;
  final RxList<AudiobookBgmTrack> bgms = <AudiobookBgmTrack>[].obs;
  final RxnString selectedVoiceCode = RxnString();
  /// null = BGM 끄기
  final RxnString selectedBgmId = RxnString();
  final RxnString activeJobId = RxnString();

  late final String bookId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['bookId'] is String) {
      bookId = args['bookId'] as String;
    } else {
      bookId = Storage.currentBookId ?? '';
    }
    load();
  }

  @override
  void onClose() {
    _player.stop();
    super.onClose();
  }

  Future<void> load() async {
    if (bookId.isEmpty) {
      _toast.showError(const ApiException('책을 선택해 주세요'));
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      overview.value = await _api.audiobook(bookId);
      if (overview.value?.allowed == true) {
        voices.assignAll(await _api.audiobookVoices(bookId));
        selectedVoiceCode.value = voices
                .where((v) => v.isDefault)
                .map((v) => v.voiceCode)
                .firstOrNull ??
            voices.firstOrNull?.voiceCode;
        bgms.assignAll(await _api.audiobookBgms(bookId));
        selectedBgmId.value ??= bgms.firstOrNull?.id;
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectVoice(String code) => selectedVoiceCode.value = code;

  void selectBgm(String? id) => selectedBgmId.value = id;

  Future<void> previewSelectedVoice() async {
    final voice = selectedVoiceCode.value;
    if (voice == null) {
      _toast.show('목소리를 선택해 주세요');
      return;
    }
    isWorking.value = true;
    try {
      final bytes = await _api.audiobookVoicePreview(bookId, voice);
      if (bytes.isEmpty) {
        _toast.show('미리듣기를 만들지 못했어요');
        return;
      }
      isWorking.value = false;
      await _player.playMpeg(bytes);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> createForChapter(AudiobookChapterStatus chapter) async {
    if (chapter.state == 'not_ready') {
      _toast.show('리뷰를 먼저 저장해 주세요');
      return;
    }
    if (chapter.remainingGenerations <= 0) {
      _toast.show('이 장의 생성 횟수를 모두 썼어요');
      return;
    }
    final voice = selectedVoiceCode.value;
    if (voice == null) {
      _toast.show('목소리를 선택해 주세요');
      return;
    }

    final voiceName =
        voices.where((v) => v.voiceCode == voice).firstOrNull?.name ?? voice;
    final bgmName = selectedBgmId.value == null
        ? '없음'
        : (bgms.where((b) => b.id == selectedBgmId.value).firstOrNull?.title ??
            '선택됨');

    final ctx = Get.context;
    if (ctx == null) return;
    final ok = await AppDialog.confirm(
      ctx,
      title: '음성책을 만들까요?',
      message:
          '제${chapter.order}장 · $voiceName\nBGM · $bgmName\n잔여 ${chapter.remainingGenerations}회',
      confirmLabel: '만들기',
      cancelLabel: '취소',
    );
    if (!ok) return;

    isWorking.value = true;
    try {
      final created = await _api.createAudiobookJob(
        bookId: bookId,
        chapterId: chapter.chapterId,
        voiceCode: voice,
        bgmTrackId: selectedBgmId.value,
        idempotencyKey:
            'ab_${chapter.chapterId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      activeJobId.value = created.jobId;
      _toast.show('음성책을 만들고 있어요', description: '잠시만 기다려 주세요');
      await _pollJob(created.jobId);
      activeJobId.value = null;
      await load();
    } on ApiException catch (e) {
      activeJobId.value = null;
      _toast.showError(e);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> cancelActiveJob() async {
    final jobId = activeJobId.value;
    if (jobId == null) return;
    final ctx = Get.context;
    if (ctx == null) return;
    final ok = await AppDialog.confirm(
      ctx,
      title: '생성을 멈출까요?',
      message: '지금까지 만든 내용은 저장되지 않아요',
      confirmLabel: '멈추기',
      cancelLabel: '계속',
    );
    if (!ok) return;
    try {
      await _api.cancelAudiobookJob(bookId, jobId);
      activeJobId.value = null;
      _toast.show('생성을 멈췄어요');
      await load();
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  Future<void> cancelChapterJob(AudiobookChapterStatus chapter) async {
    final jobId = chapter.latestJob?.id;
    if (jobId == null) return;
    final ctx = Get.context;
    if (ctx == null) return;
    final ok = await AppDialog.confirm(
      ctx,
      title: '생성을 멈출까요?',
      message: '제${chapter.order}장 생성을 취소합니다',
      confirmLabel: '멈추기',
      cancelLabel: '계속',
    );
    if (!ok) return;
    isWorking.value = true;
    try {
      await _api.cancelAudiobookJob(bookId, jobId);
      _toast.show('생성을 멈췄어요');
      await load();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> _pollJob(String jobId) async {
    for (var i = 0; i < 60; i++) {
      if (activeJobId.value != jobId) {
        throw const ApiException('음성책 생성이 중단됐어요', code: 'CANCELLED');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      final status = await _api.audiobookJob(bookId, jobId);
      if (status.status == 'completed') {
        _toast.show('음성책이 준비됐어요');
        return;
      }
      if (status.status == 'failed' || status.status == 'cancelled') {
        throw ApiException(
          status.errorCode == 'TTS_FAILED'
              ? '음성책을 만들지 못했어요'
              : '음성책 생성이 중단됐어요',
          code: status.errorCode,
        );
      }
    }
    _toast.show('아직 만들고 있어요', description: '조금 뒤 화면을 새로고침해 보세요');
  }

  Future<void> playChapter(AudiobookChapterStatus chapter) async {
    isWorking.value = true;
    try {
      final bytes = await _api.audiobookChapterAudio(
        bookId,
        chapter.chapterId,
      );
      if (bytes.isEmpty) {
        _toast.show('재생할 파일이 없어요');
        return;
      }
      isWorking.value = false;
      await _player.playMpeg(bytes);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> downloadChapter(AudiobookChapterStatus chapter) async {
    isWorking.value = true;
    try {
      final bytes = await _api.audiobookChapterAudio(
        bookId,
        chapter.chapterId,
        download: true,
      );
      if (bytes.isEmpty) {
        _toast.show('받을 파일이 없어요');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/audiobook_ch${chapter.order}_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _toast.show(
          '파일을 저장했어요',
          description: file.path,
        );
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> stopPlayback() => _player.stop();

  void onUpgradeTap() => _toast.show(
        '플랜 안내는 준비 중이에요',
        description: 'T1 이상에서 음성책을 이용할 수 있어요',
      );
}
