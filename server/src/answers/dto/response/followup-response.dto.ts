import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class FollowupDto {
  @ApiProperty() id: string;

  @ApiPropertyOptional({ description: '꼬리질문 회차 (1부터)' })
  seq?: number;

  @ApiProperty({ description: '요약 + 공감 + 질문이 한 덩어리' })
  text: string;
}

export class SubmitAnswerResponseDto {
  @ApiProperty({ type: FollowupDto })
  followup: FollowupDto;
}
