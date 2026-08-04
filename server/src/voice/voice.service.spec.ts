import { ApiException } from 'src/common/exception/api.exception';
import { VoiceService } from './voice.service';

describe('VoiceService', () => {
  it('키가 없으면 TTS_FAILED', async () => {
    const service = new VoiceService({
      hasKey: () => false,
    } as never);
    await expect(service.synthesize('안녕')).rejects.toBeInstanceOf(
      ApiException,
    );
  });

  it('문단 청크를 합성하고 nextFrom을 돌려준다', async () => {
    const textToSpeech = jest.fn().mockResolvedValue({
      audio: Buffer.from([0xff, 0xfb, 0x90, 0x00]),
      mimeType: 'audio/mpeg',
    });
    const service = new VoiceService({
      hasKey: () => true,
      defaultSpeaker: () => 'vara',
      textToSpeech,
    } as never);

    const result = await service.synthesizeChunks(
      ['첫 문단입니다.', '둘째 문단입니다.'],
      0,
      1,
    );

    expect(textToSpeech).toHaveBeenCalledWith('첫 문단입니다.', undefined);
    expect(result.nextFrom).toBe(1);
  });

  it('빈 STT 결과는 STT_FAILED', async () => {
    const service = new VoiceService({
      hasKey: () => true,
      speechToText: jest.fn().mockResolvedValue({ text: '' }),
    } as never);

    await expect(
      service.transcribe(Buffer.from([1, 2, 3])),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'STT_FAILED' }),
    });
  });
});
