import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { firstValueFrom } from 'rxjs';
import { Repository } from 'typeorm';

import { PromptTemplateModel } from '../entities/prompt-template.entity';
import { PROMPT_SEED } from '../seed/prompt.seed';

type FollowupPair = { question: string; answer: string };

const MIN_MAX_TOKENS = 800;
const MAX_MAX_TOKENS = 2400;
const TOKENS_PER_INPUT_CHAR = 1.8;
const SPARSE_ANSWER_CHARS = 80;

/**
 * 꼬리질문을 `리액션\n\n질문` 형태로 맞춘다.
 * 모델이 한 줄로 이어 쓰거나 빈 줄을 여러 개 넣어도 UI·compact 분리가 깨지지 않게 한다.
 */
export function normalizeFollowupText(raw: string): string {
  const text = raw.trim().replace(/\r\n/g, '\n');
  if (!text) return text;

  if (text.includes('\n\n')) {
    const parts = text
      .split(/\n\n+/)
      .map((part) => part.replace(/\s+/g, ' ').trim())
      .filter((part) => part.length > 0);
    if (parts.length >= 2) {
      const question = parts[parts.length - 1]!;
      const reaction = parts.slice(0, -1).join(' ');
      return `${reaction}\n\n${question}`;
    }
    return parts[0] ?? text;
  }

  // 빈 줄이 없으면 마지막 물음표 문장을 질문으로 떼어 낸다.
  const flat = text.replace(/\s+/g, ' ').trim();
  const sentences = flat.split(/(?<=[.?!。？！])\s+/).filter(Boolean);
  if (sentences.length >= 2) {
    const last = sentences[sentences.length - 1]!;
    if (/[?？]$/.test(last)) {
      const question = last.trim();
      const reaction = sentences.slice(0, -1).join(' ').trim();
      if (reaction) return `${reaction}\n\n${question}`;
    }
  }

  return flat;
}

/**
 * 꼬리질문 생성·윤문·챕터 종합.
 *
 * `AI_PROVIDER=stub`(기본)이면 형태만 맞춘 고정 글을 돌려준다.
 * `AI_PROVIDER=openrouter`이면 OpenRouter chat completions를 호출한다.
 * 프롬프트는 `prompt_template` 표(없으면 시드 문구)를 쓴다.
 * 키·플레이스홀더는 lifelegacy(`second_question` / `polish`)와 같다.
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

  /**
   * 리액션(요약·공감) + 빈 줄 + 질문이 한 덩어리로 온다
   * (lifelegacy second_question). 원 질문·원 답은 고정하고,
   * 이전 꼬리 Q&A는 history로 넘긴다.
   */
  async generateFollowup(input: {
    chapterTitle: string;
    mainQuestion: string;
    mainAnswer: string;
    followups?: FollowupPair[];
  }): Promise<string> {
    if (this.isStub) {
      this.logger.log(`[stub] 꼬리질문 생성 · ${input.chapterTitle}`);
      return normalizeFollowupText(
        [
          '말씀해 주신 장면이 눈에 그려집니다. 그 시간이 지금까지도 마음에 남아 계신 것 같아요.',
          '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요?',
        ].join('\n\n'),
      );
    }

    const followups = input.followups ?? [];
    const historyText = followups
      .map(
        (f, index) =>
          `후속 질문${index + 1}: ${f.question}\n답변${index + 1}: ${f.answer}`,
      )
      .join('\n\n');

    const prompt = await this.renderPrompt('second_question', {
      contentTitle: input.chapterTitle,
      mainQuestion: input.mainQuestion,
      mainAnswer: input.mainAnswer.slice(0, 1500),
      history: historyText,
    });
    const raw = await this.chat(prompt, { maxTokens: 400, temperature: 0.7 });
    return normalizeFollowupText(raw);
  }

  /** 1인칭 회고체 산문 (lifelegacy polish / polish_sparse) */
  async polish(input: {
    mainQuestion: string;
    mainAnswer: string;
    followups: FollowupPair[];
  }): Promise<string> {
    if (this.isStub) {
      this.logger.log('[stub] 윤문');
      return [input.mainAnswer, ...input.followups.map((f) => f.answer)]
        .map((part) => part.trim())
        .filter((part) => part.length > 0)
        .join('\n\n');
    }

    const qaText = [
      `질문: ${input.mainQuestion}\n답변: ${input.mainAnswer}`,
      ...input.followups.map(
        (f, index) =>
          `후속 질문${index + 1}: ${f.question}\n답변${index + 1}: ${f.answer}`,
      ),
    ].join('\n\n');

    const totalInputChars = [input.mainAnswer, ...input.followups.map((f) => f.answer)]
      .join('')
      .replace(/\s/g, '').length;
    const sparse = totalInputChars < SPARSE_ANSWER_CHARS;
    const maxTokens = sparse
      ? Math.min(600, Math.max(200, Math.ceil(Math.max(totalInputChars, 40) * 1.2)))
      : Math.min(
          MAX_MAX_TOKENS,
          Math.max(
            MIN_MAX_TOKENS,
            Math.ceil(totalInputChars * TOKENS_PER_INPUT_CHAR),
          ),
        );

    const prompt = await this.renderPrompt(sparse ? 'polish_sparse' : 'polish', {
      qaText,
    });
    return this.chat(prompt, { maxTokens, temperature: 0.5 });
  }

  /** 챕터 답변들을 자서전 원고로 종합 (§9.2) — prompt_template `synthesize_chapter` */
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

    const answers = parts
      .map((p, i) => `[답변 ${i + 1}]\n${p}`)
      .join('\n\n');
    const prompt = await this.renderPrompt('synthesize_chapter', {
      chapterTitle: input.chapterTitle,
      answers,
    });

    return this.chat(prompt, { maxTokens: 2000, temperature: 0.5 });
  }

  /**
   * 챕터 본문 → 이미지 생성용 영어 프롬프트.
   * regenerate면 `ai_photo_prompt_regen` (다른 컨셉).
   */
  async buildAiPhotoPrompt(input: {
    chapterTitle: string;
    body: string;
    previousPrompt?: string | null;
    regenerate?: boolean;
  }): Promise<string> {
    const body = input.body.trim().slice(0, 4000);
    if (this.isStub) {
      this.logger.log(
        `[stub] AI 사진 프롬프트 · ${input.chapterTitle}` +
          (input.regenerate ? ' (regen)' : ''),
      );
      const base = `Warm painterly book illustration of Korean memoir scene for "${input.chapterTitle}", soft natural light, square composition, no text, no watermark`;
      return input.regenerate
        ? `${base}, different concept: quiet indoor memory with symbolic objects, muted earth tones`
        : `${base}, outdoor memory with gentle atmosphere`;
    }

    const key = input.regenerate ? 'ai_photo_prompt_regen' : 'ai_photo_prompt';
    const prompt = await this.renderPrompt(key, {
      chapterTitle: input.chapterTitle,
      body,
      previousPrompt: input.previousPrompt?.trim() || '(none)',
    });
    const raw = await this.chat(prompt, {
      maxTokens: 300,
      temperature: input.regenerate ? 0.85 : 0.6,
    });
    return raw
      .replace(/^["'`]+|["'`]+$/g, '')
      .replace(/\n+/g, ' ')
      .trim();
  }

  /**
   * OpenRouter Image API — 1:1 PNG.
   * stub이면 단색 플레이스홀더 PNG를 돌려준다.
   */
  async generateSquareImage(prompt: string): Promise<{
    buffer: Buffer;
    mimeType: string;
  }> {
    if (this.isStub) {
      this.logger.log('[stub] AI 이미지 생성');
      return { buffer: STUB_SQUARE_PNG, mimeType: 'image/png' };
    }

    const apiKey = this.configService.get<string>('OPENROUTER_API_KEY');
    if (!apiKey) {
      throw new Error('OPENROUTER_API_KEY가 없습니다');
    }

    const model = this.configService.get<string>(
      'AI_IMAGE_MODEL',
      'black-forest-labs/flux.2-pro',
    );
    this.logger.log(`OpenRouter 이미지 · ${model}`);

    try {
      const { data } = await firstValueFrom(
        this.httpService.post<{
          data?: Array<{ b64_json?: string; url?: string }>;
        }>(
          'https://openrouter.ai/api/v1/images',
          {
            model,
            prompt,
            aspect_ratio: '1:1',
            output_format: 'png',
            n: 1,
          },
          {
            headers: {
              Authorization: `Bearer ${apiKey}`,
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://lifelegacy.app',
              'X-Title': 'LifeLegacy',
            },
            timeout: 120_000,
          },
        ),
      );

      const item = data.data?.[0];
      if (item?.b64_json) {
        return {
          buffer: Buffer.from(item.b64_json, 'base64'),
          mimeType: 'image/png',
        };
      }
      if (item?.url) {
        const img = await firstValueFrom(
          this.httpService.get<ArrayBuffer>(item.url, {
            responseType: 'arraybuffer',
            timeout: 60_000,
          }),
        );
        return {
          buffer: Buffer.from(img.data),
          mimeType: 'image/png',
        };
      }
      throw new Error('OpenRouter 이미지 응답이 비어 있습니다');
    } catch (err) {
      this.logger.error(`OpenRouter 이미지 실패 · ${model}`);
      throw err;
    }
  }

  /** Admin — 프롬프트 목록 */
  async listPrompts() {
    const rows = await this.prompts.find({ order: { key: 'ASC' } });
    const byKey = new Map(rows.map((r) => [r.key, r]));
    const keys = new Set([
      ...PROMPT_SEED.map((s) => s.key),
      ...rows.map((r) => r.key),
    ]);
    return [...keys].sort().map((key) => {
      const row = byKey.get(key);
      const seed = PROMPT_SEED.find((s) => s.key === key);
      return {
        key,
        title: row?.title ?? seed?.title ?? key,
        body: row?.body ?? seed?.body ?? '',
        version: row?.version ?? 1,
        updated_by: row?.updatedBy ?? null,
        updated_at: row?.updatedAt ?? null,
        from_seed: !row,
      };
    });
  }

  async getPrompt(key: string) {
    const items = await this.listPrompts();
    const found = items.find((p) => p.key === key);
    if (!found) throw new Error(`프롬프트 템플릿이 없습니다: ${key}`);
    return found;
  }

  async upsertPrompt(
    key: string,
    input: { title?: string; body: string; updatedBy?: string },
  ) {
    let row = await this.prompts.findOne({ where: { key } });
    const seed = PROMPT_SEED.find((s) => s.key === key);
    if (row) {
      if (input.title != null) row.title = input.title;
      row.body = input.body;
      row.version += 1;
      row.updatedBy = input.updatedBy ?? null;
    } else {
      row = this.prompts.create({
        key,
        title: input.title ?? seed?.title ?? key,
        body: input.body,
        version: 1,
        updatedBy: input.updatedBy ?? null,
      });
    }
    row = await this.prompts.save(row);
    return {
      key: row.key,
      title: row.title,
      body: row.body,
      version: row.version,
      updated_by: row.updatedBy,
      updated_at: row.updatedAt,
      from_seed: false,
    };
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
    // lifelegacy와 동일: 없는 키는 빈 문자열
    return body.replace(/\{\{(\w+)\}\}/g, (_, name: string) => vars[name] ?? '');
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

/** stub용 1×1 PNG (연한 크림색) */
const STUB_SQUARE_PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);
