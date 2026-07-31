import {
  Body,
  Controller,
  Get,
  HttpCode,
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
import { ConfirmTocDto } from './dto/request/confirm-toc.dto';
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

  @ApiOperation({ summary: '자기소개 문항 (5문항 고정)' })
  @ApiResponse({ status: 200, type: IntroQuestionResponseDto, isArray: true })
  @Get('questions')
  async getQuestions() {
    return { items: await this.introService.getQuestions() };
  }

  @ApiOperation({ summary: '자기소개 제출 → 케이스 판정 + 목차 생성' })
  @ApiResponse({ status: 200, type: GenerateTocResponseDto })
  @HttpCode(200)
  @Post('answers')
  submitAnswers(@UserId() userId: string, @Body() dto: SubmitIntroAnswersDto) {
    return this.introService.submitAnswers(userId, dto.answers);
  }

  @ApiOperation({ summary: '목차 확정' })
  @ApiResponse({ status: 204 })
  @HttpCode(204)
  @Post('toc/confirm')
  confirmToc(@UserId() userId: string, @Body() dto: ConfirmTocDto) {
    return this.introService.confirmToc(userId, dto.chapter_ids);
  }

  @ApiOperation({ summary: '자기소개 프로필 (F3 내 정보)' })
  @ApiResponse({ status: 200, type: IntroProfileResponseDto })
  @Get('profile')
  getProfile(@UserId() userId: string) {
    return this.introService.getProfile(userId);
  }
}
