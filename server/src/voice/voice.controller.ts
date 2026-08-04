import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
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
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import type { Response } from 'express';
import { memoryStorage } from 'multer';

import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { VoiceService } from './voice.service';

class TtsRequestDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  text: string;

  @IsOptional()
  @IsString()
  voice_code?: string;
}

@ApiTags('Voice API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('voice')
export class VoiceController {
  constructor(private readonly voiceService: VoiceService) {}

  @ApiOperation({ summary: 'TTS — 질문 읽어주기 (audio/mpeg)' })
  @HttpCode(200)
  @Post('tts')
  async tts(@Body() dto: TtsRequestDto, @Res() res: Response) {
    const { audio, durationMs } = await this.voiceService.synthesize(
      dto.text,
      dto.voice_code,
    );
    res.setHeader('Content-Type', 'audio/mpeg');
    if (durationMs != null) {
      res.setHeader('X-Voice-Duration-Ms', String(durationMs));
    }
    res.send(audio);
  }

  @ApiOperation({ summary: 'STT — 녹음 전사' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        audio: { type: 'string', format: 'binary' },
        duration_ms: { type: 'integer' },
      },
      required: ['audio'],
    },
  })
  @HttpCode(200)
  @Post('stt')
  @UseInterceptors(
    FileInterceptor('audio', {
      storage: memoryStorage(),
      limits: { fileSize: 3 * 1024 * 1024 },
    }),
  )
  async stt(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body('duration_ms') durationRaw?: string,
  ) {
    if (!file?.buffer?.length) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    const durationMs =
      durationRaw != null && durationRaw !== ''
        ? Number(durationRaw)
        : null;
    return this.voiceService.transcribe(
      file.buffer,
      Number.isFinite(durationMs) ? durationMs : null,
    );
  }

  @ApiOperation({ summary: '보이스 체크 샘플 (미리 렌더 audio/mpeg)' })
  @Get('sample')
  async sample(
    @Query('voice_code') voiceCode: string | undefined,
    @Res() res: Response,
  ) {
    const { audio } = await this.voiceService.sample(voiceCode);
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Cache-Control', 'private, max-age=86400');
    res.send(audio);
  }
}
