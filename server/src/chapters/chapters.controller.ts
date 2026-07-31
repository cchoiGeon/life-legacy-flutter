import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Body,
  Res,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { Response } from 'express';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { UpdateQuestionTextDto } from './dto/request/update-question-text.dto';
import { ChapterResponseDto } from './dto/response/chapter-response.dto';
import { QuestionResponseDto } from './dto/response/question-response.dto';
import { AnswersService } from 'src/answers/services/answers.service';
import { ChaptersService } from './services/chapters.service';

@ApiTags('Chapters API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller()
export class ChaptersController {
  constructor(
    private readonly chaptersService: ChaptersService,
    private readonly answersService: AnswersService,
  ) {}

  @ApiOperation({ summary: '장 목록' })
  @ApiResponse({ status: 200, type: ChapterResponseDto, isArray: true })
  @Get('chapters')
  async getChapters(@UserId() userId: string) {
    return { items: await this.chaptersService.getChapters(userId) };
  }

  @ApiOperation({ summary: '지금 답할 질문 (없으면 204)' })
  @ApiResponse({ status: 200, type: QuestionResponseDto })
  @Get('questions/current')
  async getCurrentQuestion(
    @UserId() userId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const question = await this.chaptersService.getCurrentQuestion(userId);
    if (!question) {
      // 앱은 204를 "다 끝났다"로 읽고 자서전 화면으로 보낸다.
      response.status(204);
      return;
    }

    return QuestionResponseDto.from(
      question,
      await this.answersService.findSavedAnswerText(question.id),
    );
  }

  @ApiOperation({ summary: '질문 단건' })
  @ApiResponse({ status: 200, type: QuestionResponseDto })
  @Get('questions/:questionId')
  async getQuestion(
    @UserId() userId: string,
    @Param('questionId', ParseUUIDPipe) questionId: string,
  ) {
    const question = await this.chaptersService.getOwnedQuestion(
      userId,
      questionId,
    );

    return QuestionResponseDto.from(
      question,
      await this.answersService.findSavedAnswerText(question.id),
    );
  }

  @ApiOperation({ summary: '질문 문구 수정 (답변 전만)' })
  @ApiResponse({ status: 200, type: QuestionResponseDto })
  @Patch('questions/:questionId')
  updateQuestionText(
    @UserId() userId: string,
    @Param('questionId', ParseUUIDPipe) questionId: string,
    @Body() dto: UpdateQuestionTextDto,
  ) {
    return this.chaptersService.updateQuestionText(
      userId,
      questionId,
      dto.text,
    );
  }
}
