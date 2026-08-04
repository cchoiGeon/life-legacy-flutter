import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { AnswerDraftModel } from '../entities/answer-draft.entity';
import { AnswerFollowupModel } from '../entities/answer-followup.entity';
import { AnswerModel } from '../entities/answer.entity';
import { DraftPhase } from '../const/answer.enum';

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

  async upsertFirstPhaseDraft(
    questionId: string,
    data: {
      userQuestion: AnswerDraftModel['userQuestion'];
      firstText: string;
      firstInputMode: AnswerDraftModel['firstInputMode'];
      firstSpokenSeconds: number | null;
    },
  ): Promise<AnswerDraftModel> {
    const existing = await this.findDraftByQuestion(questionId);
    if (existing) {
      existing.firstText = data.firstText;
      existing.firstInputMode = data.firstInputMode;
      existing.firstSpokenSeconds = data.firstSpokenSeconds;
      if (existing.phase !== DraftPhase.FOLLOWUP) {
        existing.phase = DraftPhase.FIRST;
        existing.followupQuestionText = null;
        existing.followupId = null;
        existing.followupRound = 0;
        existing.followups = null;
      }
      return await this.drafts.save(existing);
    }
    return await this.saveDraft({
      userQuestion: data.userQuestion,
      phase: DraftPhase.FIRST,
      firstText: data.firstText,
      firstInputMode: data.firstInputMode,
      firstSpokenSeconds: data.firstSpokenSeconds,
      followupRound: 0,
      followups: null,
      followupQuestionText: null,
      followupId: null,
    });
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

  async countAnsweredByBook(bookId: string): Promise<number> {
    return await this.answers
      .createQueryBuilder('a')
      .innerJoin('a.userQuestion', 'q')
      .innerJoin('q.userChapter', 'c')
      .where('c.book_id = :bookId', { bookId })
      .getCount();
  }

  createFollowupId(): string {
    return this.followups.create().id ?? '';
  }
}
