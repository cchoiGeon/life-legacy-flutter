import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';
import type { Response } from 'express';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ReviewService } from './services/review.service';

class SaveReviewDto {
  @IsOptional()
  @IsEnum(ReviewStatus)
  status?: ReviewStatus;

  @IsInt()
  @Min(1)
  version: number;
}

class ReviewTtsDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  from_paragraph?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  chunk_size?: number;

  @IsOptional()
  @IsString()
  voice_code?: string;
}

@ApiTags('Review API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('books/:bookId/chapters/:chapterId/review')
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @ApiOperation({ summary: '챕터 종합 원고 조회 (없으면 204)' })
  @Get()
  async get(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const review = await this.reviewService.getReview(
      userId,
      bookId,
      chapterId,
    );
    if (!review) {
      response.status(204);
      return;
    }
    return review;
  }

  @ApiOperation({ summary: '종합 원고 생성' })
  @HttpCode(200)
  @Post('synthesize')
  synthesize(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
  ) {
    return this.reviewService.synthesize(userId, bookId, chapterId);
  }

  @ApiOperation({ summary: '리뷰 저장 (앱은 body 미전송)' })
  @HttpCode(200)
  @Patch()
  save(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Body() dto: SaveReviewDto,
  ) {
    return this.reviewService.saveReview(userId, bookId, chapterId, {
      status: dto.status ?? ReviewStatus.REVIEWED,
      version: dto.version,
    });
  }

  @ApiOperation({ summary: '원고 읽어주기 TTS 청크 (§9.4)' })
  @HttpCode(200)
  @Post('tts')
  async tts(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Body() dto: ReviewTtsDto,
    @Res() res: Response,
  ) {
    const result = await this.reviewService.synthesizeReviewTts(
      userId,
      bookId,
      chapterId,
      {
        fromParagraph: dto.from_paragraph ?? 0,
        chunkSize: dto.chunk_size ?? 2,
        voiceCode: dto.voice_code,
      },
    );
    res.setHeader('Content-Type', 'audio/mpeg');
    if (result.durationMs != null) {
      res.setHeader('X-Voice-Duration-Ms', String(result.durationMs));
    }
    if (result.nextFrom != null) {
      res.setHeader('X-Next-Paragraph', String(result.nextFrom));
    } else {
      res.setHeader('X-Next-Paragraph', '-1');
    }
    res.send(result.audio);
  }
}
