import { SettingsService } from './settings.service';

/**
 * 등록 전에도 **빈 객체·기본값**을 돌려준다 — 앱이 "없음"과 "못 불러옴"을
 * 구분할 필요가 없게 한 계약이다.
 */
function buildService(stored: { setting?: unknown; address?: unknown } = {}) {
  const settings = {
    findOne: jest.fn().mockResolvedValue(stored.setting ?? null),
    upsert: jest.fn().mockResolvedValue(undefined),
  };
  const addresses = {
    findOne: jest.fn().mockResolvedValue(stored.address ?? null),
    upsert: jest.fn().mockResolvedValue(undefined),
  };

  return {
    service: new SettingsService(settings as never, addresses as never),
    settings,
    addresses,
  };
}

describe('SettingsService', () => {
  it('설정이 없으면 알림이 켜진 것으로 본다', async () => {
    const { service } = buildService();

    expect(await service.getSettings('u1')).toEqual({
      daily_question_alarm: true,
    });
  });

  it('저장한 값이 있으면 그 값을 돌려준다', async () => {
    const { service } = buildService({
      setting: { dailyQuestionAlarm: false },
    });

    expect((await service.getSettings('u1')).daily_question_alarm).toBe(false);
  });

  it('배송지가 없어도 404가 아니라 빈 문자열을 채워 준다', async () => {
    const { service } = buildService();

    expect(await service.getAddress('u1')).toEqual({
      recipient: '',
      phone: '',
      postal_code: '',
      line1: '',
      line2: '',
    });
  });

  it('배송지를 저장하면 snake_case로 되돌려 준다', async () => {
    const { service, addresses } = buildService();
    const dto = {
      recipient: '김영희',
      phone: '01012345678',
      postal_code: '03186',
      line1: '서울 종로구 세종대로 175',
      line2: '302동 1201호',
    };

    expect(await service.updateAddress('u1', dto)).toEqual(dto);
    // 컬럼명은 camelCase, 계약은 snake_case다.
    expect(addresses.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ postalCode: '03186' }),
      ['userId'],
    );
  });
});
