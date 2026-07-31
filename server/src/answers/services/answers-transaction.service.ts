import { Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';

import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { QuestionStatus } from 'src/chapters/const/question-status.enum';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { AnswerDraftModel } from '../entities/answer-draft.entity';
import { AnswerFollowupModel } from '../entities/answer-followup.entity';
import { AnswerModel } from '../entities/answer.entity';
import { InputMode, PolishStatus } from '../const/answer.enum';

export type CommitInput = {
  question: UserQuestionModel;
  draft: AnswerDraftModel;
  followupAnswerText: string;
  followupInputMode: InputMode;
  followupSpokenSeconds: number | null;
  polishedText: string;
};

/**
 * 확정 저장 — 원문 둘과 윤문 결과를 함께 남기고 진행 상태를 옮긴다.
 *
 * 한 트랜잭션이어야 하는 이유: 답변만 저장되고 장 진행이 안 옮겨지면
 * 같은 질문이 계속 "지금 답할 질문"으로 나온다.
 */
@Injectable()
export class AnswersTransactionService {
  constructor(private readonly dataSource: DataSource) {}

  async commitAnswer(
    input: CommitInput,
  ): Promise<{ chapterCompleted: boolean }> {
    return await this.dataSource.transaction(async (manager) => {
      const { question, draft } = input;

      const answer = await manager.save(
        manager.create(AnswerModel, {
          userQuestion: { id: question.id } as UserQuestionModel,
          questionText: question.text,
          firstText: draft.firstText,
          firstInputMode: draft.firstInputMode,
          firstSpokenSeconds: draft.firstSpokenSeconds,
          polishedText: input.polishedText,
          polishStatus: PolishStatus.OK,
          polishAttempts: 1,
        }),
      );

      await manager.save(
        manager.create(AnswerFollowupModel, {
          answer,
          seq: 1,
          questionText: draft.followupQuestionText ?? '',
          answerText: input.followupAnswerText,
          inputMode: input.followupInputMode,
          spokenSeconds: input.followupSpokenSeconds,
        }),
      );

      await manager.delete(AnswerDraftModel, {
        userQuestion: { id: question.id },
      });

      await manager.update(
        UserQuestionModel,
        { id: question.id },
        { status: QuestionStatus.ANSWERED, answeredAt: new Date() },
      );

      return await this.advanceChapter(manager, question.userChapter.id);
    });
  }

  /** 건너뛰기 — 답변 없이 완료 처리한다. 장이 끝나야 하므로 개수에는 넣는다 */
  async skipQuestion(
    question: UserQuestionModel,
  ): Promise<{ chapterCompleted: boolean }> {
    return await this.dataSource.transaction(async (manager) => {
      await manager.delete(AnswerDraftModel, {
        userQuestion: { id: question.id },
      });
      await manager.update(
        UserQuestionModel,
        { id: question.id },
        { status: QuestionStatus.SKIPPED, answeredAt: new Date() },
      );

      return await this.advanceChapter(manager, question.userChapter.id);
    });
  }

  /**
   * 장의 진행을 한 칸 옮긴다. 다 찼으면 done으로 닫고 **다음 장 하나만** 연다.
   */
  private async advanceChapter(
    manager: EntityManager,
    chapterId: string,
  ): Promise<{ chapterCompleted: boolean }> {
    const chapter = await manager.findOne(UserChapterModel, {
      where: { id: chapterId },
      relations: { user: true },
    });
    if (!chapter) {
      return { chapterCompleted: false };
    }

    const remaining = await manager.count(UserQuestionModel, {
      where: {
        userChapter: { id: chapterId },
        status: QuestionStatus.PENDING,
      },
    });
    const answered = chapter.questionCount - remaining;

    if (remaining > 0) {
      await manager.update(
        UserChapterModel,
        { id: chapterId },
        { answeredCount: answered },
      );
      return { chapterCompleted: false };
    }

    await manager.update(
      UserChapterModel,
      { id: chapterId },
      {
        answeredCount: answered,
        status: ChapterStatus.DONE,
        completedAt: new Date(),
      },
    );

    const next = await manager
      .createQueryBuilder(UserChapterModel, 'c')
      .where('c.user_id = :userId', { userId: chapter.user.id })
      .andWhere('c.sort_order > :order', { order: chapter.sortOrder })
      .orderBy('c.sort_order', 'ASC')
      .getOne();

    if (next) {
      await manager.update(
        UserChapterModel,
        { id: next.id },
        { status: ChapterStatus.WRITING },
      );
    }

    return { chapterCompleted: true };
  }
}
