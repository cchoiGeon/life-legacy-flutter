import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Not, Repository } from 'typeorm';

import { QnaStatus } from 'src/common/const/qna-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { FAQ_CATEGORIES, FAQ_SECTIONS } from '../content/faq.content';
import { CreateQnaDto } from '../dto/request/create-qna.dto';
import { FaqResponseDto } from '../dto/response/faq-response.dto';
import {
  QnaMineResponseDto,
  QnaPublishedResponseDto,
} from '../dto/response/qna-response.dto';
import { QnaQuestionModel } from '../entities/qna-question.entity';

const ALLOWED_CATEGORIES = new Set<string>(FAQ_CATEGORIES.map((c) => c.id));

@Injectable()
export class QnaService {
  constructor(
    @InjectRepository(QnaQuestionModel)
    private readonly qna: Repository<QnaQuestionModel>,
  ) {}

  getFaq(): FaqResponseDto {
    return {
      categories: FAQ_CATEGORIES.map((c) => ({ id: c.id, label: c.label })),
      sections: FAQ_SECTIONS,
    };
  }

  async create(
    userId: string,
    dto: CreateQnaDto,
  ): Promise<QnaMineResponseDto> {
    const question = dto.question.trim();
    if (question.length < 5) {
      throw new ApiException(
        ERROR_CODE.COMMON.INVALID_REQUEST,
        '문의 내용을 조금 더 적어 주세요',
      );
    }

    let category: string | null = dto.category?.trim() || null;
    if (category && !ALLOWED_CATEGORIES.has(category)) {
      throw new ApiException(
        ERROR_CODE.COMMON.INVALID_REQUEST,
        '문의 카테고리를 다시 골라 주세요',
      );
    }

    const row = this.qna.create({
      userId,
      question,
      category,
      status: QnaStatus.PENDING,
    });
    const saved = await this.qna.save(row);

    return QnaMineResponseDto.from(saved);
  }

  async listMine(userId: string): Promise<QnaMineResponseDto[]> {
    const rows = await this.qna.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });

    return rows.map(QnaMineResponseDto.from);
  }

  async listPublished(): Promise<QnaPublishedResponseDto[]> {
    const rows = await this.qna.find({
      where: {
        status: QnaStatus.PUBLISHED,
        answer: Not(IsNull()),
      },
      order: { publishedAt: 'DESC', createdAt: 'DESC' },
      take: 50,
    });

    return rows
      .filter((r) => (r.answer ?? '').trim().length > 0)
      .map(QnaPublishedResponseDto.from);
  }
}
