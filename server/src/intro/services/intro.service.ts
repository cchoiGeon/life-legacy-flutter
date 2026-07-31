import { Injectable } from '@nestjs/common';

import { ChapterResponseDto } from 'src/chapters/dto/response/chapter-response.dto';
import { UsersService } from 'src/users/services/users.service';
import { IntroAnswerItemDto } from '../dto/request/submit-intro-answers.dto';
import { GenerateTocResponseDto } from '../dto/response/generate-toc-response.dto';
import { IntroProfileResponseDto } from '../dto/response/intro-profile-response.dto';
import { IntroQuestionResponseDto } from '../dto/response/intro-question-response.dto';
import { IntroRepository } from '../repositories/intro.repository';
import { IntroTransactionService } from './intro-transaction.service';

/** F3(내 정보)에 뜨는 라벨. 성함(i1)은 화면 상단에 이미 있어 뺀다 */
const PROFILE_LABELS: Record<string, string> = {
  i2: '성별',
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
    const choices = await this.introRepository.findChoiceLabelsByQuestionIds(
      questions.map((q) => q.id),
    );

    const byQuestion = new Map<string, string[]>();
    for (const choice of choices) {
      byQuestion.set(choice.questionId, [
        ...(byQuestion.get(choice.questionId) ?? []),
        choice.label,
      ]);
    }

    return questions.map((q) =>
      IntroQuestionResponseDto.from(q, byQuestion.get(q.id) ?? []),
    );
  }

  async submitAnswers(
    userId: string,
    answers: IntroAnswerItemDto[],
  ): Promise<GenerateTocResponseDto> {
    const user = await this.usersService.getOrThrow(userId);

    const { caseDefinition, chapters } =
      await this.introTransactionService.submitAndGenerateToc(
        user,
        answers.map((a) => ({ questionCode: a.question_id, value: a.value })),
      );

    return {
      case_key: caseDefinition.caseKey,
      chapters: chapters.map((c) => ChapterResponseDto.from(c)),
    };
  }

  async confirmToc(userId: string, chapterIds: string[]): Promise<void> {
    await this.introTransactionService.confirmToc(userId, chapterIds);
  }

  async getProfile(userId: string): Promise<IntroProfileResponseDto> {
    const answers = await this.introRepository.findAnswersByUser(userId);

    return {
      entries: answers
        .filter((a) => PROFILE_LABELS[a.introQuestion.code])
        .map((a) => ({
          label: PROFILE_LABELS[a.introQuestion.code],
          value: a.valueText,
        })),
    };
  }
}
