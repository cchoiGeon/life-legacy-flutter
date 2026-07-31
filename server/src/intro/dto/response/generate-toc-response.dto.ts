import { ApiProperty } from '@nestjs/swagger';

import { ChapterResponseDto } from 'src/chapters/dto/response/chapter-response.dto';

export class GenerateTocResponseDto {
  @ApiProperty({ example: 'legacy_college_married_children' })
  case_key: string;

  @ApiProperty({ type: [ChapterResponseDto] })
  chapters: ChapterResponseDto[];
}
