import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/** api-spec §6.2 책 상세 허브 */
export class BookResponseDto {
  @ApiProperty() id: string;
  @ApiProperty({ example: '나의 이야기' }) title: string;
  @ApiProperty({ example: '김영희' }) author_name: string;
  @ApiProperty({ enum: ['draft', 'writing', 'completed'] }) status: string;
  @ApiProperty({ example: 0.42 }) progress: number;
  @ApiProperty({ example: 2 }) chapter_done: number;
  @ApiProperty({ example: 9 }) chapter_total: number;

  @ApiPropertyOptional({ nullable: true })
  current_question: {
    id: string;
    chapter_id: string;
    chapter_title: string;
    order: number;
    text: string;
  } | null;

  @ApiProperty({ type: 'array' })
  chapters: Array<{
    id: string;
    order: number;
    title: string;
    status: string;
    answered_count: number;
    question_count: number;
    next_question_text: string | null;
    review_status: string | null;
    ebook_eligible: boolean;
  }>;

  @ApiProperty()
  entitlements: {
    ebook: { allowed: boolean; reason: string | null };
    audiobook: { allowed: boolean; reason: string | null };
    storybook: { allowed: boolean; reason: string | null };
  };

  @ApiProperty({ example: 40 }) question_count: number;
  @ApiProperty({ example: 34 }) page_count: number;
  @ApiProperty({ example: 0 }) photo_count: number;
  @ApiProperty({ description: 'status === completed' }) is_complete: boolean;
}
