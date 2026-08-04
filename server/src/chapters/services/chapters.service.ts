import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { ChapterStatus } from '../const/chapter-status.enum';
import { QuestionStatus } from '../const/question-status.enum';
import { ChapterCompletionResponseDto } from '../dto/response/chapter-completion-response.dto';
import { ChapterResponseDto } from '../dto/response/chapter-response.dto';
import { QuestionResponseDto } from '../dto/response/question-response.dto';
import { UserQuestionModel } from '../entities/user-question.entity';
import { ChaptersRepository } from '../repositories/chapters.repository';

@Injectable()
export class ChaptersService {
  constructor(
    private readonly chaptersRepository: ChaptersRepository,
    private readonly bookAccess: BookAccessService,
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
  ) {}

  async getChapters(
    userId: string,
    bookId: string,
  ): Promise<ChapterResponseDto[]> {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const reviewMap = await this.reviewStatusByChapter(
      chapters.map((c) => c.id),
    );

    const result: ChapterResponseDto[] = [];
    for (const chapter of chapters) {
      const next =
        chapter.status === ChapterStatus.WRITING
          ? await this.chaptersRepository.findFirstPending(chapter.id)
          : null;
      result.push(
        ChapterResponseDto.from(
          chapter,
          next?.text ?? null,
          reviewMap.get(chapter.id) ?? null,
        ),
      );
    }

    return result;
  }

  /** 지금 답할 질문. 모든 장을 끝냈으면 null(컨트롤러가 204로 바꾼다) */
  async getCurrentQuestion(
    userId: string,
    bookId: string,
  ): Promise<UserQuestionModel | null> {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapter = await this.chaptersRepository.findWritingChapter(bookId);
    if (!chapter) {
      return null;
    }

    return await this.chaptersRepository.findFirstPending(chapter.id);
  }

  /**
   * 소유 책의 질문을 집어 온다. 잠긴 장이면 막는다.
   * 남의 질문 id면 404.
   */
  async getOwnedQuestion(
    userId: string,
    questionId: string,
  ): Promise<UserQuestionModel> {
    const question = await this.chaptersRepository.findQuestionById(questionId);
    if (
      !question ||
      question.userChapter.book.ownerUserId !== userId
    ) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    if (question.userChapter.status === ChapterStatus.LOCKED) {
      throw new ApiException(ERROR_CODE.WRITE.CHAPTER_LOCKED);
    }

    return question;
  }

  async updateQuestionText(
    userId: string,
    questionId: string,
    text: string,
  ): Promise<QuestionResponseDto> {
    const question = await this.getOwnedQuestion(userId, questionId);

    if (question.status !== QuestionStatus.PENDING) {
      throw new ApiException(ERROR_CODE.WRITE.ALREADY_ANSWERED);
    }

    question.text = text;
    question.isEdited = true;
    const saved = await this.chaptersRepository.saveQuestion(question);

    return QuestionResponseDto.from(saved);
  }

  /** api-spec §5.9 — 챕터 완료 화면용 조회 */
  async getChapterCompletion(
    userId: string,
    bookId: string,
    chapterId: string,
  ): Promise<ChapterCompletionResponseDto> {
    await this.bookAccess.requireOwnedBook(userId, bookId);

    const chapter = await this.chaptersRepository.findChapterById(chapterId);
    if (!chapter || chapter.bookId !== bookId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    if (chapter.status === ChapterStatus.LOCKED) {
      throw new ApiException(ERROR_CODE.WRITE.CHAPTER_LOCKED);
    }

    const counts =
      await this.chaptersRepository.countQuestionsInChapter(chapterId);
    const review = await this.reviews.findOne({
      where: { userChapterId: chapterId },
    });
    const next = await this.chaptersRepository.findNextChapter(
      bookId,
      chapter.sortOrder,
    );

    return {
      chapter_id: chapter.id,
      chapter_order: chapter.sortOrder,
      chapter_title: chapter.title,
      question_count: counts.questionCount,
      answered_count: counts.answeredCount,
      skipped_count: counts.skippedCount,
      review_status:
        review?.status === ReviewStatus.REVIEWED ? ReviewStatus.REVIEWED : null,
      next_chapter: next
        ? { id: next.id, order: next.sortOrder, title: next.title }
        : null,
      actions: {
        review: chapter.status === ChapterStatus.DONE,
        hub: true,
      },
    };
  }

  private async reviewStatusByChapter(
    chapterIds: string[],
  ): Promise<Map<string, ReviewStatus>> {
    const map = new Map<string, ReviewStatus>();
    if (chapterIds.length === 0) return map;
    const rows = await this.reviews.find({
      where: { userChapterId: In(chapterIds) },
    });
    for (const row of rows) {
      map.set(row.userChapterId, row.status);
    }
    return map;
  }
}
