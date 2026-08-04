import { ApiProperty } from '@nestjs/swagger';

import { ChapterResponseDto } from 'src/chapters/dto/response/chapter-response.dto';

export class GenerateTocResponseDto {
  @ApiProperty({ example: 'legacy_college_married_children' })
  case_key: string;

  @ApiProperty({ example: 'b_001' })
  book_id: string;

  @ApiProperty({ type: [ChapterResponseDto] })
  chapters: ChapterResponseDto[];
}
