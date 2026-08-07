import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { CreateQnaDto } from './dto/request/create-qna.dto';
import { FaqResponseDto } from './dto/response/faq-response.dto';
import {
  QnaMineResponseDto,
  QnaPublishedResponseDto,
} from './dto/response/qna-response.dto';
import { QnaService } from './services/qna.service';

@ApiTags('QnA API')
@Controller('qna')
export class QnaController {
  constructor(private readonly qnaService: QnaService) {}

  @ApiOperation({ summary: '문의 등록' })
  @ApiBearerAuth('access-token')
  @ApiResponse({ status: 201, type: QnaMineResponseDto })
  @UseGuards(AccessTokenGuard)
  @Post()
  create(@UserId() userId: string, @Body() dto: CreateQnaDto) {
    return this.qnaService.create(userId, dto);
  }

  @ApiOperation({ summary: '내 문의 목록' })
  @ApiBearerAuth('access-token')
  @ApiResponse({ status: 200, type: QnaMineResponseDto, isArray: true })
  @UseGuards(AccessTokenGuard)
  @Get('me')
  async listMine(@UserId() userId: string) {
    return { items: await this.qnaService.listMine(userId) };
  }

  @ApiOperation({ summary: '공개 게시 QnA (인증 불필요)' })
  @ApiResponse({ status: 200, type: QnaPublishedResponseDto, isArray: true })
  @Get('published')
  async listPublished() {
    return { items: await this.qnaService.listPublished() };
  }
}

@ApiTags('FAQ API')
@Controller('faq')
export class FaqController {
  constructor(private readonly qnaService: QnaService) {}

  @ApiOperation({ summary: '정적 FAQ (인증 불필요)' })
  @ApiResponse({ status: 200, type: FaqResponseDto })
  @Get()
  getFaq() {
    return this.qnaService.getFaq();
  }
}
