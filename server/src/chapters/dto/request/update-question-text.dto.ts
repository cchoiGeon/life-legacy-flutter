import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateQuestionTextDto {
  @ApiProperty({ example: '가족 여행 중 가장 기억에 남는 곳이 어디인가요?' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  text: string;
}
