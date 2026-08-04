import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { IntroAnswerType } from '../../const/intro-answer-type.enum';
import { IntroQuestionModel } from '../../entities/intro-question.entity';

export class IntroChoiceResponseDto {
  @ApiProperty({ example: 'ch_u' }) id: string;
  @ApiProperty({ example: '대학교 이상' }) label: string;

  @ApiPropertyOptional({
    type: [IntroChoiceResponseDto],
    description: '선택 직후 같은 화면에 뜨는 상세. 없으면 키 자체 생략',
  })
  details?: IntroChoiceResponseDto[];
}

export class IntroQuestionResponseDto {
  @ApiProperty({ example: 'i2' }) id: string;
  @ApiProperty({ example: 1 }) order: number;

  @ApiProperty({
    example: '성별을\n알려주세요',
    description: '\n이 줄바꿈 위치다',
  })
  text: string;

  @ApiProperty({ nullable: true }) subtitle: string | null;
  @ApiProperty({ nullable: true }) hint: string | null;

  @ApiProperty({ enum: IntroAnswerType })
  answer_type: IntroAnswerType;

  @ApiProperty({ example: false })
  skippable: boolean;

  @ApiProperty({ type: [IntroChoiceResponseDto] })
  choices: IntroChoiceResponseDto[];

  static from(
    question: IntroQuestionModel,
    choices: IntroChoiceResponseDto[],
  ): IntroQuestionResponseDto {
    return {
      id: question.code,
      order: question.sortOrder,
      text: question.text,
      subtitle: question.subtitle,
      hint: question.hint,
      answer_type: question.answerType,
      skippable: question.isSkippable,
      choices,
    };
  }
}
