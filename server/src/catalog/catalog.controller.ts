import {
  Controller,
  Get,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { CatalogService } from './services/catalog.service';

@ApiTags('Catalog API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @ApiOperation({ summary: '목차 추가용 카탈로그 대목차' })
  @ApiQuery({ name: 'book_id', required: true })
  @Get('chapters')
  async listChapters(
    @UserId() userId: string,
    @Query('book_id', ParseUUIDPipe) bookId: string,
  ) {
    return {
      items: await this.catalogService.listChaptersForBook(userId, bookId),
    };
  }
}
