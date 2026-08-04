import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class IntroAnswerItemDto {
  @ApiProperty({ example: 'i2' })
  @IsString()
  @MinLength(1)
  question_id: string;

  @ApiPropertyOptional({ example: '여' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  value?: string;

  @ApiPropertyOptional({ example: 'ch_f' })
  @IsOptional()
  @IsString()
  choice_id?: string;

  @ApiPropertyOptional({ example: 'ch_u1' })
  @IsOptional()
  @IsString()
  detail_choice_id?: string;

  @ApiPropertyOptional({ example: '학사' })
  @IsOptional()
  @IsString()
  detail_value?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  skipped?: boolean;
}

export class SubmitIntroAnswersDto {
  @ApiProperty({ type: [IntroAnswerItemDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => IntroAnswerItemDto)
  answers: IntroAnswerItemDto[];
}
