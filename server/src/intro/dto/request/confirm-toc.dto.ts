import { ApiProperty } from '@nestjs/swagger';
import { ArrayNotEmpty, IsArray, IsUUID } from 'class-validator';

export class ConfirmTocDto {
  @ApiProperty({ example: 'b_001' })
  @IsUUID()
  book_id: string;

  @ApiProperty({
    type: [String],
    description:
      '사용자가 "순서 바꾸기"로 재배열한 결과. 이 순서대로 order를 다시 매긴다',
  })
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  chapter_ids: string[];
}
