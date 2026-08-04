import { Injectable } from '@nestjs/common';

import { ChapterResponseDto } from 'src/chapters/dto/response/chapter-response.dto';
import { UsersService } from 'src/users/services/users.service';
import { IntroAnswerItemDto } from '../dto/request/submit-intro-answers.dto';
import { GenerateTocResponseDto } from '../dto/response/generate-toc-response.dto';
import { IntroProfileResponseDto } from '../dto/response/intro-profile-response.dto';
import { IntroQuestionResponseDto } from '../dto/response/intro-question-response.dto';
import { IntroRepository } from '../repositories/intro.repository';
import { IntroTransactionService } from './intro-transaction.service';

const PROFILE_LABELS: Record<string, string> = {
  i2: '성별',
  i6: '생년월일',
  i3: '결혼',
  i4: '자녀',
  i5: '학력',
};

@Injectable()
export class IntroService {
  constructor(
    private readonly introRepository: IntroRepository,
    private readonly introTransactionService: IntroTransactionService,
    private readonly usersService: UsersService,
  ) {}

  async getQuestions(): Promise<IntroQuestionResponseDto[]> {
    const questions = await this.introRepository.findActiveQuestions();
    const trees = await this.introRepository.findChoiceTreeByQuestionIds(
      questions.map((q) => q.id),
    );

    return questions.map((q) =>
      IntroQuestionResponseDto.from(q, trees.get(q.id) ?? []),
    );
  }

  async getWritingPlan(userId: string) {
    const plan = await this.introRepository.findWritingPlan(userId);
    const recommended = recommendWeeks(plan);
    return {
      recommended_weeks: recommended,
      plan: plan
        ? {
            daily_minutes: plan.dailyMinutes,
            available_weekdays: plan.availableWeekdays,
            available_periods: plan.availablePeriods,
            duration_weeks: plan.durationWeeks,
            duration_source: plan.durationSource,
            alarm_enabled: plan.alarmEnabled,
          }
        : null,
    };
  }

  async putWritingPlan(
    userId: string,
    body: {
      daily_minutes: number;
      available_weekdays: number[];
      available_periods: string[];
      duration_weeks: number;
      duration_source: string;
      alarm_enabled: boolean;
    },
  ) {
    const plan = await this.introRepository.upsertWritingPlan({
      userId,
      dailyMinutes: body.daily_minutes,
      availableWeekdays: body.available_weekdays,
      availablePeriods: body.available_periods,
      durationWeeks: body.duration_weeks,
      durationSource: body.duration_source,
      alarmEnabled: body.alarm_enabled,
    });
    return {
      recommended_weeks: recommendWeeks(plan),
      plan: {
        daily_minutes: plan.dailyMinutes,
        available_weekdays: plan.availableWeekdays,
        available_periods: plan.availablePeriods,
        duration_weeks: plan.durationWeeks,
        duration_source: plan.durationSource,
        alarm_enabled: plan.alarmEnabled,
      },
    };
  }

  async submitAnswers(
    userId: string,
    answers: IntroAnswerItemDto[],
  ): Promise<GenerateTocResponseDto> {
    const user = await this.usersService.getOrThrow(userId);

    const { caseDefinition, book, chapters } =
      await this.introTransactionService.submitAndGenerateToc(
        user,
        answers.map((a) => ({
          questionCode: a.question_id,
          value: a.value,
          skipped: a.skipped,
          choiceId: a.choice_id,
          detailChoiceId: a.detail_choice_id,
          detailValue: a.detail_value,
        })),
      );

    return {
      case_key: caseDefinition.caseKey,
      book_id: book.id,
      chapters: chapters.map((c) => ChapterResponseDto.from(c)),
    };
  }

  async confirmToc(
    userId: string,
    bookId: string,
    chapterIds: string[],
  ): Promise<{
    book_id: string;
    first_question_id: string | null;
    chapters: ChapterResponseDto[];
  }> {
    const result = await this.introTransactionService.confirmToc(
      userId,
      bookId,
      chapterIds,
    );

    return {
      book_id: result.bookId,
      first_question_id: result.firstQuestionId,
      chapters: result.chapters.map((c) => ChapterResponseDto.from(c)),
    };
  }

  async saveTocDraft(
    userId: string,
    bookId: string,
    chapters: Array<{
      id?: string;
      template_id?: string;
      title?: string;
    }>,
  ): Promise<{ chapters: ChapterResponseDto[] }> {
    const saved = await this.introTransactionService.saveTocDraft(
      userId,
      bookId,
      chapters.map((c) => ({
        id: c.id,
        templateId: c.template_id,
        title: c.title,
      })),
    );

    return {
      chapters: saved.map((c) => ChapterResponseDto.from(c)),
    };
  }

  async getProfile(userId: string): Promise<IntroProfileResponseDto> {
    const answers = await this.introRepository.findAnswersByUser(userId);

    return {
      entries: answers
        .filter((a) => PROFILE_LABELS[a.introQuestion.code])
        .map((a) => ({
          label: PROFILE_LABELS[a.introQuestion.code],
          value: a.isSkipped ? null : a.valueText || null,
          skipped: a.isSkipped,
        })),
    };
  }
}

/** 임시 추천 — 하루 시간이 많을수록 짧은 기간 */
function recommendWeeks(plan: {
  dailyMinutes?: number;
  availableWeekdays?: number[];
} | null): number {
  const minutes = plan?.dailyMinutes ?? 30;
  const days = plan?.availableWeekdays?.length ?? 3;
  if (minutes >= 90 && days >= 4) return 1;
  if (minutes >= 60) return 2;
  if (minutes >= 30) return 4;
  return 6;
}
