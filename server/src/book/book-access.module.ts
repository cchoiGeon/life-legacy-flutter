import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { BookModel } from './entities/book.entity';
import { BookAccessService } from './services/book-access.service';

/** BookModel + 소유 검증. 순환 import를 피하려고 분리한다. */
@Module({
  imports: [TypeOrmModule.forFeature([BookModel])],
  providers: [BookAccessService],
  exports: [BookAccessService, TypeOrmModule],
})
export class BookAccessModule {}
