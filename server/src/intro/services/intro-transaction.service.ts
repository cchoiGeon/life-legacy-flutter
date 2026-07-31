import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { ChapterTemplateModel } from 'src/catalog/entities/chapter-template.entity';
import { QuestionTemplateModel } from 'src/catalog/entities/question-template.entity';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { ConditionAxis } from 'src/common/const/condition-axis.enum';
import { CaseAxes, isChapterIncluded } from '../const/case-axes';
import { CaseDefinitionModel } from '../entities/case-definition.entity';
import { IntroChoiceModel } from '../entities/intro-choice.entity';
import { IntroQuestionModel } from '../entities/intro-question.entity';
import { UserIntroAnswerModel } from '../entities/user-intro-answer.entity';
import { UserProfileModel } from '../entities/user-profile.entity';

export type SubmittedAnswer = { questionCode: string; value: string };

/**
 * 자기소개 제출 → 목차 생성은 **한 트랜잭션**이다.
 *
 * 답변만 저장되고 목차가 안 만들어지면 사용자는 자기소개를 다시 할 수도,
 * 목차를 받을 수도 없는 상태에 갇힌다.
 */
@Injectable()
export class IntroTransactionService {
  constructor(private readonly dataSource: DataSource) {}

  async submitAndGenerateToc(
    user: AppUserModel,
    submitted: SubmittedAnswer[],
  ): Promise<{
    caseDefinition: CaseDefinitionModel;
    chapters: UserChapterModel[];
  }> {
    return await this.dataSource.transaction(async (manager) => {
      const questions = await manager.find(IntroQuestionModel, {
        where: { isActive: true },
        order: { sortOrder: 'ASC' },
      });
      const byCode = new Map(questions.map((q) => [q.code, q]));

      // 다섯 문항이 다 오지 않으면 축을 못 가른다.
      const missing = questions.filter(
        (q) => !submitted.some((s) => s.questionCode === q.code),
      );
      if (missing.length > 0) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }

      const axes: CaseAxes = {
        hasCollege: false,
        hasMarriage: false,
        hasChildren: false,
      };
      let displayName = '';
      let gender: string | null = null;
      let educationLevel = '';

      for (const item of submitted) {
        const question = byCode.get(item.questionCode);
        if (!question) {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }

        const choice = await manager.findOne(IntroChoiceModel, {
          where: { introQuestion: { id: question.id }, label: item.value },
        });

        // 원본 문자열을 그대로 남긴다 — 판정용으로 접지 않는다.
        await manager.upsert(
          UserIntroAnswerModel,
          {
            user: { id: user.id },
            introQuestion: { id: question.id },
            introChoice: choice ? { id: choice.id } : null,
            valueText: item.value,
          },
          ['user', 'introQuestion'],
        );

        applyAxis(axes, question, choice);

        if (question.code === 'i1') displayName = item.value;
        if (question.code === 'i2') gender = item.value;
        if (question.code === 'i5') educationLevel = item.value;
      }

      const caseDefinition = await manager.findOne(CaseDefinitionModel, {
        where: {
          hasCollege: axes.hasCollege,
          hasMarriage: axes.hasMarriage,
          hasChildren: axes.hasChildren,
        },
      });
      if (!caseDefinition) {
        // 케이스 8종은 축 조합을 모두 덮는다. 여기 오면 시드가 빠진 것이다.
        throw new ApiException(ERROR_CODE.COMMON.SERVER_ERROR);
      }

      await manager.upsert(
        UserProfileModel,
        {
          userId: user.id,
          case: { id: caseDefinition.id },
          displayName,
          gender,
          educationLevel,
          ...axes,
        },
        ['userId'],
      );

      if (displayName) {
        await manager.update(
          AppUserModel,
          { id: user.id },
          { name: displayName },
        );
      }

      // 다시 제출하면 이전 목차를 버리고 새로 만든다. 축이 바뀌었는데 옛
      // 목차가 남아 있으면 있을 수 없는 장이 섞인다.
      await manager.delete(UserChapterModel, { user: { id: user.id } });

      const templates = await manager.find(ChapterTemplateModel, {
        where: { isActive: true },
        order: { sortOrder: 'ASC' },
      });
      const included = templates.filter((t) =>
        isChapterIncluded(t.condition, axes),
      );

      const chapters: UserChapterModel[] = [];
      for (const [index, template] of included.entries()) {
        const questionTemplates = await manager.find(QuestionTemplateModel, {
          where: { chapterTemplate: { id: template.id }, isActive: true },
          order: { sortOrder: 'ASC' },
        });

        const chapter = await manager.save(
          manager.create(UserChapterModel, {
            user: { id: user.id } as AppUserModel,
            chapterTemplate: template,
            sortOrder: index + 1,
            title: template.title,
            // 1번 장만 열어 둔다. 나머지는 앞 장을 끝내야 열린다.
            status: index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED,
            questionCount: questionTemplates.length,
            answeredCount: 0,
          }),
        );

        for (const [order, questionTemplate] of questionTemplates.entries()) {
          await manager.save(
            manager.create(UserQuestionModel, {
              userChapter: chapter,
              questionTemplate,
              sortOrder: order + 1,
              text: questionTemplate.text,
            }),
          );
        }

        chapters.push(chapter);
      }

      return { caseDefinition, chapters };
    });
  }

  /**
   * 목차 확정 — 앱이 보낸 순서 그대로 order를 다시 매기고 상태를 초기화한다.
   */
  async confirmToc(userId: string, chapterIds: string[]): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const profile = await manager.findOne(UserProfileModel, {
        where: { userId },
      });
      if (!profile) {
        throw new ApiException(ERROR_CODE.INTRO.INTRO_REQUIRED);
      }
      if (profile.tocConfirmedAt) {
        throw new ApiException(ERROR_CODE.INTRO.TOC_ALREADY_CONFIRMED);
      }

      const chapters = await manager.find(UserChapterModel, {
        where: { user: { id: userId } },
      });
      const byId = new Map(chapters.map((c) => [c.id, c]));

      // 보낸 목록이 내 목차와 정확히 일치해야 한다. 하나라도 빠지거나
      // 남의 장이 섞이면 순서를 신뢰할 수 없다.
      const sameSet =
        chapterIds.length === chapters.length &&
        chapterIds.every((id) => byId.has(id));
      if (!sameSet) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }

      // ⚠️ 두 번에 나눠 쓴다. sortOrder에 (user, sortOrder) 유니크가 걸려
      //    있어서 곧바로 1..N을 쓰면 중간에 충돌한다. 먼저 음수로 밀어 둔다.
      for (const [index, id] of chapterIds.entries()) {
        await manager.update(
          UserChapterModel,
          { id },
          { sortOrder: -(index + 1) },
        );
      }
      for (const [index, id] of chapterIds.entries()) {
        await manager.update(
          UserChapterModel,
          { id },
          {
            sortOrder: index + 1,
            status: index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED,
          },
        );
      }

      const now = new Date();
      await manager.update(
        UserProfileModel,
        { userId },
        { tocConfirmedAt: now },
      );
      await manager.update(
        AppUserModel,
        { id: userId },
        { introCompletedAt: now },
      );
    });
  }
}

function applyAxis(
  axes: CaseAxes,
  question: IntroQuestionModel,
  choice: IntroChoiceModel | null,
): void {
  if (!choice || choice.axisValue === null) {
    return;
  }

  if (question.axis === ConditionAxis.COLLEGE)
    axes.hasCollege = choice.axisValue;
  if (question.axis === ConditionAxis.MARRIAGE)
    axes.hasMarriage = choice.axisValue;
  if (question.axis === ConditionAxis.CHILDREN)
    axes.hasChildren = choice.axisValue;
}
