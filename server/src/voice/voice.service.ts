import { Injectable, Logger } from '@nestjs/common';
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import {
  ClovaVoiceClient,
  CLOVA_TTS_MAX_CHARS,
} from './clova-voice.client';

const SAMPLE_TEXT =
  '안녕하세요. Life Legacy입니다. 소리가 잘 들리시나요?';

@Injectable()
export class VoiceService {
  private readonly logger = new Logger(VoiceService.name);
  private readonly sampleDir = join(process.cwd(), 'storage', 'voice-samples');

  constructor(private readonly clova: ClovaVoiceClient) {}

  async synthesize(
    text: string,
    voiceCode?: string,
  ): Promise<{ audio: Buffer; durationMs: number | null }> {
    this.requireKey();
    try {
      const { audio } = await this.clova.textToSpeech(text, voiceCode);
      return { audio, durationMs: this.estimateMp3DurationMs(audio) };
    } catch (e) {
      this.logger.warn(`TTS failed: ${(e as Error).message}`);
      throw new ApiException(ERROR_CODE.WRITE.TTS_FAILED);
    }
  }

  /**
   * 긴 원고를 제공자 한도 이하로 자른 뒤 한 청크만 합성한다 (§9.4).
   * 반환 nextFrom은 다음 요청에 실을 문단 인덱스(끝나면 null).
   */
  async synthesizeChunks(
    paragraphs: string[],
    fromParagraph: number,
    chunkSize: number,
    voiceCode?: string,
  ): Promise<{
    audio: Buffer;
    durationMs: number | null;
    nextFrom: number | null;
  }> {
    const start = Math.max(0, fromParagraph);
    if (start >= paragraphs.length) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const picked: string[] = [];
    let i = start;
    let chars = 0;
    while (i < paragraphs.length && picked.length < chunkSize) {
      const p = paragraphs[i]?.trim() ?? '';
      if (!p) {
        i++;
        continue;
      }
      if (chars + p.length > CLOVA_TTS_MAX_CHARS && picked.length > 0) break;
      if (p.length > CLOVA_TTS_MAX_CHARS) {
        // 한 문단이 한도를 넘으면 잘라서 보낸다
        picked.push(p.slice(0, CLOVA_TTS_MAX_CHARS));
        i++;
        break;
      }
      picked.push(p);
      chars += p.length;
      i++;
    }

    if (picked.length === 0) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const { audio, durationMs } = await this.synthesize(
      picked.join('\n\n'),
      voiceCode,
    );
    return {
      audio,
      durationMs,
      nextFrom: i >= paragraphs.length ? null : i,
    };
  }

  async transcribe(
    audio: Buffer,
    durationMs?: number | null,
  ): Promise<{ text: string; duration_ms: number | null }> {
    this.requireKey();
    try {
      const { text } = await this.clova.speechToText(audio);
      if (!text) {
        throw new ApiException(ERROR_CODE.WRITE.STT_FAILED);
      }
      return { text, duration_ms: durationMs ?? null };
    } catch (e) {
      if (e instanceof ApiException) throw e;
      this.logger.warn(`STT failed: ${(e as Error).message}`);
      throw new ApiException(ERROR_CODE.WRITE.STT_FAILED);
    }
  }

  /** 보이스 체크용 미리 렌더 샘플 (§5.8) */
  async sample(voiceCode?: string): Promise<{ audio: Buffer }> {
    this.requireKey();
    const speaker = voiceCode?.trim() || this.clova.defaultSpeaker();
    mkdirSync(this.sampleDir, { recursive: true });
    const path = join(this.sampleDir, `${speaker}.mp3`);

    if (existsSync(path)) {
      return { audio: readFileSync(path) };
    }

    try {
      const { audio } = await this.clova.textToSpeech(SAMPLE_TEXT, speaker);
      writeFileSync(path, audio);
      return { audio };
    } catch (e) {
      this.logger.warn(`voice sample failed: ${(e as Error).message}`);
      throw new ApiException(ERROR_CODE.WRITE.TTS_FAILED);
    }
  }

  private requireKey() {
    if (!this.clova.hasKey()) {
      this.logger.error('Clova credentials missing');
      throw new ApiException(ERROR_CODE.WRITE.TTS_FAILED);
    }
  }

  /** mp3 CBR 근사 — 없으면 null. 글자 동기화 스케줄러용 힌트 */
  private estimateMp3DurationMs(audio: Buffer): number | null {
    if (audio.length < 128) return null;
    // 128kbps 가정
    return Math.round((audio.length * 8) / 128);
  }
}
