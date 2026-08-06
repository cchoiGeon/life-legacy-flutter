/// POST /coupons/redeem 응답.
class CouponRedeemResult {
  const CouponRedeemResult({
    required this.planCode,
    required this.message,
  });

  final String planCode;
  final String message;

  factory CouponRedeemResult.fromJson(Map<String, dynamic> json) =>
      CouponRedeemResult(
        planCode: json['plan_code'] as String? ?? 'free',
        message: json['message'] as String? ?? '플랜이 적용됐어요',
      );
}
