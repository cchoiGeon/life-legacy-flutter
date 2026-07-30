import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/settings/address_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 인쇄본 배송지(F4).
///
/// 상세 주소만 없어도 된다(단독주택). 나머지 넷 중 하나라도 비면 책이
/// 도착하지 않으므로 저장을 막는다.
void main() {
  setUpAll(() => initTestEnv('address'));

  Future<(AddressController, MockApiClient)> build() async {
    final api = MockApiClient();
    final c = AddressController(api, ToastService());
    c.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return (c, api);
  }

  test('저장된 주소를 불러와 칸을 채운다 — 전화번호는 띄어서 보여준다', () async {
    final (c, _) = await build();

    expect(c.recipient.text, '김영희');
    expect(c.phone.text, '010 1234 5678');
    expect(c.postalCode.text, '03186');
    expect(c.line1.text, '서울 종로구 세종대로 175');
  });

  test('서버로는 숫자만 보낸다', () async {
    final (c, _) = await build();

    expect(c.draft.phone, '01012345678');
  });

  test('받는 분이 비면 저장할 수 없다', () async {
    final (c, _) = await build();
    c.recipient.text = '   ';

    expect(c.canSave, isFalse);
  });

  test('우편번호가 비면 저장할 수 없다', () async {
    final (c, _) = await build();
    c.postalCode.text = '';

    expect(c.canSave, isFalse);
  });

  test('상세 주소는 비어도 저장할 수 있다', () async {
    final (c, _) = await build();
    c.line2.text = '';

    expect(c.canSave, isTrue);
  });

  test('저장하면 서버 값이 바뀐다', () async {
    final (c, api) = await build();
    c.line2.text = '101동 202호';

    await c.save();

    final saved = await api.shippingAddress();
    expect(saved.line2, '101동 202호');
    expect(saved.phone, '01012345678');
  });
}
