import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { SubmitAnswerDto } from './dto/request/submit-answer.dto';
import { AdvanceResponseDto } from './dto/response/advance-response.dto';
import { SubmitAnswerResponseDto } from './dto/response/followup-response.dto';
import { AnswersService } from './services/answers.service';

@ApiTags('Answers API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('questions')
export class AnswersController {
  constructor(private readonly answersService: AnswersService) {}

  @ApiOperation({ summary: '1차 답변 → AI 꼬리질문' })
  @ApiResponse({ status: 200, type: SubmitAnswerResponseDto })
  @HttpCode(200)
  @Post(':questionId/answer')
  submitAnswer(
    @UserId() userId: string,
    @Param('questionId', ParseUUIDPipe) questionId: string,
    @Body() dto: SubmitAnswerDto,
  ) {
    return this.answersService.submitFirstAnswer(userId, questionId, {
      text: dto.text,
      inputMode: dto.input_mode,
      spokenSeconds: dto.spoken_seconds ?? null,
    });
  }

  @ApiOperation({ summary: '꼬리답변 → 확정 저장 + 다음 질문' })
  @ApiResponse({ status: 200, type: AdvanceResponseDto })
  @HttpCode(200)
  @Post(':questionId/followup/:followupId/answer')
  submitFollowupAnswer(
    @UserId() userId: string,
    @Param('questionId', ParseUUIDPipe) questionId: string,
    @Param('followupId', ParseUUIDPipe) followupId: string,
    @Body() dto: SubmitAnswerDto,
  ) {
    return this.answersService.submitFollowupAnswer(
      userId,
      questionId,
      followupId,
      {
        text: dto.text,
        inputMode: dto.input_mode,
        spokenSeconds: dto.spoken_seconds ?? null,
      },
    );
  }

  @ApiOperation({ summary: '이 질문 건너뛰기' })
  @ApiResponse({ status: 200, type: AdvanceResponseDto })
  @HttpCode(200)
  @Post(':questionId/skip')
  skip(
    @UserId() userId: string,
    @Param('questionId', ParseUUIDPipe) questionId: string,
  ) {
    return this.answersService.skipQuestion(userId, questionId);
  }
}
