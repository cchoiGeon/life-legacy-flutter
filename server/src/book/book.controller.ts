import { Controller, Get, Param, ParseUUIDPipe, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { EntitlementsResponseDto } from 'src/entitlement/dto/response/entitlements-response.dto';
import { ReviewService } from 'src/review/services/review.service';
import { BookPageResponseDto } from './dto/response/book-page-response.dto';
import { BookResponseDto } from './dto/response/book-response.dto';
import { BookService } from './services/book.service';

@ApiTags('Books API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('books')
export class BookController {
  constructor(
    private readonly bookService: BookService,
    private readonly reviewService: ReviewService,
  ) {}

  @ApiOperation({ summary: '책 목록' })
  @Get()
  async listBooks(@UserId() userId: string) {
    return { items: await this.bookService.listBooks(userId) };
  }

  @ApiOperation({ summary: '기능별 권한 안내 (§11)' })
  @ApiResponse({ status: 200, type: EntitlementsResponseDto })
  @Get(':bookId/entitlements')
  getEntitlements(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.bookService.getEntitlements(userId, bookId);
  }

  @ApiOperation({ summary: '책 요약/상세' })
  @ApiResponse({ status: 200, type: BookResponseDto })
  @Get(':bookId')
  getBook(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.bookService.getBook(userId, bookId);
  }

  @ApiOperation({ summary: '미리보기 쪽 (reviewed 장만)' })
  @ApiResponse({ status: 200, type: BookPageResponseDto, isArray: true })
  @Get(':bookId/pages')
  async getPages(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return { items: await this.bookService.getPages(userId, bookId) };
  }

  @ApiOperation({ summary: '책 전체 장별 사진 목록 (사진첩)' })
  @Get(':bookId/photos')
  getBookPhotos(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
  ) {
    return this.reviewService.getBookPhotos(userId, bookId);
  }

  @ApiOperation({ summary: '장 사진 상세 + 원고 (G4 chapter-read)' })
  @Get(':bookId/photos/:chapterId')
  getChapterPhotos(
    @UserId() userId: string,
    @Param('bookId', ParseUUIDPipe) bookId: string,
    @Param('chapterId', ParseUUIDPipe) chapterId: string,
  ) {
    return this.reviewService.getChapterPhotos(userId, bookId, chapterId);
  }
}
