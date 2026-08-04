import {
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateAudiobookJobDto {
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  voice_code: string;

  @IsOptional()
  @IsString()
  @MaxLength(36)
  bgm_track_id?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  idempotency_key: string;
}

export class VoicePreviewDto {
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  voice_code: string;
}
