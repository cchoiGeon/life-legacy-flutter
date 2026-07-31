import { ApiProperty } from '@nestjs/swagger';

import { UserQuestionModel } from '../../entities/user-question.entity';

export class QuestionResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() chapter_id: string;

  @ApiProperty({
    example: 3,
    description: '장 안에서의 순번. "질문 3 / 6"의 앞 숫자',
  })
  order: number;

  @ApiProperty() text: string;

  @ApiProperty({
    nullable: true,
    description: '확정 저장된 **사용자 원문**. AI 윤문 결과가 아니다',
  })
  answer: string | null;

  static from(
    question: UserQuestionModel,
    answer: string | null = null,
  ): QuestionResponseDto {
    return {
      id: question.id,
      chapter_id: question.userChapter.id,
      order: question.sortOrder,
      text: question.text,
      answer,
    };
  }
}
