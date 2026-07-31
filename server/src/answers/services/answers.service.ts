import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';

import { AiService } from 'src/ai/services/ai.service';
import { ChaptersService } from 'src/chapters/services/chapters.service';
import { QuestionResponseDto } from 'src/chapters/dto/response/question-response.dto';
import { QuestionStatus } from 'src/chapters/const/question-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { DraftPhase, InputMode } from '../const/answer.enum';
import { AdvanceResponseDto } from '../dto/response/advance-response.dto';
import { SubmitAnswerResponseDto } from '../dto/response/followup-response.dto';
import { AnswersRepository } from '../repositories/answers.repository';
import { AnswersTransactionService } from './answers-transaction.service';

/** AI 호출은 서버 안에서 이만큼 다시 시도한 뒤 실패로 판정한다 */
const AI_MAX_ATTEMPTS = 2;

@Injectable()
export class AnswersService {
  private readonly logger = new Logger('Answers');

  constructor(
    private readonly answersRepository: AnswersRepository,
    private readonly answersTransactionService: AnswersTransactionService,
    private readonly chaptersService: ChaptersService,
    private readonly aiService: AiService,
  ) {}

  async findSavedAnswerText(questionId: string): Promise<string | null> {
    const answer =
      await this.answersRepository.findAnswerByQuestion(questionId);

    // 사용자에게 보이는 건 **자기가 답한 원문**이다. 윤문 결과가 아니다.
    return answer?.firstText ?? null;
  }

  /**
   * 1차 답변 → 꼬리질문 (api-spec §5.1).
   *
   * 아직 확정이 아니다. 초안으로만 들고 있다가 꼬리답변까지 받아야 저장한다.
   */
  async submitFirstAnswer(
    userId: string,
    questionId: string,
    input: { text: string; inputMode: InputMode; spokenSeconds: number | null },
  ): Promise<SubmitAnswerResponseDto> {
    const question = await this.chaptersService.getOwnedQuestion(
      userId,
      questionId,
    );
    if (question.status !== QuestionStatus.PENDING) {
      throw new ApiException(ERROR_CODE.WRITE.ALREADY_ANSWERED);
    }

    const followupId = randomUUID();
    let followupText: string;
    try {
      followupText = await this.callWithRetry(() =>
        this.aiService.generateFollowup({
          chapterTitle: question.userChapter.title,
          question: question.text,
          answer: input.text,
        }),
      );
    } catch {
      this.logger.warn(`꼬리질문 생성 실패 · question=${questionId}`);
      // ⚠️ 초안을 남기지 않는다. 화면에 없는 글을 서버가 들고 있으면
      //    사용자가 다시 답한 내용과 어긋난다(api-spec §5.3).
      await this.answersRepository.deleteDraft(questionId);
      throw new ApiException(ERROR_CODE.WRITE.FOLLOWUP_FAILED);
    }

    // 다시 답할 수도 있으므로 초안은 질문당 하나로 덮어쓴다.
    await this.answersRepository.deleteDraft(questionId);
    await this.answersRepository.saveDraft({
      userQuestion: question,
      phase: DraftPhase.FOLLOWUP,
      firstText: input.text,
      firstInputMode: input.inputMode,
      firstSpokenSeconds: input.spokenSeconds,
      followupQuestionText: followupText,
      followupId,
    });

    return { followup: { id: followupId, text: followupText } };
  }

  /**
   * 꼬리답변 → 확정 저장 (api-spec §5.2).
   *
   * 윤문에 실패하면 **초안을 남긴 채** 던진다. 앱이 같은 요청을 다시 보내면
   * 그대로 이어서 저장된다 — 두 번 답한 이야기를 날리지 않는다.
   */
  async submitFollowupAnswer(
    userId: string,
    questionId: string,
    followupId: string,
    input: { text: string; inputMode: InputMode; spokenSeconds: number | null },
  ): Promise<AdvanceResponseDto> {
    const question = await this.chaptersService.getOwnedQuestion(
      userId,
      questionId,
    );

    const draft = await this.answersRepository.findDraftByQuestion(questionId);
    if (!draft || draft.followupId !== followupId) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    let polished: string;
    try {
      polished = await this.callWithRetry(() =>
        this.aiService.polish({
          question: question.text,
          answer: draft.firstText,
          followupQuestion: draft.followupQuestionText ?? '',
          followupAnswer: input.text,
        }),
      );
    } catch {
      this.logger.warn(`윤문 실패 · question=${questionId}`);
      throw new ApiException(ERROR_CODE.WRITE.POLISH_FAILED);
    }

    const { chapterCompleted } =
      await this.answersTransactionService.commitAnswer({
        question,
        draft,
        followupAnswerText: input.text,
        followupInputMode: input.inputMode,
        followupSpokenSeconds: input.spokenSeconds,
        polishedText: polished,
      });

    return await this.buildAdvance(userId, chapterCompleted);
  }

  async skipQuestion(
    userId: string,
    questionId: string,
  ): Promise<AdvanceResponseDto> {
    const question = await this.chaptersService.getOwnedQuestion(
      userId,
      questionId,
    );
    if (question.status !== QuestionStatus.PENDING) {
      throw new ApiException(ERROR_CODE.WRITE.ALREADY_ANSWERED);
    }

    const { chapterCompleted } =
      await this.answersTransactionService.skipQuestion(question);

    return await this.buildAdvance(userId, chapterCompleted);
  }

  private async buildAdvance(
    userId: string,
    chapterCompleted: boolean,
  ): Promise<AdvanceResponseDto> {
    const next = await this.chaptersService.getCurrentQuestion(userId);

    return {
      next_question: next ? QuestionResponseDto.from(next) : null,
      chapter_completed: chapterCompleted,
    };
  }

  /** 한 번 실패했다고 바로 포기하지 않는다. 모델 호출은 산발적으로 흔들린다 */
  private async callWithRetry<T>(call: () => Promise<T>): Promise<T> {
    let lastError: unknown;

    for (let attempt = 1; attempt <= AI_MAX_ATTEMPTS; attempt++) {
      try {
        return await call();
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError;
  }
}
