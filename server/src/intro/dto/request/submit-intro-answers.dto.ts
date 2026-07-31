import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class IntroAnswerItemDto {
  @ApiProperty({ example: 'i1' })
  @IsString()
  @MinLength(1)
  question_id: string;

  @ApiProperty({ example: '김영희', description: '고르거나 적은 원본 문자열' })
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  value: string;
}

export class SubmitIntroAnswersDto {
  @ApiProperty({ type: [IntroAnswerItemDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => IntroAnswerItemDto)
  answers: IntroAnswerItemDto[];
}
