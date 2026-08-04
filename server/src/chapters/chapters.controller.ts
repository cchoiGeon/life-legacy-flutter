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
import { AnswersService } from 'src/answers/services/answers.service';
import { UpdateQuestionTextDto } from './dto/request/update-question-text.dto';
import { ChapterResponseDto } from './dto/response/chapter-response.dto';
import { ChapterCompletionResponseDto } from './dto/response/chapter-completion-response.dto';
import { QuestionResponseDto } from './dto/response/question-response.dto';
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

  @ApiOperation({ summary: '장 목록 (책 범위)' })
  @ApiResponse({ status: 200, type: ChapterResponseDto, isArray: true })
  @Get('books/:bookId/chapters')
  async getChapters(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return { items: await this.chaptersService.getChapters(userId, bookId) };
  }

  @ApiOperation({ summary: '지금 답할 질문 (없으면 204)' })
  @ApiResponse({ status: 200, type: QuestionResponseDto })
  @Get('books/:bookId/questions/current')
  async getCurrentQuestion(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const question = await this.chaptersService.getCurrentQuestion(
      userId,
      bookId,
    );
    if (!question) {
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

  @ApiOperation({ summary: '챕터 완료 화면용 조회 (§5.9)' })
  @ApiResponse({ status: 200, type: ChapterCompletionResponseDto })
  @Get('books/:bookId/chapters/:chapterId/completion')
  getChapterCompletion(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
  ) {
    return this.chaptersService.getChapterCompletion(
      userId,
      bookId,
      chapterId,
    );
  }
}
