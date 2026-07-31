import { ApiProperty } from '@nestjs/swagger';

/**
 * 화면 하나가 필요한 값을 한 번에 준다. 서버가 여러 도메인에서 모아야
 * 하더라도 이 모양으로 합쳐서 준다.
 */
export class HomeResponseDto {
  @ApiProperty({
    nullable: true,
    description: 'null이면 앱이 빈 상태 화면을 그린다',
  })
  today_question: string | null;

  @ApiProperty({ nullable: true }) today_question_id: string | null;

  @ApiProperty({ example: 0.42, description: '0.0~1.0' })
  progress: number;

  @ApiProperty({ example: 2 }) chapter_done: number;
  @ApiProperty({ example: 5 }) chapter_total: number;
  @ApiProperty({ example: 12 }) remaining_questions: number;
}
