import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { AnswersRepository } from 'src/answers/repositories/answers.repository';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { EntitlementService } from 'src/entitlement/services/entitlement.service';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { BookAccessService } from './book-access.service';
import { BookPageModel } from '../entities/book-page.entity';
import { BookPageResponseDto } from '../dto/response/book-page-response.dto';
import { BookModel } from '../entities/book.entity';

const PARAGRAPHS_PER_PAGE = 3;

type BookStatus = 'draft' | 'writing' | 'completed';

@Injectable()
export class BookService {
  constructor(
    @InjectRepository(BookPageModel)
    private readonly pages: Repository<BookPageModel>,
    @InjectRepository(BookModel)
    private readonly books: Repository<BookModel>,
    @InjectRepository(ChapterReviewModel)
    private readonly reviews: Repository<ChapterReviewModel>,
    private readonly bookAccess: BookAccessService,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly answersRepository: AnswersRepository,
    private readonly entitlementService: EntitlementService,
  ) {}

  async listBooks(userId: string): Promise<
    Array<{
      id: string;
      title: string;
      author_name: string;
      status: BookStatus;
      chapter_count: number;
      chapter_done: number;
      progress: number;
      updated_at: string;
    }>
  > {
    const books = await this.bookAccess.findOwnedBooks(userId);
    const items: Array<{
      id: string;
      title: string;
      author_name: string;
      status: BookStatus;
      chapter_count: number;
      chapter_done: number;
      progress: number;
      updated_at: string;
    }> = [];

    for (const book of books) {
      const chapters = await this.chaptersRepository.findAllByBook(book.id);
      const { total, answered } =
        await this.chaptersRepository.countByBook(book.id);
      const reviewMap = await this.reviewStatusByChapter(
        chapters.map((c) => c.id),
      );
      const chapterDone = chapters.filter(
        (c) => c.status === ChapterStatus.DONE,
      ).length;
      const status = this.deriveStatus(chapters, reviewMap);

      items.push({
        id: book.id,
        title: book.title,
        author_name: book.authorName,
        status,
        chapter_count: chapters.length,
        chapter_done: chapterDone,
        progress: total === 0 ? 0 : answered / total,
        updated_at: book.updatedAt.toISOString(),
      });
    }

    return items;
  }

  /** api-spec §6.2 상세 허브 */
  async getBook(userId: string, bookId: string) {
    const book = await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const { total, answered } =
      await this.chaptersRepository.countByBook(bookId);
    const reviewMap = await this.reviewStatusByChapter(
      chapters.map((c) => c.id),
    );
    const status = this.deriveStatus(chapters, reviewMap);
    const chapterDone = chapters.filter(
      (c) => c.status === ChapterStatus.DONE,
    ).length;
    const pages = await this.buildPages(bookId, reviewMap);

    const chapterDtos: Array<{
      id: string;
      order: number;
      title: string;
      status: ChapterStatus;
      answered_count: number;
      question_count: number;
      next_question_text: string | null;
      review_status: ReviewStatus | null;
      ebook_eligible: boolean;
    }> = [];
    for (const chapter of chapters) {
      const next =
        chapter.status === ChapterStatus.WRITING
          ? await this.chaptersRepository.findFirstPending(chapter.id)
          : null;
      const reviewStatus = reviewMap.get(chapter.id) ?? null;
      chapterDtos.push({
        id: chapter.id,
        order: chapter.sortOrder,
        title: chapter.title,
        status: chapter.status,
        answered_count: chapter.answeredCount,
        question_count: chapter.questionCount,
        next_question_text:
          chapter.status === ChapterStatus.WRITING
            ? (next?.text ?? null)
            : null,
        review_status: reviewStatus,
        ebook_eligible: reviewStatus === ReviewStatus.REVIEWED,
      });
    }

    const current = await this.chaptersRepository.findWritingChapter(bookId);
    let currentQuestion: {
      id: string;
      chapter_id: string;
      chapter_title: string;
      order: number;
      text: string;
    } | null = null;
    if (current) {
      const pending = await this.chaptersRepository.findFirstPending(
        current.id,
      );
      if (pending) {
        currentQuestion = {
          id: pending.id,
          chapter_id: current.id,
          chapter_title: current.title,
          order: pending.sortOrder,
          text: pending.text,
        };
      }
    }

    return {
      id: book.id,
      title: book.title,
      author_name: book.authorName,
      status,
      progress: total === 0 ? 0 : answered / total,
      chapter_done: chapterDone,
      chapter_total: chapters.length,
      current_question: currentQuestion,
      chapters: chapterDtos,
      entitlements: await this.entitlementService.getDashboardEntitlements(
        userId,
        bookId,
      ),
      // E3 완성 화면 호환
      chapter_count: chapters.length,
      question_count: answered,
      page_count: pages.length,
      photo_count: book.photoCount,
      is_complete: status === 'completed',
    };
  }

  /** api-spec §11 */
  async getEntitlements(userId: string, bookId: string) {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    return this.entitlementService.getBookEntitlements(userId, bookId);
  }

  async getPages(
    userId: string,
    bookId: string,
  ): Promise<BookPageResponseDto[]> {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const reviewMap = await this.reviewStatusByChapter(
      chapters.map((c) => c.id),
    );
    return await this.buildPages(bookId, reviewMap);
  }

  /**
   * 미리보기/ebook: **reviewed** 장만 포함 (화면 MD 06-1-1).
   * review 없는 done 장은 아직 원고로 올리지 않는다.
   */
  private async buildPages(
    bookId: string,
    reviewMap?: Map<string, ReviewStatus>,
  ): Promise<BookPageResponseDto[]> {
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const statuses =
      reviewMap ??
      (await this.reviewStatusByChapter(chapters.map((c) => c.id)));
    const eligible = chapters.filter(
      (c) => statuses.get(c.id) === ReviewStatus.REVIEWED,
    );

    const result: BookPageResponseDto[] = [];
    let pageNumber = 1;

    for (const chapter of eligible) {
      const answers = await this.answersRepository.findPolishedByChapter(
        chapter.id,
      );
      const paragraphs = answers
        .map((a) => a.polishedText ?? a.firstText)
        .flatMap((text) => text.split('\n\n'))
        .map((p) => p.trim())
        .filter((p) => p.length > 0);

      for (let i = 0; i < paragraphs.length; i += PARAGRAPHS_PER_PAGE) {
        result.push({
          chapter_order: chapter.sortOrder,
          chapter_title: chapter.title,
          page_number: pageNumber++,
          total_pages: 0,
          paragraphs: paragraphs.slice(i, i + PARAGRAPHS_PER_PAGE),
        });
      }
    }

    return result.map((page) => ({ ...page, total_pages: result.length }));
  }

  private deriveStatus(
    chapters: { id: string; status: ChapterStatus }[],
    reviewMap: Map<string, ReviewStatus>,
  ): BookStatus {
    if (chapters.length === 0) return 'draft';
    const allReviewed = chapters.every(
      (c) => reviewMap.get(c.id) === ReviewStatus.REVIEWED,
    );
    if (allReviewed) return 'completed';
    return 'writing';
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
