import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
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

type DraftFollowup = {
  seq: number;
  question: string;
  answer: string;
  input_mode: string;
  spoken_seconds: number | null;
};

@Injectable()
export class AnswersService {
  private readonly logger = new Logger('Answers');

  constructor(
    private readonly answersRepository: AnswersRepository,
    private readonly answersTransactionService: AnswersTransactionService,
    private readonly chaptersService: ChaptersService,
    private readonly aiService: AiService,
    private readonly config: ConfigService,
  ) {}

  /** 꼬리질문 최대 회차 (기본 2 → 총 답변 3회) */
  private get maxFollowupRounds(): number {
    const raw = this.config.get<string>('FOLLOWUP_MAX_ROUNDS', '2');
    const n = Number(raw);
    return Number.isFinite(n) && n >= 1 ? Math.floor(n) : 2;
  }

  async findSavedAnswerText(questionId: string): Promise<string | null> {
    const answer =
      await this.answersRepository.findAnswerByQuestion(questionId);
    return answer?.firstText ?? null;
  }

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
          mainQuestion: question.text,
          mainAnswer: input.text,
          followups: [],
        }),
      );
    } catch {
      this.logger.warn(`꼬리질문 생성 실패 · question=${questionId}`);
      await this.answersRepository.deleteDraft(questionId);
      throw new ApiException(ERROR_CODE.WRITE.FOLLOWUP_FAILED);
    }

    await this.answersRepository.deleteDraft(questionId);
    await this.answersRepository.saveDraft({
      userQuestion: question,
      phase: DraftPhase.FOLLOWUP,
      firstText: input.text,
      firstInputMode: input.inputMode,
      firstSpokenSeconds: input.spokenSeconds,
      followupRound: 1,
      followups: [],
      followupQuestionText: followupText,
      followupId,
    });

    return { followup: { id: followupId, seq: 1, text: followupText } };
  }

  /**
   * 꼬리답변 — 아직 회차가 남으면 followup, 마지막이면 윤문·확정.
   * 앱은 followup 유무만으로 분기한다 (api-spec §5.2).
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

    const currentSeq = draft.followupRound || 1;
    const completed: DraftFollowup[] = [...(draft.followups ?? [])];
    completed.push({
      seq: currentSeq,
      question: draft.followupQuestionText ?? '',
      answer: input.text,
      input_mode: input.inputMode,
      spoken_seconds: input.spokenSeconds,
    });

    const maxRounds = this.maxFollowupRounds;
    if (currentSeq < maxRounds) {
      const nextId = randomUUID();
      const nextSeq = currentSeq + 1;
      let nextText: string;
      try {
        // lifelegacy와 동일: 원 질문·원 답 고정 + 지금까지 꼬리 Q&A를 history로
        nextText = await this.callWithRetry(() =>
          this.aiService.generateFollowup({
            chapterTitle: question.userChapter.title,
            mainQuestion: question.text,
            mainAnswer: draft.firstText,
            followups: completed.map((f) => ({
              question: f.question,
              answer: f.answer,
            })),
          }),
        );
      } catch {
        this.logger.warn(
          `중간 꼬리질문 생성 실패 · question=${questionId} seq=${nextSeq}`,
        );
        throw new ApiException(ERROR_CODE.WRITE.FOLLOWUP_FAILED);
      }

      draft.followups = completed;
      draft.followupRound = nextSeq;
      draft.followupId = nextId;
      draft.followupQuestionText = nextText;
      draft.phase = DraftPhase.FOLLOWUP;
      await this.answersRepository.saveDraft(draft);

      return {
        followup: { id: nextId, seq: nextSeq, text: nextText },
        next_question: null,
        chapter_completed: false,
      };
    }

    let polished: string;
    try {
      polished = await this.callWithRetry(() =>
        this.aiService.polish({
          mainQuestion: question.text,
          mainAnswer: draft.firstText,
          followups: completed.map((f) => ({
            question: f.question,
            answer: f.answer,
          })),
        }),
      );
    } catch {
      this.logger.warn(`윤문 실패 · question=${questionId}`);
      // 마지막 답을 draft에 반영해 두면 재시도 시 같은 페이로드로 확정 가능
      draft.followups = completed;
      await this.answersRepository.saveDraft(draft);
      throw new ApiException(ERROR_CODE.WRITE.POLISH_FAILED);
    }

    const { chapterCompleted } =
      await this.answersTransactionService.commitAnswer({
        question,
        draft,
        followups: completed.map((f) => ({
          seq: f.seq,
          questionText: f.question,
          answerText: f.answer,
          inputMode: f.input_mode as InputMode,
          spokenSeconds: f.spoken_seconds,
        })),
        polishedText: polished,
      });

    return await this.buildAdvance(
      userId,
      question.userChapter.bookId,
      chapterCompleted,
    );
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

    return await this.buildAdvance(
      userId,
      question.userChapter.bookId,
      chapterCompleted,
    );
  }

  async putDraft(
    userId: string,
    questionId: string,
    input: {
      text: string;
      inputMode: InputMode;
      spokenSeconds: number | null;
    },
  ) {
    const question = await this.chaptersService.getOwnedQuestion(
      userId,
      questionId,
    );
    if (question.status !== QuestionStatus.PENDING) {
      throw new ApiException(ERROR_CODE.WRITE.ALREADY_ANSWERED);
    }

    const existing =
      await this.answersRepository.findDraftByQuestion(questionId);
    if (existing?.phase === DraftPhase.FOLLOWUP) {
      return this.toDraftResponse(questionId, existing);
    }

    const draft = await this.answersRepository.upsertFirstPhaseDraft(
      questionId,
      {
        userQuestion: question,
        firstText: input.text,
        firstInputMode: input.inputMode,
        firstSpokenSeconds: input.spokenSeconds,
      },
    );
    return this.toDraftResponse(questionId, draft);
  }

  async getDraft(userId: string, questionId: string) {
    await this.chaptersService.getOwnedQuestion(userId, questionId);
    const draft =
      await this.answersRepository.findDraftByQuestion(questionId);
    if (!draft) return null;
    return this.toDraftResponse(questionId, draft);
  }

  async clearDraft(userId: string, questionId: string): Promise<void> {
    await this.chaptersService.getOwnedQuestion(userId, questionId);
    await this.answersRepository.deleteDraft(questionId);
  }

  private toDraftResponse(
    questionId: string,
    draft: {
      phase: DraftPhase;
      firstText: string;
      firstInputMode: InputMode;
      firstSpokenSeconds: number | null;
      followupRound?: number;
      followupId: string | null;
      followupQuestionText: string | null;
      updatedAt?: Date;
    },
  ) {
    const round =
      draft.phase === DraftPhase.FOLLOWUP ? (draft.followupRound ?? 1) : 0;
    return {
      question_id: questionId,
      phase: draft.phase,
      text: draft.firstText,
      input_mode: draft.firstInputMode,
      spoken_seconds: draft.firstSpokenSeconds,
      followup_round: round,
      pending_followup:
        draft.phase === DraftPhase.FOLLOWUP &&
        draft.followupId &&
        draft.followupQuestionText
          ? {
              id: draft.followupId,
              seq: round,
              text: draft.followupQuestionText,
            }
          : null,
      updated_at: (draft.updatedAt ?? new Date()).toISOString(),
    };
  }

  private async buildAdvance(
    userId: string,
    bookId: string,
    chapterCompleted: boolean,
  ): Promise<AdvanceResponseDto> {
    const next = await this.chaptersService.getCurrentQuestion(userId, bookId);

    return {
      followup: null,
      next_question: next ? QuestionResponseDto.from(next) : null,
      chapter_completed: chapterCompleted,
    };
  }

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
