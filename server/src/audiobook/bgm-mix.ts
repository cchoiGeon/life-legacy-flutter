/**
 * BGM 믹스 — lifelegacy `app/lib/audiobook/bgm-mix.ts` 이식.
 * ffmpeg-static / FFMPEG_PATH 사용. 실패 시 보이스 원본 반환.
 */

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ffmpegStatic = require('ffmpeg-static') as string | null;

export const DEFAULT_BGM_VOLUME = 0.2;
const FADE_IN_SEC = 1.5;
const MIN_BGM_VOLUME = 0;
const MAX_BGM_VOLUME = 0.35;
const DEFAULT_FFMPEG_TIMEOUT_MS = 90_000;

export type BgmMixStatus = 'mixed' | 'skipped' | 'failed' | 'disabled';

export type BgmMixResult = {
  audio: Buffer;
  status: BgmMixStatus;
  volume: number;
  trackId: string | null;
  detail?: string;
};

export function clampBgmVolume(raw: unknown): number {
  const n = typeof raw === 'number' ? raw : Number(raw);
  if (!Number.isFinite(n)) return DEFAULT_BGM_VOLUME;
  return Math.min(MAX_BGM_VOLUME, Math.max(MIN_BGM_VOLUME, n));
}

function resolveFfmpegBinary(): string {
  const fromEnv = process.env.FFMPEG_PATH?.trim();
  if (fromEnv) return fromEnv;
  if (ffmpegStatic) return ffmpegStatic;
  return 'ffmpeg';
}

function runFfmpeg(
  args: string[],
  options?: { timeoutMs?: number },
): Promise<void> {
  const bin = resolveFfmpegBinary();
  const timeoutMs = options?.timeoutMs ?? DEFAULT_FFMPEG_TIMEOUT_MS;
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, {
      stdio: ['ignore', 'ignore', 'pipe'],
      windowsHide: true,
    });
    let stderr = '';
    let settled = false;
    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      child.kill('SIGKILL');
      reject(new Error(`ffmpeg timeout after ${timeoutMs}ms`));
    }, timeoutMs);

    child.stderr?.on('data', (chunk: Buffer) => {
      stderr += chunk.toString('utf8');
      if (stderr.length > 4000) stderr = stderr.slice(-4000);
    });
    child.on('error', (err) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(err);
    });
    child.on('close', (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exit ${code}: ${stderr.slice(-800)}`));
    });
  });
}

async function mixBuffers(
  voiceMp3: Buffer,
  bgmPath: string,
  volume: number,
): Promise<Buffer> {
  const tmpDir = await mkdtemp(join(tmpdir(), 'll-bgm-'));
  const voicePath = join(tmpDir, 'voice.mp3');
  const outPath = join(tmpDir, 'mixed.mp3');

  try {
    await writeFile(voicePath, voiceMp3);
    const vol = clampBgmVolume(volume);
    const filter = [
      `[0:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[va]`,
      `[1:a]aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume=${vol},afade=t=in:st=0:d=${FADE_IN_SEC}[bg]`,
      `[va][bg]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[out]`,
    ].join(';');

    await runFfmpeg([
      '-y',
      '-i',
      voicePath,
      '-stream_loop',
      '-1',
      '-i',
      bgmPath,
      '-filter_complex',
      filter,
      '-map',
      '[out]',
      '-c:a',
      'libmp3lame',
      '-q:a',
      '4',
      outPath,
    ]);

    return await readFile(outPath);
  } finally {
    await rm(tmpDir, { recursive: true, force: true }).catch(() => undefined);
  }
}

/**
 * BGM을 보이스 아래 믹스. 실패해도 보이스 원본을 돌려준다.
 */
export async function applyAudiobookBgm(
  voiceMp3: Buffer,
  options: {
    bgmAbsolutePath: string | null;
    trackId: string | null;
    volume?: number;
  },
): Promise<BgmMixResult> {
  const volume = clampBgmVolume(options.volume ?? DEFAULT_BGM_VOLUME);
  const trackId = options.trackId;

  if (!voiceMp3.length) {
    return {
      audio: voiceMp3,
      status: 'skipped',
      volume,
      trackId,
      detail: 'empty-voice',
    };
  }
  if (!trackId || !options.bgmAbsolutePath) {
    return {
      audio: voiceMp3,
      status: 'disabled',
      volume,
      trackId,
      detail: 'no-track',
    };
  }
  if (volume <= 0) {
    return {
      audio: voiceMp3,
      status: 'disabled',
      volume,
      trackId,
      detail: 'volume-0',
    };
  }
  if (!existsSync(options.bgmAbsolutePath)) {
    return {
      audio: voiceMp3,
      status: 'failed',
      volume,
      trackId,
      detail: `missing:${options.bgmAbsolutePath}`,
    };
  }

  try {
    const mixed = await mixBuffers(voiceMp3, options.bgmAbsolutePath, volume);
    if (!mixed.length) {
      return {
        audio: voiceMp3,
        status: 'failed',
        volume,
        trackId,
        detail: 'empty-mix-output',
      };
    }
    return { audio: mixed, status: 'mixed', volume, trackId };
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return { audio: voiceMp3, status: 'failed', volume, trackId, detail };
  }
}
