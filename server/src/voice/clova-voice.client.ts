/**
 * 네이버 클라우드 CLOVA Voice TTS Premium + CSR STT.
 * 참고: lifelegacy `app/lib/audiobook/clova-tts.ts`
 * https://api.ncloud-docs.com/docs/ai-naver-clovavoice-ttspremium
 * https://api.ncloud-docs.com/docs/ai-naver-clovaspeechrecognition-stt
 */

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const CLOVA_TTS_URL =
  'https://naveropenapi.apigw.ntruss.com/tts-premium/v1/tts';
const CLOVA_STT_URL =
  'https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=Kor';

/** 한국어 TTS 한도 2000자 — 여유를 두고 청크 */
export const CLOVA_TTS_MAX_CHARS = 1800;

export type ClovaTtsResult = {
  audio: Buffer;
  mimeType: 'audio/mpeg';
};

export type ClovaSttResult = {
  text: string;
};

@Injectable()
export class ClovaVoiceClient {
  private readonly logger = new Logger(ClovaVoiceClient.name);

  constructor(private readonly config: ConfigService) {}

  hasKey(): boolean {
    return Boolean(
      this.config.get<string>('NCP_CLOVA_CLIENT_ID')?.trim() &&
        this.config.get<string>('NCP_CLOVA_CLIENT_SECRET')?.trim(),
    );
  }

  defaultSpeaker(): string {
    return (
      this.config.get<string>('CLOVA_TTS_DEFAULT_SPEAKER')?.trim() || 'vara'
    );
  }

  private credentials(): { clientId: string; clientSecret: string } {
    const clientId = this.config.get<string>('NCP_CLOVA_CLIENT_ID')?.trim();
    const clientSecret = this.config
      .get<string>('NCP_CLOVA_CLIENT_SECRET')
      ?.trim();
    if (!clientId || !clientSecret) {
      throw new Error('NCP_CLOVA_CLIENT_ID / NCP_CLOVA_CLIENT_SECRET missing');
    }
    return { clientId, clientSecret };
  }

  async textToSpeech(
    text: string,
    voiceCode?: string,
    options: {
      volume?: number;
      speed?: number;
      pitch?: number;
      alpha?: number;
      emotion?: number;
      emotionStrength?: number;
      supportsEmotion?: boolean;
      supportsEmotionStrength?: boolean;
    } = {},
  ): Promise<ClovaTtsResult> {
    const trimmed = text.trim();
    if (!trimmed) {
      throw new Error('empty tts text');
    }
    if (trimmed.length > 2000) {
      throw new Error('tts text too long');
    }

    const { clientId, clientSecret } = this.credentials();
    const speaker = voiceCode?.trim() || this.defaultSpeaker();

    const body = new URLSearchParams();
    body.set('speaker', speaker);
    body.set('text', trimmed);
    body.set('format', 'mp3');
    body.set('volume', String(options.volume ?? 0));
    body.set('speed', String(options.speed ?? 0));
    body.set('pitch', String(options.pitch ?? 0));
    body.set('alpha', String(options.alpha ?? 0));
    if (
      options.supportsEmotion &&
      typeof options.emotion === 'number' &&
      Number.isFinite(options.emotion)
    ) {
      body.set(
        'emotion',
        String(Math.min(3, Math.max(0, Math.round(options.emotion)))),
      );
    }
    if (
      options.supportsEmotionStrength &&
      typeof options.emotionStrength === 'number' &&
      Number.isFinite(options.emotionStrength)
    ) {
      body.set(
        'emotion-strength',
        String(Math.min(2, Math.max(0, Math.round(options.emotionStrength)))),
      );
    }

    const res = await fetch(CLOVA_TTS_URL, {
      method: 'POST',
      headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId,
        'X-NCP-APIGW-API-KEY': clientSecret,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.toString(),
    });

    if (!res.ok) {
      const detail = (await res.text()).slice(0, 300);
      this.logger.warn(`CLOVA TTS ${res.status}: ${detail}`);
      throw new Error(`CLOVA TTS ${res.status}`);
    }

    const audio = Buffer.from(await res.arrayBuffer());
    if (audio.length === 0) {
      throw new Error('empty tts audio');
    }
    return { audio, mimeType: 'audio/mpeg' };
  }

  async speechToText(audio: Buffer): Promise<ClovaSttResult> {
    if (!audio.length) {
      throw new Error('empty stt audio');
    }

    const { clientId, clientSecret } = this.credentials();
    const res = await fetch(CLOVA_STT_URL, {
      method: 'POST',
      headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId,
        'X-NCP-APIGW-API-KEY': clientSecret,
        'Content-Type': 'application/octet-stream',
      },
      body: new Uint8Array(audio),
    });

    if (!res.ok) {
      const detail = (await res.text()).slice(0, 300);
      this.logger.warn(`CLOVA STT ${res.status}: ${detail}`);
      throw new Error(`CLOVA STT ${res.status}`);
    }

    const json = (await res.json()) as { text?: string };
    return { text: (json.text ?? '').trim() };
  }
}
