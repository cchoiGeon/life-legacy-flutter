import { ApiProperty } from '@nestjs/swagger';

export class BookResponseDto {
  @ApiProperty({ example: '나의 이야기' }) title: string;
  @ApiProperty({ example: '김영희' }) author_name: string;
  @ApiProperty({ example: 5 }) chapter_count: number;

  @ApiProperty({
    example: 40,
    description: '책에 실린 질문 수(건너뛴 것 제외)',
  })
  question_count: number;

  @ApiProperty({ example: 34 }) page_count: number;

  @ApiProperty({ example: 0, description: 'v1은 항상 0. 사진 첨부는 2차' })
  photo_count: number;

  @ApiProperty({ description: '모든 장이 done이면 true' })
  is_complete: boolean;
}
