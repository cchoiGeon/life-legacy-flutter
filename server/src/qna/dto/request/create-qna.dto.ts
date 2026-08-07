import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateQnaDto {
  @ApiProperty({ example: '음성 입력이 안 돼요. 마이크 권한은 허용했어요.' })
  @IsString()
  @MinLength(5, { message: '문의 내용을 조금 더 적어 주세요' })
  @MaxLength(2000, { message: '문의는 2000자까지 적을 수 있어요' })
  question: string;

  @ApiPropertyOptional({
    example: 'voice',
    description: 'FAQ 카테고리 id (start, intro, write, …)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  category?: string | null;
}
