import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { EntitlementModule } from 'src/entitlement/entitlement.module';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { ReviewModule } from 'src/review/review.module';
import { UsersModule } from 'src/users/users.module';
import { BookAccessModule } from './book-access.module';
import { BookController } from './book.controller';
import { EbookController } from './ebook.controller';
import { BookPageModel } from './entities/book-page.entity';
import { BookModel } from './entities/book.entity';
import { BookService } from './services/book.service';
import { EbookService } from './services/ebook.service';
import { EbookExportModel } from 'src/ebook/entities/ebook-export.entity';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      BookModel,
      BookPageModel,
      ChapterReviewModel,
      EbookExportModel,
      MediaAssetModel,
    ]),
    BookAccessModule,
    AuthGuardModule,
    EntitlementModule,
    forwardRef(() => ChaptersModule),
    forwardRef(() => ReviewModule),
    AnswersModule,
    UsersModule,
  ],
  controllers: [BookController, EbookController],
  providers: [BookService, EbookService],
  exports: [BookService, BookAccessModule],
})
export class BookModule {}
