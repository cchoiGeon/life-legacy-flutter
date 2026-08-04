import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { ChaptersController } from './chapters.controller';
import { UserChapterModel } from './entities/user-chapter.entity';
import { UserQuestionModel } from './entities/user-question.entity';
import { ChaptersRepository } from './repositories/chapters.repository';
import { ChaptersService } from './services/chapters.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserChapterModel,
      UserQuestionModel,
      ChapterReviewModel,
    ]),
    AuthGuardModule,
    BookAccessModule,
    forwardRef(() => AnswersModule),
  ],
  controllers: [ChaptersController],
  providers: [ChaptersService, ChaptersRepository],
  exports: [ChaptersService, ChaptersRepository],
})
export class ChaptersModule {}
