import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { BookPageResponseDto } from './dto/response/book-page-response.dto';
import { BookResponseDto } from './dto/response/book-response.dto';
import { BookService } from './services/book.service';

@ApiTags('Book API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('book')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @ApiOperation({ summary: '책 요약' })
  @ApiResponse({ status: 200, type: BookResponseDto })
  @Get()
  getBook(@UserId() userId: string) {
    return this.bookService.getBook(userId);
  }

  @ApiOperation({ summary: '미리보기 쪽 (done 장만)' })
  @ApiResponse({ status: 200, type: BookPageResponseDto, isArray: true })
  @Get('pages')
  async getPages(@UserId() userId: string) {
    return { items: await this.bookService.getPages(userId) };
  }
}
