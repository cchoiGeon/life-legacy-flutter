import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ChapterStatus } from '../const/chapter-status.enum';
import { QuestionStatus } from '../const/question-status.enum';
import { UserChapterModel } from '../entities/user-chapter.entity';
import { UserQuestionModel } from '../entities/user-question.entity';

@Injectable()
export class ChaptersRepository {
  constructor(
    @InjectRepository(UserChapterModel)
    private readonly chapters: Repository<UserChapterModel>,
    @InjectRepository(UserQuestionModel)
    private readonly questions: Repository<UserQuestionModel>,
  ) {}

  async findAllByBook(bookId: string): Promise<UserChapterModel[]> {
    return await this.chapters.find({
      where: { bookId },
      order: { sortOrder: 'ASC' },
    });
  }

  async findWritingChapter(bookId: string): Promise<UserChapterModel | null> {
    return await this.chapters.findOne({
      where: { bookId, status: ChapterStatus.WRITING },
    });
  }

  async findChapterById(chapterId: string): Promise<UserChapterModel | null> {
    return await this.chapters.findOne({
      where: { id: chapterId },
      relations: { book: true },
    });
  }

  async findNextChapter(
    bookId: string,
    afterOrder: number,
  ): Promise<UserChapterModel | null> {
    return await this.chapters
      .createQueryBuilder('c')
      .where('c.book_id = :bookId', { bookId })
      .andWhere('c.sort_order > :afterOrder', { afterOrder })
      .orderBy('c.sort_order', 'ASC')
      .getOne();
  }

  /** 그 장에서 아직 답하지 않은 가장 앞 순번의 질문 */
  async findFirstPending(chapterId: string): Promise<UserQuestionModel | null> {
    return await this.questions.findOne({
      where: {
        userChapter: { id: chapterId },
        status: QuestionStatus.PENDING,
      },
      order: { sortOrder: 'ASC' },
      relations: { userChapter: { book: true } },
    });
  }

  async findQuestionById(
    questionId: string,
  ): Promise<UserQuestionModel | null> {
    return await this.questions.findOne({
      where: { id: questionId },
      relations: { userChapter: { book: true } },
    });
  }

  async saveChapter(chapter: UserChapterModel): Promise<UserChapterModel> {
    return await this.chapters.save(chapter);
  }

  async saveQuestion(question: UserQuestionModel): Promise<UserQuestionModel> {
    return await this.questions.save(question);
  }

  async countByBook(
    bookId: string,
  ): Promise<{ total: number; answered: number }> {
    const total = await this.questions
      .createQueryBuilder('q')
      .innerJoin('q.userChapter', 'c')
      .where('c.book_id = :bookId', { bookId })
      .getCount();

    const answered = await this.questions
      .createQueryBuilder('q')
      .innerJoin('q.userChapter', 'c')
      .where('c.book_id = :bookId', { bookId })
      .andWhere('q.status != :pending', { pending: QuestionStatus.PENDING })
      .getCount();

    return { total, answered };
  }

  async countQuestionsInChapter(chapterId: string): Promise<{
    questionCount: number;
    answeredCount: number;
    skippedCount: number;
  }> {
    const rows = await this.questions
      .createQueryBuilder('q')
      .innerJoin('q.userChapter', 'c')
      .select('q.status', 'status')
      .addSelect('COUNT(*)', 'cnt')
      .where('c.id = :chapterId', { chapterId })
      .groupBy('q.status')
      .getRawMany<{ status: QuestionStatus; cnt: string }>();

    let questionCount = 0;
    let answeredCount = 0;
    let skippedCount = 0;
    for (const row of rows) {
      const n = Number(row.cnt);
      questionCount += n;
      if (row.status === QuestionStatus.ANSWERED) answeredCount = n;
      if (row.status === QuestionStatus.SKIPPED) skippedCount = n;
    }
    return { questionCount, answeredCount, skippedCount };
  }
}
