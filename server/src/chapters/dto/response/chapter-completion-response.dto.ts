import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class CompletionNextChapterDto {
  @ApiProperty() id: string;
  @ApiProperty() order: number;
  @ApiProperty() title: string;
}

class CompletionActionsDto {
  @ApiProperty({ description: '장이 done이어야 true' })
  review: boolean;

  @ApiProperty() hub: boolean;
}

/**
 * GET /books/{book_id}/chapters/{chapter_id}/completion
 * api-spec §5.9
 */
export class ChapterCompletionResponseDto {
  @ApiProperty() chapter_id: string;
  @ApiProperty() chapter_order: number;
  @ApiProperty() chapter_title: string;
  @ApiProperty() question_count: number;
  @ApiProperty() answered_count: number;
  @ApiProperty() skipped_count: number;

  @ApiPropertyOptional({
    nullable: true,
    description: 'null이면 아직 리뷰 전 — 완료 화면에서 리뷰 CTA를 강조',
  })
  review_status: string | null;

  @ApiPropertyOptional({
    type: CompletionNextChapterDto,
    nullable: true,
    description: 'null이면 마지막 장',
  })
  next_chapter: CompletionNextChapterDto | null;

  @ApiProperty({ type: CompletionActionsDto })
  actions: CompletionActionsDto;
}
