import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * 꼬리질문 생성·윤문.
 *
 * 지금은 **스텁**이다 — 실제 모델을 부르지 않고 형태만 맞춘 글을 돌려준다.
 * 제공자가 정해지면 이 클래스만 갈아 끼운다. 프롬프트는 코드가 아니라
 * prompt_template 표에 있다(api-spec §9.1).
 *
 * 실패는 **던져서** 알린다. 부르는 쪽이 FOLLOWUP_FAILED / POLISH_FAILED로
 * 나눠 처리한다 — 두 실패는 사용자에게 시키는 일이 다르다.
 */
@Injectable()
export class AiService {
  private readonly logger = new Logger('Ai');

  constructor(private readonly configService: ConfigService) {}

  get isStub(): boolean {
    return this.configService.get<string>('AI_PROVIDER', 'stub') === 'stub';
  }

  get model(): string {
    return this.isStub
      ? 'stub'
      : this.configService.get<string>('AI_MODEL', 'unknown');
  }

  /** 요약 + 공감 + 질문이 한 덩어리로 온다. 빈 줄이 요약·공감과 질문을 가른다 */
  generateFollowup(input: {
    chapterTitle: string;
    question: string;
    answer: string;
  }): Promise<string> {
    if (!this.isStub) {
      throw new Error('AI 제공자가 아직 연결되지 않았습니다');
    }

    this.logger.log(`[stub] 꼬리질문 생성 · ${input.chapterTitle}`);

    return Promise.resolve(
      [
        '말씀해 주신 장면이 눈에 그려집니다.',
        '그 시간이 지금까지도 마음에 남아 계신 것 같아요.',
        '',
        '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요?',
      ].join('\n'),
    );
  }

  /** 1인칭 회고체 산문. 문단 사이는 빈 줄로 가른다 */
  polish(input: {
    question: string;
    answer: string;
    followupQuestion: string;
    followupAnswer: string;
  }): Promise<string> {
    if (!this.isStub) {
      throw new Error('AI 제공자가 아직 연결되지 않았습니다');
    }

    this.logger.log('[stub] 윤문');

    // 스텁은 지어내지 않는다 — 사용자가 답한 원문을 문단으로 잇기만 한다.
    return Promise.resolve(
      [input.answer, input.followupAnswer]
        .map((part) => part.trim())
        .filter((part) => part.length > 0)
        .join('\n\n'),
    );
  }

  /** 챕터 답변들을 자서전 원고로 종합 (§9.2) */
  synthesizeChapter(input: {
    chapterTitle: string;
    answers: string[];
  }): Promise<string> {
    if (!this.isStub) {
      throw new Error('AI 제공자가 아직 연결되지 않았습니다');
    }

    this.logger.log(`[stub] 종합 · ${input.chapterTitle}`);

    const parts = input.answers
      .map((a) => a.trim())
      .filter((a) => a.length > 0);

    if (parts.length === 0) {
      return Promise.resolve(
        `${input.chapterTitle}의 이야기를 모아 두고 있어요.\n\n아직 담긴 답이 없습니다.`,
      );
    }

    return Promise.resolve(parts.join('\n\n'));
  }
}
