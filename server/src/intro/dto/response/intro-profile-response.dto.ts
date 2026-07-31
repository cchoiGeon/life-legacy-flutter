import { ApiProperty } from '@nestjs/swagger';

export class IntroProfileEntryDto {
  @ApiProperty({ example: '성별' }) label: string;
  @ApiProperty({ example: '여성' }) value: string;
}

/**
 * 라벨과 값을 **서버가 짝지어** 내려준다. 화면이 i2·i5 같은 질문 id를 알
 * 필요가 없다. 성함(i1)은 넣지 않는다 — 화면 상단에 이미 이름이 있다.
 */
export class IntroProfileResponseDto {
  @ApiProperty({ type: [IntroProfileEntryDto] })
  entries: IntroProfileEntryDto[];
}
