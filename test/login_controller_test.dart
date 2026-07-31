import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/login/login_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 전화번호·인증번호(A3~A6)는 **앱 자체 숫자 키패드**로만 입력된다.
///
/// OS 키보드를 쓰지 않으므로 자릿수 제한·서식·지우기가 전부 컨트롤러 몫이다.
/// 재발송 타이머도 서버가 만료 시각을 주지 않아 클라이언트가 센다.
void main() {
  setUpAll(() => initTestEnv('login'));

  LoginController build() {
    final api = MockApiClient();
    return LoginController(api, AuthService(api), ToastService());
  }

  group('전화번호 키패드', () {
    test('숫자를 넣으면 "010 - 1234 - 5678"로 띄어 준다', () {
      final c = build();
      for (final d in '01012345678'.split('')) {
        c.onPhoneDigit(d);
      }

      expect(c.phoneDigits.value, '01012345678');
      expect(c.phoneFieldText, '010 - 1234 - 5678');
      expect(c.phoneController.text, '010 - 1234 - 5678');
      expect(c.canRequestCode, isTrue);
    });

    test('문장 안에 들어갈 때는 좁게 붙인다', () {
      final c = build();
      for (final d in '01012345678'.split('')) {
        c.onPhoneDigit(d);
      }

      expect(c.phoneCompact, '010-1234-5678');
    });

    test('11자리를 넘겨 눌러도 더 들어가지 않는다', () {
      final c = build();
      for (final d in '010123456789999'.split('')) {
        c.onPhoneDigit(d);
      }

      expect(c.phoneDigits.value, hasLength(11));
    });

    test('지우기는 한 자리씩, 빈 상태에서는 아무 일도 없다', () {
      final c = build();
      c
        ..onPhoneDigit('0')
        ..onPhoneDigit('1')
        ..onPhoneBackspace()
        ..onPhoneBackspace()
        ..onPhoneBackspace();

      expect(c.phoneDigits.value, isEmpty);
    });
  });

  group('인증번호 키패드', () {
    test('6자리에서 멈춘다', () {
      final c = build();
      for (final d in '4829159999'.split('')) {
        c.onCodeDigit(d);
      }

      expect(c.code.value, '482915');
      expect(c.canVerify, isTrue);
    });

    test('6자리를 채워도 자동으로 확인하지 않는다', () {
      final c = build();
      for (final d in '482915'.split('')) {
        c.onCodeDigit(d);
      }

      // 확인은 "확인" 버튼이 한다 — 마지막 숫자를 누르자마자 화면이 넘어가면
      // 잘못 누른 걸 되돌릴 틈이 없다.
      expect(c.isSubmitting.value, isFalse);
    });

    test('다시 누르기 시작하면 에러 표시가 사라진다', () {
      final c = build();
      c.codeError.value = '인증번호가 맞지 않아요. 다시 입력해주세요.';

      c.onCodeDigit('1');

      expect(c.codeError.value, isNull);
    });
  });

  group('재발송 타이머', () {
    /// 인증번호를 요청한 직후 상태로 만든다.
    LoginController requested(FakeAsync async) {
      final c = build();
      for (final d in '01012345678'.split('')) {
        c.onPhoneDigit(d);
      }
      c.requestCode();
      async.elapse(const Duration(seconds: 1)); // 목업 지연 통과
      return c;
    }

    test('유효시간은 서버가 준 값을 센다', () {
      fakeAsync((async) {
        final c = requested(async);

        // ⚠️ 클라이언트 상수가 아니다. 기기 시계가 틀어져 있어도 서버가 말한
        //    만료까지 남은 시간을 보여줘야 한다.
        expect(c.secondsLeft.value, 180);
        expect(c.timerLabel, '3분 0초 남음');

        async.elapse(const Duration(seconds: 13));
        expect(c.timerLabel, '2분 47초 남음');

        async.elapse(const Duration(minutes: 3));
        expect(c.secondsLeft.value, 0);
        expect(c.timerLabel, '시간이 지났어요');

        // 타이머가 계속 돌면 테스트 종료 시 pending timer로 잡힌다.
        c.onClose();
      });
    });

    test('"다시 받기"는 유효시간과 따로, 더 짧게 풀린다', () {
      fakeAsync((async) {
        final c = requested(async);

        // 문자를 연달아 보내면 어느 번호가 맞는지 헷갈린다. 다만 3분을 통째로
        // 막으면 문자가 안 온 사람이 3분을 기다려야 한다.
        expect(c.canResend, isFalse);
        expect(c.resendSecondsLeft.value, 30);

        async.elapse(const Duration(seconds: 29));
        expect(c.canResend, isFalse);

        async.elapse(const Duration(seconds: 1));
        expect(c.canResend, isTrue);
        expect(c.secondsLeft.value, greaterThan(0), reason: '유효시간은 아직 남았다');

        c.onClose();
      });
    });

    test('다시 받으면 두 타이머가 함께 되감긴다', () {
      fakeAsync((async) {
        final c = requested(async);
        async.elapse(const Duration(seconds: 40));

        c.resendCode();
        async.elapse(const Duration(seconds: 1));

        expect(c.secondsLeft.value, 180);
        expect(c.resendSecondsLeft.value, 30);
        expect(c.canResend, isFalse);

        c.onClose();
      });
    });
  });
}
