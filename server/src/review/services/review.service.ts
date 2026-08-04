import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { AiService } from 'src/ai/services/ai.service';
import { AnswersRepository } from 'src/answers/repositories/answers.repository';
import { BookAccessService } from 'src/book/services/book-access.service';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { VoiceService } from 'src/voice/voice.service';
import { ChapterReviewModel } from '../entities/chapter-review.entity';

@Injectable()
export class ReviewService {
  constructor(
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
    private readonly bookAccess: BookAccessService,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly answersRepository: AnswersRepository,
    private readonly aiService: AiService,
    private readonly voiceService: VoiceService,
  ) {}

  async getReview(userId: string, bookId: string, chapterId: string) {
    const chapter = await this.requireDoneChapter(userId, bookId, chapterId);
    const review = await this.reviews.findOne({
      where: { userChapterId: chapter.id },
    });
    if (!review) return null;
    return this.toDto(chapter, review);
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
    return this.toDto(chapter, review);
  }

  async saveReview(
    userId: string,
    bookId: string,
    chapterId: string,
    input: { status?: string; version: number },
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
      ...this.toDto(chapter, saved),
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
    const paragraphs = review.body
      .split(/\n\n+/)
      .map((p) => p.trim())
      .filter((p) => p.length > 0);

    return this.voiceService.synthesizeChunks(
      paragraphs,
      input.fromParagraph,
      input.chunkSize,
      input.voiceCode,
    );
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

  private toDto(
    chapter: { id: string; sortOrder: number; title: string },
    review: ChapterReviewModel,
  ) {
    const paragraphs = review.body
      .split(/\n\n+/)
      .map((p) => p.trim())
      .filter((p) => p.length > 0);

    return {
      chapter_id: chapter.id,
      chapter_order: chapter.sortOrder,
      chapter_title: chapter.title,
      status: review.status,
      version: review.version,
      paragraphs,
      media: [] as Array<{
        id: string;
        url: string;
        paragraph_index: number;
        source: string;
      }>,
      permissions: {
        manual_photo: false,
        ai_photo: true,
        ai_rewrite: false,
        edit_body: false,
      },
      edit_hint: '웹에서 수정할 수 있어요',
    };
  }
}
