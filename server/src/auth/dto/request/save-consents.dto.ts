import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class ConsentEntryDto {
  @ApiProperty({ example: 'terms_of_service' })
  @IsString()
  key: string;

  @ApiProperty({ example: '1.0' })
  @IsString()
  version: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  agreed: boolean;
}

/** 카카오 등 세션이 이미 발급된 사용자의 약관 동의 저장 */
export class SaveConsentsDto {
  @ApiProperty({
    type: [ConsentEntryDto],
    example: [
      { key: 'terms_of_service', version: '1.0', agreed: true },
      { key: 'privacy_policy', version: '1.0', agreed: true },
      { key: 'age_14', version: '1.0', agreed: true },
      { key: 'marketing', version: '1.0', agreed: false },
    ],
  })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ConsentEntryDto)
  consents: ConsentEntryDto[];
}
