import { ApiProperty } from '@nestjs/swagger';

import { QuestionResponseDto } from 'src/chapters/dto/response/question-response.dto';

export class AdvanceResponseDto {
  @ApiProperty({
    type: QuestionResponseDto,
    nullable: true,
    description: 'null이면 모든 장을 끝냈다는 뜻 — 앱은 자서전 화면으로 간다',
  })
  next_question: QuestionResponseDto | null;

  @ApiProperty({
    description: '이 답변으로 장이 끝났으면 true. 다음 장이 열린다',
  })
  chapter_completed: boolean;
}
