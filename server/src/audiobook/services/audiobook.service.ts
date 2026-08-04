import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash } from 'crypto';
import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import { In, Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { JobStatus } from 'src/common/const/job-status.enum';
import { MediaKind } from 'src/common/const/media-kind.enum';
import { MediaSource } from 'src/common/const/media-source.enum';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { EntitlementLedgerModel } from 'src/entitlement/entities/entitlement-ledger.entity';
import { EntitlementService } from 'src/entitlement/services/entitlement.service';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { ClovaVoiceClient } from 'src/voice/clova-voice.client';
import { getClovaVoice, listClovaVoicesForApp } from '../clova-voices';
import { CreateAudiobookJobDto } from '../dto/request/create-audiobook-job.dto';
import { AudiobookJobPartModel } from '../entities/audiobook-job-part.entity';
import { AudiobookJobModel } from '../entities/audiobook-job.entity';
import { BgmTrackModel } from '../entities/bgm-track.entity';
import { concatMp3Buffers } from '../mp3';
import { getParagraphPauseMp3 } from '../pause';
import {
  buildChapterScript,
  chunkTextForTts,
  splitParagraphsForTts,
} from '../script';
import {
  applyAudiobookBgm,
  DEFAULT_BGM_VOLUME,
} from '../bgm-mix';

const GENERATIONS_PER_CHAPTER = 2;
const CHARS_PER_MS = 250 / 60_000;
const SAMPLE_TEXT =
  '안녕하세요. 라이프 레거시 음성책 미리듣기입니다. 이 목소리로 선생님의 이야기를 읽어 드립니다.';

@Injectable()
export class AudiobookService {
  private readonly logger = new Logger(AudiobookService.name);
  private readonly storageRoot = join(process.cwd(), 'storage', 'audiobooks');

  constructor(
    private readonly bookAccess: BookAccessService,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly entitlementService: EntitlementService,
    private readonly clova: ClovaVoiceClient,
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
    @InjectRepository(AudiobookJobModel)
    private readonly jobs: Repository<AudiobookJobModel>,
    @InjectRepository(AudiobookJobPartModel)
    private readonly parts: Repository<AudiobookJobPartModel>,
    @InjectRepository(BgmTrackModel)
    private readonly bgms: Repository<BgmTrackModel>,
    @InjectRepository(EntitlementLedgerModel)
    private readonly ledger: Repository<EntitlementLedgerModel>,
    @InjectRepository(MediaAssetModel)
    private readonly media: Repository<MediaAssetModel>,
  ) {}

  /** api-spec §10.4 — 무료는 chapters=[] */
  async getOverview(userId: string, bookId: string) {
    const book = await this.bookAccess.requireOwnedBook(userId, bookId);
    if (
      process.env.AUDIOBOOK_AUTO_GRANT === 'true'
    ) {
      await this.entitlementService.grantAudiobookT1(userId, 'auto_grant');
    }
    const allowed = await this.entitlementService.hasFeature(
      userId,
      'audiobook',
    );

    if (!allowed) {
      return {
        book_title: book.title,
        allowed: false as const,
        reason: 'PLAN_REQUIRED',
        chapters: [] as unknown[],
      };
    }

    const planRow = await this.entitlementService.findActiveFeature(
      userId,
      'audiobook',
    );
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const reviews = await this.reviews.find({
      where: {
        userChapterId: In(chapters.map((c) => c.id)),
        status: ReviewStatus.REVIEWED,
      },
    });
    const reviewByChapter = new Map(
      reviews.map((r) => [r.userChapterId, r] as const),
    );

    const jobs = await this.jobs.find({
      where: { bookId },
      order: { createdAt: 'DESC' },
    });

    let totalChars = 0;
    const chapterDtos: Array<{
      chapter_id: string;
      order: number;
      title: string;
      state: string;
      char_count: number;
      estimated_duration_ms: number | null;
      remaining_generations: number;
      latest_job: {
        id: string;
        status: JobStatus;
        progress: number;
        stale: boolean;
      } | null;
    }> = [];

    for (const chapter of chapters) {
      const review = reviewByChapter.get(chapter.id);
      const chapterJobs = jobs.filter((j) => j.userChapterId === chapter.id);
      const used = await this.countGenerationsUsed(userId, chapter.id);
      const remaining = Math.max(0, GENERATIONS_PER_CHAPTER - used);
      const latest = chapterJobs[0] ?? null;
      const charCount = review?.body?.length ?? 0;
      totalChars += charCount;

      let state: string;
      if (!review) {
        state = 'not_ready';
      } else if (
        latest?.status === JobStatus.PROCESSING ||
        latest?.status === JobStatus.PENDING
      ) {
        state = 'processing';
      } else if (latest?.status === JobStatus.COMPLETED) {
        state = 'completed';
      } else if (latest?.status === JobStatus.FAILED) {
        state = 'failed';
      } else {
        state = 'ready';
      }

      const stale =
        latest != null &&
        review != null &&
        latest.sourceVersion !== review.version;

      chapterDtos.push({
        chapter_id: chapter.id,
        order: chapter.sortOrder,
        title: chapter.title,
        state,
        char_count: charCount,
        estimated_duration_ms:
          charCount === 0 ? null : Math.round(charCount / CHARS_PER_MS),
        remaining_generations: remaining,
        latest_job: latest
          ? {
              id: latest.id,
              status: latest.status,
              progress: latest.progress,
              stale,
            }
          : null,
      });
    }

    return {
      book_title: book.title,
      allowed: true as const,
      plan_code: planRow?.planCode ?? 'T1',
      total_char_count: totalChars,
      estimated_duration_ms:
        totalChars === 0 ? 0 : Math.round(totalChars / CHARS_PER_MS),
      chapters: chapterDtos,
    };
  }

  async listVoices(userId: string, bookId: string) {
    await this.requireAudiobookAccess(userId, bookId);
    const defaultSpeaker = this.clova.defaultSpeaker();
    return {
      items: listClovaVoicesForApp().map((v) => ({
        voice_code: v.voiceId,
        name: v.name,
        gender: v.gender,
        age: v.age,
        pro: v.pro === true,
        is_default: v.voiceId === defaultSpeaker,
      })),
    };
  }

  async voicePreview(userId: string, bookId: string, voiceCode: string) {
    await this.requireAudiobookAccess(userId, bookId);
    if (!this.clova.hasKey()) {
      throw new ApiException(ERROR_CODE.AUDIOBOOK.TTS_FAILED);
    }
    const meta = getClovaVoice(voiceCode);
    const { audio } = await this.clova.textToSpeech(SAMPLE_TEXT, voiceCode, {
      supportsEmotion: meta?.supportsEmotion,
      supportsEmotionStrength: meta?.supportsEmotionStrength,
    });
    return { audio, mimeType: 'audio/mpeg' as const };
  }

  async listBgms(userId: string, bookId: string) {
    await this.requireAudiobookAccess(userId, bookId);
    const rows = await this.bgms.find({
      where: { isActive: true },
      order: { title: 'ASC' },
    });
    // 라이선스 검수 전 empty가 정상 — 활성 행만 노출
    return {
      items: rows.map((r) => ({
        id: r.id,
        title: r.title,
        mood: r.mood,
      })),
    };
  }

  async createJob(
    userId: string,
    bookId: string,
    chapterId: string,
    dto: CreateAudiobookJobDto,
  ) {
    await this.requireAudiobookAccess(userId, bookId);
    if (!this.clova.hasKey()) {
      throw new ApiException(ERROR_CODE.AUDIOBOOK.TTS_FAILED);
    }

    const existingByKey = await this.jobs.findOne({
      where: { idempotencyKey: dto.idempotency_key },
    });
    if (existingByKey) {
      const used = await this.countGenerationsUsed(userId, chapterId);
      return {
        job_id: existingByKey.id,
        status: existingByKey.status,
        remaining_generations: Math.max(0, GENERATIONS_PER_CHAPTER - used),
      };
    }

    const chapter = await this.chaptersRepository.findChapterById(chapterId);
    if (!chapter || chapter.bookId !== bookId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const review = await this.reviews.findOne({
      where: { userChapterId: chapterId, status: ReviewStatus.REVIEWED },
    });
    if (!review) {
      throw new ApiException(ERROR_CODE.AUDIOBOOK.CHAPTER_NOT_REVIEWED);
    }

    const inFlight = await this.jobs.findOne({
      where: [
        {
          userChapterId: chapterId,
          status: JobStatus.PENDING,
        },
        {
          userChapterId: chapterId,
          status: JobStatus.PROCESSING,
        },
      ],
    });
    if (inFlight) {
      throw new ApiException(ERROR_CODE.AUDIOBOOK.JOB_IN_PROGRESS);
    }

    const used = await this.countGenerationsUsed(userId, chapterId);
    if (used >= GENERATIONS_PER_CHAPTER) {
      throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
    }

    if (dto.bgm_track_id) {
      const bgm = await this.bgms.findOne({
        where: { id: dto.bgm_track_id, isActive: true },
      });
      if (!bgm) {
        throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
      }
    }

    try {
      await this.ledger.insert({
        userId,
        bookId,
        userChapterId: chapterId,
        feature: 'audiobook',
        delta: -1,
        reason: 'audiobook_generate',
        idempotencyKey: dto.idempotency_key,
      });
    } catch {
      // 동시 재시도 — 키 충돌이면 기존 job 조회
      const raced = await this.jobs.findOne({
        where: { idempotencyKey: dto.idempotency_key },
      });
      if (raced) {
        return {
          job_id: raced.id,
          status: raced.status,
          remaining_generations: Math.max(
            0,
            GENERATIONS_PER_CHAPTER -
              (await this.countGenerationsUsed(userId, chapterId)),
          ),
        };
      }
      throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
    }

    const job = await this.jobs.save(
      this.jobs.create({
        bookId,
        userChapterId: chapterId,
        requestedBy: userId,
        sourceVersion: review.version,
        voiceCode: dto.voice_code,
        bgmTrackId: dto.bgm_track_id ?? null,
        status: JobStatus.PENDING,
        progress: 0,
        idempotencyKey: dto.idempotency_key,
      }),
    );

    void this.processJob(job.id).catch((e) => {
      this.logger.error(`audiobook job ${job.id} failed: ${(e as Error).message}`);
    });

    return {
      job_id: job.id,
      status: job.status,
      remaining_generations: Math.max(
        0,
        GENERATIONS_PER_CHAPTER - (used + 1),
      ),
    };
  }

  async getJob(userId: string, bookId: string, jobId: string) {
    await this.requireAudiobookAccess(userId, bookId);
    const job = await this.jobs.findOne({ where: { id: jobId, bookId } });
    if (!job) throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    return {
      job_id: job.id,
      chapter_id: job.userChapterId,
      status: job.status,
      progress: job.progress,
      voice_code: job.voiceCode,
      error_code: job.errorCode,
      stale: false,
    };
  }

  async cancelJob(userId: string, bookId: string, jobId: string) {
    await this.requireAudiobookAccess(userId, bookId);
    const job = await this.jobs.findOne({ where: { id: jobId, bookId } });
    if (!job) throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);

    if (
      job.status !== JobStatus.PENDING &&
      job.status !== JobStatus.PROCESSING
    ) {
      return { job_id: job.id, status: job.status };
    }

    job.status = JobStatus.CANCELLED;
    job.errorCode = 'CANCELLED';
    await this.jobs.save(job);
    await this.restoreQuota(userId, bookId, job.userChapterId, `cancel_${jobId}`);
    return { job_id: job.id, status: job.status };
  }

  async resolveStream(
    userId: string,
    bookId: string,
    chapterId: string,
  ): Promise<{ absolutePath: string; fileName: string; mimeType: string }> {
    await this.requireAudiobookAccess(userId, bookId);
    const job = await this.findLatestCompletedJob(bookId, chapterId);
    if (!job?.objectKey) {
      throw new ApiException(ERROR_CODE.AUDIOBOOK.NOT_READY);
    }
    return {
      absolutePath: join(process.cwd(), job.objectKey),
      fileName: `audiobook-${chapterId}.mp3`,
      mimeType: job.mimeType ?? 'audio/mpeg',
    };
  }

  async resolveDownload(
    userId: string,
    bookId: string,
    chapterId: string,
  ): Promise<{ absolutePath: string; fileName: string; mimeType: string }> {
    // 재생·다운로드 무제한 — 권한만 검사
    return this.resolveStream(userId, bookId, chapterId);
  }

  // ─── job processor (Naver CLOVA TTS) ─────────────────────────

  private async processJob(jobId: string) {
    const job = await this.jobs.findOne({ where: { id: jobId } });
    if (!job || job.status === JobStatus.CANCELLED) return;

    job.status = JobStatus.PROCESSING;
    job.progress = 1;
    await this.jobs.save(job);

    try {
      const chapter = await this.chaptersRepository.findChapterById(
        job.userChapterId,
      );
      const review = await this.reviews.findOne({
        where: { userChapterId: job.userChapterId },
      });
      if (!chapter || !review?.body?.trim()) {
        throw new Error('empty review body');
      }

      const script = buildChapterScript(chapter.title, review.body);
      let audio = await this.synthesizeChapterMp3(script, job.voiceCode, {
        onProgress: async (pct) => {
          const fresh = await this.jobs.findOne({ where: { id: jobId } });
          if (!fresh || fresh.status === JobStatus.CANCELLED) {
            throw new CancelledError();
          }
          fresh.progress = Math.min(99, pct);
          await this.jobs.save(fresh);
        },
      });

      // BGM 믹스 (실패해도 보이스 유지 — lifelegacy applyAudiobookBgm)
      let bgmSnapshot: unknown = null;
      if (job.bgmTrackId) {
        const bgm = await this.bgms.findOne({ where: { id: job.bgmTrackId } });
        const bgmPath = bgm
          ? join(process.cwd(), bgm.objectKey.replace(/^\//, ''))
          : null;
        const mix = await applyAudiobookBgm(audio, {
          trackId: job.bgmTrackId,
          bgmAbsolutePath: bgmPath,
          volume: Number(process.env.AUDIOBOOK_BGM_VOLUME ?? DEFAULT_BGM_VOLUME),
        });
        audio = mix.audio;
        bgmSnapshot = {
          status: mix.status,
          volume: mix.volume,
          trackId: mix.trackId,
          detail: mix.detail,
        };
      }

      mkdirSync(join(this.storageRoot, job.bookId), { recursive: true });
      const relativeKey = join('storage', 'audiobooks', job.bookId, `${jobId}.mp3`);
      const absolutePath = join(process.cwd(), relativeKey);
      writeFileSync(absolutePath, audio);

      const asset = await this.media.save(
        this.media.create({
          bookId: job.bookId,
          kind: MediaKind.AUDIO,
          source: MediaSource.AI_GENERATED,
          objectKey: relativeKey.replace(/\\/g, '/'),
          mimeType: 'audio/mpeg',
          byteSize: String(audio.length),
          checksum: createHash('sha256').update(audio).digest('hex'),
          durationMs: Math.round(
            (review.body.length || 1) / CHARS_PER_MS,
          ),
        }),
      );

      await this.parts.save(
        this.parts.create({
          audiobookJobId: jobId,
          seq: 0,
          textLength: script.length,
          status: JobStatus.COMPLETED,
          mediaAssetId: asset.id,
        }),
      );

      const done = await this.jobs.findOne({ where: { id: jobId } });
      if (!done || done.status === JobStatus.CANCELLED) {
        await this.restoreQuota(
          job.requestedBy,
          job.bookId,
          job.userChapterId,
          `cancel_after_${jobId}`,
        );
        return;
      }
      done.status = JobStatus.COMPLETED;
      done.progress = 100;
      done.objectKey = relativeKey.replace(/\\/g, '/');
      done.byteSize = String(audio.length);
      done.mimeType = 'audio/mpeg';
      done.errorCode = null;
      if (bgmSnapshot) {
        done.costSnapshot = { bgm: bgmSnapshot };
      }
      await this.jobs.save(done);
    } catch (e) {
      if (e instanceof CancelledError) {
        await this.restoreQuota(
          job.requestedBy,
          job.bookId,
          job.userChapterId,
          `cancel_${jobId}`,
        );
        return;
      }
      this.logger.warn(`job ${jobId}: ${(e as Error).message}`);
      const failed = await this.jobs.findOne({ where: { id: jobId } });
      if (failed && failed.status !== JobStatus.CANCELLED) {
        failed.status = JobStatus.FAILED;
        failed.errorCode = 'TTS_FAILED';
        await this.jobs.save(failed);
        await this.restoreQuota(
          job.requestedBy,
          job.bookId,
          job.userChapterId,
          `fail_${jobId}`,
        );
      }
    }
  }

  private async synthesizeChapterMp3(
    text: string,
    voiceCode: string,
    opts: { onProgress?: (pct: number) => Promise<void> },
  ): Promise<Buffer> {
    const paragraphs = splitParagraphsForTts(text);
    const paragraphChunks = paragraphs.map((p) => chunkTextForTts(p));
    const ttsUnits = paragraphChunks.flat();
    const pause = getParagraphPauseMp3();
    const pauseAfter = new Set<number>();
    let unitIndex = -1;
    for (let pi = 0; pi < paragraphChunks.length; pi++) {
      const len = paragraphChunks[pi].length;
      if (len === 0) continue;
      unitIndex += len;
      if (pi < paragraphChunks.length - 1) pauseAfter.add(unitIndex);
    }

    const voiceMeta = getClovaVoice(voiceCode);
    const mp3Parts: Buffer[] = [];
    const total = Math.max(ttsUnits.length, 1);

    for (let i = 0; i < ttsUnits.length; i++) {
      if (opts.onProgress) {
        await opts.onProgress(Math.round((i / total) * 100));
      }
      const { audio } = await this.clova.textToSpeech(ttsUnits[i], voiceCode, {
        supportsEmotion: voiceMeta?.supportsEmotion,
        supportsEmotionStrength: voiceMeta?.supportsEmotionStrength,
      });
      mp3Parts.push(audio);
      if (pauseAfter.has(i)) mp3Parts.push(pause);
    }

    return concatMp3Buffers(mp3Parts);
  }

  private async requireAudiobookAccess(userId: string, bookId: string) {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const allowed = await this.entitlementService.hasFeature(
      userId,
      'audiobook',
    );
    if (!allowed) {
      throw new ApiException(ERROR_CODE.PLAN.PLAN_REQUIRED);
    }
  }

  private async findLatestCompletedJob(bookId: string, chapterId: string) {
    return this.jobs.findOne({
      where: {
        bookId,
        userChapterId: chapterId,
        status: JobStatus.COMPLETED,
      },
      order: { createdAt: 'DESC' },
    });
  }

  /** ledger 소모량 (음수 합의 절대값) */
  private async countGenerationsUsed(
    userId: string,
    chapterId: string,
  ): Promise<number> {
    const rows = await this.ledger.find({
      where: { userId, userChapterId: chapterId, feature: 'audiobook' },
    });
    const sum = rows.reduce((acc, r) => acc + r.delta, 0);
    return Math.max(0, -sum);
  }

  private async restoreQuota(
    userId: string,
    bookId: string,
    chapterId: string,
    reasonSuffix: string,
  ) {
    try {
      await this.ledger.insert({
        userId,
        bookId,
        userChapterId: chapterId,
        feature: 'audiobook',
        delta: 1,
        reason: `audiobook_restore_${reasonSuffix}`,
        idempotencyKey: `restore_${reasonSuffix}`,
      });
    } catch {
      // 이미 복구됨
    }
  }
}

class CancelledError extends Error {
  constructor() {
    super('cancelled');
    this.name = 'CancelledError';
  }
}
