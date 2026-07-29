import 'package:life_legacy/data/enums/enums.dart';

/// 작성 화면의 말풍선 하나.
///
/// 채팅 모드(시안 15번)에서 질문·답변·후속질문이 시간순으로 쌓인다.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.speakable = false,
  });

  final String id;
  final ChatRole role;
  final String text;

  /// AI 말풍선 아래 "다시 들려줘" 칩을 붙일지 여부.
  /// 질문에는 붙이고, 짧은 맞장구에는 붙이지 않는다.
  final bool speakable;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: ChatRole.fromWire(json['role'] as String?),
    text: json['text'] as String? ?? '',
    speakable: json['speakable'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.wire,
    'text': text,
    'speakable': speakable,
  };
}

/// 답변 하나에 대한 AI 처리 결과.
///
/// 시안 16 → 17 흐름: 받아쓴 원문을 확인시키고(`transcript`),
/// 확인되면 문어체로 다듬은 글(`polished`)을 보여준다.
class AnswerDraft {
  const AnswerDraft({
    required this.questionId,
    required this.transcript,
    required this.polished,
  });

  final String questionId;

  /// 사용자가 말한/쓴 그대로
  final String transcript;

  /// AI가 자서전 문체로 다듬은 문단
  final String polished;

  AnswerDraft copyWith({String? transcript, String? polished}) => AnswerDraft(
    questionId: questionId,
    transcript: transcript ?? this.transcript,
    polished: polished ?? this.polished,
  );

  factory AnswerDraft.fromJson(Map<String, dynamic> json) => AnswerDraft(
    questionId: json['question_id'] as String? ?? '',
    transcript: json['transcript'] as String? ?? '',
    polished: json['polished'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'transcript': transcript,
    'polished': polished,
  };
}
