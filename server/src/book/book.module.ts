import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { UsersModule } from 'src/users/users.module';
import { BookController } from './book.controller';
import { BookPageModel } from './entities/book-page.entity';
import { BookModel } from './entities/book.entity';
import { BookService } from './services/book.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([BookModel, BookPageModel]),
    AuthGuardModule,
    ChaptersModule,
    AnswersModule,
    UsersModule,
  ],
  controllers: [BookController],
  providers: [BookService],
})
export class BookModule {}
