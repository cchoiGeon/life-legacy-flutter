import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { QnaStatus } from 'src/common/const/qna-status.enum';
import { QnaQuestionModel } from '../../entities/qna-question.entity';

/** 로그인 사용자의 내 문의 */
export class QnaMineResponseDto {
  @ApiProperty() id: string;
  @ApiPropertyOptional({ nullable: true }) category: string | null;
  @ApiProperty() question: string;
  @ApiProperty({ enum: QnaStatus }) status: QnaStatus;
  @ApiPropertyOptional({ nullable: true }) answer: string | null;
  @ApiPropertyOptional({ nullable: true }) answered_at: string | null;
  @ApiProperty() created_at: string;

  static from(row: QnaQuestionModel): QnaMineResponseDto {
    return {
      id: row.id,
      category: row.category,
      question: row.question,
      status: row.status,
      answer: row.answer,
      answered_at: row.answeredAt?.toISOString() ?? null,
      created_at: row.createdAt.toISOString(),
    };
  }
}

/** 공개 게시 QnA — admin_note·연락처·user_id 없음 */
export class QnaPublishedResponseDto {
  @ApiProperty() id: string;
  @ApiPropertyOptional({ nullable: true }) category: string | null;
  @ApiProperty() question: string;
  @ApiProperty() answer: string;
  @ApiPropertyOptional({ nullable: true }) published_at: string | null;

  static from(row: QnaQuestionModel): QnaPublishedResponseDto {
    return {
      id: row.id,
      category: row.category,
      question: row.question,
      answer: row.answer ?? '',
      published_at: row.publishedAt?.toISOString() ?? null,
    };
  }
}
