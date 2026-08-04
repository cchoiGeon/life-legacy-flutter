import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { QuestionResponseDto } from 'src/chapters/dto/response/question-response.dto';
import { FollowupDto } from './followup-response.dto';

/**
 * 꼬리답변 응답 — followup과 next_question은 동시에 오지 않는다.
 */
export class AdvanceResponseDto {
  @ApiPropertyOptional({
    type: FollowupDto,
    nullable: true,
    description: '있으면 아직 확정 전 — 같은 엔드포인트를 다시 부른다',
  })
  followup?: FollowupDto | null;

  @ApiPropertyOptional({
    type: QuestionResponseDto,
    nullable: true,
    description: 'null이면 모든 장을 끝냈다는 뜻 — 앱은 자서전 화면으로 간다',
  })
  next_question?: QuestionResponseDto | null;

  @ApiPropertyOptional({
    description: '이 답변으로 장이 끝났으면 true. 다음 장이 열린다',
  })
  chapter_completed?: boolean;
}
