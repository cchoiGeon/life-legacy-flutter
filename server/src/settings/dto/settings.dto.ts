import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsString, Matches, MaxLength } from 'class-validator';

export class AppSettingsDto {
  @ApiProperty({ description: 'v1에서 켜고 끌 수 있는 건 이 하나뿐이다' })
  @IsBoolean()
  daily_question_alarm: boolean;
}

export class ShippingAddressDto {
  @ApiProperty({ example: '김영희' })
  @IsString()
  @MaxLength(50)
  recipient: string;

  @ApiProperty({
    example: '01012345678',
    description: '숫자만. 띄우는 건 표시할 때만',
  })
  @Matches(/^\d{0,11}$/, { message: '연락처는 숫자만 입력합니다' })
  phone: string;

  @ApiProperty({ example: '03186' })
  @IsString()
  @MaxLength(10)
  postal_code: string;

  @ApiProperty({ example: '서울 종로구 세종대로 175' })
  @IsString()
  @MaxLength(200)
  line1: string;

  @ApiProperty({ example: '302동 1201호', description: '비어도 된다' })
  @IsString()
  @MaxLength(200)
  line2: string;
}
