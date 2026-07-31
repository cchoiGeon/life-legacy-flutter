import { ApiProperty } from '@nestjs/swagger';

export class FollowupDto {
  @ApiProperty() id: string;

  @ApiProperty({ description: '요약 + 공감 + 질문이 한 덩어리' })
  text: string;
}

export class SubmitAnswerResponseDto {
  @ApiProperty({ type: FollowupDto })
  followup: FollowupDto;
}
