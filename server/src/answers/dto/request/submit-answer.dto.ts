import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';

import { InputMode } from '../../const/answer.enum';

export class SubmitAnswerDto {
  @ApiProperty({ description: '사용자 원문. 음성이면 받아쓴 결과 그대로' })
  @IsString()
  @MinLength(1)
  text: string;

  @ApiProperty({ enum: InputMode })
  @IsEnum(InputMode)
  input_mode: InputMode;

  @ApiPropertyOptional({ description: 'voice일 때 말한 시간(초)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(32_000)
  spoken_seconds?: number | null;
}
