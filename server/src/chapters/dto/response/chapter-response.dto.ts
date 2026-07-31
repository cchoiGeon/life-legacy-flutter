import { ApiProperty } from '@nestjs/swagger';

import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';

export class ChapterResponseDto {
  @ApiProperty() id: string;
  @ApiProperty({ example: 1, description: '1부터. "제1장"의 숫자' })
  order: number;
  @ApiProperty({ example: '탄생과 유아기 시절' }) title: string;
  @ApiProperty({ enum: ChapterStatus }) status: ChapterStatus;
  @ApiProperty({ example: 3 }) answered_count: number;
  @ApiProperty({ example: 5 }) question_count: number;

  @ApiProperty({
    nullable: true,
    description: 'writing 장에만 채운다 — 목록에 "다음 질문 · …"으로 뜬다',
  })
  next_question_text: string | null;

  static from(
    chapter: UserChapterModel,
    nextQuestionText: string | null = null,
  ): ChapterResponseDto {
    return {
      id: chapter.id,
      order: chapter.sortOrder,
      title: chapter.title,
      status: chapter.status,
      answered_count: chapter.answeredCount,
      question_count: chapter.questionCount,
      next_question_text:
        chapter.status === ChapterStatus.WRITING ? nextQuestionText : null,
    };
  }
}
