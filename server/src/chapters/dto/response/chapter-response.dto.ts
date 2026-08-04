import { ApiProperty } from '@nestjs/swagger';

import { ChapterSource } from '../../const/chapter-source.enum';
import { ChapterStatus } from '../../const/chapter-status.enum';
import { UserChapterModel } from '../../entities/user-chapter.entity';

export class ChapterResponseDto {
  @ApiProperty() id: string;
  @ApiProperty({ example: 1, description: '1부터. "제1장"의 숫자' })
  order: number;
  @ApiProperty({ example: '탄생과 유아기 시절' }) title: string;
  @ApiProperty({ enum: ChapterStatus }) status: ChapterStatus;
  @ApiProperty({ enum: ChapterSource, example: ChapterSource.TEMPLATE })
  source_type: ChapterSource;
  @ApiProperty({ example: 3 }) answered_count: number;
  @ApiProperty({ example: 5 }) question_count: number;

  @ApiProperty({
    nullable: true,
    description: 'writing 장에만 채운다 — 목록에 "다음 질문 · …"으로 뜬다',
  })
  next_question_text: string | null;

  @ApiProperty({
    nullable: true,
    description: 'null | draft | reviewed. status:done 과 다른 개념',
  })
  review_status: string | null;

  @ApiProperty({ description: '리뷰 reviewed 시 전자책 자격' })
  ebook_eligible: boolean;

  static from(
    chapter: UserChapterModel,
    nextQuestionText: string | null = null,
    reviewStatus: string | null = null,
  ): ChapterResponseDto {
    return {
      id: chapter.id,
      order: chapter.sortOrder,
      title: chapter.title,
      status: chapter.status,
      source_type: chapter.sourceType ?? ChapterSource.TEMPLATE,
      answered_count: chapter.answeredCount,
      question_count: chapter.questionCount,
      next_question_text:
        chapter.status === ChapterStatus.WRITING ? nextQuestionText : null,
      review_status: reviewStatus,
      ebook_eligible: reviewStatus === 'reviewed',
    };
  }
}
