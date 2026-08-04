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
import { BookPageResponseDto } from './dto/response/book-page-response.dto';
import { BookResponseDto } from './dto/response/book-response.dto';
import { BookService } from './services/book.service';

@ApiTags('Books API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('books')
export class BookController {
  constructor(private readonly bookService: BookService) {}

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
}
