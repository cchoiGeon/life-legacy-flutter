import { ApiProperty } from '@nestjs/swagger';

export class BookPageResponseDto {
  @ApiProperty({ example: 1 }) chapter_order: number;
  @ApiProperty({ example: '탄생과 유아기 시절' }) chapter_title: string;

  @ApiProperty({
    example: 1,
    description: '책 전체 통쪽수. 장마다 1로 돌아가지 않는다',
  })
  page_number: number;

  @ApiProperty({ example: 34 }) total_pages: number;

  @ApiProperty({ type: [String], description: '문단 단위' })
  paragraphs: string[];
}
