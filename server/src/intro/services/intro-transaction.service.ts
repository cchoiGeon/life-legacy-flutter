import { Injectable } from '@nestjs/common';
import { DataSource, IsNull } from 'typeorm';

import { BookModel } from 'src/book/entities/book.entity';
import { ChapterSource } from 'src/chapters/const/chapter-source.enum';
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

export type SubmittedAnswer = {
  questionCode: string;
  value?: string;
  skipped?: boolean;
  choiceId?: string;
  detailChoiceId?: string;
  detailValue?: string;
};

/**
 * 자기소개 제출 → 책 생성 → 목차 생성은 **한 트랜잭션**이다.
 */
@Injectable()
export class IntroTransactionService {
  constructor(private readonly dataSource: DataSource) {}

  async submitAndGenerateToc(
    user: AppUserModel,
    submitted: SubmittedAnswer[],
  ): Promise<{
    caseDefinition: CaseDefinitionModel;
    book: BookModel;
    chapters: UserChapterModel[];
  }> {
    return await this.dataSource.transaction(async (manager) => {
      const questions = await manager.find(IntroQuestionModel, {
        where: { isActive: true },
        order: { sortOrder: 'ASC' },
      });
      const byCode = new Map(questions.map((q) => [q.code, q]));

      // skippable 문항이 아니면 반드시 답이 와야 한다
      for (const q of questions) {
        const item = submitted.find((s) => s.questionCode === q.code);
        if (!item) {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }
        // 스킵 불가인데 skipped면 거절 — isSkippable 컬럼 도입 전이면
        // i3·i4만 허용
        if (item.skipped && q.code !== 'i3' && q.code !== 'i4') {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }
      }

      const axes: CaseAxes = {
        hasCollege: false,
        hasMarriage: false,
        hasChildren: false,
      };
      let gender: string | null = null;
      let educationLevel = '';
      let educationDetail: string | null = null;
      let birthDate: string | null = null;

      for (const item of submitted) {
        const question = byCode.get(item.questionCode);
        if (!question) {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }

        if (item.skipped) {
          await manager.upsert(
            UserIntroAnswerModel,
            {
              user: { id: user.id },
              introQuestion: { id: question.id },
              introChoice: null,
              detailChoice: null,
              valueText: '',
              isSkipped: true,
            },
            ['user', 'introQuestion'],
          );
          // 건너뛴 결혼·자녀 → 축 false (장을 넣지 않음)
          if (question.axis === ConditionAxis.MARRIAGE) axes.hasMarriage = false;
          if (question.axis === ConditionAxis.CHILDREN) axes.hasChildren = false;
          continue;
        }

        const value = item.value ?? '';
        const choice = value
          ? await manager.findOne(IntroChoiceModel, {
              where: {
                introQuestion: { id: question.id },
                label: value,
                parentChoice: IsNull(),
              },
            })
          : null;

        let detailChoice: IntroChoiceModel | null = null;
        if (item.detailValue && choice) {
          detailChoice = await manager.findOne(IntroChoiceModel, {
            where: {
              introQuestion: { id: question.id },
              label: item.detailValue,
              parentChoice: { id: choice.id },
            },
          });
        }

        await manager.upsert(
          UserIntroAnswerModel,
          {
            user: { id: user.id },
            introQuestion: { id: question.id },
            introChoice: choice ? { id: choice.id } : null,
            detailChoice: detailChoice ? { id: detailChoice.id } : null,
            valueText: value,
            isSkipped: false,
          },
          ['user', 'introQuestion'],
        );

        applyAxis(axes, question, choice);

        if (question.code === 'i2') gender = value;
        if (question.code === 'i5') {
          educationLevel = value;
          educationDetail = item.detailValue ?? null;
        }
        if (question.code === 'i6') birthDate = value;
      }

      const caseDefinition = await manager.findOne(CaseDefinitionModel, {
        where: {
          hasCollege: axes.hasCollege,
          hasMarriage: axes.hasMarriage,
          hasChildren: axes.hasChildren,
        },
      });
      if (!caseDefinition) {
        throw new ApiException(ERROR_CODE.COMMON.SERVER_ERROR);
      }

      const displayName = user.name?.trim() || '나의 이야기';

      await manager.upsert(
        UserProfileModel,
        {
          userId: user.id,
          case: { id: caseDefinition.id },
          displayName,
          gender,
          birthDate,
          educationLevel: educationLevel || '-',
          educationDetail,
          ...axes,
        },
        ['userId'],
      );

      // 이전 미확정 책을 버리고 새 책을 만든다
      const existingBooks = await manager.find(BookModel, {
        where: { ownerUserId: user.id },
      });
      for (const old of existingBooks) {
        const profile = await manager.findOne(UserProfileModel, {
          where: { userId: user.id },
        });
        if (profile?.tocConfirmedAt) {
          // 이미 확정한 책이 있으면 재생성 금지 — 별도 POST /books 로 새 책을
          throw new ApiException(ERROR_CODE.INTRO.TOC_ALREADY_CONFIRMED);
        }
        await manager.delete(UserChapterModel, { bookId: old.id });
        await manager.delete(BookModel, { id: old.id });
      }

      const book = await manager.save(
        manager.create(BookModel, {
          ownerUserId: user.id,
          title: '나의 이야기',
          authorName: displayName,
        }),
      );

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
            book: { id: book.id } as BookModel,
            bookId: book.id,
            chapterTemplate: template,
            sourceType: ChapterSource.TEMPLATE,
            sortOrder: index + 1,
            title: template.title,
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

      return { caseDefinition, book, chapters };
    });
  }

  async confirmToc(
    userId: string,
    bookId: string,
    chapterIds: string[],
  ): Promise<{
    bookId: string;
    firstQuestionId: string | null;
    chapters: UserChapterModel[];
  }> {
    return await this.dataSource.transaction(async (manager) => {
      const book = await manager.findOne(BookModel, {
        where: { id: bookId, ownerUserId: userId },
      });
      if (!book) {
        throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
      }

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
        where: { bookId },
      });
      const byId = new Map(chapters.map((c) => [c.id, c]));

      const sameSet =
        chapterIds.length === chapters.length &&
        chapterIds.every((id) => byId.has(id));
      if (!sameSet) {
        throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
      }

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

      const ordered = await manager.find(UserChapterModel, {
        where: { bookId },
        order: { sortOrder: 'ASC' },
      });

      const firstChapter = ordered[0];
      let firstQuestionId: string | null = null;
      if (firstChapter) {
        const firstQ = await manager.findOne(UserQuestionModel, {
          where: { userChapter: { id: firstChapter.id } },
          order: { sortOrder: 'ASC' },
        });
        firstQuestionId = firstQ?.id ?? null;
      }

      return { bookId, firstQuestionId, chapters: ordered };
    });
  }

  /**
   * §2.4 목차 초안 — 배열 순서가 곧 순서.
   * 배열에 없는 기존 장은 삭제. 사용자 정의 장은 질문 0개(제품 결정).
   */
  async saveTocDraft(
    userId: string,
    bookId: string,
    items: Array<{ id?: string; templateId?: string; title?: string }>,
  ): Promise<UserChapterModel[]> {
    return await this.dataSource.transaction(async (manager) => {
      const book = await manager.findOne(BookModel, {
        where: { id: bookId, ownerUserId: userId },
      });
      if (!book) {
        throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
      }

      const profile = await manager.findOne(UserProfileModel, {
        where: { userId },
      });
      if (!profile) {
        throw new ApiException(ERROR_CODE.INTRO.INTRO_REQUIRED);
      }
      if (profile.tocConfirmedAt) {
        throw new ApiException(ERROR_CODE.INTRO.TOC_ALREADY_CONFIRMED);
      }

      const existing = await manager.find(UserChapterModel, {
        where: { bookId },
        relations: { chapterTemplate: true },
      });
      const byId = new Map(existing.map((c) => [c.id, c]));
      const keptIds = new Set<string>();
      const ordered: UserChapterModel[] = [];

      for (const [index, item] of items.entries()) {
        const hasId = !!item.id;
        const hasTemplate = !!item.templateId;
        const hasTitleOnly = !!item.title && !hasId && !hasTemplate;
        const kindCount = [hasId, hasTemplate, hasTitleOnly].filter(Boolean)
          .length;
        if (kindCount !== 1) {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }

        if (hasId) {
          const chapter = byId.get(item.id!);
          if (!chapter) {
            throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
          }
          if (item.title?.trim()) {
            chapter.title = item.title.trim();
          }
          chapter.sortOrder = -(index + 1);
          chapter.status =
            index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED;
          await manager.save(chapter);
          keptIds.add(chapter.id);
          ordered.push(chapter);
          continue;
        }

        if (hasTemplate) {
          const template = await manager.findOne(ChapterTemplateModel, {
            where: { id: item.templateId!, isActive: true },
          });
          if (!template) {
            throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
          }
          const already = existing.find(
            (c) => c.chapterTemplate?.id === template.id,
          );
          if (already && !keptIds.has(already.id)) {
            // 이미 있던 템플릿 장을 초안에 다시 넣은 경우 — 유지로 처리
            already.sortOrder = -(index + 1);
            already.status =
              index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED;
            await manager.save(already);
            keptIds.add(already.id);
            ordered.push(already);
            continue;
          }

          const questionTemplates = await manager.find(QuestionTemplateModel, {
            where: { chapterTemplate: { id: template.id }, isActive: true },
            order: { sortOrder: 'ASC' },
          });

          const chapter = await manager.save(
            manager.create(UserChapterModel, {
              book: { id: book.id } as BookModel,
              bookId: book.id,
              chapterTemplate: template,
              sourceType: ChapterSource.TEMPLATE,
              sortOrder: -(index + 1),
              title: template.title,
              status:
                index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED,
              questionCount: questionTemplates.length,
              answeredCount: 0,
            }),
          );

          for (const [order, qt] of questionTemplates.entries()) {
            await manager.save(
              manager.create(UserQuestionModel, {
                userChapter: chapter,
                questionTemplate: qt,
                sortOrder: order + 1,
                text: qt.text,
              }),
            );
          }

          keptIds.add(chapter.id);
          ordered.push(chapter);
          continue;
        }

        // 사용자 정의 — 질문 없음 (2026-08-04 결정)
        const title = item.title!.trim();
        if (!title) {
          throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
        }
        const chapter = await manager.save(
          manager.create(UserChapterModel, {
            book: { id: book.id } as BookModel,
            bookId: book.id,
            chapterTemplate: null,
            sourceType: ChapterSource.CUSTOM,
            sortOrder: -(index + 1),
            title,
            status: index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED,
            questionCount: 0,
            answeredCount: 0,
          }),
        );
        keptIds.add(chapter.id);
        ordered.push(chapter);
      }

      for (const old of existing) {
        if (!keptIds.has(old.id)) {
          await manager.delete(UserQuestionModel, {
            userChapter: { id: old.id },
          });
          await manager.delete(UserChapterModel, { id: old.id });
        }
      }

      for (const [index, chapter] of ordered.entries()) {
        await manager.update(
          UserChapterModel,
          { id: chapter.id },
          {
            sortOrder: index + 1,
            status:
              index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED,
          },
        );
        chapter.sortOrder = index + 1;
        chapter.status =
          index === 0 ? ChapterStatus.WRITING : ChapterStatus.LOCKED;
      }

      return ordered;
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
