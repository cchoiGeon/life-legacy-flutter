import {
  Body,
  Controller,
  Get,
  HttpCode,
  Patch,
  Post,
  Put,
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
import { ConfirmTocDto } from './dto/request/confirm-toc.dto';
import { SaveTocDraftDto } from './dto/request/save-toc-draft.dto';
import { SubmitIntroAnswersDto } from './dto/request/submit-intro-answers.dto';
import { GenerateTocResponseDto } from './dto/response/generate-toc-response.dto';
import { IntroProfileResponseDto } from './dto/response/intro-profile-response.dto';
import { IntroQuestionResponseDto } from './dto/response/intro-question-response.dto';
import { IntroService } from './services/intro.service';

@ApiTags('Intro API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('intro')
export class IntroController {
  constructor(private readonly introService: IntroService) {}

  @ApiOperation({ summary: '자기소개 문항' })
  @ApiResponse({ status: 200, type: IntroQuestionResponseDto, isArray: true })
  @Get('questions')
  async getQuestions() {
    return { items: await this.introService.getQuestions() };
  }

  @ApiOperation({ summary: '작성 계획 조회' })
  @Get('writing-plan')
  getWritingPlan(@UserId() userId: string) {
    return this.introService.getWritingPlan(userId);
  }

  @ApiOperation({ summary: '작성 계획 저장' })
  @HttpCode(200)
  @Put('writing-plan')
  putWritingPlan(
    @UserId() userId: string,
    @Body()
    body: {
      daily_minutes: number;
      available_weekdays: number[];
      available_periods: string[];
      duration_weeks: number;
      duration_source: string;
      alarm_enabled: boolean;
    },
  ) {
    return this.introService.putWritingPlan(userId, body);
  }

  @ApiOperation({ summary: '자기소개 제출 → 책·목차 생성' })
  @ApiResponse({ status: 200, type: GenerateTocResponseDto })
  @HttpCode(200)
  @Post('answers')
  submitAnswers(@UserId() userId: string, @Body() dto: SubmitIntroAnswersDto) {
    return this.introService.submitAnswers(userId, dto.answers);
  }

  @ApiOperation({ summary: '목차 초안 저장 (제목·추가·삭제·재배열)' })
  @HttpCode(200)
  @Patch('toc/draft')
  saveTocDraft(@UserId() userId: string, @Body() dto: SaveTocDraftDto) {
    return this.introService.saveTocDraft(userId, dto.book_id, dto.chapters);
  }

  @ApiOperation({ summary: '목차 확정' })
  @HttpCode(200)
  @Post('toc/confirm')
  confirmToc(@UserId() userId: string, @Body() dto: ConfirmTocDto) {
    return this.introService.confirmToc(userId, dto.book_id, dto.chapter_ids);
  }

  @ApiOperation({ summary: '자기소개 프로필 (F3 내 정보)' })
  @ApiResponse({ status: 200, type: IntroProfileResponseDto })
  @Get('profile')
  getProfile(@UserId() userId: string) {
    return this.introService.getProfile(userId);
  }
}
