import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import type { Response } from 'express';
import { memoryStorage } from 'multer';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { ReviewService } from './services/review.service';

class SaveReviewDto {
  @IsOptional()
  @IsEnum(ReviewStatus)
  status?: ReviewStatus;

  @IsInt()
  @Min(1)
  version: number;

  /** 앱·웹 본문 직접 편집 */
  @IsOptional()
  @IsString()
  @MaxLength(100_000)
  body?: string;
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

class GenerateAiPhotoDto {
  @IsOptional()
  @IsBoolean()
  regenerate?: boolean;
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

  @ApiOperation({ summary: '리뷰 저장 (본문·상태)' })
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
      body: dto.body,
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

  @ApiOperation({ summary: 'AI 챕터 사진 생성/재생성 (1:1)' })
  @HttpCode(200)
  @Post('images/generate')
  generateAiPhoto(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Body() dto: GenerateAiPhotoDto,
  ) {
    return this.reviewService.generateAiPhoto(userId, bookId, chapterId, {
      regenerate: dto.regenerate,
    });
  }

  @ApiOperation({ summary: '문단 뒤에 수동 사진 추가' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        image: { type: 'string', format: 'binary' },
        paragraph_index: { type: 'integer' },
      },
      required: ['image', 'paragraph_index'],
    },
  })
  @Post('media')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  addMedia(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body('paragraph_index', ParseIntPipe) paragraphIndex: number,
  ) {
    if (!file) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    return this.reviewService.addMedia(
      userId,
      bookId,
      chapterId,
      file,
      paragraphIndex,
    );
  }

  @ApiOperation({ summary: '사진 배치 삭제' })
  @Delete('media/:placementId')
  removeMedia(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Param('placementId', ParseUUIDPipe) placementId: string,
  ) {
    return this.reviewService.removeMedia(
      userId,
      bookId,
      chapterId,
      placementId,
    );
  }

  @ApiOperation({ summary: '사진 파일 스트림' })
  @Get('media/:placementId/file')
  async mediaFile(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Param('placementId', ParseUUIDPipe) placementId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { file, contentType } = await this.reviewService.getMediaFile(
      userId,
      bookId,
      chapterId,
      placementId,
    );
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'private, max-age=3600');
    return file;
  }
}
