import { Injectable } from '@nestjs/common';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { ChaptersService } from 'src/chapters/services/chapters.service';
import { HomeResponseDto } from '../dto/response/home-response.dto';

@Injectable()
export class HomeService {
  constructor(
    private readonly bookAccess: BookAccessService,
    private readonly chaptersService: ChaptersService,
    private readonly chaptersRepository: ChaptersRepository,
  ) {}

  async getHome(userId: string, bookId: string): Promise<HomeResponseDto> {
    await this.bookAccess.requireOwnedBook(userId, bookId);
    const chapters = await this.chaptersRepository.findAllByBook(bookId);
    const { total, answered } =
      await this.chaptersRepository.countByBook(bookId);
    const current = await this.chaptersService.getCurrentQuestion(
      userId,
      bookId,
    );

    return {
      book_id: bookId,
      today_question: current?.text ?? null,
      today_question_id: current?.id ?? null,
      progress: total === 0 ? 0 : answered / total,
      chapter_done: chapters.filter((c) => c.status === ChapterStatus.DONE)
        .length,
      chapter_total: chapters.length,
      remaining_questions: total - answered,
    };
  }
}
