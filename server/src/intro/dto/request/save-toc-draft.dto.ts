import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

/** §2.4 — 기존 · 템플릿 추가 · 사용자 정의 중 하나 */
export class TocDraftChapterItemDto {
  @ApiPropertyOptional({ description: '기존 user_chapter id' })
  @IsOptional()
  @IsUUID()
  id?: string;

  @ApiPropertyOptional({ description: '카탈로그 템플릿 id' })
  @IsOptional()
  @IsUUID()
  template_id?: string;

  @ApiPropertyOptional({
    description: '제목. 기존 장이면 수정, title만 있으면 사용자 정의 장',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  title?: string;
}

export class SaveTocDraftDto {
  @ApiProperty()
  @IsUUID()
  book_id: string;

  @ApiProperty({ type: [TocDraftChapterItemDto] })
  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => TocDraftChapterItemDto)
  chapters: TocDraftChapterItemDto[];
}
