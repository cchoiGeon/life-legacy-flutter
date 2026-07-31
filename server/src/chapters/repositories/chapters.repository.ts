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

  async findAllByUser(userId: string): Promise<UserChapterModel[]> {
    return await this.chapters.find({
      where: { user: { id: userId } },
      order: { sortOrder: 'ASC' },
    });
  }

  async findWritingChapter(userId: string): Promise<UserChapterModel | null> {
    return await this.chapters.findOne({
      where: { user: { id: userId }, status: ChapterStatus.WRITING },
    });
  }

  async findNextChapter(
    userId: string,
    afterOrder: number,
  ): Promise<UserChapterModel | null> {
    return await this.chapters
      .createQueryBuilder('c')
      .where('c.user_id = :userId', { userId })
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
      relations: { userChapter: true },
    });
  }

  async findQuestionById(
    questionId: string,
  ): Promise<UserQuestionModel | null> {
    return await this.questions.findOne({
      where: { id: questionId },
      relations: { userChapter: { user: true } },
    });
  }

  async saveChapter(chapter: UserChapterModel): Promise<UserChapterModel> {
    return await this.chapters.save(chapter);
  }

  async saveQuestion(question: UserQuestionModel): Promise<UserQuestionModel> {
    return await this.questions.save(question);
  }

  async countByUser(
    userId: string,
  ): Promise<{ total: number; answered: number }> {
    const total = await this.questions
      .createQueryBuilder('q')
      .innerJoin('q.userChapter', 'c')
      .where('c.user_id = :userId', { userId })
      .getCount();

    const answered = await this.questions
      .createQueryBuilder('q')
      .innerJoin('q.userChapter', 'c')
      .where('c.user_id = :userId', { userId })
      .andWhere('q.status != :pending', { pending: QuestionStatus.PENDING })
      .getCount();

    return { total, answered };
  }
}
