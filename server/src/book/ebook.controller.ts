import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { createReadStream } from 'fs';
import type { Response } from 'express';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { EbookService } from './services/ebook.service';

class UpdateEbookMetadataDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  title?: string;
}

@ApiTags('Ebook API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('books/:bookId/ebook')
export class EbookController {
  constructor(private readonly ebookService: EbookService) {}

  @ApiOperation({ summary: '전자책 자격 (reviewed 장 기준)' })
  @Get('eligibility')
  eligibility(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.ebookService.eligibility(userId, bookId);
  }

  @ApiOperation({ summary: '전자책 PDF 생성 (스냅샷 재사용)' })
  @Post('generate')
  generate(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.ebookService.generate(userId, bookId);
  }

  @ApiOperation({ summary: '전자책 PDF 다운로드 스트림' })
  @Get('file')
  @Header('Content-Type', 'application/pdf')
  async file(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Res({ passthrough: true }) response: Response,
  ) {
    const file = await this.ebookService.resolveFilePath(userId, bookId);
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${file.fileName}"`,
    );
    response.setHeader('X-Export-Id', file.exportId);
    const stream = createReadStream(file.absolutePath);
    return new StreamableFile(stream);
  }

  @ApiOperation({ summary: 'AI 제목 추천 (진행률 80%+)' })
  @Post('titles/suggest')
  suggestTitles(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.ebookService.suggestTitles(userId, bookId);
  }

  @ApiOperation({ summary: '전자책 메타데이터(제목) 저장' })
  @Patch('metadata')
  updateMetadata(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Body() dto: UpdateEbookMetadataDto,
  ) {
    return this.ebookService.updateMetadata(userId, bookId, dto);
  }
}
