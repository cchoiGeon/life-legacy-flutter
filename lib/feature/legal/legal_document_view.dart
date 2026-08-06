import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/service/services.dart';

/// DB에 저장된 약관·개인정보·환불정책 본문 열람.
///
/// `Get.toNamed(AppRoutes.legal, arguments: {'key': 'terms_of_service'})`
/// 또는 [LegalDocumentView.open]으로 연다.
class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({super.key, this.documentKey, this.initial});

  /// `terms_of_service` · `privacy_policy` · `refund_policy` 등.
  final String? documentKey;

  /// 이미 로드한 문서가 있으면 서버 왕복을 건너뛴다.
  final ConsentDocument? initial;

  static Future<dynamic>? open(
    String key, {
    ConsentDocument? initial,
  }) {
    return Get.toNamed(
      AppRoutes.legal,
      arguments: {
        'key': key,
        if (initial != null) 'document': initial,
      },
    );
  }

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  ConsentDocument? _doc;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _key {
    if (widget.documentKey != null) return widget.documentKey;
    final args = Get.arguments;
    if (args is Map && args['key'] is String) return args['key'] as String;
    return null;
  }

  ConsentDocument? get _argDocument {
    if (widget.initial != null) return widget.initial;
    final args = Get.arguments;
    if (args is Map && args['document'] is ConsentDocument) {
      return args['document'] as ConsentDocument;
    }
    return null;
  }

  Future<void> _load() async {
    final cached = _argDocument;
    final hasContent = cached?.content?.trim().isNotEmpty == true;
    if (cached != null && hasContent) {
      setState(() {
        _doc = cached;
        _loading = false;
      });
      return;
    }

    final key = _key ?? cached?.key;
    if (key == null) {
      setState(() {
        _loading = false;
        _error = '문서를 찾을 수 없어요';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await Get.find<ApiClient>().consentDocument(key);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      Get.find<ToastService>().showError(e);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '문서를 불러오지 못했어요';
      });
    }
  }

  Future<void> _openExternal() async {
    final url = _doc?.url;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final title = _doc?.title ?? '약관';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppTopBar(title: title),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _doc == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(label: '다시 시도', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final content = _doc?.content?.trim();
    if (content != null && content.isNotEmpty) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDimens.gutter,
          8,
          AppDimens.gutter,
          AppInsets.bottom(context, 32),
        ),
        child: SelectableText(
          content,
          style: AppTypography.bodyBase.copyWith(
            height: 1.55,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (_doc?.url != null && _doc!.url!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '브라우저에서 원문을 확인하세요.',
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(label: '원문 열기', onPressed: _openExternal),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        '표시할 내용이 없어요.',
        style: AppTypography.bodyBase.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
