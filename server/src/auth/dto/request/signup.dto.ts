import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsString,
  Length,
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

/** api-spec §1.10 */
export class SignupDto {
  @ApiProperty({
    example: 'st_…',
    description: '§1.9에서 받은 signup_token (단기). 액세스 토큰이 아님',
  })
  @IsString()
  @Length(1, 80)
  signup_token: string;

  @ApiProperty({ example: '홍길동' })
  @IsString()
  @Length(1, 50)
  name: string;

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
