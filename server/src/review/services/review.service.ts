import {
  createReadStream,
  existsSync,
  mkdirSync,
  readFileSync,
  unlinkSync,
  writeFileSync,
} from 'fs';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { Injectable, StreamableFile } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';

import { AiService } from 'src/ai/services/ai.service';
import { AnswersRepository } from 'src/answers/repositories/answers.repository';
import { BookAccessService } from 'src/book/services/book-access.service';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { MediaKind } from 'src/common/const/media-kind.enum';
import { MediaSource } from 'src/common/const/media-source.enum';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { EntitlementService } from 'src/entitlement/services/entitlement.service';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { MediaPlacementModel } from 'src/media/entities/media-placement.entity';
import { VoiceService } from 'src/voice/voice.service';
import { ChapterReviewModel } from '../entities/chapter-review.entity';

const MANUAL_PHOTO_MAX = 5;
const AI_PHOTO_REGEN_MAX = 5;
const AI_PHOTO_REGEN_PLANS = new Set(['T3', 'T4']);
const PHOTO_MAX_BYTES = 8 * 1024 * 1024;
const ALLOWED_PHOTO_MIME = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
]);
const FEATURE_AI_PHOTO = 'ai_photo';
const FEATURE_AI_PHOTO_REGEN = 'ai_photo_regen';

@Injectable()
export class ReviewService {
  constructor(
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
    @InjectRepository(MediaAssetModel)
    private readonly assets: Repository<MediaAssetModel>,
    @InjectRepository(MediaPlacementModel)
    private readonly placements: Repository<MediaPlacementModel>,
    private readonly bookAccess: BookAccessService,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly answersRepository: AnswersRepository,
    private readonly aiService: AiService,
    private readonly voiceService: VoiceService,
    private readonly entitlements: EntitlementService,
  ) {}

  async getReview(userId: string, bookId: string, chapterId: string) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.reviews.findOne({
      where: { userChapterId: chapter.id },
    });
    if (!review) return null;
    return this.toDto(userId, bookId, chapter, review);
  }

  async synthesize(userId: string, bookId: string, chapterId: string) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const answers = await this.answersRepository.findPolishedByChapter(
      chapter.id,
    );
    const texts = answers.map((a) => a.polishedText ?? a.firstText);

    let body: string;
    try {
      body = await this.aiService.synthesizeChapter({
        chapterTitle: chapter.title,
        answers: texts,
      });
    } catch {
      throw new ApiException(ERROR_CODE.WRITE.SYNTHESIZE_FAILED);
    }

    let review = await this.reviews.findOne({
      where: { userChapterId: chapter.id },
    });

    if (review) {
      review.aiDraft = body;
      review.body = body;
      review.version += 1;
      review.status = ReviewStatus.DRAFT;
      review.reviewedAt = null;
    } else {
      review = this.reviews.create({
        userChapterId: chapter.id,
        userChapter: chapter,
        body,
        aiDraft: body,
        version: 1,
        status: ReviewStatus.DRAFT,
      });
    }

    review = await this.reviews.save(review);
    return this.toDto(userId, bookId, chapter, review);
  }

  async saveReview(
    userId: string,
    bookId: string,
    chapterId: string,
    input: { status?: string; version: number; body?: string },
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.reviews.findOne({
      where: { userChapterId: chapter.id },
    });
    if (!review) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    if (review.version !== input.version) {
      throw new ApiException(ERROR_CODE.WRITE.VERSION_CONFLICT);
    }

    if (input.body != null) {
      const nextBody = input.body.trim();
      if (!nextBody) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }
      if (nextBody !== review.body) {
        review.body = nextBody;
        review.version += 1;
      }
    }

    if (input.status === ReviewStatus.REVIEWED) {
      review.status = ReviewStatus.REVIEWED;
      review.reviewedAt = new Date();
    }

    const saved = await this.reviews.save(review);
    const next = await this.chaptersRepository.findNextChapter(
      bookId,
      chapter.sortOrder,
    );

    const message =
      chapter.sortOrder === 1 ? '챕터1 저장 완료' : '현재 챕터 저장 완료';

    return {
      ...(await this.toDto(userId, bookId, chapter, saved)),
      message,
      next_chapter_id: next?.id ?? null,
    };
  }

  /** api-spec §9.4 — 원고 문단 청크 TTS */
  async synthesizeReviewTts(
    userId: string,
    bookId: string,
    chapterId: string,
    input: { fromParagraph: number; chunkSize: number; voiceCode?: string },
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.reviews.findOne({
      where: { userChapterId: chapter.id },
    });
    if (!review) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    const paragraphs = splitParagraphs(review.body);

    return this.voiceService.synthesizeChunks(
      paragraphs,
      input.fromParagraph,
      input.chunkSize,
      input.voiceCode,
    );
  }

  async addMedia(
    userId: string,
    bookId: string,
    chapterId: string,
    file: Express.Multer.File,
    paragraphIndex: number,
    caption?: string,
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);
    await this.requireManualPhoto(userId, bookId);

    if (!file?.buffer?.length) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    if (file.size > PHOTO_MAX_BYTES) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    const mime = (file.mimetype || '').toLowerCase();
    if (!ALLOWED_PHOTO_MIME.has(mime)) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const paragraphs = splitParagraphs(review.body);
    if (paragraphIndex < 0 || paragraphIndex >= paragraphs.length) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const existingManual = await this.placements
      .createQueryBuilder('p')
      .innerJoin('p.mediaAsset', 'a')
      .where('p.chapter_review_id = :id', { id: review.id })
      .andWhere('a.source = :src', { src: MediaSource.USER_UPLOAD })
      .andWhere('a.deleted_at IS NULL')
      .getCount();
    if (existingManual >= MANUAL_PHOTO_MAX) {
      throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
    }

    const ext = mime.includes('png')
      ? 'png'
      : mime.includes('webp')
        ? 'webp'
        : 'jpg';
    const dir = join(process.cwd(), 'storage', 'reviews', bookId, chapterId);
    mkdirSync(dir, { recursive: true });

    const asset = this.assets.create({
      bookId,
      kind: MediaKind.IMAGE,
      source: MediaSource.USER_UPLOAD,
      objectKey: '',
      mimeType: mime,
      byteSize: String(file.size),
      checksum: null,
      durationMs: null,
      expiresAt: null,
      deletedAt: null,
    });
    const savedAsset = await this.assets.save(asset);

    const relativeKey = join(
      'storage',
      'reviews',
      bookId,
      chapterId,
      `${savedAsset.id}.${ext}`,
    );
    writeFileSync(join(process.cwd(), relativeKey), file.buffer);
    savedAsset.objectKey = relativeKey;
    await this.assets.save(savedAsset);

    const maxSort = await this.placements
      .createQueryBuilder('p')
      .select('COALESCE(MAX(p.sort_order), -1)', 'max')
      .where('p.chapter_review_id = :id', { id: review.id })
      .andWhere('p.paragraph_index = :pi', { pi: paragraphIndex })
      .getRawOne<{ max: string }>();

    const placement = await this.placements.save(
      this.placements.create({
        chapterReviewId: review.id,
        mediaAssetId: savedAsset.id,
        paragraphIndex,
        anchor: paragraphs[paragraphIndex]?.slice(0, 80) ?? null,
        sortOrder: Number(maxSort?.max ?? -1) + 1,
        caption: caption || null,
      }),
    );

    return {
      media: {
        id: placement.id,
        url: mediaFilePath(bookId, chapterId, placement.id),
        paragraph_index: placement.paragraphIndex,
        source: savedAsset.source,
        caption: placement.caption,
      },
    };
  }

  async updatePlacement(
    userId: string,
    bookId: string,
    chapterId: string,
    placementId: string,
    input: { caption?: string; paragraph_index?: number },
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);
    await this.requireManualPhoto(userId, bookId);

    const placement = await this.placements.findOne({
      where: { id: placementId, chapterReviewId: review.id },
    });
    if (!placement) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    if (input.caption !== undefined) {
      placement.caption = input.caption || null;
    }
    if (input.paragraph_index !== undefined) {
      const paragraphs = splitParagraphs(review.body);
      if (
        input.paragraph_index < 0 ||
        input.paragraph_index >= paragraphs.length
      ) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }
      placement.paragraphIndex = input.paragraph_index;
    }

    const saved = await this.placements.save(placement);
    return {
      media: {
        id: saved.id,
        url: mediaFilePath(bookId, chapterId, saved.id),
        paragraph_index: saved.paragraphIndex,
        source: 'user_upload',
        caption: saved.caption,
      },
    };
  }

  async getBookPhotos(userId: string, bookId: string) {
    await this.bookAccess.requireOwnedBook(userId, bookId);

    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const doneChapters = chapters.filter(
      (c) => c.status === ChapterStatus.DONE,
    );
    const chapterIds = doneChapters.map((c) => c.id);

    if (chapterIds.length === 0) return { chapters: [] };

    // Find all reviews for these chapters
    const reviews = await this.reviews.find({
      where: { userChapterId: In(chapterIds) },
    });
    const reviewMap = new Map(reviews.map((r) => [r.userChapterId, r]));
    const reviewIds = reviews.map((r) => r.id);

    if (reviewIds.length === 0) return { chapters: [] };

    const allPlacements = await this.placements.find({
      where: { chapterReviewId: In(reviewIds) },
      relations: { mediaAsset: true },
      order: { paragraphIndex: 'ASC', sortOrder: 'ASC' },
    });

    const chaptersWithPhotos = chapters
      .map((ch) => {
        const rev = reviewMap.get(ch.id);
        if (!rev) return null;
        const photos = allPlacements
          .filter(
            (p) =>
              p.chapterReviewId === rev.id &&
              p.mediaAsset &&
              !p.mediaAsset.deletedAt,
          )
          .map((p) => ({
            id: p.id,
            url: mediaFilePath(bookId, ch.id, p.id),
            caption: p.caption,
            paragraph_index: p.paragraphIndex,
            source: p.mediaAsset.source,
          }));
        if (photos.length === 0) return null;
        return {
          chapter_id: ch.id,
          chapter_order: ch.sortOrder,
          chapter_title: ch.title,
          photo_count: photos.length,
          photos,
        };
      })
      .filter((ch): ch is NonNullable<typeof ch> => ch !== null);

    return { chapters: chaptersWithPhotos };
  }

  async getChapterPhotos(
    userId: string,
    bookId: string,
    chapterId: string,
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);

    const placements = await this.placements.find({
      where: { chapterReviewId: review.id },
      relations: { mediaAsset: true },
      order: { paragraphIndex: 'ASC', sortOrder: 'ASC' },
    });

    const paragraphs = splitParagraphs(review.body);

    return {
      chapter_id: chapter.id,
      chapter_order: chapter.sortOrder,
      chapter_title: chapter.title,
      body: review.body,
      paragraphs,
      photos: placements
        .filter((p) => p.mediaAsset && !p.mediaAsset.deletedAt)
        .map((p) => ({
          id: p.id,
          url: mediaFilePath(bookId, chapterId, p.id),
          caption: p.caption,
          paragraph_index: p.paragraphIndex,
          source: p.mediaAsset.source,
        })),
    };
  }

  async removeMedia(
    userId: string,
    bookId: string,
    chapterId: string,
    placementId: string,
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);
    await this.requireManualPhoto(userId, bookId);

    const placement = await this.placements.findOne({
      where: { id: placementId, chapterReviewId: review.id },
      relations: { mediaAsset: true },
    });
    if (!placement) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const asset = placement.mediaAsset;
    await this.placements.remove(placement);
    if (asset) {
      const absolute = join(process.cwd(), asset.objectKey);
      if (existsSync(absolute)) {
        try {
          unlinkSync(absolute);
        } catch {
          // ignore
        }
      }
      asset.deletedAt = new Date();
      await this.assets.save(asset);
    }
    return { ok: true };
  }

  async getMediaFile(
    userId: string,
    bookId: string,
    chapterId: string,
    placementId: string,
  ): Promise<{ file: StreamableFile; contentType: string }> {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);
    const placement = await this.placements.findOne({
      where: { id: placementId, chapterReviewId: review.id },
      relations: { mediaAsset: true },
    });
    if (!placement?.mediaAsset || placement.mediaAsset.deletedAt) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const absolute = join(process.cwd(), placement.mediaAsset.objectKey);
    if (!existsSync(absolute)) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    return {
      file: new StreamableFile(createReadStream(absolute)),
      contentType: placement.mediaAsset.mimeType || 'image/jpeg',
    };
  }

  /**
   * AI 챕터 사진 1장 생성(또는 T3/T4 재생성).
   * 첫 슬롯(문단 0 뒤)에 배치. 재생성은 기존 AI 사진을 교체한다.
   */
  async generateAiPhoto(
    userId: string,
    bookId: string,
    chapterId: string,
    input: { regenerate?: boolean } = {},
  ) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.requireReview(chapter.id);
    const paragraphs = splitParagraphs(review.body);
    if (paragraphs.length === 0) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const existingAi = await this.findAiPlacement(review.id);
    const regenerate = Boolean(input.regenerate) || existingAi != null;
    const planCode = await this.entitlements.getPlanCode(userId);
    const regenUsed = await this.entitlements.countChapterUsage(
      userId,
      chapter.id,
      FEATURE_AI_PHOTO_REGEN,
    );
    const regenRemaining = Math.max(0, AI_PHOTO_REGEN_MAX - regenUsed);

    if (regenerate) {
      if (!existingAi) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }
      if (!AI_PHOTO_REGEN_PLANS.has(planCode)) {
        throw new ApiException(ERROR_CODE.PLAN.PLAN_REQUIRED);
      }
      if (regenRemaining <= 0) {
        throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
      }
    } else {
      if (existingAi) {
        throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
      }
      const ents = await this.entitlements.getBookEntitlements(userId, bookId);
      if (!ents.features.ai_photo.allowed) {
        throw new ApiException(ERROR_CODE.PLAN.PLAN_REQUIRED);
      }
    }

    const previousPrompt = existingAi
      ? readPromptSidecar(existingAi.mediaAsset.objectKey)
      : null;

    let imagePrompt: string;
    let image: { buffer: Buffer; mimeType: string };
    try {
      imagePrompt = await this.aiService.buildAiPhotoPrompt({
        chapterTitle: chapter.title,
        body: review.body,
        previousPrompt,
        regenerate,
      });
      image = await this.aiService.generateSquareImage(imagePrompt);
    } catch {
      throw new ApiException(ERROR_CODE.WRITE.IMAGE_FAILED);
    }

    if (existingAi) {
      await this.removePlacementInternal(existingAi);
    }

    const idempotencyKey = `ai_photo:${chapter.id}:${regenerate ? 'regen' : 'gen'}:${randomUUID()}`;
    try {
      await this.entitlements.recordUsage({
        userId,
        bookId,
        userChapterId: chapter.id,
        feature: regenerate ? FEATURE_AI_PHOTO_REGEN : FEATURE_AI_PHOTO,
        reason: regenerate ? 'ai_photo_regen' : 'ai_photo_generate',
        idempotencyKey,
      });
    } catch {
      throw new ApiException(ERROR_CODE.PLAN.QUOTA_EXCEEDED);
    }

    const placement = await this.persistImageAsset({
      bookId,
      chapterId,
      reviewId: review.id,
      paragraphIndex: 0,
      anchor: paragraphs[0]?.slice(0, 80) ?? null,
      buffer: image.buffer,
      mimeType: image.mimeType,
      source: MediaSource.AI_GENERATED,
      prompt: imagePrompt,
    });

    const nextRegenRemaining = regenerate
      ? Math.max(0, regenRemaining - 1)
      : regenRemaining;

    return {
      media: {
        id: placement.id,
        url: mediaFilePath(bookId, chapterId, placement.id),
        paragraph_index: placement.paragraphIndex,
        source: MediaSource.AI_GENERATED,
      },
      placement: {
        paragraph_index: placement.paragraphIndex,
        sort_order: placement.sortOrder,
      },
      remaining_generations: nextRegenRemaining,
      ai_photo: {
        has_photo: true,
        can_generate: false,
        can_regenerate:
          AI_PHOTO_REGEN_PLANS.has(planCode) && nextRegenRemaining > 0,
        regen_remaining: nextRegenRemaining,
      },
    };
  }

  private async findAiPlacement(reviewId: string) {
    return this.placements
      .createQueryBuilder('p')
      .innerJoinAndSelect('p.mediaAsset', 'a')
      .where('p.chapter_review_id = :id', { id: reviewId })
      .andWhere('a.source = :src', { src: MediaSource.AI_GENERATED })
      .andWhere('a.deleted_at IS NULL')
      .orderBy('p.sort_order', 'ASC')
      .getOne();
  }

  private async removePlacementInternal(placement: MediaPlacementModel) {
    const asset = placement.mediaAsset;
    await this.placements.remove(placement);
    if (asset) {
      const absolute = join(process.cwd(), asset.objectKey);
      if (existsSync(absolute)) {
        try {
          unlinkSync(absolute);
        } catch {
          // ignore
        }
      }
      const promptPath = promptSidecarPath(asset.objectKey);
      if (existsSync(promptPath)) {
        try {
          unlinkSync(promptPath);
        } catch {
          // ignore
        }
      }
      asset.deletedAt = new Date();
      await this.assets.save(asset);
    }
  }

  private async persistImageAsset(input: {
    bookId: string;
    chapterId: string;
    reviewId: string;
    paragraphIndex: number;
    anchor: string | null;
    buffer: Buffer;
    mimeType: string;
    source: MediaSource;
    prompt?: string;
  }) {
    const ext = input.mimeType.includes('png')
      ? 'png'
      : input.mimeType.includes('webp')
        ? 'webp'
        : 'jpg';
    const dir = join(
      process.cwd(),
      'storage',
      'reviews',
      input.bookId,
      input.chapterId,
    );
    mkdirSync(dir, { recursive: true });

    const asset = await this.assets.save(
      this.assets.create({
        bookId: input.bookId,
        kind: MediaKind.IMAGE,
        source: input.source,
        objectKey: '',
        mimeType: input.mimeType,
        byteSize: String(input.buffer.length),
        checksum: null,
        durationMs: null,
        expiresAt: null,
        deletedAt: null,
      }),
    );

    const relativeKey = join(
      'storage',
      'reviews',
      input.bookId,
      input.chapterId,
      `${asset.id}.${ext}`,
    );
    writeFileSync(join(process.cwd(), relativeKey), input.buffer);
    if (input.prompt) {
      writeFileSync(promptSidecarPath(relativeKey), input.prompt, 'utf8');
    }
    asset.objectKey = relativeKey;
    await this.assets.save(asset);

    const maxSort = await this.placements
      .createQueryBuilder('p')
      .select('COALESCE(MAX(p.sort_order), -1)', 'max')
      .where('p.chapter_review_id = :id', { id: input.reviewId })
      .andWhere('p.paragraph_index = :pi', { pi: input.paragraphIndex })
      .getRawOne<{ max: string }>();

    return this.placements.save(
      this.placements.create({
        chapterReviewId: input.reviewId,
        mediaAssetId: asset.id,
        paragraphIndex: input.paragraphIndex,
        anchor: input.anchor,
        sortOrder: Number(maxSort?.max ?? -1) + 1,
      }),
    );
  }

  private async requireManualPhoto(userId: string, bookId: string) {
    const ents = await this.entitlements.getBookEntitlements(userId, bookId);
    if (!ents.features.manual_photo.allowed) {
      throw new ApiException(ERROR_CODE.PLAN.PLAN_REQUIRED);
    }
  }

  private async requireReview(chapterId: string) {
    const review = await this.reviews.findOne({
      where: { userChapterId: chapterId },
    });
    if (!review) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    return review;
  }

  private async requireDoneChapter(
    userId: string,
    bookId: string,
    chapterId: string,
  ) {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapter = await this.chaptersRepository.findChapterById(chapterId);
    if (!chapter || chapter.bookId !== bookId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    if (chapter.status !== ChapterStatus.DONE) {
      throw new ApiException(ERROR_CODE.WRITE.CHAPTER_LOCKED);
    }
    return chapter;
  }

  private async toDto(
    userId: string,
    bookId: string,
    chapter: { id: string; sortOrder: number; title: string },
    review: ChapterReviewModel,
  ) {
    const paragraphs = splitParagraphs(review.body);
    const ents = await this.entitlements.getBookEntitlements(userId, bookId);
    const planCode = ents.plan_code;
    const mediaRows = await this.placements.find({
      where: { chapterReviewId: review.id },
      relations: { mediaAsset: true },
      order: { paragraphIndex: 'ASC', sortOrder: 'ASC' },
    });

    const media = mediaRows
      .filter((p) => p.mediaAsset && !p.mediaAsset.deletedAt)
      .map((p) => ({
        id: p.id,
        url: mediaFilePath(bookId, chapter.id, p.id),
        paragraph_index: p.paragraphIndex,
        source: p.mediaAsset.source,
        caption: p.caption,
      }));

    const hasAiPhoto = media.some((m) => m.source === MediaSource.AI_GENERATED);
    const regenUsed = await this.entitlements.countChapterUsage(
      userId,
      chapter.id,
      FEATURE_AI_PHOTO_REGEN,
    );
    const regenRemaining = Math.max(0, AI_PHOTO_REGEN_MAX - regenUsed);
    const canRegen =
      hasAiPhoto &&
      AI_PHOTO_REGEN_PLANS.has(planCode) &&
      regenRemaining > 0;
    const canGenerate =
      ents.features.ai_photo.allowed && !hasAiPhoto;

    return {
      chapter_id: chapter.id,
      chapter_order: chapter.sortOrder,
      chapter_title: chapter.title,
      status: review.status,
      version: review.version,
      paragraphs,
      media,
      permissions: {
        manual_photo: ents.features.manual_photo.allowed,
        ai_photo: canGenerate,
        ai_photo_regen: canRegen,
        ai_photo_regen_remaining: regenRemaining,
        ai_rewrite: ents.features.ai_rewrite.allowed,
        edit_body: true,
      },
      edit_hint: ents.features.manual_photo.allowed
        ? '문장을 고치고 사진을 넣을 수 있어요'
        : '문장을 고칠 수 있어요. 사진 추가는 유료에서 가능해요',
    };
  }
}

function splitParagraphs(body: string): string[] {
  return body
    .split(/\n\n+/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
}

function mediaFilePath(
  bookId: string,
  chapterId: string,
  placementId: string,
): string {
  return `/books/${bookId}/chapters/${chapterId}/review/media/${placementId}/file`;
}

function promptSidecarPath(objectKey: string): string {
  return join(process.cwd(), `${objectKey}.prompt.txt`);
}

function readPromptSidecar(objectKey: string): string | null {
  const path = promptSidecarPath(objectKey);
  if (!existsSync(path)) return null;
  try {
    return readFileSync(path, 'utf8').trim() || null;
  } catch {
    return null;
  }
}
