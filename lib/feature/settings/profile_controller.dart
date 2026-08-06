import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// F3 내 정보 — 프로필 사진 업로드 포함.
class ProfileController extends GetxController {
  ProfileController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final Rxn<Address> address = Rxn<Address>();
  final Rxn<IntroProfile> introProfile = Rxn<IntroProfile>();
  final RxBool isLoading = true.obs;
  final RxBool isUploadingAvatar = false.obs;

  User? get user => _auth.user.value;
  Uint8List? get avatarBytes => _auth.avatarBytes.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _api.shippingAddress(),
        _api.introProfile(),
      ]);
      address.value = results[0] as Address;
      introProfile.value = results[1] as IntroProfile;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadAvatar() async {
    if (isUploadingAvatar.value) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    isUploadingAvatar.value = true;
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final contentType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final user = await _api.uploadAvatar(
        bytes: bytes,
        filename: file.name,
        contentType: contentType,
      );
      _auth.updateUser(user);
      await _auth.setAvatarBytes(Uint8List.fromList(bytes));
      _toast.show('프로필 사진을 올렸어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// "김영희 · 010 1234 5678"
  String get recipientLine {
    final a = address.value;
    if (a == null || !a.isComplete) return '아직 등록하지 않았어요';
    return '${a.recipient} · ${Address.formatPhone(a.phone)}';
  }

  String get addressLine {
    final a = address.value;
    if (a == null || !a.isComplete) return '아직 등록하지 않았어요';
    return a.oneLine;
  }
}
