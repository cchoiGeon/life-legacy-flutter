import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { AnswerDraftModel } from '../entities/answer-draft.entity';
import { AnswerFollowupModel } from '../entities/answer-followup.entity';
import { AnswerModel } from '../entities/answer.entity';

@Injectable()
export class AnswersRepository {
  constructor(
    @InjectRepository(AnswerModel)
    private readonly answers: Repository<AnswerModel>,
    @InjectRepository(AnswerDraftModel)
    private readonly drafts: Repository<AnswerDraftModel>,
    @InjectRepository(AnswerFollowupModel)
    private readonly followups: Repository<AnswerFollowupModel>,
  ) {}

  async findAnswerByQuestion(questionId: string): Promise<AnswerModel | null> {
    return await this.answers.findOne({
      where: { userQuestion: { id: questionId } },
    });
  }

  async findDraftByQuestion(
    questionId: string,
  ): Promise<AnswerDraftModel | null> {
    return await this.drafts.findOne({
      where: { userQuestion: { id: questionId } },
    });
  }

  async saveDraft(draft: Partial<AnswerDraftModel>): Promise<AnswerDraftModel> {
    return await this.drafts.save(this.drafts.create(draft));
  }

  async deleteDraft(questionId: string): Promise<void> {
    await this.drafts.delete({ userQuestion: { id: questionId } });
  }

  async findPolishedByChapter(chapterId: string): Promise<AnswerModel[]> {
    return await this.answers
      .createQueryBuilder('a')
      .innerJoin('a.userQuestion', 'q')
      .where('q.user_chapter_id = :chapterId', { chapterId })
      .orderBy('q.sort_order', 'ASC')
      .getMany();
  }

  async countAnsweredByUser(userId: string): Promise<number> {
    return await this.answers
      .createQueryBuilder('a')
      .innerJoin('a.userQuestion', 'q')
      .innerJoin('q.userChapter', 'c')
      .where('c.user_id = :userId', { userId })
      .getCount();
  }

  createFollowupId(): string {
    return this.followups.create().id ?? '';
  }
}
