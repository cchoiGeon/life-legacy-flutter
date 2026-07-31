import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * 문자 발송.
 *
 * 지금은 **스텁**이다 — 실제로 보내지 않고 로그만 남긴다. 공급사(NCP SENS
 * 등)가 정해지면 이 클래스만 갈아 끼운다.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger('Sms');

  constructor(private readonly configService: ConfigService) {}

  get isStub(): boolean {
    return this.configService.get<string>('SMS_PROVIDER', 'stub') === 'stub';
  }

  /**
   * 스텁 모드에서는 **고정 인증번호**를 쓴다. 앱 목업(MockApiClient)과 같은
   * 값이라 연동 테스트가 바로 된다.
   */
  get stubCode(): string {
    return this.configService.get<string>('STUB_VERIFICATION_CODE', '482915');
  }

  sendVerificationCode(phone: string, code: string): Promise<void> {
    if (this.isStub) {
      this.logger.log(`[stub] ${phone} 인증번호 ${code}`);
      return Promise.resolve();
    }

    throw new Error('SMS 공급사가 아직 연결되지 않았습니다');
  }
}
