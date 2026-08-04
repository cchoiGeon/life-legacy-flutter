import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { createReadStream } from 'fs';
import type { Response } from 'express';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import {
  CreateAudiobookJobDto,
  VoicePreviewDto,
} from './dto/request/create-audiobook-job.dto';
import { AudiobookService } from './services/audiobook.service';

@ApiTags('Audiobook API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('books/:bookId/audiobook')
export class AudiobookController {
  constructor(private readonly audiobookService: AudiobookService) {}

  @ApiOperation({ summary: '오디오북 현황 (무료는 chapters=[] )' })
  @Get()
  overview(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.audiobookService.getOverview(userId, bookId);
  }

  @ApiOperation({ summary: '선택 가능한 CLOVA 음성' })
  @Get('voices')
  listVoices(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.audiobookService.listVoices(userId, bookId);
  }

  @ApiOperation({ summary: '음성 샘플 (Naver CLOVA TTS)' })
  @Post('voice-preview')
  @Header('Content-Type', 'audio/mpeg')
  async voicePreview(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Body() dto: VoicePreviewDto,
    @Res({ passthrough: true }) response: Response,
  ) {
    const { audio, mimeType } = await this.audiobookService.voicePreview(
      userId,
      bookId,
      dto.voice_code,
    );
    response.setHeader('Content-Type', mimeType);
    return new StreamableFile(audio);
  }

  @ApiOperation({ summary: 'BGM 카탈로그' })
  @Get('bgms')
  listBgms(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.audiobookService.listBgms(userId, bookId);
  }

  @ApiOperation({ summary: '챕터 오디오북 생성 (CLOVA TTS)' })
  @Post('chapters/:chapterId/jobs')
  createJob(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Body() dto: CreateAudiobookJobDto,
  ) {
    return this.audiobookService.createJob(userId, bookId, chapterId, dto);
  }

  @ApiOperation({ summary: '생성 job 상태' })
  @Get('jobs/:jobId')
  getJob(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('jobId', ParseUUIDPipe) jobId: string,
  ) {
    return this.audiobookService.getJob(userId, bookId, jobId);
  }

  @ApiOperation({ summary: '생성 job 취소' })
  @Post('jobs/:jobId/cancel')
  cancelJob(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('jobId', ParseUUIDPipe) jobId: string,
  ) {
    return this.audiobookService.cancelJob(userId, bookId, jobId);
  }

  @ApiOperation({ summary: '챕터 오디오 재생 스트림' })
  @Get('chapters/:chapterId/stream')
  async stream(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const file = await this.audiobookService.resolveStream(
      userId,
      bookId,
      chapterId,
    );
    response.setHeader('Content-Type', file.mimeType);
    response.setHeader(
      'Content-Disposition',
      `inline; filename="${file.fileName}"`,
    );
    return new StreamableFile(createReadStream(file.absolutePath));
  }

  @ApiOperation({ summary: '챕터 오디오 다운로드 (한도 없음)' })
  @Post('chapters/:chapterId/downloads')
  async download(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const file = await this.audiobookService.resolveDownload(
      userId,
      bookId,
      chapterId,
    );
    response.setHeader('Content-Type', file.mimeType);
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${file.fileName}"`,
    );
    return new StreamableFile(createReadStream(file.absolutePath));
  }
}
