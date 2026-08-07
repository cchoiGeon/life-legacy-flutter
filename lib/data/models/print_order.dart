/// 종이책(인쇄본) 신청 결과.
class PrintOrderResult {
  const PrintOrderResult({
    required this.id,
    required this.bookId,
    required this.quantity,
    required this.status,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final int quantity;
  final String status;
  final String? note;
  final DateTime createdAt;

  factory PrintOrderResult.fromJson(Map<String, dynamic> json) {
    return PrintOrderResult(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      quantity: json['quantity'] as int,
      status: json['status'] as String? ?? 'requested',
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
