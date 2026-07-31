import { ApiProperty } from '@nestjs/swagger';

import { IntroQuestionModel } from '../../entities/intro-question.entity';

export class IntroQuestionResponseDto {
  @ApiProperty({ example: 'i1' }) id: string;
  @ApiProperty({ example: 1 }) order: number;

  @ApiProperty({
    example: '성함을\n알려주세요',
    description: '\n이 줄바꿈 위치다 — 시안이 끊어 놓은 자리를 그대로 준다',
  })
  text: string;

  @ApiProperty({ nullable: true }) subtitle: string | null;

  @ApiProperty({ nullable: true, description: 'choices가 비었을 때만 쓴다' })
  hint: string | null;

  @ApiProperty({
    type: [String],
    description: '비어 있으면 텍스트 입력, 있으면 선택지',
  })
  choices: string[];

  static from(
    question: IntroQuestionModel,
    choices: string[],
  ): IntroQuestionResponseDto {
    return {
      // 앱은 코드(i1~i5)를 질문 id로 쓴다 — uuid를 알 필요가 없다.
      id: question.code,
      order: question.sortOrder,
      text: question.text,
      subtitle: question.subtitle,
      hint: question.hint,
      choices,
    };
  }
}
