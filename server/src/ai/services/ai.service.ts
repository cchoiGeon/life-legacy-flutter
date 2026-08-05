import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { firstValueFrom } from 'rxjs';
import { Repository } from 'typeorm';

import { PromptTemplateModel } from '../entities/prompt-template.entity';
import { PROMPT_SEED } from '../seed/prompt.seed';

/**
 * 꼬리질문 생성·윤문·챕터 종합.
 *
 * `AI_PROVIDER=stub`(기본)이면 형태만 맞춘 고정 글을 돌려준다.
 * `AI_PROVIDER=openrouter`이면 OpenRouter chat completions를 호출한다.
 * 프롬프트는 `prompt_template` 표(없으면 시드 문구)를 쓴다.
 */
@Injectable()
export class AiService {
  private readonly logger = new Logger('Ai');

  constructor(
    private readonly configService: ConfigService,
    private readonly httpService: HttpService,
    @InjectRepository(PromptTemplateModel)
    private readonly prompts: Repository<PromptTemplateModel>,
  ) {}

  get isStub(): boolean {
    return this.configService.get<string>('AI_PROVIDER', 'stub') === 'stub';
  }

  get model(): string {
    return this.isStub
      ? 'stub'
      : this.configService.get<string>(
          'AI_MODEL',
          'openai/gpt-4o-mini',
        );
  }

  /** 요약 + 공감 + 질문이 한 덩어리로 온다. 빈 줄이 요약·공감과 질문을 가른다 */
  async generateFollowup(input: {
    chapterTitle: string;
    question: string;
    answer: string;
  }): Promise<string> {
    if (this.isStub) {
      this.logger.log(`[stub] 꼬리질문 생성 · ${input.chapterTitle}`);
      return [
        '말씀해 주신 장면이 눈에 그려집니다.',
        '그 시간이 지금까지도 마음에 남아 계신 것 같아요.',
        '',
        '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요?',
      ].join('\n');
    }

    const prompt = await this.renderPrompt('followup', {
      chapter_title: input.chapterTitle,
      question: input.question,
      answer: input.answer,
    });
    return this.chat(prompt, { maxTokens: 400, temperature: 0.7 });
  }

  /** 1인칭 회고체 산문. 문단 사이는 빈 줄로 가른다 */
  async polish(input: {
    question: string;
    answer: string;
    followupQuestion: string;
    followupAnswer: string;
  }): Promise<string> {
    if (this.isStub) {
      this.logger.log('[stub] 윤문');
      return [input.answer, input.followupAnswer]
        .map((part) => part.trim())
        .filter((part) => part.length > 0)
        .join('\n\n');
    }

    const prompt = await this.renderPrompt('polish', {
      question: input.question,
      answer: input.answer,
      followup_question: input.followupQuestion,
      followup_answer: input.followupAnswer,
    });
    return this.chat(prompt, { maxTokens: 1200, temperature: 0.5 });
  }

  /** 챕터 답변들을 자서전 원고로 종합 (§9.2) */
  async synthesizeChapter(input: {
    chapterTitle: string;
    answers: string[];
  }): Promise<string> {
    const parts = input.answers
      .map((a) => a.trim())
      .filter((a) => a.length > 0);

    if (this.isStub) {
      this.logger.log(`[stub] 종합 · ${input.chapterTitle}`);
      if (parts.length === 0) {
        return `${input.chapterTitle}의 이야기를 모아 두고 있어요.\n\n아직 담긴 답이 없습니다.`;
      }
      return parts.join('\n\n');
    }

    if (parts.length === 0) {
      return `${input.chapterTitle}의 이야기를 모아 두고 있어요.\n\n아직 담긴 답이 없습니다.`;
    }

    const prompt = [
      '당신은 어르신의 자서전을 정리하는 작가입니다.',
      `「${input.chapterTitle}」 장의 답변들을 1인칭 회고체 산문으로 이어 쓰세요.`,
      '없는 사실을 지어내지 말고, 답변에 있는 내용만 씁니다.',
      '',
      ...parts.map((p, i) => `[답변 ${i + 1}]\n${p}`),
    ].join('\n');

    return this.chat(prompt, { maxTokens: 2000, temperature: 0.5 });
  }

  private async renderPrompt(
    key: string,
    vars: Record<string, string>,
  ): Promise<string> {
    const row = await this.prompts.findOne({ where: { key } });
    const seed = PROMPT_SEED.find((p) => p.key === key);
    let body = row?.body ?? seed?.body;
    if (!body) {
      throw new Error(`프롬프트 템플릿이 없습니다: ${key}`);
    }
    for (const [name, value] of Object.entries(vars)) {
      body = body.replaceAll(`{{${name}}}`, value);
    }
    return body;
  }

  private async chat(
    prompt: string,
    opts: { maxTokens: number; temperature: number },
  ): Promise<string> {
    const apiKey = this.configService.get<string>('OPENROUTER_API_KEY');
    if (!apiKey) {
      throw new Error('OPENROUTER_API_KEY가 없습니다');
    }

    const model = this.model;
    this.logger.log(`OpenRouter 호출 · ${model}`);

    try {
      const { data } = await firstValueFrom(
        this.httpService.post<{
          choices?: Array<{ message?: { content?: string } }>;
        }>(
          'https://openrouter.ai/api/v1/chat/completions',
          {
            model,
            messages: [{ role: 'user', content: prompt }],
            max_tokens: opts.maxTokens,
            temperature: opts.temperature,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://lifelegacy.app',
              'X-Title': 'LifeLegacy',
            },
            timeout: 60_000,
          },
        ),
      );

      const text = data.choices?.[0]?.message?.content?.trim() ?? '';
      if (!text) {
        throw new Error('OpenRouter 응답이 비어 있습니다');
      }
      return text;
    } catch (err) {
      this.logger.error(`OpenRouter 실패 · ${model}`);
      throw err;
    }
  }
}
