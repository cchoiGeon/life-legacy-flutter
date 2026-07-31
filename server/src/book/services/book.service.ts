import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { AnswersRepository } from 'src/answers/repositories/answers.repository';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ChaptersRepository } from 'src/chapters/repositories/chapters.repository';
import { UsersService } from 'src/users/services/users.service';
import { BookPageModel } from '../entities/book-page.entity';
import { BookPageResponseDto } from '../dto/response/book-page-response.dto';
import { BookResponseDto } from '../dto/response/book-response.dto';

/** 한 쪽에 담는 문단 수 — 쪽 나누기는 **서버가** 정한다. 앱은 받은 대로 그린다 */
const PARAGRAPHS_PER_PAGE = 3;

@Injectable()
export class BookService {
  constructor(
    @InjectRepository(BookPageModel)
    private readonly pages: Repository<BookPageModel>,
    private readonly chaptersRepository: ChaptersRepository,
    private readonly answersRepository: AnswersRepository,
    private readonly usersService: UsersService,
  ) {}

  async getBook(userId: string): Promise<BookResponseDto> {
    const user = await this.usersService.getOrThrow(userId);
    const chapters = await this.chaptersRepository.findAllByUser(userId);
    const answered = await this.answersRepository.countAnsweredByUser(userId);
    const pages = await this.buildPages(userId);

    return {
      title: '나의 이야기',
      author_name: user.name,
      chapter_count: chapters.length,
      question_count: answered,
      page_count: pages.length,
      photo_count: 0,
      is_complete:
        chapters.length > 0 &&
        chapters.every((c) => c.status === ChapterStatus.DONE),
    };
  }

  async getPages(userId: string): Promise<BookPageResponseDto[]> {
    return await this.buildPages(userId);
  }

  /**
   * done 장의 윤문 결과를 이어 붙여 쪽을 나눈다.
   *
   * 매번 새로 계산한다 — 장이 끝날 때마다 캐시를 갱신하는 쪽이 빠르지만,
   * 어긋났을 때 사용자가 보는 건 "내 이야기가 사라졌다"이다. v1은 정확성을
   * 택하고, 느려지면 book_page 표에 캐시한다.
   */
  private async buildPages(userId: string): Promise<BookPageResponseDto[]> {
    const chapters = await this.chaptersRepository.findAllByUser(userId);
    const done = chapters.filter((c) => c.status === ChapterStatus.DONE);

    const result: BookPageResponseDto[] = [];
    let pageNumber = 1;

    for (const chapter of done) {
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

    // 앱이 쪽 하나만 들고도 "12 / 34쪽"을 그릴 수 있어야 해서 쪽마다 총수를 싣는다.
    return result.map((page) => ({ ...page, total_pages: result.length }));
  }
}
