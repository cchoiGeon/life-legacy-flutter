import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';

import { InputMode } from '../../const/answer.enum';

export class SaveAnswerDraftDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  text: string;

  @ApiProperty({ enum: InputMode })
  @IsEnum(InputMode)
  input_mode: InputMode;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(32_000)
  spoken_seconds?: number | null;

  @ApiPropertyOptional({ description: '녹음 메타. 서버는 검증만 하고 저장하지 않을 수 있다' })
  @IsOptional()
  @IsObject()
  recording_meta?: Record<string, unknown>;
}
