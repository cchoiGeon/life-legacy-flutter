import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class IntroProfileEntryDto {
  @ApiProperty({ example: '성별' }) label: string;
  @ApiPropertyOptional({ example: '여', nullable: true }) value: string | null;
  @ApiPropertyOptional({ example: false }) skipped?: boolean;
}

/**
 * 라벨과 값을 **서버가 짝지어** 내려준다. 화면이 i2·i5 같은 질문 id를 알
 * 필요가 없다. 성함은 가입 이름을 쓰므로 여기 넣지 않는다.
 */
export class IntroProfileResponseDto {
  @ApiProperty({ type: [IntroProfileEntryDto] })
  entries: IntroProfileEntryDto[];
}
